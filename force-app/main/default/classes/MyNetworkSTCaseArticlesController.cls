/**
* @author       : manish.jhingran@auspost.com.au
* @date         : 10/09/2022
* @description  : Controller Class for ST user console.It has below features.
                  a. list of Articles travelled through AP Network only
                  b. Get the networks from EventMessages for AP user for the related case.
                  c. Saving Case investigation records
                  d.Checking Duplicate case investigation records
                  **Jira Story : 689,691 and 723
                                  
*/
public with sharing class MyNetworkSTCaseArticlesController {

    @AuraEnabled
    public static List<Article__c> getArticles(String caseId) {
       
       return [SELECT Id, Name, Network__c, Network__r.ID,Network__r.Name,(select Id,Name,Facility__c, EventDescription__c,Facility__r.Name,Facility__r.Comment__c,Facility__r.Contact_Facility__c,Facility__r.Phone_Number__c,Facility__r.Network_Address__c, ActualDateTime__c,Case__c, FacilityOrganisationID__c from Event_Messages__r where Facility__r.RecordType.Name NOT IN ('Agent','Care Agent','Metro','Regional')  order by ActualDateTime__c asc) FROM Article__c where Case__c =:caseId AND Network__c != null order by createddate asc NULLS LAST  LIMIT 10000 ];
       
    }
    @AuraEnabled
    public static Boolean getNetworksFromEventMessage(String caseId){
        try {
            List<EventMessage__c> eventMessage = [SELECT Id, Facility__c,Facility__r.Contact_Facility__c,Facility__r.Comment__c from EventMessage__c where (Facility__c != null) AND (Article__r.Case__c = :caseId)];
            if(eventMessage != null && !eventMessage.isEmpty()){
                return true;
            }
            return false;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    
    //Save Case Investigation Records, Check for Duplicate records
    @AuraEnabled
    public static String createCaseInv(String recsString, String recordId) {
        try {
            List< CaseInvestigation__c > recstoSave = (List< CaseInvestigation__c >) JSON.deserialize(recsString, List<CaseInvestigation__c>.class);
            List< CaseInvestigation__c > existingCaseInv = [Select Id, Article__c, Network__c, Case__c from CaseInvestigation__c where Case__c = :recordId AND Status__c != 'Closed' AND Network__r.RecordType.Name NOT IN ('Agent','Care Agent','Metro','Regional')];
            Set<String> existingArticleNetworkSet = new Set<String>();
            for(CaseInvestigation__c caseInv: existingCaseInv){
                existingArticleNetworkSet.add(''+caseInv.Article__c + caseInv.Network__c);
            }
            for(CaseInvestigation__c caseInv : recstoSave){
                if(existingArticleNetworkSet.contains(''+caseInv.Article__c+caseInv.Network__c)){
                    return 'error';
                }
            }
            insert recstoSave;
            return 'success';
        } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
        }
    }

    //Wrapper to get the knowledge articles
    @AuraEnabled(cacheable=true)
    public static List<CriticalIncidentWrapper> fetchCriticalIncidents() {
        List<CriticalIncidentWrapper> wrapperList = new List<CriticalIncidentWrapper>();
        Map<String, List<CriticalIncident>> criticalIncidentMap = new Map<String, List<CriticalIncident>>();
        // query critical incidents knowledge articles
        for (Critical_Incident__kav ci : CriticalIncidentsSelector.newInstance().selectCriticalIncidentsByPublishStatus('Online').values()) {
            if (!String.isBlank(ci.Network_Org_Id__c)) {
                
                for (String networkOrgId : ci.Network_Org_Id__c.split(';')) {
                    if(!String.isEmpty(networkOrgId)) {
                        if(criticalIncidentMap.get(networkOrgId) == null) {
                            criticalIncidentMap.put(networkOrgId, new List<CriticalIncident>());
                        }
                        CriticalIncident incident = new CriticalIncident();
                        incident.id = ci.Id;
                        incident.urlName = ci.UrlName;
                        incident.knowledgeArticleId = '/'+ ci.KnowledgeArticleId;
                        criticalIncidentMap.get(networkOrgId).add(incident);
                    }
                }
            }
        }

        for (String networkId : criticalIncidentMap.keySet()) {
            CriticalIncidentWrapper wrapper = new CriticalIncidentWrapper();
            wrapper.networkOrgId = networkId;
            wrapper.criticalIncidentList = criticalIncidentMap.get(networkId);
            wrapperList.add(wrapper);
        }
        return wrapperList;
    }

    public class CriticalIncidentWrapper {
        @AuraEnabled
        public String networkOrgId {get;set;}
        @AuraEnabled
        public List<CriticalIncident> criticalIncidentList {get;set;}
    }

    public class CriticalIncident {
        @AuraEnabled
        public Id id {get;set;}
        @AuraEnabled
        public String urlName {get;set;}
        @AuraEnabled
        public String knowledgeArticleId {get;set;}
    }
   

   
}