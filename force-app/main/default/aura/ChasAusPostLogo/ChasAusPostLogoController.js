({
    gotoApHome: function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "https://auspost.com.au/"
        });
        urlEvent.fire();
    }
})