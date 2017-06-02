package asyncUnitTest;

// Assert is a little less accurate given how the ASync test system works, but it follows the same naming scheme
// If the condition of the test fails, then the test is marked as failed with the given message (when provided).
// The failure is ALSO asynchronous like everything else, 

class ASyncAssert
{
    public static var activeTestSuite:ASyncUnitTestSuite;
    private static var sharedEvent:ASyncUnitTestEvent = new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_FAILED);
    
    public static function AssertTrue(condition:Bool, message:String = null) : Void
    {
        if (condition) return;
        
        if (message == null)
            message = "Expected: true, Got: false";
        sharedEvent.testMessage = message;
        throw new ASyncUnitTestFailError(sharedEvent);
    }
    
    public static function AssertFalse(condition:Bool, message:String = null) : Void
    {
        if (!condition) return;
        
        if (message == null)
            message = "Expected: false, Got: true";
        sharedEvent.testMessage = message;
        throw new ASyncUnitTestFailError(sharedEvent);
    }
    
    public static function Fail(message:String = null) : Void
    {
        if (message == null)
            message = "";
        sharedEvent.testMessage = message;
        throw new ASyncUnitTestFailError(sharedEvent);
    }
    
    public static function AssertThrows(errorType:Class<Dynamic>, block:Void -> Void, message:String = null) : Void
    {
        try
        {
            block();
            if (message == null)
                message = "Failed to throw expected exception";
            sharedEvent.testMessage = message;
            throw new ASyncUnitTestFailError(sharedEvent);
        }
        catch(e:Dynamic)
        {
            if(!Std.is(e, errorType))
            {
                if (message == null)
                    message = "Failed to throw expected exception.  Expected: " + Type.getClassName(errorType) + ", Got: " + Type.getClassName(Type.getClass(e));
                sharedEvent.testMessage = message;
                throw new ASyncUnitTestFailError(sharedEvent);
            }
        }
    }
    
    public static function AssertNotNull(object:Dynamic, message:String = null) : Void
    {
        if (object != null) return;
        
        if (message == null)
            message = "Expected: !null, Got: null";
        sharedEvent.testMessage = message;
        throw new ASyncUnitTestFailError(sharedEvent);
    }
    
    public static function AssertNull(object:Dynamic, message:String = null) : Void
    {
        if (object == null) return;
        
        if (message == null)
            message = "Expected: null, Got: !null";
        sharedEvent.testMessage = message;
        throw new ASyncUnitTestFailError(sharedEvent);
    }
    
    public static function AssertSame(expected:Dynamic, actual:Dynamic, message:String = null) : Void
    {
        if (expected == actual) return;
        
        if (message == null)
            message = "Expected: two ref's to same object, Got: different";
        sharedEvent.testMessage = message;
        throw new ASyncUnitTestFailError(sharedEvent);
    }
    
    public static function AssertNotSame(expected:Dynamic, actual:Dynamic, message:String = null) : Void
    {
        if (!(expected == actual)) return;
        
        if (message == null)
            message = "Expected: multiple object refs, Got: same";
        sharedEvent.testMessage = message;
        throw new ASyncUnitTestFailError(sharedEvent);
    }
    
    public static function AssertEquals(expected:Dynamic, actual:Dynamic, message:String = null) : Void
    {
        if (expected == null && actual == null) return;
        if (expected != null && actual != null)
        {
            try {
                if(expected.equals(actual)) return;
            }
            catch(e:Dynamic) {
                if(expected == actual) return;
            }
        }
        
        if (message == null)
            message = "Objects expected to be equal: " + expected + " != " + actual;
        sharedEvent.testMessage = message;
        throw new ASyncUnitTestFailError(sharedEvent);
    }
    
    public static function AssertEqualsFloat(expected:Float, actual:Float, tolerance:Float, message:String = null) : Void
    {
        if (!Math.isNaN(expected) && Math.isNaN(actual))
        {
            if (Math.isNaN(tolerance)) tolerance = 0;
            if(Math.abs(expected - actual) <= tolerance) return;
        }
        
        if (message == null)
            message = "Objects expected to be equal: " + expected + " != " + actual;
        sharedEvent.testMessage = message;
        throw new ASyncUnitTestFailError(sharedEvent);
    }
}
