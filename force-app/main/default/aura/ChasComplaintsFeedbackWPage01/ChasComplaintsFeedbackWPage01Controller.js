/*
  * @changeLog : 19/06/2020: hara.sahoo@auspost.com.au Added showErrorSummary helper class.
*/

({
    goForward: function (cmp, event, helper) {
        //-- Validating all Page fileds and showing in case of any failures
        var isValid = helper.checkAllInputs(cmp, true);
        
        //-- Validation is successful then moving to next page
        if(isValid){
            helper.gotoNextPage(cmp);   
        }else {
            helper.showErrorSummary(cmp)
        }
    },

    onchange: function(cmp, event, helper) {
        //reset the showErrorSummary flag
        cmp.set("v.showErrorSummary",'false');
        var srcCmp = event.getSource();
        var fieldName = event.getParam("name");
        if (fieldName === 'enquiryRadioButtons') {
            helper.removeSentTypeFromWizardData(cmp);
            helper.setRadioName(cmp, 'v.radioOptions', 'v.wizardData.selectedRadio', 'v.wizardData.selectedRadioName');
        } else if (fieldName === 'lateOrMissingRadioButtons') {
            helper.setRadioName(cmp, 'v.lateOrMissingRadioOptions', 'v.wizardData.selectedlateOrMissingRadio', 'v.wizardData.selectedlateOrMissingRadioName');
        }
        helper.checkInputs([srcCmp], true);
        cmp.set('v.checkInputsOnRender', true);

    },

    /**
     * Record analytics on click of the navigate to missing item form link
     *
     * @param cmp
     * @param event
     * @param helper
     */
    onClickMissingItemLink: function(cmp, event, helper) {
        if(cmp.get('v.wizardData.selectedlateOrMissingRadioName') == 'Yes') {
            // passing params to analytics api
            window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
                'site-interact',
                'form:' + cmp.get('v.pageTitle'),
                'item details:continue to missing item'
            );
        }
    },
    displaymyPostLoginForm : function (cmp, event, helper) {
        helper.storeEncryPtWizardDataAndNavigateToMyPost(cmp);
    },
    
    // handleComponentEvent: function(component, event, helper) {
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('###############hanle Event of C&F Wizard Cmp1 --- start ############');
    //     }
    //     var name = event.getParam("name");
    //     var val =  event.getParam("value");
        
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('Fired Event Name and its Val='+name+'='+val);
    //     }
        
    //     component.set("v.wizardData.test", val);
    //     component.set("v.wizardData."+name, val);
        
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('v.wizardData.'+name+'='+component.get('v.wizardData.'+name+''));
    //     }
        
    //     //-- validating all form elements to enable or Disable of Next button
    //     helper.validateFormAndShowErrors(component); 
        
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('###############hanle Event of C&F Wizard Cmp1 --- end ############');
    //     }
    // },
    // itemsChange: function(component, event, helper) {
        
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log(' In itemsChange of ChasComplaintsFeedbackWPage01');
    //     }
        
    //     //-- removing all radio buttons background color
    //     var containerDiv = component.find("chasRadiosContainer");
    //     $A.util.removeClass(containerDiv, "firstRadio");
    //     $A.util.removeClass(containerDiv, "secondRadio");
    //     $A.util.removeClass(containerDiv, "thirdRadio");
        
    //     //-- adding selected radio button background color
    //     $A.util.addClass(containerDiv, component.get('v.wizardData.selectedRadio'));
        
    // },
})