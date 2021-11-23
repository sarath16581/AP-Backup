/**
 * Created by nmain on 28/05/2018.
 */
({
    validationMap: function() {
        return {
            'ChasGivenName': this.validateGivenName,
            'ChasSurname': this.validateSurname,
            'ChasEmail': this.validateEmail,
            'ChasPhone': this.validatePhone
        };
    },
    // checkAllValid: function(cmp, showError) {
    //     cmp.set('v.errors', []);
    //     // Must use single '&' so that it runs through all functions.
    //     var isValid = (
    //         this.validateGivenName(cmp.find("ChasGivenName"), showError) & 
    //         this.validateSurname(cmp.find("ChasSurname"), showError) & 
    //         this.validateEmail(cmp.find("ChasEmail"), showError) & 
    //         this.validatePhone(cmp.find("ChasPhone"), showError)
    //         );

    //     if(isValid){
    //         cmp.set('v.formValid', true);
    //     }else{
    //         cmp.set('v.formValid', false);
    //     }
    //     return isValid;
    // }
    
    // validateFormAndShowErrors: function(component){
        
    //     var isValid = true;
        
    //     var givenName 	 = component.find('givenName');
    //     var givenNameVal = givenName.get('v.value');
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('givenNameVal===='+givenNameVal);
    //     }
        
    //     var surname 	= component.find('surname');
    //     var surnameVal 	= surname.get('v.value');
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('surnameVal===='+surnameVal);
    //     }
        
    //     var emailId 	= component.find('emailId');
    //     var emailIdVal 	= emailId.get('v.value');
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('emailIdVal===='+emailIdVal);
    //     }
        
    //     var phone 	  = component.find('phone');
    //     var phoneVal  = phone.get('v.value');
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('phoneVal===='+phoneVal);
    //     }
        
    //     //-- Validating 'Given Name' if empty
    //     var givenNameInputCmp = component.find("givenName");
    //     if(!givenNameVal || givenNameVal.trim().length === 0){
            
    //         givenNameInputCmp.set("v.errors", [{message:"Enter given name"}]);
    //         isValid = false;
    //     }else{
    //         givenNameInputCmp.set("v.errors",null); 
    //     }
        
    //     //-- Validating 'surname' if empty
    //     var surnameInputCmp = component.find("surname");
    //     if(!surnameVal || surnameVal.trim().length === 0){
    //         surnameInputCmp.set("v.errors", [{message:"Enter surname"}]);
    //         isValid = false;
    //     }else{
    //         surnameInputCmp.set("v.errors",null); 
    //     }
        
    //     //-- Validating 'email Id' if empty
    //     var emailInputCmp = component.find("emailId");
    //     if(!emailIdVal || emailIdVal.trim().length === 0){
    //         emailInputCmp.set("v.errors", [{message:"Enter email address"}]);
    //         isValid = false;
    //     }else{
    //         emailInputCmp.set("v.errors",null); 
    //     }
        
    //     // Validating email Id
    //     var isValidEmail = true;
    //     var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;  
    //     if(!$A.util.isEmpty(emailIdVal)){   
    //         if(!emailIdVal.match(regExpEmailformat)){
    //             emailInputCmp.set("v.errors", [{message:"Enter valid email address"}]);
    //             isValid = false;
    //         }else{
    //             emailInputCmp.set("v.errors",null); 
    //         }
    //     }
        
    //     //-- Validating 'phone' if empty
    //     var phoneInputCmp = component.find("phone");
    //     if(!phoneVal || phoneVal.trim().length === 0){
    //         phoneInputCmp.set("v.errors", [{message:"Enter phone number"}]);
    //         isValid = false;
    //     }else{
    //         phoneInputCmp.set("v.errors",null); 
    //     }
    //     if(isValid){
    //         component.set('v.enableOrDisableNextBtnVal', 'Enable');
    //     }else{
    //         component.set('v.enableOrDisableNextBtnVal', 'Disable');
    //     }
    //     return isValid
    // },
    // validateFormAndNotShowErrors: function(component){
    //     var currentId = component.get('v.currentAuraId');
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('currentId=='+component.get('v.currentAuraId'));
    //     }
    //     var isValid = true;
        
    //     var givenName 	 = component.find('givenName');
    //     var givenNameVal = givenName.get('v.value');
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('givenNameVal===='+givenNameVal);
    //     }
        
    //     var surname 	= component.find('surname');
    //     var surnameVal 	= surname.get('v.value');
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('surnameVal===='+surnameVal);
    //     }
        
    //     var emailId 	= component.find('emailId');
    //     var emailIdVal 	= emailId.get('v.value');
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('emailIdVal===='+emailIdVal);
    //     }
        
    //     var phone 	  = component.find('phone');
    //     var phoneVal  = phone.get('v.value');
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log('phoneVal===='+phoneVal);
    //     }
        
    //     //-- Validating 'Given Name' if empty
    //     var givenNameInputCmp = component.find("givenName");
    //     if(!givenNameVal || givenNameVal.trim().length === 0){
    //         if(currentId == "givenName"){
    //             givenNameInputCmp.set("v.errors",null); 
                
    //         }
    //         isValid = false;
    //     }else{
    //         if(currentId == "givenName"){
    //             givenNameInputCmp.set("v.errors",null); 
    //         }
    //     }
        
    //     //-- Validating 'surname' if empty
    //     var surnameInputCmp = component.find("surname");
    //     if(!surnameVal || surnameVal.trim().length === 0){
    //         if(currentId == "surname"){
    //             surnameInputCmp.set("v.errors",null); 
    //         }
    //         isValid = false;
    //     }else{
    //         if(currentId == "surname"){
    //             surnameInputCmp.set("v.errors",null); 
    //         }
    //     }
        
    //     //-- Validating 'email Id' if empty
    //     var emailInputCmp = component.find("emailId");
    //     if(!emailIdVal || emailIdVal.trim().length === 0){
    //         if(currentId == "emailId"){
    //             emailInputCmp.set("v.errors",null); 
    //         }
    //         isValid = false;
    //     }else{
    //         if(currentId == "emailId"){
    //             emailInputCmp.set("v.errors",null); 
    //         }
    //     }
        
    //     // Validating email Id
    //     var isValidEmail = true;
    //     var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;  
    //     if(!$A.util.isEmpty(emailIdVal)){   
    //         if(!emailIdVal.match(regExpEmailformat)){
    //             if(currentId == "emailId"){
    //                 emailInputCmp.set("v.errors",null); 
                    
    //             }
    //             isValid = false;
    //         }else{
    //             if(currentId == "emailId"){
    //                 emailInputCmp.set("v.errors",null); 
    //             }
    //         }
    //     }
        
    //     //-- Validating 'phone' if empty
    //     var phoneInputCmp = component.find("phone");
    //     if(!phoneVal || phoneVal.trim().length === 0){
    //         if(currentId == "phone"){
    //             phoneInputCmp.set("v.errors",null);
    //         }
    //         isValid = false;
    //     }else{
    //         if(currentId == "phone"){
    //             phoneInputCmp.set("v.errors",null); 
    //         }
    //     }
    //     //-- Console log
    //     if(component.get("v.debugMode")){
    //         console.log(isValid);
    //     }
    //     if(isValid){
    //         component.set('v.enableOrDisableNextBtnVal', 'Enable');
    //     }else{
    //         component.set('v.enableOrDisableNextBtnVal', 'Disable');
    //     }
    //     return isValid;
    // }
})