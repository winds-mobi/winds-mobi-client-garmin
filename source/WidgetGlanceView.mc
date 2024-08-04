using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

(:glance)
class WidgetGlanceView extends Ui.GlanceView {
	
    function initialize() {
      GlanceView.initialize();
    }
    
    function onUpdate(dc) {
        var app = Application.getApp();

    	 dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
         dc.drawText(10, 0, Graphics.FONT_TINY, "winds.mobi", Graphics.TEXT_JUSTIFY_LEFT);

        var cache = Application.Storage.getValue("weather");

        if(cache != null) {

          var avg = cache["last"]["w-avg"];
          var max = cache["last"]["w-max"];

          if(app.getProperty("mesure_unit") == 1) {
              avg = convertKmhToKts(avg);
              max = convertKmhToKts(max);
          }

          dc.drawText(10, 20, Graphics.FONT_XTINY, cache["name"], Graphics.TEXT_JUSTIFY_LEFT);
          dc.drawText(10, 35, Graphics.FONT_XTINY, avg.format("%.1f") + " / " + max.format("%.1f"), Graphics.TEXT_JUSTIFY_LEFT);
        }
    }    
      
   function convertKmhToKts(speed) {
		if(speed > 0) {
			return speed * 0.539957;
		}else{
			return 0;
		}
	}

}