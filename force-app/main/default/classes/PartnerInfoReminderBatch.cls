/**************************************************
Type:       Batch Class on Partner Addendum Object
Purpose:    Send Reminders to Customers on Licence Expiries
Used By:    
History:
--------------------------------------------------
07.08.2015  Ritika Dhandia (Salesforce.com)     Created
**************************************************/
global with sharing class PartnerInfoReminderBatch implements Database.Batchable<sObject>{
    
    public static final string STATUS_CEASED = 'Ceased';
    public static final string STATUS_FIRST_REMINDER_SENT = 'First Reminder Sent';
    public static final string STATUS_SECOND_REMINDER_SENT = 'Second Reminder Sent';
    public static final string STATUS_FINAL_REMINDER_SENT = 'Final Reminder Sent';
    public static final string NEGOTIATED_PAYMENT_REC_TYPE = 'Negotiated_Payment%';

    // Fetch all relevant Partner Addednums for reminder emails
    global Database.QueryLocator start(Database.BatchableContext bc) {
    
        Partner_Info_Settings__c setting = Partner_Info_Settings__c.getInstance();
        integer days = Integer.valueOf(setting.First_Reminder_Days__c);
        return Database.getQueryLocator([
                                            SELECT id, Licence__c,Licence__r.Licence_Anniversary__c, End_Date__c,
                                                   Licence__r.Facility__r.WCIS_Code__c, Licence__r.Email__c
                                            FROM Partner_Addendum__c
                                            WHERE Renewal_Status__c != : STATUS_CEASED
                                            AND RecordType.DeveloperName like : NEGOTIATED_PAYMENT_REC_TYPE
                                            AND Licence__c != null
                                            AND Licence__r.Licence_Anniversary__c <= : Date.today().addDays(days)
                                            ORDER BY Licence__r.Licence_Anniversary__c
                                        ]);
    
    }
    
    // Renewal Status is updated on Partner Addendums
    // Approval Status is updated on Accounts
    // Email List updated on Account, if changed, from Custom Settings
    // Workflow triggered, which sends respective Emails
    global void execute(Database.BatchableContext BC, list<Partner_Addendum__c> addendums){
    
        // Find the Email Address from Custom Setting
        Partner_Info_Settings__c setting = Partner_Info_Settings__c.getInstance();
        
        Map<Id,Partner_Addendum__c> addendumsToUpdate = new Map<Id,Partner_Addendum__c>();
        
        // Group All Partner Addendums by Reminder Frequency and Accounts
        map<id, Account> accountsToUpdate = new map<id, Account>();
        
        for(Partner_Addendum__c addendum : addendums){
            
            // Additionally check if Partner Addendum End Date matchies the Licence Anniversary
            // Do not send reminders if it doesn't match
            if(addendum.End_Date__c == addendum.Licence__r.Licence_Anniversary__c){

                if(!accountsToUpdate.containsKey(addendum.Licence__c)){
                    accountsToUpdate.put(addendum.Licence__c, addendum.Licence__r);
                }
                
                Account licence = accountsToUpdate.get(addendum.Licence__c);
                
                string stateCode = licence.Facility__r.WCIS_Code__c.left(1);
                
                // Verify if Email change is required 
                if(setting.get('Email_List_'+stateCode+'__c') != licence.Email__c){
                    licence.Email__c = String.valueOf(setting.get('Email_List_'+stateCode+'__c'));
                }
                // Set the correct Reminder Status
                system.debug(Date.today().Daysbetween(licence.Licence_Anniversary__c));
                if(Date.today().Daysbetween(licence.Licence_Anniversary__c) > setting.Second_Reminder_Days__c ){
                    // First Reminder
                    licence.Approval_Status__c = STATUS_FIRST_REMINDER_SENT;
                    addendum.Renewal_Status__c = STATUS_FIRST_REMINDER_SENT;
                }
                else if(Date.today().Daysbetween(licence.Licence_Anniversary__c) > setting.Third_Reminder_Days__c){
                    // Second Reminder
                    licence.Approval_Status__c = STATUS_SECOND_REMINDER_SENT;
                    addendum.Renewal_Status__c = STATUS_SECOND_REMINDER_SENT;
                }
                else{
                    // Final Reminder
                    licence.Approval_Status__c = STATUS_FINAL_REMINDER_SENT;
                    addendum.Renewal_Status__c = STATUS_FINAL_REMINDER_SENT;
                }
                
                addendumsToUpdate.put(addendum.Id, addendum);
            }
        }
        
        if(addendumsToUpdate.size()>0){
            update addendumsToUpdate.values();
        }
        
        // The update will fire a workflow to send the email alert
        // Based on the approval status
        update accountsToUpdate.values();
    
    }
    
    // No action needs to be taken on finish
    global void finish(Database.BatchableContext BC){
    }
    
}