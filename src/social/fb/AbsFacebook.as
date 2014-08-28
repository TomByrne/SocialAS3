package social.fb
{
	import org.osflash.signals.Signal;
	
	import social.social;
	import social.auth.IAuth;
	import social.web.IWebView;

	public class AbsFacebook
	{
		use namespace social;
		
		social function get platform():FacebookPlatform
		{
			return _platform;
		}
		
		
		public function get manageSession():Boolean
		{
			return _platform.manageSession;
		}
		public function set manageSession(value:Boolean):void
		{
			_platform.manageSession = value;
		}
		
		public function get accessToken():String
		{
			return _platform.accessToken;
		}
		public function set accessToken(value:String):void
		{
			_platform.accessToken = value;
		}
		
		public function get stateChanged():Signal{
			return _platform.stateChanged;
		}
		public function get state():String{
			return _platform.state;
		}
		
		
		protected var _platform:FacebookPlatform
		
		public function AbsFacebook(name:String, permissions:Array, auth:IAuth=null)
		{
			_platform = new FacebookPlatform(name, permissions, auth);
		}
		public function setWebView(webView:IWebView):void{
			_platform.setWebView(webView);
		}
		
		public function init(clientId:String, redirectUrl:String):void
		{
			_platform.setProp(FacebookPlatform.URL_CLIENT_ID, clientId);
			_platform.setProp(FacebookPlatform.URL_REDIRECT_URL, redirectUrl);
		}
		public function authenticate(showImmediately:Boolean = true, onComplete:Function=null):void
		{
			_platform.doCall(FacebookPlatform.CALL_AUTH, {showImmediately:showImmediately}, onComplete);
		}
		public function cancelAuth():void{
			_platform.cancelAuth();
		}
		public function logout(onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_LOGOUT, {}, onComplete);
		}
		public function revokePermissions(onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_LOGOUT, {}, onComplete);
		}
		
		
		public function getSelf( onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_SELF, {}, onComplete);
		}
		public function getFriends( onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_FRIENDS, {}, onComplete);
		}
		
		public function getAlbums( onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_ALBUMS, {}, onComplete);
		}
		
		public function getPicture( size:String=null, width:int = -1, height:int = -1, onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_PICTURE, {"size":size, "width":width, "height":height}, onComplete);
		}
		
		public function getPictureInfo( size:String=null, width:int = -1, height:int = -1, onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_PICTURE_INFO, {"size":size, "width":width, "height":height}, onComplete);
		}
		
		public function getAlbum( albumId:String, onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_ALBUM, {objectId:albumId}, onComplete);
		}
		
		public function getAlbumPicture( albumId:String, onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_ALBUM_PICTURE, {objectId:albumId}, onComplete);
		}
		
		public function getAlbumPhotos( albumId:String, onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_ALBUM_PHOTOS, {objectId:albumId}, onComplete);
		}
		
		public function getUserAlbums( userId:String, onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_USER_ALBUMS, {userId:userId}, onComplete);
		}
		
		public function getUserPicture( userId:String, size:String=null, width:int = -1, height:int = -1, onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_USER_PICTURE, {userId:userId, "size":size, "width":width, "height":height}, onComplete);
		}
		
		public function getUserPictureInfo( userId:String, size:String=null, width:int = -1, height:int = -1, onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_USER_PICTURE_INFO, {userId:userId, "size":size, "width":width, "height":height}, onComplete);
		}
		
		public function fql( fql:String, onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_FQL, {q:fql}, onComplete);
		}
		public function fqlMulti( fql:FqlMultiQuery, onComplete:Function=null):void{
			_platform.doCall(FacebookPlatform.CALL_FQL_MULTI, {q:fql.toString()}, onComplete);
		}
		
		// URL generators
		
		public function getPictureUrl( size:String=null, width:int = -1, height:int = -1):String{
			return _platform.getCallUrl(FacebookPlatform.CALL_PICTURE, {"size":size, "width":width, "height":height});
		}
		
		public function getUserPictureUrl( userId:String, size:String=null, width:int = -1, height:int = -1):String{
			return _platform.getCallUrl(FacebookPlatform.CALL_USER_PICTURE, {userId:userId, "size":size, "width":width, "height":height});
		}
	}
}