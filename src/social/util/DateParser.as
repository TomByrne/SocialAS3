package social.util
{
	public class DateParser
	{
		private static const MONTHS_SHORT:Array = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
		
		
		public static function parser(format:String, adjustTimezone:Boolean):Function
		{
			var formatReg:RegExp = createReg(format);
			return function(str:String):Date{
				return parseReg(formatReg, str, adjustTimezone);
			}
		}
		public static function parse(format:String, dateStr:String, adjustTimezone:Boolean):Date
		{
			return parseReg(createReg(format), dateStr, adjustTimezone);
		}
		private static function createReg(format:String):RegExp
		{
			format = format.replace("%r", "%I:%M:%S %p");
			format = format.replace("%R", "%H:%M");
			format = format.replace("%T", "%H:%M:%S");
			format = format.replace("%D", "%m/%d/%y");
			format = format.replace("%F", "%Y-%m-%d");
			format = format.replace("%n", "\\n");
			format = format.replace("%t", "\\t");
			format = format.replace("%%", "!@#$!@#$");
			format = format.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
			format = format.replace(/%(\w)/g, "(?P<$1>[ +\\d\\w]+)");
			format = format.replace("!@#$!@#$", "%");
			return new RegExp(format, "");
		}
		private static function parseReg(format:RegExp, dateStr:String, adjustTimezone:Boolean):Date
		{
			var result:Object = format.exec(dateStr);
			if(result){
				var ret:Date = new Date();
				var meridian:String;
				var meridianHour:Number;
				var timezoneOffset:Number;
				for(var i:* in result){
					switch(i){
						case "d":// Two-digit day of the month
						case "e":// Day of the month, with a space preceding single digits.
							ret.date = parseInt(result[i]);
							break;
						case "m"://Two digit representation of the month
							ret.month = parseInt(result[i]) - 1;
							break;
						case "G"://The full four-digit representation of the year going by ISO-8601:1988 standards
						case "Y"://Four digit representation for the year
							ret.fullYear = parseInt(result[i]);
							break;
						case "H"://Two digit representation of the hour in 24-hour format, 00 through 23
						case "k"://Two digit representation of the hour in 24-hour format, with a space preceding single digits, 00 through 23
							ret.hours = parseInt(result[i]);
							break;
						case "I"://Two digit representation of the hour in 12-hour format, 01 through 12
						case "l"://Hour in 12-hour format, with a space preceding single digits, 01 through 12
							meridianHour = parseInt(result[i]);
							break;
						case "M"://Two digit representation of the minute, 00 through 59
							ret.minutes = parseInt(result[i]);
							break;
						case "p"://UPPER-CASE 'AM' or 'PM' based on the given time
							meridian = result[i].toLowerCase();
							break;
						case "p"://lower-case 'am' or 'pm' based on the given time
							meridian = result[i];
							break;
						case "S"://Two digit representation of the second, 00 through 59
							ret.seconds = parseInt(result[i]);
							break;
						case "z"://The time zone offset. See below for more information.
							timezoneOffset = parseInt(result[i]);
							break;
						case "s"://Unix Epoch Time timestamp
							ret.time = parseInt(result[i]) * 1000;
							break;
						case "B":// Full month name, based on the locale
						case "b":// Abbreviated month name, based on the locale
						case "h":// Abbreviated month name, based on the locale (an alias of %b)
							ret.month = MONTHS_SHORT.indexOf(result[i].toUpperCase().substr(0,3));
							break;
						case "j":// Day of the year, 3 digits with leading zeros
						case "g":// Two digit representation of the year going by ISO-8601:1988 standards (see %V)
						case "C":// Two digit representation of the century (year divided by 100, truncated to an integer)
						case "u":// day of the week, 1 (for Monday) though 7 (for Sunday)
						case "w":// day of the week, 0 (for Sunday) through 6 (for Saturday)
						case "U":// Week number of the given year, starting with the first Sunday as the first week
						case "V":// Week number of the given year, starting with the first week of the year with at least 4 weekdays, with Monday being the start of the week
						case "W":// A numeric representation of the week of the year, starting with the first Monday as the first week
						case "g":// Two digit representation of the year going by ISO-8601:1988 standards
						case "y":// Two digit representation of the year
						case "x":// Preferred date representation based on locale, without the time
						case "X":// Preferred time representation based on locale, without the date
						case "Z":// The time zone abbreviation. See below for more information.
							throw "not implemented"
							break;
						case "a":// An abbreviated textual representation of the day
						case "A":// A full textual representation of the day
					}
				}
				if(meridian && !isNaN(meridianHour)){
					ret.hours = (meridian=="am"?meridianHour:meridianHour+12);
				}
				if(adjustTimezone && !isNaN(timezoneOffset)){
					var timezoneDiff:Number = timezoneOffset - ret.timezoneOffset;
					ret.time += timezoneDiff * 60 * 1000;
				}
				return ret;
			}else{
				return null;
			}
		}
	}
}