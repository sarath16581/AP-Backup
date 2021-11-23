({
	/**
	 * This is called after the javascript are loaded which will always be AFTER the component's initialize event
	 * See <ltng:require> dec. in component
	 */
    initialise: function(cmp, event, helper) {
        // this allows the queue in helper to be processed.
        cmp.set('v.isLoaded', true);
		helper.initialise(cmp);
    },

	/**
	 * Retrieve a list of the field labels from the server.
	 * This will add the request to a queue to be processed only after the lisghtning script is loaded.
	 */
    getFieldLabels: function(cmp, event, helper) {
		helper.getSObjectFieldLabels(cmp, event.getParam('arguments'));
    },

    /**
	 * Retrieve a list of picklist values based on the fields passed in.
	 */
	getFieldPicklistValues: function(cmp, event, helper) {
		helper.getSObjectFieldPicklistValues(cmp, event.getParam('arguments'));
	},
    
    
    /**
	 * Retrieve a custom setting based on the fields passed in.
	 */
	getCustomSettingListByName: function(cmp, event, helper) {
		helper.getSystemCustomSettingListByName(cmp, event.getParam('arguments'));
	}
    
})