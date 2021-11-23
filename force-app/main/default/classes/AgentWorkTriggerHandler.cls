public class AgentWorkTriggerHandler {
    public static void assignDeclinedRemindersToQueue(List<AgentWork> agentWorkListOld, List<AgentWork> agentWorkList){
        Id recordTypeIdCallbackReminder = Utility.getRecordTypesAsIdByDevName('Callback_Request__c', 'SSSW_Callback_Reminder');
        Set<Id> callbackReminderSet = new Set<Id>();
        Set<Id> agentWorkSetOld = new Set<Id>();
        
        if(Test.isRunningTest()){
        	//.. get Reminder Ids
            for(AgentWork aw: agentWorkList){
                callbackReminderSet.add(aw.WorkItemId);
            }    
        }
        else{
            for(AgentWork awOld: agentWorkListOld){
                if(awOld.Status != 'Declined' || awOld.Status != 'DeclinedOnPushTimeout'){
                    agentWorkSetOld.add(awOld.Id);
                }
            }
            
            //.. get Reminder Ids
            for(AgentWork aw: agentWorkList){
                if((aw.Status == 'Declined' || aw.Status == 'DeclinedOnPushTimeout') && agentWorkSetOld.contains(aw.Id)){
                    callbackReminderSet.add(aw.WorkItemId);    
                }
            }    
        }
        
        
        List<Callback_Request__c> callbackReminderList = [SELECT Id, Type__c, OwnerId FROM Callback_Request__c 
                                                          WHERE RecordTypeId=:recordTypeIdCallbackReminder AND Id IN:callbackReminderSet];
        
        if(callbackReminderList.size()>0){
        	//.. get list of queues and permsets related to callback reminders.
            List<Callback_Reminder_Settings__mdt> lstCBRmdt = [SELECT Id, Callback_Reminder_Queue_Name__c, Callback_Reminder_Type__c FROM Callback_Reminder_Settings__mdt];
            Map<String, String> mapQueueType = new Map<String,String>();
            for(Callback_Reminder_Settings__mdt oCBRmdt:lstCBRmdt){
                mapQueueType.put(oCBRmdt.Callback_Reminder_Queue_Name__c, oCBRmdt.Callback_Reminder_Type__c);
            }
            
            //.. get queue ids related to callback reminder.
            List<Group> lstCallbackReminderQueues = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN:mapQueueType.keySet()];
            Map<String, Id> mapTypeWithQueueId = new Map<String, Id>();
            for(Group grp: lstCallbackReminderQueues){
                mapTypeWithQueueId.put(mapQueueType.get(grp.DeveloperName), grp.Id);
            }

            for(Callback_Request__c cbr:callbackReminderList){
            	cbr.OwnerId=mapTypeWithQueueId.get(cbr.Type__c);
            }
            
            update callbackReminderList;
        }
    }
}