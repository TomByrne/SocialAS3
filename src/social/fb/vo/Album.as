package social.fb.vo
{
	public class Album
	{
		public var id:String;
		public var canUpload:Boolean;
		public var count:int;
		public var coverPhoto:String;
		public var createdTime:Date;
		public var from:User;
		public var link:String;
		public var name:String;
		public var privacy:String;
		public var type:String;
		public var updatedTime:Date;
		
		public function Album()
		{
		}
	}
}