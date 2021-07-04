class Utils {

	static function orientation(degres as Float) {
		
		var sector = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSO","SO","OSO","O","ONO","NO","NNO","N"];
		var index = (degres / 22.5).toNumber();
				
		return sector[index];
	}
}