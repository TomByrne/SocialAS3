package social.fb
{
	import social.social;
	import social.core.PlatformState;
	
	/**
	 * This is a Facebook API for use in conjuction with the distriqt Facebook API
	 * Native Extension. This adds SSO support for mobile platforms. If SSO is
	 * unavailable this class reverts to the regular web authentication behaviour
	 * (as is used by the simpler Facebook class).
	 * 
	 * Get the extension here:
	 * http://distriqt.com/product/air-native-extensions/facebookapi
	 * 
	 */
	public class FacebookMobileDistriqt extends AbsFacebook
	{
		use namespace social;
		
		private var _fbMobileAuth:FacebookMobileAuth;
		
		public function FacebookMobileDistriqt(devKey:String, permissions:Array, apiVersion:String=null, castObjects:Boolean=true)
		{
			if(FacebookMobileAuth.isSupported()){
				_fbMobileAuth = new FacebookMobileAuth(devKey, permissions);
			}
			super("FacebookMobileDistriqt", permissions, apiVersion, castObjects, _fbMobileAuth);
			
			if(_fbMobileAuth){
				_platform.addGateway(FacebookPlatform.GATEWAY_OAUTH, _fbMobileAuth);
				_platform.addCall(FacebookPlatform.GATEWAY_OAUTH, FacebookPlatform.CALL_AUTH, PlatformState.STATE_UNAUTHENTICATED, [], null, "Revives session if possible, otherwise displays login view.", null, {doAuth:true});
			}
		}
		
		override public function init(clientId:String, redirectUrl:String):void{
			super.init(clientId, redirectUrl);
			if(_fbMobileAuth)_fbMobileAuth.init(clientId);
		}
	}
}

import com.distriqt.extension.facebookapi.FacebookAPI;
import com.distriqt.extension.facebookapi.events.FacebookAPIEvent;

import org.osflash.signals.Signal;

import social.auth.IAuth;
import social.core.IUrlProvider;
import social.gateway.IGateway;
import social.web.IWebView;

class FacebookMobileAuth implements IAuth, IGateway
{
	public static function isSupported():Boolean{
		return FacebookAPI.isSupported;
	}
	
	public static const URL_ACCESS_TOKEN			:String		= "${accessToken}";
	public static const TOKEN_SEARCHER				:RegExp		= /access_token=([\d\w\.\-_]*)/;
	public static const ERROR_SEARCHER				:RegExp		= /error=([\d\w\.\-_]*)/;
	
	public function get accessTokenChanged():Signal{
		if(!_accessTokenChanged)_accessTokenChanged = new Signal();
		return _accessTokenChanged;
	}
	
	private var _urlProvider			:IUrlProvider;
	
	private var _accessToken			:String;
	private var _accessTokenChanged		:Signal;
	
	private var _urlScopeChecker		:Function;
	
	private var _pendingAuth			:Boolean;
	private var _onCompletes			:Array;
	private var _tokenTested			:Boolean;
	private var _showImmediately:Boolean;
	
	private var _permissions:Array;
	private var _facebookMobile:FacebookAPI;
	private var _clientId:String;
	
	
	public function FacebookMobileAuth(devKey:String, permissions:Array)
	{
		_permissions = permissions;
		_onCompletes = [];
		FacebookAPI.init(devKey);
		_facebookMobile = FacebookAPI.service;
		
		_facebookMobile.addEventListener( FacebookAPIEvent.SESSION_OPENED, session_openedHandler );
		_facebookMobile.addEventListener( FacebookAPIEvent.SESSION_CLOSED, session_closedHandler );
		_facebookMobile.addEventListener( FacebookAPIEvent.SESSION_OPEN_DISABLED, session_openDisabledHandler );
		_facebookMobile.addEventListener( FacebookAPIEvent.SESSION_OPEN_ERROR, session_openErrorHandler );
	}
	
	public function init(clientId:String):void
	{
		_clientId = clientId;
		_facebookMobile.initialiseApp(_clientId);
		if(_facebookMobile.isSessionOpen()){
			accessToken = _facebookMobile.getAccessToken();
		}
	}
	public function setWebView(webView:IWebView):void{
		//ignore
	}
	public function buildUrl( urlProvider:IUrlProvider, args:Object, protocol:String ):String{
		return urlProvider.url;
	}
	public function doRequest( urlProvider:IUrlProvider, args:Object, protocol:String, onComplete:Function=null ):void
	{
		if(onComplete!=null)_onCompletes.push(onComplete);
		
		_pendingAuth = true;
		_facebookMobile.createSession(_permissions, true, false);
		
	}
	private function session_openedHandler(e:FacebookAPIEvent):void
	{
		_pendingAuth = false;
		_accessToken = _facebookMobile.getAccessToken();
		if(_accessTokenChanged)_accessTokenChanged.dispatch();
		callComplete(true, null);
	}
	private function session_closedHandler(e:FacebookAPIEvent):void
	{
		accessToken = null;
	}
	private function session_openDisabledHandler(e:FacebookAPIEvent):void
	{
		callComplete(null, true);
	}
	private function session_openErrorHandler(e:FacebookAPIEvent):void
	{
		callComplete(null, e);
	}
	
	public function cancelAuth():void
	{
		if(!_pendingAuth)return;
		callComplete(null, true);
	}
	
	private function callComplete(success:*, fail:*):void
	{
		if(_onCompletes.length){
			for each(var onComplete:Function in _onCompletes){
				onComplete(success, fail);
			}
			_onCompletes = [];
		}
	}
	
	public function markTokenWorks():void
	{
		_tokenTested = true;
	}
	
	public function get accessToken():String
	{
		return _accessToken;
	}
	
	public function set accessToken(value:String):void
	{
		_accessToken = value;
		_tokenTested = false;
		if(!value && _pendingAuth){
			cancelAuth();
			_pendingAuth = false;
		}
		if(!value && _facebookMobile.isSessionOpen()){
			_facebookMobile.closeSession(true);
		}
		if(_accessTokenChanged)_accessTokenChanged.dispatch();
	}
	
	public function get pendingAuth():Boolean
	{
		return _pendingAuth;
	}
	
	public function get tokenTested():Boolean
	{
		return _tokenTested;
	}
}