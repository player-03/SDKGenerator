package;

import flash.display.Sprite;
import flash.events.*;
import flash.text.*;

import openfl.Assets;

import haxe.Json;

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
		addChild(textField);
		
		var data:Dynamic = Json.parse(Assets.getText("assets/testTitleData.json"));
		if(data.titleId != null && data.titleId.indexOf(" ") == -1) {
			textField.text = "Running tests...";
			testSuite = new PlayFabApiTests(data, new ASyncUnitTestTraceReporter());
			testSuite.addEventListener(ASyncUnitTestEvent.SUITE_TEARDOWN_COMPLETE, OnTestsComplete);
		} else {
			textField.text = "Please fill in assets/testTitleData.json and rebuild.";
		}
	}
	
	// Title Data loaded, do tests
	private function OnTestsComplete(event:ASyncUnitTestEvent) : Void
	{
		textField.text = "Tests finished.";
		testSuite.removeEventListener(ASyncUnitTestEvent.SUITE_TEARDOWN_COMPLETE, OnTestsComplete);
		
		var exitCode:Int = 0;
		if (event.testsErrored > 0 || event.testsSkipped > 0 || event.testsFailed > 0 || event.testsTimedOut > 0)
			exitCode = 1000 + event.testsErrored + event.testsSkipped + event.testsFailed + event.testsTimedOut;
		
		#if sys
		Sys.exit(exitCode);
		#end
	}
}
