package social.fb
{
	import com.freshplanet.ane.AirFacebook.Facebook;
	
	import social.social;
	import social.core.PlatformState;
	
	/**
	 * This is a Facebook API for use in conjuction with the freshplanet facebook
	 * Native Extension. This adds SSO support for mobile platforms. If SSO is
	 * unavailable this class reverts to the regular web authentication behaviour
	 * (as is used by the simpler Facebook class).
	 * 
	 * Unfortunately, as of 12/06/2014 this Native Extension doesn't play well with
	 * other Extensions.
	 * 
	 * Get the extension here:
	 * https://github.com/freshplanet/ANE-Facebook
	 * 
	 */
	public class FacebookMobileFP extends AbsFacebook
	{
		use namespace social;
		
		private var _fbMobileAuth:FacebookMobileAuth;
		
		public function FacebookMobileFP(permissions:Array, apiVersion:String=null, castObjects:Boolean=true, allowWebDialog:Boolean=true)
		{
			if(FacebookMobileAuth.isSupported() && (allowWebDialog || com.freshplanet.ane.AirFacebook.Facebook.getInstance().canPresentShareDialog())){
				_fbMobileAuth = new FacebookMobileAuth(permissions);
			}
			super("FacebookMobileFP", permissions, apiVersion, castObjects, _fbMobileAuth);
			
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
import com.freshplanet.ane.AirFacebook.Facebook;

import org.osflash.signals.Signal;

import social.auth.IAuth;
import social.core.IUrlProvider;
import social.fb.FacebookPermissions_v2;
import social.gateway.IGateway;
import social.web.IWebView;

class FacebookMobileAuth implements IAuth, IGateway
{
	public static function isSupported():Boolean{
		return Facebook.isSupported;
	}
	private static var PUBLISH_PERMS				:Array;{
		PUBLISH_PERMS = [FacebookPermissions_v2.manage_notifications,FacebookPermissions_v2.manage_pages,FacebookPermissions_v2.publish_actions,FacebookPermissions_v2.publish_stream,FacebookPermissions_v2.rsvp_event];
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
	
	private var _facebookMobile			:Facebook;
	private var _permissions:Array;
	
	
	public function FacebookMobileAuth(permissions:Array)
	{
		
		_permissions = permissions;
		_onCompletes = [];
		
		_facebookMobile = Facebook.getInstance();
	}
	
	public function init(clientId:String):void
	{
		_facebookMobile.init(clientId);
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
		if(hasPublishPermission(_permissions)){
			_facebookMobile.openSessionWithPublishPermissions(_permissions, onAuthComplete);
		}else{
			_facebookMobile.openSessionWithReadPermissions(_permissions, onAuthComplete);
		}
	}
	
	private function hasPublishPermission(perms:Array):Boolean
	{
		for each(var perm:String in perms){
			if(PUBLISH_PERMS.indexOf(perm)!=-1)return true;
		}
		return false;
	}
	
	private function onAuthComplete(success:Boolean, userCancelled:Boolean, error:String):void
	{
		_pendingAuth = false;
		_accessToken = _facebookMobile.accessToken;
		if(_accessTokenChanged)_accessTokenChanged.dispatch();
		callComplete(success?success:null, error);
		
		if(success){
			_facebookMobile.requestWithGraphPath("me/albums", null, "GET", onTestAlbums);
		}
	}
	
	private function onTestAlbums(... params):void
	{
		params = params;
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
		var tokenWas:String = _accessToken;
		_accessToken = value;
		_tokenTested = false;
		if(!value && _pendingAuth){
			cancelAuth();
			_pendingAuth = false;
		}
		if(tokenWas && !value)_facebookMobile.closeSessionAndClearTokenInformation();
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