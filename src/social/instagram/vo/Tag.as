package social.instagram.vo 
{
	/**
	 * ...
	 * @author pbordachar
	 */
	
	public class Tag
	{
		private var _count:int;
		private var _name:String;
		
		public function Tag() 
		{
			
		}
		
		// count
		
		public function get count():int 
		{
			return _count;
		}
		
		public function set count( value:int ):void
		{
			_count = value;
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
		
	}

}