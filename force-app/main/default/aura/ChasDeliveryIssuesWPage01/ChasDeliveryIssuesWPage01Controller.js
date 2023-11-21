/**
 *
 * History :
 * --------------------------------------------------
 * 2019-08-30 hasantha.liyanage@auspost.com.au Modified : added Analytics capability and lateOrMissingRadioGroup
 * 2020-07-17 hara.sahoo@auspost.com.au Modified : added Analytics capability for trackingtype = "helpsupport-form-navigate" and trackingtype = "site-interact", for all of the issueType options selected 
 * 2020-07-17 hara.sahoo@auspost.com.au Modified : Commented out the Analytics capability and lateOrMissingRadioGroup, as it is covered already. No need to do it indiviually
 * 2020-10-29 madhuri.awasthi@auspost.com.au - INC1644977 - Consumer Help and Support "Delivery Issues" form content changes. 
												Note chasDevliveryIssuesWPage01.cmp and ChasApexController.apxc changes are also required as the Label values are used.
 * 2020-10-26 hara.sahoo@auspost.com.au Modified : Prepopulate track id and options passed in the url for auto-progression of the forms
 * 2022-05-30 : Thang Nguyen : [DDS-10785] update selectedIssueHandler to redirect to productServicePage
 * 2023-11-20 - Nathan Franklin - Adding a tactical reCAPTCHA implementation to assist with reducing botnet attack vectors (INC2251557)
*/
({
    
	handleCaptchaVerify: function(cmp, event, helper) {
		const token = event.getParam('token');
		cmp.set('v.articleTrackingCaptchaToken', token);
		cmp.set('v.articleTrackingCaptchaEmptyError', false);

		var a = cmp.get('c.searchTrackingNumberService');
        $A.enqueueAction(a);
	},

	maybeResetCaptchaToken: function(cmp) {
		const existingToken = cmp.get('v.articleTrackingCaptchaToken');
		if(existingToken) {
			// // means the user will need to reverify 
			cmp.set('v.articleTrackingCaptchaToken', '');
			cmp.find("chasCaptcha").reset();
		}
	},

    goForward: function(cmp, event, helper) {
        var isValid = helper.checkAllInputs(cmp, true);
        //reset the error flags
        cmp.set('v.error', '');
        var deliveryAddressIsValid = helper.validateAddressNotNull(cmp, true);
        //Check if address selected from the AME service is valid
        //-- If all validations are completed then move to next screen
        if(isValid && deliveryAddressIsValid){
            /*if(cmp.get('v.wizardData.selectedRadio3Name') == 'Yes') {
                // passing params to analytics api
                window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
                    'site-interact',
                    'form:' + cmp.get('v.pageTitle'),
                    'item details:continue to missing item'
                );

                helper.gotoPage(cmp);

            } else {
                helper.gotoNextPage(cmp);
            }*/
            
            helper.gotoNextPage(cmp);
            
        } else {
            helper.showErrorSummary(cmp)
        }
    },
    onchange: function (cmp, event, helper) {
        var srcCmp = event.getSource();
        var fieldName = event.getParam("name");
        if (fieldName === 'issueTypeRadioButtons') {
            helper.setRadioName(cmp, 'v.issueTypeRadioGroup', 'v.wizardData.selectedRadio1', 'v.wizardData.selectedRadio1Name');
            helper.removeSentTypeFromWizardData(cmp);
        } else if (fieldName === 'parcelOrLetterRadioButtons') {
            helper.setRadioName(cmp, 'v.parcelOrLetterRadioGroup', 'v.wizardData.selectedRadio2', 'v.wizardData.selectedRadio2Name');
        } else if (fieldName === 'parcelOrRegPostRadioButtons') {
            helper.setRadioName(cmp, 'v.parcelOrRegPostRadioGroup', 'v.wizardData.selectedRadio2', 'v.wizardData.selectedRadio2Name');
        } else if (fieldName === 'recipientOrSenderRadioButtons') {
            helper.setRadioName(cmp, 'v.recipientOrSenderRadioGroup', 'v.wizardData.selectedRadio3', 'v.wizardData.selectedRadio3Name');
        }
        helper.checkInputs([srcCmp], true);
        cmp.set('v.checkInputsOnRender', true);
        
    },
    selectedIssueHandler : function(cmp, event, helper) {
        window.scrollTo(0, 0);
        var issueVal = event.getParam("selectedIssue");
        // calling the analytics API methods for trackingtype = "site-interact", for all of the issueType options selected 
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            'site-interact',
            'form:' + cmp.get('v.pageTitle'),
            'issue details: ' + issueVal
        );
        if(issueVal == 'Late or missing item') {
            helper.gotoPage(cmp, 'missingItemPage');
        }else if (issueVal == 'Accessibility and disability issue'){
            helper.gotoPage(cmp, 'productServicePage');
        }else{
            cmp.set('v.showIssuesList',false);
        }
        cmp.set('v.IssueName',issueVal);
        cmp.set('v.wizardData.IssueName', issueVal);
        cmp.set('v.wizardData.showIssuesList', cmp.get('v.showIssuesList'));
        cmp.set('v.wizardData.selectedRadio1Name', issueVal);
        cmp.set('v.parcelOrLetterRadioButtonsFlag',false);
        cmp.set('v.inCorrectDeliveryAddressFlag',false);
        cmp.set('v.deliveryAddress','Delivery address');
        cmp.set('v.issueDateFlag',false);
        if(issueVal =='Postie didn\'t knock'  || issueVal =='Item was left in an unsafe place'){
            cmp.set('v.parcelOrLetterRadioButtonsFlag',true);
            cmp.set('v.issueDateFlag',true);
        }else if(issueVal =='Item was damaged' ){
            cmp.set('v.parcelOrLetterRadioButtonsFlag',true);
        }
        if(issueVal =='Incorrect delivery address needs fixing'){
            cmp.set('v.deliveryAddress','Correct delivery address');
            cmp.set('v.inCorrectDeliveryAddressFlag',true);
        }
        // building the analytics params object for trackingtype = "helpsupport-form-navigate"
        var analyticsObject = {
            form: {
                name: 'form:' + cmp.get('v.pageTitle'),
                step: 'issue details:' + issueVal,
                stage: '',
            }
        };
        // calling the analytics API methods for trackingtype = "helpsupport-form-navigate"
        window.AP_ANALYTICS_HELPER.trackByObject({
            trackingType: 'helpsupport-form-navigate',
            componentAttributes: analyticsObject
        });
    },
    goBackHandler : function(cmp, event, helper) { 
        //reset the showErrorSummary flag
        cmp.set("v.showErrorSummary",'false');
        cmp.set('v.showIssuesList',true);
    },
    doInit : function(cmp, event, helper) {
        //--Call the helper method to parse the url.
        var urlVars = helper.parseUrlParam();
        //--Get the Tracking Id parameter.
        var trackingId = urlVars.trackingId;
        //--Get the selected option
        var option = urlVars.form;
        if(!$A.util.isEmpty(trackingId) || !$A.util.isUndefined(trackingId))
        {
            //Pre-populate track id from the url
            cmp.set('v.wizardData.trackingId',trackingId);
        }
        if(!$A.util.isEmpty(option) || !$A.util.isUndefined(option))
        {
            //Setting selected options from the url for auto-progression of the forms
            if(option == 'postiecarded')
            {
                cmp.set('v.wizardData.IssueName','Postie didn\'t knock');
            } 
            if(option == 'unsafeplace')
            {
                cmp.set('v.wizardData.IssueName','Item was left in an unsafe place');
            } 
            if(option == 'inconvenientPO')
            {
                cmp.set('v.wizardData.IssueName','Item was taken to an inconvenient post office');
            } 
            if(option == 'itemdamaged')
            {
                cmp.set('v.wizardData.IssueName','Item was damaged');
            } 
            if(option == 'incorrectaddress')
            {
                cmp.set('v.wizardData.IssueName','Incorrect delivery address needs fixing');
            } 
            if(option == 'something')
            {
                cmp.set('v.wizardData.IssueName','Something else');
            } 
            // Invoke the service for the below issue types for auto progression of the forms
            var issueName = cmp.get('v.wizardData.IssueName');
            if(!$A.util.isEmpty(issueName) && (issueName == 'Postie didn\'t knock' || issueName == 'Item was left in an unsafe place'))
            {
                helper.searchTrackingNumber(cmp,event,helper);
            }
            
        }
        if(cmp.get('v.wizardData.IssueName')){
            cmp.set('v.showIssuesList',false);
            cmp.set('v.IssueName',cmp.get('v.wizardData.IssueName'));
        }
        if(cmp.get('v.wizardData.IssueName') == 'Incorrect delivery address needs fixing')
        {
            cmp.set('v.inCorrectDeliveryAddressFlag',true);
        }
        if(cmp.get('v.wizardData.IssueName') == 'Postie didn\'t knock' || cmp.get('v.wizardData.IssueName') == 'Item was left in an unsafe place' || cmp.get('v.wizardData.IssueName') == 'Item was damaged')
        {
            cmp.set('v.parcelOrLetterRadioButtonsFlag',true);
            
        }
    },
    searchTrackingNumberService : function (cmp, event, helper) {
        var issueName = cmp.get('v.wizardData.IssueName');
        // invoke the service for the below issue types only
        if(!$A.util.isEmpty(issueName) && (issueName == "Postie didn\'t knock" || issueName == "Item was left in an unsafe place"))
        {
            helper.searchTrackingNumber(cmp,event,helper);
            
        }
        
    },
    displaymyPostLoginForm : function (cmp, event, helper) {
        helper.storeEncryPtWizardDataAndNavigateToMyPost(cmp);
    },
    navigateToLoginMyPost: function(cmp, event, helper) {
        helper.storeEncryPtWizardDataAndNavigateToMyPost(cmp);
    },
    getAddressTyped:function(cmp, event, helper) {
        helper.getAddressTyped(cmp, event, 'AMEAddressBlock');
    },    
    getSelectedAddress : function(cmp, event, helper) {
        helper.getSelectedAddress(cmp, event, 'AMEAddressBlock');
    },
    getOverrideAddress : function(cmp, event, helper) {
        helper.getOverrideAddress(cmp, event, 'AMEAddressBlock');
    },
    getIncorrectAddressTyped:function(cmp, event, helper) {
        helper.getAddressTyped(cmp, event, 'AMEAddressBlock1');
    },
    getIncorrectSelectedAddress : function(cmp, event, helper) {
        helper.getSelectedAddress(cmp, event, 'AMEAddressBlock1');
    },
    getIncorrectOverrideAddress : function(cmp, event, helper) {
        helper.getOverrideAddress(cmp, event, 'AMEAddressBlock1');
    },
    getIncorrectShowError : function(cmp, event, helper) {
        var showerror = event.getParam('inputError');
        cmp.set("v.incorrectShowError",showerror);
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