/**
 * @File Name          : OmniChannelAPIUitlity_Test.cls
 * @Description        : 
 * @Author             : rajesh.punjabi@mav3rik.com
 * @Group              : 
 * @Last Modified By   : rajesh.punjabi@mav3rik.com
 * @Last Modified On   : 9/25/2019, 11:55:15 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    9/25/2019   rajesh.punjabi@mav3rik.com     Initial Version
**/
@IsTest (IsParallel=true)
public class OmniChannelAPIUitlity_Test {
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
		Id ReminderQueueId = [SELECT Id FROM Group WHERE DeveloperName='SSSW_Business' LIMIT 1].Id;
        DateTime dtNow = System.now();
        List<Callback_Request__c> callbackRequestList = new List<Callback_Request__c>();
        callbackRequestList.add(new Callback_Request__c(Type__c ='Business',ReExecutionDateTime__c=dtNow.addMinutes(15),OwnerId=ReminderQueueId,RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId));
        callbackRequestList.add(new Callback_Request__c(Type__c ='FCR',ReExecutionDateTime__c=dtNow.addMinutes(15),OwnerId=Userinfo.getUserId(),RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId));
		insert callbackRequestList;
    }
    @IsTest
    public static void isUserOnline_Test(){
        Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
        Id UserId = [SELECT Id, OwnerId FROM Callback_Request__c WHERE RecordTypeId=:SSSW_Callback_ReminderId LIMIT 1].OwnerId;
        Set<Id> setUserIds = new Set<Id>();
        setUserIds.add(UserId);
        Test.startTest();
        setUserIds = OmniChannelAPIUitlity.isUserOnline(setUserIds);
        Test.stopTest();   
        
        System.assert(setUserIds.size() > 0, 'User is online');
    }
    
    @IsTest
    public static void getServiceChannelIdTest(){
        Id presenceId;
        
        Test.startTest();
        presenceId = OmniChannelAPIUitlity.getServiceChannelId('Callback_Request_Channel');
        Test.stopTest(); 
        
        System.assert(!String.isBlank(presenceId), 'Presence Id found');
    }
    
    @IsTest
    public static void getPendingServiceRoutingIdsTest(){
        Map<Id, Id> mapWorkItemServiceRoutingIds = new Map<Id, Id> ();
        Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
        Id ReminderQueueId = [SELECT Id FROM Group WHERE DeveloperName='SSSW_FCR' LIMIT 1].Id;
        List<Callback_Request__c> callbackRequestList = [SELECT Id, OwnerId FROM Callback_Request__c WHERE RecordTypeId=:SSSW_Callback_ReminderId LIMIT 1];
        for(Callback_Request__c cbr: callbackRequestList){
            cbr.OwnerId=ReminderQueueId;
        }
        Test.startTest();
		mapWorkItemServiceRoutingIds = OmniChannelAPIUitlity.getPendingServiceRoutingIds((new Map<Id,Callback_Request__c>(callbackRequestList)).keySet());
        Test.stopTest();
        
        System.assert(mapWorkItemServiceRoutingIds.size()>0, 'Callback Reminder Service Routing Id found.');
        
    }
   
    @IsTest
    public static void createWorkItemforOwnerTest(){
        Boolean bReturn = false;
        Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
        Id ReminderQueueId = [SELECT Id FROM Group WHERE DeveloperName='SSSW_FCR' LIMIT 1].Id;
        
        Callback_Request__c cbr = [SELECT Id, OwnerId FROM Callback_Request__c WHERE RecordTypeId=:SSSW_Callback_ReminderId LIMIT 1];
        
        Id ServiceChannelId = OmniChannelAPIUitlity.getServiceChannelId('Callback_Request_Channel');
        Id WorkItemId = cbr.Id;
    	Id UserId = Userinfo.getUserId();
        cbr.OwnerId = ReminderQueueId;
        update cbr;
        
        List<Callback_Request__c> callbackRequestList = new List<Callback_Request__c>();
        callbackRequestList.add(cbr);
        
		Map<Id, Id> pendingserviceIds = OmniChannelAPIUitlity.getPendingServiceRoutingIds((new Map<Id,Callback_Request__c>(callbackRequestList)).keySet());
        Id PendingServiceRoutingId = pendingserviceIds.get(WorkItemId);

        List<AgentWorkWrapper> lstWrap = new List<AgentWorkWrapper>();
        AgentWorkWrapper wrap = new AgentWorkWrapper();
        wrap.ServiceChannelId=ServiceChannelId;
        wrap.WorkItemId=WorkItemId;
        wrap.UserId=UserId;
        wrap.PendingServiceRoutingId=PendingServiceRoutingId;
        lstWrap.add(wrap);
        
        Test.startTest();
        bReturn = OmniChannelAPIUitlity.createWorkItemforOwner(lstWrap);
        Test.stopTest();
        
        System.assert(bReturn, 'Reminder request assigned to agent');
    }
}