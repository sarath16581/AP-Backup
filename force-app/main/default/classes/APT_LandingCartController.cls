/*@author Nasir Jawed
*@date 2023-02-13
*@tag Apex Class
*@tag Proposal creation
*@domain Core
*@description A class which creates Proposal when a button "Add Product" is clicked from the
		opportunity page which is called form lightning "aPT_AddProductLWC" class
*@changelog
*2023-02-28 Bharat Patel : Replace hard-code values from code (coding standard practice)
*2023-07-24 Nasir Jawed : Added new picklist value "Accepted without proposal document" to the condition, so that new proposal can be created when status is "Accepted without proposal document".
*2023-07-27 Nasir Jawed : Added error code related to Access to BG Base user.
*2023-09-07 Bharat Patel : Added error code related to Access to Onboarding User.
*2023-11-15 Bharat Patel : Added logic related to Sales's Specialist, validationCheck()
*/
public with sharing class APT_LandingCartController {
	/**
	*This method gets calling from aPT_AddProductLwc lightning and is used to create a proporsal when "Add Product" button gets clicked from opportunity.
	*@param String OpportunityId
	*@return proposal Id and Flow
	*/
	@AuraEnabled
	public static string validationCheck(ID recordId){
		auraHandledException exceptionHandler;
		id userProfileID = userinfo.getProfileId();
		id proposalId;
		string returnValue;
		Id opportunityOwnerId;
		string profileName;
		Id loggedInUserId;
		string readWritePermisssion = 'false';
		//getting the profile id of current user
		map<Id,Profile>  getProfile = ProfilesSelector.newInstance(1).selectById(new Set<Id>{userProfileID});
		profile p = getProfile.get(userProfileID);
		profileName = getProfile.get(userProfileID).name;
		loggedInUserId = UserInfo.getUserId();
		List<Apttus_Proposal__Proposal__c> proposalList = new List<Apttus_Proposal__Proposal__c>();
		Apttus_Proposal__Proposal__c proposal;
		List<Database.SaveResult> proposalInsert = new List<Database.SaveResult>();
		boolean proposalExist=APT_Constants.BOOL_FALSE;
		map<Id,Opportunity> oppMap = new map<Id,Opportunity>();

		//Fetching recordTypeid for diffrent record Types
		string proposalRecordId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
		string renewalQuoteRecordId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Renewal Quote').getRecordTypeId();
		string amendmentQuoteRecordId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Amendment Quote').getRecordTypeId();

		try {
			if(recordId != null){
				List<UserRole> userRolesList = UserRolesSelector.newInstance().selectById(new Set<Id>{UserInfo.getUserRoleId()}).values();
				Boolean isSalesSpecialist = false;
				if(!userRolesList.isEmpty())
				{
					List<APT_Sales_Specialist_Role__mdt> salesSpecialistRole = [SELECT Id, MasterLabel FROM APT_Sales_Specialist_Role__mdt WHERE MasterLabel =: userRolesList[0].Name];
					if(!salesSpecialistRole.isEmpty()){
						isSalesSpecialist = true;
					}
				}

				oppMap = OpportunitySelector.newInstance().selectById(new Set<Id>{recordId});
				Opportunity opp = oppMap.get(recordId);
				opportunityOwnerId = oppMap.get(recordId).OwnerId;

				if(cartIsAccessible(opportunityOwnerId, loggedInUserId, profileName, isSalesSpecialist))
				{
					readWritePermisssion = 'true';
				}
				else{
					readWritePermisssion = 'false';
					exceptionHandler = new AuraHandledException(System.Label.Abandon_Shopping_Cart_Error);
					exceptionHandler.setMessage(System.Label.Abandon_Shopping_Cart_Error);
					throw exceptionHandler;
				}
				if(readWritePermisssion == 'true'){
				//Checking error condition as per business requirement
				//USer should not be permitted to create proposal if IsStartrackProposal__c field is empty or null
				if(opp.IsStartrackProposal__c == '' || opp.IsStartrackProposal__c == null){
					exceptionHandler = new AuraHandledException(System.Label.isStarTrackProduct);
					exceptionHandler.setMessage(System.Label.isStarTrackProduct);
					throw exceptionHandler;
				}
				//User should not be permitted to create proposal if KeyContact field is blank or null
				if(opp.KeyContact__c == null){
					exceptionHandler = new AuraHandledException(System.Label.KeyContactError);
					exceptionHandler.setMessage(System.Label.KeyContactError);
					throw exceptionHandler;
				}
				//User should not be permitted to create proposal if stagename field is 'closed Lost'
				if(opp.stagename == APT_Constants.OPPORTUNITY_STAGENAME_CLOSED_LOST && opp.stagename != null ){
					exceptionHandler = new AuraHandledException(System.Label.Add_Product_On_Closed_Opportunity);
					exceptionHandler.setMessage(System.Label.Add_Product_On_Closed_Opportunity);
					throw exceptionHandler;
				}
				//User should not be permitted to create proposal if IsStartrackProposal__c field is 'yes' and APTPostcodeSuburb__c ,APTMinimumMonthlySpend__c are blank or null
				if(opp.IsStartrackProposal__c != null && opp.IsStartrackProposal__c == APT_Constants.OPTION_YES && (opp.APTPostcodeSuburb__c == null || opp.APTMinimumMonthlySpend__c == null)){
					exceptionHandler = new AuraHandledException(System.Label.Yes_Its_StarTrackProduct);
					exceptionHandler.setMessage(System.Label.Yes_Its_StarTrackProduct);
					throw exceptionHandler;
				}
				//User should be able to create proposal if field IsStartrackProposal__c is having values and stagename field is not 'closed Lost'
				if(opp.IsStartrackProposal__c == APT_Constants.OPTION_NO  && opp.stagename != APT_Constants.OPPORTUNITY_STAGENAME_CLOSED_LOST){
					proposal = createProposalRecord(opp,profileName,loggedInUserId, isSalesSpecialist, opportunityOwnerId);
					proposalList.add(proposal);
				}
				//User should be able to create proposal if IsStartrackProposal__c is yes and  field APTMinimumMonthlySpend__c and APTPostcodeSuburb__c having values'
				if(opp.IsStartrackProposal__c == APT_Constants.OPTION_YES && opp.APTPostcodeSuburb__c != null && opp.APTMinimumMonthlySpend__c != null && opp.stagename != APT_Constants.OPPORTUNITY_STAGENAME_CLOSED_LOST){
						proposal = createProposalRecord(opp,profileName,loggedInUserId, isSalesSpecialist, opportunityOwnerId);
					proposalList.add(proposal);
				}
			}

			}
			//Querying the proposal record by using the proposal id returned from the method createProposalRecord().
			List<Apttus_Proposal__Proposal__c> existingProposalRedirect = APT_ProposalObjectsSelector.newInstance().selectByConfigIds(new Set<Id>{proposal.id});

			if(existingProposalRedirect != null && existingProposalRedirect.size()> 0){
				if( existingProposalRedirect[0].Apttus_Proposal__Primary__c == APT_Constants.BOOL_TRUE  && (existingProposalRedirect[0].Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_ACCEPTED) || (existingProposalRedirect[0].Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_DENIED) || (existingProposalRedirect[0].Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_ACCEPTED_WITHOUT_PROP_DOC)){
					proposalExist= APT_Constants.BOOL_TRUE;
					proposalID = existingProposalRedirect[0].id;

					if(opportunityOwnerId == loggedInUserId) {
						List<Apttus_Config2__ProductConfiguration__c>  prodConfig = ProductConfigurationSelector.newInstance().selectByProposalId(new Set<Id>{proposal.id});
						if(prodConfig.size() > 0){
							if(configurationCheck(loggedInUserId, prodConfig[0])) {
								Apttus_Config2__ProductConfiguration__c  prodConfigToUpdate = new Apttus_Config2__ProductConfiguration__c();
								prodConfigToUpdate.Id = prodConfig[0].Id;
								prodConfigToUpdate.OwnerId = loggedInUserId;
								ApplicationDatabase.getInstance().dmlUpdate(new List<Apttus_Config2__ProductConfiguration__c>{prodConfigToUpdate});
							}
						}
					}
				}
			}
			else{
				if(proposalList != null) {
					proposalInsert = ApplicationDatabase.getInstance().dmlInsert(proposalList);
					for (Database.SaveResult sr : proposalInsert) {
						if (sr.isSuccess()) {
						proposalID = sr.getId();
						}
					}
				}
			}


			//Checking which flow to use to land to the Catalogue page for the proposal which gets created or the existed proposal.
			if(((proposalId != null || proposalExist== APT_Constants.BOOL_TRUE) && proposal.Apttus_QPConfig__PriceListId__c != null
			&& proposal.Apttus_Proposal__Primary__c == APT_Constants.BOOL_TRUE && proposal.Is_Startrack_Proposal__c != ''
			&& proposal.Apttus_Proposal__Approval_Stage__c !=  APT_Constants.APPROVAL_STAGE_ACCEPTED) ||
			(
			(proposal.Apttus_QPApprov__Approval_Status__c != APT_Constants.APPROVAL_STAGE_APPROVED && proposal.Apttus_QPApprov__Approval_Status__c != null  && proposal.Is_Startrack_Proposal__c != APT_Constants.OPTION_NO && proposal.Is_Startrack_Proposal__c !=null) ||
			(proposal.Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_ACCEPTED && proposal.Apttus_Proposal__Approval_Stage__c != null && proposal.Is_Startrack_Proposal__c != APT_Constants.OPTION_YES && proposal.Is_Startrack_Proposal__c !=null)
			)
			){
				//Redirecting to the New Quote catalogue page depending upon Profile
				if(proposal.recordTypeId == proposalRecordId && p.name != APT_Constants.STRING_PRICING_MANAGEMENT ){
					returnValue = proposalId+'+NewQuote';
					return returnValue;
				}
				//Redirecting to the Approval flow catalogue page depending upon Profile
				if(proposal.recordTypeId == proposalRecordId && p.name == APT_Constants.STRING_PRICING_MANAGEMENT){
					returnValue = proposalId+'+Approvalflow';
					return returnValue;
				}
				//Redirecting to the Approval flow catalogue page depending upon Profile
				if((proposal.recordTypeId == renewalQuoteRecordId || proposal.recordTypeId == amendmentQuoteRecordId) && p.name == APT_Constants.STRING_PRICING_MANAGEMENT){
					returnValue = proposalId+'+Approvalflow';
					return returnValue;
				}
				//Redirecting to the Renewal flow catalogue page depending upon Profile
				if(proposal.recordTypeId == renewalQuoteRecordId || proposal.recordTypeId == amendmentQuoteRecordId){
					returnValue = proposalId+'+RenewalQuote';
					return returnValue;
				}

			}
			return proposalId;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	*This method gets calling from validationCheck fucntion either to create a proposal record of land to the existing proposal record.
	*@param String OpportunityId
	*@return proposal record
	*/
	public Static Apttus_Proposal__Proposal__c  createProposalRecord(opportunity opp,string profileName,ID loggedInUserId, Boolean isSalesSpecialistRole, ID opportunityOwnerId){
		auraHandledException exceptionHandler;
		boolean newProposal= APT_Constants.BOOL_FALSE;
		string proposalRecordId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
		Apttus_Proposal__Proposal__c proposal ;
		List<Apttus_Proposal__Proposal__c> updatePrimaryFalse = new List<Apttus_Proposal__Proposal__c>();
		set<Id> proposalPrimaryTrueId = new set<Id>();
		List<Database.SaveResult> proposalupdatePrimaryfalse = new List<Database.SaveResult>();

		//Querying the proposal record by using the opportunity id passed to the method createProposalRecord() to check if there existing any proposal on the opportunity.
		List<Apttus_Proposal__Proposal__c> existingProposalList = APT_ProposalObjectsSelector.newInstance().selectByOpportunityId(new Set<Id>{opp.id});

		//checking if there is a existing proposal record which status Accepted, Denied and Accepted without proposal document, then update the proposal with Primary to false.
		if(existingProposalList.size() >0){
			for(Apttus_Proposal__Proposal__c existingProposalPrimary: existingProposalList){
				if((existingProposalPrimary.Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_ACCEPTED || existingProposalPrimary.Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_DENIED || existingProposalPrimary.Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_ACCEPTED_WITHOUT_PROP_DOC) && existingProposalPrimary.Apttus_Proposal__Primary__c == APT_Constants.BOOL_TRUE){
					existingProposalPrimary.Apttus_Proposal__Primary__c = APT_Constants.BOOL_FALSE;
					updatePrimaryFalse.add(existingProposalPrimary);
					}else{
						proposalPrimaryTrueId.add(existingProposalPrimary.id);
					}
				}
				//Querying the product config record by using the proposal id to show the error if user don't have access to Prod config.
				if(proposalPrimaryTrueId.size() >0){
					//Querying the product config record by using the proposal id to show the error if user don't have access to Prod config.
					List<Apttus_Config2__ProductConfiguration__c> prodConfig = ProductConfigurationSelector.newInstance().selectByProposalId(proposalPrimaryTrueId);
					Id prodConfigOwnerId;
					Id prodConfigOwnerId2;
					if(prodConfig.size() > 0){
						for(Apttus_Config2__ProductConfiguration__c pc:prodConfig){
							if(pc.Apttus_Config2__Status__c == 'New'){
								prodConfigOwnerId = pc.OwnerId;
							}
							if(pc.Apttus_Config2__Status__c == 'Saved'){
								prodConfigOwnerId2 = pc.OwnerId;
							}
						}
						//Throwing Error message when config owner is not loggedin user and profile is other than system admin
						if(prodConfigOwnerId != null){
							if(cartOwnerCheck(prodConfigOwnerId, loggedInUserId, profileName, isSalesSpecialistRole, opportunityOwnerId)) {
								exceptionHandler = new AuraHandledException(System.Label.Abandon_Shopping_Cart_Error);
								exceptionHandler.setMessage(System.Label.Abandon_Shopping_Cart_Error);
								throw exceptionHandler;
							}
						}
						if(prodConfigOwnerId2 != null){
							if(cartOwnerCheck(prodConfigOwnerId2, loggedInUserId, profileName, isSalesSpecialistRole, opportunityOwnerId)){
								exceptionHandler = new AuraHandledException(System.Label.Abandon_Shopping_Cart_Error);
								exceptionHandler.setMessage(System.Label.Abandon_Shopping_Cart_Error);
								throw exceptionHandler;
							}
						}
					}
				}
				if(updatePrimaryFalse.size()>0){
					proposalupdatePrimaryfalse = ApplicationDatabase.getInstance().dmlupdate(updatePrimaryFalse);
				}
			}else{
				newProposal= APT_Constants.BOOL_TRUE;
			}
			//Checking wheather to create a proposal or land to the existing proposal depending upon the status
			if(newProposal == APT_Constants.BOOL_FALSE){
			List<Apttus_Proposal__Proposal__c> existingProposalListupdated = APT_ProposalObjectsSelector.newInstance().selectByOpportunityId(new Set<Id>{opp.id});

			if(existingProposalListupdated.size() >0){
				for(Apttus_Proposal__Proposal__c existingProposal: existingProposalListupdated){
					if((existingProposal.Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_ACCEPTED || existingProposal.Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_DENIED || existingProposal.Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_ACCEPTED_WITHOUT_PROP_DOC) && existingProposal.Apttus_Proposal__Primary__c == APT_Constants.BOOL_FALSE){
						newProposal= APT_Constants.BOOL_TRUE;
					}
					if((existingProposal.Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_ACCEPTED || existingProposal.Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_DENIED || existingProposal.Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_ACCEPTED_WITHOUT_PROP_DOC) && newProposal == APT_Constants.BOOL_FALSE && existingProposal.Apttus_Proposal__Primary__c == APT_Constants.BOOL_TRUE){
						return existingProposal;
					}
				}
			}
		}
		//Creating a new proposal record with values populated
		if(opp != null && newProposal == APT_Constants.BOOL_TRUE){
			APT_R2T_System_Properties__c r2tSystemPropertiesObj = APT_R2T_System_Properties__c.getOrgDefaults();
			proposal = new Apttus_Proposal__Proposal__c();
			proposal.Apttus_Proposal__Account__c  = opp.AccountID;
			proposal.Apttus_Proposal__Opportunity__c = opp.ID;
			proposal.Is_Startrack_Proposal__c = opp.IsStartrackProposal__c;
			proposal.APT_Postcode_Suburb__c = opp.APTPostcodeSuburb__c;
			proposal.APT_Minimum_Monthly_Spend__c = opp.APTMinimumMonthlySpend__c;
			proposal.Apttus_Proposal__Primary_Contact__c = opp.KeyContact__c;
			proposal.Apttus_Proposal__Proposal_Expiration_Date__c = system.today();
			proposal.APT_Contracting_Entity__c = APT_Constants.STRING_AUSTRALIAN_Postal_Corporation;
			proposal.Apttus_Proposal__Primary__c = APT_Constants.BOOL_TRUE;
			proposal.Apttus_Proposal__Approval_Stage__c =  APT_Constants.QUOTE_TYPE_DRAFT;
			proposal.Apttus_QPApprov__Approval_Status__c =  APT_Constants.SELECT_OPTION_NONE;
			proposal.Apttus_QPConfig__PriceListId__c = r2tSystemPropertiesObj.APT_Default_Price_List_ID__c;
			proposal.recordTypeId = proposalRecordId ;
		}
		return proposal;
	}

	/**
	 *This method will validate the user's accessiblity of shopping cart
	 *@param Id opportunityOwnerId
	 *@param Id loggedInUserId
	 *@param String profileName
	 *@param Boolean isSalesSpecialistRole
	 *@return boolean value
	 */
	private static Boolean cartIsAccessible(Id opportunityOwnerId, Id loggedInUserId, String profileName, Boolean isSalesSpecialistRole) {
		Set<String> profileListCheck = new Set<String>{APT_Constants.STRING_SYSTEM_ADMINISTRATOR, APT_Constants.STRING_ONBOARDING};
		return (profileListCheck.contains(profileName) || isSalesSpecialistRole || loggedInUserId == opportunityOwnerId);
	}

	/**
	 *This method will check the configuration's ownership
	 *@param Id configOwnerId
	 *@param Id loggedInUserId
	 *@param String profileName
	 *@param Boolean isSalesSpecialistRole
	 *@return boolean value
	 */
	private static Boolean cartOwnerCheck(Id configOwnerId, Id loggedInUserId, String profileName, Boolean isSalesSpecialistRole, Id opportunityOwnerId) {
		Set<String> profileListCheck = new Set<String>{APT_Constants.STRING_SYSTEM_ADMINISTRATOR, APT_Constants.STRING_ONBOARDING};
		return (configOwnerId != loggedInUserId && !profileListCheck.contains(profileName) && isSalesSpecialistRole == false && (loggedInUserId != opportunityOwnerId && profileName != APT_Constants.STRING_BG_BASE));
	}

	/**
	 *This method will check the configuration's status and owner
	 *@param Id loggedInUserId
	 *@param Apttus_Config2__ProductConfiguration__c prodConfig
	 *@return boolean value
	 */
	private static Boolean configurationCheck(Id loggedInUserId, Apttus_Config2__ProductConfiguration__c prodConfig) {
		Set<String> configurationStatusCheck = new Set<String>{APT_Constants.CASE_STATUS_NEW, APT_Constants.URL_SAVED};
		return (configurationStatusCheck.contains(prodConfig.Apttus_Config2__Status__c) && loggedInUserId != prodConfig.OwnerId);
	}
}