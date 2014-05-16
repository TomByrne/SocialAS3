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
		
		
		public function set imagesArr(value:Array):void{
			images = Vector.<Image>(value);
		}
		
		public function Photo()
		{
		}
	}
}