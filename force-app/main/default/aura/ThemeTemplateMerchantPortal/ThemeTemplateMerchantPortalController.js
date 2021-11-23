({

    afterScriptsLoaded: function(cmp) {
        try{
            svg4everybody({
                nosvg: true, // shiv <svg> and <use> elements and use image fallbacks
                polyfill: true // polyfill <use> elements for External Content
            });
        } catch (e) {
            console.log('failed to run svg4everybody')
            console.error(e)
        }  
    },

    doInit: function(cmp) {
        // retrieve community URL
        var action = cmp.get("c.retrieveMerchantPortalCommunityURL");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set('v.homeURL', response.getReturnValue());
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    }
});