window.AP_CORS_MESSENGER = (function() {

	var monitoredEvents = [],
		eventListenerEnabled = false;

	var maybeStartEventListener = function() {
		if(!eventListenerEnabled) {
			// make sure we only listen once
			eventListenerEnabled = true;

			window.addEventListener("message", function(event) {
				for(var i=0;i<monitoredEvents.length;i++) {
					if(monitoredEvents[i].senderWindow == event.source && event.data != null && isObject(event.data) && event.data.eventType === monitoredEvents[i].eventType) {
						// callback to monitored events call back
						if (monitoredEvents[i].callback)
							monitoredEvents[i].callback(event.data);
					}
				}
			}, false);
		}
	};

	var push = function(window, eventType, params) {
		params = params || {};
		params.eventType = eventType;
		window.postMessage(params, '*');
	};

	var get = function(fromWhichSender, eventType, callback) {
		monitoredEvents.push({senderWindow: fromWhichSender, eventType: eventType, callback: callback});
		maybeStartEventListener();
	};

	var setHeightPullMonitor = function(iframePullTarget) {
		get(iframePullTarget.contentWindow, 'heightChange', function(data) {
			iframePullTarget.style.height = data.height + 'px';
		})
	};

	var setHeightPushMonitor = function(pushTarget) {
		var lastHeight = 0;
		var config = ({childList:true, subtree:true, attributes: true });

		var callback = function() {
			var height = document.body.scrollHeight;
			if(lastHeight !== height) {
				lastHeight = height;
				push(pushTarget, 'heightChange', {height: document.body.scrollHeight});
			}
		};

		// Create an observer instance linked to the callback function
		MutationObserver = window.MutationObserver || window.WebKitMutationObserver;
		if(MutationObserver != null) {
			var observer = new MutationObserver(callback);
			observer.observe(document, config);
		}

		// a secondary call to catch resize events
		var timerId = null;
		window.onresize = function(e) {
			if(timerId != null) clearTimeout(timerId);
			timerId = setTimeout(callback, 10);
		}

	};


	var isObject = function(value) {
		return Object.prototype.toString.call(value).indexOf('Object') !== -1;
	};

	var isArray = function(value) {
		return Object.prototype.toString.call(value).indexOf('Array') !== -1;
	};

	return {
		push: push,
		get: get,

		// monitor for messages from an iframe that has called 'pushHeight'
		setHeightPullMonitor: setHeightPullMonitor,

		// broadcast a message to a parent window when the height of the document changes
		// this is paired with the parent window calling 'monitorHeight' to automatically receive these messages and adjust the frame height accordingly
		setHeightPushMonitor: setHeightPushMonitor
	}
});