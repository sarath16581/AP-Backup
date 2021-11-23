({
    hideModal : function(cmp, event, helper) {
        //closes the modal or popover from the component
        cmp.find("overlayLib").notifyClose();
    },
    closeCase: function(cmp, event, helper) {
    	if (!cmp.get('v.isLoading')) {
	    	cmp.set('v.isLoading', true);
	    	cmp.find('submitButton').set('v.label', "");
	    	cmp.get('v.closeCaseAction').call(this, $A.getCallback(function() {
	    		cmp.find("overlayLib").notifyClose();
	    	}));
	    }
    },
})