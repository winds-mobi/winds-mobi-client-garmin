using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian as Gregorian;

(:glance)
class WidgetGlanceView extends Ui.GlanceView {
	
    function initialize() {
      GlanceView.initialize();
    }
    
    function onUpdate(dc) {
        var app = Application.getApp();

    	 dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
         

        var cache = Application.Storage.getValue("weather");

        if(cache != null) {

          var avg = cache["last"]["w-avg"];
          var max = cache["last"]["w-max"];
          var lastTime = cache["last"]["_id"];
          var sign = "kmh";

          if(app.getProperty("mesure_unit") == 1) {
              avg = convertKmhToKts(avg);
              max = convertKmhToKts(max);
              sign = "kts";
          }

          var orientation = cache["last"]["w-dir"];
          dc.drawText(0, 0, Graphics.FONT_XTINY , cache["name"], Graphics.TEXT_JUSTIFY_LEFT);
          dc.drawText(0, 20, Graphics.FONT_XTINY, avg.format("%.1f") + " / " + max.format("%.1f") + " " + sign, Graphics.TEXT_JUSTIFY_LEFT);
          dc.drawText(0, 40, Graphics.FONT_XTINY, orientation + "°", Graphics.TEXT_JUSTIFY_LEFT);
          

          try {
            var time = new Toybox.Time.Moment(lastTime);	
            var info = Gregorian.info(time, Time.FORMAT_SHORT);	
            var hourLast = Lang.format("$1$:$2$",[info.hour, info.min.format("%02d")]);
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
            dc.drawText(dc.getWidth(), 40, Gfx.FONT_XTINY, hourLast, Gfx.TEXT_JUSTIFY_RIGHT);
          } catch (e) {
        		//@todo
        	}

        }else{
          dc.drawText(0, 0, Graphics.FONT_XTINY, "WINDS.MOBI", Graphics.TEXT_JUSTIFY_LEFT);
          dc.drawText(10, 20, Graphics.FONT_XTINY, "--", Graphics.TEXT_JUSTIFY_LEFT);
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