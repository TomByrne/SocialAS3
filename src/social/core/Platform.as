package social.core
{
	import flash.utils.Dictionary;
	
	import org.osflash.signals.Signal;
	
	import social.social;
	import social.auth.IAuth;
	import social.auth.TokenSaver;
	import social.desc.ArgDesc;
	import social.desc.CallDesc;
	import social.desc.PropDesc;
	import social.gateway.IGateway;
	import social.util.StateObject;
	import social.util.closure;
	import social.web.IWebView;
	

	public class Platform
	{
		use namespace social;

		protected static function a(name:String, desc:String, optional:Boolean=false, def:*=null, type:Class = null):ArgDesc{
			return new ArgDesc(name, desc, optional, def, type);
		}
		
		public function get label():String{
			return _platformId;
		}
		
		public function get stateChanged():Signal{
			return _stateObj.stateChanged;
		}
		public function get state():String{
			return _stateObj.state;
		}
		
		public function get manageSession():Boolean{
			return _manageSession;
		}
		public function set manageSession(value:Boolean):void{
			if(_manageSession == value)return;
			_manageSession = value;
			if(_manageSession){
				if(!_tokenSaver)_tokenSaver = new TokenSaver(_platformId, _auth);
				_tokenSaver.active = true;
			}else{
				_tokenSaver.active = false;
			}
		}
		
		public function get accessToken():String{
			return _auth.accessToken;
		}
		public function set accessToken(value:String):void{
			_auth.accessToken = value;
		}
		
		public function get pendingAuth():Boolean{
			return _auth.pendingAuth;
		}
		public function get props():Vector.<PropDesc>{
			return _props;
		}
		public function get calls():Vector.<CallDesc>{
			return _callList;
		}
		
		protected var _auth:IAuth;
		private var _stateObj:StateObject;
		private var _manageSession:Boolean;
		private var _tokenSaver:TokenSaver;
		private var _gateways:Dictionary;
		private var _calls:Dictionary;
		private var _callList:Vector.<CallDesc>;
		private var _props:Vector.<PropDesc>;
		private var _propLookup:Dictionary;
		private var _platformId:String;
		private var _webView:IWebView;
		
		public function Platform(platformId:String, auth:IAuth) {
			
			_platformId = platformId;
			_stateObj = new StateObject([PlatformState.STATE_UNAUTHENTICATED, PlatformState.STATE_AUTHENTICATING, PlatformState.STATE_AUTHENTICATED], PlatformState.STATE_UNAUTHENTICATED);
			
			_gateways = new Dictionary();
			_calls = new Dictionary();
			_callList = new Vector.<CallDesc>();
			_props = new Vector.<PropDesc>();
			_propLookup = new Dictionary();
			
			_auth = auth;
			_auth.accessTokenChanged.add(onTokenChanged);
			manageSession = true;
		}
		public function setWebView(webView:IWebView):void{
			_webView = webView;
			for(var i:* in _gateways){
				var gateway:IGateway = _gateways[i];
				gateway.setWebView(_webView);
			}
		}
		
		protected function addProp(name:String, desc:String, optional:Boolean=false, def:*=null):void
		{
			var prop:PropDesc = new PropDesc(name, desc, optional, def);
			_props.push(prop);
			_propLookup[name] = prop;
		}
		
		public function setProp(name:String, value:*):void{
			var prop:PropDesc = _propLookup[name];
			prop.value = value;
		}
		
		
		social function addGateway(id:String, gateway:IGateway):void
		{
			_gateways[id] = gateway;
			if(_webView)gateway.setWebView(_webView);
		}
		
		social function addCall(gatewayId:String, callId:String, availableState:String, args:Array, url:IUrlProvider, desc:String = null, resultHandler:Function=null, urlTokens:Object=null, protocol:String=null):void
		{
			if(urlTokens){
				var proxy:UrlProxy = new UrlProxy(url);
				for(var i:* in urlTokens){
					proxy.setToken(i, urlTokens[i]);
				}
				url = proxy;
			}
			var callDesc:CallDesc = new CallDesc(gatewayId, callId, availableState, args, url, desc, resultHandler, protocol);
			_calls[callId] = callDesc;
			_callList.push(callDesc);
		}
		protected function onLogout(success:*, fail:*, onComplete:Function=null):void
		{
			_stateObj.state = PlatformState.STATE_UNAUTHENTICATED;
			_auth.accessToken = null;
			if(fail){
				if(onComplete!=null)onComplete(null, true);
			}else{
				if(onComplete!=null)onComplete(true, null);
			}
		}
		public function doMultiCall(calls:Array, onComplete:Function=null):void
		{
			var finished:int = 0;
			var results:Array = [];
			var onCompleteHandler:Function = function(success:*, fail:*, index:int):void{
				++finished;
				results[index] = {success:success, fail:fail};
				if(finished==calls.length && onComplete!=null)onComplete(results);
			}
			for(var i:int=0; i<calls.length; ++i){
				var callObj:Object = calls[i];
				doCall(callObj.id, callObj.args, closure(onCompleteHandler, [i], true));
			}
		}
		public function doCall(callId:String, argVals:Object, onComplete:Function=null):void
		{
			for each(var prop:PropDesc in _props){
				if(!prop.optional && (prop.value || prop.defaultValue)==null){
					throw new Error("Property "+prop.name+" must be set before calls can be made.");
				}
			}
			
			var callDesc:CallDesc = _calls[callId];
			for each(var arg:ArgDesc in callDesc.args){
				if(!argVals.hasOwnProperty(arg.name)){
					if(!arg.optional){
						throw new Error("Argument "+arg.name+" must be provided.");
					}else{
						argVals[arg.name] = arg.def;
					}
				}
			}
			
			if(callDesc.resultHandler!=null){
				onComplete = closure(callDesc.resultHandler, [onComplete], true);
			}
			var gateway:IGateway = _gateways[callDesc.gatewayId];
			gateway.doRequest(callDesc.url, argVals, callDesc.protocol, onComplete);
		}
		public function getCallUrl(callId:String, argVals:Object):String
		{
			for each(var prop:PropDesc in _props){
				if(!prop.optional && (prop.value || prop.defaultValue)==null){
					throw new Error("Property "+prop.name+" must be set before calls can be made.");
				}
			}
			
			var callDesc:CallDesc = _calls[callId];
			for each(var arg:ArgDesc in callDesc.args){
				if(!argVals.hasOwnProperty(arg.name)){
					if(!arg.optional){
						throw new Error("Argument "+arg.name+" must be provided.");
					}else{
						argVals[arg.name] = arg.def;
					}
				}
			}
			var gateway:IGateway = _gateways[callDesc.gatewayId];
			return gateway.buildUrl(callDesc.url, argVals, callDesc.protocol);
		}
		
		private function onTokenChanged():void
		{
			if(_auth.accessToken){
				_stateObj.state = PlatformState.STATE_AUTHENTICATED;
			}else{
				_stateObj.state = PlatformState.STATE_UNAUTHENTICATED;
			}
			
		}
		
		private function onOAuthComplete(success:*, fail:*, onComplete:Function):void
		{
			if(success){
				_stateObj.state = PlatformState.STATE_AUTHENTICATED;
				if(onComplete!=null)onComplete(accessToken, null);
			}else{
				_stateObj.state = PlatformState.STATE_UNAUTHENTICATED;
				if(onComplete!=null)onComplete(null, {});
			}
		}
		
		public function cancelAuth():void{
			_auth.cancelAuth();
		}
		
	}
}