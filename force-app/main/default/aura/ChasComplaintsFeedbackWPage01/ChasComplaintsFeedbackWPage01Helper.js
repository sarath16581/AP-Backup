({
    validateRadioButtons: function(cmp, showError) {
        return this.validateNotNull(cmp, showError, "Choose an option");
    },

    validateTextArea: function(cmp, showError) {
        return this.validateNotNull(cmp, showError, "Enter complaint or feedback details")
    },

    validationMap: function() {
        return {
            'enquiryRadioButtons': this.validateRadioButtons,
            'lateOrMissingRadioButtons': this.validateRadioButtons,
            'enquiryTextareaDetails': this.validateTextArea,
        };
    },
    
    /**
     * Clear controls
     * @param cmp
     */
    removeSentTypeFromWizardData: function(cmp){
        //-- setting below to null in wizardData if user selected 'Registered Post' and choose 'Parcel' option
        if(cmp.get('v.wizardData.selectedlateOrMissingRadioName') != ''){
            cmp.set('v.wizardData.selectedlateOrMissingRadio', null);
            cmp.set('v.wizardData.selectedlateOrMissingRadioName', null);
        }
    }
})