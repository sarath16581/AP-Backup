({

    queue: [],

    initialise: function(cmp) {
        // after the lightning script has loaded we process the queue
		this.processQueue(cmp);
    },

	/**
	 * Calls to methods in this component are queued until the external script loads which is required to make calls to the server
	 * AFter initialisation, the queue is processed from the initialise helper method.
	 */
    processQueue: function(cmp) {
        console.log('>> cpUtilityComponent >> processQueue');

        var i = this.queue.length;
        while(i--) {
            var item = this.queue.pop();
            item.callable(cmp, item.params);
        }
    },

	/**
	 * Add items to the queue because the external script hasn't loaded yet.
	 */
    pushQueue: function(callable, params) {
        console.log('>> cpUtilityComponent >> pushing Queue item.');
		this.queue.push({callable: callable, params: params});
    },

	/**
	 * Grabs a list of field labels for sobject fields.
	 */
    getSObjectFieldLabels: function(cmp, params) {
		if(!cmp.get('v.isLoaded')) {
			this.pushQueue(this.getSObjectFieldLabels, params);
  		} else {
			var success = params.completionCallback;
			var failed = params.errorCallback;

			// send request to the server
			window.AP_LIGHTNING_UTILS.invokeController(cmp, 'getSObjectFieldLabels', {fieldNames: params.fieldNames}, success, failed, true, params.waitingQueueComponent);
    	}
    },

	/**
	 * Grab a list of Sobject field picklist values
	 **/
    getSObjectFieldPicklistValues: function(cmp, params) {
        if(!cmp.get('v.isLoaded')) {
			this.pushQueue(this.getSObjectFieldPicklistValues, params);
		} else {
			var success = params.completionCallback;
			var failed = params.errorCallback;

			// send request to the server
			window.AP_LIGHTNING_UTILS.invokeController(cmp, 'getSObjectFieldPicklistValues', {fieldNames: params.fieldNames}, success, failed, true, params.waitingQueueComponent);
		}
    },
    
    /**
	 * Grab a list of Sobject field picklist values
	 **/
    getSystemCustomSettingListByName: function(cmp, params) {
        if(!cmp.get('v.isLoaded')) {
			this.pushQueue(this.getSystemCustomSettingListByName, params);
		} else {
			var success = params.completionCallback;
			var failed = params.errorCallback;

            // send request to the server 
			window.AP_LIGHTNING_UTILS.invokeController(cmp, 'getSystemCustomSettingListByName', {listName: params.listName, recordName: params.recordName}, success, failed, true, params.waitingQueueComponent);
		}
    }

})