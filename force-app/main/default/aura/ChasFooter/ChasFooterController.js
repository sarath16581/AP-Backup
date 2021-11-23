({
    /* Added below code on 19/10/2018 for Header and Footer changes for mobile App. */
    /* Comparing the user agent string from mobile App and setting the status to show or hide. */
    doInit: function(cmp, event, helper) {
        var agentString = "";
        //Get the user agent string.
        agentString = navigator.userAgent;
        //Checking the user agent string for iOS or Android.
        if(agentString == 'com.auspost.mobile.ios' || agentString == 'com.auspost.mobile.android'){
            //Set the status to hide.
            cmp.set('v.status', 'hide'); 
        }else{
            //Set the status to show.
            cmp.set('v.status', 'show');
        }
        
	},
	onclick : function(cmp, event, helper) {
		var url = event.target.dataset.url;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
	}
})