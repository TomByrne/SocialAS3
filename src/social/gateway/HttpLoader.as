package social.gateway
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import social.auth.IAuth;
	import social.core.IUrlProvider;
	import social.util.closure;
	import social.web.IWebView;

	public class HttpLoader implements IGateway
	{
		public static const PROTOCOL_GET		:String = "GET";
		public static const PROTOCOL_POST		:String = "POST";
		public static const PROTOCOL_DELETE		:String = "DELETE";
		
		private static var _loaders:Vector.<URLLoader> = new Vector.<URLLoader>();
		private static function takeLoader():URLLoader{
			if(_loaders.length)return _loaders.pop();
			else return new URLLoader();
		}
		private static function returnLoader(value:URLLoader):void{
			_loaders.push(value);
		}
		
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
				if(value==null)continue;
				
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
		public static function createHandler(parser:Function=null, dataProp:String=null, errorResponseCheck:Function=null):Function
		{
			if(errorResponseCheck==null)errorResponseCheck = defaultErrorResponseCheck;
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
					if(errorResponseCheck(data)){
						onComplete( null, data);
						return;
					}
					if(dataProp)data = getProp(data, dataProp);
					var res:* = parser!=null?parser( data ):data;
					if(onComplete!=null){
						onComplete( res || true, null);
					}
				}
			}
		}
		public static function createPaginationHandler(parser:Function=null, dataProp:String=null, pagProp:String=null, errorResponseCheck:Function=null):Function
		{
			if(errorResponseCheck==null)errorResponseCheck = defaultErrorResponseCheck;
			return _createPaginationHandler(parser, dataProp, pagProp, errorResponseCheck);
		}
		private static function _createPaginationHandler(parser:Function=null, dataProp:String=null, pagProp:String=null, errorResponseCheck:Function=null, addTo:Array=null, onMainComplete:Function=null):Function
		{
			return function(success:String, fail:*, onComplete:Function=null):void{
				if(!addTo)addTo = [];
				
				if(onMainComplete!=null)onComplete = onMainComplete;
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
					if(errorResponseCheck(data)){
						onComplete( null, data);
						return;
					}
					var nextPage:String;
					if(pagProp)nextPage = getProp(data, pagProp);
					if(dataProp)data = getProp(data, dataProp);
					addTo = addTo.concat(data);
					if(!data.length || !nextPage){
						var res:* = parser!=null?parser( addTo ):addTo;
						if(onComplete!=null){
							onComplete( res || true, null);
						}
					}else{
						loadPage(nextPage, _createPaginationHandler(parser, dataProp, pagProp, errorResponseCheck, addTo, onComplete));
					}
				}
			}
		}
		
		private static function defaultErrorResponseCheck(response:Object):Boolean{
			return response.error!=null;
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
		
		private var _loaderToComplete:Dictionary = new Dictionary();
		public function doRequest( urlProvider:IUrlProvider, args:Object, protocol:String, onComplete:Function=null ):void
		{
			var loader:URLLoader = takeLoader();
			_loaderToComplete[loader] = onComplete;
			loader.addEventListener( Event.COMPLETE, onDataSuccess);
			loader.addEventListener( IOErrorEvent.IO_ERROR, onDataFailure);
			loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onDataFailure);
			
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
			if ( protocol == "POST" )
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
				
			}else{
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
			
			loader.dataFormat = _dataFormat;
			request.method = protocol;
			trace( protocol +" - "+loader.dataFormat+ " - request: " + request.url );
			
			loader.load( request );
		}
		private function onDataSuccess(e:Event):void{
			var onComplete:Function = _loaderToComplete[e.target];
			_oauth.markTokenWorks();
			var loader:URLLoader = (e.target as URLLoader);
			if(onComplete!=null)onComplete(loader.data, null);
			cleanUp(loader);
		}
		private function onDataFailure(e:Event):void{
			var onComplete:Function = _loaderToComplete[e.target];
			if(!_oauth.tokenTested){
				_oauth.accessToken = null;
			}
			if(onComplete!=null)onComplete(null, e);
			cleanUp(e.target as URLLoader);
		}
		
		private function cleanUp(loader:URLLoader):void
		{
			delete _loaderToComplete[loader];
			loader.close();
			loader.removeEventListener( Event.COMPLETE, onDataSuccess);
			loader.removeEventListener( IOErrorEvent.IO_ERROR, onDataFailure);
			loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onDataFailure);
			returnLoader(loader);
		}
		
		
		
		/// PAGE LOADER
		private static var _pageLoaderToComplete:Dictionary = new Dictionary();
		private static function loadPage( pageUrl:String, onComplete:Function=null ):void
		{
			var loader:URLLoader = takeLoader();
			_pageLoaderToComplete[loader] = onComplete;
			loader.addEventListener( Event.COMPLETE, onDataSuccess);
			loader.addEventListener( IOErrorEvent.IO_ERROR, onDataFailure);
			loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onDataFailure);
			
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			trace( loader.dataFormat+ " - request: " + pageUrl );
			loader.load( new URLRequest(pageUrl) );
		}
		private static function onDataSuccess(e:Event):void{
			var onComplete:Function = _pageLoaderToComplete[e.target];
			var loader:URLLoader = (e.target as URLLoader);
			if(onComplete!=null)onComplete(loader.data, null);
			cleanUp(loader);
		}
		private static function onDataFailure(e:Event):void{
			var onComplete:Function = _pageLoaderToComplete[e.target];
			if(onComplete!=null)onComplete(null, e);
			cleanUp(e.target as URLLoader);
		}
		private static function cleanUp(loader:URLLoader):void{
			delete _pageLoaderToComplete[loader];
			loader.close();
			loader.removeEventListener( Event.COMPLETE, onDataSuccess);
			loader.removeEventListener( IOErrorEvent.IO_ERROR, onDataFailure);
			loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onDataFailure);
			returnLoader(loader);
		}
	}
}