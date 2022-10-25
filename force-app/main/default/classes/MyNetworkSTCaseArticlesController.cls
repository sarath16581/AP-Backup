/**
* @author       : manish.jhingran@auspost.com.au
* @date         : 10/09/2022
* @description  : Controller Class for ST user console.It has below features.
                  a. list of Articles
                  b. Selection of networks for AP user
                                  
*/
Public with sharing class MyNetworkSTCaseArticlesController {
@AuraEnabled(cacheable=true)
    public static List<Network__c> getNetworks() {
        return [SELECT Id, Name FROM Network__c order by createddate desc NULLS LAST  LIMIT 10000];
    }

    @AuraEnabled
    public static List<Article__c> getArticles(String caseId) {
        //return [SELECT Id, Name, Network__r.ID, Network__r.Name FROM Article__c];
       return [SELECT Id, Name, Network__c, Network__r.ID,Network__r.Name,(select Id,Name,Facility__c, EventDescription__c,Facility__r.Name, ActualDateTime__c,Case__c from Event_Messages__r where Facility__r.RecordType.Name NOT IN ('Agent','Care Agent','Metro','Regional') order by ActualDateTime__c asc) FROM Article__c where Case__c =:caseId order by createddate desc NULLS LAST  LIMIT 10000 ];
       //return [SELECT Id, Name, Network__c, Network__r.ID,Network__r.Name,(select Id,Name,Facility__c,Facility__r.Name from Event_Messages__r) FROM Article__c];
        
        
    }
    @AuraEnabled
    public static Boolean getNetworksFromEventMessage(String caseId){
        try {
            List<EventMessage__c> eventMessage = [SELECT Id, Facility__c from EventMessage__c where Facility__c != null AND Article__r.Case__c = :caseId];
            if(eventMessage != null && !eventMessage.isEmpty()){
                return true;
            }
            return false;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
@AuraEnabled
    public static String saveRecords(String recsString) {
        List<Article__c> recs2Save = (List<Article__c>) JSON.deserialize(recsString, List<Article__c>.class);
        update recs2Save;
        return 'success';
    }
   
}