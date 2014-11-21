package social.core
{
	import org.osflash.signals.Signal;

	public interface IUrlProvider
	{
		function get urlChanged():Signal;
		function get url():String;
	}
}