package social.instagram.vo
{
	/**
	 * ...
	 * @author pbordachar
	 */
	
	public class Photo
	{
		public const THB:int = 150;
		public const LOW:int = 306;
		public const STD:int = 612;
		

		private var _id:String;
		private var _type:String;
		private var _created_time:Number;
		private var _likes:int;
		
		private var _user:User;
		private var _location:Location;
		
		private var _tags:Array;
		private var _sizes:Array;
		

		public function Photo(){
			_sizes = [];
		}

		// id

		public function get id():String
		{
			return _id;
		}

		public function set id(value:String):void
		{
			_id = value;
		}
		
		// created_time
		
		public function get creation():Number
		{
			return _created_time;
		}

		public function set creation(value:Number):void
		{
			_created_time = value;
		}
		
		// user
		
		public function get user():User
		{
			return _user;
		}

		public function set user(value:User):void
		{
			_user = value;
		}

		// likes
		
		public function get likes():int
		{
			return _likes;
		}

		public function set likes(value:int):void
		{
			_likes = value;
		}

		// type
		
		public function get type():String
		{
			return _type;
		}

		public function set type(value:String):void
		{
			_type = value;
		}
		
		// location
		
		public function get location():Location
		{
			return _location;
		}

		public function set location(value:Location):void
		{
			_location = value;
		}
		
		// tags
		
		public function get tags():Array
		{
			return _tags;
		}
		
		public function set tags(value:Array):void
		{
			_tags = value;
		}
		
		public function get sizes():Array
		{
			return _sizes;
		}
		
		public function set sizes(value:Array):void
		{
			_sizes = value;
		}
		
		
		public function addSize(size:PhotoSize):void{
			if(_sizes.indexOf(size)==-1)_sizes.push(size);
		}
		
	}
}