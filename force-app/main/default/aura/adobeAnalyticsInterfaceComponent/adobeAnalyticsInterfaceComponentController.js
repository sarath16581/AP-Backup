/**************************************************
 Description: Component for handling Adobe Analytics integration

 History:
 --------------------------------------------------
 2019-08-27  nathan.franklin@auspost.com.au  Created
 **************************************************/
({
    initialise: function(component, event, helper) {
        var action = component.get('c.retrieveUserDetails');
        action.setStorable();
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.apcn', result.apcn);
                component.set('v.isLoggedIn', result.isLoggedIn);
            }
            component.set('v.isLoaded', true);

            // process any tracking messages that were queued during the callout
            helper.handleQueue(component, helper);
        });
        $A.enqueueAction(action);
    },

    handleAdobeAnalyticsEvent: function(component, event, helper) {
        var trackingType = event.getParam('trackingType');
        var componentAttributes = event.getParam('componentAttributes');
        var interactionCategory = event.getParam('interactionCategory');
        var interactionDescription = event.getParam('interactionDescription');

        var obj = {
            type: trackingType,
            attributes: componentAttributes,
            interactionCategory: interactionCategory,
            interactionDescription: interactionDescription
        };

        helper.queueMessage(component, helper, obj);
    }
});