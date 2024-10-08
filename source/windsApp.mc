import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.System;
import Toybox.Time;


class windsApp extends Application.AppBase {

    function getGlanceView() {
        return [ new WidgetGlanceView() ];
    }

    function initialize() {
 
        if(Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(5 * 60));
        } else {
            System.println("****background not available on this device****");
        }

        AppBase.initialize();
    }

    public function getServiceDelegate() as Array<ServiceDelegate>{
        return [new $.WindsSpeedDelegate()] as Array<ServiceDelegate>;
    }

   	function onBackgroundData(data) {
		//$.p(data);
		// Process only if no BLE error
		if (data != null) {
			Application.Storage.setValue("weather", data);
		}
	}


    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
    
    	var isBTConnected= System.getDeviceSettings().phoneConnected;
    	if(isBTConnected) {
        	return [new $.windsView(0), new $.WindsViewDelegate(0)] as Array<Views or InputDelegates>;
        } else{
        	return [new $.notConnectedView()] as Array<Views or InputDelegates>;
        }
    }

}

function getApp() as windsApp {
    return Application.getApp() as windsApp;
}