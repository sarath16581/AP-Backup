public with sharing class SSSWRedirectController {

    public SSSWRedirectController(ApexPages.StandardController stdController){
    
    }
    
    public PageReference redirectMe(){
        string profileName = [Select Name from Profile where Id =: userinfo.getProfileid() limit 1].name;
        SSSWRedirect__c settings = SSSWRedirect__c.getValues(profileName);
        PageReference result = null;

        if(settings != null){
            result = new PageReference(settings.URL__c);
        } else {
            settings = SSSWRedirect__c.getValues('No Matching Profile');
            if(settings != null){
                result = new PageReference(settings.URL__c);
            }
        }
        
        return result;
    }
}