/**************************************************
 Description: Component for handling Adobe Analytics integration

 History:
 --------------------------------------------------
 2019-08-27  nathan.franklin@auspost.com.au  Created
 **************************************************/
({
    afterRender: function(component, helper) {
        this.superAfterRender();

        // used to track pageviews if the pageViewTracking is true
        // some components will include the adobe component without requiring it to track page views
        setTimeout($A.getCallback(function() {
            if(component.get('v.pageViewTracking')) {
                var attribs = helper.getAnalayticsComponentAttributes(component);
                var obj = {
                    type: component.get('v.pageViewTrackingType'),
                    attributes: attribs
                };
                helper.queueMessage(component, helper, obj);
            }
        }), 3000); // <-- don't know why the 3 second delay was in place when taking it this from the old analytics... possibly to give the apex processing time to complete ??
    }
})