/**************************************************
Type:       AddressComponent's controller 
Purpose:    Used by AddressComponent VF component to show different address fields and perform a validation behind the screens  
History:
--------------------------------------------------
Dec-2013:  shruthi.kunchinadka@bluewolf.com  Created                                            
**************************************************/
Public Class AddressComponentController {
    public String token 
    {
        get 
        {
            if(token == null||token == 'token') 
            {
                token= AddressValidationService.getToken();
            }
            return token;
        }
        set {
            token = value;
        }
    }
    
    public String addressURL
    {
    	get 
        {
            if(addressURL == null||addressURL == '') 
            {
                addressURL= AddressValidationService.getAddressURL();
            }
            return token;
        }
        set {
            addressURL = value;
        }
    }
    
    public String detailsURL
    {
    	get 
        {
            if(detailsURL == null||detailsURL == '') 
            {
                detailsURL= AddressValidationService.getDetailsURL();
            }
            return detailsURL;
        }
        set {
            detailsURL = value;
        }
    }
    
    public String suffixClass {get; set;}
    public Boolean hiddenAddressComp {get; set;}
    public sObject sObj {get; set;}
    public Schema.FieldSetMember[] fm
    {
        get;
        set;
    }
    public fieldSetMemberWrapper[] fs 
    {
        get;
        set;
    }
    
    public void refreshToken() {
        token= AddressValidationService.getToken();
    }

    public AddressComponentController() {
        token = 'token';
        system.debug('inside component**'+token);
        
    } 
    
}