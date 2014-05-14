package social.dropbox.vo
{
	public class FileMetadata extends BaseMetadata
	{
		/**
		 * For files, this is the modification time set by the desktop client when the file
		 * was added to Dropbox, in the standard date format. Since this time is not verified
		 * (the Dropbox server stores whatever the desktop client sends up), this should only
		 * be used for display purposes (such as sorting) and not, for example, to determine
		 * if a file has changed or not.
		 */
		public var clientModified:Date;
		public var size:String;
		public var bytes:int;
		
		
		public function FileMetadata()
		{
			super();
		}
	}
}