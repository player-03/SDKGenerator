package asyncUnitTest;

interface ASyncUnitTestReporter
{
    function ReportTestResult(testDuration:Float, testName:String, testResult:Int, testMessage:String) : Void;
    function ReportSuiteResult(suiteName:String, suiteSetUpDuration:Float, suiteTearDownDuration:Float, cumulativeSetUpTime:Float, cumulativeTearDownTime:Float,
        testsRun:Int, testsPassed:Int, testsFailed:Int, testsErrored:Int, testsTimedOut:Int, testsSkipped:Int) : Void;
    function Debug(line:String) : Void;
}
