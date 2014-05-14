package social.instagram.vo
{
	/**
	 * ...
	 * @author pbordachar
	 */
	
	public class Location
	{
		private var _id:int;
		private var _name:String;
		
		private var _latitude:Number;
		private var _longitude:Number;
		
		public function Location() {}
		
		// id
		
		public function get id():int 
		{
			return _id;
		}
		
		public function set id( value:int ):void
		{
			_id = value;
		}
		
		// name
		
		public function get name():String 
		{
			return _name;
		}
		
		public function set name( value:String ):void
		{
			_name = value;
		}
		
		// latitude
		
		public function get latitude():Number 
		{
			return _latitude;
		}
		
		public function set latitude( value:Number ):void
		{
			_latitude = value;
		}
		
		// longitude
		
		public function get longitude():Number 
		{
			return _longitude;
		}
		
		public function set longitude( value:Number ):void
		{
			_longitude = value;
		}
	}

}