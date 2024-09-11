/**
 * @author	   : nandan.narasappa@auspost.com.au
 * @date		 : 16/06/2015
 * @description  : Handler Class for Case object trigger which includes context-specific methods
					that are automatically called when a trigger is executed.
 * @changelog
 * 16/05/2015 - nandan.narasappa@auspost.com.au - Created
 * 01/08/2016 - nandan.narasappa@auspost.com.au - Bypassed trigger execution for future methods to prevent portal
 *												duplicates potentially for INC0777012.
 * 05/09/2016 - eric.shen@auspost.com.au -  - Add code to update missing item SNAP it case for address information
 * 13/10/2016 - david.e.catindoy@accenture.com -	 Added notificationAutomationModel
 * 1/12/2016 -  david.e.catindoy@accenture.com -	 Added duplicateStarTrackCases to perform auto calculation of case weight based on current case field values.
 * 08/03/2017 - david.e.catindoy@accenture.com -	 Change line 186 to reference the closeRelatedTasksAndWFEmails method in StarTrackUtil class.
 * 14/04/2017 - kalpita.talwadekar@auspost.com.au -  Updated the recurssion checks in methods
 * 12/05/2017 - angelo.p.rivera@auspost.com.au -	 Added invocation of caseUtility.assignContactIDToSnapItCase for Snap It Case before inserting Case
 * 2017-09-26 - nathan.franklin@auspost.com.au -	 Added a sync cases to articles method. This replaces the TIBCODataTranslator linkArticlesToCase method.
 * 2017-10-12 - nathan.franklin@auspost.com.au -	 Removed processSnapitMissingItem since it is no longer needed.
 * 2018-03-14 - nathan.franklin@auspost.com.au -	 Added a flag to prevent the execution of the trigger as a whole for the purposes of manual rollup calculation from StatusTracking
 * 2018-07-10 - nathan.franklin@auspost.com.au -	 Update entry points to NPS case flagging for SSSW
 * 2018-11-01 - nathan.franklin@auspost.com.au -	 Added liveagent link to transcript functionality.
 * 2018-11-08 - dilshan.egodawela@auspost.com.au -   Removed the flag that prevents the execution of the trigger
 * 2019-02-19 - ramtej.juloori@auspost.com.au -	  Added method from SLAReporting utility to insert a case activity on closure of startrack case with FCR
 * 2019-02-23 - nathan.franklin@auspost.com.au -	  Minor refactoring of Calculate Resolution Time and FCR flagging (Moved them out of closeRelatedTasksAndWFEmails)
 * 2019-03-18 - gunith.devasurendra@auspost.com.au - Removed the static variable for routing
 * 2019-03-25 - gnana.muruganantham@auspost.com.au - Added invocation of acicUtility.addCaseTeamMemberForACICCase to add Case Team Members for ACIC Request Cases
 *													  Added invocation of acicUtility.updateProposalBasedOnACICStatus to update Proposal's ACIC Request Accepted based on Case Status
 *													  Created Utility Class Variable ACICCaseUtility and instance of ACICCaseUtility.
 * 2019-05-02 - rajesh.punjabi@mav3rik.com -		 Added Five days SLA functionality. Refer to 'SLAforCasesService.closeCallbackRequetRelatedToCase'. -  -  -  -  -  -
 * 2019-05-06 - gunith.devasurendra@auspost.com.au - Convert Workflow logic to route Cases when state is 'new'ed
 * 14/05/2019 - gunith.devasurendra@auspost.com.au - Fixed issue where Network Escalation emails don't have email addresses set (INC1370890)
 * 2019-05-08 - seth.p.heang@accenture.com -		 Added invocation of CaseCommonUtility.populateRequestorWithCurrentUser to populate requestor field of 'CAR' case with current user if left empty on case creation
 * 2020-05-03 - Nathan Franklin - Updated call to syncArticlesToCase
 * 2020-08-20 - Nathan Franklin - Deprecated syncArticlesToCase
 * 2020-10-15 - Naseer Abbasi						Modified calls to routeCase(), additional parameter added
 * 2021-10-04 - Nathan Franklin - Deprecated shareUtility.createSignatureAttachments
 * 16.05.2022   SaiSwetha Pingali  Removed snapIt logic as it is no longer required.
 * 2023-05-25 - Nathan Franklin - Refactoring routing code
 * 2024-09-11 - Vasu Gorakati - CSLU-1413 Service Cloud Voice Work Summaries
 */
