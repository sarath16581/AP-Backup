({
    doInit : function(cmp, event, helper) {
        helper.fetchLoggedInUserCases(cmp);    
    },

    gotoHelpAndSupport : function(cmp, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url": "https://auspost.com.au/help-and-support"
		});
		urlEvent.fire();
    }
})