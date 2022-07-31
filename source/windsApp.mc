import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;


class windsApp extends Application.AppBase {

    function getGlanceView() {
        
    }

    function initialize() {
        AppBase.initialize();
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