/*
 * * 2020-07-28 hara.sahoo@auspost.com.au Reset the showErrorSummary flag, to display the error summary.
 * * 2020-09-17 hara.sahoo@auspost.com.au Push analytics for direct link redirection from chatbots, faq pages.
 */
({    
    doInit :function(cmp, event, helper) {
        //Check the base url of the page, this is to ascertain users getting directed from a direct link
        var baseUrl = window.location.href;
        if(baseUrl.includes("transfertoPO"))
        {
            cmp.set("v.isFromDirectLink", true);
            cmp.set('v.wizardData.selectedRadio1','firstRadio');
            cmp.set('v.wizardData.selectedRadio1Name','Mail products');
            cmp.set('v.wizardData.mailProductsEnquiryType','Transfer to another post office');
            var selectedValue = cmp.get("v.wizardData.selectedRadio1Name") + '-' + cmp.get("v.wizardData.mailProductsEnquiryType");
            cmp.set("v.wizardData.transferToPoSelectedValue",selectedValue);
        }
    },
    goForward: function(cmp, event, helper) {
       var isValid = helper.checkAllInputs(cmp, true);
       //reset the error flags
       cmp.set('v.error', ''); 
       var deliveryAddressIsValid = helper.validateAddressNotNull(cmp, true);
        
        //-- If all validations are completed then move to next screen
        if(isValid){
            if (cmp.get('v.wizardData.selectedRadio1Name') === 'Mail products' &&
                cmp.get('v.wizardData.mailProductsEnquiryType') === 'Transfer to another post office' && deliveryAddressIsValid) 
            {
                cmp.set("v.wizardData.transferToPo", true);
                helper.gotoNextPage(cmp);
            }
            //-- Address validation for Online shop
            if (cmp. get('v.wizardData.selectedRadio1Name') === 'Online Shop' &&cmp.get('v.wizardData.selectedRadio2Name') === 'Yes' && deliveryAddressIsValid) {
                helper.gotoNextPage(cmp);
            }
            else
            {
                helper.gotoNextPage(cmp);
            }
            
        } else {
            helper.showErrorSummary(cmp);
            //-- separate error handling for post office lwc component 
            var selectedPostOffice = cmp.get('v.wizardData.selectedPostOffice');
            if (cmp.get('v.wizardData.selectedRadio1Name') === 'Mail products' &&
                cmp.get('v.wizardData.mailProductsEnquiryType') === 'Transfer to another post office' && ($A.util.isEmpty(selectedPostOffice) || $A.util.isUndefined(selectedPostOffice)) )
            {
                cmp.set("v.showPoError", true);
            }
        }
    },
    searchTrackingNumberService : function (cmp, event, helper) {
        helper.searchTrackingNumber(cmp,event,helper);
    },
    onchange: function (cmp, event, helper) {
        
        var selectedValue= '';
        //reset the showErrorSummary flag
        cmp.set("v.showErrorSummary",'false');
        if (cmp.get('v.wizardData.selectedRadio1Name') === 'Mail products' &&
            cmp.get('v.wizardData.mailProductsEnquiryType') === 'Transfer to another post office') {
            cmp.set('v.helptext', "To transfer an item, please provide the name and address of the Post Office: \n 1. your item is currently at, and \n 2. you'd like your item transferred to.")
        } else {
            cmp.set('v.helptext', null);
        }
        var srcCmp = event.getSource();
        var fieldName = event.getParam("name");
        if (fieldName === 'enquiryDetailsRadioButtons') {
            helper.setRadioName(cmp, 'v.enquiryDetailsRadioGroup', 'v.wizardData.selectedRadio1', 'v.wizardData.selectedRadio1Name');
        } else if (fieldName === 'madeAnOrderRadioButtons') {
            helper.setRadioName(cmp, 'v.madeAnOrderRadioGroup', 'v.wizardData.selectedRadio2', 'v.wizardData.selectedRadio2Name');
        } else if (fieldName === 'moneyEnquiryTypeRadioButtons') {
            helper.setRadioName(cmp, 'v.moneyEnquiryTypeRadioGroup', 'v.wizardData.selectedRadio3', 'v.wizardData.selectedRadio3Name');
        }
        
        helper.checkInputs([srcCmp], true);
        cmp.set('v.checkInputsOnRender', true);
        // ensure the analytics is only triggered from onchange event and disallow changes prepopulated from a direct link like chatbot, faq pages
        // analytics from direct link is handled on page load and not from an onchange event
        var directLink = cmp.get("v.isFromDirectLink");
        if(! directLink && fieldName =='mailProductsEnquiryType')
        {
            //Push analytics for enquiry details - on Mail Products Enquire Selection
            if (cmp.get('v.wizardData.selectedRadio1Name') === 'Mail products' &&
                cmp.get('v.wizardData.mailProductsEnquiryType') === 'Transfer to another post office') 
            {
                var enquiryType = cmp.get('v.wizardData.mailProductsEnquiryType');
                var radioSelected = cmp.get('v.wizardData.selectedRadio1Name');
                selectedValue = radioSelected + '-' + enquiryType;
                cmp.set("v.wizardData.transferToPoSelectedValue",selectedValue);
                helper.pushFormAnalytics(cmp, selectedValue);
            }
        }
    },
    
    selectedpostofficehandler : function(component, event, helper) {
        component.set("v.selectedPostOffice",event.getParam('value'));
        var selectedPostOffice = event.getParam('value');
        //let selectedPostOfficeAddressTitle= selectedPostOffice.location.title;
        var selectedPostOfficeAddress= selectedPostOffice.location.address;
        var previousSelectedPostOffice = component.get('v.previousSelectedPO');
        component.set('v.wizardData.selectedPostOffice',selectedPostOfficeAddress);
        //Check if the previous address selected was changed
        if(!$A.util.isEmpty(previousSelectedPostOffice) &&  previousSelectedPostOffice != selectedPostOfficeAddress)
        {
            //Push analytics for address change
            helper.pushInteractionAnalytics(component, 'transfer to another post office:change');
        }
        else
        {
            //Push analytics for address selected
            helper.pushInteractionAnalytics(component, 'transfer to another post office:select');
        }
        
        component.set('v.previousSelectedPO',selectedPostOfficeAddress);
        //-- reset the error flag
        component.set("v.showPoError", false);
    },
    displaymyPostLoginForm : function (cmp, event, helper) {
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
    getShowError : function(cmp, event, helper) {
        var showerror = event.getParam('inputError');
        cmp.set("v.showError",showerror);
    },
    checkOverride : function(cmp, event, helper) {
        var overriden = event.getParam('selected');
        cmp.set("v.isOverriden",overriden);
    }, 
    
})