// created at 2014.7.1 by shengpeng.xiao@bluewolf.com 
// if the Compensation's status changed to Rejected, change it's relate Case owner to the Compensation's last modify user
/** ----------------- HISTORY ----------------- **/
/**
 * [Compensation Form] [DDS-8012]
 * Modified at: 2021.10.13
 * Modified by: Phap Mai (phap.mai@audpost.com.au)
 * Changes:
 * - Added updateCompensationToken on before update
 * - Added sendCompensationEmails on after update
 * Why need changes: Development for H&S compensation form
 * What is changed:
 * - on before update, update compensation token to valid records
 * - on after update, send compensation email & create comment on case about sent out email
 * Note: for compensation that is auto approved after created the update trigger will also be executed thanks to field update action (ref: https://developer.salesforce.com/docs/atlas.en-us.234.0.apexcode.meta/apexcode/apex_triggers_order_of_execution.htm)
 * Modified: Hasantha Liyanage : as a part of the minor work MW0005476 Module concept is introduced only for the newly added changes,  refactor of the existing logic needs to be done
 **/

trigger CompensationTrigger on Compensation__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {


    if(!TriggerHelper.isTriggerDisabled(String.valueOf(Case.sObjectType))){  // verify if triggers are disabled
        (new CompensationTriggerHandler()).dispatch();
    }

    if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            // todo check Compensation__c's status
            // if the status changed to Rejected, go to util logic
            List<Compensation__c> list_newComp = new List<Compensation__c>();
            for(Compensation__c comp : Trigger.new) {
                Compensation__c old_comp = Trigger.oldMap.get(comp.Id);
                if(comp.Case__c != null && comp.Status__c != old_comp.Status__c) {       //comp.Case__c != null && comp.Status__c == 'Rejected' &&
                    list_newComp.add(comp);
                }
            }
            
            CaseCompensationUtil.updateCaseOwnerWhenCompensionRejected(list_newComp);

            // [DDS-8012] : send email after compensation token has been updated, this should not hinder comitting process
            // the send email is put in after update since the email need to use compensation token which is updated in before update
            try {
                CaseCompensationUtil.sendCompensationEmails(Trigger.new, Trigger.oldMap);
            }
            catch (Exception e)
            {
                UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'CHAS_Compensation', 'CaseCompensationUtil', 'sendCompensationEmails', 'CompensationTrigger:AfterUpdate', LoggingLevel.ERROR);
            }
            
        }
    }
    if (Trigger.isBefore && Trigger.isUpdate)
    {
        // [DDS-8012] : update compensation token, this should not hinder comitting process
        try
        {
            CaseCompensationUtil.updateCompensationToken(Trigger.new, Trigger.oldMap);
        }
        catch (Exception e)
        {
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'CHAS_Compensation', 'CaseCompensationUtil', 'sendCompensationEmails', 'CompensationTrigger:BeforeUpdate', LoggingLevel.ERROR);
        }
    }
}