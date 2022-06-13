class Utils {

	static const WINDS_API_ENDPOINT = "https://winds.mobi/api/2";

	static function orientation(degres as Float) {
		
		var sector = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSO","SO","OSO","O","ONO","NO","NNO","N"];
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
