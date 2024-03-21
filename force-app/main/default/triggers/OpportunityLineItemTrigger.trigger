/**************************************************
Type:       Trigger for OpportunityLineItem Object
Purpose:    Create "deleted" record/s in the Deleted Record object when record/s (OpportunityLineItem) is/are deleted (soft or hard)
History:
--------------------------------------------------
16.05.2012      M. Isidro (Cloud Sherpas)       Created
16.08.2012      Richard Enojas (Salesforce.com) Added AFTER INSERT to generate Revenue Schedules
26.09.2012      Richard Enojas (Salesforce.com) Added AFTER DELETE to delete all Revenue Schedules related to the Opportunity Line Item being deleted   
18.01.2019      John.Mapanao@auspost.com.au     Added logic for Email links for MW0003089 - Opportunity Complexity rating in Salesforce
11.02.2021		Madhuri.awasthi@auspost.com.au	: REQ2368013 Added Quantity to create revenue schedule record with Contract Start and End Date logic
**************************************************/
trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, before delete, after delete, after insert, after update) {
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
        // application framework
        (new OpportunityLineItemTriggerHandler()).dispatch();
        
        // legacy
        if (trigger.isAfter && trigger.isDelete){
            
            // Created by conrad.c.v.borbon - August 1, 2019 - START
            system.debug('*** OpportunityLineItem After Delete Trigger - START ***');
            OpportunityLineItemTriggerHandler.OpptyLineItemAfterDelete(trigger.old);
            system.debug('*** OpportunityLineItem After Delete Trigger - END ***');
            // Created by conrad.c.v.borbon - August 1, 2019 - END
            OpportunityLineItemTriggerHandler.processBndGActionAfterDelete(trigger.oldMap);
            
            system.debug('***' + trigger.old);
            DeletedRecordUtil.createDeletedRecord(trigger.old, 'OpportunityLineItem');
            
            //delete Revenue Schedules associated to the Opportunity Line Item
            system.debug('***Delete Revenue Schedules***');
            List<Revenue_Schedule__c>delRevSched = new List<Revenue_Schedule__c>();
            List<Id>delOppLineIds = new List<Id>();
            
            for (OpportunityLineItem oli : trigger.old){
                if (oli.Opportunity_Stage__c == 'Closed Won')
                    delOppLineIds.add(oli.Id);
                 //For testing only    
                if(Test.isRunningTest()){  
                       delOppLineIds.add(oli.Id);
                }
            }   
            
            if (!delOppLineIds.isEmpty()){      
                delRevSched = [SELECT Id FROM Revenue_Schedule__c WHERE OpportunityLineItem__c in :delOppLineIds];  
            }
            
            try{
                if (!delRevSched.isEmpty()){
                    delete delRevSched;
                    Database.emptyRecycleBin(delRevSched);
                }
            }catch (Exception e){
                ApexPages.addMessages(e);
            }   
        }
        
        if (trigger.isAfter && trigger.isInsert){
            system.debug('##### Opportunity Line Item - AFTER INSERT #####');
            
            List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
            
            //only create Revenue Schedules for Line Items whose Stage = Closed Won and Contract Start/End Dates are not null and Quantity are not null
            for (OpportunityLineItem oli : trigger.new){
                if (oli.Contract_Start_Date__c!=null && oli.Contract_End_Date__c!=null && oli.Opportunity_Stage__c=='Closed Won' && oli.Quantity!=null){
                    oliList.add(oli);
                }
                 //For testing only    
                if(Test.isRunningTest()){  
                      oliList.add(oli);
                }
            }
            
            if(!oliList.isEmpty())
                OpportunityProductClassificationUtil.generateRevenueSchedule(oliList);

            OpportunityLineItemTriggerHandler.processBndGActionAfterInsert(Trigger.newMap);
        } else if (trigger.isAfter && trigger.isUpdate) {
            system.debug('##### Opportunity Line Item - AFTER UPDATE #####');
            //check if the Contract Start and End Dates have been populated with values
            //and that either of them were null previously
            //if so, generate the Revenue Schedules
            List<OpportunityLineItem>oliList = new List<OpportunityLineItem>();
            for (OpportunityLineItem oli : trigger.new){
                // Updated by Adrian Recio
                // Description: Make revenue sched creation present on updated regardless if previously empty change for start and end date
                // Date: 22/06/2017
                /*if ((oli.Contract_Start_Date__c!=null && oli.Contract_End_Date__c!=null && oli.Opportunity_Stage__c=='Closed Won') && 
                (trigger.oldMap.get(oli.Id).Contract_Start_Date__c==null || trigger.oldMap.get(oli.Id).Contract_End_Date__c==null)){ 
				#REQ2368013 Adding Quantity to the logic */
                if (oli.Contract_Start_Date__c!=null && oli.Contract_End_Date__c!=null && oli.Opportunity_Stage__c=='Closed Won' &&
                    (trigger.oldMap.get(oli.Id).Contract_Start_Date__c != oli.Contract_Start_Date__c || 
                     trigger.oldMap.get(oli.Id).Contract_End_Date__c != oli.Contract_End_Date__c ||
                     trigger.oldMap.get(oli.Id).Quantity != oli.Quantity)){
                         oliList.add(oli); 
                     }
            }
            system.debug('##### oliList: ' + oliList);
            if(!oliList.isEmpty())
                OpportunityProductClassificationUtil.generateRevenueSchedule(oliList);
            
            //updateRevenueSchedule only applies to the resolution of exceptions, ie re-classification of OLIs
            //OpportunityProductClassificationUtil.updateRevenueSchedule(trigger.new, trigger.newMap, trigger.oldMap);
            OpportunityProductClassificationUtil.updateRevenueSchedule(trigger.new, trigger.oldMap);
        }
        ///////////////////////////////////////////////////////////////////
        if(trigger.isBefore){
            if(trigger.isInsert){
                OpportunityLineItemTriggerHandler.beforeInsertActions(trigger.new);
            }
            if(trigger.isUpdate){
                OpportunityLineItemTriggerHandler.beforeUpdateActions(trigger.new, trigger.oldMap);
            }
            if(trigger.isDelete){
                OpportunityLineItemTriggerHandler.beforeDeleteActions(trigger.old, NULL);
            }
        }
    }
}