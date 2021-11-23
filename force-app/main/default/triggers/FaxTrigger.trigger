/**************************************************
Type:       Trigger for Fax__c object.
Purpose:    
History:
-------------------------------------------------- 
16.12.2013  A. Tran (Bluewolf)  Created.
**************************************************/
trigger FaxTrigger on Fax__c (before insert, after insert, before update, after update) 
{
    system.debug('####################################### FaxTrigger trigger: ' + SystemSettings__c.getInstance().Disable_Triggers__c + '#######################################');

    if (!SystemSettings__c.getInstance().Disable_Triggers__c) 
    {       
        if(trigger.isInsert){
            if(trigger.isBefore){               
                system.debug('####################################### FaxTrigger isInsert & isBefore #####################################');
                
                SSSWFaxUtility.createCaseForFax(Trigger.new);
            }
            
            if(trigger.isAfter){
                system.debug('####################################### FaxTrigger isInsert & isAfter #####################################');

                SSSWFaxUtility.generateAttachment(Trigger.newMap.values());

            }
        }

        if(trigger.isUpdate){
            if(trigger.isBefore){
                system.debug('####################################### FaxTrigger isUpdate & isBefore #####################################');
                
                
            }
            
            if(trigger.isAfter){
                system.debug('####################################### FaxTrigger isUpdate & isAfter #####################################');
                
                //Process Status Tracking for Faxes to Occur only for Inbound Faxes
                /**Map<id,Fax__c> inboundFaxes = new Map<id,Fax__c>();
                for(Fax__c fax : Trigger.new)
                {
                    system.debug('FAX details**'+fax.RecordTypeId+fax.RecordType);
                    system.debug(fax.Case__r.IsClosed);
                    if(fax.RecordType.Name == 'Inbound' && !fax.Case__r.IsClosed)
                    {
                        inboundFaxes.put(fax.id,fax);
                    }
                }               
                if(inboundFaxes.size() > 0)
                {
                    SSSWFaxUtility.updateCaseStatusTracking(Trigger.oldMap, inboundFaxes.values()); 
                }**/
                SSSWFaxUtility.updateCaseStatusTracking(Trigger.oldMap, Trigger.newMap.values());
                //End of Status Tracking Update and Checks
            }
        } 
    }
         
}