public with sharing class CaseTriggerHandler{

	// Variables
	private static CaseTriggerHelper helper;	// Helper class variable to call methods based on scenario
	private static CaseSharingUtility shareUtility;	// Helper class variable to call methods based on scenario
	private static CaseCommonUtility caseUtility;	// Helper class variable to call methods based on scenario
	private static CaseMilestoneUtility milestoneUtility;	// Helper class variable to call methods based on scenario
	private static CaseTrackingHelper trackingUtility;	// Helper class variable to call methods based on scenario
	private static CaseOpportunityUtility oppUtility;	// Helper class variable to call methods based on scenario
	private static ACICCaseUtility acicUtility;	 // Utility class variable to call methods on scenario

	//flags to stop recurssion - 12.04.2017 Kalpita
	public static Boolean isBeforeUpdateExecuted = false;	  // flag for status tracking
	public static Boolean isAfterUpdateExecuted = false;	  // flag for status tracking
	/**
	  * @description	   This method is invoked from trigger which in-turn calls the handlers
						   for before and after event.
	  * @param			 NA
	  * @return			Void
	  * @throws			NA
	  */
	public static void execute() {

		// 01/08/2016 - Nandan : Bypassed trigger execution for future methods to prevent portal duplicates potentially.
		if(!System.isFuture()) {
			helper = new CaseTriggerHelper();   // instance of helper class for Case trigger
			shareUtility = new CaseSharingUtility();	// instance of sharing helper class for Case trigger
			caseUtility = new CaseCommonUtility();	// instance of case utility
			milestoneUtility = new CaseMilestoneUtility();	// instance of case milestone utility
			trackingUtility = new CaseTrackingHelper();	// instance of case tracking helper
			oppUtility = new CaseOpportunityUtility();	// instance of case tracking helper
			acicUtility = new ACICCaseUtility();	// instance of ACIC Case Utility
			
			// Check for event type of trigger
			if(Trigger.isBefore) {
				beforeHandler();		// invoke of before handler
			} else if(Trigger.isAfter) {
				afterHandler();		 // invoke of after handler
			}
		}
	}

	/**
	  * @description	   This method is handler for before events invoked by execute method.
						   Method invokes the helper class methods based on the scenario.
	  * @param			 NA
	  * @return			Void
	  * @throws			NA
	  */
	private static void beforeHandler() {
		// Check for type of operation
		if(Trigger.isInsert) {

			// Methods to be invoked for before insert event
			caseUtility.assignContactIDToCase(Trigger.new); // links contact to case based on the email & other details
			caseUtility.validateCase(Trigger.new);  // assigns case locality to international & checks for duplicate for BSP & DDC
			oppUtility.updateOpportunityDriver(Trigger.new);	// sets opportunity driver for case to opportunity owner
			trackingUtility.setLastStatusChange(Trigger.new);   // set default values for last status change
			CaseRoutingService.getInstance().routeCase(Trigger.new, null, true);   // route the case based on the SSSW routing or default mapping
			milestoneUtility.insertMilestones(Trigger.new);	 // link case to Entitlement to trigger milestones & set escalation if assigned to agent
			caseUtility.detectPermanentSpam(Trigger.new);   // checks if incoming case is from spam email and sets prevent email
			caseUtility.updateHierarchyManager(Trigger.new); //Update Manager Hierarchy
			caseUtility.populateRequestorWithCurrentUser(Trigger.new); // checks if 'CAR' case requestor field is empty, then populate current user as the requestor

		} else if(Trigger.isUpdate) {

			// Methods to be invoked for before update event
			if(!CaseCommonUtility.isXferCaseRecursive) {
				caseUtility.setOwnerToCurrentUser(Trigger.new,(Map<Id,Case>)Trigger.oldMap); // transfers case to current user if status is on hold
			}

			if(!CaseCommonUtility.isCaseValidated || !CaseCommonUtility.isCaseLocalitySet) {
				caseUtility.validateCase_Update(Trigger.new);  // assigns case locality to international & update key for duplicate (BSP & DDC Profiles)
			}

			if(!CaseTriggerHelper.isUpdateParentCaseRecursive) { 
				helper.updateParentCase((Map<Id,Case>)Trigger.newMap);// reallocates parent case when child case is set for queue allocation
			}

			CaseRoutingService.getInstance().routeCase(Trigger.new, (Map<Id,Case>)Trigger.oldMap, false);   // route the case based on the SSSW routing or default mapping

			if(!CaseTrackingHelper.isSetStatusTrackRecursive) {
				trackingUtility.setStatusTracking(Trigger.new,(Map<Id,Case>)Trigger.oldMap);// calculates time spent with support & customer for case
			}

			milestoneUtility.updateNetworkEscalationEmails(Trigger.new,(Map<Id,Case>)Trigger.oldMap);

			if(!CaseMilestoneUtility.isMilestoneUpdated) { //NOTE: this recursion check will prevent updateMilestones to be called during Workflow Case DML when a Case is a HLC or CR. CaseTriggerHelper.updateHLC() will fire a Case DML and flag isMilestoneUpdated to true
				milestoneUtility.updateMilestones(Trigger.new,(Map<Id,Case>)Trigger.oldMap); // creates activity for milestone violation, updates the escalation tier in status tracking
			}

			if(!NPSSurveyUtil.isCheckNPSOrigin) {
				// check to see if NPS date should be applied to this case
				// this will pass the case through the NPS rules engine
				// only do this for SSSW cases
				NPSSurveyUtil.maybeFlagNPS(Trigger.new, (Map<Id, Case>)Trigger.oldMap, 'SSSW');
			}

			if(!CaseTriggerHelper.isUpdateHLCRecursive) {
				helper.updateHLC(Trigger.new,(Map<Id,Case>)Trigger.oldMap); // update IsHLC & IsCR based on the case assignment
			}

			if(!CaseCommonUtility.isCustCloseRecursive) {
				caseUtility.avoidCustomerClose(Trigger.new,(Map<Id,Case>)Trigger.oldMap); // prevent auto close of case for Damaged enquiry sub type if violates customer milestone
			}

			// In StarTrack, in certain situations the FCR (First Call Resolution) flag should be to true.
			// Generally this occurs when cases are resolved with little contact to the contact centre
			StarTrackUtil.processFCRFlag((List<Case>)Trigger.new, (Map<Id, Case>)Trigger.oldMap);

			helper.updateSentToNetworkDate((List<Case>)Trigger.new, (Map<Id, Case>)Trigger.oldMap);

			helper.setValuesforUnifiedCases((List<Case>)Trigger.new, (Map<Id, Case>)Trigger.oldMap);

			isBeforeUpdateExecuted = true;

		}
		else if(Trigger.isDelete) {
			// Methods to be invoked for before update event
		}
	}

	/**
	  * @description	   This method is handler for after events invoked by execute method.
						   Method invokes the helper class methods based on the scenario.
	  * @param			 NA
	  * @return			Void
	  * @throws			NA
	  */
	private static void afterHandler() {
		// Check for type of operation
		if(Trigger.isInsert) {
			// Methods to be invoked for after insert event
			trackingUtility.insertCaseStatusTracking(Trigger.new);  // create status tracking record on case creation

			oppUtility.updateOPCUnderReviewBySalesManagerFlag(trigger.new); // sets under review for product classification linked to case

			helper.copyAuthorisedContacts(Trigger.new);				 // creates authorized contacts for case

			helper.updateHLC(Trigger.new,null);				 // update IsHLC & IsCR based on the case assignment

			milestoneUtility.updateSLA(Trigger.new);	// update Target SLA & Customer SLA for case // kapita 11.04.2017 commented as duplicate call in trigger

			shareUtility.handleCaseTeamMembers(Trigger.new,null);   // creates CaseTeamMember when case is assigned to network

			//shareUtility.createSignatureAttachments(Trigger.new,null);   // creates signature attachments

			shareUtility.insertCaseTeamMembersForChildCase((Map<Id, Case>)Trigger.newMap);	// Insert Case Team Member for Child Cases from Metadata

			helper.updateCaseIdonArticle(trigger.new); //update case id on article record for usage in SMS automation for SSSW cases

			// check if a Chat Key of a Live Chat engagement was inserted and check to see if there are any LiveChatTranscript records to link each case to.
			LiveChatTranscriptUtility.linkCreatedCaseToTranscript((Map<Id,Case>)Trigger.newMap);

			//Method from SLAReportingUtility to insert case activity if a startrack case is closed with FCR checked
			SLAReportingUtility.generateCaseActivity((Map<Id, Case>)Trigger.newMap, null);

			//Case creator is added to the CaseTeam so they have access to the Case, after its assigned to Queue
			acicUtility.addCaseTeamMemberForACICCase(Trigger.new);
		}
		else if(Trigger.isUpdate) {

			//.. @description: Close CallbackRequest assocaited with Cases.
			//.. @author: rajesh.punjabi@mav3rik.com
			SLAforCasesService.closeCallbackRequetRelatedToCase(Trigger.new, Trigger.old);

			// Methods to be invoked for after update event
			if(!CaseTriggerHelper.isCompleteMilestonRecursive) {
				helper.completeMilestone(Trigger.new,(Map<Id,Case>)Trigger.oldMap); // complete the milestones for case
			}

			if(!CaseTrackingHelper.isDeleteCaseFaxRecursive) {
				trackingUtility.deleteCaseForFax(Trigger.new);// links fax to parent case & delete child case
			}

			if(!CaseTrackingHelper.isUpdateStatusTrackRecursive) {
				trackingUtility.updateCaseStatusTracking(Trigger.new,(Map<Id,Case>)Trigger.oldMap);// create status tracking for status & owner change, closes open tracking record for case
			}

			if(!CaseMilestoneUtility.isCaseSLASet) {
				milestoneUtility.updateSLA(Trigger.new);	// update Target SLA & Customer SLA for case
			}

			if(!CaseSharingUtility.isHandleTeamMemberRecursive) {
				shareUtility.handleCaseTeamMembers(Trigger.new,(Map<Id,Case>)Trigger.oldMap);   // creates/removes CaseTeamMember when case is assigned to network or removed
			}

			//if(!CaseSharingUtility.isCreateSignatureRecursive) {
			//	shareUtility.createSignatureAttachments(Trigger.new,(Map<Id,Case>)Trigger.oldMap);   // creates signature attachments
			//}

			if(!CaseCommonUtility.isCloseChildCaseRecursive) {
				caseUtility.closeChildCases(Trigger.new,(Map<Id,Case>)Trigger.oldMap);   // closes child cases if parent case is closed
			}
			
			CaseRoutingService.getInstance().updateParentForRouting(Trigger.new,(Map<Id,Case>)Trigger.oldMap); //check child cases and send parent for re-routing

			//StarTrack method to close tasks and Workflow emails after closing Case
			//Call method to close all related tasks and workflow email records when the case was closed/bulk close was triggered in the case.
			StarTrackUtil.closeRelatedTasksAndWFEmails((Map<Id,Case>)Trigger.newMap, (Map<Id,Case>)Trigger.oldMap);

			//StarTrack R4.1 - Call method to perform notification automation.
			if(!CaseCommonUtility.isNotifyAutoRecursive) {
				CaseCommonUtility.notificationAutomationModel((Map<Id,Case>)Trigger.newMap, (Map<Id,Case>)Trigger.oldMap);
				//CaseCommonUtility.isNotifyAutoRecursive = true;
			}
			//StarTrack R4.3 - Call method to delete related contacts of duplicaye cases.
			if(!CaseCommonUtility.isduplicateSTRcursive) {
				CaseCommonUtility.duplicateStarTrackCases((Map<Id,Case>)Trigger.newMap);
				CaseCommonUtility.isduplicateSTRcursive = true;
			}

			// Calculate the StarTrack case resolution time based on business hours
			StarTrackUtil.calculateResolutionTime((List<Case>)Trigger.new, (Map<Id, Case>)Trigger.oldMap);

			// check if a Chat Key of a Live Chat engagement was inserted and check to see if there are any LiveChatTranscript records to link each case to.
			LiveChatTranscriptUtility.linkCreatedCaseToTranscript((Map<Id,Case>)Trigger.newMap, (Map<Id,Case>)Trigger.oldMap);

			//Method from SLAReportingUtility to insert case activity if a startrack case is closed with FCR checked
			SLAReportingUtility.generateCaseActivity((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);

			//To update ACIC Request Approved checkbox on Proposal based on whether the ACIC Case has been Approved or Rejected
			acicUtility.updateProposalBasedOnACICStatus(Trigger.new,(Map<Id,Case>)Trigger.oldMap);

			// 2020-03-24 vcheng: BGS update to send email on Case Closure
			helper.sendClosureEmails((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);

			isAfterUpdateExecuted = true;
		}
		else if(Trigger.isDelete) {
			// Methods to be invoked for after delete event
		}
		else if(Trigger.isUndelete) {
			// Methods to be invoked for after undelete event
		}
	}
}