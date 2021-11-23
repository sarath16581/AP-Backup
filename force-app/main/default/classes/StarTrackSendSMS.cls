/**
 ** Description: Sending StarTrack SMS
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: FEB.4.2016
 ** History:--------------------------------------------
 **         FEB.4.2016 David Catindoy - Created
 **/
public class StarTrackSendSMS {

    @InvocableMethod
    public static void sendStarTrackSMS(List<Id> taskIds){
        
        List<Task> taskList = [SELECT Id, RecordTypeId, Case_Phone__c, SMSMessage__c, SMSError__c, SMSDateSent__c FROM Task WHERE Id IN :taskIds];
        ActivityUtil.sendSMSForStarTrackTasks(taskList);
        
    }
}