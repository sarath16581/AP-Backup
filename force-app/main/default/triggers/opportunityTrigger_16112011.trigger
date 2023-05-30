trigger opportunityTrigger_16112011 on Opportunity (before insert, before update, after insert, after update, after delete, after undelete, before delete) {
/**************************************************
Type:       Trigger for Opportunity Object
Purpose:    For inserts/updates, roll up Opportunity Amount
            to corresponding Account Plan Opportunity Value             
History:
--------------------------------------------------
16.11.2011      Carl Vescovi                    Created - clone of SFDC PS trigger
                                                Added additional processing for adding previous oppty owner to sales team at handover
05.15.2011      M. Isidro (Cloud Sherpas)       Added after delete and after undelete
07.06.2012      Joseph Barrameda                Added before insert and before update to update EmployeeNumber field 
22.06.2012      Joseph Barrameda                Added after insert to assign Sales Representative
25.06.2012      Joseph Barrameda                Added after insert to update Personal Account field
06.08.2012      Richard Enojas (Salesforce.com) Added after insert to generate revenue schedules upon setting stage to 'Closed Won'
15.08.2012      Richard Enojas (Salesforce.com) Added before insert to set Hidden Close Date via code since WF rule is causing issues
16.08.2012      Richard Enojas (Salesforce.com) Added logic to ignore BAU WF update to Modified Contract Start Date
18.01.2019      John.Mapanao@auspost.com.au     Added logic for Email links for MW0003089 - Opportunity Complexity rating in Salesforce
2020-08-02 - Nathan Franklin - Refactored some logic around updateOwnerEmployeeNumber on this extremely dodgy trigger
2021-02-22 - arjun.singh@auspost.com.au - Modified to update Direct Contribution details on closed opportunity owner change
2023-05-04 - Ranjeewa Silva - Added support for domain based trigger dispatch.
**************************************************/

	if(!TriggerHelper.isTriggerDisabled(String.valueOf(Opportunity.sObjectType))){
		// domain based trigger dispatch
		(new OpportunityTriggerHandler()).dispatch();
	}


    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        System.debug('***** BEFORE INSERT/BEFORE UPDATE *****');

        OpportunityUtility_part2.registerOpptyOwner(Trigger.new, Trigger.oldMap);

        // Refactored into OpportunityUtility_part2.registerOpptyOwner
        //OpportunityUtility.updateOwnerEmployeeNumber(Trigger.new, Trigger.oldMap);
    }

