package social.fb.vo
{
	public class Photo
	{
		public var id:String;
		public var width:String;
		public var height:String;
		public var createdTime:Date;
		public var from:User;
		public var icon:String;
		public var images:Vector.<Image>;
		public var link:String;
		public var name:String;
		public var picture:String;
		public var source:String;
		public var updatedTime:Date;
		
		
		// The below properties are only returned when doing a full photo details call
		/**
		 * The time that the photo was taken
		 */
		public var backdatedTime:Date;
		
		/**
		 * How accurate the backdated time is.
		 * enum{'year', 'month', 'day', 'hour', 'min', 'none'}
		 */
		public var backdatedTimeGranularity:String;
		
		/**
		 * ID of the page story this corresponds to if any
		 */
		public var pageStoryId:String;
		
		/**
		 * Location associated with the photo, if any.
		 * Page ID
		 */
		public var place:String;
		
		/**
		 * An array containing an array of objects mentioned in the name field.
		 */
		public var nameTags:Vector.<NameTag>;
		
		
		// The below properties allow arrays to be set where vectors are the underlying data structure.
		public function set imagesArr(value:Array):void{
			images = Vector.<Image>(value);
		}
		public function set nameTagsArr(value:Array):void{
			nameTags = Vector.<NameTag>(value);
		}
		
		public function Photo()
		{
		}
	}
}