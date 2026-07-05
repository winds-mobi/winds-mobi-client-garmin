import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Graphics as Gfx;
import Toybox.Lang;

//! Page 3: min / max / average of the average wind over the last hour,
//! plus the strongest gust. (README To-Do item.)
class StatsView extends WatchUi.View {

	function initialize() {
		View.initialize();
	}

	function onUpdate(dc as Dc) as Void {
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		var hist = $.ctrl.hist;
		if(hist == null || !(hist instanceof Lang.Array) || hist.size() < 1) {
			dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_SMALL, "No history", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			Utils.drawPageIndicator(dc);
			return;
		}

		var mn = null;
		var mx = 0.0;
		var sum = 0.0;
		var cnt = 0;
		var gust = 0.0;
		var sumGf = 0.0;
		var cntGf = 0;

		for(var i = 0; i < hist.size(); i++) {
			var a = hist[i]["w-avg"];
			if(a != null) {
				if(mn == null || a < mn) { mn = a; }
				if(a > mx) { mx = a; }
				sum += a;
				cnt++;
			}
			var g = hist[i]["w-max"];
			if(g != null && g > gust) { gust = g; }
			if(a != null && a > 0 && g != null) {
				sumGf += g.toFloat() / a;
				cntGf++;
			}
		}

		if(mn == null) { mn = 0.0; }
		var avg = (cnt > 0) ? sum / cnt : 0.0;
		var gfAvg = (cntGf > 0) ? sumGf / cntGf : null;
		var unit = Utils.speedLabel();

		var w = dc.getWidth();
		var h = dc.getHeight();
		var lineH = dc.getFontHeight(Gfx.FONT_TINY);
		var y = h / 5;

		dc.drawText(w / 2, 2, Gfx.FONT_XTINY, "Last hour", Gfx.TEXT_JUSTIFY_CENTER);

		y = drawRow(dc, w, y, lineH, "Min", Utils.convSpeed(mn), unit, Gfx.COLOR_LT_GRAY);
		y = drawRow(dc, w, y, lineH, "Avg", Utils.convSpeed(avg), unit, Gfx.COLOR_GREEN);
		y = drawRow(dc, w, y, lineH, "Max", Utils.convSpeed(mx), unit, Gfx.COLOR_WHITE);
		y = drawRow(dc, w, y, lineH, "Gust", Utils.convSpeed(gust), unit, Gfx.COLOR_ORANGE);

		// Gust factor (turbulence) averaged over the hour.
		if(gfAvg != null) {
			dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
			dc.drawText(w / 4, y, Gfx.FONT_TINY, "GF", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			dc.setColor(Utils.gustColor(gfAvg), Gfx.COLOR_BLACK);
			dc.drawText((w * 3) / 4, y, Gfx.FONT_TINY, "x" + gfAvg.format("%.1f"), (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		}

		Utils.drawPageIndicator(dc);
	}

	function drawRow(dc, w, y, lineH, label, value, unit, color) {
		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
		dc.drawText(w / 4, y, Gfx.FONT_TINY, label, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		dc.setColor(color, Gfx.COLOR_BLACK);
		dc.drawText((w * 3) / 4, y, Gfx.FONT_TINY, value.format("%.1f") + " " + unit, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		return y + lineH + 4;
	}
}
