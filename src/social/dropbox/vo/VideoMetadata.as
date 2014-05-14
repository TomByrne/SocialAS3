package social.dropbox.vo
{
	public class VideoMetadata extends FileMetadata
	{
		public var lat:Number;
		public var long:Number;
		public var timeTaken:Date;
		public var duration:int; // ms
		
		public function VideoMetadata()
		{
			super();
		}
	}
}