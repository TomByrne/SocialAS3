package social.fb.vo
{
	public class NameTag
	{
		/**
		 * ID of the profile
		 */
		public var id:String;
		
		/**
		 * The object itself
		 */
		public var object:String;
		
		/**
		 * Number of characters in the text indicating the object
		 */
		public var length:int;
		
		/**
		 * Name of the object
		 */
		public var name:String;
		
		/**
		 * The character offset in the source text of the text indicating the object
		 */
		public var offset:int;
		
		/**
		 * Type of the object
		 */
		public var type:String;
		
		public function NameTag()
		{
		}
	}
}