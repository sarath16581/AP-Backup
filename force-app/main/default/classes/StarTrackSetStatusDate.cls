/*------------------------------------------------------------
Author:        David Catindoy
Company:       Cloud Sherpas
Description:   Class for used by StarTrack Calculate Task Status Duration (Process)
Test Class:    StarTrackSetStatusDate_Test
History
June 1, 2016 - David Catindoy - Created
------------------------------------------------------------*/

public without sharing class StarTrackSetStatusDate {

    @InvocableMethod
    public static void setStatusDate(List<Id> taskIdList){
    	List<Task> taskList = [SELECT Id, Status, WhatId, Waiting_for_Operations_Date__c, Acknowledged_Date__c, CreatedDate, Finished_Date__c, 
    		Operations_to_Acknowledged_Time__c, Operations_to_Finished_Time__c, Create_to_Finished_Time__c FROM Task WHERE Id IN :taskIdList];
        StarTrackUtil.setStatusDate(taskList);
    }
}