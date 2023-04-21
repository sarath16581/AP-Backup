/**
 * Created by nmain on 13/11/2017.
 *
 * History :
 * --------------------------------------------------
 * 2020-02-12 gunith.devasurendra@auspost.com.au Added support for Adobe Analytics to get Network Eligibility
 * 2020-04-03 rufus.solomon@auspost.com.au Added support for essential pharma
 * 2020-07-28 hara.sahoo@auspost.com.au Reset the showErrorSummary flag, to display the error summary.
 * 2020-11-23 hara.sahoo@auspost.com.au Special handling for 403 response code for missing item form
 * 2020-11-26 hara.sahoo@auspost.com.au Added click tracking for adobe analytics
 * 2022-02-28 alex.volkov@auspost.com.au Added deflection page skip option
 * 2023-04-21 StephenL added logic to skip the deflection page is the EDD Status is LATE
 */

({
    
    
    init: function(component, event, helper) {
        var statusCode = component.get('v.wizardData.trackingNumSerachStatusCode');
        let eddStatus = component.get('v.wizardData.eddStatus');
        //show the first search section on the component
        component.set('v.displaySection','START');
        //Special handling for response code 403
        if(statusCode == 403 || component.get('v.wizardData.skipDeflectionPage') || eddStatus === 'LATE'){
            component.set('v.displaySection','START_CASE_CREATE');
            // setting the caller type (sender/Receiver) from the previous page if a value is selected
            var recipientOrSenderCallerType = component.get('v.wizardData.recipientOrSenderCallerType');
            if(recipientOrSenderCallerType) {
                component.set('v.recipientOrSenderRadioGroup',recipientOrSenderCallerType);
            }
        }
        
    },
    
    goForward: function(cmp, event, helper) {        
        var isValid = helper.checkAllInputs(cmp, true);
        //reset the error flags
        cmp.set('v.error', ''); 
        var senderOrRecipientType = cmp.get("v.wizardData.senderOrRecipientType");
        var recipientOrSender = cmp.get("v.wizardData.selectedRadio1Name");
        if(senderOrRecipientType == 'International' && recipientOrSender == 'Receiver'){
            if(isValid){
                helper.gotoNextPage(cmp);
            } else {
                helper.showErrorSummary(cmp)
            } 
        } 
        //-- Check if address selected from the AME service is valid
        //-- If all validations are completed then move to next screen. Extra validation for delivery address if it is a Domestic/Sender parcel
        else {
            var deliveryAddressIsValid = helper.validateAddressNotNull(cmp, true);
            if(isValid && deliveryAddressIsValid){
                helper.gotoNextPage(cmp);
            } else {
                helper.showErrorSummary(cmp)
            }  
        }
        //Click tracking - push analytics for site-interact
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            'site-interact',
            'form:' + cmp.get('v.pageTitle'),
            'item details: ' + 'confirm:continue'
        );
        
    },
    goStartCreateCase: function(cmp, event, helper) {
        cmp.set('v.displaySection','START_CASE_CREATE');
        var deliveryAddress = cmp.get("v.wizardData.correctDeliveryAddress");
        if(!$A.util.isEmpty(deliveryAddress) || !$A.util.isUndefined(deliveryAddress))
        {
            //push analytics
            helper.pushAnalytics(cmp,'item details:confirm:prefill');
        } else {
            //push analytics
            helper.pushAnalytics(cmp,'item details:confirm');
        }
        
    },
    goBack: function (cmp, event, helper) {
        //Check the base url of the page, this is to ascertain users getting directed from a direct link
        //Also do this for multiple article selection so that previous page would show selection rather than search
        var baseUrl = window.location.href;
        if(baseUrl.includes("trackingId"))
        {
            baseUrl = baseUrl + '#';
            window.location.href = window.location.href + '#';
        }
        helper.gotoPrevPage(cmp);
    },
    onchange: function (cmp, event, helper) {
        //reset the showErrorSummary flag
        cmp.set("v.showErrorSummary",'false');
        var srcCmp = event.getSource();
        var fieldName = event.getParam("name");
        if (fieldName === 'recipientOrSenderRadioButtons') {
            helper.setRadioName(cmp, 'v.recipientOrSenderRadioGroup', 'v.wizardData.selectedRadio1', 'v.wizardData.selectedRadio1Name');
        } else if (fieldName === 'parcelOrLetterRadioButtons') {
            helper.setRadioName(cmp, 'v.parcelOrLetterRadioGroup', 'v.wizardData.selectedRadio2', 'v.wizardData.selectedRadio2Name');
            helper.removeSentTypeFromWizardData(cmp);
        } else if (fieldName === 'domesticParcelSentTypeRadioButtons') {
            helper.setRadioName(cmp, 'v.domesticParcelSentTypeRadioGroup', 'v.wizardData.selectedRadio3', 'v.wizardData.selectedRadio3Name');
        } else if (fieldName === 'domesticLetterSentTypeRadioButtons') {
            helper.setRadioName(cmp, 'v.domesticLetterSentTypeRadioGroup', 'v.wizardData.selectedRadio3', 'v.wizardData.selectedRadio3Name');
        } else if (fieldName === 'internationalParcelSentTypeRadioButtons') {
            helper.setRadioName(cmp, 'v.internationalSentTypeRadioGroup', 'v.wizardData.selectedRadio3', 'v.wizardData.selectedRadio3Name');
        } else if (fieldName === 'pharmaRadioButtons') { // Added by RSolomon to handle Pharma options
            helper.setRadioName(cmp, 'v.pharmaRadioGroup', 'v.wizardData.selectedRadio4', 'v.wizardData.selectedRadio4Name');
        } else if (fieldName === 'reasonForEnquiry'){
            helper.setRadioName(cmp, 'v.reasonForEnquiry', 'v.wizardData.selectedRadioReasonForEnquiry', 'v.wizardData.selectedRadioReasonForEnquiry');
        } else if (fieldName === 'sentimentalValueRadioButtons'){
            helper.setRadioName(cmp, 'v.sentimentalValueRadioGroup', 'v.wizardData.selectedSenti', 'v.wizardData.selectedSentiValue');
        }
        
        helper.checkInputs([srcCmp], true);
        cmp.set('v.checkInputsOnRender', true);
    },
    
    navToBsp: function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "https://auspost.com.au/business/business-admin/access-the-business-support-portal"
        });
        urlEvent.fire();
    },
    calculateDeliveryTime: function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "https://auspost.com.au/parcels-mail/calculate-postage-delivery-times/#/"
        });
        urlEvent.fire();
    },
    navToTrackingTool: function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "https://auspost.com.au/mypost/track/#/search"
        });
        urlEvent.fire();
    },
    navToMyPost: function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": " https://auspost.com.au/mypost/auth/#/register"
        });
        urlEvent.fire();
    },
    openModal: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isModalOpen", true);
    },
    
    closeModal: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
    },
    getSelectedAddress : function(cmp, event, helper) {
        helper.getSelectedAddress(cmp, event, 'AMEAddressBlock');
    },
    getOverrideAddress : function(cmp, event, helper) {
        helper.getOverrideAddress(cmp, event, 'AMEAddressBlock');
    },
    getAddressTyped:function(cmp, event, helper) {
        helper.getAddressTyped(cmp, event, 'AMEAddressBlock');
    },
    getRecipientAddressTyped:function(cmp, event, helper) {
        helper.getAddressTyped(cmp, event, 'AMEAddressBlock1');
    },
    getRecipientSelectedAddress : function(cmp, event, helper) {
        helper.getSelectedAddress(cmp, event, 'AMEAddressBlock1');
        // DDS-5928 : EDD estimate feature - when no EDD is returned from the consignment service, call the shipment edd service to get delivery estimates
        if (cmp.get('v.wizardData.eddStatus') == 'NO_EDD')
        {
            helper.getEDDServiceEstimates(cmp,event,helper);
        }
    },
    getRecipientOverrideAddress : function(cmp, event, helper) {
        helper.getOverrideAddress(cmp, event, 'AMEAddressBlock1');
        // DDS-5928 : EDD estimate feature - when no EDD is returned from the consignment service, call the shipment edd service to get delivery estimates
        if (cmp.get('v.wizardData.eddStatus') == 'NO_EDD')
        {
            helper.getEDDServiceEstimates(cmp,event,helper);
        }
    },
    getShowError : function(cmp, event, helper) {
        var showerror = event.getParam('inputError');
        cmp.set("v.showError",showerror);
    },
    getRecipientShowError : function(cmp, event, helper) {
        var showerror = event.getParam('inputError');
        cmp.set("v.recipientShowError",showerror);
    },
    checkOverride : function(cmp, event, helper) {
        var overriden = event.getParam('selected');
        cmp.set("v.isOverriden",overriden);
    },
})