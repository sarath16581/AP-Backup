/**
 *
 * History :
 * --------------------------------------------------
 * 2019-09-22 hasantha.liyanage@auspost.com.au Modified : added onInitLoad method to replace the thanks you message text with blank.
 * 2020-08-17 hara.sahoo@auspost.com.au Modified : added custom message SafeDropCaseThankYouMessage for safedrop flow
 * 2020-10-12 hara.sahoo@auspost.com.au Modified : Code fix for SafeDropCaseThankYouMessage
 * 2020-10-26 hara.sahoo@auspost.com.au Modified : added custom message for network eligible cases created from delivery issue form
 */

({
    onInitLoad : function(component, event, helper) {
        // caseThankYouMessage message is retrived from a commonly used label, and the change required to replace the "MyPost dashboard now" text
        // and this will be displaed as a link to dashboard in the component UI.
        var caseThankYouMessage = $A.get('$Label.c.CaseThankYouMessage');
        caseThankYouMessage = caseThankYouMessage.replace('MyPost dashboard now', ' ');
        component.set('v.caseThankYouMessage', caseThankYouMessage);
        //--fetch the flags to decide on the thank you message
        var hasCustomerSeenSafedropImage = component.get("v.hasCustomerSeenSafedropImage");
        var isEligibleForNetworkDeliveryIssue = component.get("v.isEligibleForNetworkDeliveryIssue");
        //check for network eligibility for cases created from delivery issue form
        if (isEligibleForNetworkDeliveryIssue == true)
        {
            var nextSteps = component.find("nextSteps");
            nextSteps.set("v.value","<br/><br/>We've sent the feedback about your item to the relevant delivery centre.<br/><br/>The local delivery team will review, check-in with the Postie, and make a note on your account for the next time we deliver to your address.<br/><br/>If there is a specific reason for the way the delivery was attempted, we'll contact you as soon as we can to discuss, if required.<br/><br/>Otherwise, we appreciate you taking the time to let us know how we can improve our delivery services. This enquiry can be found by visiting your");
        }
        //check if the image is captured via the safedrop flow
        //2020-10-12- Code fix for SafeDropCaseThankYouMessage
        if (hasCustomerSeenSafedropImage == 'true')
        {
            caseThankYouMessage = $A.get('$Label.c.SafeDropCaseThankYouMessage');
            component.set('v.caseThankYouMessage', caseThankYouMessage);
        }
        var transferToPo = component.get("v.transferToPo");
        if(component.get("v.transferToPo") == true)
        {
           caseThankYouMessage = $A.get('$Label.c.TransferToPoThankYouMessage');
            component.set('v.caseThankYouMessage', caseThankYouMessage);
        }
    }
})