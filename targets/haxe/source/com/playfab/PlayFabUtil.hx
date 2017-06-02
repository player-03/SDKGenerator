package com.playfab;

class PlayFabUtil
{
    private static var TimePattern:EReg = ~/(\d\d\d\d)-?(\d\d)-?(\d\d)[T ](\d\d):(\d\d):(\d\d)(?:\.\d+)?(Z|[+\-]\d\d(?::?\d\d)?|)/;
    
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
        
        //Retrieve the local time zone.
        var timeZoneOffset:Float = new Date(1970, 0, 1, 0, 0, 0).getTime();
        
        var timeZoneString:String = TimePattern.matched(7);
        if(timeZoneString != "" && timeZoneString != "Z")
        {
            timeZoneOffset += Std.parseInt(timeZoneString) * 60 * 60 * 1000;
            
            if(timeZoneString.indexOf(":") > 0)
            {
                timeZoneString = timeZoneString.substr(timeZoneString.indexOf(":") + 1);
                timeZoneOffset += Std.parseInt(timeZoneString) * 60 * 1000;
            }
        }
        
        //Month needs to be 0-indexed.
        var date:Date = new Date(year, month - 1, day, hour, minute, second);
        
        date = Date.fromTime(date.getTime() - timeZoneOffset);
        
        return date;
    }
}
