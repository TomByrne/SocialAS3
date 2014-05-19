package social.gateway
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import social.auth.IAuth;
	import social.core.IUrlProvider;
	import social.util.closure;
	import social.web.IWebView;

	public class HttpLoader implements IGateway
	{
		public static const PROTOCOL_GET		:String = "GET";
		public static const PROTOCOL_POST		:String = "POST";
		
		public static const URL_ENDPOINT		:String		= "${endPoint}";
		
		public static function loaderHandler(success:ByteArray, fail:*, onComplete:Function):void
		{
			if(success){
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, closure(onLoaderComplete, [onComplete], true));
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, closure(onLoaderComplete, [onComplete], true));
				loader.loadBytes(success);
			}else{
				if(onComplete!=null)onComplete(null, fail);
			}
		}
		
		private static function onLoaderComplete(e:Event, onComplete:Function):void
		{
			if(e is IOErrorEvent){
				if(onComplete!=null)onComplete(null, true);
			}else{
				var loader:Loader = (e.target as LoaderInfo).loader;
				if(onComplete!=null)onComplete(loader.content, null);
			}
		}
		
		public static function createParser(klass:Class, childParsers:Object = null, propMapper:Object=null):Function
		{
			return function(obj:Object):*{
				var ret:Object = new klass;
				fillObject(ret, obj, childParsers, propMapper);
				return ret;
			}
		}
		
		public static function createConditionalParser(conditionalParsers:Object, defKlass:*=null, childParsers:Object = null, propMapper:Object=null):Function
		{
			return function(obj:Object):*{
				var ret:Object;
				var value:*;
				for(var cond:String in conditionalParsers){
					value = getProp(obj, cond);
					if(value && value!="false"){
						ret = conditionalParsers[cond](obj);
						break;
					}
				}
				if(!ret){
					if(defKlass!=null){
						if(defKlass is Class){
							ret = new defKlass();
						}else{
							ret = defKlass(obj);
						}
					}else{
						throw new Error("No class found for response: "+obj);
					}
				}
				fillObject(ret, obj, childParsers, propMapper);
				return ret;
			}
		}
		
		private static function fillObject(ret:Object, obj:Object, childParsers:Object, propMapper:Object):void
		{
			obj["*"] = obj; // allows for splitting data definitions (e.g. User/Role)
			for(var i:String in propMapper){
				var value:* = getProp(obj, i);
				var dest:String = propMapper[i];
				if(childParsers){
					var parser:Function = childParsers[i];
					if(parser!=null && value!=null){
						value = parser(value);
					}
				}
				if(dest){
					if(dest.indexOf("()")==dest.length-2){
						ret[dest.substr(0, dest.length-2)](value);
					}else{
						ret[dest] = value;
					}
				}
			}
		}
		
		private static function getProp(obj:Object, propName:String):*
		{
			var pathParts:Array = propName.split(".");
			for(var i:int=0; i<pathParts.length; ++i){
				obj = obj[pathParts[i]];
				if(!obj)return null;
			}
			return obj;
		}
		public static function createArrParser(objParser:Function):Function
		{
			return function(arr:Object):Array{
				var ret:Array = [];
				if(arr is Array){
					for each(var obj:Object in arr){
						ret.push(objParser(obj));
					}
				}else{
					for(var i:String in arr){
						ret.push(objParser(arr[i]));
					}
				}
				return ret;
			}
		}
		public static function createHandler(parser:Function=null, dataProp:String=null):Function
		{
			return function(success:String, fail:*, onComplete:Function):void{
				if(fail){
					if(onComplete!=null)onComplete(null, fail || true);
				}else{
					try{
						var data:* = JSON.parse( success );
					}catch(e:Error){}
					if(data==null){
						onComplete( null, "JSON parsing error");
						return;
					}
					if(dataProp)data = data[dataProp];
					var res:* = parser!=null?parser( data ):data;
					if(onComplete!=null){
						onComplete( res || true, null);
					}
				}
			}
		}
		
		
		public function get oauth():IAuth{
			return _oauth
		}
		public function set oauth(value:IAuth):void{
			if(_oauth==value)return;
			_oauth = value;
		}
		
		
		private var _oauth:IAuth;
		private var _defaultProtocol:String;
		private var _dataFormat:String;
		
		public function HttpLoader(oauth:IAuth=null, dataFormat:String=URLLoaderDataFormat.TEXT, defaultProtocol:String = PROTOCOL_GET)
		{
			this.oauth = oauth;
			_defaultProtocol = defaultProtocol;
			_dataFormat = dataFormat;
		}
		
		public function setWebView(webView:IWebView):void{
			// ignore
		}
		
		public function buildUrl( urlProvider:IUrlProvider, args:Object, protocol:String ):String{
			var url:String = urlProvider.url;
			for ( var prop:* in args )
			{
				var val:* = args[prop]; 
				var token:String = "${"+prop+"}";
				if(url.indexOf(token)!=-1){
					url = url.replace(token, val);
					val = null;
				}
				if(val==null || val==-1 || (typeof(val)=="number" && isNaN(val))){
					delete args[prop];
				}
			}
			
			if(!protocol)protocol = _defaultProtocol;
			var params:String = "";
			if (protocol == "GET" )
			{
				if ( args )
				{
					for ( prop in args )
					{
						params += "&"+prop+"="+args[prop]; 
					}
				}
			}
			return url + params;
		}
		
		public function doRequest( urlProvider:IUrlProvider, args:Object, protocol:String, onComplete:Function=null ):void
		{
			var loader:URLLoader = new URLLoader();
			loader.addEventListener( Event.COMPLETE, closure(onDataSuccess, [onComplete], true));
			loader.addEventListener( IOErrorEvent.IO_ERROR, closure(onDataFailure, [onComplete], true));
			
			var request:URLRequest;
			var urlVars:URLVariables;
			
			var prop:String;
			var val:*;
			
			var url:String = urlProvider.url;
			for ( prop in args )
			{
				val = args[prop]; 
				var token:String = "${"+prop+"}";
				if(url.indexOf(token)!=-1){
					url = url.replace(token, val);
					val = null;
				}
				if(val==null || val==-1 || (typeof(val)=="number" && isNaN(val))){
					delete args[prop];
				}
			}
			
			if(!protocol)protocol = _defaultProtocol;
			if (protocol == "GET" )
			{
				var params:String = "";
				if ( args )
				{
					for ( prop in args )
					{
						params += "&"+prop+"="+args[prop]; 
					}
				}
				request = new URLRequest( url + params );
			}
				
			else if ( protocol == "POST" )
			{
				urlVars = new URLVariables();
				
				if ( args )
				{
					for ( prop in args )
					{
						urlVars[prop] = args[prop]; 
					}
				}
				
				request	= new URLRequest( urlProvider.url );
				request.data = urlVars;
					
			}
			loader.dataFormat = _dataFormat;
			request.method = protocol;
			trace( protocol +" - "+loader.dataFormat+ " - request: " + request.url );
			
			loader.load( request );
		}
		private function onDataSuccess(e:Event, onComplete:Function):void{
			_oauth.markTokenWorks();
			var loader:URLLoader = (e.target as URLLoader);
			if(onComplete!=null)onComplete(loader.data, null);
		}
		private function onDataFailure(e:IOErrorEvent, onComplete:Function):void{
			if(!_oauth.tokenTested){
				_oauth.accessToken = null;
			}
			if(onComplete!=null)onComplete(null, e);
		}
	}
}