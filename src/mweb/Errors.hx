package mweb;

enum DecoderError
{
	TypeNotFound(type:String);
	DecoderNotFound(type:String);
}

enum RequestError
{
	InvalidRequest(message:String);
}