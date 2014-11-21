package  
{
	/**
	 * ...
	 * @author 
	 */
	public class TestGeoData
	{
		// lat|lng
		
		public static const AFGHANISTAN_KABUL		:String = "34.500|69.167";
		public static const ALGERIA_ALGER			:String = "36.833|3.000";
		public static const ARGENTINA_BUENOS_AIRES	:String = "-34.667|-58.500";
		public static const AUSTRALIA_SYDNEY		:String = "-33.917|151.167";
		public static const BELGIUM_BRUSSELS		:String = "50.850|4.350";
		
		public static const FRANCE_PARIS			:String = "48.833|2.333";
		public static const FRANCE_BAYONNE			:String = "43.500|-1.467";
		
		public static const USA_NEW_YORK_NY			:String = "40.667|-73.833";
		public static const USA_SAN_FRANCISCO_CA	:String = "37.770|-122.430";
		public static const USA_DETROIT_MI			:String = "42.383|-83.083";
		
		public function TestGeoData() 
		{
			
		}
		
		public static function getLatLng( s:String ):Array
		{
			var arr:Array = s.split("|");
			return arr;
		}
		
	}

}