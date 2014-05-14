package social.dropbox.vo
{
	public class DirMetadata extends BaseMetadata
	{
		public var hash:String;
		public var contents:Vector.<BaseMetadata>;
		
		public function set contentsArray(value:Array):void{
			contents = value?Vector.<BaseMetadata>(value):null;
		}
		
		public function DirMetadata()
		{
			super();
		}
	}
}