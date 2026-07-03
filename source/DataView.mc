import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian as Gregorian;
import Toybox.Time;
import Toybox.Lang;

//! Page 0: current observation of the selected beacon
//! (provider, altitude, name, Avg / Max / Delta table, direction, freshness).
class DataView extends WatchUi.View {

	var app = Application.getApp();

	function initialize() {
		View.initialize();
	}

	// Load the native input-hint layout (arc at the START / right-top button).
	function onLayout(dc as Dc) as Void {
		setLayout(Rez.Layouts.StartHint(dc));
	}

	function onUpdate(dc as Dc) as Void {
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		var info = $.ctrl.info;

		if($.ctrl.hasData()) {
			drawRequestedData(dc, info);
		} else if(info != null && info["last"] == null) {
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
			if(info["detail"] != null) {
				dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_XTINY, info["detail"], (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			} else {
				dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_MEDIUM, "STATION ERROR ...", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			}
		} else {
			drawLoading(dc);
		}

		// Native Garmin button hint (arc at START), only useful with several
		// beacons. Auto-positioned per device; absent on button-less devices.
		if($.itemMemu.size() >= 2) {
			var hint = findDrawableById("startHint");
			if(hint != null) {
				hint.draw(dc);
			}
		}
	}

	function drawLoading(dc) as Void {
		if($.itemMemu.size() > 0) {
			dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_MEDIUM, "Loading ...", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		} else if(app.getProperty("enable_gps") == true && !$.nearestStationsFound) {
			dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_MEDIUM, "Waiting GPS ...", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		} else {
			dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_SMALL, "No station found", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		}
	}

	function drawRequestedData(dc, info) as Void {

		var fontXTinyH = dc.getFontHeight(Gfx.FONT_XTINY);
		var fontTinyH = dc.getFontHeight(Gfx.FONT_TINY);

		var currentHeight = fontTinyH;

		var windAvgKmh = info["last"]["w-avg"];
		var windAvg = Utils.convSpeed(windAvgKmh);
		var windMax = Utils.convSpeed(info["last"]["w-max"]);
		var lastTime = info["last"]["_id"];
		var altiValue = info["alt"];
		var altiLabel = "m";

		if(Utils.useKts()) {
			altiValue = Utils.convertMetersToFeet(altiValue);
			altiLabel = "ft";
		}

		var sector = WatchUi.loadResource(Utils.orientation(info["last"]["w-dir"]));
		var provider = info["pv-name"];
		var baliseName = info["name"];

		if(baliseName.length() > 18) {
			baliseName = baliseName.substring(0, 18) + "...";
		}

		var altitude = altiValue + " " + altiLabel;
		dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_XTINY, provider, Gfx.TEXT_JUSTIFY_CENTER);
		currentHeight = currentHeight + fontXTinyH;

		dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_XTINY, altitude, Gfx.TEXT_JUSTIFY_CENTER);
		currentHeight = currentHeight + fontXTinyH;
		dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_TINY, baliseName, Gfx.TEXT_JUSTIFY_CENTER);
		currentHeight = currentHeight + fontTinyH;

		// Gust factor (turbulence): peak gust / mean wind, coloured by roughness.
		var gf = Utils.gustFactor(windAvgKmh, info["last"]["w-max"]);
		if(gf != null) {
			dc.setColor(Utils.gustColor(gf), Gfx.COLOR_BLACK);
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_XTINY, "GF x" + gf.format("%.1f"), Gfx.TEXT_JUSTIFY_CENTER);
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
		}

		var deltatext = "";
		var delta = $.ctrl.trend();
		if(delta != null) {
			var d = Utils.convSpeed(delta.abs());
			if(delta < 0) { d = -d; }
			deltatext = Utils.getSign(delta) + d.format("%.1f");
		}

		var positionY = dc.getHeight() / 2;
		var positionX = 0;
		var margin = 2;
		var tabHeigh = fontTinyH;
		var tabWidth = dc.getWidth() / 3;

		dc.drawLine(positionX, positionY, dc.getWidth(), positionY);

		dc.drawText(tabWidth / 2, positionY + (tabHeigh / 2), Gfx.FONT_TINY, "Avg", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		dc.drawText(tabWidth + (tabWidth / 2), positionY + (tabHeigh / 2), Gfx.FONT_TINY, "Max", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		dc.drawText(tabWidth + tabWidth + (tabWidth / 2), positionY + (tabHeigh / 2), Gfx.FONT_TINY, "Δ h-1", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));

		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
		dc.drawText(tabWidth / 2, positionY + tabHeigh + (tabHeigh / 2), Gfx.FONT_TINY, windAvg.format("%.1f"), (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		dc.drawText(tabWidth + (tabWidth / 2), positionY + tabHeigh + (tabHeigh / 2), Gfx.FONT_TINY, windMax.format("%.1f"), (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		dc.drawText(tabWidth + tabWidth + (tabWidth / 2), positionY + tabHeigh + (tabHeigh / 2), Gfx.FONT_TINY, deltatext, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));

		dc.drawLine(positionX + tabWidth, dc.getHeight() / 2, positionX + tabWidth, dc.getHeight() / 2 + tabHeigh + tabHeigh);
		positionY = positionY + tabHeigh;
		dc.drawLine(positionX, positionY, dc.getWidth(), positionY);

		dc.drawLine(positionX + tabWidth + tabWidth, dc.getHeight() / 2, positionX + tabWidth + tabWidth, positionY + tabHeigh);

		positionY = positionY + tabHeigh;
		dc.drawLine(positionX, positionY, dc.getWidth(), positionY);

		var positionSectorY = positionY + margin;
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
		dc.drawText(dc.getWidth() / 2, positionSectorY, Gfx.FONT_SMALL, sector + " " + info["last"]["w-dir"] + "°", Gfx.TEXT_JUSTIFY_CENTER);

		try {
			var time = new Toybox.Time.Moment(lastTime);
			var timeInfo = Gregorian.info(time, Time.FORMAT_SHORT);
			drawStatus(dc, retrieveStationStatus(info), timeInfo);
		} catch (e) {
			//@todo
		}

		try {
			drawGpsStatus(dc);
		} catch (e) {
			//@todo
		}
	}

	function drawStatus(dc, status, info) as Void {
		if(status == 2) {
			dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
			var hourLast = Lang.format("$1$:$2$", [info.hour, info.min.format("%02d")]);
			dc.drawText(dc.getWidth() / 2, 0, Gfx.FONT_TINY, hourLast, Gfx.TEXT_JUSTIFY_CENTER);
		} else if(status == 1) {
			dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_BLACK);
			var hourLast = Lang.format("$1$:$2$", [info.hour, info.min.format("%02d")]);
			dc.drawText(dc.getWidth() / 2, 0, Gfx.FONT_TINY, hourLast, Gfx.TEXT_JUSTIFY_CENTER);
		} else if(status == 0) {
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
			dc.drawText(dc.getWidth() / 2, 0, Gfx.FONT_TINY, "!!!!", Gfx.TEXT_JUSTIFY_CENTER);
		}
	}

	function drawGpsStatus(dc) as Void {
		if(app.getProperty("enable_gps") == true) {
			if($.nearestStationsFound) {
				dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
			} else {
				dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
			}
			var fontXTinyH = dc.getFontHeight(Gfx.FONT_XTINY);
			dc.drawText(dc.getWidth() / 2, dc.getHeight() - fontXTinyH, Gfx.FONT_XTINY, "GPS", Gfx.TEXT_JUSTIFY_CENTER);
		}
	}

	function retrieveStationStatus(station) as Number {
		var stationValue;
		var lastValue;

		if(station["status"].equals("green")) {
			stationValue = 2;
		} else if(station["status"].equals("orange")) {
			stationValue = 1;
		} else {
			stationValue = 0;
		}

		if(station["last"]) {
			var stationTimeStamp = station["last"]["_id"];
			var currentTimeStamp = Time.now().value();
			var diffTimeStamp = currentTimeStamp - stationTimeStamp;

			var nowSub2h = 7200;
			var nowLess1h = 3600;
			var nowAdd5min = currentTimeStamp + 300;

			if(diffTimeStamp > nowSub2h) {
				lastValue = 0;
			} else if(diffTimeStamp > nowLess1h) {
				lastValue = 1;
			} else if(stationTimeStamp > nowAdd5min) {
				lastValue = 0;
			} else {
				lastValue = 2;
			}
		} else {
			lastValue = 0;
		}

		return lastValue < stationValue ? lastValue : stationValue;
	}
}
