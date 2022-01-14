/**************************************************
Description:    Trigger Class for Email Message
History:
--------------------------------------------------
5/9/2016  eric.shen@auspost.com.au  add methods to parse email body for snap it case
2018-07-10  nathan.franklin@auspost.com.au  Renamed checkNPS to setEmailToCaseAddress as it's a more meaningful name
2019-02-22  nathan.franklin@auspost.com.au  Added CaseActivity__c integration for first response SLA reporting
**************************************************/
/**
  * @author       : 
  * @date         : 
  * @description  : Trigger Class for Email Message
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    5/9/2016          eric.shen@auspost.com.au             add methods to parse email body for snap it case
    Date                User                                        Comments
    30/11/2021          ashapriya.gadi@auspost.com.au      Added a call to ServiceAdvisorEmailMessageTriggerHandler as part of SMWD-312 - MW0004779
    
*******************************  History ************************************************/

trigger EmailMessageTrigger on EmailMessage (after insert,before insert, after update, before update) 
{
    system.debug('####################################### Email Message trigger: ' + SystemSettings__c.getInstance().Disable_Triggers__c + '#######################################');
    
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) 
    {   
        if(trigger.isInsert){
            
            if(trigger.isBefore){    
                system.debug('####################################### Email Message isInsert & isBefore #####################################');
                
                //Removing Cloning of Cases - change to not allow networks to reopen closed cases.
                //EmailMessageUtil.clonePermanentlyClosedCases(Trigger.new);
                
                EmailMessageUtil.switchInboundToOutbound(Trigger.new);
                EmailMessageUtil.detectPermanentSpam(Trigger.new);
                EmailMessageUtil.startrackDuplicateInboundEmail(Trigger.new); //StarTrack method to check for inbound email duplication.
                EmailMessageUtil.processVOCIncidentEmails(Trigger.new); //StarTrack method to handle inbound emails for VOC incident.
            }
            
            if(trigger.isAfter){
                system.debug('####################################### Email Message isInsert & isAfter #####################################');
                
                EmailMessageUtil.detectSpamEmailOnCases(Trigger.new);

                // when an email is received from email to case, this is used to set the email-to-case address on the parent case record
                EmailMessageUtil.setEmailToCaseAddress(Trigger.newMap);

                //5-9-16 Eric Shen add parseEmailbodySnapIt 
                EmailMessageUtil.parseEmailbodySnapIt(Trigger.new);

                // Given agent sends email to the customer (via Send Email action in case record)
                // And cases are under customer centre
                // Then create CaseActivity record for SLA Reporting
                SLAReportingUtility.generateCaseActivity(trigger.new);
                // SMWD-312 - MW0004779 - This will kick off the newly created ServiceAdvisorEmailMessageTriggerHandler.
                new EmailMessageTriggerHandler().dispatch();

            }
        }

        if(trigger.isUpdate){
            if(trigger.isBefore){
                system.debug('####################################### Email Message isUpdate & isBefore #####################################');
                
            }
            
            if(trigger.isAfter){
                system.debug('####################################### Email Message isUpdate & isAfter #####################################');
                
            }
        } 
    }
}