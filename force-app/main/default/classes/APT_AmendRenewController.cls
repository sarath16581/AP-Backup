/**
Description: This class is controller for vf page - APT_AmendRenew. This will handle DoV and Renew.
This will be called from Amend/Renew button from Agreement.
Created By - Mausam Padhiyar
Created Date - 3rd Nov, 2015

Last Modified By - Mausam Padhiyar
Last Modified Date - 29th July, 2016 | Defect-1233, Sort Amend/Renew categories

Last Modified By - Mausam Padhiyar
Last Modified Date - 9th Aug, 2016 | Defect-1336, populate selected contract amend/renew category and require customer signature? fields

Last Modified By - Mausam Padhiyar
Last Modified Date - 20th Sept, 2016 | 1165 : Contract Pricing

Last Modified By - Mausam Padhiyar
Last Modified Date - 20th Jan, 2017 | 1825 : Use Offline Rates

Last Modified By - Conrad Borbon
Last Modified Date - 30th July, 2018 | Updated class to implement CR/REQ 146: Amendment flow enhacements

Last Modified By - Lyndon Lavapie
Last Modified Date - 30th July, 2018 | Updated class to implement CR/REQ 148/13: Increase and decrease revenue process


Last Modified By - Lija Jawahar
Last Modified Date - 28th May 2020 | SOQL Limit exceeding Fix

Last Modified By - Shashwat Nath
Last Modified Date - 3rd Aug, 2020 | Updated class to implement DOV Reason Picklist

Last Modified By - Shashwat Nath
Last Modified Date - 18th Aug, 2020 | Updated class to implement Logic to Allow Users to Associate DOV/Renewal to an Existing Opportunity

Last Modified By - Krishna Velani
Last Modified Date - 26th Feb, 2021 | STP-3031 Updated lookupToOpportunity method to remove initial filter of fetching DoV Increase/DoV Decrease Opportunities
and updated doAmend method to add logic to update Opportunity Sub type based on Revenue type

Last Modified By - Mansi Shah
Lat Modified Date - 28th May, 2021 | STP-5134 commented the code for DoV Reason - Removed Validation for Dov Reason and population of DoV Reason

@changelog:
2022-10-05	seth.heang@auspost.com.au	uplift API version to 55
2023-07-06 nasir.jawed2@auspost.com.au Added method goToOpportunity(), and in doAmend(),doRenew() and when helps the user to select an opportunity for DOV.
2023-05-09  Bharat Patel - update in condition to check key fields in doAmend(),doRenew() method to fix STP-9554.
2023-11-23  Bharat Patel - STP-9770 - update to redirect to shopping cart instead of proposal
**/

