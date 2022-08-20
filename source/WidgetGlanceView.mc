using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

(:glance)
class WidgetGlanceView extends Ui.GlanceView {
	
    function initialize() {
      GlanceView.initialize();
    }
    
    function onUpdate(dc) {
    	 dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
         dc.drawText(10, 0, Graphics.FONT_TINY, "winds.mobi", Graphics.TEXT_JUSTIFY_LEFT);
         dc.drawText(10, 20, Graphics.FONT_XTINY, "", Graphics.TEXT_JUSTIFY_LEFT);
         dc.drawText(10, 40, Graphics.FONT_XTINY, "", Graphics.TEXT_JUSTIFY_LEFT);
    }
}