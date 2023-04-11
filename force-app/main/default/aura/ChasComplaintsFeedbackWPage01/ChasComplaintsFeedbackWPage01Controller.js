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
})