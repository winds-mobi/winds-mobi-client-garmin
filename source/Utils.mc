import Toybox.Lang;
using Toybox.Application;
using Toybox.Graphics as Gfx;

class Utils {

	static const WINDS_API_ENDPOINT = "https://winds.mobi/api/2";

	static function orientation(degres as Float) {


		var sector = [Rez.Strings.N,Rez.Strings.NNE,Rez.Strings.NE,Rez.Strings.ENE,Rez.Strings.E,Rez.Strings.ESE,Rez.Strings.SE,Rez.Strings.SSE,Rez.Strings.S,Rez.Strings.SSO,Rez.Strings.SO,Rez.Strings.OSO,Rez.Strings.O,Rez.Strings.ONO,Rez.Strings.NO,Rez.Strings.NNO,Rez.Strings.N];
		var index = (degres / 22.5).toNumber();
		if(index < 0) { index = 0; }
		if(index > 16) { index = index % 16; }

		return sector[index];
	}

	// ---- Unit helpers -------------------------------------------------------

	// true when the user selected knots + imperial in the settings.
	static function useKts() {
		return Application.getApp().getProperty("mesure_unit") == 1;
	}

	// Convert a km/h speed to the unit selected by the user.
	static function convSpeed(speed) {
		if(speed == null) { return 0; }
		return useKts() ? convertKmhToKts(speed) : speed;
	}

	// Label matching the selected speed unit.
	static function speedLabel() {
		return useKts() ? "kts" : "km/h";
	}

	// ---- Gust factor (turbulence) -------------------------------------------
	// Peak gust / mean wind. Unitless, so independent of the speed unit.
	// A high ratio means gusty / turbulent air, regardless of wind strength.
	static function gustFactor(avg, max) {
		if(avg == null || max == null || avg <= 0) {
			return null;
		}
		return max.toFloat() / avg.toFloat();
	}

	// Colour by turbulence: < 1.3 smooth, < 1.7 active, else turbulent.
	static function gustColor(gf) {
		if(gf == null) { return Gfx.COLOR_LT_GRAY; }
		if(gf < 1.3) { return Gfx.COLOR_GREEN; }
		if(gf < 1.7) { return Gfx.COLOR_ORANGE; }
		return Gfx.COLOR_RED;
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

	static function getSign(number as Float) {
		if(number > 0){
			return "+";
		}else{
			return "";
		}
	}

	// ---- Page indicator -----------------------------------------------------
	// Vertical column of dots on the right edge, one per page, the current page
	// highlighted. Invites the user to scroll up/down through the pages, the way
	// the Menu2 draws its own scroll hint for the beacon list.
	static function drawPageIndicator(dc) as Void {
		var count = $.ctrl.PAGE_COUNT;
		var current = $.ctrl.currentPage;

		var spacing = 10;                 // vertical gap between dots
		var r = 2;                        // dot radius
		var x = dc.getWidth() - 6;        // hug the right edge
		var totalH = (count - 1) * spacing;
		var y = dc.getHeight() / 2 - totalH / 2;

		for(var i = 0; i < count; i++) {
			if(i == current) {
				dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
				dc.fillCircle(x, y + i * spacing, r + 1);
			} else {
				dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
				dc.fillCircle(x, y + i * spacing, r);
			}
		}
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
	}

}
