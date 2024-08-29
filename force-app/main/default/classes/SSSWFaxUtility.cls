/**
* @author A Tran
* @date 2013-12-16
* @group Utility Class
* @tag FaxTrigger, CaseTrackingUtility class
* @tag Fax__c Object
* @domain Case Details
* @description Utility class for Fax objects.
* @purpose 	When a Fax is linked to a Case, this class will handle the creating and updating
			of StatusTracking__c objects related to the Case. The EndDate of the previous 
			StatusTracking is set to the CreatedDate of the Fax. This is to account for the
			delay between the Fax is received and when the Case is linked.
* 2013-12-16 - A Tran - Created
* 2020-06-10 - Dheeraj Mandavilli - Included @Future on Add Attachments method
* 2024-08-28 - Mona Raghav - REQ3388493 - Method TrimContent added to trim the escalation email content to the field length before updating
*/
public with sharing class SSSWFaxUtility 
{   
    public static void generateAttachment(List<Fax__c> newFaxes){
        RecordType rt = [select id from RecordType where DeveloperName = 'outbound' and sobjecttype='Fax__c'];
        Map<id, Fax__c> shortListed = new Map<id, Fax__c>();
        for(Fax__c f: newFaxes){
            if(f.recordTypeId == rt.id){
                shortListed.put(f.id, f);
            }
        }
        if(!shortListed.isEmpty()){
            Map<id, Map<id, Attachment>> mapping = new Map<Id, Map<id, Attachment>>();
            for(Attachment a: [select parentId, Name, body from Attachment where Name = 'Fax.pdf' and parentId in :shortListed.keySet()]) {
                if(mapping.get(a.parentId) == null){
                    mapping.put(a.parentId, new Map<id, Attachment>());
                }
                mapping.get(a.parentId).put(a.id, a);
            }
            Map<id, Fax__c> faxesRequiringAttachments = new Map<id, Fax__c>();
            for(Fax__c f: shortListed.values()){
                if(mapping.get(f.id) == null || mapping.get(f.id).isEmpty()){
                    faxesRequiringAttachments.put(f.id, f);
                }
            }  
            
            addAttachments(faxesRequiringAttachments.keySet());
        }    
    }
    
    
    @Future(callout=true)
    static void addAttachments(Set<id> faxIds){
        
        Map<id, string> casesVsContent = new Map<id, string>();
        List<Attachment> newAttachments = new List<Attachment>();
        try{
            for(Fax__c f: [select id,Case__c from Fax__c where id in :faxIds]){
                PageReference pdf = new PageReference('/apex/SSSW_Case_FaxTemplateHTML');
                pdf.getParameters().put('id',f.Case__c);
                pdf.getParameters().put('session',Userinfo.getSessionId());
                Attachment a = new Attachment(Name='Fax.pdf');
                a.Body = pdf.getContentAsPDF();
                a.ParentId=f.id;
                a.ContentType = 'application/pdf';
                newAttachments.add(a);
                casesVsContent.put(f.Case__c, pdf.getContent().toString());
            }
        }
        catch(Exception e){
        }
        
        insert newAttachments;
        
        
        if(!casesVsContent.isEmpty()){
            List<Case> casesToUpdate = new List<Case>();
            for(Case c: [select EscalationEmail__c from Case where id in: casesVsContent.keySet()]){
                c.EscalationEmail__c = trimContent(casesVsContent.get(c.id), Schema.SObjectType.Case.fields.EscalationEmail__c.getLength());
                casesToUpdate.add(c);
            }
            update casesToUpdate;
        }
        
    }

	public static string trimContent(String content, integer length) {
		if(content.length() > length) {
			content = content.substring(0,length);
		}
		return content;
	}
    
    // Flag for CaseTrackingUtility to determine which class will create the new StatusTracking
    public static Boolean isFax = false;
    
    static Map<id, StatusTracking__c> cachedCaseRelatedStatusTrackings {get{if(cachedCaseRelatedStatusTrackings == null) cachedCaseRelatedStatusTrackings = new Map<id, StatusTracking__c>(); return cachedCaseRelatedStatusTrackings;}}
    static List<StatusTracking__c> getCaseRelatedStatusTrackingsFromCache(Set<id> keys) {
        List<StatusTracking__c> result = new List<StatusTracking__c>();
        system.debug('################## getCaseRelatedStatusTrackingsFromCache keys: ' + keys.isEmpty());
        if(!keys.isEmpty()){
            Set<id> notLoadedKeys = new Set<id>();
            for(id key: keys){
                system.debug('################## getCaseRelatedStatusTrackingsFromCache key: ' + key);
                if(cachedCaseRelatedStatusTrackings.containsKey(key)){
                    if(cachedCaseRelatedStatusTrackings.get(key) != null) {
                        result.add(cachedCaseRelatedStatusTrackings.get(key));
                    }
                }else{
                    notLoadedKeys.add(key);
                    cachedCaseRelatedStatusTrackings.put(key, null);
                }
            }
            if(!notLoadedKeys.isEmpty()){
                for(StatusTracking__c r: [Select Id, Case__c, Name, Duration__c, BusinessHours__c, CreatedDate, StartDate__c, EndDate__c, Fax__c from StatusTracking__c where Case__c in :notLoadedKeys and Duration__c = null]){
                    result.add(r);
                    cachedCaseRelatedStatusTrackings.put(r.id, r);
                }
            }
        }
        return result;
    }
    
    public static void updateCaseStatusTracking(Map<Id, Fax__c> oldFaxes, List<Fax__c> updatedFaxes) 
    {
        isFax = true;
        
        Id faxCaseRTId = getSSSWFaxCaseRT();
        
        // Cases
        Map<Id, Case> cases = new Map<Id, Case>(); 
        List<Case> toUpdateCase = new List<Case>();
        Map<Id, Fax__c> oldFaxCases = new Map<Id, Fax__c>(); 
        Map<Id,User> caseOwnerMap = new Map<Id,User>();
        List<Fax__c> considerFaxes = new List<Fax__c>();
        for (Fax__c fax : [select Case__c,Id, CreatedDate from Fax__c where Id in :updatedFaxes and RecordType.Name = 'Inbound' and Case__r.IsClosed = false]) {
            cases.put(fax.Case__c, null);
            considerFaxes.add(fax);
        }
        /**for (Fax__c fax : updatedFaxes) {
cases.put(fax.Case__c, null);
}**/
        for (Fax__c fax : oldFaxes.values()) {
            oldFaxCases.put(fax.Case__c, fax);
        }
        for (Case cas : [select Id, Status, OwnerId, RecordTypeId from Case where Id in :cases.keyset() or Id in :oldFaxCases.keyset()]) {
            cases.put(cas.Id, cas);
        }
        
        //Retreive the Case Owner IDs and User Names from the Trigger Map.
        for (Case cas : cases.values())
        {   
            if (cas != null) {
                caseOwnerMap.put(cas.OwnerId, null);
            }
        }
        for(User user: CaseTrackingUtility.getUsersFromCache(caseOwnerMap.keyset()))
        {
            caseOwnerMap.put(user.Id ,user);
        }
        
        // StatusTracking
        Map<Id, List<StatusTracking__c>> statusTrackingMap = new Map<Id, List<StatusTracking__c>>();
        List<StatusTracking__c> tempList;
        Set<StatusTracking__c> toUpdateSTSet = new Set<StatusTracking__c>();    // Nandan : added to prevent duplicate record in a list before DML
        List<StatusTracking__c> toUpdateST = new List<StatusTracking__c>();
        List<StatusTracking__c> toUpdateSTAfterCase = new List<StatusTracking__c>();
        List<StatusTracking__c> toInsertST = new List<StatusTracking__c>();
        Map<Id, StatusTracking__c> oldFaxStatusTrackingMap = new Map<Id, StatusTracking__c>();
        Map<Id, List<StatusTracking__c>> outdatedStatusTrackingMap = new Map<Id, List<StatusTracking__c>>();
        
        List<StatusTracking__c> statusTrackings = CaseTrackingUtility.getNotCompletedStatusTrackingsFromCache(cases.keyset());
        
        List<StatusTracking__c> oldStatusTrackings = getCaseRelatedStatusTrackingsFromCache(oldFaxCases.keyset());
        statusTrackings.addAll(oldStatusTrackings);
        
        for (StatusTracking__c st : statusTrackings) {
            // StatusTracking to update
            if (cases.keyset().contains(st.Case__c) && st.Duration__c == null) {
                tempList = statusTrackingMap.get(st.Case__c);
                if (tempList == null) {
                    tempList = new List<StatusTracking__c>{st};
                        } else {
                            tempList.add(st);
                        }
                statusTrackingMap.put(st.Case__c, tempList);
            }
        }
        
        for (StatusTracking__c st : oldStatusTrackings) {
            
            if (st.Fax__c == oldFaxCases.get(st.Case__c).Id) {
                oldFaxStatusTrackingMap.put(st.Case__c, st);
                
            } else if (st.EndDate__c == oldFaxCases.get(st.Case__c).CreatedDate) {
                tempList = outdatedStatusTrackingMap.get(st.Case__c);
                if (tempList == null) {
                    tempList = new List<StatusTracking__c>{st};
                        } else {
                            tempList.add(st);
                        }
                outdatedStatusTrackingMap.put(st.Case__c, tempList);
            }
        }        
        
        for (Fax__c fax : considerFaxes) {
            // Update related Case
            Id caseId = fax.Case__c;
            
            if (caseId != null) {
                Case relatedCase = cases.get(caseId);
                
                relatedCase.Status = 'Network Responded';
                relatedCase.Bypass_Data_enforcement__c = true;
                toUpdateCase.add(relatedCase);
                
                
                // Update related StatusTracking
                if(statusTrackingMap.get(caseId)!=null) {
                    for (StatusTracking__c st : statusTrackingMap.get(caseId)) {
                        st.EndDate__c = fax.CreatedDate;    
                        System.debug('** ST Id ==>'+ st.Id);
                        System.debug('** toUpdateSTSet ==>'+ toUpdateSTSet);
                        toUpdateSTSet.add(st);  // Nandan : used set instead of list to prevent duplicate 
                        //toUpdateST.add(st);   // Nandan : commented as it contains duplicate
                    }
                    
                }
                
                // Update Case status after updating related StatusTracking, but before creating a new StatusTracking                                       
                String OwnerId = relatedCase.OwnerId;
                String OwnerTZ = '';
                String OwnerName = '';  
                
                //Case Owner Details are for User Only          
                if (OwnerId.startsWith('005')) {
                    OwnerTZ = caseOwnerMap.get(OwnerId).TimeZoneSidKey;
                    OwnerName = caseOwnerMap.get(OwnerId).Name;  
                }               
                
                // Create new StatusTracking
                StatusTracking__c newStatusTracking = CaseTrackingUtility.newFaxTracking(relatedCase, 'Status', fax.CreatedDate, fax.Id, OwnerTZ, OwnerName);
                
                toInsertST.add(newStatusTracking);
                
            }
            
            // Clean up Cases if Fax was linked to another Case previously
            Fax__c oldFax = oldFaxes.get(fax.Id);
            system.debug('OldFaxCase:'+oldFax.Case__c);
            system.debug('NewFaxCase:'+fax.Case__c);
            if (oldFax != null && oldFax.Case__c != null && oldFax.Case__c != fax.Case__c) {
                
                Case oldCase = cases.get(oldFax.Case__c);
                if (oldCase.recordTypeId != faxCaseRTId) {
                    List<StatusTracking__c> toUpdate = new List<StatusTracking__c>();
                    Id cId = null;
                    String status = '';
                    
                    // Delete StatusTracking with this fax
                    StatusTracking__c oldFaxStatusTracking = oldFaxStatusTrackingMap.get(oldFax.Case__c);
                    
                    // Re-open StatusTracking with EndDate the same as the fax CreatedDate
                    List<StatusTracking__c> outdatedStatusTracking = outdatedStatusTrackingMap.get(oldFax.Case__c);
                    
                    //if (oldFaxStatusTracking.EndDate__c == null && outdatedStatusTracking != null) { comment out by yuanyuan zhang
                    if(outdatedStatusTracking != null) {
                        if (oldFaxStatusTracking.EndDate__c == null) {
                            for (StatusTracking__c st : outdatedStatusTracking) {
                                st.EndDate__c = null;
                                st.Duration__c = null;
                                st.DurationHours__c = null;
                                st.DurationMins__c = null;
                                st.DurationSeconds__c = null;
                                toUpdate.add(st);
                                
                                cId = oldFaxStatusTracking.Case__c;
                                //System.debug('[SSSWFaxUtility] oldFaxStatusTracking.Case__c' + oldFaxStatusTracking.Case__c);
                                status = st.StatusValue__c;
                            }
                        } else {
                            for (StatusTracking__c st : outdatedStatusTracking) {
                                st.EndDate__c = oldFaxStatusTracking.EndDate__c;
                                st.Duration__c = null;
                                st.DurationHours__c = null;
                                st.DurationMins__c = null;
                                st.DurationSeconds__c = null;
                                toUpdate.add(st);
                            }
                        }
                    }
                    
                    if (cId != null) {
                        Case c = cases.get(cId);
                        c.Status = status;
                        c.Bypass_Data_enforcement__c = true;
                        toUpdateCase.add(c);
                        
                        toUpdateSTAfterCase.addAll(toUpdate);
                    } else {
                        CaseTrackingUtility.updateOldTracking(toUpdate); 
                    }
                }
            }
        }
        toUpdateST.addAll(toUpdateST);
        System.debug('** toUpdateST ==>'+ toUpdateST);
        update toUpdateST;
        update toUpdateCase;
        update toUpdateSTAfterCase;
        insert toInsertST;
        delete oldFaxStatusTrackingMap.values();
        
        isFax = false;
    }
    
    /**
* When an inbound fax is created, need to create a temporary case so it
* appears in the work queue.
**/
    public static void createCaseForFax(List<Fax__c> faxes) 
    {
        List<Case> fCases = new List<Case>();
        
        Id rtFax, rtCase;
        for (RecordType rt : [select Id, DeveloperName, SObjectType from RecordType where (DeveloperName='Inbound' and SObjectType='Fax__c') OR (DeveloperName='SSSWFax' and SObjectType='Case')]) {
            if (rt.DeveloperName == 'Inbound' && rt.SObjectType == 'Fax__c') {
                rtFax = rt.Id;
            } else if (rt.DeveloperName == 'SSSWFax' && rt.SObjectType == 'Case') {
                rtCase = rt.Id;
            }
        }
        
        Group defaultFaxCaseOwner = [select id from Group where Type='Queue' and developername = 'SSSW_BOH_Group_3' LIMIT 1];
        
        // Create wrapper cases for each fax
        for (Fax__c fax : faxes) {
            if (fax.Case__c == null && fax.RecordTypeId == rtFax) {
                Case fCase = new Case(OwnerID = defaultFaxCaseOwner.id, RecordTypeId=rtCase, Origin='Fax', Type='Unprocessed Fax', Subject='Please Update Case based on Fax.', PriorityNumber__c = 10);
                fCases.add(fCase); 
            }
        }
        
        // Insert these cases
        insert fCases;
        
        // Link faxes to the new cases
        Integer i = 0;
        for (Fax__c fax : faxes) {
            if (fax.Case__c == null && fax.RecordTypeId == rtFax) {
                fax.Case__c = fCases[0].Id;
                i++;
            }
        }
    }
    
    public static void deleteCaseForFax(List<Case> cases) 
    {
        Map<Id, Case> toDeleteCases = new Map<Id, Case>();
        List<Fax__c> toUpdateFaxes = new List<Fax__c>();
        Id faxCaseRTId = getSSSWFaxCaseRT();
        
        for (Case c : cases) {
            if (c.RecordTypeId == faxCaseRTId && c.ParentId != null) {
                toDeleteCases.put(c.Id, c);
            }
        }
        
        if (toDeleteCases.values().size() > 0) {
            for (Fax__c fax : [select Id, Case__c from Fax__c where Case__c in :toDeleteCases.keyset()]) {
                Id parentCaseId = toDeleteCases.get(fax.Case__c).ParentId;
                fax.Case__c = parentCaseId;
                toUpdateFaxes.add(fax);
            }
            
            if(!Test.isRunningTest()) {
                update toUpdateFaxes;
            }
            
            
            for (Case c : [select id from Case where Id in :toDeleteCases.keyset()]) {
                toDeleteCases.put(c.Id, c);
            }
            
            delete toDeleteCases.values();
        }
    }
    
    // get Case SSSW Fax Record Type Id
    public static Id getSSSWFaxCaseRT() {
        DescribeSObjectResult result = Schema.getGlobalDescribe().get('Case').getDescribe();               
        Map<String, Schema.RecordTypeInfo> recordTypeInfo = result.getRecordTypeInfosByName();
        return recordTypeInfo.get('SSSW Fax').getRecordTypeId();        
    }
    
    /**
* When Fax to Facility (Outbound fax) is created, the case status is changed to
* 'awaiting facility response'.
**/
    /*
Jack disabled updateCaseStatus on 25th March. The logic is moved to FacilitySearch.cls

public static void updateCaseStatus(List<Fax__c> newFaxes) 
{
Map<Id, Case> statusToUpdateCases = new Map<Id, Case>(); 

RecordType rt = [select id from RecordType where DeveloperName = 'Outbound' and sobjecttype='Fax__c'];

for (Fax__c fax : newFaxes) {
if (fax.Case__c != null && fax.RecordTypeId == rt.Id) {
statusToUpdateCases.put(fax.Case__c, null);
}
}

for (Case cas : [select Id, Status, PrimaryFacility__c from Case where Id in :statusToUpdateCases.keyset()]) {
if (cas.PrimaryFacility__c != null) {
cas.Status = 'Awaiting Facility Response';
statusToUpdateCases.put(cas.Id, cas);
} else {
statusToUpdateCases.remove(cas.Id);
}
}

update statusToUpdateCases.values();
}
*/
}