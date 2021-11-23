/**

Created By - Mausam Padhiyar
Created Date - 24th Nov, 2015
Last Modified By -
Last Modified Date -
**/
public with sharing class APT_PricingApprovalHelpController {
    /**
        This method will used for page redirect.
    **/
    public PageReference doRedirect() {
        try {
            PageReference pr = new PageReference(APT_Constants.RESOURCE_URL1);
            return pr;
        }    
        catch(Exception ex) {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));  
                return null;          
        }
    }
}