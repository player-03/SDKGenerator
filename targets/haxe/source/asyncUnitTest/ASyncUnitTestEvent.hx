package asyncUnitTest;

import flash.events.Event;

class ASyncUnitTestEvent extends Event
{
	public static inline var SUITE_SETUP_COMPLETE:String = "SUITE_SETUP_COMPLETE";
	public static inline var TEST_SETUP_COMPLETE:String = "TEST_SETUP_COMPLETE";
	public static inline var TICK_TEST:String = "TICK_TEST";
	public static inline var FINISH_TEST:String = "FINISH_TEST";
	public static inline var TEST_TEARDOWN_COMPLETE:String = "TEST_TEARDOWN_COMPLETE";
	public static inline var SUITE_TEARDOWN_COMPLETE:String = "SUITE_TEARDOWN_COMPLETE";
	
	public static inline var STATE_PENDING:Int = 0;
	public static inline var STATE_SUITE_SETUP:Int = 1;
	public static inline var STATE_TEST_SETUP:Int = 2;
	public static inline var STATE_TEST_RUNNING:Int = 3;
	public static inline var STATE_TEST_TEARDOWN:Int = 4;
	public static inline var STATE_SUITE_TEARDOWN:Int = 5;
	public static inline var STATE_FINISHED:Int = 6;
	public static inline var STATE_TIMED_OUT:Int = 7;
	
	public static inline var RESULT_INVALID:Int = 0;
	public static inline var RESULT_SKIPPED:Int = 1;
	public static inline var RESULT_ERROR:Int = 2;
	public static inline var RESULT_FAILED:Int = 3;
	public static inline var RESULT_TIMED_OUT:Int = 4; // This must by necessity cause all following tests to be RESULT_SKIPPED
	public static inline var RESULT_PASSED:Int = 5;
	
	public var testResult:Int;
	public var testMessage:String;
	
	// Result Report Data
	public var suiteSetUpDuration:Float;
	public var suiteTearDownDuration:Float;
	public var cumulativeSetUpTime:Float;
	public var cumulativeTearDownTime:Float;
	public var testsRun:Int;
	public var testsPassed:Int;
	public var testsFailed:Int;
	public var testsErrored:Int;
	public var testsTimedOut:Int;
	public var testsSkipped:Int;
	
	public function new(type:String, testResult:Int=RESULT_PASSED, testMessage:String=null, bubbles:Bool=false, cancelable:Bool=false) : Void
	{
		super(type, bubbles, cancelable);
		this.testResult = testResult;
		this.testMessage = testMessage;
	}
	
	public function SetResultReport(suiteSetUpDuration:Float, suiteTearDownDuration:Float, cumulativeSetUpTime:Float, cumulativeTearDownTime:Float,
		testsRun:Int, testsPassed:Int, testsFailed:Int, testsErrored:Int, testsTimedOut:Int, testsSkipped:Int) : Void
	{
		this.suiteSetUpDuration = suiteSetUpDuration;
		this.suiteTearDownDuration = suiteTearDownDuration;
		this.cumulativeSetUpTime = cumulativeSetUpTime;
		this.cumulativeTearDownTime = cumulativeTearDownTime;
		this.testsRun = testsRun;
		this.testsPassed = testsPassed;
		this.testsFailed = testsFailed;
		this.testsErrored = testsErrored;
		this.testsTimedOut = testsTimedOut;
		this.testsSkipped = testsSkipped;
	}
}
