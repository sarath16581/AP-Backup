({

    initialise: function(cmp, helper, ev) {
        AP_LIGHTNING_UTILS.invokeController(cmp, "retrieveUserDetails", {}, function(result) {
            // success callback

            cmp.set('v.apcn', result.apcn);
            cmp.set('v.isLoggedIn', result.isLoggedIn);


            window.setTimeout(
                $A.getCallback(function() {

                    analytics.page.pageData.sitePrefix = 'auspost:' + cmp.get('v.sitePrefix');
                    analytics.page.pageData.pageAbort = "true";
                    analytics.user.userData.apcn = cmp.get('v.apcn');
                    analytics.user.userData.loginStatus = (cmp.get('v.isLoggedIn') ? 'authenticated' : 'anonymous'); //For users in logged in state

                    // page specific data
                    analytics.page.pageData.pageCategory = cmp.get('v.pageCategory');
                    analytics.page.pageData.pageDescription = cmp.get('v.pageDescription');

                    _satellite.track(cmp.get('v.trackingType'));

                }), 1000
            );

        }, false);
    }

});