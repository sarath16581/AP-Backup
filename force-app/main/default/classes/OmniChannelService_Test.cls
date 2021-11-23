/**
 * @File Name          : OmniChannelService_Test.cls
 * @Description        : 
 * @Author             : rajesh.punjabi@mav3rik.com
 * @Group              : 
 * @Last Modified By   : rajesh.punjabi@mav3rik.com
 * @Last Modified On   : 9/25/2019, 12:13:33 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    8/21/2019, 10:54:47 AM   rajesh.punjabi@mav3rik.com     Initial Version
**/
@IsTest (IsParallel=true)
public class OmniChannelService_Test {
    @TestSetup
    static void setup(){
        /*** Create Case record records. */
        Case cs2 = new Case();
        cs2.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId();
        cs2.BusinessHoursId=[SELECT Id FROM BusinessHours WHERE Name='SSSWSydney'].Id;
        cs2.Type = SSSWConstants.CASE_TYPE;
        cs2.Origin = SSSWConstants.CASE_ORIGIN;
        cs2.ProductCategory__c = SSSWConstants.CASE_PROD_CAT;
        cs2.ProductSubCategory__c = SSSWConstants.CASE_PROD_SUB_CAT;
        cs2.Priority = SSSWConstants.CASE_PRIORITY;
        cs2.Subject='Testing 5 Days SLA';
        cs2.Status=SSSWConstants.CASE_SLA_STATUS;
        cs2.OwnerId = [SELECT Id, QueueId FROM QueueSobject WHERE Queue.Name='SSSW Network Queue'].QueueId;
        insert cs2;
        
        /*** Create callback records. */
        Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
        List<Callback_Request__c> callbackRequestList = new List<Callback_Request__c>();
        DateTime dtNow = System.now();
        callbackRequestList.add(new Callback_Request__c(OwnerId=Userinfo.getUserId(),Type__c ='Business',ReExecutionDateTime__c=dtNow.addMinutes(15),RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId));
        callbackRequestList.add(new Callback_Request__c(OwnerId=Userinfo.getUserId(),Type__c ='Business',ReExecutionDateTime__c=dtNow.addMinutes(15),RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId));
		insert callbackRequestList;
    }
    
    @IsTest
    public static void assignRemindertoAgent_Test(){
        Boolean bReturn = false;
        Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
        List<Callback_Request__c> cbrlist = [SELECT Id, OwnerId, Status__c,CreatedById FROM Callback_Request__c WHERE RecordTypeId=:SSSW_Callback_ReminderId LIMIT 1];
        Id HoldingQueueId = [SELECT Id FROM Group WHERE DeveloperName='SSSW_Callback_Reminder_Holding_Queue' LIMIT 1].Id;
        
        List<Callback_Request__c> cbrToUpdate = new List<Callback_Request__c>();	

        //.. updating owner to queue to generate pending service id
        for (Callback_Request__c cbr: cbrlist){
            cbrToUpdate.Add(new Callback_Request__c(Id=cbr.Id, OwnerId=HoldingQueueId));
        }
        if(cbrToUpdate.size()> 0){
            update cbrToUpdate;
        }
        
        for (Callback_Request__c cbr: cbrlist){
            cbr.OwnerId=Userinfo.getUserId();
        }
        
        Test.startTest();
        bReturn = OmniChannelService.assignRemindertoAgent(cbrlist);
        Test.stopTest();
        
        System.assert(bReturn, 'Reminder request assigned to agent');
    }
}