package
{
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	import com.bit101.components.TextArea;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import social.core.PlatformState;
	import social.instagram.Instagram;
	import social.web.StageWebViewProxy;

	//import com.demonsters.debugger.MonsterDebugger;	//v3
	
	/**
	 * ...
	 * @author pbordachar
	 */
	[SWF(width='820', height='800', backgroundColor='#ffffff', frameRate='30')]
	public class TestAPI extends Sprite 
	{
		//[Embed(source = "/assets/instagram.jpg")] 
		//private var itgLogo:Class;
		
		private var _instagram:Instagram;
		private var _container:Sprite;
		private var _results:TextArea;
		
		// http://instagr.am/developer/manage/
		/*
		 app name : xxxx
		 client id : xxxx
		 client secret : xxxx
		 callback url : xxxx
		*/
		 
		public function TestAPI():void 
		{
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			
			_results = new TextArea();
			_results.x = 350;
			_results.y = 10;
			_results.setSize(400, 800);
			stage.addChild( _results );
		}
		
		protected function onEnterFrame(event:Event):void
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			_instagram	= new Instagram();
			_instagram.setWebView(new StageWebViewProxy(stage, new Rectangle(0,20,stage.stageWidth, stage.stageHeight-20)));
			_instagram.init("15a5469e6d284a6eb592391718ac0fe1", "http://devdevelopversion.whitechimagine.com/imagine/app_instagram_redirect.php?userGroupID=7");
			if(_instagram.state==PlatformState.STATE_AUTHENTICATED){
				onInstagramStateChanged();
			}
			//_instagram.manageSession = false;
			_instagram.stateChanged.add(onInstagramStateChanged);
			onInstagramStateChanged();
		}
		
		protected function onInstagramStateChanged():void{
			switch(_instagram.state){
				case PlatformState.STATE_UNAUTHENTICATED:
					loggedOutUI();
					break;
				case PlatformState.STATE_AUTHENTICATING:
					loggingInUI();
					break;
				case PlatformState.STATE_AUTHENTICATED:
					loggedInUI();
					break;
			}
		}

		// - - -
		
		private function loggedOutUI():void
		{
			removeAllChildren();
			
			var btn:PushButton;
			btn = new PushButton(this, 0, 0, "Start Auth", itgStartAuth );
		}
		
		
		private function itgStartAuth( e:Event ):void
		{
			_instagram.authenticate();
		}
		private function itgCancelAuth( e:Event ):void
		{
			_instagram.cancelAuth();
		}
		private function loggingInUI():void
		{
			removeAllChildren();
			var label:Label = new Label(this, 0,0,"Logging in...");
			var btn:PushButton;
			btn = new PushButton(this, 80, 0, "Cancel Auth", itgCancelAuth );
		}
		
		private function loggedInUI():void
		{
			removeAllChildren();
			
			var btn:PushButton;
			btn = new PushButton(this, 20, 20, "User Self Info", itgGetSelfUser );
			btn = new PushButton(this, 20, 50, "User Infos", itgGetUser );
			btn = new PushButton(this, 20, 80, "Self Feed", itgGetFeed );
			btn = new PushButton(this, 20, 110, "Photo Infos", itgGetPhoto );
			btn = new PushButton(this, 20, 140, "User Recent", itgGetUserRecent );
			btn = new PushButton(this, 20, 170, "Self Recent", itgGetSelfRecent );
			btn = new PushButton(this, 20, 200, "User Search", itgGetUserSearch );
			btn = new PushButton(this, 20, 230, "Photo Search", itgGetPhotoSearch );
			btn = new PushButton(this, 20, 260, "Most Popular", itgGetPopular );
			btn = new PushButton(this, 20, 290, "Location Infos", itgGetLocation );
			btn = new PushButton(this, 20, 320, "Location Recent", itgGetLocationRecent );
			btn = new PushButton(this, 20, 350, "Location search", itgGetLocationSearch );
			btn = new PushButton(this, 20, 380, "Tag Infos", itgGetTag );
			btn = new PushButton(this, 20, 410, "Tag Recent", itgGetTagRecent );
			btn = new PushButton(this, 20, 440, "Tag search", itgGetTagSearch );
			btn = new PushButton(this, 20, 470, "Geography Recent", itgGetGeographyRecent );
			
			btn = new PushButton(this, 20, 530, "Logout", itgLogout );
			
			_container = new Sprite();
			_container.x = 120;
			_container.y = 10;
			addChild( _container );
		}
		
		private function removeAllChildren():void
		{
			while(numChildren)removeChildAt(0);
		}
		
		private function doParseInt(txt:String):int{
			if(txt.length)return parseInt(txt);
			else return -1;
		}
		
		private function doParseFloat(txt:String):Number{
			if(txt.length)return parseFloat(txt);
			else return NaN;
		}
		
		private function clear():void
		{
			while ( _container.numChildren )
			{
				_container.removeChildAt( 0 );
			}
		}

		// See the authenticated user's feed.
		
		private function itgGetFeed( e:Event ):void
		{
			clear();
			
			var label:Label;
			
			label = new Label( _container, 10, 10, "count" );
			var count:InputText = new InputText(_container, 10, 30, "" );
			
			label = new Label( _container, 10, 50, "min ID" );
			var minID:InputText = new InputText(_container, 10, 70, "" );
			
			label = new Label( _container, 10, 90, "max ID" );
			var maxID:InputText = new InputText(_container, 10, 110, "" );
			
			var sendBtn:PushButton = new PushButton ( _container, 120, 68, "SEND", send )
			
			function send():void
			{
				_instagram.getFeed( count.text.length?doParseInt(count.text):-1, minID.text.length?doParseInt(minID.text):-1, maxID.text.length?doParseInt(maxID.text):-1, onResult );
			}
		}
		
		
		private function itgLogout( e:Event ):void
		{
			clear();
			
			var sendBtn:PushButton = new PushButton ( _container, 120, 28, "SEND", send )
			
			function send():void
			{
				_instagram.logout(onResult);
			}
		}
		
		
		private function itgGetSelfUser( e:Event ):void
		{
			clear();
			
			var sendBtn:PushButton = new PushButton ( _container, 120, 28, "SEND", send )
			
			function send():void
			{
				_instagram.getSelf(onResult);
			}
		}
		
		// Get basic information about a user.
		
		private function itgGetUser( e:Event ):void
		{
			clear();
			
			var label:Label = new Label( _container, 10, 10, "User ID" );
			var userID:InputText = new InputText(_container, 10, 30, "" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 28, "SEND", send )
			
			function send():void
			{
				_instagram.getUser( doParseInt(userID.text), onResult );
			}
		}
		
		// Get the most recent media published by a user.
		
		private function itgGetUserRecent( e:Event ):void
		{
			clear();
			
			var label:Label = new Label( _container, 10, 10, "User ID" );
			var userID:InputText = new InputText(_container, 10, 30, "" );
			var max:Label = new Label( _container, 10, 50, "max ID" );
			var maxID:InputText = new InputText(_container, 10, 70, "" );
			var min:Label = new Label( _container, 10, 90, "min ID" );
			var minID:InputText = new InputText(_container, 10, 110, "" );
			var max2:Label = new Label( _container, 10, 150, "max TS" );
			var maxTS:InputText = new InputText(_container, 10, 170, "" );
			var min2:Label = new Label( _container, 10, 190, "min TS" );
			var minTS:InputText = new InputText(_container, 10, 210, "" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 208, "SEND", send )
			
			function send():void
			{
				_instagram.getUserRecent( doParseInt(userID.text), doParseInt(maxID.text), doParseInt(minID.text), doParseInt(maxTS.text), doParseInt(minTS.text), onResult );
			}			
		}
		
		// Get the most recent media published by a user.
		
		private function itgGetSelfRecent( e:Event ):void
		{
			clear();
			
			var max:Label = new Label( _container, 10, 50, "max ID" );
			var maxID:InputText = new InputText(_container, 10, 70, "" );
			var min:Label = new Label( _container, 10, 90, "min ID" );
			var minID:InputText = new InputText(_container, 10, 110, "" );
			var max2:Label = new Label( _container, 10, 150, "max TS" );
			var maxTS:InputText = new InputText(_container, 10, 170, "" );
			var min2:Label = new Label( _container, 10, 190, "min TS" );
			var minTS:InputText = new InputText(_container, 10, 210, "" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 208, "SEND", send )
			
			function send():void
			{
				_instagram.getSelfRecent( doParseInt(maxID.text), doParseInt(minID.text), doParseInt(maxTS.text), doParseInt(minTS.text), onResult );
			}			
		}
		
		// Search for a user by name.
		
		private function itgGetUserSearch( e:Event ):void
		{
			clear();
			
			var label:Label = new Label( _container, 10, 10, "Search for" );
			var search:InputText = new InputText(_container, 10, 30, "" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 28, "SEND", send )
			
			function send():void
			{
				_instagram.userSearch( search.text, onResult );
			}			
		}
		
		// Get information about a media object
		
		private function itgGetPhoto( e:Event ):void
		{
			clear();
			
			var labelL:Label = new Label( _container, 10, 10, "Photo ID" );
			var photoID:InputText = new InputText(_container, 10, 30, "44011372" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 28, "SEND", send )
			
			function send():void
			{
				_instagram.getPhoto( doParseInt(photoID.text), onResult );
			}			
		}
		
		// Search for media in a given area.
		
		private function itgGetPhotoSearch( e:Event ):void
		{
			clear();
			
			var coord:Array = TestGeoData.getLatLng( TestGeoData.USA_SAN_FRANCISCO_CA );
			
			var latitude:Label = new Label( _container, 10, 10, "latitude" );
			var lat:InputText = new InputText(_container, 10, 30, coord[ 0 ] );
			var longitude:Label = new Label( _container, 10, 50, "longitude" );
			var long:InputText = new InputText(_container, 10, 70, coord[ 1 ] );
			var distance:Label = new Label( _container, 10, 90, "distance" );
			var dist:InputText = new InputText(_container, 10, 110, "" );
			var max2:Label = new Label( _container, 10, 130, "max TS" );
			var maxTS:InputText = new InputText(_container, 10, 150, "" );
			var min2:Label = new Label( _container, 10, 170, "min TS" );
			var minTS:InputText = new InputText(_container, 10, 190, "" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 188, "SEND", send )
			
			function send():void
			{
				var d:int = ( doParseInt( dist.text ) > 5000 ) ? 5000 : 1000; // default value in meters
				
				_instagram.getPhotoSearch( doParseFloat(lat.text), doParseFloat(long.text), d, doParseInt(maxTS.text), doParseInt(minTS.text), onResult );
			}			
		}
		
		// Get a list of what media is most popular at the moment.
		
		private function itgGetPopular( e:Event ):void
		{
			clear();
			
			var popular:Label = new Label( _container, 10, 10, "most popular" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 8, "SEND", send )
			
			function send():void
			{
				_instagram.getPhotoPopular( onResult);
			}
		}
		
		// Get information about a location
		
		private function itgGetLocation( e:Event ):void
		{
			clear();
			
			var label:Label = new Label( _container, 10, 10, "Loc ID" );
			var locID:InputText = new InputText(_container, 10, 30, "1" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 188, "SEND", send )
			
			function send():void
			{
				_instagram.getLocation( doParseInt(locID.text), onResult );
			}
		}
		
		// Get a list of recent media objects from a given location
		
		private function itgGetLocationRecent( e:Event ):void
		{
			clear();
			
			var label:Label = new Label( _container, 10, 10, "Loc ID" );
			var locID:InputText = new InputText(_container, 10, 30, "1" );
			var max:Label = new Label( _container, 10, 50, "max ID" );
			var maxID:InputText = new InputText(_container, 10, 70, "" );
			var min:Label = new Label( _container, 10, 90, "min ID" );
			var minID:InputText = new InputText(_container, 10, 110, "" );
			var max2:Label = new Label( _container, 10, 130, "max TS" );
			var maxTS:InputText = new InputText(_container, 10, 150, "" );
			var min2:Label = new Label( _container, 10, 170, "min TS" );
			var minTS:InputText = new InputText(_container, 10, 190, "" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 188, "SEND", send )
			
			function send():void
			{
				_instagram.getLocationRecent( doParseInt(locID.text), doParseInt(maxID.text), doParseInt(minID.text), doParseInt(maxTS.text), doParseInt(minTS.text), onResult );
			}
		}
		
		// Search for a location by name and geographic coordinate.
		
		private function itgGetLocationSearch( e:Event ):void
		{
			clear();
			
			var latitude:Label = new Label( _container, 10, 10, "latitude" );
			var lat:InputText = new InputText(_container, 10, 30, "43.500" );
			var longitude:Label = new Label( _container, 10, 50, "longitude" );
			var long:InputText = new InputText(_container, 10, 70, "-1.467" ); // bayonne
			var distance:Label = new Label( _container, 10, 90, "distance" );
			var dist:InputText = new InputText(_container, 10, 110, "" );
			var foursquare:Label = new Label( _container, 10, 130, "foursquareID" );
			var foursquareID:InputText = new InputText(_container, 10, 150, "" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 148, "SEND", send )
			
			function send():void
			{
				var d:int = ( doParseInt( dist.text ) > 5000 ) ? 5000 : 1000; // default value in meters
				
				_instagram.getLocationSearch( doParseFloat(lat.text), doParseFloat(long.text), d, doParseInt(foursquareID.text), onResult );
			}			
		}
		
		// Get information about a tag object.
		
		private function itgGetTag( e:Event ):void
		{
			clear();
			
			var label:Label = new Label( _container, 10, 10, "Tag name" );
			var name:InputText = new InputText(_container, 10, 30, "" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 28, "SEND", send )
			
			function send():void
			{
				_instagram.getTag( name.text, onResult );
			}			
		}
		
		// Get a list of recently tagged media
		
		private function itgGetTagRecent( e:Event ):void
		{
			clear();
			
			var label:Label = new Label( _container, 10, 10, "Tag" );
			var search:InputText = new InputText(_container, 10, 30, "" );
			var max:Label = new Label( _container, 10, 50, "max ID" );
			var maxID:InputText = new InputText(_container, 10, 70, "" );
			var min:Label = new Label( _container, 10, 90, "min ID" );
			var minID:InputText = new InputText(_container, 10, 110, "" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 28, "SEND", send )
			
			function send():void
			{
				_instagram.getTagRecent( search.text, doParseInt(minID.text), doParseInt(maxID.text), onResult );
			}			
		}
		
		// Search for tags by name
		
		private function itgGetTagSearch( e:Event ):void
		{
			clear();
			
			var label:Label = new Label( _container, 10, 10, "Search for" );
			var search:InputText = new InputText(_container, 10, 30, "" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 28, "SEND", send )
			
			function send():void
			{
				var params:String;
				params =  "&q=" + search.text;
				
				_instagram.getTagSearch( search.text, onResult );
			}			
		}
		
		// Get most recent media from a geography subscription that you created
		
		private function itgGetGeographyRecent( e:Event ):void
		{
			clear();
			
			var label:Label = new Label( _container, 10, 10, "Geo ID" );
			var geoID:InputText = new InputText(_container, 10, 30, "555" );
			var sendBtn:PushButton = new PushButton ( _container, 120, 28, "SEND", send )
			
			function send():void
			{
				_instagram.getGeographyRecent( doParseInt(geoID.text), onResult );
			}			
		}
		
		private function onResult(success:*, fail:*):void
		{
			_results.textField.appendText("\n\n");
			if(success){
				setResultColour(0x666666);
				_results.textField.appendText("------------------SUCCESS---------------");
				_results.textField.appendText("\n"+stringify(success));
			}else{
				setResultColour(0xbb0000);
				_results.textField.appendText("------------------FAILURE---------------");
				_results.textField.appendText("\n"+stringify(fail));
			}
			_results.textField.scrollV = _results.textField.maxScrollV;
		}
		
		private function setResultColour(colour:Number):void
		{
			var format:TextFormat = _results.textField.defaultTextFormat;
			format.color = colour;
			_results.textField.defaultTextFormat = format;
		}
		
		private function stringify(obj:*, tabs:String = "", done:Dictionary=null):String
		{
			if(!done)done = new Dictionary();
			if(typeof(obj)=="object"){
				done[obj] = true;
				var type:String = getQualifiedClassName(obj);
				var ret:String = type;
				for(var i:String in obj){
					var value:* = obj[i];
					if(done[value])continue;
					ret += "\n"+tabs+" "+i+" = "+stringify(value, tabs+"\t", done);
				}
				var description:XML = describeType(obj);
				for each (var a:XML in description.*.(localName()=="variable" || localName()=="accessor")){
					i = a.@name;
					value = obj[i];
					if(done[value])continue;
					ret += "\n"+tabs+" "+i+" = "+stringify(value, tabs+"\t", done);
				}
				return ret;
			}else{
				return String(obj);
			}
		}
		
	}
	
}