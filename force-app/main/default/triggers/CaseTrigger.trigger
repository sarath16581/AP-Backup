/**************************************************
Type:       Trigger for Case Object
Purpose:    Update an OPC field when a Case is initiated from the OPC detail page 
History:
--------------------------------------------------
27.09.2012  M. Isidro (Cloud Sherpas)   Created
01.09.2015  Eric Shen (AusPost)   add line 21 to open status tracking for USQ case type
2018-07-12  nathan.franklin@auspost.com.au  commented out
**************************************************/

trigger CaseTrigger on Case (after insert,before insert, after update, before update) {
//    //added by shengpeng.xiao@bluewolf.com at 2014.6.19 begin
//    //when run the test class that not test this trigger, prevent run this trigger to avoid Too many SOQL queries: 101 limits
//    if(TestDataProvider.preventTrigger) return;
//    //added by shengpeng.xiao@bluewolf.com at 2014.6.19 end
//
//    system.debug('####################################### case trigger: ' + SystemSettings__c.getInstance().Disable_Triggers__c + '#######################################');
//
//    if (!SystemSettings__c.getInstance().Disable_Triggers__c)
//    {
//        Set<Id> validRecordTypes = CaseUtility.getRecordTypesWithDevNameContainsIncludingDirectEmail('SSSW');
//        validRecordTypes.addAll(CaseUtility.getRecordTypesWithDevNameContains('User_Support')); // 01-Sep-15 Eric Shen   open case trigger for USQ case status tracking
//
//        Map<Id, Case> newMap = new Map<Id, Case>();
//        List<Case> newCases = new List<Case>();
//        for(Case c: trigger.new){
//            if(c.RecordTypeId != null && validRecordTypes.contains(c.recordTypeId)){
//                newCases.add(c);
//                newMap.put(c.Id, c);
//            }
//        }
//
//        if(trigger.isInsert){
//
//            if(trigger.isBefore){
//
//                system.debug('####################################### isInsert & isBefore #####################################');
//                CaseUtility.assignContactIDToCase(newCases);
//                CaseUtility.validateCase(newCases);
//                CaseOpportunityUtil.updateOpportunityDriver(trigger.new);
//
//                CaseTrackingUtility.setLastStatusChange(newCases);
//                CaseUtility.assignFacilityToCase(newCases, true);
//                CaseUtility.assignCharterTarget(newCases);
//
//                CaseMileStoneUtil.insertMilestones(newCases);
//
//                CaseUtility.detectPermanentSpam(newCases);
//
//
//            }
//
//            if(trigger.isAfter){
//                system.debug('####################################### isInsert & isAfter #####################################');
//
//                //Passing Map to Sales Ops Case Utility for Processing Case Status Tracking.
//                CaseTrackingUtility.insertCaseStatusTracking(newMap);
//
//                CaseOpportunityUtil.updateOPCUnderReviewBySalesManagerFlag(trigger.new);
//
//                //Check if Case Contact has Authorised Contact for all Cases.
//                CaseContactUtil.CopyAuthorisedContacts(newMap);
//
//                CaseMileStoneUtil.setCharterMilestones(newCases);
//
//                CaseUtilityWithoutSharing.createSignatureAttachmentsAfterInsert(newMap);
//
//                CaseUtility.linkCaseToArticles(newMap);
//
//                CaseUtility.closeChildCases(newMap);
//            }
//        }
//
//        if(trigger.isUpdate){
//            if(trigger.isBefore){
//                system.debug('####################################### isUpdate & isBefore #####################################');
//                CaseUtility.setOwnerToCurrentUser(newMap, trigger.oldMap);
//
//                CaseUtility.validateCase(newMap);
//                //Passing Map to Sales Ops Case Utility for setting Case fields - Account and Status.
//                CaseChildQueueManagement.updateParentCase(newMap);
//
//                CaseUtility.assignFacilityToCase(newCases, false);
//                CaseUtility.assignCharterTarget(newCases);
//
//                CaseTrackingUtility.setStatusTracking(newMap, trigger.oldMap);
//
//                CaseMilestoneUtil.updateMilestones(newMap, trigger.oldMap);
//
//                CaseUtility.avoidCustomerClose(Trigger.newMap, Trigger.oldMap);
//
//                CaseUtility.setNPSScheduleDate(Trigger.newMap, Trigger.oldMap);
//
//                CaseUtility.avoidUserToUserOwnerChangeFromFillInbox(Trigger.newMap, Trigger.oldMap);
//
//            }
//
//            if(trigger.isAfter){
//                system.debug('####################################### isUpdate & isAfter #####################################');
//
//                SSSWFaxUtility.deleteCaseForFax(newCases);
//                CaseUtility.setArticlesSubscribed(newMap, trigger.oldMap);
//
//                CaseUtilityWithoutSharing.createSignatureAttachmentsAfterUpdate(newMap, trigger.oldMap);
//
//                CaseTrackingUtility.updateCaseStatusTracking(trigger.oldMap, newMap);
//
//                //New Customer Teir Updates
//                CaseMileStoneUtil.setCharterMilestones(newCases);
//
//                CaseUtility.checkOriginChangeForNPS(newMap, Trigger.oldMap);
//
//                CaseUtility.closeChildCases(newMap, Trigger.oldMap);
//            }
//        }
//    }
    
}