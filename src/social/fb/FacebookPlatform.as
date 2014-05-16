package social.fb
{
	import flash.net.URLLoaderDataFormat;
	
	import social.auth.oauth2.OAuth2;
	import social.core.IUrlProvider;
	import social.core.Platform;
	import social.core.PlatformState;
	import social.core.UrlProvider;
	import social.desc.ArgDesc;
	import social.fb.vo.Album;
	import social.fb.vo.Image;
	import social.fb.vo.Photo;
	import social.fb.vo.User;
	import social.gateway.HttpLoader;
	import social.util.DateParser;
	import social.web.StageWebViewProxy;

	public class FacebookPlatform extends Platform
	{
		public static const URL_CLIENT_ID				:String		= "${clientId}";
		public static const URL_REDIRECT_URL			:String		= "${redirectUrl}";
		private static const URL_PERMISSIONS			:String		= "${permissions}";
		public static const URL_OBJECT_ID				:String		= "${objectId}";
		public static const URL_USER_ID					:String		= "${userId}";
		
		private static const GATEWAY_OAUTH				:String		= "oauth";
		private static const GATEWAY_JSON				:String		= "json";
		private static const GATEWAY_IMAGE				:String		= "image";
		
		public static const CALL_AUTH					:String		= "auth";
		public static const CALL_LOGOUT					:String		= "logout";
		
		public static const CALL_FQL					:String		= "fql";
		public static const CALL_FQL_MULTI				:String		= "fqlMulti";
		
		public static const CALL_ALBUM					:String		= "album";
		public static const CALL_ALBUMS					:String		= "albums";
		public static const CALL_ALBUM_PICTURE			:String		= "albumPicture";
		public static const CALL_ALBUM_PHOTOS			:String		= "albumPhotos";
		
		public static const CALL_USER_ALBUMS			:String		= "userAlbums";
		
		public static const CALL_SELF					:String		= "self";
		public static const CALL_FRIENDS				:String		= "friends";
		
		protected static const AUTH_URL:String = "https://www.facebook.com/dialog/oauth?client_id="+URL_CLIENT_ID+"&redirect_uri="+URL_REDIRECT_URL+"&response_type=token&scope="+URL_PERMISSIONS;
		protected static const API_URL:String = "https://graph.facebook.com/"+HttpLoader.URL_ENDPOINT+"?access_token="+OAuth2.URL_ACCESS_TOKEN;
		protected static const LOGOUT_URL:String = "https://www.facebook.com/"+HttpLoader.URL_ENDPOINT+".php?client_id="+URL_CLIENT_ID+"&redirect_uri="+URL_REDIRECT_URL;
		
		private var _oauthUrl:UrlProvider;
		private var _callUrl:UrlProvider;
		private var _logoutUrl:UrlProvider;
		
		private var _oauth:OAuth2;
		private var _webView:StageWebViewProxy;
		
		public function FacebookPlatform(){
			
			var dateParser:Function = DateParser.parser("%G-%m-%eT%H:%M:%S+%z", true);
			
			var parseUser:Function = HttpLoader.createParser(User, {"updated_time":dateParser},
				{"id":"id", "name":"name", "birthday":"birthday", "first_name":"firstName", 
					"gender":"gender", "last_name":"lastName", "link":"link",
					"locale":"locale", "timezone":"timezone", "updated_time":"updatedTime",
					"username":"username", "verified":"verified"});
			
			var parseAlbum:Function = HttpLoader.createParser(Album, {"from":parseUser, "created_time":dateParser, "updated_time":dateParser},
				{"id":"id", "can_upload":"canUpload", "count":"count", "cover_photo":"coverPhoto",
					"created_time":"createdTime", "from":"from", "link":"link", "name":"name",
					"privacy":"privacy", "type":"type", "updated_time":"updatedTime"});
			
			var parseImage:Function = HttpLoader.createParser(Image, null,
				{"source":"source", "width":"width", "height":"height"});
			
			var parsePhoto:Function = HttpLoader.createParser(Photo, {"from":parseUser, "created_time":dateParser, "updated_time":dateParser, "images":HttpLoader.createArrParser(parseImage)},
				{"id":"id", "width":"width", "height":"height", "created_time":"createdTime",
					"from":"from", "icon":"icon", "images":"imagesArr", "link":"link", "name":"name",
					"picture":"picture", "source":"source", "updated_time":"updatedTime"});
			
			var onUser:Function = HttpLoader.createHandler(parseUser);
			var onUsers:Function = HttpLoader.createHandler(HttpLoader.createArrParser(parseUser), "data");
			
			var onAlbum:Function = HttpLoader.createHandler(parseAlbum);
			var onAlbums:Function = HttpLoader.createHandler(HttpLoader.createArrParser(parseAlbum), "data");
			
			var onPhoto:Function = HttpLoader.createHandler(parsePhoto);
			var onPhotos:Function = HttpLoader.createHandler(HttpLoader.createArrParser(parsePhoto), "data");
			
			
			_oauthUrl = new UrlProvider(true, AUTH_URL);
			_oauthUrl.setupArrayToken(URL_PERMISSIONS, "+", ["user_photos", "friends_photos"]);
			_oauthUrl.setToken(URL_CLIENT_ID, "");
			_oauthUrl.setToken(URL_REDIRECT_URL, "");
			
			_callUrl = new UrlProvider(true, API_URL);
			_logoutUrl = new UrlProvider(true, LOGOUT_URL);
			
			_oauth = new OAuth2(checkAuthUrl);
			_oauth.accessTokenChanged.add(onTokenChanged);
			super("Facebook_v2", _oauth);
			
			addGateway(GATEWAY_OAUTH, _oauth);
			addGateway(GATEWAY_JSON, new HttpLoader(_oauth));
			addGateway(GATEWAY_IMAGE, new HttpLoader(_oauth, URLLoaderDataFormat.BINARY));
			
			addProp(URL_CLIENT_ID, "Instagram application client ID", false);
			addProp(URL_REDIRECT_URL, "Instagram application redirect URL", false);
			
			var userId:ArgDesc 			= a("userId", "Relevant user");
			var objectId:ArgDesc 		= a("objectId", "Object to retrieve");
			/*var locationId:ArgDesc 	= a("locID", "Location to retrieve");
			var tagId:ArgDesc 			= a("tagID", "Tag to retrieve");
			var searchQuery:ArgDesc 	= a("q", "Search query");
			var minId:ArgDesc 			= a("min_id", "Return media later than this min_id", true);
			var maxId:ArgDesc 			= a("max_id", "Return media earlier than this max_id", true);
			var minTime:ArgDesc 		= a("min_timestamp", "Return media after this UNIX timestamp", true);
			var maxTime:ArgDesc 		= a("max_timestamp", "Return media before this UNIX timestamp", true);
			var count:ArgDesc 			= a("count", "Count of media to return", true);*/
			
			var s1:String = PlatformState.STATE_UNAUTHENTICATED;
			var s2:String = PlatformState.STATE_AUTHENTICATING;
			var s3:String = PlatformState.STATE_AUTHENTICATED;
			
			addCall(GATEWAY_OAUTH, CALL_AUTH, s1, [], _oauthUrl, "Revives session  if possible, otherwise displays login view.", null, {doAuth:true});
			addEndpointCall(GATEWAY_JSON, CALL_LOGOUT, s3, "logout", [], _logoutUrl, "Deauthenticate user", onLogout);
			
			addEndpointCall(GATEWAY_JSON, CALL_SELF, s3, "me", [], _callUrl, "The user's info.", onUser);
			addEndpointCall(GATEWAY_JSON, CALL_FRIENDS, s3, "me/friends", [], _callUrl, "The user's friends.", onUsers);
			
			addEndpointCall(GATEWAY_JSON, CALL_ALBUMS, s3, "me/albums", [], _callUrl, "Get photo albums.", onAlbums);
			addEndpointCall(GATEWAY_JSON, CALL_ALBUM, s3, URL_OBJECT_ID, [objectId], _callUrl, "Get a photo album.", onAlbum);
			addEndpointCall(GATEWAY_IMAGE, CALL_ALBUM_PICTURE, s3, URL_OBJECT_ID+"/picture", [objectId], _callUrl, "The cover photo of this album.", HttpLoader.loaderHandler);
			addEndpointCall(GATEWAY_JSON, CALL_ALBUM_PHOTOS, s3, URL_OBJECT_ID+"/photos", [objectId], _callUrl, "Photos contained in this album.", onPhotos);
			
			addEndpointCall(GATEWAY_JSON, CALL_USER_ALBUMS, s3, URL_USER_ID+"/albums", [userId], _callUrl, "Get a user's photo albums.", onAlbums);
			
			
			
			addEndpointCall(GATEWAY_JSON, CALL_FQL, s3, "fql", [a("q", "FQL query")], _callUrl, "The query to execute.", HttpLoader.createHandler(null, "data"));
			
			var queryParser:Function = function(results:Array):Object{
				var ret:Object = {};
				for each(var res:Object in results){
					ret[res.name] = res.fql_result_set;
				}
				return ret;
			}
			addEndpointCall(GATEWAY_JSON, CALL_FQL_MULTI, s3, "fql", [a("q", "FQL query")], _callUrl, "The query to execute.", HttpLoader.createHandler(queryParser, "data"));
			
			/*
			/achievement
			Represents a user gaining a game achievement in a Facebook App.
			
			/achievement-type
			A games achievement type created by a Facebook App.
			
			/picture
			The cover photo of this album.
			
			/photos
			Photos contained in this album.
			
			/app
			A Facebook app.
			
			/app_link_hosts
			The app link objects created by this app.
			
			/accounts/test-users
			Test User accounts associated with the app.
			
			/achievements
			Game achievement types registered for the app.
			
			/banned
			List of people banned from this app
			
			/groups
			Groups for this app
			
			/insights
			Usage metrics for this app.
			
			/picture
			The app's profile picture.
			
			/roles
			The developer roles defined for this app.
			
			/scores
			Scores for a person and their friends.
			
			/staticresources
			Usage stats about the canvas app's static resources, such as javascript and CSS, and which ones are being flushed to browsers early.
			
			/subscriptions
			All of the subscriptions this app has for real-time notifications.
			
			/translations
			The translated strings for this app.
			
			/app-link-host
			An app link object created by an app.
			
			/comment
			A comment published on any other node.
			
			/domain
			A web domain claimed within Facebook Insights.
			
			/event
			An event.
			
			/attending
			All of the users who are attending this event.
			
			/declined
			All of the users who declined their invitation to this event.
			
			/feed
			This event's wall.
			
			/invited
			All of the users who have been invited to this event.
			
			/maybe
			All of the users who have been responded 'Maybe' to their invitation to this event.
			
			/noreply
			All of the users who have been not yet responded to their invitation to this event.
			
			/picture
			The event's profile picture.
			
			/photos
			The photos uploaded to an event.
			
			/videos
			The videos uploaded to an event.
			
			/friendlist
			A grouping of friends created by someone on Facebook.
			
			/members
			The profiles that are members of this list
			
			/group
			A Facebook group.
			
			/admins
			The admins of a group. This edge is only available to app and game groups.
			
			/docs
			The docs in this group.
			
			/events
			The events in this group.
			
			/feed
			This group's feed.
			
			/files
			Files uploaded to this group.
			
			/members
			All of the users who are members of this group.
			
			/link
			A link shared on Facebook.
			
			/message
			A Facebook message.
			
			/milestone
			A Facebook Page milestone.
			
			/photos
			Any photos attached to the milestone.
			
			/object/comments
			A set of comments on a particular object.
			
			/object/likes
			A set of likes on a particular object.
			
			/object/sharedposts
			The shares of a particular object.
			
			/object/insights
			Usage metrics for several types of object.
			
			/offer
			An offer published by a Page.
			
			/page
			A Facebook Page.
			
			/admins
			A list of the Page's Admins.
			
			/albums
			The photo albums the Page has uploaded.
			
			/blocked
			A list of users blocked from the Page.
			
			/conversations
			A list of the Page's conversations.
			
			/events
			The events the Page has created.
			
			/feed
			The Page's wall.
			
			/global_brand_children
			Expose information of all children Pages.
			
			/insights
			The Page's Insights data
			
			/links
			The Page's posted links.
			
			/locations
			The location Pages that are children of this Page.
			
			/milestones
			A list of the Page's milestones.
			
			/offers
			The offers created by this Page
			
			/picture
			The Page's profile picture.
			
			/photos
			The photos the Page is tagged in.
			
			/posts
			The Page's own posts, a derivative of /feed.
			
			/promotable_posts
			The Page's own posts, a derivative of /feed that includes unpublished and scheduled posts
			
			/settings
			Controllable settings for this page.
			
			/statuses
			The Page's status updates.
			
			/tabs
			The Page's tabs and the apps in them.
			
			/tagged
			The photos, videos, and posts in which the Page has been tagged. A derivative of /feeds
			
			/videos
			The videos the Page has uploaded.
			
			/payment
			Details of a payment made via Facebook.
			
			/dispute
			Updates the dispute status of a payment.
			
			/refunds
			Refunds a payment.
			
			/photo
			A photo published to Facebook.
			
			/tags
			The Users tagged in the photo
			
			/place-tag
			An instance of a person being tagged at a place in a photo, video, post, status or link.
			
			/post
			A post published to Facebook.
			
			/review
			A review of a Facebook app.
			
			/status
			A status message or post published to Facebook.
			
			/test-user
			A test user created by a Facebook app.
			
			/friends
			The friends of the test user - this edge can be used to friend two test users.
			
			/thread
			A message thread in Facebook Messages.
			
			/user
			A person using Facebook.
			
			/accounts
			The Facebook pages of which the current user is an administrator.
			
			/achievements
			The achievements for the user.
			
			/activities
			The activities listed on the user's profile.
			
			/adaccounts
			The advertising accounts to which the current user has access.
			
			/applications/developer
			List of applications for this developer.
			
			/apprequests
			The user's outstanding requests from an app.
			
			/books
			The books listed on the user's profile.
			
			/events
			The events this user is attending.
			
			/family
			The user's family relationships
			
			/feed
			The posts and links published by this person or others on their profile.
			
			/friendlists
			The user's friend lists.
			
			/friendrequests
			The user's incoming friend requests.
			
			/friends
			The user's friends.
			
			/games
			Games the user has added tits and Entertainment section of their profile.
			
			/groups
			The Groups that the user belongs to.
			
			/home
			The user's news feed.
			
			/ids_for_business
			The list of IDs that a user has in any other apps owned by the same business entity.
			
			/inbox
			The Threads in this user's inbox.
			
			/interests
			The interests listed on the user's profile.
			
			/invitable_friends
			A list of friends that can be invited to install a Facebook Canvas app.
			
			/likes
			All the pages this user has liked.
			
			/links
			This is a duplicate of the /feeds edge which only shows posts of type link published by the user themselves.
			
			/movies
			The movies listed on the user's profile.
			
			/music
			The music listed on the user's profile.
			
			/notifications
			App notifications for the user.
			
			/outbox
			The messages in this user's outbox.
			
			/payment_transactions
			The Facebook Payments orders the user placed with an application.
			
			/payments
			Deprecated endpoint for Facebook Credits product. Use Facebook Payments instead.
			
			/permissions
			The permissions that user has granted the application.
			
			/picture
			The user's profile picture.
			
			/photos
			Photos the user (or friend) is tagged in.
			
			/photos/uploaded
			Similar to /photos except shows all photos this person has uploaded.
			
			/pokes
			The user's pokes.
			
			/posts
			This is a duplicate of the /feeds edge which only shows posts published by the user themselves.
			
			/scores
			The scores this person has received from Facebook Games that they've played.
			
			/statuses
			This is a duplicate of the /feeds edge which only shows status update posts published by the user themselves.
			
			/taggable_friends
			Friends that can be tagged in content published via the Graph API.
			
			/tagged
			This is a duplicate of the /feeds edge which only shows posts in which the user is tagged.
			
			/tagged_places
			List of tags of this person at a place in a photo, video, post, status or link.
			
			/television
			The television listed on the user's profile.
			
			/videos
			The videos this user has been tagged in.
			
			/videos/uploaded
			Similar to /videos except shows all videos this person has uploaded.
			
			/video
			A video published to Facebook.
			*/
			
			/*addEndpointCall(GATEWAY_JSON, CALL_GET_FEED, s3, "users/self/feed/", [count, minId, maxId], _callUrl, "Get current user's feed.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_USER, s3, "users/${userID}/", [userId], _callUrl, "Gets a user's info.", onUser);
			addEndpointCall(GATEWAY_JSON, CALL_USER_SEARCH, s3, "users/search/", [searchQuery], _callUrl, "Search for users.", onUsers);
			addEndpointCall(GATEWAY_JSON, CALL_GET_SELF, s3, "users/self/", [], _callUrl, "Get current user info.", onUser);
			addEndpointCall(GATEWAY_JSON, CALL_GET_SELF_RECENT, s3, "users/self/media/recent/", [minId, maxId, minTime, maxTime], _callUrl, "Get current users recent photos.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_USER_RECENT, s3, "users/${userID}/media/recent/", [userId, minId, maxId, minTime, maxTime], _callUrl, "Get users recent photos.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_SELF_LIKED, s3, "users/self/media/liked/", [], _callUrl, "See the authenticated user's list of media they've liked.", onPhotos);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_PHOTO, s3, "media/${photoID}/", [a("photoID", "Photo to retrieve")], _callUrl, "Get a photo's info.", onPhoto);
			addEndpointCall(GATEWAY_JSON, CALL_PHOTO_SEARCH, s3, "media/search/", [searchQuery], _callUrl, "Search for photos.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_POPULAR_PHOTOS, s3, "media/popular/", [], _callUrl, "Get popular photos.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_PHOTO_LIKES, s3, "media/${photoID}/likes", [], _callUrl, "Get users who have liked this media.", onUsers);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_LOCATION, s3, "locations/${locID}/", [locationId], _callUrl, "Get location's info.", onLocation);
			addEndpointCall(GATEWAY_JSON, CALL_GET_LOCATION_RECENT, s3, "locations/${locID}/media/recent/", [locationId, minId, maxId, minTime, maxTime], _callUrl, "Get recent photos from location.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_LOCATION_SEARCH, s3, "locations/search/", [
				a("lat", "Latitude of the center search coordinate. If used, lng is required"),
				a("lng", "Longitude of the center search coordinate. If used, lat is required."),
				a("distance", "Default is 1000m (distance=1000), max distance is 5000"),
				a("foursquare_id", "Returns a location mapped off of a foursquare v1 api location id. If used, you are not required to use lat and lng. Note that this method is deprecated; you should use the new foursquare IDs with V2 of their API.")
			], _callUrl, "Search for locations.", onLocations);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_TAG, s3, "tags/${tagID}/", [tagId], _callUrl, "Get tag's info.", onTag);
			addEndpointCall(GATEWAY_JSON, CALL_GET_TAG_RECENT, s3, "tags/${tagID}/media/recent/", [tagId, minId, maxId], _callUrl, "Get recent photos from tag.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_TAG_SEARCH, s3, "tags/search/", [searchQuery], _callUrl, "Search for tags.", onTags);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_GEOGRAPHIES_RECENT, s3, "geographies/${geoID}/media/recent/", [a("geoID", "Geography to search"), count, minId], _callUrl, "Get recent photos from geography.", onPhotos);*/
		}
		
		override public function setProp(name:String, value:*):void{
			super.setProp(name, value);
			_oauthUrl.setToken(name, value);
			_callUrl.setToken(name, value);
		}
		
		protected function addEndpointCall(gatewayId:String, callId:String, availableState:String, endPoint:String, args:Array, url:IUrlProvider, desc:String = null, resultHandler:Function=null, urlTokens:Object=null, protocol:String=null):void
		{
			if(!urlTokens)urlTokens = {};
			urlTokens[HttpLoader.URL_ENDPOINT] = endPoint;
			addCall(gatewayId, callId, availableState, args, url, desc, resultHandler, urlTokens, protocol); 
		}
		
		private function onTokenChanged():void
		{
			_oauthUrl.setToken(OAuth2.URL_ACCESS_TOKEN, _oauth.accessToken);
			_callUrl.setToken(OAuth2.URL_ACCESS_TOKEN, _oauth.accessToken);
		}
		
		private function checkAuthUrl(url:String):Boolean{
			return (
				url.indexOf("facebook.com/dialog/oauth")!=-1 ||
				url.indexOf("facebook.com/login")!=-1 
			);
		}
	}
}