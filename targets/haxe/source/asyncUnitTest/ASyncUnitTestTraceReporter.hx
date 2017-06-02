package asyncUnitTest;

class ASyncUnitTestTraceReporter implements ASyncUnitTestReporter
{
    public function new() {}
    
    public function ReportTestResult(testDuration:Float, testName:String, testResult:Int, testMessage:String) : Void
    {
        var line:String = "";
        line += testDuration;
        while (line.length < 12)
            line = " " + line;
        line += " - " + testName + " - ";
        switch (testResult)
        {
            case ASyncUnitTestEvent.RESULT_SKIPPED: line += "SKIPPED";
            case ASyncUnitTestEvent.RESULT_ERROR: line += "ERROR";
            case ASyncUnitTestEvent.RESULT_FAILED: line += "FAILED";
            case ASyncUnitTestEvent.RESULT_TIMED_OUT: line += "TIMED OUT";
            case ASyncUnitTestEvent.RESULT_PASSED: line += "PASSED";
        }
        if (testMessage != null)
            line += " - " + testMessage;
        line += "\n";
        trace(line);
    }
    
    public function ReportSuiteResult(suiteName:String, suiteSetUpDuration:Float, suiteTearDownDuration:Float, cumulativeSetUpTime:Float, cumulativeTearDownTime:Float,
        testsRun:Int, testsPassed:Int, testsFailed:Int, testsErrored:Int, testsTimedOut:Int, testsSkipped:Int) : Void
    {
        ReportTestResult(suiteSetUpDuration, suiteName + ".SuiteSetUp", ASyncUnitTestEvent.RESULT_PASSED, "");
        ReportTestResult(cumulativeSetUpTime, suiteName + ".CumulativeSetUpTime", ASyncUnitTestEvent.RESULT_PASSED, "");
        ReportTestResult(cumulativeTearDownTime, suiteName + ".CumulativeTearDownTime", ASyncUnitTestEvent.RESULT_PASSED, "");
        ReportTestResult(suiteTearDownDuration, suiteName + ".SuiteTearDown", ASyncUnitTestEvent.RESULT_PASSED, "");
        
        var line:String = "";
        line += "Tests Run: " + testsRun + ", ";
        line += "Tests Passed: " + testsPassed + ", ";
        line += "Tests Failed: " + testsFailed + ", ";
        line += "Tests Errored: " + testsErrored + ", ";
        line += "Test TimeOuts: " + testsTimedOut + ", ";
        line += "Tests Skipped: " + testsSkipped + "\n";
        trace(line);
    }
    
    public function Debug(line:String) : Void
    {
        line += "\n";
        trace(line);
    }
}
