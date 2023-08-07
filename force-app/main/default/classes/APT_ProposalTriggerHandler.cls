/**
Description: This apex class if handler class for apex trigger - APT_ProposalTrigger.
Created By: Mausam Padhiyar
Created Date: 14th Aug, 2015

Last Modified By: Mausam Padhiyar
Last Modified Date: 27th July, 2016

Last Modified By: Mausam Padhiyar
Last Modified Date: 14th Feb, 2017 | 1834 | remove code for identical lines flag. Moved to create proposal

Last Modified By - Mausam Padhiyar
Last Modified Date - 16th March, 2017 | CR - Kg Rounding

Last Modified By - Adrian Recio
Last Modified Date - 4th December, 2017 | CR - Added error handling for target and revenue without end date.
					Proposal creation will throw an error if target and revenue doesn't exist for renewal contracts.
Last Modified By - Lyndon Lavapie
Last Modified Date - 10th july, 2018 | CR - Added logic to fire the calculation and assignment value for "Revenue Decrease" field in Opportunity
					when Proposal Approval status update to “Accepted"
Last Modified By - Neha Nimran
Last Modified Date - 7th Aug, 2019 | ACIC Auto Case Creation logic Added for Workforce Verification

2020-08-02 - Nathan Franklin - only call createQuoteLP if there are records to process

2020-10-22 - Mathew Jose - Added 'setContractingEntities' method.

Last Modified By - Krishna Velani
Last Modified Date - 6th May, 2021 | STP-5088 Added setOpportunityDriver method to update Proposal Owner

2021-06-05 - Naveen Rajanna - STP-5598/REQ2519238 - Set APT_pricing_fields_changed__c to true if value changed from previous value of not NULL
								on either Primary pickup location(Postcode-Suburb) or Minimum Monthly Spend

2021-06-08 - Seth Heang - STP-5389 Autopopulate Proposal's APT_Method_of_Payment__c from Opportunity's field in Before Insert Trigger

2021-06-09 - Mansi Shah - Added Code to blank out Approval related fields on Approval Rejection/Cancellatio

Last Modified By - Darshan Chauhan
Last Modified Date - 2021-06-15 Darshan Chauhan Removing unessecary code for Approval Rejection

2021-07-14 - Mansi Shah - Added method onBeforeInsert and commented method setOpportunityDriver

2022-05-02 SaiSwetha Pingali REQ2703521 - Added logic to capture role of the user at the time of creation.
Ken McGuire 2023.04.19 Proposal field migration to opportunity
2023-04-27 - Nasir Jawed - added logic on beforeUpdateEvent for the field 'APT_Proposal_Status_Accepted_Denied__c' update on opportunity
*/

