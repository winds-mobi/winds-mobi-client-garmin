import Toybox.Lang;

class Utils {

	static const WINDS_API_ENDPOINT = "https://winds.mobi/api/2";

	static function orientation(degres as Float) {
		
		
		var sector = [Rez.Strings.N,Rez.Strings.NNE,Rez.Strings.NE,Rez.Strings.ENE,Rez.Strings.E,Rez.Strings.ESE,Rez.Strings.SE,Rez.Strings.SSE,Rez.Strings.S,Rez.Strings.SSO,Rez.Strings.SO,Rez.Strings.OSO,Rez.Strings.O,Rez.Strings.ONO,Rez.Strings.NO,Rez.Strings.NNO,Rez.Strings.N];
		var index = (degres / 22.5).toNumber();
				
		return sector[index];
	}

	static function convertKmhToKts(speed as Float) {
		if(speed > 0) {
			return speed * 0.539957;
		}else{
			return 0;
		}
	}

	static function convertMetersToFeet(meters as Float) {
		if(meters > 0) {
			return (meters * 3.28084).toNumber();
		}else{
			return 0;
		}
	}

}
