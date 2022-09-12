({
    /**
     *   Called when component is initialised.
     */
    doInit: function (cmp, evt, hlpr) {
        cmp.invocationCallbacks = {};
        var action = cmp.get("c.getVFBaseURL");
        action.setStorable();
        action.setCallback(this, function (response) {

            var state = response.getState();
            // setting the url configs
            if (state == "SUCCESS") {
                var URLConfig = response.getReturnValue();
                // only if the loaded through a community we will need this
                var UrlPath = URLConfig.UrlPathPrefix ;

                // url path determines wheather the user is logged in from a community or aas an internal user,
                // if the user is a BSP then the prefix will not be appended
                if(typeof UrlPath !== 'undefined' && UrlPath.includes("auspostbusiness")) { //CHG0176934
                    UrlPath = '/' + URLConfig.UrlPathPrefix +'/apex/AsynchApexContinuation';
                } else {
                    UrlPath = '/apex/AsynchApexContinuation';
                }
                console.log(' AsynchApexContinuationProxyController : doInit ',UrlPath);

                // following parameters will be passed to the component where the AsynchApexContinuation will be loaded based on the context (internal or community user)
                cmp.set("v.iframeSrc", UrlPath);
                cmp.set("v.vfBaseURL", URLConfig.baseURL);


                var topic = cmp.get("v.topic");
                window.addEventListener("message", function (evt) {

                    if (evt.origin !== URLConfig.baseURL) {
                        // Not the expected origin: reject message
                        return;
                    }

                    // Only handle messages we are interested in
                    if (evt.data.topic === topic) {
                        console.log('doInit  : ',URLConfig.baseURL);
                        console.log('doInit  : ',evt.origin);
                        // Retrieve the callback for the specified invocation id
                        var callback = cmp.invocationCallbacks[evt.data.invocationId];
                        if (callback && typeof callback == 'function') {
                            callback(evt.data.result);
                            delete cmp.invocationCallbacks[evt.data.invocationId];
                        }
                    }
                }, false);
            } else if (state === "ERROR") {
                var errors = response.getError();
                var message = 'Error'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                // Display the message
                console.error('doInit url configs : ',message);
            }

        });
        $A.enqueueAction(action);
    },
    /**
     *   Trigger the call to VF message and keep tack of id in field invocationId.
     */
    doInvoke: function (cmp, evt, hlpr) {
        var vfBaseURL = cmp.get("v.vfBaseURL");
        var topic = cmp.get("v.topic");
        var args = evt.getParam("arguments");
        var invocationId = hlpr.getUniqueId();
        cmp.invocationCallbacks[invocationId] = args.callback;
        var message = {
            topic: topic,
            invocationId: invocationId,
            className : args.className,
            methodName: args.methodName,
            useAsynchCallout : args.useAsynchCallout,
            methodParams: args.methodParams
        };
        var vf = cmp.find("vfFrame").getElement().contentWindow;

        vf.postMessage(JSON.parse(JSON.stringify(message)), vfBaseURL);
    }
})