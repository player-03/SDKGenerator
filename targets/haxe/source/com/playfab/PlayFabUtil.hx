package com.playfab;

class PlayFabUtil
{
    //private static var TimePattern:EReg = ~/(\d+)\-(\d+)\-(\d+)T(\d+):(\d+):(\d+)(\.(\d+))?Z?/x;
    private static var TimePattern:EReg = ~/\w*(\d+)\w*\-\w*(\d+)\w*\-\w*(\d+)\w*T\w*(\d+)\w*:\w*(\d+)\w*:\w*(\d+)\w*(\.\w*(\d+))?\w*Z?/;
    
    public static function parseDate(data:String):Date
    {
        if(data == null || data.length == 0)
            return null;
        
        var result:Bool = TimePattern.match(data);
        
        if(!result)
            return null;
        
        var year:Int = Std.parseInt(TimePattern.matched(1));
        var month:Int = Std.parseInt(TimePattern.matched(2));
        var day:Int = Std.parseInt(TimePattern.matched(3));
        
        var hour:Int = Std.parseInt(TimePattern.matched(4));
        var minute:Int = Std.parseInt(TimePattern.matched(5));
        var second:Int = Std.parseInt(TimePattern.matched(6));
        
        if(data.charAt(data.length-1) == "Z")
        {
            return Date.fromTime(DateTools.makeUtc(year, month-1, day, hour, minute, second));
        }
        else
        {
            return new Date(year, month-1, day, hour, minute, second);
        }
    }
}
