package asyncUnitTest;

import flash.display.Sprite;
import flash.errors.*;
import flash.events.*;
import flash.utils.Timer;

class ASyncUnitTestSuite extends Sprite
{
	private var reporter:ASyncUnitTestReporter;
	private var activeTest:TestCall; // The function activating that is currently running
	private var testCalls:Array<TestCall> = new Array<TestCall>(); // A list of all the pending test-function delegates
	
	private var tickTimer:Timer = new Timer(0,1); // The timer that enforces that tests keep responding in a reasonable timeframe
	private var testTimer:Timer = new Timer(0,1); // The timer that enforces the max total test timeout
	private var suiteTimer:Timer = new Timer(0,1); // The timer that enforces the max suite timeout
	
	private var activeState:Int;
	private var activeTestStartTime:Float;
	private var activeTestEndTime:Float;
	
	private var suiteSetUpStartTime:Float;
	private var suiteSetUpEndTime:Float;
	private var suiteTearDownStartTime:Float;
	private var suiteTearDownEndTime:Float;
	private var cumulativeSetUpTime:Float;
	private var eachSetUpStartTime:Float;
	private var eachSetUpEndTime:Float;
	private var cumulativeTearDownTime:Float;
	private var eachTearDownStartTime:Float;
	private var eachTearDownEndTime:Float;
	
	private var testsRun:Int;
	private var testsPassed:Int;
	private var testsFailed:Int;
	private var testsErrored:Int;
	private var testsTimedOut:Int;
	private var testsSkipped:Int;
	
	public function new(reporter:ASyncUnitTestReporter)
	{
		super();
		
		this.reporter = reporter;
		
		addEventListener(ASyncUnitTestEvent.SUITE_SETUP_COMPLETE, SuiteSetUpCompleteHandler);
		addEventListener(ASyncUnitTestEvent.TEST_SETUP_COMPLETE, SetUpCompleteHandler);
		addEventListener(ASyncUnitTestEvent.TICK_TEST, TickTestHandler);
		addEventListener(ASyncUnitTestEvent.FINISH_TEST, FinishTestHandler);
		addEventListener(ASyncUnitTestEvent.TEST_TEARDOWN_COMPLETE, TearDownCompleteHandler);
		addEventListener(ASyncUnitTestEvent.SUITE_TEARDOWN_COMPLETE, SuiteTearDownCompleteHandler);
		
		tickTimer.addEventListener(TimerEvent.TIMER_COMPLETE, OnTestTimeout);
		testTimer.addEventListener(TimerEvent.TIMER_COMPLETE, OnTestTimeout);
		suiteTimer.addEventListener(TimerEvent.TIMER_COMPLETE, OnTestTimeout);
		
		activeState = ASyncUnitTestEvent.STATE_PENDING;
		
		suiteSetUpStartTime = suiteSetUpEndTime = suiteTearDownStartTime = suiteTearDownEndTime = cumulativeSetUpTime = cumulativeTearDownTime = 0;
		
		testsRun = testsSkipped = testsFailed = testsTimedOut = testsPassed = 0;
	}
	
	// Adds a test to an ordered list of tests to be executed
	public function AddTest(testName:String, testFunc:Void -> Void) : Void
	{
		testCalls.unshift(new TestCall(testName, testFunc)); // Queue Functionality
	}
	
	// Call this function from outside the system to activate this TestCase
	// Because this entire system is async, we only kick off the tests, and expect event callbacks in the future.
	public function KickOffTests(tickTimeout:Float = 2, testTimeout:Float = 15, suiteTimeout:Float = 180) : Void
	{
		tickTimer.delay = tickTimeout * 1000;
		tickTimer.repeatCount = 1;
		testTimer.delay = testTimeout * 1000;
		testTimer.repeatCount = 1;
		suiteTimer.delay = testTimeout * 1000;
		suiteTimer.repeatCount = 1;
		
		suiteTimer.start();
		suiteSetUpStartTime = haxe.Timer.stamp();
		activeState = ASyncUnitTestEvent.STATE_SUITE_SETUP;
		SuiteSetUp();
	}
	
	// SuiteSetUp is called once, immediately after KickOffTests
	// For synchronous, override and super-call within your function
	// For asynchronous, override, but do NOT super-call until the end of your sequence
	//   (the last event handler which indicates your sequence is complete)
	private function SuiteSetUp() : Void
	{
		dispatchEvent(new ASyncUnitTestEvent(ASyncUnitTestEvent.SUITE_SETUP_COMPLETE));
	}
	
	private function SuiteSetUpCompleteHandler(event:ASyncUnitTestEvent = null) : Void
	{
		if (activeState == ASyncUnitTestEvent.STATE_TIMED_OUT)
			return;
		
		TickTestHandler();
		suiteSetUpEndTime = haxe.Timer.stamp();
		StartNextTest();
	}
	
