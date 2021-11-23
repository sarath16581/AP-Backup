/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Apex class used by StarTrack Log a Call Process Builder (Process)
Test Class:    StarTrackCreateCallLogActivity_Test
History
August 10, 2016 - David Catindoy - Created
August 23, 2016 - David Catindoy - Modified to use @future method
------------------------------------------------------------*/

public with sharing class StarTrackCreateCallLogActivity {
    @InvocableMethod    
    public static void createLogACallRecord(List<Id> caseIdList){
        //Call method to create call log record.
        if(StarTrack_Settings__c.getOrgDefaults().Create_Call_Log_using_Future__c){
            //Execute the process in asynchronous manner.
            createCallLogAsync(caseIdList);
        } else{
            //Execute the process in synchronous manner.
            createCallLogSync(caseIdList);
        }
        
    }
    
    public static void createCallLogSync(List<Id> caseIdList){
        createCallLog(caseIdList);
    }
    
    @future
    public static void createCallLogAsync(List<Id> caseIdList){
        createCallLog(caseIdList);
    }
    
    public static void createCallLog(List<Id> caseIdList){
        //Initialize container
        List<QuickAction.QuickActionRequest> reqList = new List<QuickAction.QuickActionRequest>();
        //Query to get the latest case records.
        List<Case> caseRecList = [SELECT Id, Recent_Caller_First_Name__c, Recent_Caller_Last_Name__c, Recent_Caller_Type__c, Priority, Status, Recent_Caller_Phone_Number__c, Recent_Caller_Email__c,
                                  Number_of_Callers__c, Direction__c, Recent_Caller_Pref_Method_of_Contact__c, Call_Purpose__c,
                                  (SELECT Id, Subject, RecordType.Name FROM Tasks WHERE RecordType.Name = :StarTrack_Constants.TASK_RECTYPE_ACTIVITY AND (Subject LIKE :(StarTrack_Constants.INBOUND_CALLLOG_PREFIX + '%') OR Subject LIKE :(StarTrack_Constants.OUTBOUND_CALLLOG_PREFIX + '%')))
                                  FROM Case WHERE Id IN :caseIdList];
        for(Case caseRec : caseRecList){
            Task newTask = new Task(Subject = caseRec.Direction__c + StarTrack_Constants.CALLLOG_PREFIX + caseRec.Recent_Caller_First_Name__c + ' ' + caseRec.Recent_Caller_Last_Name__c + ' (' + caseRec.Recent_Caller_Type__c + ')', Interaction_Type__c = StarTrack_Constants.TASK_INTERACTION,
                                Priority = String.isBlank(caseRec.Priority) ? StarTrack_Constants.PRIORITY_NORMAL : caseRec.Priority, Description = caseRec.Direction__c + StarTrack_Constants.CALLLOG_PREFIX + caseRec.Recent_Caller_First_Name__c + ' ' + caseRec.Recent_Caller_Last_Name__c + ' (' + caseRec.Recent_Caller_Type__c + (String.isBlank(caseRec.Call_Purpose__c) ? '' : (': ' + caseRec.Call_Purpose__c)) + ')',
                                Status = StarTrack_Constants.TASK_STATUS_COMPLETED, Phone__c = caseRec.Recent_Caller_Phone_Number__c, Email__c = caseRec.Recent_Caller_Email__c, Call_Log_Number__c = caseRec.Tasks.size() + 1, Type = StarTrack_Constants.TASK_TYPE_PHONE,
                                Direction__c = caseRec.Direction__c, Pref_Method_of_Contact__c = String.isBlank(caseRec.Recent_Caller_Pref_Method_of_Contact__c) ? StarTrack_Constants.TASK_NA : caseRec.Recent_Caller_Pref_Method_of_Contact__c);
            //Initialize quick action request.
            QuickAction.QuickActionRequest req = new QuickAction.QuickActionRequest();
            //Specify the quick action name to be performed.
            req.quickActionName = Schema.Case.QuickAction.Custom_Call_log;
            //Specify the record to be created when quick action was performed.
            req.record = newTask;
            //Specify the case record in which the action is to be associated with.
            req.contextid = caseRec.Id;
            //Add single quick action request to the container list 
            reqList.add(req);
        }
        
        //Check if there is a quick action request to be performed.
        if(!reqList.isEmpty()){
            //Perform all quick action requests specified in the parameter.
            List<QuickAction.QuickActionResult> res = QuickAction.performQuickActions(reqList);
            //Update case records to reflect the updated number of callers.
            Database.update(caseRecList);
        }
    }
}