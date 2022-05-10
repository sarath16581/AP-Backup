/**
 * @File Name          : CallbackRequestTriggerHandlerTest.cls
 * @Description        : 
 * @Author             : rajesh.punjabi@mav3rik.com
 * @Group              : 
 * @Last Modified By   : rajesh.punjabi@mav3rik.com
 * @Last Modified On   : 9/24/2019, 2:04:29 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
 * 1.0    7/30/2019, 10:55:02 AM   rajesh.punjabi@mav3rik.com     Initial Version
**/
@IsTest (IsParallel=true)
public class CallbackRequestTriggerHandlerTest {
    
    @TestSetup
    static void setup(){
        
        /*** Create Case record records. */
        Case cs = new Case();
        cs.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId();
        cs.BusinessHoursId=[SELECT Id FROM BusinessHours WHERE Name='SSSWSydney'].Id;
        cs.Type = SSSWConstants.CASE_TYPE;
        cs.Origin = SSSWConstants.CASE_ORIGIN;
        cs.ProductCategory__c = SSSWConstants.CASE_PROD_CAT;
        cs.ProductSubCategory__c = SSSWConstants.CASE_PROD_SUB_CAT;
        cs.Priority = SSSWConstants.CASE_PRIORITY;
        cs.Subject='Testing 5 Days SLA';
        cs.Status=SSSWConstants.CASE_SLA_STATUS;
        cs.OwnerId = [SELECT Id, QueueId FROM QueueSobject WHERE Queue.Name='SSSW Network Queue'].QueueId;
        insert cs;

        /*** Create Case record records. */
        Case cs2 = new Case();
        cs2.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId();
        cs2.BusinessHoursId=[SELECT Id FROM BusinessHours WHERE Name='SSSWSydney'].Id;
        cs2.Type = SSSWConstants.CASE_TYPE;
        cs2.Origin = SSSWConstants.CASE_ORIGIN;
        cs2.ProductCategory__c = SSSWConstants.CASE_PROD_CAT;
        cs2.ProductSubCategory__c = SSSWConstants.CASE_PROD_SUB_CAT;
        cs2.Priority = SSSWConstants.CASE_PRIORITY;
        cs2.Subject='CBR_Reminder';
        cs2.Status=SSSWConstants.CASE_SLA_STATUS;
        cs2.OwnerId = [SELECT Id, QueueId FROM QueueSobject WHERE Queue.Name='SSSW Network Queue'].QueueId;
        insert cs2;
        
        /*** Create callback records. */
        Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
        Id SSSW_Callback_RequestId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Request').getRecordTypeId();

        List<Callback_Request__c> callbackRequestList = new List<Callback_Request__c>();
        DateTime dtNow = System.now();
        
        callbackRequestList.add(new Callback_Request__c(Type__c ='Business',ReExecutionDateTime__c=dtNow.addMinutes(15), RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId));
        callbackRequestList.add(new Callback_Request__c(Type__c ='FCR',ReExecutionDateTime__c=dtNow.addMinutes(15),RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId));
        callbackRequestList.add(new Callback_Request__c(RecordTypeId=SSSW_Callback_RequestId,Status__c = SSSWConstants.CALLBACK_REQUEST_STATUS_VOICEMAIL, CaseId__c=cs.Id, CaseBusinessHoursId__c=cs.BusinessHoursId));
        callbackRequestList.add(new Callback_Request__c(RecordTypeId=SSSW_Callback_RequestId,Status__c = SSSWConstants.CALLBACK_REQUEST_STATUS_NO_VOICEMAIL, CaseId__c=cs.Id, CaseBusinessHoursId__c=cs.BusinessHoursId));
        callbackRequestList.add(new Callback_Request__c(RecordTypeId=SSSW_Callback_RequestId,Status__c = SSSWConstants.CALLBACK_REQUEST_STATUS_CASE_UNRESOLVED, CaseId__c=cs.Id,CaseBusinessHoursId__c=cs.BusinessHoursId));
        
        insert callbackRequestList;
        
    }
    
    @IsTest
    public static void ValidateAndScheduleCallbackRequestTest(){
        Id SSSW_Callback_RequestId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Request').getRecordTypeId();
        List<Callback_Request__c> cbReqlist = [SELECT Id, Status__c, ReExecutionDateTime__c, CaseId__c FROM Callback_Request__c WHERE RecordTypeId=:SSSW_Callback_RequestId];
        
        Test.startTest();
        CallbackRequestTriggerHandler.ValidateAndScheduleCallbackRequest(cbReqlist);
        Test.stopTest();
        
        for(Callback_Request__c cbReq:cbReqlist){
            if(cbReq.Status__c==SSSWConstants.CALLBACK_REQUEST_STATUS_VOICEMAIL || cbReq.Status__c==SSSWConstants.CALLBACK_REQUEST_STATUS_NO_VOICEMAIL){
                system.assertNotEquals(cbReq.ReExecutionDateTime__c < System.Datetime.Now()+1, true, 'Customer didnot attend the call.');
            }
            else{
                system.assertNotEquals(cbReq.ReExecutionDateTime__c > System.Datetime.Now()+4, true, 'Case not resolved.');
            }
        }
    }
    
