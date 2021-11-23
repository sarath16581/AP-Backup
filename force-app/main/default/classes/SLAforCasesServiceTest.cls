@IsTest (IsParallel=true)
public class SLAforCasesServiceTest {
    @TestSetup
    static void setup(){
        /*** Create Case record records. */
        Case cs = new Case();
        cs.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId();
        cs.BusinessHoursId=[SELECT Id FROM BusinessHours WHERE Name='SSSWSydney'].Id;
        cs.Type = SSSWConstants.CASE_TYPE_INVESTIGATION;
        cs.Origin = SSSWConstants.CASE_ORIGIN;
        cs.ProductCategory__c = SSSWConstants.CASE_PROD_CAT;
        cs.ProductSubCategory__c = SSSWConstants.CASE_PROD_SUB_CAT;
        cs.Priority = SSSWConstants.CASE_PRIORITY;
        cs.Subject='Testing 5 Days SLA';
        cs.Status= 'Closed'; //SSSWConstants.CASE_STATUS_NEW;
        cs.OwnerId = [SELECT Id, QueueId FROM QueueSobject WHERE Queue.Name='SSSW Network Queue'].QueueId;
        cs.ResolutionCode__c = 'Assistance provided';
        cs.EnquirySubType__c = SSSWConstants.CASE_ENQUIRY_SUBTYPE;
        insert cs;
        
        /*** Create callback records. */
        List<Callback_Request__c> callbackRequestList = new List<Callback_Request__c>();
        /*** Create callback records. */
        Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
        Id SSSW_Callback_RequestId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Request').getRecordTypeId();
        
        callbackRequestList.add(new Callback_Request__c(RecordTypeId=SSSW_Callback_RequestId,Status__c = SSSWConstants.CALLBACK_REQUEST_STATUS_VOICEMAIL, CaseId__c=cs.Id, CaseBusinessHoursId__c=cs.BusinessHoursId));
        callbackRequestList.add(new Callback_Request__c(RecordTypeId=SSSW_Callback_RequestId,Status__c = SSSWConstants.CALLBACK_REQUEST_STATUS_NO_VOICEMAIL, CaseId__c=cs.Id, CaseBusinessHoursId__c=cs.BusinessHoursId));
        callbackRequestList.add(new Callback_Request__c(RecordTypeId=SSSW_Callback_RequestId,Status__c = SSSWConstants.CALLBACK_REQUEST_STATUS_CASE_UNRESOLVED, CaseId__c=cs.Id,CaseBusinessHoursId__c=cs.BusinessHoursId));
        
        insert callbackRequestList;
        
        /*** Create Case record records. Validate Duplicate */
        cs = new Case();
        cs.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId();
        cs.BusinessHoursId=[SELECT Id FROM BusinessHours WHERE Name='SSSWSydney'].Id;
        cs.Type = SSSWConstants.CASE_TYPE_INVESTIGATION;
        cs.Origin = SSSWConstants.CASE_ORIGIN;
        cs.ProductCategory__c = SSSWConstants.CASE_PROD_CAT;
        cs.ProductSubCategory__c = SSSWConstants.CASE_PROD_SUB_CAT;
        cs.Priority = SSSWConstants.CASE_PRIORITY;
        cs.Subject='Testing 5 Days SLA - Duplicate Validation';
        cs.Status = SSSWConstants.CASE_SLA_STATUS;
        cs.OwnerId = [SELECT Id, QueueId FROM QueueSobject WHERE Queue.Name='SSSW Network Queue'].QueueId;
        cs.ResolutionCode__c = 'Assistance provided';
        cs.EnquirySubType__c = SSSWConstants.CASE_ENQUIRY_SUBTYPE;
        insert cs;
    }
    
    @IsTest
    public static void Validate5DaysSLATest(){
        
        List<Case> caseList = [SELECT Id, RecordTypeId, Status, CreatedDate,BusinessHoursId FROM Case];
        Double SLAHours = 0.0;
        
        Test.startTest();
        SLAforCasesService.validateSLAandCreateCBRequest(caseList);
        Test.stopTest();
        
        Set<Id> resultIds = (new Map<Id,Case>(caseList)).keySet();
        
        List<Callback_Request__c> cbReq = [SELECT Id, CaseId__c FROM Callback_Request__c WHERE CaseId__c IN: resultIds];
        
        System.assert(cbReq.size()>0, 'Callback Request created.');
    }
    
    @IsTest
    public static void CreateCallbackRequestTest(){
        List<Case> caseList = [SELECT Id, RecordTypeId, Status, CreatedDate,BusinessHoursId FROM Case];
        Test.startTest();
        SLAforCasesService.createCallbackRequest(caseList);
        Test.stopTest();
        
        Set<Id> resultIds = (new Map<Id,Case>(caseList)).keySet();
        List<Callback_Request__c> cbReq = [SELECT Id, CaseId__c FROM Callback_Request__c WHERE CaseId__c IN: resultIds];        
        System.assert(cbReq.size()>0, 'Callback Request created.');
    }
    
    @IsTest
    public static void closeCallbackRequetRelatedToCaseTest(){
        
        List<Case> caseList = [SELECT Id, RecordTypeId, Status, CreatedDate,BusinessHoursId FROM Case WHERE Status='Closed'];
        List<Case> caseListOld = caseList.Clone();
        
        for(Case c: caseListOld){
            c.Status = 'New';
        }
        
        Test.startTest();
        SLAforCasesService.closeCallbackRequetRelatedToCase(caseList, caseListOld);
        Test.stopTest();
       
        List<Callback_Request__c> cbReq = [SELECT Id, Status__c, CaseId__c, CaseBusinessHoursId__c FROM Callback_Request__c WHERE CaseId__c IN: (new Map<Id,Case>(caseList)).keySet()];
        System.assert(cbReq.size()>0, 'Callback Request Closed.');
    }
}