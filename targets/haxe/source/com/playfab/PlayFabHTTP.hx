package com.playfab;

import flash.errors.Error;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import haxe.Json;

class PlayFabHTTP
{
	public static function post(url:String, requestBody:String, authType:String, authKey:String, onComplete:Dynamic -> PlayFabError -> Void):Void
	{
		var request:URLRequest = new URLRequest(url);
		request.method = URLRequestMethod.POST;
		
		//Object data?
		if( requestBody != null ) {
			request.contentType = "application/json";
			request.data = requestBody;
		}
		
		if(authType != null) request.requestHeaders.push( new URLRequestHeader( authType, authKey ) );
		request.requestHeaders.push( new URLRequestHeader( "X-PlayFabSDK", PlayFabVersion.getVersionString() ) );
		
		var gotHttpStatus:Int=0;
		var loader:URLLoader = null;
		var cleanup:Void -> Void = null;
		
		var onHttpStatus:HTTPStatusEvent -> Void = function(event:HTTPStatusEvent):Void
		{
			gotHttpStatus = event.status;
		}
		
		var onSuccess:Event -> Void = function(event:Event):Void
		{
			cleanup();
			var replyEnvelope:Dynamic = Json.parse(loader.data);
			if(gotHttpStatus == 200)
				onComplete(replyEnvelope.data, null);
			else
				onComplete(null, new PlayFabError(replyEnvelope.data));
		}
		
		var onError:IOErrorEvent -> Void = function(event:IOErrorEvent):Void
		{
			cleanup();
			
			var error:PlayFabError;
			if (event.currentTarget != null)
			{
				try // When possible try to display the actual error returned from the PlayFab server
				{
					var replyEnvelope:Dynamic = Json.parse(event.currentTarget.data);
					error = new PlayFabError(replyEnvelope);
				}
				catch (e:Error)
				{
					error = new PlayFabError({
						httpCode: "HTTP ERROR:" + gotHttpStatus,
						httpStatus: gotHttpStatus,
						error: "NetworkIOError",
						errorCode: PlayFabError.NetworkIOError,
						errorMessage: event.toString() // Default to the IOError
					});
				}
			}
			else
			{
				error = new PlayFabError({
					httpCode: "HTTP ERROR:" + gotHttpStatus,
					httpStatus: gotHttpStatus,
					error: "NetworkIOError",
					errorCode: PlayFabError.NetworkIOError,
					errorMessage: event.toString() // Default to the IOError
				});
			}
			
			onComplete(null, error);
		}
		
		var onSecurityError:SecurityErrorEvent -> Void = function(event:SecurityErrorEvent):Void
		{
			cleanup();
			var error:PlayFabError = new PlayFabError({
				httpCode: "HTTP ERROR:" + gotHttpStatus,
				httpStatus: gotHttpStatus,
				error: "FlashSecurityError",
				errorCode: PlayFabError.FlashSecurityError,
				errorMessage: event.toString()
			});
			onComplete(null, error);
		}
		
		cleanup = function():Void
		{
			loader.removeEventListener( HTTPStatusEvent.HTTP_STATUS, onHttpStatus );
			loader.removeEventListener( Event.COMPLETE, onSuccess );
			loader.removeEventListener( IOErrorEvent.IO_ERROR, onError );
			loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError );
		};
		
		loader = new URLLoader();
		loader.addEventListener( HTTPStatusEvent.HTTP_STATUS, onHttpStatus );
		loader.addEventListener( Event.COMPLETE, onSuccess );
		loader.addEventListener( IOErrorEvent.IO_ERROR, onError );
		loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError );
		
		loader.load( request );
	}
}
