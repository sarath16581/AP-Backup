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

    // checkAllValid: function(cmp, showError) { 
    //     // Must use single '&' so that it runs through all functions.
    //     var isValid = (
    //         this.validateRadioButtons(cmp.find("enquiryRadioButtons"), showError) & 
    //         this.validateTextArea(cmp.find("enquiryTextareaDetails"), showError)
    //         );

    //     if(isValid){
    //         cmp.set('v.formValid', true);
    //     }else{
    //         cmp.set('v.formValid', false);
    //     }
    //     return isValid;
    // },
    
    // validateFormAndShowErrors: function(component){
    //     var isValid = true;
    //     var radioButtonsCmp = component.find("enquiryRadioButtons");
        
    //     if(component.get('v.wizardData.selectedRadio') == null){
    //         //-- Showing Enquiry Type error message Div
    //         radioButtonsCmp.set("v.errors", [{message:"Choose an option"}]);
    //         isValid = false;
    //     }else{
    //         //-- Hiding Enquiry Type error message Div
    //         radioButtonsCmp.set("v.errors", null);
    //     }
        
    //     var ComplaintDetailsVal 	= component.get('v.wizardData.complaintDetails');
    //     var textareaEnquiryDetails = component.find("enquiryTextareaDetails");

    //     if(textareaEnquiryDetails) {
    //         if(!ComplaintDetailsVal || ComplaintDetailsVal.trim().length === 0 ){
    //             textareaEnquiryDetails.set("v.errors", [{message:"Enter details"}]);

    //             // if( component.get("v.validateComplaintDetails") == false){
    //             //     component.set("v.validateComplaintDetails", true);
    //             // }else{
    //             //     component.set("v.validateComplaintDetails", false);
    //             // }
    //             isValid = false;
    //         } else {
    //             textareaEnquiryDetails.set("v.errors", null);  
    //         }
    //     }

    //      //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('isValid===='+isValid);
    //     }
    //      //-- checking form is valid or not
    //     if(isValid){
    //         component.set('v.enableOrDisableNextBtnVal', 'Enable');
    //     }else{
    //         component.set('v.enableOrDisableNextBtnVal', 'Disable');
    //     }
        
    //     return isValid;
    // },
    // validateFormAndNotShowErrors: function(component){
    //     var isValid = true;
    //     var radioButtonsCmp = component.find("enquiryRadioButtons");
        
    //     if(component.get('v.wizardData.selectedRadio') == null){
    //         radioButtonsCmp.set("v.errors", null);
    //         //-- Showing Enquiry Type error message Div
    //         // radioButtonsCmp.set("v.errors", [{message:"Choose an option"}]);
    //         isValid = false;
    //     }else{
    //         //-- Hiding Enquiry Type error message Div
    //         radioButtonsCmp.set("v.errors", null);
    //     }
        
    //     var ComplaintDetailsVal 	= component.get('v.wizardData.complaintDetails');
    //     var textareaEnquiryDetails = component.find("enquiryTextareaDetails");

    //     if(textareaEnquiryDetails) {
    //         if(!ComplaintDetailsVal || ComplaintDetailsVal.trim().length === 0 ){
    //             textareaEnquiryDetails.set("v.errors", null);

    //             // if( component.get("v.validateComplaintDetails") == false){
    //             //     component.set("v.validateComplaintDetails", true);
    //             // }else{
    //             //     component.set("v.validateComplaintDetails", false);
    //             // }
    //             isValid = false;
    //         } else {
    //             textareaEnquiryDetails.set("v.errors", null);  
    //         }
    //     }

    //      //-- Console log
    //     if(component.get("v.debugMode")){
    //     console.log('isValid===='+isValid);
    //     }
        
    //     if(isValid){
    //         component.set('v.enableOrDisableNextBtnVal', 'Enable');
    //     }else{
    //         component.set('v.enableOrDisableNextBtnVal', 'Disable');
    //     }
        
    //     return isValid;
    // }
})