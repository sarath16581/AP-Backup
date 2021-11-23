/*
* @author: Rajesh P. (Mav3rik)
* @description: Handler class for Trigger [CallbackRequest on Callback_Request__c].
* @description: Validate the status of Callback Request when Agent modifies (manually).
* @description: If status = Voicemail or No Voicemail, call back request will be re-routed after 6 business hours.
* @description: if status = Case Un-resolved, callback request will be re-routed after 5 business days.
* @testclass: CallbackRequestTriggerHandlerTest
* @history:09-APR-2019, class created.

TODO: Re-factor code to avoid SQL query.
*/

public class CallbackRequestTriggerHandler {  
    /**
    * @description Adding six(6) business hours or 5 Business Days to ReExecution DateTime field based Status.
    * @description Timebased Workflow will be triggerred based on reexecution date; 
    * @author rajesh.punjabi@mav3rik.com | 7/26/2019
    * @param List<Callback_Request__c> cbReqList
    * @return void
    */
    public static void ValidateAndScheduleCallbackRequest(List<Callback_Request__c> cbReqList){
        try{
            Id recordTypeIdCallbackRequest = Utility.getRecordTypesAsIdByDevName('Callback_Request__c', 'SSSW_Callback_Request');
            //.. @decription: requrying to fetch additional fields.
            List<Callback_Request__c> cbRequestList = [SELECT Id, Status__c, CaseId__c, CaseBusinessHoursId__c, LastModifiedDate 
                                                    FROM Callback_Request__c 
                                                    WHERE RecordTypeId =: recordTypeIdCallbackRequest AND Id IN: (new Map<Id,SObject>(cbReqList)).keySet()];
            
            List<Callback_Request__c> cbReqListToUpdate = new List<Callback_Request__c>();

            //.. Get Custom Metadata for Callback Settings.
                Callback_Request_Settings__mdt callbackMdt = [SELECT Initial_SLA_in_Hours__c,Second_SLA_in_Hours__c 
                                                            FROM Callback_Request_Settings__mdt 
                                                            WHERE QualifiedApiName = 'Callback_Request_Settings'];
            
            //.. @description: Check if record has been previous modified using RecursionUtility. Process only unprocessed records;
            for(Callback_Request__c cbReqRec : (List<Callback_Request__c>) RecursionUtility.getUnprocessedRecords('CBReq_Status_Changed', cbRequestList, new Set<String>{'Status__c'})) {
                //.. @description: Add 5 business days; case un-resolved.
                if (cbReqRec.Status__c == SSSWConstants.CALLBACK_REQUEST_STATUS_CASE_UNRESOLVED){
                    DateTime FiveDaysSLADateTime = BusinessHours.add(cbReqRec.CaseBusinessHoursId__c , cbReqRec.LastModifiedDate, (Double.valueOf(callbackMdt.Initial_SLA_in_Hours__c) / SSSWConstants.SLA_HOURS_TO_MS_UNIT).longValue());
                    cbReqListToUpdate.Add(new Callback_Request__c(Id=cbReqRec.Id, ReExecutionDateTime__c=FiveDaysSLADateTime));
                }
                //.. @description: Add 6 business hours; customer didnot attended the call (voicemail or no-voicemail).
                else if(cbReqRec.Status__c == SSSWConstants.CALLBACK_REQUEST_STATUS_VOICEMAIL || cbReqRec.Status__c == SSSWConstants.CALLBACK_REQUEST_STATUS_NO_VOICEMAIL){
                    DateTime SixHoursSLA = BusinessHours.add(cbReqRec.CaseBusinessHoursId__c, cbReqRec.LastModifiedDate, (Double.valueOf(callbackMdt.Second_SLA_in_Hours__c) / SSSWConstants.SLA_HOURS_TO_MS_UNIT).longValue());
                    cbReqListToUpdate.Add(new Callback_Request__c(Id=cbReqRec.Id, ReExecutionDateTime__c=SixHoursSLA));
                }
            }
            //.. @description: Update re-execution datetime field if list contains the records.
            if(cbReqListToUpdate.size()>0){
                update cbReqListToUpdate;
            }
        }
        catch(Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 'CallbackRequest', 'NA', 'NA', LoggingLevel.ERROR);
        }           
    }
    
    /**
    * @description Add feed item when status changes for callback request.
    * @author rajesh.punjabi@mav3rik.com | 7/26/2019
    * @param List<Callback_Request__c> cbReqList
    * @return void
    */
    public static void addFeedItem(List<Callback_Request__c> cbReqList){
        List<FeedItem> lstFeedItem = new List<FeedItem>();

        for(Callback_Request__c cbr : (List<Callback_Request__c>) RecursionUtility.getUnprocessedRecords('CBReq_Status_Change_FeedItem', cbReqList, new Set<String>{'Status__c'})) {
            if(cbr.Status__c != SSSWConstants.CALLBACK_REQUEST_STATUS_NEW){
                lstFeedItem.add(new FeedItem(Type = 'TextPost',ParentId = cbr.CaseId__c,Title = 'Callback',Body = 'Callback status changed to ' + cbr.Status__c + ', by user - ' + UserInfo.getUserName()));
            }
        }
        if(lstFeedItem.size()>0){
            insert lstFeedItem;
        }
    }

     /**
    * @description route callback reminder to agent if online, otherwise assigned to queue.
    * @author rajesh.punjabi@mav3rik.com | 7/30/2019
    * @param List<Callback_Request__c> cbRemindersLst
    * @return void
    */
    public static void routeCallbackReminder(List<Callback_Request__c> cbRemindersLstOld, List<Callback_Request__c> cbRemindersLst){
        try{
           	Set<Id> setCBROldIds = new Set<Id>();
            for(Callback_Request__c cbrOld: cbRemindersLstOld){
                if(cbrOld.Status__c == 'New'){
					setCBROldIds.add(cbrOld.Id);    
                }
            }
            Map<Id, Id> mapCallbackOwnerIds = new Map<Id,Id>(); 
            List<Callback_Request__c> lstCallbackReminder = new List<Callback_Request__c>();

            Id recordTypeIdCallbackReminder = Utility.getRecordTypesAsIdByDevName('Callback_Request__c', 'SSSW_Callback_Reminder');

            //.. check for specific record type ids (callback reminder)
            for(Callback_Request__c oCBR: cbRemindersLst){
                if(oCBR.RecordTypeId == recordTypeIdCallbackReminder){
                    lstCallbackReminder.add(oCBR);
                }
            }
            
            //.. check if status fields is updated to avoid recurssion.
            for(Callback_Request__c cbReqRec : (List<Callback_Request__c>) RecursionUtility.getUnprocessedRecords('CBReminder_Status_Changed', lstCallbackReminder, new Set<String>{'Status__c'})) {
                if(cbReqRec.Status__c =='Assigned' && setCBROldIds.contains(cbReqRec.Id)){
                    mapCallbackOwnerIds.put(cbReqRec.OwnerId, cbReqRec.Id);
                }
            }

            if(!mapCallbackOwnerIds.isEmpty()){
                //.. get list of queues and permsets related to callback reminders.
                Map<String, String> mapQueueType = new Map<String,String>();
                
                for(Callback_Reminder_Settings__mdt oCBRmdt:customMetadata){
                    mapQueueType.put(oCBRmdt.Callback_Reminder_Queue_Name__c, oCBRmdt.Callback_Reminder_Type__c);
                }
                
                //.. get queue ids related to callback reminder.
                List<Group> lstCallbackReminderQueues = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN:mapQueueType.keySet()];
                
                Map<String, Id> mapTypeWithQueueId = new Map<String, Id>();
                
                for(Group grp: lstCallbackReminderQueues){
                    mapTypeWithQueueId.put(mapQueueType.get(grp.DeveloperName), grp.Id);
                }
                
                Id HoldingQueueId = mapTypeWithQueueId.get('HoldingQueue');

                // get list of online users.
                Set<Id> setAvailableUserIds = OmniChannelAPIUitlity.isUserOnline(mapCallbackOwnerIds.keySet());
                
                List<Callback_Request__c> lstAssignCallbacksToAgent = new List<Callback_Request__c> ();
                List<Callback_Request__c> lstAssignCallbacksToQueue = new List<Callback_Request__c> ();

                for(Callback_Request__c oCBR: cbRemindersLst){
                    if(setAvailableUserIds.contains(oCBR.OwnerId) && oCBR.OwnerId==HoldingQueueId){
                        lstAssignCallbacksToAgent.add(new Callback_Request__c(Id=oCBR.Id));
                    }
                    else{
                     	lstAssignCallbacksToQueue.add(new Callback_Request__c(Id=oCBR.Id, OwnerId=mapTypeWithQueueId.get(oCBR.Type__c)));
                    }
                }

                if(lstAssignCallbacksToQueue.size()>0){
                    update lstAssignCallbacksToQueue;   
                }
                
                if(lstAssignCallbacksToAgent.size()>0){
                    OmniChannelService.assignRemindertoAgent(lstAssignCallbacksToAgent);
                }
            }
        }
        catch(Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 'CallbackReminder', 'NA', 'NA', LoggingLevel.ERROR);
        }
    }
    
    //.. Callback reminder changeset
    @testVisible static List<Callback_Reminder_Settings__mdt> customMetadata { 
    get {
        if (customMetadata == null)
            customMetadata = [SELECT Id,Callback_Reminder_Queue_Name__c,Callback_Reminder_Type__c,ShiftStartTime__c,ShiftEndTime__c FROM Callback_Reminder_Settings__mdt]; 
        return customMetadata;
    } set; }
    
    /**
    * @description Validate Due Time is within shift hours.
    * @author rajesh.punjabi@mav3rik.com | 9/23/2019 
    * @param cbRemindersLst 
    * @return void 
    **/
    public static void validateDueDateTimeWithShiftHours(List<Callback_Request__c> cbRemindersLst){
        Id recordTypeIdCallbackReminder = Utility.getRecordTypesAsIdByDevName('Callback_Request__c', 'SSSW_Callback_Reminder');

        //.. get list of queues and permsets related to callback reminders.
        Map<String, Callback_Reminder_Settings__mdt> mapTypeShiftHours = new Map<String, Callback_Reminder_Settings__mdt> ();
        for(Callback_Reminder_Settings__mdt mdtCR: customMetadata){
            mapTypeShiftHours.put(mdtCR.Callback_Reminder_Type__c, mdtCR);
        }

        for(Callback_Request__c oCBR: cbRemindersLst){
            if(oCBR.RecordTypeId == recordTypeIdCallbackReminder){
                Callback_Reminder_Settings__mdt mdtCBR = mapTypeShiftHours.get(oCBR.Type__c);
                
                Time oShiftStartTime = Time.newInstance(Integer.valueOf(mdtCBR.ShiftStartTime__c.split(':')[0]), Integer.valueof(mdtCBR.ShiftStartTime__c.split(':')[1]), 0, 0);
                Time oShiftEndTime = Time.newInstance(Integer.valueOf(mdtCBR.ShiftEndTime__c.split(':')[0]), Integer.valueof(mdtCBR.ShiftEndTime__c.split(':')[1]), 0, 0);
                DateTime dtCurrentDateTime = System.now();
                //.. validate shift hours + time should be not be in past.
             
                if(oCBR.ReExecutionDateTime__c.date() < System.today()){
                    oCBR.addError(System.Label.SSSWCBRPastDateErrorMsg);
                }
                else if(oCBR.ReExecutionDateTime__c.date() == System.today() && oCBR.ReExecutionDateTime__c.time() < dtCurrentDateTime.time()){
                	oCBR.addError(System.Label.SSSWCBRPastDateErrorMsg);    
                }
                else if(oCBR.ReExecutionDateTime__c.time() > oShiftEndTime || oCBR.ReExecutionDateTime__c.time() < oShiftStartTime){
                     oCBR.addError(System.Label.SSSWCBRShiftHoursErrorMsg);
                }  
            }
        }
    }
}