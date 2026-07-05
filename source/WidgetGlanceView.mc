using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Math;
using Toybox.Application;
using Toybox.Lang;

//! Glance shown in the widget carousel: freshness dot + station name + time on
//! the top row, a wind-direction arrow + the avg/max speed as the hero below.
//! Kept self-contained (no Utils dependency) to stay within the glance memory
//! budget.
(:glance)
class WidgetGlanceView extends Ui.GlanceView {

	function initialize() {
		GlanceView.initialize();
	}

	function onUpdate(dc) {
		var app = Application.getApp();

		var w = dc.getWidth();
		var h = dc.getHeight();
		var hXT = dc.getFontHeight(Gfx.FONT_XTINY);
		var hHero = dc.getFontHeight(Gfx.FONT_TINY);

		var cache = Application.Storage.getValue("weather");

		if(cache == null) {
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
			dc.drawText(0, 0, Gfx.FONT_TINY, "WINDS.MOBI", Gfx.TEXT_JUSTIFY_LEFT);
			dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
			dc.drawText(0, hHero, Gfx.FONT_XTINY, "no data", Gfx.TEXT_JUSTIFY_LEFT);
			return;
		}

		var last = cache["last"];
		if(last == null || last["w-avg"] == null || last["w-max"] == null) {
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
			dc.drawText(0, 0, Gfx.FONT_XTINY, fitText(dc, cache["name"], Gfx.FONT_XTINY, w), Gfx.TEXT_JUSTIFY_LEFT);
			dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
			dc.drawText(0, hHero, Gfx.FONT_XTINY, "no data", Gfx.TEXT_JUSTIFY_LEFT);
			return;
		}
		var avg = last["w-avg"];
		var max = last["w-max"];
		var dir = last["w-dir"];
		var lastTime = last["_id"];
		var unit = "kmh";

		if(app.getProperty("mesure_unit") == 1) {
			avg = convertKmhToKts(avg);
			max = convertKmhToKts(max);
			unit = "kts";
		}

		// ---- Top row: freshness dot + name (left) ......... time (right) ----
		var dotR = 3;
		var dotCy = hXT / 2;
		dc.setColor(freshnessColor(lastTime), Gfx.COLOR_TRANSPARENT);
		dc.fillCircle(dotR, dotCy, dotR);

		var timeStr = "";
		try {
			var t = new Time.Moment(lastTime);
			var ti = Gregorian.info(t, Time.FORMAT_SHORT);
			timeStr = Lang.format("$1$:$2$", [ti.hour, ti.min.format("%02d")]);
		} catch (e) {
			//@todo
		}

		var timeW = (timeStr.length() > 0) ? dc.getTextWidthInPixels(timeStr, Gfx.FONT_XTINY) : 0;
		if(timeW > 0) {
			dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
			dc.drawText(w, 0, Gfx.FONT_XTINY, timeStr, Gfx.TEXT_JUSTIFY_RIGHT);
		}

		var nameX = dotR * 2 + 4;
		var nameMax = w - nameX - timeW - 6;
		var name = fitText(dc, cache["name"], Gfx.FONT_XTINY, nameMax);
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawText(nameX, 0, Gfx.FONT_XTINY, name, Gfx.TEXT_JUSTIFY_LEFT);

		// ---- Hero row: direction arrow + avg / max speed --------------------
		var heroY = hXT + 1;
		var arrowR = hHero / 2 - 2;
		var arrowCx = arrowR + 1;
		var arrowCy = heroY + hHero / 2;
		var speedX = arrowCx + arrowR + 5;
		if(dir != null) {
			windArrow(dc, arrowCx, arrowCy, arrowR, dir, Gfx.COLOR_BLUE);
		} else {
			speedX = 0;
		}

		var speed = avg.format("%.0f") + " / " + max.format("%.0f") + " " + unit;
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawText(speedX, heroY, Gfx.FONT_TINY, speed, Gfx.TEXT_JUSTIFY_LEFT);
	}

	// Filled triangle pointing toward the bearing the wind comes FROM
	// (same convention as CompassView). Falls back to an outline if the device
	// has no fillPolygon.
	function windArrow(dc, cx, cy, r, bearing, color) {
		var a = bearing * Math.PI / 180.0;
		var aL = (bearing + 140) * Math.PI / 180.0;
		var aR = (bearing - 140) * Math.PI / 180.0;
		var rb = r * 0.85;
		var tip = [cx + r * Math.sin(a), cy - r * Math.cos(a)];
		var left = [cx + rb * Math.sin(aL), cy - rb * Math.cos(aL)];
		var right = [cx + rb * Math.sin(aR), cy - rb * Math.cos(aR)];

		dc.setColor(color, Gfx.COLOR_TRANSPARENT);
		if(dc has :fillPolygon) {
			dc.fillPolygon([
				[tip[0].toNumber(), tip[1].toNumber()],
				[left[0].toNumber(), left[1].toNumber()],
				[right[0].toNumber(), right[1].toNumber()]
			]);
		} else {
			dc.setPenWidth(2);
			dc.drawLine(tip[0], tip[1], left[0], left[1]);
			dc.drawLine(tip[0], tip[1], right[0], right[1]);
			dc.drawLine(left[0], left[1], right[0], right[1]);
			dc.setPenWidth(1);
		}
	}

	// Green < 1 h, orange < 2 h, red beyond (age of the observation).
	function freshnessColor(lastTime) {
		var diff = Time.now().value() - lastTime;
		if(diff < 3600) { return Gfx.COLOR_GREEN; }
		if(diff < 7200) { return Gfx.COLOR_ORANGE; }
		return Gfx.COLOR_RED;
	}

	// Truncate text with an ellipsis so it fits within maxW pixels.
	function fitText(dc, text, font, maxW) {
		if(text == null) { return ""; }
		if(dc.getTextWidthInPixels(text, font) <= maxW) { return text; }
		while(text.length() > 1 && dc.getTextWidthInPixels(text + "...", font) > maxW) {
			text = text.substring(0, text.length() - 1);
		}
		return text + "...";
	}

	function convertKmhToKts(speed) {
		if(speed > 0) {
			return speed * 0.539957;
		} else {
			return 0;
		}
	}
}