	private function StartNextTest() : Void
	{
		testTimer.reset();
		testTimer.start();
		
		if (testCalls.length > 0) // Continue on to the next test
		{
			activeTest = testCalls.pop();
			eachSetUpStartTime = haxe.Timer.stamp();
			activeState = ASyncUnitTestEvent.STATE_TEST_SETUP;
			SetUp();
		}
		else // Trigger the final cleanup
		{
			suiteTearDownStartTime = haxe.Timer.stamp();
			SuiteTearDown();
		}
	}
	
	// SetUp is called before every test function
	//   SetUp is NOT called for any tests skipped due to a previous test-timeout
	// For synchronous, override and super-call within your function
	// For asynchronous, override, but do NOT super-call until the end of your sequence
	//   (the last event handler which indicates your sequence is complete)
	private function SetUp() : Void
	{
		dispatchEvent(new ASyncUnitTestEvent(ASyncUnitTestEvent.TEST_SETUP_COMPLETE));
	}
	
	private function SetUpCompleteHandler(event:ASyncUnitTestEvent = null) : Void
	{
		if (activeState == ASyncUnitTestEvent.STATE_TIMED_OUT)
			return;
		
		TickTestHandler();
		eachSetUpEndTime = haxe.Timer.stamp();
		cumulativeSetUpTime += eachSetUpEndTime - eachSetUpStartTime;
		
		activeTestStartTime = eachSetUpEndTime;
		activeState = ASyncUnitTestEvent.STATE_TEST_RUNNING;
		testsRun += 1;
		
		var wrappedCall:Void -> Void = Wrap0(activeTest.testFunc, activeTest.testName);
		wrappedCall();
	}
	
	// A test has notified that it's made progress, reset the tick-timeout
	// This can be called directly, or posted as an event
	// Call this whenever your test makes progress, such as receiving an async-event
	private function TickTestHandler(event:ASyncUnitTestEvent = null) : Void
	{
		tickTimer.reset();
		tickTimer.start();
	}
	
	// Report that a test has completed.  This is the only place where event.testResult is used
	// This can be called directly, or posted as an event
	private function FinishTestHandler(event:ASyncUnitTestEvent) : Void
	{
		if (activeState == ASyncUnitTestEvent.STATE_TIMED_OUT || activeTest == null)
			return;
		
		TickTestHandler();
		activeTestEndTime = haxe.Timer.stamp();
		reporter.ReportTestResult(activeTestEndTime - activeTestStartTime, activeTest.testName, event.testResult, event.testMessage);
		activeTest = null;
		
		switch (event.testResult)
		{
			case ASyncUnitTestEvent.RESULT_PASSED: testsPassed += 1;
			case ASyncUnitTestEvent.RESULT_FAILED: testsFailed += 1;
			case ASyncUnitTestEvent.RESULT_ERROR: testsErrored += 1;
			case ASyncUnitTestEvent.RESULT_TIMED_OUT: testsTimedOut += 1;
			case ASyncUnitTestEvent.RESULT_SKIPPED: testsSkipped += 1;
		}
		
		activeState = ASyncUnitTestEvent.STATE_TEST_TEARDOWN;
		eachTearDownStartTime = activeTestEndTime;
		if (event.testResult != ASyncUnitTestEvent.RESULT_SKIPPED)
			TearDown();
	}
	
	// TearDown is called after every test function dispatches a FINISH_TEST event, or after the current test times out
	//   TearDown is NOT called for any tests skipped due to a previous test-timeout
	// For synchronous, override and super-call within your function
	// For asynchronous, override, but do NOT super-call until the end of your sequence
	//   (the last event handler which indicates your sequence is complete)
	private function TearDown() : Void
	{
		dispatchEvent(new ASyncUnitTestEvent(ASyncUnitTestEvent.TEST_TEARDOWN_COMPLETE));
	}
	
	private function TearDownCompleteHandler(event:ASyncUnitTestEvent = null) : Void
	{
		if (activeState == ASyncUnitTestEvent.STATE_TIMED_OUT)
			return;
		
		eachTearDownEndTime = haxe.Timer.stamp();
		cumulativeTearDownTime += eachTearDownStartTime - eachTearDownEndTime;
		StartNextTest();
	}
	
	// SuiteTearDown is called once
	// For synchronous, override and super-call within your function
	// For asynchronous, override, but do NOT super-call until the end of your sequence
	//   (the last event handler which indicates your sequence is complete)
	private function SuiteTearDown() : Void
	{
		dispatchEvent(new ASyncUnitTestEvent(ASyncUnitTestEvent.SUITE_TEARDOWN_COMPLETE));
	}
	
	private function SuiteTearDownCompleteHandler(event:ASyncUnitTestEvent = null) : Void
	{
		if (activeState == ASyncUnitTestEvent.STATE_TIMED_OUT)
			return;
		
		suiteTearDownEndTime = haxe.Timer.stamp();
		Cleanup();
		
		ReportSuiteResult(suiteSetUpEndTime - suiteSetUpStartTime, suiteTearDownEndTime - suiteTearDownStartTime, cumulativeSetUpTime, cumulativeTearDownTime,
			testsRun, testsPassed, testsFailed, testsErrored, testsTimedOut, testsSkipped);
	}
	
