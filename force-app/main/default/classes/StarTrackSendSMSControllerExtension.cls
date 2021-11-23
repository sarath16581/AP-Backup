global with sharing class StarTrackSendSMSControllerExtension {
    public String txtMobile {get;set;}
    public String txtMessage {get;set;}
    public Case caseRecord {get;set;}
    public Boolean validation {get; set;}
    public Integer charCount {get; set;}
    public Integer totalCount {get; set;}
    
    public StarTrackSendSMSControllerExtension(ApexPages.StandardController con){
        caseRecord = [SELECT Id, CaseNumber, Recent_Contact_Mobile_Number__c FROM Case WHERE Id = :con.getRecord().Id limit 1];
        if(caseRecord.Recent_Contact_Mobile_Number__c != null && caseRecord.Recent_Contact_Mobile_Number__c.length() == 10) {
            txtMobile = caseRecord.Recent_Contact_Mobile_Number__c;
        }
        validation = false;
        totalCount = 160 - (StarTrack_Settings__c.getOrgDefaults().StarTrack_SMS_Suffix__c != null ? StarTrack_Settings__c.getOrgDefaults().StarTrack_SMS_Suffix__c.length()+2 : 0);
        charCount = 0;
    }
    
    public void setValidationToTrue(){
        validation = true;
    }

    @RemoteAction
    global static string sendSMS(Id caseId, String caseNumber, String mobileNumber, String message, Integer totalCount){
        String result = '';
        try {
            if(message != null && message.trim().length() > 0 && message.trim().length() <= totalCount && mobileNumber != '' && mobileNumber.length() == 10 && mobileNumber.isNumeric()) {
                Map<String, RecordType> taskRecordTypesByDeveloperName = Util.getRecordTypesByDeveloperName('Task');
                Task aTask = new Task(WhatId = caseId, ActivityDate = Date.today(), Description = message, RecordTypeId = taskRecordTypesByDeveloperName.get('StarTrack_SMS').Id, Subject = 'Outbound SMS (' + (message.trim().length()>=19?message.substring(0, 19):message.substring(0)) + ')', Status = 'In Progress', Interaction_Type__c = 'SMS');
                aTask.SMSMessage__c = message + '\n\n' +(StarTrack_Settings__c.getOrgDefaults().StarTrack_SMS_Suffix__c != null ? StarTrack_Settings__c.getOrgDefaults().StarTrack_SMS_Suffix__c : '');
                aTask.Case_Phone__c = mobileNumber;
                
                insert aTask;
                result = 'Success!';
            } else if(mobileNumber == null || mobileNumber == ''){
                result = 'Error: Mobile Number not specified.';
            } else if(mobileNumber.length() < 10){
                result = 'Error: Invalid Mobile Number.';
            } else if (!mobileNumber.isNumeric()){
                result = 'Error: Invalid Mobile Number.';
            } else {
                result = 'Error: Max number characters allowed is 160';
            }
        } catch(Exception ex){
            result = 'Error: ' + ex.getMessage();
        }
        return result;
    }
}