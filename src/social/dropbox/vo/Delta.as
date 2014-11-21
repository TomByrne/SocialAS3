package social.dropbox.vo
{
	public class Delta
	{
		public var reset:Boolean;
		public var cursor:String;
		public var hasMore:Boolean;
		public var entries:Vector.<DeltaEntry>;
		
		public function set entriesArray(value:Array):void{
			entries = value?Vector.<DeltaEntry>(value):null;
		}
		
		public function Delta()
		{
		}
	}
}