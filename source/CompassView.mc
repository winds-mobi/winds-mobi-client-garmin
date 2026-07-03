import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.Math;
import Toybox.Lang;

//! Page 2: a compass rose with an arrow pointing to the direction the wind
//! comes FROM.
class CompassView extends WatchUi.View {

	function initialize() {
		View.initialize();
	}

	function onUpdate(dc as Dc) as Void {
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		if(!$.ctrl.hasData()) {
			dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_SMALL, "No data", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			return;
		}

		var info = $.ctrl.info;
		var w = dc.getWidth();
		var h = dc.getHeight();
		var cx = w / 2;
		var cy = h / 2;
		var radius = (w < h ? w : h) / 2 - (h / 8);

		// Compass circle.
		dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_BLACK);
		dc.setPenWidth(2);
		dc.drawCircle(cx, cy, radius);
		dc.setPenWidth(1);

		// Cardinal labels.
		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
		var labelR = radius + (h / 16);
		drawAtBearing(dc, cx, cy, labelR, 0, "N");
		drawAtBearing(dc, cx, cy, labelR, 90, "E");
		drawAtBearing(dc, cx, cy, labelR, 180, "S");
		drawAtBearing(dc, cx, cy, labelR, 270, "W");

		// Wind arrow: points to where the wind comes from.
		var dir = info["last"]["w-dir"];
		var avgKmh = info["last"]["w-avg"];

		dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_BLACK);
		dc.setPenWidth(4);
		var tip = bearingPoint(cx, cy, radius - 4, dir);
		var tail = bearingPoint(cx, cy, radius - 4, dir + 180);
		dc.drawLine(tail[0], tail[1], tip[0], tip[1]);
		drawArrowHead(dc, cx, cy, radius - 4, dir);
		dc.setPenWidth(1);

		// Center readout: cardinal + degrees, then avg / max.
		var sector = WatchUi.loadResource(Utils.orientation(dir));
		var avg = Utils.convSpeed(avgKmh);
		var max = Utils.convSpeed(info["last"]["w-max"]);
		var fontTinyH = dc.getFontHeight(Gfx.FONT_TINY);

		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
		dc.drawText(cx, cy - fontTinyH, Gfx.FONT_TINY, sector + " " + dir + "°", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		dc.drawText(cx, cy + fontTinyH / 2, Gfx.FONT_XTINY, avg.format("%.0f") + " / " + max.format("%.0f") + " " + Utils.speedLabel(), (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
	}

	// Point on a circle of given radius at a compass bearing (0 = North, clockwise).
	function bearingPoint(cx, cy, r, bearing) {
		var a = bearing * Math.PI / 180.0;
		var x = cx + r * Math.sin(a);
		var y = cy - r * Math.cos(a);
		return [x.toNumber(), y.toNumber()];
	}

	function drawAtBearing(dc, cx, cy, r, bearing, text) as Void {
		var p = bearingPoint(cx, cy, r, bearing);
		dc.drawText(p[0], p[1], Gfx.FONT_XTINY, text, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
	}

	// Two short strokes forming a "V" at the arrow tip.
	function drawArrowHead(dc, cx, cy, r, bearing) as Void {
		var tip = bearingPoint(cx, cy, r, bearing);
		var l = bearingPoint(cx, cy, r - (r / 4), bearing - 12);
		var rp = bearingPoint(cx, cy, r - (r / 4), bearing + 12);
		dc.drawLine(tip[0], tip[1], l[0], l[1]);
		dc.drawLine(tip[0], tip[1], rp[0], rp[1]);
	}
}