public without sharing class APT_ProposalTriggerHandler {

/**
*Before Insert
*CR - KG Rounding
*/

	Public static Boolean blnIsExceptionThrownFromTestClass = False;

	public static String beforeInsertEvent(list<Apttus_Proposal__Proposal__c> listProposal) {

		//KG ROUNDING CODE START
		try
		{
		 //spingali - REQ2703521 - Added logic to capture role of the user at the time of creation.
		 String roleId = Userinfo.getUserRoleId();
		 List<UserRole> RoleList ;
		 if(roleId !=null)
		 {
			 RoleList = [SELECT id, name FROM userrole WHERE Id =: roleId ];
		 }
			Set<ID> accSet = new Set<ID>();
			Map<ID, Apttus_Proposal__Proposal__c> oppToProposalMap = new Map<ID, Apttus_Proposal__Proposal__c>();
			for(Apttus_Proposal__Proposal__c proposal : listProposal) {
				accSet.add(proposal.Apttus_Proposal__Account__c);
				oppToProposalMap.put(proposal.Apttus_Proposal__Opportunity__c, proposal);
			}

			// STP 5389 : Auto-population of Proposal.APT_Method_of_Payment__c from Upstream Opportunity.Type_of_billing_account_required__c if exists
			for(Opportunity opp : [SELECT Id, Type_of_billing_account_required__c FROM Opportunity WHERE Id IN: oppToProposalMap.keySet()]){
				Apttus_Proposal__Proposal__c proposal = oppToProposalMap.get(opp.Id);
				if(opp.Type_of_billing_account_required__c == 'Charge account and sub-account'){
					proposal.APT_Method_of_Payment__c = 'Charge Account + Sub Account';
				}else if(opp.Type_of_billing_account_required__c == 'Charge account'){
					proposal.APT_Method_of_Payment__c = 'Charge Account';
				}
			}

			//.debug('*** accSet ***'+accSet);
			//List<Budget_and_Revenue__c> targetRevList = [select ID, Product__r.ProductCode,Organisation__c from Budget_and_Revenue__c where Organisation__c IN:accSet];
			Map<ID, Boolean> accIDToEparcelCheckMap = new Map<ID, Boolean>();
			Map<Id,Boolean> brHasErrorMap = new Map<Id,Boolean>();

			for(Budget_and_Revenue__c revObj : [select ID, Product__r.ProductCode,Organisation__c, Int_Last_Upd_Date__c
												from Budget_and_Revenue__c
												where Organisation__c IN:accSet]) {
				// Updated by Adrian Recio, Added null check in last update field , 28/11/2017
				if(revObj.Product__r.ProductCode != null &&
				 (revObj.Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) ||
				 revObj.Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)) ){
					if(revObj.Int_Last_Upd_Date__c == null){
						 brHasErrorMap.put(revObj.Organisation__c,true);
					}else if(revObj.Int_Last_Upd_Date__c.monthsBetween(Date.Today()) <= 13) {
						accIDToEparcelCheckMap.put(revObj.Organisation__c, true);
					}
				}
			}

			for(Apttus_Proposal__Proposal__c proposal : listProposal){
				//spingali - REQ2703521 - Added logic to capture role of the user at the time of creation.
				proposal.APT_Creator_Role__c = RoleList?.get(0).Name;
				// Added by Adrian Recio, 4/12/2017, Check if organisation budget and revenue has error
				Boolean hasBRError = brHasErrorMap.get(proposal.Apttus_Proposal__Account__c);
				if(hasBRError == true){
					proposal.addError('Your contract target and revenue is missing.');
				}else{
					if(accIDToEparcelCheckMap.containsKey(proposal.Apttus_Proposal__Account__c) &&
					 accIDToEparcelCheckMap.get(proposal.Apttus_Proposal__Account__c)){
						proposal.APT_Is_Existing_eParcel_Customer__c = 'Yes';
					}else{
						proposal.APT_Is_Existing_eParcel_Customer__c = 'No';
					}
				}
			}
			//Added By Apttus to Cover code of catch block and Trigger Exception
			if(Test.IsRunningTest() && blnIsExceptionThrownFromTestClass){
				integer i = 1/0;
			}

		}
		catch(Exception e)
		{
			return null;
		}
		return APT_Constants.SUCCESS_LABEL;
		//KG ROUNDING CODE END
	}


	/**
		Sync with Opportunity & Create Quote Lodgement point
	 */
	public static String afterUpdateEvent(list<Apttus_Proposal__Proposal__c> listProposal, map<Id, Apttus_Proposal__Proposal__c> mapProposalOld) {

			// Added by Adrian Recio
			// 9/8/2017
			// Repopulate total contract value from proposal to agreement if value changed
			set<Decimal> newSumSet = new set<Decimal>();
			set<Decimal> oldSumSet = new set<Decimal>();

			map<Id, Apttus_Proposal__Proposal__c> apNewAmountMap = new map<Id, Apttus_Proposal__Proposal__c>();

			for(Apttus_Proposal__Proposal__c apVar: listProposal){
				newSumSet.add(apVar.APT_TotalOPLineItemPrice__c);
				Apttus_Proposal__Proposal__c oldMapVar = mapProposalOld.get(apVar.Id);
				oldSumSet.add(oldMapVar.APT_TotalOPLineItemPrice__c);

				if(apVar.APT_TotalOPLineItemPrice__c!=oldMapVar.APT_TotalOPLineItemPrice__c){
					apNewAmountMap.put(apVar.Id, apVar);
				}
			}

			if(apNewAmountMap.keySet().size()>0){
				List<Apttus__APTS_Agreement__c>aCList = [Select Id, Apttus__Total_Contract_Value__c,Apttus_QPComply__RelatedProposalId__c
														 from Apttus__APTS_Agreement__c
														 where Apttus_QPComply__RelatedProposalId__c In :apNewAmountMap.keySet()];
				if(aCList.size()>0){
					for(Apttus__APTS_Agreement__c acVar: aCList){
						acVar.Apttus__Total_Contract_Value__c = apNewAmountMap.get(acVar.Apttus_QPComply__RelatedProposalId__c).APT_TotalOPLineItemPrice__c;
					}

					try{
						update aCList;
					}catch(exception e){
						return null;
					}
				}
			}
			// End of total contract population

			set<Id> syncWithOpportunityProposalIds = new set<Id>();

			set<Id> setPresentedProposalId = new set<Id>();
			set<Apttus_Proposal__Proposal__c> finalizedQuotes = new set<Apttus_Proposal__Proposal__c>();
			set<Id> finalizedIds = new set<Id>();
			set<Id> setOpportunityId = new set<Id>();
			Set<ID> proposalStatusChangedByCreditManagementEmailerList = new Set<ID>();

			try {
				for(Apttus_Proposal__Proposal__c proposal : listProposal) {
					Apttus_Proposal__Proposal__c oldProposal = mapProposalOld.get(proposal.id);

					setOpportunityId.add(proposal.Apttus_Proposal__Opportunity__c);
					//APOST-1524
					if(oldProposal != null && oldProposal.Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_PRESENTED && proposal.Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_PRESENTED) {
						setPresentedProposalId.add(proposal.Id);
					}


					if(proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c !=null && proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != oldProposal.Apttus_QPConfig__ConfigurationFinalizedDate__c){
						finalizedQuotes.add(proposal);
						finalizedIds.add(proposal.Id);
					}

					if(oldProposal != null && oldProposal.APT_Credit_Assessment_Status__c != proposal.APT_Credit_Assessment_Status__c
							&& (((APT_Constants.CREDIT_ASSESSMENT_REFFERED).equalsIgnoreCase(oldProposal.APT_Credit_Assessment_Status__c)
									&&((APT_Constants.APPROVAL_STATUS_REJECTED).equalsIgnoreCase(proposal.APT_Credit_Assessment_Status__c)
										|| (APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED).equalsIgnoreCase(proposal.APT_Credit_Assessment_Status__c))
								) || ((APT_Constants.APPROVAL_STATUS_REJECTED).equalsIgnoreCase(oldProposal.APT_Credit_Assessment_Status__c)
									&&(APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED).equalsIgnoreCase(proposal.APT_Credit_Assessment_Status__c))
									)){

						proposalStatusChangedByCreditManagementEmailerList.add(proposal.id);
					}

					Boolean oldProposalNotNull = oldProposal != null;
					Boolean approvalStageChangedToAccepted = oldProposal.Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_ACCEPTED
																&& proposal.Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_ACCEPTED;

					//approval required
					Boolean approvalStageChangedToApprovalRequired = APT_Constants.PROPOSAL_APPROVAL_STATUS_PENDING_APPROVAL.equalsIgnoreCase(proposal.Apttus_QPApprov__Approval_Status__c);


					//- When ‘Is primary' flag changed from false to true
					Boolean proposalMadePrimary = proposal.Apttus_Proposal__Primary__c && !oldProposal.Apttus_Proposal__Primary__c;

					//- When ‘Estimated Revenue Start Date' or ‘Estimated Revenue End Date' fields are updated before Quote is ‘Accepted'
					Boolean proposalRevenueStartDateChange = proposal.Expected_Revenue_Start_Date__c !=null
									&& oldProposal.Expected_Revenue_Start_Date__c != proposal.Expected_Revenue_Start_Date__c
									&& oldProposal.Expected_Revenue_Start_Date__c != null
									&& proposal.Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_ACCEPTED;

					//- When ‘Estimated Revenue End Date' fields are updated before Quote is ‘Accepted'
					Boolean proposalRevenueEndDateChange = proposal.Expected_Revenue_End_Date__c !=null
									&& oldProposal.Expected_Revenue_End_Date__c != proposal.Expected_Revenue_End_Date__c
									&& oldProposal.Expected_Revenue_End_Date__c != null
									&& proposal.Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_ACCEPTED;

					//- Whenever finalized date field is changed and ‘Is primary' flag equals true
					Boolean finalizedDateChangePrimary = proposal.Apttus_Proposal__Primary__c
						&& String.IsBlank(proposal.Apttus_QPApprov__Approval_Status__c)
						&& oldProposal.Apttus_QPConfig__ConfigurationFinalizedDate__c != proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c;
					//APOST-1524
					if( oldProposalNotNull && proposal.Apttus_Proposal__Primary__c
							&& (approvalStageChangedToAccepted || proposalMadePrimary
								|| proposalRevenueStartDateChange || proposalRevenueEndDateChange
								|| finalizedDateChangePrimary
								|| approvalStageChangedToApprovalRequired)) {

						syncWithOpportunityProposalIds.add(proposal.Id);

					}


				}


				// create Quote Lodgement point from Line item Lodgementpoint on finalization of Product configuration.
				if(!finalizedQuotes.isEmpty()) {
					createQuoteLP(finalizedQuotes);
				}

				//create Line Item Rate Card

				//sync with Opportunity
				/* Shashwat.Nath@Auspost.com has commented this line of code as part of the changes to the Sync Process for SFT Release 2.
				 The Sync process would now be getting Triggered from APT_ConfigurationTrigger */
				//APT_ConfigurationTriggerHandler.sycWithOpportunity(syncWithOpportunityProposalIds);

				/* Shashwat.Nath@Auspost.com commenting ends */

				//APOST-1524
				if(setPresentedProposalId.size() > 0) {
					list<Apttus_Proposal__Proposal_Line_Item__c> listPLI = [SELECT Id, Apttus_Proposal__Proposal__c,
																			Apttus_QPConfig__OptionId__r.APT_Domestic_Pricing__c
																			FROM Apttus_Proposal__Proposal_Line_Item__c
																			WHERE Apttus_Proposal__Proposal__c IN :setPresentedProposalId
																			AND Apttus_QPConfig__OptionId__r.APT_Domestic_Pricing__c = true];

					if(listPLI != null && listPLI.size() > 0) {
						APT_UpdateProposalUsagePriceTierBatch controller = new APT_UpdateProposalUsagePriceTierBatch(setPresentedProposalId);
						database.executeBatch(controller, 1);
					}
				}
			//Added By Apttus to Cover code of catch block and Trigger Exception
			if(Test.IsRunningTest() && blnIsExceptionThrownFromTestClass){
				integer i = 1/0;
			}

				// creating ACIC case for workforce verification when approval stage is accepted
				APT_ProposalCustomUtility.autoCaseCreate('APT_ApttusImplWorkforceVerfication',listProposal,mapProposalOld);


		} catch(Exception e){
				return null;
		}
			return APT_Constants.SUCCESS_LABEL;
	}

	public static final string MAIL_DEAR = 'Dear ';
	public static final string MAIL_BR = '<br/>';
	public static final string MAIL_P = '<p>';
	public static final string MAIL_FULL_STOP = '.';
	public static final string MAIL_HAS_BEEN = ' has been ';
	public static final string MAIL_CLOSE_P = '</p>';
	public static final string MAIL_BOLD = '<b>';
	public static final string CUSTOMER_DETAILS = 'Customer Details:';
	public static final string MAIL_BOLD_CLOSE = '</b>';
	public static final string MAIL_AHREF = '<a href="';
	public static final string MAIL_CLICk_HERE = 'Click on the link below to access the Proposal: ';
	public static final string PROPOSAL_ID = 'Proposal ID: ';
	public static final string OPPORTUNITY_NUMBER = 'Opportunity Number: ';
	public static final string CUSTOMER_NUMBER = 'Customer Number: ';
	public static final string LEGAL_ENTITY_NAME = 'Legal Entity Name: ';


	/**
		This method will update proposals
		@params
		listProposal - list of proposals
	**/
	public static Map<Id,String> beforeUpdateEvent(list<Apttus_Proposal__Proposal__c> listProposal, map<Id, Apttus_Proposal__Proposal__c> mapProposalOld) {
		try {
			//for CR148/13 Start
			// Added by Lyndon Lavapie
			// Fetch the Amendment record Type Id
			List<Apttus_Proposal__Proposal__c> decreaseAmendment = new List<Apttus_Proposal__Proposal__c>();
			Id amendmentRecType = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE).getRecordTypeId();
			//End

			Map<Id,Id> mapProp_Config = new Map<Id,Id>();
			Set<Id> prodConfig=new Set<Id>();
			Map<Id,String> mapQuote_prod = new Map<Id,String>();
			List<Apttus_Config2__LineItem__c> listOfLI = new List<Apttus_Config2__LineItem__c>();
			List<Apttus_Config2__ProductConfiguration__c> prodConfigurationId = new List<Apttus_Config2__ProductConfiguration__c>();
			Set<Id> setPropId = new Set<Id>();
			APT_R2T_System_Properties__c r2tSystemObj = APT_R2T_System_Properties__c.getOrgDefaults();
			list<Opportunity> listOpportunity = new list<Opportunity>();
			set<Opportunity> setOpportunity = new set<Opportunity>();
			List<Opportunity> listOpp;
			Opportunity oppty;
			for(Apttus_Proposal__Proposal__c prop:listProposal){
				setPropId.add(prop.Id);

				//APOST-2007 : populate approval stage
				if(mapProposalOld.get(prop.id) != null && String.isNotBlank(mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c) && String.isBlank(prop.Apttus_Proposal__Approval_Stage__c)) {
					prop.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_DRAFT;
				}
				//APOST-2007 : populate approval stage

				//populate proposal draft date
				if(mapProposalOld.get(prop.id) != null && prop.Apttus_Proposal__Approval_Stage__c != null && mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c != null && False == mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_DRAFT) && true == prop.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_DRAFT)) {
					//prop.APT_Proposal_Draft_Date__c = getLocalDateTime();
					prop.APT_Proposal_Draft_Date__c = system.now();
				}

				//populate proposal approved date
				if(mapProposalOld.get(prop.id) != null && prop.Apttus_Proposal__Approval_Stage__c != null && mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c != null && False == mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_APPROVED) && true == prop.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_APPROVED)) {
					prop.APT_Proposal_Approved_Date__c = system.now();
				}

				//populate proposal rejected date
				if(mapProposalOld.get(prop.id) != null && prop.Apttus_Proposal__Approval_Stage__c != null && mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c != null && False == mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_DENIED) && true == prop.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_DENIED)) {
					prop.APT_Proposal_Rejected_Date__c = system.now();
				}

				//populate proposal Generated date
				if(mapProposalOld.get(prop.id) != null && prop.Apttus_Proposal__Approval_Stage__c != null && mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c != null && False == mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_GENERATED) && true == prop.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_GENERATED)) {
					prop.APT_Proposal_Generated_Date__c = system.now();
				}

				//populate proposal Presented date
				if(mapProposalOld.get(prop.id) != null && prop.Apttus_Proposal__Approval_Stage__c != null && mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c != null && False == mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_PRESENTED) && true == prop.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_PRESENTED)) {
					prop.APT_Proposal_Presented_Date__c = system.now();
				}

				//populate proposal Accepted date
				if(mapProposalOld.get(prop.id) != null && prop.Apttus_Proposal__Approval_Stage__c != null && mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c != null && False == mapProposalOld.get(prop.id).Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED) && true == prop.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED)) {
					prop.APT_Proposal_Accepted_Date__c = system.now();
				}

				//populate default price list id in proposal record
				if(!String.isBlank(r2tSystemObj.APT_Default_Price_List_ID__c))
				{
					prop.Apttus_QPConfig__PriceListId__c = r2tSystemObj.APT_Default_Price_List_ID__c;
				}
				if(null != prop.Apttus_Proposal__Opportunity__c)
				{
					oppty = new Opportunity(ID = prop.Apttus_Proposal__Opportunity__c);
					List<string> proposalStatus = new List<string>{'Accepted','Denied'};
					//This logic is update the boolean field on Opportunity which decides to create a new proposal or redirect to the cart of existing proposal
					if(!proposalStatus.contains(prop.Apttus_Proposal__Approval_Stage__c)){
					oppty.APT_Proposal_Status_Accepted_Denied__c = APT_Constants.BOOL_TRUE;
					setOpportunity.add(oppty);
					}
					if(proposalStatus.contains(prop.Apttus_Proposal__Approval_Stage__c)){
					oppty.APT_Proposal_Status_Accepted_Denied__c = APT_Constants.BOOL_FALSE;
					setOpportunity.add(oppty);
					}
					listOpp = new List<Opportunity>(setOpportunity);

					if( null != prop.Apttus_QPConfig__ConfigurationFinalizedDate__c && null == mapProposalOld.get(prop.ID).Apttus_QPConfig__ConfigurationFinalizedDate__c)
					{
						//CR148/13
						//Added by Lynbdon Lavapie 7/18/2018
						//block the update of Oppty status when creating decrease in revenue
						if(!(prop.recordTypeId == amendmentRecType && prop.APT_Revenue_Type__c == APT_AmendRenewController.DECREASE_REVENUE)){

						/*Shashwat.Nath@Auspost.com commented the below line on 09/09/2020 to stop automated progression of opportunity Stage as per
+ the requirement STP-2806 for release 2*/

						//oppty.StageName = APT_Constants.OPPORTUNITY_STAGE_QUALIFY;

						 /* Shashwat.Nath@Auspost.com code comment ends */

						oppty.Next_Step__c = APT_Constants.OPPORTUNITY_NEXTSTEP_CONFIRM_ISSUES_NEEDS_AND_DESIRED_OUTCOMES;
						}

						//prop.APT_Next_Steps__c = APT_Constants.OPPORTUNITY_NEXTSTEP_CONFIRM_ISSUES_NEEDS_AND_DESIRED_OUTCOMES;
						listOpportunity.add(oppty);
					}
					if(!String.isEmpty(prop.Apttus_Proposal__Approval_Stage__c) && prop.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_GENERATED) && !mapProposalOld.get(prop.ID).Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_GENERATED))
					{
						//CR148/13
						//Added by Daric Dava 7/24/2018
						//block the update of Oppty status when proposal status updated to GENERATED
						if(!(prop.recordTypeId == amendmentRecType && prop.APT_Revenue_Type__c == APT_AmendRenewController.DECREASE_REVENUE)){

						/*Shashwat.Nath@Auspost.com commented the below line on 09/09/2020 to stop automated progression of opportunity Stage as per
+ the requirement STP-2806 for release 2*/

						//oppty.StageName = APT_Constants.OPPORTUNITY_STAGE_PROPOSE;

						/* Shashwat.Nath@Auspost.com code comment ends */
						oppty.Next_Step__c = APT_Constants.OPPORTUNITY_NEXTSTEP_PRESENT_PROPOSAL_TO_CUSTOMER;
						}

						//prop.APT_Next_Steps__c = APT_Constants.OPPORTUNITY_NEXTSTEP_PRESENT_PROPOSAL_TO_CUSTOMER;
						listOpportunity.add(oppty);
					}
					if(!String.isEmpty(prop.Apttus_Proposal__Approval_Stage__c) && prop.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_PRESENTED) && !mapProposalOld.get(prop.ID).Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_PRESENTED))
					{
						//CR148/13
						//Added by Daric Dava 7/24/2018
						//block the update of Oppty status when proposal status updated to PRESENTED
						if(!(prop.recordTypeId == amendmentRecType && prop.APT_Revenue_Type__c == APT_AmendRenewController.DECREASE_REVENUE)){

						/*Shashwat.Nath@Auspost.com commented the below line on 09/09/2020 to stop automated progression of opportunity Stage as per
+ the requirement STP-2806 for release 2*/

						//oppty.StageName = APT_Constants.OPPORTUNITY_STAGE_PROPOSE;

						 /* Shashwat.Nath@Auspost.com code comment ends */
						oppty.Next_Step__c = APT_Constants.OPPORTUNITY_NEXTSTEP_OBTAIN_VERBAL_AGREEMENT;
						}

						//prop.APT_Next_Steps__c = APT_Constants.OPPORTUNITY_NEXTSTEP_OBTAIN_VERBAL_AGREEMENT;
						listOpportunity.add(oppty);
					}
					if(!String.isEmpty(prop.Apttus_Proposal__Approval_Stage__c) && prop.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED) && !mapProposalOld.get(prop.ID).Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_ACCEPTED))
					{
						//CR148/13
						//Added by Daric Dava 7/24/2018
						//block the update of Oppty status when when proposal status updated to ACCEPTED
					 if(!(prop.recordTypeId == amendmentRecType && prop.APT_Revenue_Type__c == APT_AmendRenewController.DECREASE_REVENUE)){

						/*Shashwat.Nath@Auspost.com commented the below line on 09/09/2020 to stop automated progression of opportunity Stage as per
+ the requirement STP-2806 for release 2*/

						//oppty.StageName = APT_Constants.OPPORTUNITY_STAGE_NEGOTIATE;

						/* Shashwat.Nath@Auspost.com code comment ends */
						oppty.Next_Step__c = APT_Constants.OPPORTUNITY_NEXTSTEP_PREPARE_CONTRACT;
						}
						//prop.APT_Next_Steps__c = APT_Constants.OPPORTUNITY_NEXTSTEP_PREPARE_CONTRACT;
						listOpportunity.add(oppty);
					}
				}
					//CR148/13 Start
					//Added By Lyndon Lavapie
					//Whenever Status changed to "Accepted" fire the calculation and assignment value for "Revenue Decrease" field in Opportunity
					Apttus_Proposal__Proposal__c oldProposal = mapProposalOld.get(prop.id);
					if(oldProposal != null && oldProposal.Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_ACCEPTED
							&& prop.Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_ACCEPTED
							&& prop.APT_Revenue_Type__c == APT_AmendRenewController.DECREASE_REVENUE
							&& prop.recordTypeId == amendmentRecType) {
						decreaseAmendment.add(prop);
					}
					//End
					//STP-5598/REQ2519238 - Set APT_pricing_fields_changed__c to true if value changed from previous value of not NULL on either Primary pickup location(Postcode-Suburb) or Minimum Monthly Spend
					if(oldProposal != null &&
						((oldProposal.Apttus_Proposal__Opportunity__r.APTPostcodeSuburb__c != null && prop.Apttus_Proposal__Opportunity__r.APTPostcodeSuburb__c != oldProposal.Apttus_Proposal__Opportunity__r.APTPostcodeSuburb__c) ||
						(oldProposal.Apttus_Proposal__Opportunity__r.APTMinimumMonthlySpend__c != null && prop.Apttus_Proposal__Opportunity__r.APTMinimumMonthlySpend__c != oldProposal.Apttus_Proposal__Opportunity__r.APTMinimumMonthlySpend__c)))
					{
						prop.APT_pricing_fields_changed__c = true;
					}
			}
			 //CR148/13 Start
			 //Added By Lyndon Lavapie
			 //Call Method to calculate the decrease revenue
			if(decreaseAmendment.size() > 0){
				calculateRevenueDecrease(decreaseAmendment);
			}
			//End

			if(listOpportunity.size() > 0) {
				update listOpportunity;
			}
		 for(Apttus_Config2__ProductConfiguration__c config : [Select id,Name,Apttus_QPConfig__Proposald__c from Apttus_Config2__ProductConfiguration__c where Apttus_QPConfig__Proposald__c in : setPropId AND Apttus_Config2__Status__c = :APT_Constants.CONFIGURATION_STATUS_FINALIZED]){
				prodConfig.add(config.Id);
				mapProp_Config.put(config.Apttus_QPConfig__Proposald__c,config.Id);
			}
			 map<Id, String> configIdProNameMap = new Map<Id, String>();
			for(Apttus_Config2__LineItem__c lineItem :[SELECT id,name,Apttus_Config2__ConfigurationId__c,Apttus_Config2__ProductId__r.Name,Apttus_Config2__ProductId__r.APT_Is_Cash_Account_Product__c,Apttus_Config2__ProductId__r.APT_Is_Charge_Account_Product__c,APT_Billing_Account__c,APT_Selected_LP__c,APT_Lodgement_Zone__c ,Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__c,Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c in : prodConfig]){
				String productNames=APT_Constants.EMPTY_STRING;
				if(lineItem.Apttus_Config2__ProductId__r.APT_Is_Cash_Account_Product__c==false && lineItem.Apttus_Config2__ProductId__r.APT_Is_Charge_Account_Product__c==true ){
					if(configIdProNameMap.containskey(lineitem.Apttus_Config2__ConfigurationId__c)&&(!(configIdProNameMap.get(lineitem.Apttus_Config2__ConfigurationId__c).contains(lineItem.Apttus_Config2__ProductId__r.Name)))){
						productNames = configIdProNameMap.get(lineitem.Apttus_Config2__ConfigurationId__c)+APT_Constants.SEPARATOR_COMMA_SPACE+lineItem.Apttus_Config2__ProductId__r.Name;
					}
					else{
						productNames = lineItem.Apttus_Config2__ProductId__r.Name;

					}
					configIdProNameMap.put(lineitem.Apttus_Config2__ConfigurationId__c,productNames);
				}
			}

			for(Apttus_Proposal__Proposal__c prop:listProposal){
				if(configIdProNameMap.get(mapProp_Config.get(prop.Id))!=null && prop.APT_Method_of_Payment__c==APT_Constants.PAYMENT_METHOD_CASH_ACCOUNT ){
					mapQuote_prod.put(prop.Id, APT_Constants.LABEL_FOR+configIdProNameMap.get(mapProp_Config.get(prop.Id))+APT_Constants.PRODUCT_BILLING_ACCOUNT1);
				}
			}

			//Added By Apttus to Cover code of catch block and Trigger Exception
			if(Test.IsRunningTest() && blnIsExceptionThrownFromTestClass){
				integer i = 1/0;
			}
			if(listOpp != null){
			ApplicationDatabase.getInstance().dmlupdate(listOpp);
			}


			return mapQuote_prod;
		}catch(Exception e){
			 return null;
		}
	}


	static set<id> setlP = new set<id>();
	static Map<string,Id> mapBillingAcc=new Map<string,Id>();
	static List<String> lststrg = new List<String>();
	static List<String> lstIds = new List<String>();
	 /**
		Method to create Quote Lodgement point from Line item Lodgementpoint on finalization of Product configuration.
		@params -
		trigger.new & Trigger.oldmap of proposal
	 **/
	private static void createQuoteLP(set<Apttus_Proposal__Proposal__c> finalizedQuotes) {
		try {
			set<id> finalizedQuoteIds = new set<id>();
			List<APT_Quote_Lodgement_Point__c> listQLP =new List<APT_Quote_Lodgement_Point__c>();
			Map<id,set<id>> mapntwkIdsFromQuote = new Map<id,set<id>>();
			Map<id,set<id>> mapntwkIdsFromLineItem = new Map<id,set<id>>();
			set<id> allNtwkIds = new set<id>();
			set<id> NtwkIds;
			for(Apttus_Proposal__Proposal__c quote :finalizedQuotes){
			 finalizedQuoteIds.add(quote.ID);
			 if(quote.APT_Selected_LP__c !=APT_Constants.EMPTY_STRING && quote.APT_Selected_LP__c != Null){
				 NtwkIds = new Set<id> ();
				 NtwkIds = getLPIDs(quote.APT_Selected_LP__c,quote.Id);
				 mapntwkIdsFromQuote.put(quote.ID,NtwkIds);
				 allNtwkIds.addall(getLPIDs(quote.APT_Selected_LP__c,quote.ID));
				}
			}

			Delete [select id from APT_Quote_Lodgement_Point__c where APT_Quote_Proposal__c IN : finalizedQuoteIds];

			Map<ID,Apttus_Config2__LineItem__c> mapLineItems=new Map<ID,Apttus_Config2__LineItem__c>([select id,APT_Lodgement_Zone_Selected__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c,APT_Selected_LP__c,APT_Product_Name__c,Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__c from Apttus_Config2__LineItem__c where Apttus_Config2__IsPrimaryLine__c = True AND Apttus_Config2__LineType__c != :APT_Constants.LABEL_LINE_TYPE_OPTION AND Apttus_Config2__ConfigurationId__c IN
																	(select id from Apttus_Config2__ProductConfiguration__c where Apttus_Config2__Status__c =:APT_Constants.CONFIGURATION_STATUS_FINALIZED AND Apttus_QPConfig__Proposald__c IN: finalizedQuoteIds)]);
			 for(Apttus_Config2__LineItem__c LI: mapLineItems.values()){
			 if(LI.APT_Selected_LP__c !=APT_Constants.EMPTY_STRING && LI.APT_Selected_LP__c != Null){
				 mapntwkIdsFromLineItem.put(LI.Id,new set<id>(getLPIDs(LI.APT_Selected_LP__c,LI.Id)));
				 allNtwkIds.addall(getLPIDs(LI.APT_Selected_LP__c,LI.Id));
				}
			}


			// Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
			Map<ID,network__c> mapntwk=new Map<ID,network__c>([select id,Post_Code__c,State__c,APT_Business_Unit__c,Network_Address__c,APT_DWS_ID__c,APT_eParcel_Enabled__c,APT_Transport_Capability__c,Org_ID__c from network__c where id IN : allNtwkIds]);


			Map<id,Id> mapProposalLineItemId=new Map<id,Id>();
			Integer count = 0;
			for(Apttus_Proposal__Proposal_Line_Item__c pLI: [select id,Apttus_Proposal__Proposal__c,Apttus_QPConfig__DerivedFromId__c from Apttus_Proposal__Proposal_Line_Item__c where Apttus_QPConfig__DerivedFromId__c IN: mapLineItems.keyset()] ){
				count = count + 1;
				mapProposalLineItemId.put(pLI.Apttus_QPConfig__DerivedFromId__c,pLI.ID);
			}

			for(Id quoteId : mapntwkIdsFromQuote.keyset()){
				for(id netId:mapntwkIdsFromQuote.get(quoteId)){
				 listQLP.add(populateQLPFields(quoteId,netId,mapBillingAcc.get(netId+APT_Constants.ADD_HYPHEN+quoteId),mapntwk.get(netId),APT_Constants.URL_QUOTE,Null,Null));
			 }
			}

			for(Id LineItemId : mapntwkIdsFromLineItem.keyset()){
				for(id netId:mapntwkIdsFromLineItem.get(LineItemId)){
				 listQLP.add(populateQLPFields(mapLineItems.get(LineItemId).Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c,netId,mapBillingAcc.get(netId+APT_Constants.ADD_HYPHEN+LineItemId),mapntwk.get(netId),APT_Constants.LABEL_LINEITEM,mapProposalLineItemId.get(LineItemId),mapLineItems.get(LineItemId)));
				}
			 }

			if(listQLP.size()>0){
				insert listQLP;
			}
		}catch(Exception e){
			return;
		}
	 }

	 /**
		Method to populate field values of Quote Lodgement point
	 **/
	public static APT_Quote_Lodgement_Point__c populateQLPFields(id quoteId,Id ntwkId,Id billAcc,Network__c ntwk,string source,Id proposalId,Apttus_Config2__LineItem__c lineItem){
		APT_Quote_Lodgement_Point__c qLP = new APT_Quote_Lodgement_Point__c();
		try {

					qLP.APT_Quote_Proposal__c = quoteId;
					if(source==APT_Constants.LABEL_LINEITEM){
						 Map<id,Id> mapLZ = getLPZoneIds(lineItem.APT_Lodgement_Zone_Selected__c);
						 qLP.APT_Proposal_Line_Item__c= proposalId;
						 qLP.APT_Lodgement_Zone_Lookup__c = mapLZ.get(ntwkId);
						 //lineItem.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__c;
						 qLP.APT_Product__c =lineItem.APT_Product_Name__c;
					}
					qLP.APT_Selected_Lodgement_Point__c = ntwkId;
					qLP.APT_LP_Post_Code__c = ntwk.Post_Code__c;
					qLP.APT_LP_State__c =ntwk.State__c;

					// Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
					qLP.APT_Outlet_Type__c =ntwk.APT_Business_Unit__c;
					qLP.APT_Address__c = ntwk.Network_Address__c;
					qLP.APT_Billing_Account__c = billAcc;
					qLP.APT_DWS_ID__c = ntwk.APT_DWS_ID__c;
					qLP.APT_eParcel_Enabled__c = ntwk.APT_eParcel_Enabled__c;
					qLP.APT_Lodgement_Point_Lookup__c = ntwkId;
					qLP.APT_Organisation_ID__c =ntwk.Org_ID__c;
					qLP.APT_Transport_Capability__c =ntwk.APT_Transport_Capability__c;
		}catch(Exception e){
			return null;
		}
		return qLP;
	}

	/**
		Method to parse the Lodgement Point and Billing Account Ids
	 **/
	public static set<id> getLPIDs(String selectedLP,String recId){
		 try {
			 setlP = new set<id>();
			 LIst<string> lstlPIds = new List<string>();
			 lststrg = new List<String>();
			 lstIds = new List<String>();
			 if(selectedLP.contains(APT_Constants.SEPERATOR_COMMA)){
				lststrg = selectedLP.split(APT_Constants.SEPERATOR_COMMA);
			 }else {
				lststrg.add(selectedLP);
			 }
			 for(string s: lststrg){
				if(s.contains(APT_Constants.SEPERATOR_SIMILARITY)){
				lstIds=s.split(APT_Constants.SEPERATOR_SIMILARITY);
				lstlPIds.addall(lstIds);
				if(lstIds != null && lstIds.size()>=2 ){
					mapBillingAcc.put(lstIds[0]+APT_Constants.ADD_HYPHEN+recId,lstIds[1]);
				}

			 }else {
				lstlPIds.add(s);
			 }
			 }
			 for(String nId: lstlPIds){
				if(nId.startsWith(Network__c.sObjectType.getDescribe().getKeyPrefix())){
				setlP.add(nId);
				}
			 }
		}catch(Exception e){
			return null;
		}
	 return setlP;
	}

	/**
		Map
	**/
	public static Map<Id,Id> getLPZoneIds(String selectedZone){
		Map<Id,Id> mapLZ =new Map<Id,Id>();
		try {

			 if(selectedZone!=null){
				String[] selectedLZList = selectedZone.split(APT_Constants.SEPERATOR_COMMA);
				for(string s:selectedLZList){
				String [] lstLZ = s.split(APT_Constants.SEPERATOR_SIMILARITY);
				if(lstLZ.size()==2){
				mapLZ.put(lstLZ[0],lstLZ[1]);
			 }
			 }
			 }
		}catch(Exception e){
			return null;
		}
	 return mapLZ;
	}

	 //CR148/13
	 //Added By Lyndon Lavapie
	 //Calculate and assignment value for "Revenue Decrease" to Oppty
	public static void calculateRevenueDecrease(List<Apttus_Proposal__Proposal__c> decreaseAmendment) {
		Map<Id,Id> originalOppty = new Map<Id,Id>();

		Set<Id> accountId = new Set<Id>();
		Map<Id,Decimal> proposalTotalPrice = new Map<Id,Decimal>();
		Map<Id,Decimal> opptyTotalDecrease = new Map<Id,Decimal>();
		Map<Id,Decimal> opptyTotalAmount = new Map<Id,Decimal>();
		List<opportunity> opptyToUpdate = new list<Opportunity>();
		Map<Id,Id> opptyBundleMap = new Map<Id,Id>();
		set<Id> contractIds = new Set<Id>();
		set<String> agreementNumber = new Set<String>();
		try {

			for(Apttus_Proposal__Proposal__c a: decreaseAmendment){
				originalOppty.put(a.Apttus_Proposal__Opportunity__c,a.Id);
				accountId.add(a.Apttus_Proposal__Account__c);
				contractIds.add(a.APT_Contract_Id__c);
			}
			for(Apttus__APTS_Agreement__c cont: [select Id, Apttus__Agreement_Number__c From Apttus__APTS_Agreement__c where Id =: contractIds]){
				agreementNumber.add(cont.Apttus__Agreement_Number__c);
			}

			for (AggregateResult ar : [SELECT APT_Quote_Proposal__c, SUM(APT_TotalPrice__c) FROM APT_Opportunity_Product_Line_Item__c where APT_Quote_Proposal__c in: decreaseAmendment GROUP BY APT_Quote_Proposal__c]) {
				proposalTotalPrice.put((Id)ar.get('APT_Quote_Proposal__c'), (Decimal)ar.get('expr0'));
			}
			for(Apttus__APTS_Agreement__c contract : [Select Id, Apttus__Related_Opportunity__c, Apttus__Account__c From Apttus__APTS_Agreement__c where Apttus__Account__c in: accountId AND Apttus__Agreement_Number__c in: agreementNumber AND ((Apttus__Status__c =: APT_AmendRenewController.SUPERSEDED_STATUS AND Apttus__Status_Category__c =: APT_AmendRenewController.AMENDED_STATUS_CATEGORY) OR Id in: contractIds)]){
				opptyBundleMap.put(contract.Apttus__Related_Opportunity__c, contract.Apttus__Account__c);

			}
			for (AggregateResult ar : [SELECT AccountId, SUM(Amount), Max(APT_Revenue_Decrease__c) FROM Opportunity where Id in: opptyBundleMap.keyset() GROUP BY AccountId]) {
				//proposalTotalPrice.put((Id)ar.get('APT_Quote_Proposal__c'), (Decimal)ar.get('expr0'));
				opptyTotalAmount.put((Id)ar.get('AccountId'), (Decimal)ar.get('expr0'));
				opptyTotalDecrease.put((Id)ar.get('AccountId'), (Decimal)ar.get('expr1'));
			}



			for(Opportunity oppty: [Select Id, Amount, AccountId From Opportunity where id in: originalOppty.keyset()]){
				if(opptyTotalAmount.containsKey(oppty.AccountId)){
						//Decimal decreaseRev = opptyTotalDecrease.get(oppty.AccountId));

						Decimal decreaseRev = opptyTotalDecrease.get(oppty.AccountId) == null ? 0 : opptyTotalDecrease.get(oppty.AccountId);
						oppty.APT_Revenue_Decrease__c = (opptyTotalAmount.get(oppty.AccountId) - proposalTotalPrice.get(originalOppty.get(oppty.Id)) );

						opptyToUpdate.add(oppty);

				}

			}

			if(!opptyToUpdate.isEmpty()){
				update opptyToUpdate;
			}
		}catch(Exception e){
			return;
		}
	}

	/**
		Method to derive the contracting entity associated with a Proposal by looking at the a
		ssociated proposal line items.
		@params -
		newProposalList - List of proposal records being inserted/ updated.
	**/
	public static string setContractingEntities(Map<Id, Apttus_Proposal__Proposal__c> newProposalMap) {
		Map<Id, Apttus_Proposal__Proposal__c> proposalIdsToRecalc = new Map<Id, Apttus_Proposal__Proposal__c>();
		try{
			for(Apttus_Proposal__Proposal__c p : [SELECT Id,
													(SELECT id, Apttus_Proposal__Product__c, APT_Bundle_Product_Name__c,
														Apttus_Proposal__Product__r.name,
														Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c ,
														Apttus_Proposal__Product__r.APT_Contracting_Entity__c
													FROM Apttus_Proposal__R00N70000001yUfBEAU__r
													WHERE Apttus_Proposal__Product__r.APT_Contracting_Entity__c != '')
												FROM Apttus_Proposal__Proposal__c
												WHERE Id IN : newProposalMap.keySet()]){
				if(!p.Apttus_Proposal__R00N70000001yUfBEAU__r.isEmpty()){
					String contractingEntity = p.Apttus_Proposal__R00N70000001yUfBEAU__r?.get(0).Apttus_Proposal__Product__r?.APT_Contracting_Entity__c;
					if(!String.isBlank(contractingEntity)){
						newProposalMap.get(p.Id).APT_Contracting_Entity__c = contractingEntity;
					}
				}
			}
			return APT_Constants.SUCCESS_LABEL;
		}catch(Exception e){
			return e.getMessage();
		}
	}

	//STP-5088 To update Proposal Owner with the value of Opportunity Driver (Opportunity'owner)
	 /*public static string setOpportunityDriver(Map<Id, Apttus_Proposal__Proposal__c> newProposalMap) {
		Map<String, String> opportunityToProposal = new Map<String, String>();

		try{
			for(Apttus_Proposal__Proposal__c p : newProposalMap.values())
			{

				opportunityToProposal.put(p.Apttus_Proposal__Opportunity__c,p.ID);
			}
			for(Opportunity op : [Select Id,OwnerId from Opportunity where Id in: opportunityToProposal.keySet()] )
			{
				if(opportunityToProposal.containskey(op.Id))
				{
					String proposalID = opportunityToProposal.get(op.Id);
					if(!String.isBlank(newProposalMap.get(proposalID).Apttus_Proposal__Opportunity__c))
					{
						newProposalMap.get(proposalID).OwnerId=op.OwnerId;
					}
				}
			}

			return APT_Constants.SUCCESS_LABEL;
		}catch(Exception e){
			return e.getMessage();
		}
	}*/

	/**
	* @description : This method will be called from BeforeInsert Trigger
	* @author Mansi Shah | 06-10-2021
	* @param listOfNewProposals
	*/
	public static void onBeforeInsert(List<Apttus_Proposal__Proposal__c> listOfNewProposals){
		APT_ProposalTriggerHelper.updateProposalOwner(listOfNewProposals);
	}

	/**
	* @description : This method will be called from BeforeUpdate Trigger
	* @author Mansi Shah | 06-10-2021
	* @param oldProposalMap
	* @param newProposalMap
	**/
	public static void onBeforeUpdate(Map<Id,Apttus_Proposal__Proposal__c> oldProposalMap,Map<Id,Apttus_Proposal__Proposal__c> newProposalMap){
		APT_ProposalTriggerHelper.updateApprovalFields(oldProposalMap,newProposalMap);
	}
}