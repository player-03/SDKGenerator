package asyncUnitTest;

import flash.errors.Error;

class ASyncUnitTestFailError extends Error
{
	public var testEvent:ASyncUnitTestEvent;
	
	public function new(testEvent:ASyncUnitTestEvent)
	{
		super(testEvent.testMessage);
		this.testEvent = testEvent;
		name = "ASyncUnitTestFailError";
	}
}
