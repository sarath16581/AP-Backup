/*
* @date 2020-11-18
* @group BillingAccounts
* @tag BillingAccount
* @domain Core
* @description Controller for createBillingAccount component and used for billing account creation, contains request payload and send to Camunda for SAP integration
* @changelog
* 2020-11-18 - arjun.singh@auspost.com.au - Created
* 2021-05-12 - seth.heang@auspost.com.au - updated request payload structure and field mappings
* 2021-05-11 - avula.jansirani@auspost.com.au - updated (for BCA billing account creation)
* 2021-05-28 - ankur.gandhi@auspost.com.au - removing special chars from BSB number
* 2021-06-08 - seth.heang@auspost.com.au - STP-5386 map sender name field from opportunity and to same field on DSR's New Billing Account Request Modal Popup
* 2022-07-07 - madhuri.awasthi@auspost.com. - REQ2800825 Filtering Status for LP before sending in SAP
* 2022-08-04 - Seth.Heang@auspost.com.au - Added methods for Rating Plan Activation request payload changes
* 2023-06-14 - sarath.burra@auspost.com.au - CI-613 For a created DSR if service commencement date AND/OR service expiry date for APPC service are not populated system should throw an error
* 2023-10-31 - Ranjeewa Silva - Updated 'processResponse' to call CreateBillingAccountHelper after receiving parsed response from service to do required status updates.
*/
public with sharing class CreateBillingAccountController {
	@TestVisible private static final String DSR_OBJECT = 'Deal_Support_Request__c';
	@TestVisible private static final String CREDIT_ASSESMENT_OBJECT = 'APT_Credit_Assessment__c';
	@TestVisible private static stateInfo stateInfoVar;

	// Setup constants for uses in the population of the request payload
	private static final String CHARGE_ACCOUNT = 'Charge Account';
	private static final String CHARGE_ACCOUNT_PROCESSTYPE = 'PT001';
	private static final String CHARGE_ACCOUNT_PROCESSTYPE_DESC = 'Assisted Onboarding - New Charge Account';
	private static final String CHARGE_SUB_ACCOUNT = 'Charge Account + Sub Account';
	private static final String CHARGE_SUB_ACCOUNT_PROCESSTYPE = 'PT002';
	private static final String CHARGE_SUB_ACCOUNT_PROCESSTYPE_DESC = 'Assisted Onboarding - New Charge and Sub Account';
	private static final String SAP_TARGET_SYSTEM = 'SAP';
	private static final String NEW_ACCOUNT_TYPE = 'New Account';

	//CI-613 Method to check if Service Commencement Date and Service Expiry Date are populated, if any of the dates are not populated throw an error
	@AuraEnabled
	public static boolean checkServiceDatesOnALI(String dsrId){
		boolean serviceDatesError=false;
		Deal_Support_Request__c dsrRecord;
		String objectName = String.valueOf(id.valueOf(dsrId).getsobjecttype());
			if(objectName == DSR_OBJECT){
				dsrRecord = DealSupportRequestsSelector.newInstance().selectById(
					new set<Id>{dsrId},
					new set<object>{
						DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
						DealSupportRequestsSelector.Options.WITH_CONTRACT,
						DealSupportRequestsSelector.Options.WITH_ORGANISATION
				}).values()[0];
			}
		// Query for 'Option' type Agreement Line Item based on contract Id And order by apttus item sequence field
		for(Apttus__AgreementLineItem__c ali :APT_AgreementLineItemsSelector.newInstance().selectByContractIdsAndLineType(
			new Set<id>{(Id)dsrRecord.APT_Contract__c},
			new Set<String>{'Product/Service'},
			new Set<Object>{
			APT_AgreementLineItemsSelector.Options.WITH_CONTRACT,
			APT_AgreementLineItemsSelector.Options.WITH_APPLIED_PSR}))
			{
				if('Australia Post Parcel Contract'.equalsIgnoreCase(ali.APT_Product_Name__c) &&  ali.Apttus_CMConfig__EffectiveDate__c!=null && ali.Apttus_CMConfig__EndDate__c!=null){
					serviceDatesError=false;
				}else{
					serviceDatesError=true;
				}
		}
		return serviceDatesError;
	}
	/**
	 * @Description:  Checks and validation all the required attributes for Billing Account creation and provide
	 *				a message to user in case of any one attribute is missing and prevents the billign account
	 *				creation till the time all requried attribute is populated.
	 *				1. Will generate the Billing account request record using generateBillingAccountCreationRequestFromDSR method
	 *				2. Will validatite the attribute details using CreateBillingAccountHelper.BillingAccountValidations method
	 */
	@AuraEnabled
	public static CreateBillingAccountHelper.billingAccountWithEmptyfields billingAccountCreationPreCheck(String recordId){
		CreateBillingAccountHelper.BillingAccountWithEmptyfields billingAccountWithEmptyfieldsVar ;
		BillingAccountWrapper billingAccountRequest = new BillingAccountWrapper();
		try {
			String ObjectName = String.valueOf(id.valueOf(recordId).getsobjecttype());
			if(ObjectName == DSR_OBJECT){
				billingAccountWithEmptyfieldsVar = generateBillingAccountCreationRequestFromDSR(recordId, null);
			}
			return billingAccountWithEmptyfieldsVar;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
	/**
	 * @Descciption  : Generated the External onboading request record prior to actual billing account creation is triggered.
	 *				 Uses  CreateBillingAccountHelper.ExternalOnboardingRequestDetails() for creation.
	 * */
	@AuraEnabled
	public static CreateBillingAccountHelper.externalOnboardingRequestWithConnectionDetails generateExternalOnboardingRecord(String recordId, String billingAccountName){
		CreateBillingAccountHelper.BillingAccountWithEmptyfields billingAccountWithEmptyfieldsVar;
		CreateBillingAccountHelper.ExternalOnboardingRequestWithConnectionDetails externalOnboardingRequestWithConnectionDetailsVar;
		try {
			String objectName = String.valueOf(id.valueOf(recordId).getsobjecttype());
			if(objectName == DSR_OBJECT){
				billingAccountWithEmptyfieldsVar = generateBillingAccountCreationRequestFromDSR(recordId, billingAccountName);
			}else  if(objectName == CREDIT_ASSESMENT_OBJECT){
				billingAccountWithEmptyfieldsVar = generateBillingAccountCreationRequestFromCA(recordId);
			}

			String onboardingRequestId = CreateBillingAccountHelper.createExternalOnboardingRequest(billingAccountWithEmptyfieldsVar.billingAccountAttributesDetails);
			externalOnboardingRequestWithConnectionDetailsVar = CreateBillingAccountHelper.ExternalOnboardingRequestDetails(billingAccountWithEmptyfieldsVar, onboardingRequestId);
		}catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return externalOnboardingRequestWithConnectionDetailsVar;
	}

	/**
	 * @Description : Triggers the actual Billing account creation and uses CreateBillingAccountHelper.createBillingAccountCallOut() for call out
	 */
	@AuraEnabled(continuation=true)
	public static Object billingAccountCreationRequest(String externalOnboardingRequestWithConnectionDetailsVar){
		Boolean callOutSuccessful = false;
		String sourceSystem = 'salesforce';
		CreateBillingAccountHelper.externalOnboardingRequestWithConnectionDetails externalOnboardingRequestWithConnectionDetailsRecord = (CreateBillingAccountHelper.externalOnboardingRequestWithConnectionDetails)System.JSON.deserialize(externalOnboardingRequestWithConnectionDetailsVar, CreateBillingAccountHelper.externalOnboardingRequestWithConnectionDetails.class);
		try {
			BillingAccountWrapper billingAccount = externalOnboardingRequestWithConnectionDetailsRecord.billingAccountWithEmptyfieldsVar.billingAccountAttributesDetails;
			billingAccount.transactionId = externalOnboardingRequestWithConnectionDetailsRecord.onboardingRequestId;
			String billingAccountJson = System.JSON.serialize(billingAccount, true);
			String requestObjId = externalOnboardingRequestWithConnectionDetailsRecord.billingAccountWithEmptyfieldsVar.billingAccountAttributesDetails.requestObjId;
			String chargeAccountRequestId = externalOnboardingRequestWithConnectionDetailsRecord.billingAccountWithEmptyfieldsVar.billingAccountValidations.chargeAccountRequestId;
			String onboardingRequestId = externalOnboardingRequestWithConnectionDetailsRecord.onboardingRequestId;


			stateInfoVar = new stateInfo();
			stateInfoVar.requestObjId = requestObjId;
			stateInfoVar.chargeAccountRequestId = chargeAccountRequestId;
			stateInfoVar.onboardingRequestId = onboardingRequestId;

			// populate rating plan details into StateInfo; payload contains billing account details including APPC product
			ratingPlanInfo ratingPlanDetails = new ratingPlanInfo();
			ratingPlanDetails.isBillingAccountPlusRatingPlanFlow = true;
			if(billingAccount.ratingPlanActivation == null){
				ratingPlanDetails.hasAPPCProduct = false;
			}else{
				ratingPlanDetails.hasAPPCProduct = true;
			}
			stateInfoVar.ratingPlanDetails = ratingPlanDetails;

			BillingAccountService service = BillingAccountService.getInstance();
			Continuation con = service.getContinuation(billingAccountJson, onboardingRequestId, sourceSystem);
			con.state = stateInfoVar;
			con.continuationMethod = 'processResponse';
			return con;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @description		This method wait and process the continuation response, then parse the response and return boolean for callout success or failure
	 * @param			List<String> labels,Object state
	 * @return			Boolean callout status; true for success or false for failure
	 */
	@AuraEnabled
	public static Boolean processResponse(List<String> labels,Object state) {
		StateInfo stateInformation = (StateInfo)state;
		HttpResponse httpResponse = Continuation.getResponse(labels[0]);
		BillingAccountService.Response response = BillingAccountService.getInstance().parseResponse(httpResponse);
		String status = (response.isSuccess ? 'Requested' : 'Error');
		CreateBillingAccountHelper.updateDSRAndChargeAccount(stateInformation.requestObjId, stateInformation.chargeAccountRequestId, stateInformation.onboardingRequestId, status, response.getErrorMessage(), stateInformation.ratingPlanDetails);
		return response.isSuccess;
	}
	public class stateInfo{
		@AuraEnabled
		public string requestObjId;
		@AuraEnabled
		public string chargeAccountRequestId;
		@AuraEnabled
		public string onboardingRequestId;
		@AuraEnabled
		public ratingPlanInfo ratingPlanDetails;
	}

	public class ratingPlanInfo{
		@AuraEnabled
		public boolean isBillingAccountPlusRatingPlanFlow;
		@AuraEnabled
		public boolean hasAPPCProduct;
	}
	/**
	 * @Description: Creates the Billing Account Creation Request using DSR as a base record which has details from multiple objects such as
	 *				related organisation, Primary Contact, Credit Assessment.
	 * 				  Seth Heang - 12/05/21 Updated Request Payload structure and field mappings
	 *
	 */
	public static CreateBillingAccountHelper.billingAccountWithEmptyfields generateBillingAccountCreationRequestFromDSR(String recordId, String billingAccountName){
		BillingAccountWrapper billingAccountRequestVar = new BillingAccountWrapper();
		CreateBillingAccountHelper.BillingAccountWithEmptyfields billingAccountWithEmptyfieldsVar = new CreateBillingAccountHelper.BillingAccountWithEmptyfields();
		CreateBillingAccountHelper.BillingAccountWithOtherValidations billingAccountOtherValidation = new CreateBillingAccountHelper.billingAccountWithOtherValidations();
		String tradingName;
		String legalEntityName;
		String senderNameFromOpportunity;
		boolean hasSubAccount;
		Integer subAccountCount;
		try{
			Deal_Support_Request__c dealSupportRequest = DealSupportRequestsSelector.newInstance().selectById(new set<Id>{recordId},
					new set<object>{
						DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
						DealSupportRequestsSelector.Options.WITH_CONTRACT
					}).values()[0];
			String integrationStatus = dealSupportRequest.Integration_Status__c ;
			billingAccountOtherValidation.loggedInUserProfile = ProfilesSelector.newInstance().selectById(new set<id>{userinfo.getProfileId()}).values()[0].name;
			if(dealSupportRequest.APT_Contract__c != null){
				Apttus__APTS_Agreement__c contractRecord = ApttusContractsSelector.newInstance().selectById(
					new set<Id>{dealSupportRequest.APT_Contract__c},
					new Set<object>{
						ApttusContractsSelector.Options.WITH_ORGANISATION,
						ApttusContractsSelector.Options.WITH_CONTACT,
						ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,
						ApttusContractsSelector.Options.WITH_PROPOSAL,
						ApttusContractsSelector.Options.WITH_OPPORTUNITY
					}).values()[0];
				if(contractRecord != null){
					if(contractRecord.Apttus__Account__c != null){
						/* Shashwat.Nath@auspost.com has added below lines of code to enforce a validation if customer role is invalid
							or if there are multiple roles within an organisation */

						Account accountRecord =  AccountsSelector.newInstance().selectById(new set<id>{contractRecord.Apttus__Account__c} , new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES}).values()[0];
						if(accountRecord?.Organisation_Roles__r.size()>1){
							billingAccountOtherValidation.hasMultipleRoles = true;
						}
						else{
							billingAccountOtherValidation.hasMultipleRoles = false;
						}
						if('Customer'.equalsIgnoreCase(accountRecord?.Role_Type_Roll_Up__c) || 'Prospect'.equalsIgnoreCase(accountRecord?.Role_Type_Roll_Up__c)
								|| 'Known'.equalsIgnoreCase(accountRecord?.Role_Type_Roll_Up__c)){

							billingAccountOtherValidation.isValidRole = true;
						}
						else{
							billingAccountOtherValidation.isValidRole = false;
						}

						billingAccountOtherValidation.chargeAccountRequestId = contractRecord.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.APT_Charge_Account__c;
						billingAccountOtherValidation.newAccountType = contractRecord.Apttus_QPComply__RelatedProposalId__r?.APT_Method_of_Payment__c;
						billingAccountOtherValidation.dsrWorkType = dealSupportRequest.Work_Type__c;

						billingAccountOtherValidation.physicalStreet = contractRecord.Apttus__Account__r.ShippingStreet;
						billingAccountOtherValidation.physicalCity = contractRecord.Apttus__Account__r.ShippingCity;
						billingAccountOtherValidation.physicalState = contractRecord.Apttus__Account__r.ShippingState;
						billingAccountOtherValidation.physicalPostCode = contractRecord.Apttus__Account__r.ShippingPostalCode;

						/* Shashwat.Nath@auspost.com code ends */

						/*
							* Retrieve new account type from associated proposal, to perform branching logic for the field mapping between
							* Charge Account Only & Charge + Sub Account Scenario
						*/
						String newAccountType = contractRecord.Apttus_QPComply__RelatedProposalId__r?.APT_Method_of_Payment__c;
						// Charge Account Only Scenario
						if(newAccountType == CHARGE_ACCOUNT){
							billingAccountRequestVar.processType = CHARGE_ACCOUNT_PROCESSTYPE;
							billingAccountRequestVar.processTypeDesc = CHARGE_ACCOUNT_PROCESSTYPE_DESC;

							// set the childAccount object to null
							billingAccountRequestVar.sap.customer.childAccount = null;
							billingAccountRequestVar.sap.customer.characteristics.elmsFlag = null;
							// parent billing account number only exists for sub-account only scenario
							billingAccountRequestVar.sap.customer.parentBillingAccNo = null;
							// Set Sub-Account flag as false to be sent out for UI processing at the LWC component
							hasSubAccount = false;
						}
						// Charge + Sub Account Scenario
						else if(newAccountType == CHARGE_SUB_ACCOUNT){
							// Set Sub-Account flag as true to be sent out for UI processing at the LWC component
							hasSubAccount = true;
							// parent billing account number only exists for sub-account only scenario
							billingAccountRequestVar.sap.customer.parentBillingAccNo = null;

							// Query Sub-Account request associated with the charge account Id
							List<APT_Sub_Account__c> subAccountRequestList = SubAccountRequestsSelector.newInstance().selectByChargeAcountRequestIdAndStatus(new set<id>{billingAccountOtherValidation.chargeAccountRequestId},new Set<String>{'Pending Charge Account'}, new Set<object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT}).values();
							if(subAccountRequestList.size() > 0){
								// Set the count of sub-account request to be sent out for UI processing at the LWC component
								subAccountCount = subAccountRequestList.size();
								billingAccountRequestVar.processType = CHARGE_SUB_ACCOUNT_PROCESSTYPE;
								billingAccountRequestVar.processTypeDesc = CHARGE_SUB_ACCOUNT_PROCESSTYPE_DESC;
								List<BillingAccountWrapper.childAccountDetail> subAccWrapperList = new List<BillingAccountWrapper.childAccountDetail>();
								// Loop through each sub-account request and map the appropriate fields
								for(APT_Sub_Account__c sar : subAccountRequestList){
									// Map Sub-Account requests details
									BillingAccountWrapper.childAccountDetail currentChildAcc = new BillingAccountWrapper.childAccountDetail();
									currentChildAcc.objectId = sar.id;
									currentChildAcc.objectType = 'Sub Account';
									currentChildAcc.name1 = sar.name;
									currentChildAcc.name2 = sar.APT_Account_Name_2__c;

									// Map revelent fields to characteristics details in the wrapper payload
									BillingAccountWrapper.CharacteristicsDetail charDetails = new BillingAccountWrapper.CharacteristicsDetail();
									// map Yes/No picklist value to True/False boolean for request payload
									if('Yes'.equals(sar?.APT_eParcel_Enabled__c)){
										charDetails.pcmsFlag = true;
									}else if('No'.equals(sar?.APT_eParcel_Enabled__c)){
										charDetails.pcmsFlag = false;
									}

									if('Yes'.equals(sar?.APT_eLMS_Enabled__c)){
										charDetails.elmsFlag = true;
									}else if('No'.equals(sar?.APT_eLMS_Enabled__c)){
										charDetails.elmsFlag = false;
									}
									currentChildAcc.characteristics = charDetails;

									// Map revelent fields to contact details in the wrapper payload
									BillingAccountWrapper.ContactDetail currentChildAccContact = new BillingAccountWrapper.ContactDetail();
									currentChildAccContact.firstName = sar?.SubAccountContact__r?.FirstName;
									currentChildAccContact.lastName = sar?.SubAccountContact__r?.LastName;
									currentChildAccContact.contactPersonId = sar?.SubAccountContact__c;
									BillingAccountWrapper.communicationInfoDetail currentChildCommInfo = new BillingAccountWrapper.communicationInfoDetail();
									currentChildCommInfo.email = sar?.SubAccountContact__r?.Email;
									currentChildCommInfo.phone = sar?.SubAccountContact__r?.Phone;
									currentChildCommInfo.mobile = sar?.SubAccountContact__r?.MobilePhone;
									currentChildAccContact.communicationInfo = currentChildCommInfo;
									currentChildAcc.contactPersons = new List<BillingAccountWrapper.ContactDetail>{currentChildAccContact};

									// Map revelent fields to address details in the wrapper payload
									BillingAccountWrapper.addressInfoDetail currentChildAccAddrInfo = new BillingAccountWrapper.addressInfoDetail();
									currentChildAccAddrInfo.street = sar?.APT_Postal_Address_Street_Name__c;
									currentChildAccAddrInfo.state = sar?.APT_Postal_Address_State__c;
									currentChildAccAddrInfo.city = sar?.APT_Postal_Address_Suburb__c;
									currentChildAccAddrInfo.postcode = sar?.APT_Postal_Address_Street_Postcode__c;
									currentChildAccAddrInfo.country = 'AU';
									currentChildAcc.addressInfo = currentChildAccAddrInfo;

									// Map revelent fields to lodgement point details in the wrapper payload
									List<BillingAccountWrapper.lodgementPointsDetail> curChildAccLPList;
									// Split the line for each entry
									List<String> lpWccPostcodeMap = new List<String>();
									lpWccPostcodeMap = sar?.Lodgement_Point_to_Work_Centre_Code__c.split('\n');
									// salesforce field format = "LodgementPoint:WorkCentreCode:PostCode"
									if(lpWccPostcodeMap != null && lpWccPostcodeMap.size() > 0){
										curChildAccLPList = new List<BillingAccountWrapper.lodgementPointsDetail>();
										// Split by ":" and retrieve the work centre code which is the second element
										for(String curRow : lpWccPostcodeMap){
											List<String> colonSplitList = curRow.split(':');
											BillingAccountWrapper.lodgementPointsDetail curChildAccLP = new BillingAccountWrapper.lodgementPointsDetail();
											// second element or [1] is Work-Centre-Code
											curChildAccLP.lodgementPointId = colonSplitList[1];
											curChildAccLPList.add(curChildAccLP);
										}
										currentChildAcc.lodgementPoints = new List<BillingAccountWrapper.lodgementPointsDetail>();
										currentChildAcc.lodgementPoints.addAll(curChildAccLPList);
									}
									// add an entire sub-account request object into a list format
									subAccWrapperList.add(currentChildAcc);
								}
								// Add the list of sub-account request list to request payload
								billingAccountRequestVar.sap.customer.childAccount = new List<BillingAccountWrapper.childAccountDetail>();
								billingAccountRequestVar.sap.customer.childAccount.addAll(subAccWrapperList);
							}else{
								// no sub account requests found
								billingAccountRequestVar.sap.customer.childAccount = null;
								// zero count of sub-account request
								subAccountCount = 0;
							}

						}

						// Query "Agreement Lodgement Point" junction record which related to Apttus Contract, and retrieve the Network record
						List<APT_Agreement_Lodgement_Point__c> contractLodgementPointList = APT_AgreementLodgementPointsSelector.newInstance().selectByApttusContractId(new set<id>{contractRecord.Id}, new set<object>{APT_AgreementLodgementPointsSelector.Options.WITH_NETWORK,APT_AgreementLodgementPointsSelector.Options.FILTER_ACTIVE_STATUS}).values();
						// New Set to store unique Work Centre Code, as Apttus Lodgement point can have duplicate entries for same product (e.g. eParcel)
						Set<String> uniqueWorkCentreCode = new Set<String>();
						// Map work centre code into LodgementPointId from the Agreement Lodgement Point
						if(contractLodgementPointList.size() > 0){
							List<BillingAccountWrapper.lodgementPointsDetail> contractLPList = new List<BillingAccountWrapper.lodgementPointsDetail>();
							// Map the Work Centre Code from related Network record and Map to LodgementPointId on Camunda spec for both PT001(Charge account only) and PT002(Charge+Sub Account) scenario
							for(APT_Agreement_Lodgement_Point__c contractLP : contractLodgementPointList){
								// Only map unique work centre code
								if(!uniqueWorkCentreCode.contains(contractLP.APT_Lodgement_Point_Lookup__r?.Org_ID__c) && contractLP.APT_Lodgement_Point_Lookup__r?.Org_ID__c != null){
									uniqueWorkCentreCode.add(contractLP.APT_Lodgement_Point_Lookup__r?.Org_ID__c);
									BillingAccountWrapper.lodgementPointsDetail curContractLP = new BillingAccountWrapper.lodgementPointsDetail();
									curContractLP.lodgementPointId = contractLP.APT_Lodgement_Point_Lookup__r?.Org_ID__c;
									contractLPList.add(curContractLP);
								}
							}
							billingAccountRequestVar.sap.customer.lodgementPoints = new List<BillingAccountWrapper.lodgementPointsDetail>();
							billingAccountRequestVar.sap.customer.lodgementPoints.addAll(contractLPList);
						}

						//Code using JSON Structure
						//Map relevant Charge Account fields to the request payload
						//Characteristics Details - pcms flag is defaulted to true for 'Charge Account Only' & 'Charge + Sub Account' Scenario
						billingAccountRequestVar.sap.customer.characteristics.pcmsFlag = true;

						//Status Details
						billingAccountRequestVar.sap.customer.creditControls.creditAssessNo = contractRecord.Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r?.Name;
						billingAccountRequestVar.sap.customer.creditControls.creditLimit = String.valueOf(contractRecord.Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r?.Aus_Post_Proposed_for_New_Account__c);

						//Contact Details
						BillingAccountWrapper.ContactDetail customerContact = new BillingAccountWrapper.ContactDetail();
						BillingAccountWrapper.communicationInfoDetail customerCommInfo = new BillingAccountWrapper.communicationInfoDetail();
						customerCommInfo.email = contractRecord?.Apttus__Primary_Contact__r?.Email;
						customerCommInfo.phone = contractRecord?.Apttus__Primary_Contact__r?.Phone;
						customerCommInfo.mobile = contractRecord?.Apttus__Primary_Contact__r?.MobilePhone;
						customerContact.communicationInfo = customerCommInfo;
						customerContact.firstName = contractRecord.Apttus__Primary_Contact__r.FirstName;
						customerContact.lastName = contractRecord.Apttus__Primary_Contact__r.LastName;
						customerContact.contactPersonId = contractRecord.Apttus__Primary_Contact__c;
						billingAccountRequestVar.sap.customer.contactPersons = new List<BillingAccountWrapper.ContactDetail>{customerContact};

						billingAccountRequestVar.sap.customer.objectId = billingAccountOtherValidation.chargeAccountRequestId;
						billingAccountRequestVar.sap.customer.objectType = 'Organisation';

						//Org Details
						String accountNameVar;
						String accountName2Var;

						tradingName = contractRecord.Apttus__Account__r.Organisation_Trading_Name__c;
						legalEntityName = contractRecord.Apttus__Account__r.Name;
						if(contractRecord.Apttus__Account__r.Organisation_Trading_Name__c != null){
							accountNameVar = billingAccountName;
							accountName2Var = contractRecord.Apttus__Account__r.Name;
						}else{
							accountNameVar = billingAccountName;
							accountName2Var = '';
						}
						// Map the Sender_name_to_appear_on_parcel_label__c field from opportunity and populate the same field on DSR's New Billing Account Request Modal Popup
						senderNameFromOpportunity = dealSupportRequest?.Opportunity__r?.Sender_name_to_appear_on_parcel_label__c;

						billingAccountRequestVar.sap.customer.name1 = accountNameVar;
						billingAccountRequestVar.sap.customer.name2 = accountName2Var;
						billingAccountRequestVar.sap.customer.accountGroup = contractRecord.Apttus__Account__r?.Customer_Account_Group__c;
						billingAccountRequestVar.sap.customer.customerId = contractRecord.Apttus__Account__r?.LEGACY_ID__c;

						// Address details
						billingAccountRequestVar.sap.customer.addressInfo.city = contractRecord.Apttus__Account__r?.BillingCity;
						billingAccountRequestVar.sap.customer.addressInfo.postcode = contractRecord.Apttus__Account__r?.BillingPostalCode;
						billingAccountRequestVar.sap.customer.addressInfo.state = contractRecord.Apttus__Account__r?.BillingState;
						billingAccountRequestVar.sap.customer.addressInfo.street = contractRecord.Apttus__Account__r?.BillingStreet;
						billingAccountRequestVar.sap.customer.addressInfo.country = contractRecord.Apttus__Account__r?.BillingCountry;


						//populating org email with contract primary contact email as SAP does not expect org email
						billingAccountRequestVar.sap.customer.communicationInfo.email = contractRecord.Apttus__Primary_Contact__r?.Email;
						billingAccountRequestVar.sap.customer.communicationInfo.phone = contractRecord.Apttus__Primary_Contact__r?.Phone;
						billingAccountRequestVar.sap.customer.communicationInfo.mobile = contractRecord.Apttus__Primary_Contact__r?.MobilePhone;

						// Customer Details
						billingAccountRequestVar.sap.customer.abn = contractRecord.Apttus__Account__r?.ABN__c;
						billingAccountRequestVar.sap.customer.acn = contractRecord.Apttus__Account__r?.ACN__c;

						//Requested record Id
						billingAccountRequestVar.requestObjId = id.valueOf(recordId);
						billingAccountRequestVar.orgRecordId = contractRecord.Apttus__Account__c;
						billingAccountRequestVar.targetSystem = SAP_TARGET_SYSTEM;

						// For new account scenario, append the rating plan activation payload to the billing account creation payload below
						if(dealSupportRequest.APT_Contract__r.APT_APPC_Count__c > 0 && NEW_ACCOUNT_TYPE.equalsIgnoreCase(dealSupportRequest.Work_Type__c)) {
							billingAccountRequestVar.ratingPlanActivation = CreateBillingAccountHelper.generateActivateRatePlanJSON(dealSupportRequest, true);
						}
					}
				}
			}
			billingAccountWithEmptyfieldsVar = CreateBillingAccountHelper.billingAccountValidations(billingAccountRequestVar, integrationStatus , billingAccountOtherValidation, tradingName, legalEntityName, hasSubAccount, subAccountCount, senderNameFromOpportunity);
		}catch(Exception ex){
			throw new AuraHandledException(ex.getMessage());
		}

		return billingAccountWithEmptyfieldsVar;
	}

	/**
	 * added by - avula.jansirani@auspost.com.au
	 * Building Billing account wrapper from Credit Assesment record
	 * */
	public static CreateBillingAccountHelper.billingAccountWithEmptyfields generateBillingAccountCreationRequestFromCA(String caId){

		CreateBillingAccountHelper.BillingAccountWithEmptyfields billingAccountWithEmptyfieldsWrapperObj = new CreateBillingAccountHelper.BillingAccountWithEmptyfields();
		// Deal_Support_Request__c dealSupportRequest = DealSupportRequestsSelector.newInstance().selectById(new set<Id>{recordId}).values()[0];
		// billingAccountWithEmptyfieldsWrapperObj.integrationStatus = dealSupportRequest.Integration_Status__c;
		billingAccountWithEmptyfieldsWrapperObj.billingAccountAttributesDetails = buildBillingAccountWrapperFromCA(caId);

		return billingAccountWithEmptyfieldsWrapperObj;
	}

	/**
	 * building billingAccountWrapper from CA record
	 * */
	public static BillingAccountWrapper buildBillingAccountWrapperFromCA(String caId){

		Set<SobjectField> caFieldSet = new Set<SObjectField> {
			APT_Credit_Assessment__c.Id,
			APT_Credit_Assessment__c.APT_Organisation_Name__c,
			APT_Credit_Assessment__c.APT_Email_Address__c,
			APT_Credit_Assessment__c.APT_Correspondence_Email_Address__c,
			APT_Credit_Assessment__c.APT_Telephone__c,
			APT_Credit_Assessment__c.Name,
			APT_Credit_Assessment__c.APT_Requested_Credit_Limit__c,
			APT_Credit_Assessment__c.Contact_First_Name__c,
			APT_Credit_Assessment__c.Contact_Last_Name__c,
			APT_Credit_Assessment__c.APT_Postal_City__c,
			APT_Credit_Assessment__c.APT_Postal_Country__c,
			APT_Credit_Assessment__c.APT_Postal_Postcode__c,
			APT_Credit_Assessment__c.APT_Postal_State__c,
			APT_Credit_Assessment__c.APT_Postal_Address_Line_1__c,
			APT_Credit_Assessment__c.APT_Postal_Address_Line_2__c,
			APT_Credit_Assessment__c.APT_Business_Name__c,
			APT_Credit_Assessment__c.APT_Legal_Entity_Name__c,
			APT_Credit_Assessment__c.Direct_Debit_Account_Name__c,
			APT_Credit_Assessment__c.Direct_Debit_Account_Number__c,
			APT_Credit_Assessment__c.Direct_Debit_BSB_Number__c,
			APT_Credit_Assessment__c.APT_Entity_Type__c,
			APT_Credit_Assessment__c.APT_Industry_Type__c,
			APT_Credit_Assessment__c.APT_ABN__c,
			APT_Credit_Assessment__c.APT_ACN__c
		};

		Set<Object> caOptions = new Set<Object>();
		caOptions.add(CreditsAssessmentSelector.Options.WITH_ORGANISATION);
		caOptions.add(CreditsAssessmentSelector.Options.WITH_CREDIT_ASSESSMENT_NETWOKS);

		//query CA and its Organisation and Credit_Assesment_Network records(assume ca must in database so not checking for list size and null checks)
		APT_Credit_Assessment__c ca = CreditsAssessmentSelector.newInstance(caFieldSet).selectById(new Set<Id>{caId}, caOptions).values()[0];

		BillingAccountWrapper billingAccountWrapperObj =  new BillingAccountWrapper();

		billingAccountWrapperObj.sap.customer.childAccount = null;  // no need child account for BCA flow

		billingAccountWrapperObj.orgRecordId = ca.APT_Organisation_Name__c;
		billingAccountWrapperObj.requestObjId = ca.Id;
		billingAccountWrapperObj.processType = 'PT004';
		billingAccountWrapperObj.processTypeDesc = 'Online Onboarding - New Charge Account';
		billingAccountWrapperObj.targetSystem = 'SAP';
		// sap details info --- START
		billingAccountWrapperObj.sap.customer.name1 = ca.APT_Business_Name__c;
		billingAccountWrapperObj.sap.customer.name2 = ca.APT_Legal_Entity_Name__c;

		billingAccountWrapperObj.sap.customer.objectId = ca.Id;
		billingAccountWrapperObj.sap.customer.objectType = 'Charge Account';

		billingAccountWrapperObj.sap.customer.customerId = ca.APT_Organisation_Name__r.LEGACY_ID__c;
		billingAccountWrapperObj.sap.customer.abn =	ca.APT_ABN__c;
		billingAccountWrapperObj.sap.customer.accountGroup = ca.APT_Organisation_Name__r.Customer_Account_Group__c;
		billingAccountWrapperObj.sap.customer.acn = ca.APT_ACN__c;
		billingAccountWrapperObj.sap.customer.industryId = ca.APT_Industry_Type__c;
		billingAccountWrapperObj.sap.customer.entityType = ca.APT_Entity_Type__c;

		// customer address info
		billingAccountWrapperObj.sap.customer.addressInfo.city = ca.APT_Postal_City__c;
		billingAccountWrapperObj.sap.customer.addressInfo.country = ca.APT_Postal_Country__c;
		billingAccountWrapperObj.sap.customer.addressInfo.postcode = ca.APT_Postal_Postcode__c;
		billingAccountWrapperObj.sap.customer.addressInfo.state = ca.APT_Postal_State__c;
		billingAccountWrapperObj.sap.customer.addressInfo.street = ca.APT_Postal_Address_Line_1__c + (null != ca.APT_Postal_Address_Line_2__c ?(' ' +ca.APT_Postal_Address_Line_2__c):'');

		// customer bank accounts info
		billingAccountWrapperObj.sap.customer.bankAccounts = new List<BillingAccountWrapper.BankAccount>();
		BillingAccountWrapper.BankAccount bankAcc = new BillingAccountWrapper.BankAccount();
		bankAcc.accountHolderName = ca.Direct_Debit_Account_Name__c;
		bankAcc.bankAccountNo = ca.Direct_Debit_Account_Number__c;
		bankAcc.bankStateBranch = ca.Direct_Debit_BSB_Number__c != null?ca.Direct_Debit_BSB_Number__c.replaceAll('[^0-9\\s+]', ''):ca.Direct_Debit_BSB_Number__c;
		billingAccountWrapperObj.sap.customer.bankAccounts.add(bankAcc);

		// customer characteristics info
		billingAccountWrapperObj.sap.customer.characteristics.elmsFlag = false;
		billingAccountWrapperObj.sap.customer.characteristics.pcmsFlag = false;

		// customer communicationInfo
		billingAccountWrapperObj.sap.customer.communicationInfo.email = ca.APT_Correspondence_Email_Address__c;
		//billingAccountWrapperObj.sap.customer.communicationInfo.mobile = ca.APT_Telephone__c;
		billingAccountWrapperObj.sap.customer.communicationInfo.phone = ca.APT_Telephone__c;

		// customer contact details info
		BillingAccountWrapper.ContactDetail conDetail = new BillingAccountWrapper.ContactDetail();
		conDetail.firstName = ca.Contact_First_Name__c;
		conDetail.lastName = ca.Contact_Last_Name__c;
		conDetail.communicationInfo = new BillingAccountWrapper.communicationInfoDetail();
		conDetail.communicationInfo.email = ca.APT_Email_Address__c;
		conDetail.communicationInfo.mobile = ca.APT_Telephone__c;
		conDetail.communicationInfo.phone = ca.APT_Telephone__c;
		billingAccountWrapperObj.sap.customer.contactPersons.add(conDetail);

			// customer credit controls info
		billingAccountWrapperObj.sap.customer.creditControls.creditAssessNo = ca.Name;
		billingAccountWrapperObj.sap.customer.creditControls.creditLimit = String.valueOf(ca.APT_Requested_Credit_Limit__c);

		//customer lodging points info
		List<Credit_Assessment_Network__c> caNetworksList = ca.Credit_Assessment_Networks__r;
		if(!caNetworksList.isEmpty()){
			billingAccountWrapperObj.sap.customer.lodgementPoints = new List<BillingAccountWrapper.lodgementPointsDetail>();
			for(Credit_Assessment_Network__c can : caNetworksList){
				BillingAccountWrapper.lodgementPointsDetail lodgementDetail = new BillingAccountWrapper.lodgementPointsDetail();
				lodgementDetail.lodgementPointId = can.Network__r.Org_ID__c;
				billingAccountWrapperObj.sap.customer.lodgementPoints.add(lodgementDetail);
			}
		}
			// sap details info --- END
		System.debug('billingAccountWrapperObj='+JSON.serialize(billingAccountWrapperObj));

		return billingAccountWrapperObj;
	}

	/**
	 * @description		This method builds the request payload and perform appropriate mapping for existing account scenario.
	 * 					It then create external onboarding request record and handling wrapper record for usage on LWC front-end
	 * @param			String recordId
	 * @return			CreateBillingAccountHelper.ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation wrapper
	 * */
	@AuraEnabled
	public static CreateBillingAccountHelper.ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation activateRatingPlan(String recordId){
		CreateBillingAccountHelper.ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation externalOnboardingRequestWithConnectionDetailsVar;
		try {
			BillingAccountWrapper ratingPlanRequestPayload = new BillingAccountWrapper();
			// Query DSR record and perform initial field mappings specifically for existing account scenario
			String objectName = String.valueOf(id.valueOf(recordId).getsobjecttype());
			if(objectName == DSR_OBJECT){
				Deal_Support_Request__c dsrRecord = DealSupportRequestsSelector.newInstance().selectById(
					new set<Id>{ recordId },
					new set<object>{
						DealSupportRequestsSelector.Options.WITH_OPPORTUNITY,
						DealSupportRequestsSelector.Options.WITH_CONTRACT,
						DealSupportRequestsSelector.Options.WITH_ORGANISATION
				}).values()[0];
				ratingPlanRequestPayload.sap = null;
				ratingPlanRequestPayload.requestObjId = id.valueOf(recordId);
				ratingPlanRequestPayload.customerId = dsrRecord.Organisation__r.LEGACY_ID__c;
				// call method to generate the full request payload
				ratingPlanRequestPayload.ratingPlanActivation = CreateBillingAccountHelper.generateActivateRatePlanJSON(dsrRecord, false);
			}
			// call method to create external onboarding request and return wrapper obj to LWC for handling front-end
			String onboardingRequestId = CreateBillingAccountHelper.createExternalOnboardingRequest(ratingPlanRequestPayload);
			externalOnboardingRequestWithConnectionDetailsVar = CreateBillingAccountHelper.externalOnboardingRequestDetailsForRatingPlanActivation(ratingPlanRequestPayload, onboardingRequestId, recordId);
		}catch (Exception e) {
			throw new AuraHandledException('Error occurred while preparing a rating plan activation payload' + e.getMessage());
		}
		return externalOnboardingRequestWithConnectionDetailsVar;
	}

	/**
	 * @description		This continutation method triggers the actual Rating Plan Activation creation using BillingAccountService.
	 * 					It serialises request payload into proper JSON format and send the payload to Camunda
	 * @param			String externalOnboardingRequestWithConnectionDetailsVar, String dsrId
	 * @return			Continuation object
	 */
	@AuraEnabled(continuation=true)
	public static Object ratingPlanActivationCreationRequest(String externalOnboardingRequestWithConnectionDetailsVar, String dsrId){
		Boolean callOutSuccessful = false;
		String sourceSystem = 'salesforce';
		CreateBillingAccountHelper.ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation externalOnboardingRequestWithConnectionDetailsRecord = (CreateBillingAccountHelper.ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation)System.JSON.deserialize(externalOnboardingRequestWithConnectionDetailsVar, CreateBillingAccountHelper.ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation.class);
		try {
			BillingAccountWrapper ratingPlanPayload = externalOnboardingRequestWithConnectionDetailsRecord.ratingPlanWrapper;
			ratingPlanPayload.transactionId = externalOnboardingRequestWithConnectionDetailsRecord.onboardingRequestId;
			String ratingPlanPayloadJson = System.JSON.serialize(ratingPlanPayload, true);
			String requestObjId = dsrId;
			String onboardingRequestId = externalOnboardingRequestWithConnectionDetailsRecord.onboardingRequestId;

			// Populate StateInfo for handling response
			stateInfoVar = new stateInfo();
			stateInfoVar.requestObjId = requestObjId;
			stateInfoVar.onboardingRequestId = onboardingRequestId;

			// Populate rating plan details to StateInfo; payload has APPC products and is rating plan payload only
			ratingPlanInfo ratingPlanDetails = new ratingPlanInfo();
			ratingPlanDetails.isBillingAccountPlusRatingPlanFlow = false;
			ratingPlanDetails.hasAPPCProduct = true;
			stateInfoVar.ratingPlanDetails = ratingPlanDetails;

			BillingAccountService service = BillingAccountService.getInstance();
			Continuation con = service.getContinuation(ratingPlanPayloadJson, onboardingRequestId, sourceSystem);
			con.state = stateInfoVar;
			con.continuationMethod = 'processResponse';
			return con;
		}catch (Exception e) {
			throw new AuraHandledException('Error occurred while making a continuation callout to Camunda'+ e.getMessage());
		}
	}
}