({
	backClicked : function(cmp, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": cmp.get('v.backButtonUrl')
        });
        urlEvent.fire();
	}
})