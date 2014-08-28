package social.web
{
	import flash.display.Stage;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.LocationChangeEvent;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	import flash.utils.Dictionary;
	
	import mx.resources.ResourceBundle;
	
	import org.osflash.signals.Signal;

	public class StageWebViewProxy implements IWebView
	{
		private var importResourceBundle:ResourceBundle; // to force inclusion in SWC
		
		[Embed(source="../../../embed/injection.js",mimeType="application/octet-stream")]
		private static const INJECTION_CLASS:Class;
		private static var INJECTION:String;
		{
			INJECTION = new INJECTION_CLASS();
		}
		
		private static const COMMUNICATION_PROTOCOL:String = "adobe-air-comm:";
		private static const COMMUNICATION_DELIMITER:String = "|";
		
		public static var consoleLog:Function = function():void{
			trace.apply(null, ["console.log: "].concat(arguments));
		}
		public static var windowOnError:Function = function():void{
			trace.apply(null, ["window.onerror: "].concat(arguments));
		}
		
		public function get loadComplete():Signal{
			if(!_loadComplete)_loadComplete = new Signal();
			return _loadComplete;
		}
		public function get locationChanged():Signal{
			if(!_locationChanged)_locationChanged = new Signal();
			return _locationChanged;
		}
		public function get isLoadingChanged():Signal{
			if(!_isLoadingChanged)_isLoadingChanged = new Signal();
			return _isLoadingChanged;
		}
		public function get isPopulatedChanged():Signal{
			if(!_isPopulatedChanged)_isPopulatedChanged = new Signal();
			return _isPopulatedChanged;
		}
		
		public function get location():String{
			return _location || _webView.location;
		}
		
		public function get viewPort():Rectangle{
			return _webView.viewPort;
		}
		public function set viewPort(value:Rectangle):void{
			_webView.viewPort = value;
		}
		
		public function get stage():Stage{
			return _stage;
		}
		public function set stage(value:Stage):void{
			_stage = value;
			if(_webView.stage || (_isPopulated || !_isLoading))_webView.stage = value;
		}
		
		public function get isLoading():Boolean{
			return _isLoading;
		}
		
		public function get isPopulated():Boolean{
			return _isPopulated;
		}
		
		public function get isHistoryBackEnabled():Boolean{
			return _hasBackOverride || _webView.isHistoryBackEnabled;
		}
		
		public function get isHistoryForwardEnabled():Boolean{
			return _webView.isHistoryForwardEnabled;
		}
		
		private var _stage:Stage;
		private var _webView:StageWebView;
		private var _isLoading:Boolean;
		private var _ignoreChanges:Boolean;
		private var _isPopulated:Boolean;
		private var _location:String;
		private var _lastEvent:LocationChangeEvent;
		private var _hasBackOverride:Boolean;
		
		private var _loadComplete:Signal;
		private var _locationChanged:Signal;
		private var _isLoadingChanged:Signal;
		private var _isPopulatedChanged:Signal;
		private var _callMap:Dictionary;
		
		public function StageWebViewProxy(stage:Stage=null, viewPort:Rectangle=null){
			_stage = stage;
			_webView = new StageWebView();
			if(viewPort)this.viewPort = viewPort;
			
			
			_webView.addEventListener( Event.COMPLETE, onLoadSuccess );
			_webView.addEventListener(ErrorEvent.ERROR, onLoadError);
			_webView.addEventListener(LocationChangeEvent.LOCATION_CHANGING, onLocationChange);
		}
		
		public function historyBack():void{
			_webView.historyBack();
		}
		
		public function historyForward():void{
			_webView.historyForward();
		}
		
		private function clearHistory():void{
			if(isHistoryBackEnabled || isHistoryForwardEnabled){
				var stage:Stage = _webView.stage;
				var viewport:Rectangle = _webView.viewPort;
				_webView.dispose();
				_webView.removeEventListener( Event.COMPLETE, onLoadSuccess );
				_webView.removeEventListener(ErrorEvent.ERROR, onLoadError);
				_webView.removeEventListener(LocationChangeEvent.LOCATION_CHANGING, onLocationChange);
				_webView = null;
				
				_webView = new StageWebView();
				_webView.viewPort = viewport;
				_webView.stage = stage;
				_webView.addEventListener( Event.COMPLETE, onLoadSuccess );
				_webView.addEventListener(ErrorEvent.ERROR, onLoadError);
				_webView.addEventListener(LocationChangeEvent.LOCATION_CHANGING, onLocationChange);
				
				_hasBackOverride = false;
				setIsPopulated(false);
				setIsLoading(false);	
			}
		}
		
		public function mapCall(name:String, method:Function):void{
			if(!_callMap){
				_callMap = new Dictionary();
				if(_location)setupComm();
			}
			_callMap[name] = method;
		}
		
		public function redirectConsole():void{
			mapCall("console.log", consoleLog);
		}
		
		public function redirectErrors():void{
			mapCall("window.onerror", windowOnError);
		}
		
		protected function onLocationChange(event:LocationChangeEvent):void
		{
			if(_ignoreChanges)return;
			
			_lastEvent = event;
			if(event.location.indexOf(COMMUNICATION_PROTOCOL)==0){
				// recieved communication
				var args:Array = decodeURI(event.location.substr(COMMUNICATION_PROTOCOL.length)).split(COMMUNICATION_DELIMITER);
				var method:String = args.shift();
				var call:Function = _callMap[method];
				if(call==null){
					trace("No call mapped for "+method+" call from StageWebView");
				}else{
					for(var i:int=0; i<args.length; ++i){
						var arg:String = args[i];
						if(arg=="true"){
							args[i] = true;
						}else if(arg=="false"){
							args[i] = false;
						}else{
							var firstChar:String = arg.charAt(0);
							var num:Number;
							if(firstChar=="[" || firstChar=="{"){
								args[i] = JSON.parse(arg);
							}else if((num = parseFloat(arg)).toString()==arg){
								args[i] = num;
							} // else is string
						}
					}
					call.apply(null, args);
				}
				
				cancelLocationChange();
				return;
			}
			
			_location = event.location;
			if(_locationChanged)_locationChanged.dispatch(cancelLocationChange);
		}
		
		protected function onLoadError(event:ErrorEvent):void{
			if ( null != event.text && event.text.indexOf("NSURLErrorDomain error -999") != -1 )
			{
				/* It's safe to ignore that error because is is
				returned when an asynchronous load is canceled. A Web Kit framework
				delegate will receive this error when it performs a cancel operation on a
				loading resource. Note that an NSURLConnection or NSURLDownload delegate
				will not receive this error if the download is canceled
				*/
				return;
			}
			_location = null;
			if(_ignoreChanges || !_isPopulated)return;
			
			setIsLoading(false);
			_loadComplete.dispatch(null, true);
		}
		
		protected function onLoadSuccess(event:Event):void{
			_location = null;
			if(_ignoreChanges || !_isPopulated)return;
			if(_isLoading)_webView.stage = stage;
			setIsLoading(false);
			_loadComplete.dispatch(true, null);
			
			if(_callMap)setupComm();
		}
		
		private function setupComm():void
		{
			_webView.loadURL("javascript:"+INJECTION);
			_webView.loadURL("javascript:setupComm('"+COMMUNICATION_PROTOCOL+"','"+COMMUNICATION_DELIMITER+"')");
			if(_callMap["console.log"])_webView.loadURL("javascript:redirectConsole()");
			if(_callMap["window.onerror"])_webView.loadURL("javascript:redirectErrors()");
		}
		
		public function showView(url:String, showImmediately:Boolean, clearHistory:Boolean = false):void{
			if(clearHistory)this.clearHistory();
			
			_location = null;
			setIsPopulated(true);
			setIsLoading(true);			
			_webView.loadURL(url);
			if(showImmediately)_webView.stage = _stage;
		}
		public function hideView():void{
			_location = null;
			setIsPopulated(false);
			_webView.stage = null;
			setIsLoading(false);
			_ignoreChanges = true;
			_webView.loadString("<html></html>"); // clears the view for reuse
			_hasBackOverride = true;
			_ignoreChanges = false;
		}
		
		private function setIsLoading(value:Boolean):void
		{
			if(_isLoading!=value){
				_isLoading = value;
				if(_isLoadingChanged)_isLoadingChanged.dispatch();
			}
		}
		
		private function setIsPopulated(value:Boolean):void
		{
			if(_isPopulated!=value){
				_isPopulated = value;
				if(_isPopulatedChanged)_isPopulatedChanged.dispatch();
			}
		}
		
		private function cancelLocationChange():void{
			if(_lastEvent){
				_lastEvent.preventDefault();
				_lastEvent = null;
			}
		}
	}
}