public with sharing class APT_AmendRenewController {

	// Constants CR148,146 and 13
	public static final string AMENDED_CONTRACT_TYPE = 'Deed of Variation Category';
	public static final string CATEGORY_DOV_PROPANDCONTR ='Proposal and Contract Flow';
	public static final string DECREASE_REVENUE ='Decrease Revenue';
	public static final string INCREASE_REVENUE ='Increase Revenue';
	public static final string NOT_INCREASE_REVENUE_ERROR ='OPC is not increase in revenue.';
	public static final string NOT_DECREASE_REVENUE_ERROR ='OPC is not decrease in revenue.';
	public static final string AMENDED_STATUS_CATEGORY ='Amended';
	public static final string SUPERSEDED_STATUS ='Superseded';

	// Options added to hold revenue type picklist values
	public List<SelectOption> revenueValues {get; set;}
	public List<SelectOption> reasons{get; set;}
	// strng variable added to hold revenue type selected,
	public string selectedRevenue {get; set;}
	public string selectedReason {get; set;}
	// Boolean added as reference in visualforce to control revenue type picklist visibility
	public boolean bDisplayRevenue {get; set;}

	String agreementId;
	String actionName;
	public boolean haserrorMessages {get; set;}
	public string selectedCategory {get; set;}
	public string titleMsg{get; set;}
	public string relatedAccountId;

	public boolean bDisplayRenew {get; set;}
	public boolean bDisplayAmend {get; set;}
	public boolean displayReasonPicklist{get; set;}
	public boolean displayLookup{get; set;}
	public boolean helpSection {get; set;}
	public APT_R2T_Renew_DoV_Properties__c DoVProperties {get;set;}
	// CR 146 Enhancement - August 7, 2018 - conrad.c.v.borbon - START and END
	public list<APT_R2T_Renew_DoV_Properties__c> displayCatValues {get;set;}

	// CR 146 Enhancement - August 7, 2018 - conrad.c.v.borbon - START
	public static final string ERROR_SELECT_REVENUE ='Please select a revenue type.';

	// Agreement
	public static Apttus__APTS_Agreement__c agreement;
	public static final string ERROR_SELECT_REASON ='Please select a DOV Reason.';

	/* Shashwat.Nath@Auspost.com Added the below Variables to be used in lookupToOpportunity method added for User Story STP-2209 */

	public String oppName{get;set;}
	public Id oppId{get;set;}
	public List<Opportunity> oppList {get;set;}
	Public string accountName;

	/* Shashwat.Nath@auspost.com Code ends*/

	public List<APT_R2T_Renew_DoV_Properties__c> getDisplayCatValues() {
		// 28/05/2020 LJ Removed the SOQL - SOQL 101 Error FIX
		displayCatValues = new list<APT_R2T_Renew_DoV_Properties__c>();
		List<APT_R2T_Renew_DoV_Properties__c> catgoryValues = APT_R2T_Renew_DoV_Properties__c.getAll().values();
		for (APT_R2T_Renew_DoV_Properties__c item : catgoryValues){
			if(item.APT_Type__c == APT_Constants.ACTION_NAME_DoV ){
				displayCatValues.add(item);
			}
		}
		displayCatValues.sort();
		return displayCatValues;
	}
	// CR 146 Enhancement - August 7, 2018 - conrad.c.v.borbon - END

	/*
	 * created by conrad.c.v.borbon on 07/02/2018
	 * Method to generate picklist values for Revenue Type
	 * Part of CR 146
	*/
	public List<SelectOption> getRevenueType() {
		revenueValues = new List<SelectOption>();
		// CR 146 Enhancement - August 7, 2018 - conrad.c.v.borbon - START
		revenueValues.add(new SelectOption(APT_Constants.SELECT_OPTION_NONE,APT_Constants.SELECT_OPTION_NONE));
		// CR 146 Enhancement - August 7, 2018 - conrad.c.v.borbon - END

		// Perform field describe to pull revenue type picklist value from proposal object
		Schema.DescribeFieldResult fieldResult = Apttus_Proposal__Proposal__c.APT_Revenue_Type__c.getDescribe();
		List<Schema.PicklistEntry> revenueType = fieldResult.getPicklistValues();

		// Store picklist value in a selection option list
		for( Schema.PicklistEntry picklistVal : revenueType) {
			revenueValues.add(new SelectOption(picklistVal.getLabel(), picklistVal.getValue()));
		}
		return revenueValues;
	}

	/* Mansi Shah commented DOV reason method for User Story - STP-5314*/
	/* Shashwat.Nath@Auspost.Com added the below method as Part of STP Release 2 Dov/Renewals Enhancements
	 * This method is Called from the page APT_AmendRenew when User Selects a value for "Revenue Type " Picklist .
	 * This method is used to display a new picklist field on the page "DOV Reason " which gets rendered on selection of "Revenue Type"
	*/
	/*public void renderDovReasonPicklist() {
	 try{
		 //Resetting the variables on reshuffling of the Revenue type Values
			oppName ='';
			oppId = null;
			displayLookup = false;
			displayReasonPicklist = false;
			reasons= new List<SelectOption>();
			// Adding a None Constant Value to the Select Option
			reasons.add(new SelectOption(APT_Constants.SELECT_OPTION_NONE,APT_Constants.SELECT_OPTION_NONE));

			/* Fetching the Values from the Custom Setting to get the Values from the DOV increase reason and DOV increase/decrease
			 reason and populate them them based on the selection of Revenue type
			Map<String , APT_R2T_Renew_DoV_Properties__c> maptR2TRenewDoVProperties = APT_R2T_Renew_DoV_Properties__c.getall();
			List<String> dovReasons = new List<String>();
			// Adding all the values to the List
			dovReasons.addAll(maptR2TRenewDoVProperties.keyset());
			// Sorting the Valyes
			dovReasons.sort();
			// Iterating over the custom Setting Records
			for(String s : dovReasons) {
				if('Increase Revenue'.equalsIgnoreCase(selectedRevenue) && maptR2TRenewDoVProperties.get(s).DOV_Increase_Reason__c!=null){
					reasons.add(new SelectOption(maptR2TRenewDoVProperties.get(s).DOV_Increase_Reason__c, maptR2TRenewDoVProperties.get(s).DOV_Increase_Reason__c));
				}
				else if('Decrease Revenue'.equalsIgnoreCase(selectedRevenue) && maptR2TRenewDoVProperties.get(s).DOV_Decrease_Reason__c!=null){
					reasons.add(new SelectOption(maptR2TRenewDoVProperties.get(s).DOV_Decrease_Reason__c, maptR2TRenewDoVProperties.get(s).DOV_Decrease_Reason__c));
				}
			}

			// Setting the display Display Lookup Reason boolean to true
			if('Increase Revenue'.equalsIgnoreCase(selectedRevenue)){
				displayReasonPicklist = true;
				displayLookup = true;
			}
		}
		catch (System.Exception ex) {
		 ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}
	}*/

	/* Shashwat.Nath@auspost.com.au code ends */

	/*
		CreatedBy: Mansi Shah
		CreatedDate: 28-05-2021
		Description: This method will check if Opportunity Lookup needs to be displayed on UI or not
	*/
	public void checkOpprtunityDisplay(){
		// Setting the display Display Lookup Reason boolean to true
			if('Increase Revenue'.equalsIgnoreCase(selectedRevenue)){
				displayLookup = true;
			}
	}

	/*
	 * created by conrad.c.v.borbon on 07/02/2018
	 * Method to check if string value selected is proposal and contract flow
	 * Part of CR 146
	*/
	public Boolean bCheckPropToContract() {
		// Validate and assign boolean to true if selected amendment category is proposal and contract flow
		if(selectedCategory == APT_AmendRenewController.CATEGORY_DOV_PROPANDCONTR) {
			if(selectedRevenue != APT_Constants.SELECT_OPTION_NONE && 'Increase Revenue'.equalsIgnoreCase(selectedRevenue )){
				displayReasonPicklist = true;
				displayLookup = true;
			}
			else{
				displayReasonPicklist = false;
				displayLookup = false;
			}

			return TRUE;
		}

		//Updating the boolean to display the ability to select an existing opportunity to associate the Renewal for both type of Renewals
		else if('Standard Apttus Renewal'.equalsIgnoreCase(selectedCategory) || 'Ariba and SAP Contracts'.equalsIgnoreCase(selectedCategory)){
			displayLookup = true;
			return FALSE;
		}

		else {
			displayReasonPicklist = false;
			displayLookup = false;
			return FALSE;
		}
	}

	/* Shashwat.Nath@Auspost.com added the below method which would be called upon from "APT_AmendRenew" VFP when user clicks on the lookup
		icon to select the Opportunity to associate with the DOV/renewal*/

	public PageReference lookupToOpportunity(){
		String opportunitySubType;
		// Setting the value for opportunitySubType filter based on Revenue Type Selection by the User when User is Doing DOV
		//Increase Revenue
		//STp-3031 krishna.velani@auspost.com.au on 26thFeb: Commented below logic and removed subtype filter from If-Else block so that it fetches all open opportunites associated with the organization
	 /* if(actionName.equalsIgnoreCase(APT_Constants.ACTION_NAME_DoV) && 'Increase Revenue'.equalsIgnoreCase(selectedRevenue)){
			opportunitySubType = 'DoV Increase';
		}
		//Decrease Revenue
		else if(actionName.equalsIgnoreCase(APT_Constants.ACTION_NAME_DoV) && 'Decrease Revenue'.equalsIgnoreCase(selectedRevenue)){
			opportunitySubType = 'DoV Decrease';
		}
		//Setting the value for opportunitySubType filter when User is doing Renewal
		else if(actionName.equalsIgnoreCase(APT_Constants.ACTION_NAME_RENEW)){
			opportunitySubType = 'Re-Contract';
		}*/
		/* Query the Opportunity based upon the name match or Opportunity Number match which user enters . Query filters the opportunity records within
		 same Organisation as Active Contract from which the DOV is initiated .
		 Also putting an inner query to get at least one proposal associated to Opportunity which is a Primary Proposal . This would be used later to
		 restrict user to use any such opportunity which is already having an active proposal when they click on Continue Button by displaying them an
		 error . Adding an inner query here to save a SOQL on doAmend() in order to find if selected opportunity has any active proposal linked to them */

		if(!String.isblank(oppName) && !String.isblank(relatedAccountId) ){
			oppList = [Select id,Name,Account.name,Opportunity_Number__c,Opportunity_SubType__c,LastmodifiedDate, amount,
						(Select id from R00N70000001yUfDEAU where Apttus_Proposal__Primary__c = true LIMIT 1),
						stagename, isClosed , Owner.Name
						from Opportunity WHERE
						(Name LIKE : oppName+'%' OR Opportunity_Number__c =:oppName)
						AND isClosed=false AND AccountId=:relatedAccountId LIMIT 1000];
		}
		//If user chooses to view the Opportunities under the same Organisation as the original account without wanting to put any oppoortunity name or number
		else if(String.isblank(oppName) && !String.isblank(relatedAccountId)){
		 oppList = [Select id,Name,Account.name,Opportunity_Number__c,Opportunity_SubType__c,LastmodifiedDate, amount,
					 (Select id from R00N70000001yUfDEAU where Apttus_Proposal__Primary__c = true LIMIT 1),
					 stagename, isClosed , Owner.Name
					 from Opportunity WHERE
					 isClosed=false AND Accountid=:relatedAccountId LIMIT 1000];
		}
		else{
			oppList = new List<Opportunity>();
		}
		// Setting up the Page reference for the "LookupOpportunityVFP" which would display the list of opportunities for user to select
		PageReference pageRef = new PageReference('/apex/LookupOpportunityVFP');
		pageRef.setRedirect(false);

		return pageRef;
	}

	/* Shashwat.Nath@Auspost.com added the below method which would be called upon from "LookupOpportunityVFP" VFP when user clicks on the Selected
		Opportunity link to redirect user back to the "APT_AmendRenewP" Page and also set's the Opportunity id and Opportunity Name Variables*/

	public PageReference goBack(){
		// Set's the opportunity name Variable
		oppName = ApexPages.currentPage().getParameters().get('oppName');

		// Set's the opportunity id to associate the proposal with
		oppId= ApexPages.currentPage().getParameters().get('oppId');

		// Setting the page reference to redirect user back to
		PageReference pageRef = new PageReference('/apex/APT_AmendRenew');
		pageRef.setRedirect(false);
		return pageRef;
	}

	/* Shashwat.Nath@Auspost.com code ends */

	/**
	*This method gets calling from aPT_AddProductLwc lightning and is used to create a proporsal when "Add Product" button gets clicked from opportunity.
	*@param String
	*@return pageRef APT_AmendRenew
	*/
	public PageReference goToOpportunity(){
		// Set's the opportunity name Variable
		oppName =string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('oppName'));

		// Set's the opportunity id to associate the proposal with
		oppId= string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('oppId'));

		//fetching the opportunity record by using selector
		map<Id,Opportunity> oppMap = OpportunitySelector.newInstance(0,new Set<SObjectField>{opportunity.IsStartrackProposal__c,opportunity.APTPostcodeSuburb__c,opportunity.APTMinimumMonthlySpend__c}).selectById(new Set<Id>{oppId});
		Opportunity opp = oppMap.get(oppId);
		//Checking the value for StarTrack Opportunity to show an error mesaage
		if(opp.IsStartrackProposal__c == null || opp.IsStartrackProposal__c == ''){
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,System.Label.APT_AmendRenewal_StarTrackField));
			return null;
		}
		if(opp.IsStartrackProposal__c != null && opp.IsStartrackProposal__c == APT_Constants.OPTION_YES && (opp.APTPostcodeSuburb__c == null || opp.APTMinimumMonthlySpend__c == null)){
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,System.Label.Yes_Its_StarTrackProduct));
			return null;
		}
		// Setting the page reference to redirect user back to
		PageReference pageRef = new PageReference('/apex/APT_AmendRenew');
		pageRef.setRedirect(false);
		return pageRef;
	}

	/**
	 * returns the help message associated to selected category
	 * */
	public String getTextmessage() {
		// Updated by Adrian Recio, removed unecessary try catch condition and reduce code size
		// 31/7/2018, part of CR 148 changes
		// 28/05/2020 LJ Removed the SOQL - SOQL 101 Error FIX
		List<APT_R2T_Renew_DoV_Properties__c> selDoVProperties = new List<APT_R2T_Renew_DoV_Properties__c>();

		List<APT_R2T_Renew_DoV_Properties__c> catgoryValues = APT_R2T_Renew_DoV_Properties__c.getAll().values();
		for (APT_R2T_Renew_DoV_Properties__c item : catgoryValues){
			if(item.APT_Category__c == selectedCategory ){
				selDoVProperties.add(item);
			}
		}

		// If property exist, pull help text from the cs
		if(selDoVProperties.size()>0 ){
			return selDoVProperties[0].APT_Help_Text__c;
		}

		// Return empty string
		return APT_Constants.EMPTY_STRING;
	}

	/**
	 * returns text message
	 * */
	public PageReference textmessage() {
		// Conrad Borbon, set boolean to true if flow is proposal and contract flow
		bDisplayRevenue = bCheckPropToContract();
		return null;
	}

	/**
	 * Constructor of class APT_AmendRenewController
	 * */
	public APT_AmendRenewController() {
		// Adrian Recio, 1/8/2018
		// Initialize controller
		init();
	}

	/*
	 * initialization
	 */
	public void init() {
		try {
			// Pull page agreement Id and action page parameters
			agreementId = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_AGREEMENT_ID));
			actionName = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_ACTION_NAME));

			// Set defailt visibility for renewal and amendment components
			bDisplayRenew = false;
			bDisplayAmend = false;
			//Set default value to false
			displayReasonPicklist = false;
			displayLookup = false;
			selectedCategory = APT_Constants.SELECT_OPTION_NONE;
			selectedReason = APT_Constants.SELECT_OPTION_NONE;
			// CR 146 Enhancement - August 7, 2018 - conrad.c.v.borbon - START and END
			selectedRevenue = APT_Constants.SELECT_OPTION_NONE;
			helpSection=false;

			// Assign title message based on current action type
			if(!String.isEmpty(actionName) && actionName.equalsIgnoreCase(APT_Constants.ACTION_NAME_RENEW)) {
				titleMsg = APT_Constants.RENEW_CONTRACT_TYPE;
				bDisplayRenew = true;
			} else if(!String.isEmpty(actionName) && actionName.equalsIgnoreCase(APT_Constants.ACTION_NAME_DoV )) {
				titleMsg = APT_AmendRenewController.AMENDED_CONTRACT_TYPE;
				bDisplayAmend = true;
			}

			// Pull and validate agreement and line Item
			// 28/05/2020 LJ Combined SOQL - SOQL 101 Error FIX
			agreement = [
					SELECT
							Id, Name, Apttus__Related_Opportunity__c,
							Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c, APT_Contract_Number__c,
							Apttus__Primary_Contact__c, Apttus__Account__c, Apttus__FF_Agreement_Number__c,
							Apttus_QPComply__RelatedProposalId__r.Apttus_Proposal__Proposal_Name__c, Included_Product_Lines__c,
							Apttus_QPComply__RelatedProposalId__r.APT_Method_of_Payment__c,
							APT_SelectedContractAmendRenewCategory__c, APT_Require_Customer_Signature__c, Apttus_QPComply__RelatedProposalId__c,
							Apttus_QPComply__RelatedProposalId__r.APT_Use_Offline_Rates__c,
					(
							SELECT id,Apttus_CMConfig__DerivedFromId__c,Apttus__AgreementId__c
							FROM Apttus__AgreementLineItems__r
							WHERE Apttus_CMConfig__DerivedFromId__r.APT_International_PCMS_or_CSP__c =: APT_Constants.PRODUCT_DETAILS_PCMS AND
							Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__ProductId__r.ProductCode =: APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE
							LIMIT 1
					)
					FROM Apttus__APTS_Agreement__c
					WHERE Id = :agreementId
					LIMIT 1
			];

			if(agreement != null && agreement.Apttus_QPComply__RelatedProposalId__r.APT_Use_Offline_Rates__c) {
				haserrorMessages = true;
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The Proposal has Offline Rates attached.'));
			}

			if(!agreement.Apttus__AgreementLineItems__r.isEmpty() && (actionName == APT_Constants.ACTION_NAME_RENEW)){
				haserrorMessages = true;
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.WARNING,System.Label.APT_InternationalDBundle_Renew));
			}
			relatedAccountId = agreement.Apttus__Account__c;
			// Onload call revenue type initialization method, Conrad Borbon
			getRevenueType();
			getDisplayCatValues();
			//getReasons();
		} catch (System.Exception ex) {
			haserrorMessages = true;
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}
	}

	/**
	 * returns the list of categories
	 * */
	// Updated by Adrian Recio
	// 1/8/2018, removed unecessary try catch condition and optimize option creation
	public list<SelectOption> getCategories() {
		list<SelectOption> listCategory = new list<SelectOption>();
		listCategory.add(new SelectOption(APT_Constants.SELECT_OPTION_NONE,APT_Constants.SELECT_OPTION_NONE));
		list<APT_R2T_Renew_DoV_Properties__c> listR2TRenewDoVProperties = APT_R2T_Renew_DoV_Properties__c.getall().values();
		for(APT_R2T_Renew_DoV_Properties__c R2TRenewDoVProperty : listR2TRenewDoVProperties) {
			if(// if cs type is aligned with the renewal page action, populate option
					(!String.isEmpty(R2TRenewDoVProperty.APT_Category__c ) && !String.isEmpty(actionName) && actionName.equalsIgnoreCase(APT_Constants.ACTION_NAME_RENEW)
							&& !String.isEmpty(R2TRenewDoVProperty.APT_Type__c) && R2TRenewDoVProperty.APT_Type__c.equalsIgnoreCase(APT_Constants.ACTION_TYPE_RENEWAL)) ||
							// if cs type is aligned with the amendment page action, populate option
							(!String.isEmpty(R2TRenewDoVProperty.APT_Category__c) && !String.isEmpty(actionName) && actionName.equalsIgnoreCase(APT_Constants.ACTION_NAME_DoV )
									&& !String.isEmpty(R2TRenewDoVProperty.APT_Type__c) && R2TRenewDoVProperty.APT_Type__c.equalsIgnoreCase(APT_Constants.ACTION_NAME_DoV ))
					) {
				listCategory.add(new SelectOption(R2TRenewDoVProperty.APT_Category__c, R2TRenewDoVProperty.APT_Category__c));
			}// End If
		}// End For
		return listCategory;
	}

	/**
	 * returns to the agreement page upon cancel
	 * */
	public PageReference doCancel() {
		// Update by Adrian Recio, removed unecessary try catch condition
		// 31/7/2018,
		if( !String.isEmpty(agreementId)) {
			Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c();
			agreement.id = agreementId;
			return new ApexPages.StandardController(agreement).View();
		}
		return null;
	}

	/**
	 * processes the renew request
	 * */
	public PageReference doRenew() {
		Savepoint sp = Database.setSavepoint();
		try {
			// Added by Adrian Recio to disable trigger cloning
			AgreementToSFContractTriggerHandler.disableCloning = true;
			displayLookup = true;
			if(String.isEmpty(selectedCategory)) {
				haserrorMessages = true;
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_SELECT_CATEGORY));
				return null;
			}

			/* Shashwat.Nath@Auspost.com has added the below code to check if the selected opportunity has an associated proposal which is primary
			 then display an error to user and do not allow them to proceed further with that opportunity */
			if(!String.isBlank(oppId)){
				//Iterating over the open Opportunity list for the same revenue type within the same organisation as Active Contract
				for(Opportunity opportunityRecord :oppList){
					// Display error if the selected opportunity is already having a primary proposal
					if(!opportunityRecord.R00N70000001yUfDEAU__r.isEmpty() && opportunityRecord.id==oppId){
						haserrorMessages = true;
						ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, LABEL.OpportunityHasPrimayProposal));
						return null;
					 }
				 }
			 }

			/*Shashwat.Nath@auspost.com.au code ends */

			Boolean bCreateCase = false;
			Boolean bCreateOpportunity = false;
			Boolean bCreateQuote = false;
			Boolean bCreateAgreement = false;
			Boolean bRequireCustomerSignature = false; //defect 1336

			if( !String.isEmpty(actionName) && actionName.equalsIgnoreCase(APT_Constants.ACTION_NAME_RENEW)) {
				list<APT_R2T_Renew_DoV_Properties__c> listR2TRenewDoVProperties = APT_R2T_Renew_DoV_Properties__c.getall().values();
				if(listR2TRenewDoVProperties != null && listR2TRenewDoVProperties.size() > 0){
					for(APT_R2T_Renew_DoV_Properties__c renewDovProperty : listR2TRenewDoVProperties) {
						if( !String.isEmpty(renewDovProperty.APT_Type__c) && renewDovProperty.APT_Type__c.equalsIgnoreCase(APT_Constants.ACTION_TYPE_RENEWAL)
								&& !String.isEmpty(renewDovProperty.APT_Category__c) && renewDovProperty.APT_Category__c.equalsIgnoreCase(selectedCategory)) {

							bCreateOpportunity = renewDovProperty.APT_Create_Opportunity__c;
							bCreateQuote = renewDovProperty.APT_Create_Quote__c;
							bCreateAgreement = renewDovProperty.APT_Create_Agrement__c;
							bCreateCase = renewDovProperty.APT_Create_Case__c;
							bRequireCustomerSignature = renewDovProperty.APT_Require_Customer_Signature__c; //defect 1336
						}
					}
				}
			}

			// 28/05/2020 LJ conditional query- SOQL 101 Error FIX
			if ( agreement == null || agreement.Id != agreementId) {
				agreement = [
						SELECT Id, Name, Apttus__Related_Opportunity__c, Apttus_QPComply__RelatedProposalId__c,
								Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c, APT_Contract_Number__c,
								Apttus__Primary_Contact__c, Apttus__Account__c, Apttus__FF_Agreement_Number__c,
								Apttus_QPComply__RelatedProposalId__r.Apttus_Proposal__Proposal_Name__c, Included_Product_Lines__c,
								Apttus_QPComply__RelatedProposalId__r.APT_Method_of_Payment__c,
								APT_SelectedContractAmendRenewCategory__c, APT_Require_Customer_Signature__c
						FROM Apttus__APTS_Agreement__c
						WHERE Id = :agreementId
				];
			}

			if(agreement != null && agreement.Apttus__Related_Opportunity__c != null && oppId == null){
				//fetching the opportunity record by using selector
				map<Id,Opportunity> oppMap = OpportunitySelector.newInstance(0,new Set<SObjectField>{opportunity.IsStartrackProposal__c,opportunity.APTPostcodeSuburb__c,opportunity.APTMinimumMonthlySpend__c}).selectById(new Set<Id>{agreement.Apttus__Related_Opportunity__c});
				Opportunity opp = oppMap.get(agreement.Apttus__Related_Opportunity__c);
				//Checking the value for StarTrack Opportunity to show an error mesaage
				if(opp.IsStartrackProposal__c == null || opp.IsStartrackProposal__c == ''){
					haserrorMessages = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,System.Label.APT_AmendRenewal_StarTrackField));
					return null;
				}
				if(opp.IsStartrackProposal__c != null && opp.IsStartrackProposal__c == APT_Constants.OPTION_YES && (opp.APTPostcodeSuburb__c == null || opp.APTMinimumMonthlySpend__c == null)){
					haserrorMessages = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,System.Label.Yes_Its_StarTrackProduct));
					return null;
				}
			}

			//defect 1336
			agreement.APT_SelectedContractAmendRenewCategory__c = selectedCategory;
			agreement.APT_Require_Customer_Signature__c = bRequireCustomerSignature;

			update agreement;
			//defect 1336

			if(bCreateQuote && bCreateAgreement ) {
				haserrorMessages = true;
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_SETTING_NOT_CONFIGURED));
				return null;
			} else if(!bCreateOpportunity && !bCreateQuote && !bCreateAgreement) {
				haserrorMessages = true;
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_SETTING_NOT_CONFIGURED));
				return null;
			} else if(bCreateCase) {
				haserrorMessages = true;
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_SETTING_NOT_CONFIGURED));
				return null;
			} 

			//create opportunity
			String opportunityId;
			if(bCreateOpportunity) {
				if(agreement != null && !String.isEmpty(agreement.Apttus__Related_Opportunity__c)) {
					/* Shashwat.Nath@Auspost.com has added the below if else condition to make sure that new opportunity is
					 created for the renewal only if user has not selected any existing opportunity to associate the renewal with
					 after clicking on "Renew" button on Apttus Contract Record */

					if(String.isBlank(oppId) || (!String.isBlank(oppId) && String.isBlank(oppName))){
						Opportunity clonedOpportunity = APT_AmendRenewUtility.cloneOpporunity(agreement, APT_Constants.ACTION_TYPE_RENEWAL);
						insert clonedOpportunity;
						opportunityId = clonedOpportunity.Id;
					}
					else{
						/* Setting the opportunity Id to the Existing opportunity which User has selected to associate the renewal after clicking
						 Renew button on Apttus Contract detail Page */
						opportunityId = string.escapeSingleQuotes(oppId);
						//Link the original Opportunity to this Existing opportunity which user has selected
						Opportunity existingOpportunity = new Opportunity();
						//Setting the Opportunity Id
						existingOpportunity.id = string.escapeSingleQuotes(oppId);
						// Linking the Existing Opportunity with Original Opportunity Which is Associated to Apttus Contract from where the DOV Was Started
						existingOpportunity.ECLM_Original_Opportunity_No__c = agreement.Apttus__Related_Opportunity__c;
						//Update existing Opportunity
						update existingOpportunity;
					}

					/*Shashwat.Nath@Auspost .com code ends */
					/*
					list<OpportunityLineItem> listOpportunityLineItem = [SELECT Id, Name, Description, OpportunityId, PriceBookEntryId,
																			Quantity, UnitPrice, Subtotal, Classification__c,
																			Sub_Classification__c, Contract_End_Date__c, Contract_Start_Date__c,
																			ProdClassFieldUpdate__c
																			FROM OpportunityLineItem
																			WHERE opportunityId = :agreement.Apttus__Related_Opportunity__c];

					if(listOpportunityLineItem != null && listOpportunityLineItem.size() > 0) {
						list<OpportunityLineItem> listClonedOpportunityLineItem = APT_AmendRenewUtility.cloneOpporunityProducts(clonedOpportunity.Id, agreement, listOpportunityLineItem, APT_Constants.ACTION_TYPE_RENEWAL);
						insert listClonedOpportunityLineItem;
					}*/
				} else {
					 // Create a new Opportunity only if user has not selected an existing opportunity to associate the Renewal to
							if(String.isBlank(oppId) || (!String.isBlank(oppId) && String.isBlank(oppName))){
								//new opportunity
								Opportunity newOpportunity = APT_AmendRenewUtility.newOpportunity(agreement, APT_Constants.ACTION_TYPE_RENEWAL);
								insert newOpportunity;
								opportunityId = newOpportunity.Id;
							}
							// Assign the existing opportunity Id which user has selected to assosiate the renewal to
							else{
								 opportunityId = string.escapeSingleQuotes(oppId);
							}
					}
			}

			//redirect to opportunity
			if(bCreateOpportunity && !bCreateQuote && !bCreateAgreement) {
				Opportunity opty = new Opportunity();
				opty.id = opportunityId;
				return new ApexPages.StandardController(opty).View();
			}

			//create quote
			String proposalId;
			if(bCreateQuote) {
				//default price list id
				APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
				String priceListId;
				if(r2tSystemProperty != null && !String.isEmpty(r2tSystemProperty.APT_Default_Price_List_ID__c)) {
					priceListId = r2tSystemProperty.APT_Default_Price_List_ID__c;
				} else {
					Database.rollback(sp);
					haserrorMessages = true;
					ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_MISSING_DEFAULT_PRICE));
					return null;
				}

				if(agreement != null && !String.isEmpty(agreement.Apttus_QPComply__RelatedProposalId__c)) {
					//clone proposal
					Apttus_Proposal__Proposal__c clonedProposal = APT_AmendRenewUtility.cloneProposal(APT_Constants.RECORD_TYPE_RENEWAL_QUOTE, opportunityId, priceListId, agreement);
					insert clonedProposal;

					//proposalId = clonedProposal.Id;

					//copy configuration PST
					Boolean bResult = APT_AmendRenewUtility.copyConfiguration(agreement.Apttus_QPComply__RelatedProposalId__c, clonedProposal.Id);

					if(!bResult) {
						Database.rollback(sp);
						haserrorMessages = true;
						ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_COPY_CONFIG_FIELDS ));
						return null;
					}

					//copy proposal child records PST
					bResult = APT_AmendRenewUtility.copyProposalChildRecords(agreement.Apttus_QPComply__RelatedProposalId__c, clonedProposal.Id, agreement.Included_Product_Lines__c, APT_Constants.ACTION_NAME_RENEW, clonedProposal.APT_Contract_Id__c);
					//bResult = Apttus_QPConfig.QPConfigWebService.copyProductConfiguration(agreement.Apttus_QPComply__RelatedProposalId__c, clonedProposal.Id);

					if(!bResult) {
						Database.rollback(sp);
						haserrorMessages = true;
						ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_COPY_PROPOSAL_CHILD_FAILED));
						return null;
					}

					//Deleting International Digital Bundle(Start)
					Id renewalRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Renewal Quote').getRecordTypeId();
					Id amendRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Amendment Quote').getRecordTypeId();

					List<Apttus_Config2__LineItem__c> ltli1 = new List<Apttus_Config2__LineItem__c>();
					ltli1 = [SELECT Id,Apttus_Config2__ConfigurationId__c,
							APT_International_PCMS_or_CSP__c,Apttus_Config2__ProductId__r.ProductCode,
							Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c,
							Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.RecordTypeId,
							Apttus_Config2__LineNumber__c,Apttus_Config2__ConfigurationId__r.id
					FROM Apttus_Config2__LineItem__c WHERE
					Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c =: clonedProposal.Id AND APT_International_PCMS_or_CSP__c =: APT_Constants.PRODUCT_DETAILS_PCMS AND Apttus_Config2__ProductId__r.ProductCode =: APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE AND
					(Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.RecordTypeId =: renewalRecordTypeId OR Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.RecordTypeId =: amendRecordTypeId) LIMIT 1];


					if(!ltli1.isEmpty()){
						/*Apttus_CPQApi.CPQ.RemoveBundleRequestDO request = new Apttus_CPQApi.CPQ.RemoveBundleRequestDO();
						request.CartId = ltli1[0].Apttus_Config2__ConfigurationId__r.id;
						request.LineNumber = ltli1[0].Apttus_Config2__LineNumber__c;
						//Apttus_CPQApi.CPQ.RemoveBundleResponseDO response = Apttus_CPQApi.CPQWebService.removeBundle(request);*/

						PageReference pageRef = Page.APT_DeleteLegacyIntDigitalBundle;
						pageRef.getParameters().put(APT_Constants.CONFIGID,ltli1[0].Apttus_Config2__ConfigurationId__r.id);
						pageRef.getParameters().put(APT_Constants.BUNDLELINENO,string.ValueOf(ltli1[0].Apttus_Config2__LineNumber__c));
						pageRef.getParameters().put(APT_Constants.PROPOSALID,clonedProposal.Id);
						return pageRef;
					}else{

						//Deleting International Digital Bundle(End)

						//redirect to cart
						PageReference pageRef = Page.Apttus_QPConfig__ProposalConfiguration;
						//pageRef.setRedirect(true);
						pageRef.getParameters().put(APT_Constants.PARAM_ID, clonedProposal.Id);
						pageRef.getParameters().put(APT_Constants.PARAM_IS_ASSET_DISABLED, APT_Constants.BOOLEAN_TRUE);
						pageRef.getParameters().put(APT_Constants.PARAM_USE_ADVANCED_APPROVAL, APT_Constants.BOOLEAN_TRUE);
						pageRef.getParameters().put(APT_Constants.PARAM_FLOW, APT_Constants.FLOW_RENEW_FLOW);
						//pageRef.getParameters().put(APT_Constants.PARAM_FLOW, APT_Constants.FLOW_RENEW_FLOW);

						//1165
						//pageRef.getParameters().put(APT_Constants.CONTRACT_NUMBER_PARM, clonedProposal.APT_Contract_Id__c);
						//1165

						//return null;
						return pageRef;
						//return new PageReference(Page.Apttus_QPConfig__ProposalConfiguration.getURL()+'?Id='+clonedProposal.Id+'&isAssetDisabled=true&useAdvancedApproval=true&flow=RenewalQuote');
					}
				} else {
					//new proposal
					Apttus_Proposal__Proposal__c newProposal = APT_AmendRenewUtility.newProposal(APT_Constants.RECORD_TYPE_RENEWAL_QUOTE,
							opportunityId, priceListId, agreement);
					insert newProposal;
					//proposalId = newProposal.Id;

					//redirect to quote
					//return new ApexPages.StandardController(newProposal).View();
					PageReference pageRef = Page.Apttus_QPConfig__ProposalConfiguration;
					pageRef.setRedirect(true);
					pageRef.getParameters().put(APT_Constants.PARAM_ID, newProposal.Id);
					pageRef.getParameters().put(APT_Constants.PARAM_IS_ASSET_DISABLED, APT_Constants.BOOLEAN_TRUE);
					pageRef.getParameters().put(APT_Constants.PARAM_USE_ADVANCED_APPROVAL, APT_Constants.BOOLEAN_TRUE);
					pageRef.getParameters().put(APT_Constants.PARAM_FLOW, APT_Constants.FLOW_RENEW_FLOW);

					//1165
					//pageRef.getParameters().put(APT_Constants.CONTRACT_NUMBER_PARM, newProposal.APT_Contract_Id__c);
					//1165

					return pageRef;
					//return new PageReference('/' + newProposal.Id);
				}
			}
			//create agreement
			if(bCreateAgreement) {
				//renew agreement
				Apttus__APTS_Agreement__c renewedAgreement = APT_AmendRenewUtility.renewAgreement(APT_Constants.RECORD_TYPE_RENEWAL_CONTRACT,
						opportunityId, proposalId, agreement);
				insert renewedAgreement;

				//build relationship with original agreement
				Boolean bResult = APT_AmendRenewUtility.afterRenew(agreement.Id, renewedAgreement.Id, false);
				if(!bResult) {
					Database.rollback(sp);
					haserrorMessages = true;
					ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.RENEWAL_AGREEMENT_FAILED));
					return null;
				} else {
					//redirect to renewed agreement

					return new ApexPages.StandardController(renewedAgreement).View();
					//return new PageReference('/' + renewedAgreement.Id);
				}
			}


			//redirect to existing agreement
			Apttus__APTS_Agreement__c agreement2 = new Apttus__APTS_Agreement__c();
			agreement2.id = agreementId;
			return new ApexPages.StandardController(agreement2).View();
			//return new PageReference('/' + agreementId );
		} catch(System.Exception ex) {
			Database.rollback(sp);
			haserrorMessages = true;
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}
		return null;
	}

	/**
	 * Processes the ammendment request
	 * */
	public PageReference doAmend() {
		Savepoint sp = Database.setSavepoint();
		try {
			// Added by Adrian Recio to disable trigger cloning
			AgreementToSFContractTriggerHandler.disableCloning = true;
			if(selectedCategory.equalsIgnoreCase(APT_Constants.SELECT_OPTION_NONE)) {
				haserrorMessages = true;
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_SELECT_CATEGORY));
				return null;
			}

			// CR 146 Enhancement - August 7, 2018 - conrad.c.v.borbon - START
			if(selectedCategory.equalsIgnoreCase(CATEGORY_DOV_PROPANDCONTR) && selectedRevenue.equalsIgnoreCase(APT_Constants.SELECT_OPTION_NONE)) {
				haserrorMessages = true;
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERROR_SELECT_REVENUE));
				return null;
			}

			/* Shashwat.Nath@auspost.com has added the below if condition display an error on page if user does not selects a
			 DOV reason after selecting the Revenue Type Picklist as Increase Revenue */
			/* Modified By: Mansi Shah - commented the below code as we are not showing DoV Reason on this page anymore as per User Story - STP-5134*/

			/*if(selectedCategory.equalsIgnoreCase(CATEGORY_DOV_PROPANDCONTR) && 'Increase Revenue'.equalsIgnoreCase(selectedRevenue)
				&& selectedReason.equalsIgnoreCase(APT_Constants.SELECT_OPTION_NONE)) {
				haserrorMessages = true;
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERROR_SELECT_REASON ));
				return null;
			}*/



			/* Shashwat.Nath@Auspost.com has added the below code to check if the selected opportunity has an associated proposal which is primary
			 then display an error to user and do not allow them to proceed further with that opportunity */
			if(!String.isBlank(oppId)){
				//Iterating over the open Opportunity list for the same revenue type within the same organisation as Active Contract
				for(Opportunity opportunityRecord :oppList){
					// Display error if the selected opportunity is already having a primary proposal
					if(!opportunityRecord.R00N70000001yUfDEAU__r.isEmpty() && opportunityRecord.id==oppId){
						haserrorMessages = true;
						ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, LABEL.OpportunityHasPrimayProposal));
						return null;
					 }
				 }
			 }

			/*Shashwat.Nath@auspost.com.au code ends */

			// CR 146 Enhancement - August 7, 2018 - conrad.c.v.borbon - END

			boolean bCreateCase = false;
			boolean bCreateOpportunity = false;
			boolean bCreateQuote = false;
			boolean bCreateAgreement = false;
			boolean bRequireCustomerSignature = false; //defect 1336

			if( !String.isEmpty(actionName) && actionName.equalsIgnoreCase(APT_Constants.ACTION_NAME_DoV )) {
				list<APT_R2T_Renew_DoV_Properties__c> listR2TRenewDoVProperties = APT_R2T_Renew_DoV_Properties__c.getall().values();
				if(listR2TRenewDoVProperties != null && listR2TRenewDoVProperties.size() > 0){
					for(APT_R2T_Renew_DoV_Properties__c renewDovProperty : listR2TRenewDoVProperties) {
						if( !String.isEmpty(renewDovProperty.APT_Type__c) && renewDovProperty.APT_Type__c.equalsIgnoreCase(APT_Constants.ACTION_NAME_DoV )
								&& !String.isEmpty(renewDovProperty.APT_Category__c) && renewDovProperty.APT_Category__c.equalsIgnoreCase(selectedCategory)) {

							bCreateCase = renewDovProperty.APT_Create_Case__c;
							bCreateQuote = renewDovProperty.APT_Create_Quote__c;
							bCreateAgreement = renewDovProperty.APT_Create_Agrement__c;
							bCreateOpportunity = renewDovProperty.APT_Create_Opportunity__c;
							bRequireCustomerSignature = renewDovProperty.APT_Require_Customer_Signature__c; //defect 1336
						}
					}
				}
			}
			if(bCreateQuote && bCreateAgreement) {
				haserrorMessages = true;
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_SETTING_NOT_CONFIGURED));
				return null;
			} else if(bCreateCase && (bCreateQuote || bCreateAgreement)) {
				haserrorMessages = true;
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_SETTING_NOT_CONFIGURED));
				return null;
			} 

			// 28/05/2020 LJ conditional query - SOQL 101 Error FIX
			if ( agreement == null || agreement.Id != agreementId) {
				agreement = [
						SELECT Id, Name, Apttus__Related_Opportunity__c, Apttus_QPComply__RelatedProposalId__c,
								Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c, APT_Contract_Number__c,
								Apttus__Primary_Contact__c, Apttus__Account__c, Apttus__FF_Agreement_Number__c,
								Apttus_QPComply__RelatedProposalId__r.Apttus_Proposal__Proposal_Name__c, Included_Product_Lines__c,
								Apttus_QPComply__RelatedProposalId__r.APT_Method_of_Payment__c,
								APT_SelectedContractAmendRenewCategory__c, APT_Require_Customer_Signature__c
						FROM Apttus__APTS_Agreement__c
						WHERE Id = :agreementId
				];
			}

			if(agreement != null && agreement.Apttus__Related_Opportunity__c != null && oppId == null){
				//fetching the opportunity record by using selector
				map<Id,Opportunity> oppMap = OpportunitySelector.newInstance(0,new Set<SObjectField>{opportunity.IsStartrackProposal__c,opportunity.APTPostcodeSuburb__c,opportunity.APTMinimumMonthlySpend__c}).selectById(new Set<Id>{agreement.Apttus__Related_Opportunity__c});
				Opportunity opp = oppMap.get(agreement.Apttus__Related_Opportunity__c);
				//Checking the value for StarTrack Opportunity to show an error mesaage
				if(opp.IsStartrackProposal__c == null || opp.IsStartrackProposal__c == ''){
					haserrorMessages = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,System.Label.APT_AmendRenewal_StarTrackField));
					return null;
				}
				if(opp.IsStartrackProposal__c != null && opp.IsStartrackProposal__c == APT_Constants.OPTION_YES && (opp.APTPostcodeSuburb__c == null || opp.APTMinimumMonthlySpend__c == null)){
					haserrorMessages = true;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,System.Label.Yes_Its_StarTrackProduct));
					return null;
				}
			}
			//defect 1336
			agreement.APT_SelectedContractAmendRenewCategory__c = selectedCategory;
			agreement.APT_Require_Customer_Signature__c = bRequireCustomerSignature;

			update agreement;
			//defect 1336

			//create case
			//create case
			if(bCreateCase) {
				PageReference pageRef = Page.APT_CreateCase;
				pageRef.setRedirect(true);
				pageRef.getParameters().put(APT_Constants.PARAM_AGREEMENT_ID, agreement.Id);
				pageRef.getParameters().put(APT_Constants.PARAM_SELECTED_CATEGORY, selectedCategory);
				return pageRef;
				//return new PageReference('/apex/APT_CreateCase?agreementId='+agreement.Id+'&selectedCategory='+selectedCategory);
			}

			//create opportunity
			String opportunityId;
			if(bCreateOpportunity) {
				if(agreement != null && !String.isEmpty(agreement.Apttus__Related_Opportunity__c)) {
					//CR-148/13 Start
					//Added By Lyndon Lavapie
					//Assign the Original oppty as related oppty if decrease revenue type
					/* Shashwat.Nath@Auspost.com Commented the below line of code where for Decrease in Revenue would associate the new Proposal to
					 original Opportunity . However going forward even Decrease in Revenue would create either a new opportunity from original Opportunity
					 or would link the DOV to an existing Opportunity which is selected by User */
					/*if(selectedRevenue == APT_AmendRenewController.DECREASE_REVENUE){
						opportunityId = agreement.Apttus__Related_Opportunity__c;
					}*/

					/* Shashwat.Nath code commenting ends */
					//Clone Oppty
					//else{//if(selectedRevenue == 'Increase Revenue')
						//clone opportunit

						/*Shashwat.Nath@Auspost.com Added below if else condition to differentiate the process between new Opportunity creation vs
						 Linking the DOV with an existing Opportunity . If block code would fire when user goes with new opportunity Creation for
						 DOV and else block would run when User selects an existing Opportunity to associate the DOV with */
						/* STP-3031: krishna.velani@auspost.com.au added logic to update Opportunity subtype for Increase and Decrease Revenue */
						if(String.isBlank(oppId) || (!String.isBlank(oppId) && String.isBlank(oppName))){

							// When user has selected Increase in Revenue
							if(INCREASE_REVENUE.equalsIgnoreCase(selectedRevenue)){
								Opportunity clonedOpportunity = new Opportunity();
								clonedOpportunity = APT_AmendRenewUtility.cloneOpporunity(agreement, APT_Constants.ACTION_NAME_DoV_Increase);
								clonedOpportunity.APT_Revenue_Decrease__c = 0;
								//Modified By: Mansi Shah - commented the below code as we are not showing DoV Reason on this page anymore as per User Story - STP-5134
								//clonedOpportunity.DOV_Reason__c = selectedReason ;
								clonedOpportunity.Opportunity_SubType__c = 'DoV Increase';
								insert clonedOpportunity;
								opportunityId = clonedOpportunity.Id;
							}
							// When User Selects Decrease in Revenue
							else If(DECREASE_REVENUE.equalsIgnoreCase(selectedRevenue)){
								// In case of Decrease Revenue Assigning Original Opportunity Id as It should not Create New Opp
								 opportunityId = agreement.Apttus__Related_Opportunity__c;
								 List<Opportunity> existingopportunitiesToBeUpdated = new List<Opportunity>();
								 Opportunity existingOppty = new Opportunity();
								 existingOppty.id = opportunityId;
								 existingOppty.Opportunity_SubType__c = 'DoV Decrease';
								 existingopportunitiesToBeUpdated.add(existingOppty);
								 database.update(existingopportunitiesToBeUpdated,false);
							}

						}
						else{
							List<Opportunity> opportunitiesToBeUpdated = new List<Opportunity>();
							// Creating Opportunity Instance to Update the Existing Opportunity.
							Opportunity existingOpportunity = new Opportunity();
							//Setting the Opportunity Id
							existingOpportunity.id = string.escapeSingleQuotes(oppId);
							// Linking the Existing Opportunity with Original Opportunity Which is Associated to Apttus Contract from where the DOV Was Started
							existingOpportunity.ECLM_Original_Opportunity_No__c = agreement.Apttus__Related_Opportunity__c;
							// Setting the DOV Reason on Existing Opportunity
							//Modified By: Mansi Shah - commented the below code as we are not showing DoV Reason on this page anymore as per User Story - STP-5134
							//existingOpportunity.DOV_Reason__c = selectedReason ;
							// Setting the Opportunity Subtype based on Revenue type
							if(INCREASE_REVENUE.equalsIgnoreCase(selectedRevenue))
								{existingOpportunity.Opportunity_SubType__c= 'DoV Increase';}
							else if (DECREASE_REVENUE.equalsIgnoreCase(selectedRevenue))
								{existingOpportunity.Opportunity_SubType__c= 'DoV Decrease';}

							// Adding to the list
							opportunitiesToBeUpdated.add(existingOpportunity);

							// Setting the Opportunity id Variable to the id of the Existing opportunity to be later used during the creation of new proposal
							opportunityId = string.escapeSingleQuotes(oppId);

							//Updating the opportunities
							List<Database.SaveResult> result = database.update(opportunitiesToBeUpdated,false);
						}
				 // }
					//End
				} else {
					 // Create a new Opportunity only if user has not selected an existing opportunity to associate the Renewal to
							if(String.isBlank(oppId) || (!String.isBlank(oppId) && String.isBlank(oppName))){
								//new opportunity
								Opportunity newOpportunity = APT_AmendRenewUtility.newOpportunity(agreement, APT_Constants.ACTION_NAME_DoV_Increase);
								insert newOpportunity;
								opportunityId = newOpportunity.Id;
							}
							// Assign the existing opportunity Id which user has selected to assosiate the DoV with
							else{
								 opportunityId = string.escapeSingleQuotes(oppId);
							}
					}
			}

			if(bCreateOpportunity && !bCreateQuote && !bCreateAgreement) {
				Opportunity opty = new Opportunity();
				opty.ID = opportunityId;
				return new ApexPages.StandardController(opty).View();
				//return new PageReference('/'+opportunityId);
			}

			//create quote
			String proposalId;
			if(bCreateQuote) {
				//default price list id
				APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
				String priceListId;
				if(r2tSystemProperty != null && !String.isEmpty(r2tSystemProperty.APT_Default_Price_List_ID__c)) {
					priceListId = r2tSystemProperty.APT_Default_Price_List_ID__c;
				} else {
					Database.rollback(sp);
					haserrorMessages = true;
					ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_MISSING_DEFAULT_PRICE));
					return null;
				}

				if(agreement != null && !String.isEmpty(agreement.Apttus_QPComply__RelatedProposalId__c)) {
					//clone proposal
					Apttus_Proposal__Proposal__c clonedProposal = APT_AmendRenewUtility.cloneProposal(APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE, opportunityId,
							priceListId, agreement);

					//1084
					clonedProposal.APT_DoV_Category__c = selectedCategory;
					//1084

					// Adde by Conrad Borbon
					// Statement will assign selected revenue type to proposal field revenue type
					clonedProposal.APT_Revenue_Type__c = selectedRevenue;
					insert clonedProposal;

					/*
					Commented this for QC-1584
					clonedProposal.Apttus_Proposal__Proposal_Expiration_Date__c= clonedProposal.Expected_Revenue_End_Date__c;
					update clonedProposal;*/


					//copy configuration
					Boolean bResult = APT_AmendRenewUtility.copyConfiguration(agreement.Apttus_QPComply__RelatedProposalId__c, clonedProposal.Id);
					if(!bResult) {
						Database.rollback(sp);
						haserrorMessages = true;
						ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_COPY_CONFIG_FIELDS));
						return null;
					}

					//copy proposal child records
					bResult = APT_AmendRenewUtility.copyProposalChildRecords(agreement.Apttus_QPComply__RelatedProposalId__c, clonedProposal.Id, agreement.Included_Product_Lines__c, APT_Constants.ACTION_NAME_AMEND, clonedProposal.APT_Contract_Id__c);
					if(!bResult) {
						Database.rollback(sp);
						haserrorMessages = true;
						ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_COPY_PROPOSAL_CHILD_FAILED));
						return null;
					}

					//Deleting International Digital Bundle(Start)
					/* Id renewalRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Renewal Quote').getRecordTypeId();
						 Id amendRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Amendment Quote').getRecordTypeId();
			 List<Apttus_Config2__LineItem__c> ltli1 = new List<Apttus_Config2__LineItem__c>();
				ltli1 = [SELECT Id,Apttus_Config2__ConfigurationId__c,
													 APT_International_PCMS_or_CSP__c,Apttus_Config2__ProductId__r.ProductCode,
													 Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c,
													 Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.RecordTypeId,
													 Apttus_Config2__LineNumber__c,Apttus_Config2__ConfigurationId__r.id
													 FROM Apttus_Config2__LineItem__c WHERE
				Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c =: clonedProposal.Id AND APT_International_PCMS_or_CSP__c =: APT_Constants.PRODUCT_DETAILS_PCMS AND Apttus_Config2__ProductId__r.ProductCode =: APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE AND
				(Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.RecordTypeId =: renewalRecordTypeId OR Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.RecordTypeId =: amendRecordTypeId) LIMIT 1];


				 if(!ltli1.isEmpty()){
					Apttus_CPQApi.CPQ.RemoveBundleRequestDO request = new Apttus_CPQApi.CPQ.RemoveBundleRequestDO();
				 request.CartId = ltli1[0].Apttus_Config2__ConfigurationId__r.id;
				 request.LineNumber = ltli1[0].Apttus_Config2__LineNumber__c;
				 Apttus_CPQApi.CPQ.RemoveBundleResponseDO response = Apttus_CPQApi.CPQWebService.removeBundle(request);

				 }*/




					//Deleting International Digital Bundle(End)

					//redirect to cart
					PageReference pageRef = Page.Apttus_QPConfig__ProposalConfiguration;
					pageRef.setRedirect(true);
					pageRef.getParameters().put(APT_Constants.PARAM_ID, clonedProposal.Id);
					pageRef.getParameters().put(APT_Constants.PARAM_IS_ASSET_DISABLED, APT_Constants.BOOLEAN_TRUE);
					pageRef.getParameters().put(APT_Constants.PARAM_USE_ADVANCED_APPROVAL, APT_Constants.BOOLEAN_TRUE);
					pageRef.getParameters().put(APT_Constants.PARAM_FLOW, APT_Constants.FLOW_RENEW_FLOW);

					//1165
					//pageRef.getParameters().put(APT_Constants.CONTRACT_NUMBER_PARM, clonedProposal.APT_Contract_Id__c);
					//1165

					return pageRef;
					//return new PageReference(Page.Apttus_QPConfig__ProposalConfiguration.getURL()+'?Id='+clonedProposal.Id+'&isAssetDisabled=true&useAdvancedApproval=true&&flow=RenewalQuote');
				} else {
					Apttus_Proposal__Proposal__c newProposal = APT_AmendRenewUtility.newProposal(APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE,
							opportunityId, priceListId, agreement);
					insert newProposal;
					//proposalId = newProposal.Id;

					//redirect to cart
					String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
					baseURL += APT_Constants.STRING_URL_PROPOSAL_CART + newProposal.Id + APT_Constants.STRING_URL_AMEND_QUOTE_CART;
					PageReference pageRef = new PageReference(baseURL);
					pageRef.setRedirect(true);
					return pageRef;
				}
			}

			//create agreement
			if(bCreateAgreement) {
				//renew agreement
				Apttus__APTS_Agreement__c amendedAgreement = APT_AmendRenewUtility.amendAgreement(APT_Constants.RECORD_TYPE_DOV_CONTRACT,
						opportunityId, null, agreement, APT_Constants.ACTION_NAME_AMEND);

				//1084
				amendedAgreement.APT_Mark_All_Agreement_Line_Items_as_Old__c = true;
				//1084

				insert amendedAgreement;
				//build relationship with original agreement
				Boolean bResult = APT_AmendRenewUtility.afterAmend(agreement.Id, amendedAgreement.Id, false);

				if(!bResult) {
					Database.rollback(sp);
					haserrorMessages = true;
					ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.AMEND_AGREEMENT_FAILED));
					return null;
				} else {
					//redirect to renewed agreement
					return new ApexPages.StandardController(amendedAgreement).View();
					//return new PageReference('/' + amendedAgreement.Id);
				}
			}

		} catch(System.Exception ex) {
			Database.rollback(sp);
			haserrorMessages = true;
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}

		return null;
	}
}