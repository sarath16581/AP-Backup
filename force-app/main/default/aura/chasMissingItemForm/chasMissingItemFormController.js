/*
 * @changelog : 
 * 2020-09-10 : Modified : Set network eligibility based on the user input for reason for enquiry
 * 2020-11-26 hara.sahoo@auspost.com.au Added click tracking for adobe analytics
 */
({
    init :function (cmp, event, helper) {
        //helper.checkAllInputs(cmp, false);
        
        //push analytics on form load based on the payload
        var safeDropPayLoad = cmp.get("v.wizardData.safeDropPayload");
        if(!$A.util.isEmpty(safeDropPayLoad) || !$A.util.isUndefined(safeDropPayLoad))
        {
            helper.pushAnalytics(cmp,'item details:confirm:prefill safe drop');
        }
        else
        {
            helper.pushAnalytics(cmp,'item details:confirm:prefill');
        }
        
        
    },
    onchange: function (cmp, event, helper) {
        var srcCmp = event.getSource();
        var fieldName = event.getParam("name");
        if (fieldName === 'recipientOrSenderRadioButtons') {
            helper.setRadioName(cmp, 'v.recipientOrSenderRadioGroup', 'v.wizardData.selectedRadio1', 'v.wizardData.selectedRadio1Name');
        } 
        else if (fieldName === 'parcelOrLetterRadioButtons') {
            helper.setRadioName(cmp, 'v.parcelOrLetterRadioGroup', 'v.wizardData.selectedRadio2', 'v.wizardData.selectedRadio2Name');
            helper.removeSentTypeFromWizardData(cmp);
        } else if (fieldName === 'domesticParcelSentTypeRadioButtons') {
            helper.setRadioName(cmp, 'v.domesticParcelSentTypeRadioGroup', 'v.wizardData.selectedRadio3', 'v.wizardData.selectedRadio3Name');
        } else if (fieldName === 'domesticLetterSentTypeRadioButtons') {
            helper.setRadioName(cmp, 'v.domesticLetterSentTypeRadioGroup', 'v.wizardData.selectedRadio3', 'v.wizardData.selectedRadio3Name');
        } else if (fieldName === 'internationalParcelSentTypeRadioButtons') {
            helper.setRadioName(cmp, 'v.internationalSentTypeRadioGroup', 'v.wizardData.selectedRadio3', 'v.wizardData.selectedRadio3Name');
        } else if (fieldName === 'pharmaRadioButtons') { 
            helper.setRadioName(cmp, 'v.pharmaRadioGroup', 'v.wizardData.selectedRadio4', 'v.wizardData.selectedRadio4Name');
        } else if (fieldName === 'reasonForEnquiry'){
                helper.setRadioName(cmp, 'v.reasonForEnquiry', 'v.wizardData.selectedRadio5', 'v.wizardData.selectedRadio5Name');
                var reasonForEnquiry = cmp.get('v.wizardData.selectedRadio5Name');
                cmp.set('v.wizardData.reasonForEnquiry', reasonForEnquiry);
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
    
    openModal: function(component, event, helper) {
        //Click tracking - push analytics for site-interact
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            'site-interact',
            'form:' + component.get('v.pageTitle'),
            'item details: ' + 'confirm:prefill safe drop:enlarge photo'
        );
        // Set isModalOpen attribute to true
        component.set("v.isModalOpen", true);
    },
    
    closeModal: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
    },
    goForward: function(cmp, event, helper) { 
        // Set network eligibility based on the user input for reason for enquiry
        var reasonForEnquiry = cmp.get("v.wizardData.reasonForEnquiry");
        if(reasonForEnquiry == 'Other' || reasonForEnquiry == 'Parcel is no longer in the location shown')
        {
            cmp.set("v.wizardData.isEligibleForMyNetworkAssignment",false);
        } 
        var ifSender = cmp.get("v.wizardData.selectedRadio1Name");
        var isValid = helper.checkAllInputs(cmp, true);
        //-- Check if address selected from the AME service is valid
        var deliveryAddressIsValid = helper.validateAddressNotNull(cmp, true);
        //-- If all validations are completed then move to next screen. Extra validation for delivery address if it is a sender
        if(ifSender == 'Sender'){
            if(isValid && deliveryAddressIsValid){
                helper.gotoNextPage(cmp);
            } else {
                helper.showErrorSummary(cmp)
            }
        } else 
        {
            if(isValid){
                helper.gotoNextPage(cmp);
            } else {
                helper.showErrorSummary(cmp)
            } 
        }
    },
    goBack: function (cmp, event, helper) {
        var safeDropPayload = cmp.get("v.wizardData.safeDropPayload");
        //check if the delivery address is captured via the AME service, go back to the chasMissingItemForm
        if (!$A.util.isEmpty(safeDropPayload) || !$A.util.isUndefined(safeDropPayload))
        {
            //Check the base url of the page, this is to ascertain users getting directed from a direct link
            var baseUrl = window.location.href;
            if(baseUrl.includes("trackingId"))
            {
                window.location.href = window.location.href + '#';
            }
            //cmp.set("v.wizardData.correctDeliveryAddress",null);
            helper.gotoPrevPage(cmp,'chasMissingItemAddressValidation');
        }
        //for all other cases, go back to the form as per the "prev" attribute in corresponding wizard
        else
        {
            helper.gotoPrevPage(cmp);
        }
        
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
    getShowError : function(cmp, event, helper) {
        var showerror = event.getParam('inputError');
        cmp.set("v.showError",showerror);
    },
    checkOverride : function(cmp, event, helper) {
        var overriden = event.getParam('selected');
        cmp.set("v.isOverriden",overriden);
    },
    
})