/* this is the original trigger content from SFDC PS */
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
        if(trigger.isAfter){
            if(trigger.isInsert || trigger.isUpdate){
                
                system.debug('***** AFTER INSERT/AFTER UPDATE *****');
                
                Set<Id> acctplanIds = new Set<Id>();
                List<Id> closedoppIds = new List<Id>();
                        
                for(Opportunity opp : trigger.new){
                    if (opp.Account_Plan__c!=null){
                        if( (trigger.isInsert) ||
                            (trigger.isUpdate && (opp.Account_Plan__c!=trigger.oldMap.get(opp.Id).Account_Plan__c ||
                                opp.Amount!=trigger.oldMap.get(opp.Id).Amount))){
                            acctplanIds.add(opp.Account_Plan__c);       
                        }
                    }
                    
                    //Phase 2 - Added 03.08.2012. Generate Revenue Schedules when the Opportunity is set to 'Closed Won'.
                    //16.08.2012 - Added extra condition to ignore BAU WF update to Modified Contract Start Date field. 
                    if (opp.IsWon && (trigger.isInsert || (trigger.isUpdate && !trigger.oldMap.get(opp.Id).IsWon &&
                        (opp.Modified_Contract_Start_Date__c==trigger.oldMap.get(opp.Id).Modified_Contract_Start_Date__c)))){                                           
                            closedoppIds.add(opp.Id);
                    }
                }
                if(!acctplanIds.isEmpty())
                    OpportunityUtility.updateAccountPlan(acctplanIds);
                
                //Phase 2
                if(!closedoppIds.isEmpty()){
                    if (!OpportunityProductClassificationUtil.hasCreatedSchedules()) {
                    system.debug('*****closedoppIds: ' + closedoppIds);
                    
                    List<OpportunityLineItem> oliList = [SELECT Id, OpportunityId, PricebookEntryId, TotalPrice, 
                                                                Classification__c, Contract_Start_Date__c, Contract_End_Date__c 
                                                    FROM OpportunityLineItem 
                                                    WHERE OpportunityId in :closedoppIds
                                                    AND Contract_Start_Date__c <> null
                                                    AND Contract_End_Date__c <> null];  
                
                    system.debug('*****oliList: ' + oliList);
                    system.debug('*****generateRevenueSchedule*****');
                    OpportunityProductClassificationUtil.generateRevenueSchedule(oliList);
                    //set static variable to prevent infinite loop
                    OpportunityProductClassificationUtil.setAlreadyCreatedSchedules();
                    }
                }
                
            }
        }
    }
    /* this is the end of the original trigger content from SFDC */
    
    /* this is the extension by CV on 16.11.2011, to insert sales team members on ownership change */
    
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
        if(trigger.isAfter){
            if(trigger.isUpdate){
                
                system.debug('***** AFTER UPDATE *****');
                
                OpportunityUtility_part2.insertSalesTeamMember(trigger.new, trigger.oldMap);
                OpportunityUtility_part2.validateAndUpdateDirectContribution(trigger.new, trigger.oldMap);
                
            }   
        }
    }
    /* end of CV extension */
    
    /* this is the extension by CV for 23.11.2011, to insert sales team members on ownership change */
    
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
        if(trigger.isBefore){
            if(trigger.isUpdate){
                
                system.debug('***** BEFORE UPDATE *****');

                // Added logic for Email links for MW0003089 - Opportunity Complexity rating in Salesforce
                // Eligibility Criteria - business rules
                // Commit to Action
                // >= $3m Opportunity Annualised Value AND multiple ‘Level 2’ product items AND (Answer of “No” to any question in the Complexity Drivers section)
                // Deal Desk
                // < $3m Opportunity Annualised Value AND multiple ‘Level 2’ product items AND (Answer of “No” to any question in the Complexity Drivers section)
                //
                // Values to be displayed in this field:
                // 1. If the deal meets Commit to Action criteria, display - “Please contact B&GCommitToAction mailbox”
                // 2. If the deal meets Deal Desk criteria, display - “Please contact B&GDealDesk mailbox”
                // 3. If neither criteria is met, display - “Not required, see your manager to opt-in”
                OpportunityLineItemTriggerHandler.processBndGActionBeforeUpdate(Trigger.newMap);
            }   
        }
    }
    /* end of 23.11.2011 CV extension */
    
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
        if (trigger.isBefore && trigger.isDelete){
            
            system.debug('***** BEFORE DELETE *****');
            
            system.debug('***trigger.old: ' + trigger.old);
            DeletedRecordUtil.createDeletedRecord(trigger.old, 'Opportunity');  
        }
    
        if (trigger.isAfter && trigger.isUnDelete){
            
            system.debug('***** AFTER UNDELETE *****');
            
            system.debug('***trigger.new: ' + trigger.new);
            DeletedRecordUtil.undeleteDeletedRecord(trigger.new);
        }
            
        if (trigger.isAfter && trigger.isInsert){
            
            system.debug('***** AFTER INSERT *****');
            
            system.debug('***Assign Sales Rep***');
            OpportunityUtility.assignSalesRep(trigger.new);
            //OpportunityUtility.assignOpportunityOwner(trigger.new);
            //OpportunityUtility.updatePersonalAccount(trigger.new);    
        }   
    }

    
     // Added by Apttus Managed Services for case# 00210442
    // --------------------------------------------------Apttus Code Starts---------------------------------------------------
    // ADD1     Jeoffrey Palmero        06/05/2019          Added triggers for User Profile validation
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
        if(trigger.isAfter){
            if(trigger.isUpdate){
                if(APTMS_AvoidRecursion.isFirstRun()){
                    system.debug('***** AFTER UPDATE Apttus Trigger called *****');
                    APTMS_OpportunityHandler.updateRecordTypeOfOPLs(trigger.new, trigger.oldMap);
                }
                OpportunityHandler.afterUpdateAction(trigger.new, trigger.oldMap);
                
            }
        }
        
        if (trigger.isBefore) {
            // Call method to block Closing-Won Opportunities that do not have Opportunity Products
            if (trigger.isUpdate) {
                OpportunityHandler.beforeUpdateAction(trigger.new, trigger.oldMap);
            }
        }   
    }
    // --------------------------------------------------Apttus Code Ends----------------------------------------------------
}