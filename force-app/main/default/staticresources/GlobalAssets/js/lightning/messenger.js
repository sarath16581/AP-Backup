window.AP_IFRAME_PROXY = (function() {

	var $context = this,
		monitoredEvents = [],
		monitoredComponents = {},
		eventListenerEnabled = false;

	var maybeStartEventListener = function() {
		if(!eventListenerEnabled) {
		    //console.log('>> SETTING UP LIGHTNING PROXY EVENT MONITOR');

		    // make sure we only listen once
		    eventListenerEnabled = true;

		    window.addEventListener("message", function(event) {
		        for(var i=0;i<monitoredEvents.length;i++) {
		         	var componentWindow = document.getElementById(monitoredEvents[i].componentWindowId);
//		         	console.log(componentWindow.contentWindow == event.source);
//		         	console.log(monitoredEvents[i].eventType);
//		         	console.log(event.data.eventType);
//		         	console.log(isObject(event.data))
					if(componentWindow.contentWindow == event.source && event.data != null && isObject(event.data) && event.data.eventType == monitoredEvents[i].eventType) {
					    //console.log('>> RECEIVING LIGHTNING PROXY EVENT', monitoredEvents[i].eventType, event.data);

						// callback to monitored events call back
						if(monitoredEvents[i].callback)
							monitoredEvents[i].callback(event.data);
					}
          		}
			}, false);
  		}
 	};

	/**
	 * When the LightningComponentWrapper page receives a monitored event from a lightning component, this is sent back up to the main page
	 * This will only ever be called in the LightningComponentWrapper page.
	 */
	var proxyLightningEvent = function(event) {
	    var eventType = event.getType();
	    var params = event.getParams();
	    if(!isObject(params))
	    	params = {};

	    params.eventType = eventType;
		window.parent.postMessage(params, '*');
 	};

	/**
	 * On the main visualforce page, this is used to monitor for proxied events that have come from a lightning component and been proxied through the LightningComponentWrapper page.
	 * This ensure that only 1 listener event is created per window and will add any number of proxied events to listen for
	 */
 	var monitorProxiedEvent = function(componentWindowId, eventType, callback) {
 	    monitoredComponents[componentWindowId] = true;
 	    monitoredEvents.push({componentWindowId: componentWindowId, eventType: eventType, callback: callback});
 	    maybeStartEventListener();
  	};

  	var isObject = function(value) {
  	    return Object.prototype.toString.call(value).indexOf('Object') !== -1;
   	};

   	var isArray = function(value) {
    	return Object.prototype.toString.call(value).indexOf('Array') !== -1;
    };

    return {
        proxyLightningEvent: proxyLightningEvent,
        monitorProxiedEvent: monitorProxiedEvent
    }
})();