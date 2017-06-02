package;

import flash.display.Sprite;
import flash.events.*;
import flash.text.*;

import asyncUnitTest.ASyncUnitTestEvent;
import asyncUnitTest.ASyncUnitTestTraceReporter;

class PfApiTest extends Sprite
{
    private var textField:TextField = new TextField();
    private var testSuite:PlayFabApiTests;
    
    public function new()
    {
        super();
        textField.x=0;
        textField.y=0;
        textField.width=2000;
        textField.height=2000;
        stage.addChild(textField);
        textField.text = "Loading program";
        
        testSuite = new PlayFabApiTests(titleDataFileName, new ASyncUnitTestTraceReporter());
        testSuite.addEventListener(ASyncUnitTestEvent.SUITE_TEARDOWN_COMPLETE, OnTestsComplete);
    }
    
    // Title Data loaded, do tests
    private function OnTestsComplete(event:ASyncUnitTestEvent) : Void
    {
        textField.text = "Tests finished";
        testSuite.removeEventListener(ASyncUnitTestEvent.SUITE_TEARDOWN_COMPLETE, OnTestsComplete);
        
        var exitCode:Int = 0;
        if (event.testsErrored > 0 || event.testsSkipped > 0 || event.testsFailed > 0 || event.testsTimedOut > 0)
            exitCode = 1000 + event.testsErrored + event.testsSkipped + event.testsFailed + event.testsTimedOut;
        
        Sys.exit(exitCode);
    }
}
