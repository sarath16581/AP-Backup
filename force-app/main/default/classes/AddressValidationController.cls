/**************************************************
Type:       AddressValidation's controller 
Purpose:    Used by AddressValidation VF component to show the autocomplete address from AusPost  
History:
--------------------------------------------------
Dec-2013:  george.nguyen@bluewolf.com  Created                                            
**************************************************/
global with sharing class AddressValidationController {
    
    public string token {get;set;}
    public string addressSearchURL {get;set;}
    public string addressDetailsURL {get;set;}
    
    public AddressValidationController(){
        token = '';
        addressSearchURL = '';
        addressDetailsURL = '';
        
        AusPostSettings__c setting = AusPostSettings__c.getValues('AddressValidation');
        if(setting != null){
            token = setting.Token__c;
            addressSearchURL = setting.URL2__c;
            addressDetailsURL = setting.URL3__c;
        }
    }
    
    
}