	private function Cleanup() : Void
	{
		removeEventListener(ASyncUnitTestEvent.SUITE_SETUP_COMPLETE, SuiteSetUpCompleteHandler);
		removeEventListener(ASyncUnitTestEvent.TEST_SETUP_COMPLETE, SetUpCompleteHandler);
		removeEventListener(ASyncUnitTestEvent.TICK_TEST, TickTestHandler);
		removeEventListener(ASyncUnitTestEvent.FINISH_TEST, FinishTestHandler);
		removeEventListener(ASyncUnitTestEvent.TEST_TEARDOWN_COMPLETE, TearDownCompleteHandler);
		removeEventListener(ASyncUnitTestEvent.SUITE_TEARDOWN_COMPLETE, SuiteTearDownCompleteHandler);
		
		tickTimer.reset();
		testTimer.reset();
		suiteTimer.reset();
		tickTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, OnTestTimeout);
		testTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, OnTestTimeout);
		suiteTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, OnTestTimeout);
	}
	
	// All callbacks passed into sequential steps should use Wrap, so that errors in those functions will be caught as error-failures here
	private function Wrap0(func:Void -> Void, description:String) : Void -> Void
	{
		var Wrapper:Void -> Void = function() : Void
		{
			TickTestHandler();
			try
			{
				func();
			}
			catch(error:ASyncUnitTestFailError)
			{
				error.testEvent.testMessage = "\n" + error.getStackTrace();
				FinishTestHandler(error.testEvent);
			}
			catch(error:Error)
			{
				var testMessage:String = description + "\n" + error.getStackTrace();
				FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_ERROR, testMessage));
			}
			catch(error:Dynamic)
			{
				var testMessage:String = description + "\n" + Std.string(error);
				FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_ERROR, testMessage));
			}
			TickTestHandler();
		}
		return Wrapper;
	}
	private function Wrap1<T>(func:T -> Void, description:String) : T -> Void
	{
		var Wrapper:T -> Void = function(arg:T) : Void
		{
			TickTestHandler();
			try
			{
				func(arg);
			}
			catch(error:ASyncUnitTestFailError)
			{
				error.testEvent.testMessage = "\n" + error.getStackTrace();
				FinishTestHandler(error.testEvent);
			}
			catch(error:Error)
			{
				var testMessage:String = description + "\n" + error.getStackTrace();
				FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_ERROR, testMessage));
			}
			catch(error:Dynamic)
			{
				var testMessage:String = description + "\n" + Std.string(error);
				FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_ERROR, testMessage));
			}
			TickTestHandler();
		}
		return Wrapper;
	}
	
	// If there is a timeout, skip all remaining tests, including the active one
	private function OnTestTimeout(event:Event) : Void
	{
		if (activeTest != null) // This will kick off a TearDown
			FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_TIMED_OUT, "Timeout during test"));
		
		while (testCalls.length > 0) // Skip all tests
		{
			var eachSkippedTest:TestCall = testCalls.pop();
			reporter.ReportTestResult(activeTestEndTime - activeTestStartTime, eachSkippedTest.testName, ASyncUnitTestEvent.RESULT_SKIPPED, "Timeout during previous test");
		}
		
		activeState = ASyncUnitTestEvent.STATE_TIMED_OUT;
		ReportSuiteResult(suiteSetUpEndTime - suiteSetUpStartTime, -1, cumulativeSetUpTime, cumulativeTearDownTime,
			testsRun, testsPassed, testsFailed, testsErrored, testsTimedOut, testsSkipped);
	}
	
	private function ReportSuiteResult(suiteSetUpDuration:Float, suiteTearDownDuration:Float, cumulativeSetUpTime:Float, cumulativeTearDownTime:Float,
		testsRun:Int, testsPassed:Int, testsFailed:Int, testsErrored:Int, testsTimedOut:Int, testsSkipped:Int) : Void
	{
		reporter.ReportSuiteResult(Type.getClassName(Type.getClass(this)), suiteSetUpDuration, suiteTearDownDuration, cumulativeSetUpTime, cumulativeTearDownTime,
			testsRun, testsPassed, testsFailed, testsErrored, testsTimedOut, testsSkipped);
		
		var event:ASyncUnitTestEvent = new ASyncUnitTestEvent(ASyncUnitTestEvent.SUITE_TEARDOWN_COMPLETE);
		event.SetResultReport(suiteSetUpDuration, suiteTearDownDuration, cumulativeSetUpTime, cumulativeTearDownTime,
			testsRun, testsPassed, testsFailed, testsErrored, testsTimedOut, testsSkipped);
		
		dispatchEvent(event);
	}
}

class TestCall
{
	public var testName:String;
	public var testFunc:Void -> Void;
	public function new(testName:String, testFunc:Void -> Void)
	{
		this.testName = testName;
		this.testFunc = testFunc;
	}
	
	public function toString() : String
	{
		return testName;
	}
}
