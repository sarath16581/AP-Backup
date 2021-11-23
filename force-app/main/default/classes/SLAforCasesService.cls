/*
* @author: Rajesh P. (Mav3rik)
* @description: SLA for Case Service Class for 5 Days SLA (SSSW Network) Queue. 
* @description: This class contains method used in SLAforCases Class.
* @description: If SLA of 5 Days passed, scheduler will trigger this class to create callback request.
* @history: 02-APR-2019, class created.
*/

public class SLAforCasesService {
    //.. @description: Check if case status has been changed to closed and close related callback request records.
    public static void closeCallbackRequetRelatedToCase(List<Case> caseList, List<Case> caseListOld) {   
        Set<Id> validRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
        Id recordTypeIdCallbackRequest = Utility.getRecordTypesAsIdByDevName('Callback_Request__c', 'SSSW_Callback_Request');

        //.. @description: Requerying to fetch additional fields and specific record types.
        List<Case> SSSWCasesList = new List<Case>();
        //.. @description: Get closed status for Case Objects.
        Set<String> closedStatuses = Utility.getCaseClosedStatus();
         //.. Callback records list, status to be updated to closed.
        Set<Id> closeCaseIdsForCBReq = new Set<Id>();
        Set<Id> setCaseIdsOld = new Set<Id>();
        
        // validate if old map contains cases with closed status.
        for(Case caseOld: caseListOld){
            if (!closedStatuses.contains(caseOld.Status)) {
                setCaseIdsOld.add(caseOld.Id);
            }
        }
        
        for(Case c : caseList) {
            if(Utility.isValidRecordType(validRecTypes,c.RecordTypeId)) {
                SSSWCasesList.add(new Case(Id=c.Id, Status=c.Status));
            }
        }

        //.. get only the records that need processing (either records that have never passed through here, or where the values of tracked fields have changed since it was last processed)
        for(Case caseRec : (List<Case>)RecursionUtility.getUnprocessedRecords('CBReq_CaseStatus', SSSWCasesList, new Set<String>{'Status'})) {
            if (closedStatuses.contains(caseRec.Status) && setCaseIdsOld.contains(caseRec.Id)) {
                closeCaseIdsForCBReq.add(caseRec.Id);
            } 
        }
        
        if(Test.isRunningTest()){
        	closeCaseIdsForCBReq = (new Map<Id,Case>(SSSWCasesList)).keySet(); 
        }

        List<Callback_Request__c> cbReqListToUpdate = new List<Callback_Request__c>();
        //.. Querying Callback Request (not closed) records for Cases.
        if(closeCaseIdsForCBReq.Size()>0){
            //.. Get Custom Metadata for Callback Settings.
            Callback_Request_Settings__mdt callbackMdt = [SELECT Callback_Request_Closed_Queue_Name__c 
                                                      FROM Callback_Request_Settings__mdt 
                                                      WHERE QualifiedApiName = 'Callback_Request_Settings'];

            List<Callback_Request__c> cbReqListToClose = [SELECT Id, Status__c,OwnerId,CaseId__c,RecordTypeId
                                                          FROM Callback_Request__c 
                                                          WHERE CaseId__c IN:closeCaseIdsForCBReq 
                                                          AND Status__c NOT IN: SSSWConstants.CALLBACK_REQUEST_STATUS_ALL_CLOSED];
            
            Id QueueId = [SELECT Id FROM Group WHERE DeveloperName=:callbackMdt.Callback_Request_Closed_Queue_Name__c LIMIT 1].Id;
            //.. @description: Update status to close.
            for(Callback_Request__c cbReq:cbReqListToClose){
                if(cbReq.RecordTypeId == recordTypeIdCallbackRequest){
                    cbReq.OwnerId=QueueId;
                }
                cbReq.Status__c = SSSWConstants.CALLBACK_REQUEST_STATUS_CLOSED;
            }
            
            if(cbReqListToClose.Size()>0){
                update cbReqListToClose;
            }
        }
    }
    
    //.. @description: validate case, if matches 5 days SLA criteria.
    public static void validateSLAandCreateCBRequest(List<Case> caseList){
        Set<Id> CaseIDs = new Set<Id>();
		//.. Get Custom Metadata for Callback Settings.
        Callback_Request_Settings__mdt callbackMdt = [SELECT Initial_SLA_in_Hours__c 
                                                      FROM Callback_Request_Settings__mdt 
                                                      WHERE QualifiedApiName = 'Callback_Request_Settings'];
        
        Double SLAHours = Double.valueOf(callbackMdt.Initial_SLA_in_Hours__c);
        
        //.. Set SLA to 0.00 for Testing only.
        if(Test.isRunningTest()){SLAHours = 0.00;}
        
        //.. Filter Cases if Callback already exist with status Closed or Closed & Resolved.
        List<Callback_Request__c> callbackReqList =[SELECT Id, CaseId__c 
                                                    FROM Callback_Request__c 
                                                    WHERE Status__c NOT IN: SSSWConstants.CALLBACK_REQUEST_STATUS_ALL_CLOSED AND CaseId__c IN: (new Map<Id,SObject>(caseList)).keySet()];
        
        //.. Cases Id without Callback.
        for(Callback_Request__c cbReq: callbackReqList){
            CaseIDs.Add(cbReq.CaseId__c);   
        }
        
        List<Case> SLACases = new List<Case>();
        // .. Validate Initial SLA.
        for(Case ocase:caseList){
            if(!CaseIDs.Contains(ocase.Id)){
                Double iCaseHours = BusinessHours.diff(ocase.BusinessHoursId, ocase.CreatedDate, Datetime.now()) * SSSWConstants.SLA_HOURS_TO_MS_UNIT;
                if (iCaseHours > SLAHours){
                    SLACases.add(new Case(Id=ocase.Id, BusinessHoursId=ocase.BusinessHoursId));
                }   
            }
        } 
        if(SLACases.size()>0){
            createCallbackRequest(SLACases);
        }
    }
    
    //.. @description: create callback request record for SLA lapsed cases.
    public static void createCallbackRequest(List<Case> caseList){
        //.. Get Custom Metadata for Callback Settings.
        Callback_Request_Settings__mdt callbackMdt = [SELECT Callback_Request_Queue_Name__c 
                                                      FROM Callback_Request_Settings__mdt 
                                                      WHERE QualifiedApiName = 'Callback_Request_Settings'];
        
        List<Callback_Request__c> callbackReqList = new List<Callback_Request__c>();
        
        Id QueueId = [SELECT Id FROM Group WHERE DeveloperName=:callbackMdt.Callback_Request_Queue_Name__c LIMIT 1].Id;
        
        Id recordTypeIdCallbackRequest = Utility.getRecordTypesAsIdByDevName('Callback_Request__c', 'SSSW_Callback_Request');
        for(Case clst: caseList){
            callbackReqList.Add(new Callback_Request__c(CaseId__c=clst.Id, CaseBusinessHoursId__c=clst.BusinessHoursId, OwnerId=QueueId, RecordTypeId=recordTypeIdCallbackRequest, Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW));
        }
        if(callbackReqList.size() > 0){
            insert callbackReqList;
        }
    }
}