package com.playfab;

abstract PlayFabMap<T>(Dynamic)
{
	public inline function new()
	{
		this = {};
	}
	
	@:arrayAccess
	public inline function get(key:String):T
	{
		return Reflect.field(this, key);
	}
	
	@:arrayAccess
	public inline function set(key:String, value:T):T
	{
		Reflect.setField(this, key, value);
		return value;
	}
	
	public inline function exists(key:String):Bool
	{
		return Reflect.hasField(this, key);
	}
	
	public inline function delete(key:String):Void
	{
		return Reflect.deleteField(this, key);
	}
}
