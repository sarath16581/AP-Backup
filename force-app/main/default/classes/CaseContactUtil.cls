public with sharing class CaseContactUtil {
	public static void CopyAuthorisedContacts (Map<Id,Case> newCases) {   
        List<Id> contactIds = new List<Id>();
        List<Case> shortListedCases = new List<Case>();
        
        for(Case c : newCases.values()) {
            if(!String.isEmpty(c.Contactid)) {
                shortListedCases.add(c);                
                contactIds.add(c.Contactid); 
            }
        }
        
        if(contactIds.size() > 0) {
            AggregateResult[] groupContacts =   [SELECT AuthorisingContact__c,AuthorisedContact__c 
                                                FROM AuthorisedContacts__c
                                                where AuthorisingContact__c IN:contactIds and RecordType.DeveloperName = 'AllCases'
                                                group by AuthorisingContact__c,AuthorisedContact__c];
            
            if(groupContacts.size() > 0) {
                id caseOnlyTypeId = [Select Id from RecordType where SobjectType = 'AuthorisedContacts__c' AND DeveloperName = 'CaseOnly' Limit 1].id;
                List<AuthorisedContacts__c> newACs = new List<AuthorisedContacts__c>();
                for(Case c: shortListedCases) {
                    for(AggregateResult r: groupContacts){
                        if((id)r.get('AuthorisingContact__c') == c.contactId){
                            newACs.add(new AuthorisedContacts__c(
                                            AuthorisingContact__c = c.contactId, 
                                            AuthorisedContact__c = (id)r.get('AuthorisedContact__c'), 
                                            RecordTypeId = caseOnlyTypeId, 
                                            Case__c = c.id));
                        }
                    }
                }   
                
                if(newACs.size() > 0) {
                    insert newACs;
                }
            }
        }
    }
}