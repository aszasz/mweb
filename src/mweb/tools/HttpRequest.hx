package mweb.tools;

@:forward abstract HttpRequest(IHttpRequestData) from IHttpRequestData
{
	@:extern inline public function new(data)
	{
		this = data;
	}

	@:from inline public static function fromWeb(cls:LikeWeb):HttpRequest
	{
		return new WebRequest(cls);
	}

	public static function fromData(method:String, uri:String, ?params:Map<String,Array<String>>):HttpRequest
	{
		return new HttpRequestStatic(method,uri,params == null ? new Map() : params);
	}

	public function withURI(uri:String)
	{
		return new HttpRequestStatic(this.getMethod(),uri,this.getParamsData());
	}

	@:allow(mweb.tools) static function splitArgs(data:String, into:Map<String,Array<String>>)
	{
		if (data == null || data.length == 0)
			return;
		for ( part in data.split("&") )
		{
			var i = part.indexOf("=");
			var k = part.substr(0, i);
			var v = part.substr(i + 1);
			if ( v != "" )
				v = StringTools.urlDecode(v);
			var data = into[k];
			if (data == null)
			{
				into[k] = data = [];
			}
			data.push(v);
		}
	}
}

interface IHttpRequestData
{
	/**
		Should return the method (verb) used by the request - values like GET/POST
	 **/
	public function getMethod():String;

	/**
		Should return the URI queried by the HTTP request
	 **/
	public function getUri():String;

	/**
		Should return a String containing the parameters.
		It is advised that as a security measure on a non-GET request, only the parameters passed
		through the body of the message are sent here.
	 **/
	public function getParamsData():Map<String,Array<String>>;
}

class HttpRequestStatic implements IHttpRequestData
{
	var method:String;
	var uri:String;
	var params:Map<String,Array<String>>;

	public function new(method,uri,params)
	{
		this.method = method;
		this.uri = uri;
		this.params = params;
	}

	/**
		Should return the method (verb) used by the request - values like GET/POST
	 **/
	public function getMethod():String
	{
		return method;
	}

	/**
		Should return the URI queried by the HTTP request
	 **/
	public function getUri():String
	{
		return uri;
	}

	/**
		Should return a String containing the parameters.
		It is advised that as a security measure on a non-GET request, only the parameters passed
		through the body of the message are sent here.
	 **/
	public function getParamsData():Map<String,Array<String>>
	{
		return params;
	}
}

private typedef LikeWeb = {
	function getMethod():String;
	function getURI():String;
	function getParamsString():String;
	function getPostData():String;
	function getClientHeader(k:String):Null<String>;
}

private class WebRequest implements IHttpRequestData
{
	var web:LikeWeb;
	public function new(web)
	{
		this.web = web;
	}

	public function getMethod():String
	{
		var method = web.getMethod();

		if (method.toLowerCase() != "get")
		{
			var h = web.getClientHeader('X-Http-Method-Override');
			if (h != null) switch (h.toLowerCase()) {
				case 'delete' | 'patch' | 'put':
					return h.toUpperCase();
				case _:
			}
		}
		return method;
	}

	public function getUri():String
	{
		return web.getURI();
	}

	public function getParamsData():Map<String,Array<String>>
	{
		var verb = web.getMethod();
		var args = new Map();

		switch(verb.toLowerCase())
		{
			case "get":
				HttpRequest.splitArgs( StringTools.replace(web.getParamsString(), ';', '&'), args );
			case _:
				HttpRequest.splitArgs( web.getPostData(), args );
		}

		return args;
	}
}
