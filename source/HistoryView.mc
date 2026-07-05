import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Graphics as Gfx;
import Toybox.Lang;

//! Page 1: line chart of the average wind and gusts over the last hour.
//! Data comes from ctrl.hist (newest sample first).
class HistoryView extends WatchUi.View {

	function initialize() {
		View.initialize();
	}

	function onUpdate(dc as Dc) as Void {
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		var hist = $.ctrl.hist;
		if(hist == null || !(hist instanceof Lang.Array) || hist.size() < 2) {
			dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_SMALL, "No history", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			Utils.drawPageIndicator(dc);
			return;
		}

		var w = dc.getWidth();
		var h = dc.getHeight();
		// Plot area kept well inside the (possibly round) screen so the
		// axis labels are never clipped by the bezel.
		var top = h / 4;
		var bottom = (h * 7) / 10;
		var left = w / 4;
		var right = (w * 9) / 10;
		var fontH = dc.getFontHeight(Gfx.FONT_XTINY);

		var n = hist.size();

		// Vertical scale based on the maximum gust.
		var maxV = 0.0;
		for(var i = 0; i < n; i++) {
			var g = hist[i]["w-max"];
			if(g != null && g > maxV) { maxV = g; }
		}
		if(maxV <= 0) { maxV = 1.0; }

		// Title: station name + unit.
		var title = ($.ctrl.info != null) ? $.ctrl.info["name"] : "";
		if(title.length() > 14) { title = title.substring(0, 14) + "..."; }
		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
		dc.drawText(w / 2, 2, Gfx.FONT_XTINY, title, Gfx.TEXT_JUSTIFY_CENTER);

		// Axes + mid gridline.
		var midY = (top + bottom) / 2;
		dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_BLACK);
		dc.drawLine(left, top, left, bottom);
		dc.drawLine(left, bottom, right, bottom);
		dc.drawLine(left, midY, right, midY);

		// Scale labels, placed inside the safe area.
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
		dc.drawText(left, top - fontH - 1, Gfx.FONT_XTINY, Utils.convSpeed(maxV).format("%.0f") + " " + Utils.speedLabel(), Gfx.TEXT_JUSTIFY_LEFT);
		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
		dc.drawText(left - 3, midY, Gfx.FONT_XTINY, Utils.convSpeed(maxV / 2).format("%.0f"), (Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER));
		dc.drawText(left - 3, bottom, Gfx.FONT_XTINY, "0", (Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER));
		dc.drawText(left, bottom + 3, Gfx.FONT_XTINY, "-1h", Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(right, bottom + 3, Gfx.FONT_XTINY, "now", Gfx.TEXT_JUSTIFY_RIGHT);

		// Gust line first (behind), then average.
		drawSerie(dc, hist, "w-max", left, right, top, bottom, maxV, Gfx.COLOR_LT_GRAY);
		drawSerie(dc, hist, "w-avg", left, right, top, bottom, maxV, Gfx.COLOR_GREEN);

		Utils.drawPageIndicator(dc);
	}

	// hist[0] is the newest sample -> plotted at the right edge.
	function drawSerie(dc, hist, key, left, right, top, bottom, maxV, color) as Void {
		dc.setColor(color, Gfx.COLOR_BLACK);
		dc.setPenWidth(2);

		var n = hist.size();
		var prevX = null;
		var prevY = null;
		var plotW = right - left;
		var plotH = bottom - top;

		for(var i = 0; i < n; i++) {
			var v = hist[i][key];
			if(v == null) {
				prevX = null;
				prevY = null;
				continue;
			}
			var x = right - (plotW * i) / (n - 1);
			var ratio = v / maxV;
			if(ratio > 1) { ratio = 1; }
			var y = bottom - (plotH * ratio);
			if(prevX != null) {
				dc.drawLine(prevX, prevY, x, y);
			}
			prevX = x;
			prevY = y;
		}
		dc.setPenWidth(1);
	}
}