    @IsTest
    public static void addFeedItemTest(){
        Id SSSW_Callback_RequestId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Request').getRecordTypeId();
        List<Callback_Request__c> cbReqlist = [SELECT Id, Status__c, CaseId__c FROM Callback_Request__c WHERE RecordTypeId=:SSSW_Callback_RequestId];
        
        Test.startTest();
        CallbackRequestTriggerHandler.addFeedItem(cbReqlist);
        Test.stopTest();
        
        List<FeedItem> fi = [SELECT Id FROM FeedItem WHERE ParentId =: cbReqlist[0].CaseId__c and Title='Callback'];
        System.assert(fi.size()>0, 'Feed Item found');
        
    }

    @IsTest
    public static void routeCallbackReminderTest(){
        Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();

        List<Callback_Request__c> callbackRequestList = new List<Callback_Request__c>();
        DateTime dtNow = System.now();
        Case cs2 =[SELECT Id,BusinessHoursId FROM Case WHERE Subject='CBR_Reminder'];
        
        Callback_Request__c cbr1 = new Callback_Request__c(Type__c ='Business',ReExecutionDateTime__c=dtNow.addMinutes(15), RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId);
        Callback_Request__c cbr2 = new Callback_Request__c(Type__c ='FCR',ReExecutionDateTime__c=dtNow.addMinutes(15),RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId);
        
        List<Callback_Request__c> cbReqlistOld = new List<Callback_Request__c>();
        List<Callback_Request__c> cbReqlist = new List<Callback_Request__c>();
        cbReqlistOld.add(cbr1);
        cbReqlistOld.add(cbr2);
        cbReqlist.add(cbr1);
        cbReqlist.add(cbr2);
                     
        Test.startTest();
        CallbackRequestTriggerHandler.routeCallbackReminder(cbReqlistOld, cbReqlist);
        Test.stopTest();
        
        cbReqlist = [SELECT Id, OwnerId, Status__c, ReExecutionDateTime__c, CaseId__c,RecordTypeId FROM Callback_Request__c WHERE RecordTypeId=:SSSW_Callback_ReminderId];                                                                                      
        System.assert(cbReqlist.size()>0, 'Record Assigned to Queue');
    }
    
    @IsTest
    public static void validateDueDateTimeWithShiftHours1(){  /// date less than today
        Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
        DateTime dtNow = System.now();
        Case cs2 =[SELECT Id,BusinessHoursId FROM Case WHERE Subject='CBR_Reminder'];
        Callback_Request__c cbr1 = new Callback_Request__c(Type__c ='Business',ReExecutionDateTime__c=dtNow.addDays(-2), RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId);
        
        List<Callback_Request__c> cbReqlist = new List<Callback_Request__c>();
        cbReqlist.add(cbr1);
        
        
        Test.startTest();
        CallbackRequestTriggerHandler.validateDueDateTimeWithShiftHours(cbReqlist);
        Test.stopTest();
        for(ApexPages.Message message : ApexPages.getMessages()){
            System.assert(message.getSummary() == System.Label.SSSWCBRPastDateErrorMsg, System.Label.SSSWCBRPastDateErrorMsg);
        }
    }
    
    @IsTest
    public static void validateDueDateTimeWithShiftHours2(){  // Within date but not time
        Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
        DateTime dtNow = System.now();
        Case cs2 =[SELECT Id,BusinessHoursId FROM Case WHERE Subject='CBR_Reminder'];
        Callback_Request__c cbr1 = new Callback_Request__c(Type__c ='Business',ReExecutionDateTime__c=dtNow.addHours(-2), RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId);
        
        List<Callback_Request__c> cbReqlist = new List<Callback_Request__c>();
        cbReqlist.add(cbr1);
       
        Test.startTest();
        CallbackRequestTriggerHandler.validateDueDateTimeWithShiftHours(cbReqlist);
        Test.stopTest();
        
        for(ApexPages.Message message : ApexPages.getMessages()){
            System.debug('----:'+ message.getSummary());
            System.assert(message.getSummary() == System.Label.SSSWCBRPastDateErrorMsg, System.Label.SSSWCBRPastDateErrorMsg);
        }
    }
    
    @IsTest
    public static void validateDueDateTimeWithShiftHours3(){  // Date Time is OK + SLA Hours Fails.
        Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
        Date dtToday = System.today();
        Time tCurrent = Time.newInstance(22, 09, 11, 11);
        DateTime dtNow = DateTime.newInstance(dtToday, tCurrent);
               
        Case cs2 =[SELECT Id,BusinessHoursId FROM Case WHERE Subject='CBR_Reminder'];
        Callback_Request__c cbr1 = new Callback_Request__c(Type__c ='FCR',ReExecutionDateTime__c=dtNow, RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId);
        
        List<Callback_Request__c> cbReqlist = new List<Callback_Request__c>();
        cbReqlist.add(cbr1);
        
        
        Test.startTest();
        CallbackRequestTriggerHandler.validateDueDateTimeWithShiftHours(cbReqlist);
        Test.stopTest();
        
        for(ApexPages.Message message : ApexPages.getMessages()){
            System.assert(message.getSummary() == System.Label.SSSWCBRShiftHoursErrorMsg, System.Label.SSSWCBRShiftHoursErrorMsg);
        }
    }
}