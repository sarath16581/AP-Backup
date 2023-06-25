	/*
	* @date 2020-11-18
	* @group BillingAccounts
	* @tag BillingAccount
	* @domain Core
	* @description Helper for createBillingAccount component and used for billing account creation
	* @changelog
	* 2020-11-18 - arjun.singh@auspost.com.au - Created
	* 2021-05-12 - seth.heang@auspost.com.au - updated fields mapping due to changes to wrapper class attribute
	* 2021-05-14 - avula.jansirani@auspost.com.au - updated (for BCA billing account creation)
	* 2021-06-15 - Seth.Heang@auspost.com.au - STP-5386 Add senderNameFromOpportunity attribute in the wrapper and pass this value to LWC
	* 2022-08-04 - Seth.Heang@auspost.com.au - Added methods for Rating Plan Activation request payload changes
	* 2023-06-14 - sarath.burra@auspost.com.au - CI-613 Populate the validFrom and validTo dates in RatingPlanActivation from SCD and SED in ContractLineItem
	*/
public with sharing class CreateBillingAccountHelper {
	private static final String DSR_OBJECT = 'Deal_Support_Request__c';
	private static final String CA_OBJECT = 'APT_Credit_Assessment__c';
	private static final String ANYWHERE_LODGEMENT_ZONE_TYPE = 'AN';
	private static final String Z1_DESTINATION_ZONE_TYPE = 'Z001';
	private static final String APPC_SPEED_STANDARD_PRODUCT_CLASSIFICATION = 'APPC-Standard';
	private static final String APPC_SPEED_PREMIUM_PRODUCT_CLASSIFICATION = 'APPC-Premium';
	private static final String APPC_FEATURES_PRODUCT_CLASSIFICATION = 'APPC-Feature';
	private static final String APPC_SURCHARGES_PRODUCT_CLASSIFICATION = 'APPC-Surcharge';
	private static final String APPC_RETURNS_PRODUCT_CLASSIFICATION = 'APPC-Return';
	private static final String APPC_FUEL_SURCHARGES_PRODUCT_CLASSIFICATION = 'APPC-FuelSurcharge';
	private static final String OPEN_ENDED_CONTRACT_LABEL = 'Open Ended';
	private static final String OPEN_ENDED_CONTRACT_VALUE = '9999-12-31';
	private static final String FIXED_TERM_CONTRACT_LABEL = 'Fixed Term';
	private static final String NEW_STANDARD_RATING_PLAN_ACTION_LABEL = 'newStandardRatingPlan';
	private static final String NEW_STANDARD_RATING_PLAN_ACTION_ID = '001';
	private static final String TRANSIT_COVER_TYPE_ADHOC = 'Adhoc';
	private static final String PRICE_POINT_ADHOC = 'TCOVER-1';
	private static final String PRICE_POINT_ALWAYS_ON = 'TCOVER-NR';
	private static final String RATING_PLAN_OBJ_TYPE_CHARGE_ACC = 'ChargeAccount';
	private static final String RATING_PLAN_OBJ_TYPE_SUB_ACC = 'SubAccount';
	private static final String RATING_PLAN_OBJ_TYPE_BILLING_ACC = 'BillingAccount';
	private static final String CONTRACT_RELATIONSHIP_ORG = 'Organisation';
	private static final String CONTRACT_RELATIONSHIP_BILLING_ACC = 'Billing Account';

	@testVisible static private Map<String, List<SObject>> metadataCoverageRecordsMap = new Map<String, List<SObject>>();
	/**
	 * @Description : Checks and validation all the required attributes for Billing Account creation and provide
	 *                a message to user in case of any one attribute is missing and prevents the billign account
	 *                creation till the time all requried attribute is populated.
	 * 				  Seth Heang 12/05/21 - Add hasSubAccount and subAccountCount as parameters to be sent fir UI processing at LWC component
	 */
	public static billingAccountWithEmptyfields billingAccountValidations(BillingAccountWrapper billingAccountRecord, String integrationStatus ,
											billingAccountWithOtherValidations otherValidationCheck, String tradingName, String legalEntityName, boolean hasSubAccount, Integer subAccountCount, String senderNameFromOpportunity){
		//Validation
		List<String> fieldList = new List<String>();
		if(otherValidationCheck.loggedInUserProfile !='Enterprise Onboarding' && otherValidationCheck.loggedInUserProfile !='System Administrator'){
			fieldList.add('Only Customer On Boarding users can access Billing Account Request');
		}
		if('Sub Account'.equalsIgnoreCase(otherValidationCheck.newAccountType)){
			fieldList.add('Billing Account Creation is not allowed for Sub Account');
		}

		if(!'New Account'.equalsIgnoreCase(otherValidationCheck.dsrWorkType)){
			fieldList.add('Billing Account Creation is only allowed for New Account Work Type');
		}
		if(String.isEmpty(billingAccountRecord.sap.customer.addressInfo.street)){
			fieldList.add('Billing Street is required');
		}
		if(String.isEmpty(billingAccountRecord.sap.customer.addressInfo.city)){
			fieldList.add('Billing City/Suburb is required');
		}
		if(String.isEmpty(billingAccountRecord.sap.customer.addressInfo.state)){
			fieldList.add('Billing State is required');
		}
		if(String.isEmpty(billingAccountRecord.sap.customer.addressInfo.postcode)){
			fieldList.add('Billing Postal Code is required');
		}
		if(String.isEmpty(otherValidationCheck.physicalStreet)){
			fieldList.add('Physical Street is required');
		}
		if(String.isEmpty(otherValidationCheck.physicalCity)){
			fieldList.add('Physical City/Suburb is required');
		}
		if(String.isEmpty(otherValidationCheck.physicalState)){
			fieldList.add('Physical State is required');
		}
		if(String.isEmpty(otherValidationCheck.physicalPostCode)){
			fieldList.add('Physical Postal Code is required');
		}
		if(String.isEmpty(billingAccountRecord.sap.customer.abn) && String.isEmpty(billingAccountRecord.sap.customer.acn)){
			fieldList.add('ABN or ACN is required');
		}
		if(String.isEmpty(billingAccountRecord.sap.customer.contactPersons[0].firstName)){
			fieldList.add('First Name is required');
		}
		if(String.isEmpty(billingAccountRecord.sap.customer.contactPersons[0].lastName)){
			fieldList.add('Last Name is required');
		}
		if(String.isEmpty(billingAccountRecord.sap.customer.contactPersons[0].communicationInfo.email)){
			fieldList.add('Primary Contact Email is required');
		}
		if(String.isEmpty(otherValidationCheck.chargeAccountRequestId)){
			fieldList.add('Charge Account Request Id is required');
		}
		if(String.isEmpty(billingAccountRecord.sap.customer.creditControls.creditAssessNo)){
			fieldList.add('Credit Assessment Number is required');
		}
		if(String.isEmpty(billingAccountRecord.sap.customer.creditControls.creditLimit)){
			fieldList.add('Credit Limit is required');
		}
		if(billingAccountRecord.sap.customer.creditControls.creditLimit != null
				&& Integer.ValueOf(billingAccountRecord.sap.customer.creditControls.creditLimit) <= 10){
			fieldList.add('Proposed Credit Limit is less than $10, unable to proceed with Account Creation');
		}
		if(hasSubAccount == true && subAccountCount == 0){
			fieldList.add('You need to "finalize" sub-account requests prior to submission. You can finalize sub-account requests in the sub-account request form for the related proposal');
		}
		/* Shashwat.Nath@auspost.com has added below lines of code */

		if(otherValidationCheck.hasMultipleRoles != null && otherValidationCheck.hasMultipleRoles){
			fieldList.add('Organisation has multiple roles . Please resolve');
		}
		if(otherValidationCheck.isValidRole !=null && !otherValidationCheck.isValidRole){
			fieldList.add('Organisation role must be Prospect, Known or Customer');
		}

		/* Shashwat.Nath@auspost.com code ends */

		billingAccountWithEmptyfields billingAccountWithEmptyfieldsVar = new billingAccountWithEmptyfields();
		billingAccountWithEmptyfieldsVar.billingAccountAttributesDetails = billingAccountRecord;
		billingAccountWithEmptyfieldsVar.emptyAttributesList = fieldList;
		billingAccountWithEmptyfieldsVar.integrationStatus = integrationStatus;
		billingAccountWithEmptyfieldsVar.billingAccountValidations = otherValidationCheck;
		billingAccountWithEmptyfieldsVar.tradingName = tradingName;
		billingAccountWithEmptyfieldsVar.legalEntityName = legalEntityName;
		billingAccountWithEmptyfieldsVar.senderNameFromOpportunity = senderNameFromOpportunity;
		billingAccountWithEmptyfieldsVar.hasSubAccount = hasSubAccount;
		billingAccountWithEmptyfieldsVar.subAccountCount = subAccountCount;
		return billingAccountWithEmptyfieldsVar;
	}
	/**
	 * @Descrtipion : An object which holds informations as below:
	 *                1. billingAccountAttributesDetails: Attributes for billing account creation
	 *                2. emptyAttributesList: Attribites which has missing values and related message
	 *                3. integrationStatus : Integration status which holds current status of request for billing account creation
	 *                                       It has different values such as Requested, Completed, Error
	 *                4. billingAccountValidations : Addtitional validation details which are required prior to billing account creation
	 *                5. tradingName : Related organisation trading name
	 *                6. senderNameFromOpportunity : Query value from Opportunity.Sender_name_to_appear_on_parcel_label__c
	 *                                               Used to pre-populate the "What sender name should be displayed on parcel labels" input field on DSR's New Billing Account Modal Popup
	 *                7. legalEntityName : Related organisation legal Entity name
	 *                8. hasSubAccount : flag to determine if this is Charge Account Only or Charge + Sub Account Scenario
	 *                9. subAccountCount : count of the sub-account requests
	 */
	public class BillingAccountWithEmptyfields{
		@AuraEnabled
		public BillingAccountWrapper billingAccountAttributesDetails;
		@AuraEnabled
		public List<String> emptyAttributesList;
		@AuraEnabled
		public String integrationStatus;
		@AuraEnabled
		public billingAccountWithOtherValidations billingAccountValidations;
		@AuraEnabled
		public String tradingName;
		@AuraEnabled
		public String senderNameFromOpportunity;
		@AuraEnabled
		public String legalEntityName;
		@AuraEnabled
		public boolean hasSubAccount;
		@AuraEnabled
		public Integer subAccountCount;
	}
	/**
	 * @ Description: Object which has details of additionl validation required prior to billing account creation
	 */
	public class BillingAccountWithOtherValidations{
		@AuraEnabled
		public Boolean hasMultipleRoles;
		@AuraEnabled
		public Boolean isValidRole;
		@AuraEnabled
		public String chargeAccountRequestId;
		@AuraEnabled
		public String loggedInUserProfile;
		@AuraEnabled
		public String newAccountType;
		@AuraEnabled
		public String dsrWorkType;
		@AuraEnabled
		public String physicalStreet;
		@AuraEnabled
		public String physicalCity;
		@AuraEnabled
		public String physicalState;
		@AuraEnabled
		public String physicalPostCode;

	}
	/**
	 * @Description : Creates External Onboarding Request prior to billing account creation and record Id
	 *                will be passed as once of the parameter called as transaction Id in request.
	 */

	public static externalOnboardingRequestWithConnectionDetails externalOnboardingRequestDetails(billingAccountWithEmptyfields billingAccountRecord, String onboardingRequestId){
		/*
			A new custom Metadata to configure if the org is integration with SAP for billing account creation.
			If yes then actual Integration flow will be executed . If not then a mocking framework will
			be used to create the event and further billing account record within salesforce.
		*/
		externalOnboardingRequestWithConnectionDetails externalOnboardingRequestWithConnectionDetailsVar = new externalOnboardingRequestWithConnectionDetails();

		try{
			List<SAP_Integration__mdt> sapIntegrationRecord = getSAPIntegrationMetadataRecords('Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'');

			System.debug('sapIntegrationRecord>>>>'+sapIntegrationRecord[0]);
			if(sapIntegrationRecord[0].Connected__c =='Yes'){
				externalOnboardingRequestWithConnectionDetailsVar.connected = true;
				externalOnboardingRequestWithConnectionDetailsVar.onboardingRequestId = onboardingRequestId;
				externalOnboardingRequestWithConnectionDetailsVar.billingAccountWithEmptyfieldsVar = billingAccountRecord;
			}else{
				// Create a mock response for Billing Account Creation
				Integer len = 8;
				String str = string.valueof(Math.abs(Crypto.getRandomLong()));
				String randomNumber = str.substring(0, len);
				// common for DSR and BCA
				BillingAccountCreationEvent__e billingEvent = new BillingAccountCreationEvent__e() ;
				billingEvent.Billing_Account_Number__c =  'SF-'+randomNumber;
				billingEvent.Billing_Account_Name__c =   billingAccountRecord.billingAccountAttributesDetails.sap.customer.name1;
				billingEvent.Customer_Id__c = billingAccountRecord.billingAccountAttributesDetails.sap.customer.customerId;
				billingEvent.Organisation_Record_Id__c = billingAccountRecord.billingAccountAttributesDetails.orgRecordId;
				billingEvent.Request_Object_Id__c = billingAccountRecord.billingAccountAttributesDetails.requestObjId;
				billingEvent.Status_Description__c = 'Mocking the response';
				billingEvent.Source_System__c = 'SAP';
				billingEvent.Transaction_Id__c = onboardingRequestId;
				billingEvent.Status__c= 'Success';
				String objectName = String.valueOf(id.valueOf(billingAccountRecord.billingAccountAttributesDetails.requestObjId)?.getsobjecttype());

				//-- for BCA flow, the source as 'SAP'
				if(CA_OBJECT.equalsIgnoreCase(objectName)){
					billingEvent.Source_System__c = 'SAP';
					billingEvent.Type__c = 'CUST';
					billingEvent.Credit_Person__c='	xxxx - SMB VIC/TAS';
					billingEvent.Credit_Group__c='Credit Mgt - VIC';
					billingEvent.Credit_Person_Code__c='3N';
				}

				System.debug('billingEvent platform event='+billingEvent);
				Database.SaveResult sr = EventBus.publish(billingEvent);

				if(billingAccountRecord.billingAccountAttributesDetails.sap.customer.childAccount!=null &&
					billingAccountRecord.billingAccountAttributesDetails.sap.customer.childAccount.size()>0){
					Integer count = 0;
					for(BillingAccountWrapper.childAccountDetail obj : billingAccountRecord.billingAccountAttributesDetails.sap.customer.childAccount){
						Integer len1 = 8;
						String strn = string.valueof(Math.abs(Crypto.getRandomLong()));
						String randomNumberSubAccnt = strn.substring(0, len1);

						BillingAccountCreationEvent__e billingEvent1 = new BillingAccountCreationEvent__e() ;
						billingEvent1.Billing_Account_Name__c = obj.name1;
						billingEvent1.Billing_Account_Number__c = 'SF-'+randomNumberSubAccnt;
						billingEvent1.Organisation_Record_Id__c =billingAccountRecord.billingAccountAttributesDetails.orgRecordId;
						billingEvent1.Request_Object_Id__c = billingAccountRecord.billingAccountAttributesDetails.requestObjId;
						billingEvent1.Status_Description__c = 'Mocking the response';
						billingEvent1.Transaction_Id__c = onboardingRequestId;
						billingEvent1.Source_System__c = 'SAP';
						billingEvent1.Status__c= 'Success';
						billingEvent1.Parent_Account_Number__c = billingEvent.Billing_Account_Number__c;
						billingEvent1.Sub_Account_Request_Id__c = obj.objectId;
						billingEvent1.MLID__c = '555000';
						count++;
						EventBus.publish(billingEvent1);
					}
				}



				/* shashwat.nath@auspost.com updated the below code to set the interim status of the charge account request to "New" when
				the request is submitted */

				List<sObject> updateRelatedRecords = new List<sObject>();

				if(objectName == DSR_OBJECT){
					Deal_Support_Request__c dealSupportRequest = new Deal_Support_Request__c();
					dealSupportRequest.Id = billingAccountRecord.billingAccountAttributesDetails.requestObjId;
					dealSupportRequest.Integration_Status__c= 'Requested';
					updateRelatedRecords.add(dealSupportRequest);
				}else if(objectName == CA_OBJECT){
					APT_Credit_Assessment__c ca = new APT_Credit_Assessment__c();
					ca.Id = billingAccountRecord.billingAccountAttributesDetails.requestObjId;
					ca.Integration_Status__c= 'Requested';
					updateRelatedRecords.add(ca);
				}

				if(objectName != CA_OBJECT){
					APT_Charge_Account__c chargeAccntReq = new APT_Charge_Account__c();
					chargeAccntReq.id = billingAccountRecord.billingAccountValidations.chargeAccountRequestId;
					chargeAccntReq.Status__c = 'New';
					updateRelatedRecords.add(chargeAccntReq);
				}

				updateSobjectRecords(updateRelatedRecords);
				externalOnboardingRequestWithConnectionDetailsVar.connected = false;
				externalOnboardingRequestWithConnectionDetailsVar.onboardingRequestId = onboardingRequestId;
				externalOnboardingRequestWithConnectionDetailsVar.billingAccountWithEmptyfieldsVar = billingAccountRecord;
			}
		}catch(Exception ex){
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'B&G Sales', 'CreateBillingAccountHelper' , 'externalOnboardingRequestDetails', null, LoggingLevel.ERROR);
		}

		return externalOnboardingRequestWithConnectionDetailsVar;
	}
	/**
	 * @Description : External Onboarding Request creation method. The created record is used as transaction Id
	 *                for request.
	 */
	public static String createExternalOnboardingRequest(BillingAccountWrapper billingAccountWrapperVar){
		List<Database.SaveResult> sResult;
		try{
			String requestObjId = billingAccountWrapperVar.requestObjId;
			String objectName;
			if(requestObjId != null){
				objectName = String.valueOf(id.valueOf(requestObjId).getsobjecttype());
			}

			// populate external onboarding request object for logging purposes
			BAMExternalOnboardingRequest__c bamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();
			bamExternalOnboardingRequest.Request_Object_Name__c = objectName;
			bamExternalOnboardingRequest.Request_Object_Id__c = requestObjId;
			bamExternalOnboardingRequest.Request_Date__c = System.now();
			bamExternalOnboardingRequest.RecordTypeId = Schema.SObjectType.BAMExternalOnboardingRequest__c.getRecordTypeInfosByDeveloperName().get('Billing_Account_Creation').getRecordTypeId();

			sResult= ApplicationDatabase.getInstance().dmlInsert(new List<BAMExternalOnboardingRequest__c>{bamExternalOnboardingRequest});
			// save external onboarding request id to the transactionId of the request payload
			billingAccountWrapperVar.transactionId = String.valueOf(sResult[0].getId());

			BAMExternalOnboardingRequest__c updateBamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();
			updateBamExternalOnboardingRequest.Id= String.valueOf(sResult[0].getId());
			// remove null attribute/object off the payload
			//We need to make Bank account details null for not storing in External On boarding request.
			BillingAccountWrapper billingAccountTempWrapper = billingAccountWrapperVar;
			if(billingAccountTempWrapper?.sap != null){
				billingAccountTempWrapper.sap.customer.bankAccounts = null;
			}
			// remove null attribute/object off the payload
			updateBamExternalOnboardingRequest.Request_Payload__c = JSON.serialize(billingAccountTempWrapper, true);
			List<Database.SaveResult> sResultForUpdate= ApplicationDatabase.getInstance().dmlUpdate(new List<BAMExternalOnboardingRequest__c>{updateBamExternalOnboardingRequest});
		}catch(Exception ex){
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'B&G Sales', 'CreateBillingAccountHelper' , 'createExternalOnboardingRequest', null, LoggingLevel.ERROR);
		}

		return String.valueOf(sResult[0].getId());
	}

	/**
	 * @description		This method updates the related DSR and Charge Account and external onborading request based on the initial response received from camunda
	 * @param			String requestObjId, String chargeAccountRequestId, String onboardingRequestId, String status, String responseMsg, CreateBillingAccountController.ratingPlanInfo; specify rating plan detail for new customer or existing customer flow and if APPC product exists
	 * @return			void
	 */
	public static void updateDSRAndChargeAccount(String requestObjId, String chargeAccountRequestId, String onboardingRequestId, String status, String responseMsg, CreateBillingAccountController.ratingPlanInfo ratingPlanDetails){
		try{
			List<sObject> updateRelatedRecords = new List<sObject>();
			if(DSR_OBJECT.equalsIgnoreCase(String.valueOf(id.valueOf(requestObjId)?.getsobjecttype()))){
				Deal_Support_Request__c dealSupportRequest = new Deal_Support_Request__c();
				dealSupportRequest.Id = requestObjId;
				// for billing account + rating plan flow, update DSR integration status related fields regardless of products in the payload
				if(ratingPlanDetails.isBillingAccountPlusRatingPlanFlow == true){
					dealSupportRequest.Integration_Status__c= status;
					dealSupportRequest.Integration_Status_Description__c =responseMsg;
					dealSupportRequest.Integration_Transaction_Id__c = onboardingRequestId;
				}
				// In addition, for APPC product only; update DSR rating plan integration status
				if(ratingPlanDetails != null && ratingPlanDetails.hasAPPCProduct == true){
					// always update rating plan integration related field
					dealSupportRequest.Rating_Integration_Transaction_Id__c = onboardingRequestId;
					dealSupportRequest.Rating_Integration_Status__c = status;
					dealSupportRequest.Rating_Integration_Status_Description__c = responseMsg;
				}
				updateRelatedRecords.add(dealSupportRequest);
			}
			// update charge account request status if not blank
			if(status == 'Requested' && (chargeAccountRequestId != null || !String.isBlank(chargeAccountRequestId))){
				APT_Charge_Account__c chargeAccntReq = new APT_Charge_Account__c();
				chargeAccntReq.id = chargeAccountRequestId;
				chargeAccntReq.Status__c = 'New';
				updateRelatedRecords.add(chargeAccntReq);
			}
			// update External onboarding request status and response payload
			BAMExternalOnboardingRequest__c bamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();
			bamExternalOnboardingRequest.Id = onboardingRequestId;
			bamExternalOnboardingRequest.Response_Payload__c = responseMsg;
			if(status =='Error'){
				bamExternalOnboardingRequest.Status__c = status;
			}
			updateRelatedRecords.add(bamExternalOnboardingRequest);
			updateSobjectRecords(updateRelatedRecords);
		}catch(Exception ex){
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'B&G Sales', 'CreateBillingAccountHelper' , 'updateDSRAndChargeAccount', null, LoggingLevel.ERROR);
		}
	}

	/**
	 * @Description: Updates the CA and external onborading request based on the initial
	 *               response received from camunda
	 * avula.jansirani@auspost.com.au
	 */
	public static void updateCaAndOnboardingObj(String requestObjId, String onboardingRequestId, String status, String responseMsg){
		List<sObject> updateRelatedRecords = new List<sObject>();

		APT_Credit_Assessment__c ca = new APT_Credit_Assessment__c();
		ca.Id = requestObjId;
		ca.Integration_Status__c= status;
		ca.Integration_Status_Description__c = responseMsg;
		ca.Integration_Transaction_Id__c = onboardingRequestId;
		updateRelatedRecords.add(ca);

		BAMExternalOnboardingRequest__c bamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();
		bamExternalOnboardingRequest.Id = onboardingRequestId;
		bamExternalOnboardingRequest.Response_Payload__c = responseMsg;
		if(status =='Error'){
			bamExternalOnboardingRequest.Status__c = status;
		}
		updateRelatedRecords.add(bamExternalOnboardingRequest);
		updateSobjectRecords(updateRelatedRecords);
	}

		/**
	 * @Description: Updates the sobjects
	 * avula.jansirani@auspost.com.au - created
	 */
	public static void updateSobjectRecords(List<sObject> recordsList){
		ApplicationDatabase.getInstance().dmlUpdate(recordsList);
	}

	public class ExternalOnboardingRequestWithConnectionDetails{
		@AuraEnabled
		public Boolean connected;
		@AuraEnabled
		public String onboardingRequestId;
		@AuraEnabled
		public billingAccountWithEmptyfields billingAccountWithEmptyfieldsVar;
	}

	/**
	 * @description Wrapper class for rating plan activation for usage on the LWC front-end
	 */
	public class ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation{
		@AuraEnabled
		public Boolean connected;
		@AuraEnabled
		public String onboardingRequestId;
		@AuraEnabled
		public BillingAccountWrapper ratingPlanWrapper {get;set;}
	}

	public static List<SObject> getSAPIntegrationMetadataRecords(String query){
		if(!metadataCoverageRecordsMap.containsKey(query)){
			metadataCoverageRecordsMap.put(query, Database.query(query));
		}
		return metadataCoverageRecordsMap.get(query);
	}

	/**
	 * @description		This method perform all the required mapping and generate the rating plan activation section of the final payload
	 * @param			Deal_Support_Request__c dsrRecord, Boolean isNewAccount; used to to determine if this is for new account or existing account
	 * @return 			BillingAccountWrapper.CompassContractActivation section of the payload
	 */
	public static BillingAccountWrapper.CompassContractActivation generateActivateRatePlanJSON(Deal_Support_Request__c dsrRecord, Boolean isNewAccount) {
		BillingAccountWrapper.CompassContractActivation activateRatePlan = new BillingAccountWrapper.CompassContractActivation();
		try {

			activateRatePlan.customer = new List<BillingAccountWrapper.ratingPlanCustomer>();
			// Query Agreement lodgement point junction object based on contract Id, for populating the customer node in the payload
			List<APT_Agreement_Lodgement_Point__c> agreementLPs = APT_AgreementLodgementPointsSelector.newInstance().selectByApttusContractId(
				new Set<Id>{(Id)dsrRecord.APT_Contract__c},
				new Set<Object>{
					APT_AgreementLodgementPointsSelector.Options.WITH_BILLING_ACCOUNT,
					APT_AgreementLodgementPointsSelector.Options.WITH_CHARGE_ACCOUNT_REQ,
					APT_AgreementLodgementPointsSelector.Options.WITH_SUB_ACCOUNT_REQ,
					APT_AgreementLodgementPointsSelector.Options.WITH_ORGANISATION
				}).values();

			List<BillingAccountWrapper.ratingPlanCustomer> linkedAccountsList = new List<BillingAccountWrapper.ratingPlanCustomer>();
			Apttus__APTS_Agreement__c apttusContractForUpdate = new Apttus__APTS_Agreement__c(id=dsrRecord.APT_Contract__c);
			if(agreementLPs.size() > 0){
				// Loop through each agreement lodgement point to perform appropriate mapping and also update contract relationship field on Apttus Contract
				for(APT_Agreement_Lodgement_Point__c alp : agreementLPs){
					BillingAccountWrapper.ratingPlanCustomer ratingPlanCus = new BillingAccountWrapper.ratingPlanCustomer();
					// send rating plan Id if exists in retry attempt, else leave blank for first attempt
					ratingPlanCus.ratingPlanId = alp.Rating_Plan_Id__c != null ? alp.Rating_Plan_Id__c : '';
					// Map objectType to 'Organisation' if linked at the Org level
					if(alp.APT_Charge_Account__c == null && alp.APT_Sub_Account__c == null && alp.APT_Billing_Account__c == null){
						ratingPlanCus.objectType = 'Organisation';
						ratingPlanCus.objectId = alp.APT_Organisation__r.LEGACY_ID__c;
						ratingPlanCus.requestObjId = alp.id;
						linkedAccountsList.add(ratingPlanCus);
						// set contract relationship to Organisation
						apttusContractForUpdate.Contract_Relationship__c = CONTRACT_RELATIONSHIP_ORG;
						continue;
					}
					// is New Account Flow
					if(isNewAccount != null && isNewAccount == true){
						// Map objectType to 'ChargeAccount' if linked at charge account request level
						if(alp.APT_Charge_Account__c != null && alp.APT_Sub_Account__c == null){
							ratingPlanCus.objectType = RATING_PLAN_OBJ_TYPE_CHARGE_ACC;
							ratingPlanCus.objectId = alp.APT_Charge_Account__c;
							ratingPlanCus.requestObjId = alp.id;
							linkedAccountsList.add(ratingPlanCus);
							// set contract relationship to Billing Account
							apttusContractForUpdate.Contract_Relationship__c = CONTRACT_RELATIONSHIP_BILLING_ACC;
							continue;
						}
						// Map objectType to 'SubAccount' if linked at Sub account request level
						else if(alp.APT_Sub_Account__c != null && alp.APT_Charge_Account__c == null){
							ratingPlanCus.objectType = RATING_PLAN_OBJ_TYPE_SUB_ACC;
							ratingPlanCus.objectId = alp.APT_Sub_Account__c;
							ratingPlanCus.requestObjId = alp.id;
							linkedAccountsList.add(ratingPlanCus);
							// set contract relationship to Billing Account
							apttusContractForUpdate.Contract_Relationship__c = CONTRACT_RELATIONSHIP_BILLING_ACC;
							continue;
						}
					}// is Existing Account Flow
					else if(isNewAccount != null && isNewAccount == false){
						// Map objectType to 'BillingAccount' if linked at the billing account level
						if(alp.APT_Billing_Account__c != null){
							ratingPlanCus.objectType = RATING_PLAN_OBJ_TYPE_BILLING_ACC;
							ratingPlanCus.objectId = alp.APT_Billing_Account__r.LEGACY_ID__c;
							ratingPlanCus.requestObjId = alp.id;
							linkedAccountsList.add(ratingPlanCus);
							// set contract relationship to Billing Account
							apttusContractForUpdate.Contract_Relationship__c = CONTRACT_RELATIONSHIP_BILLING_ACC;
							continue;
						}
					}
				}
			}
			// asyc update contract relationship field on Apttus Contract
			updateApttusContract(apttusContractForUpdate.Id, apttusContractForUpdate.Contract_Relationship__c);
			activateRatePlan.customer = linkedAccountsList;

			List<Apttus__AgreementLineItem__c> agrLiList = new List<Apttus__AgreementLineItem__c>();
			// Query for 'Option' type Agreement Line Item based on contract Id And order by apttus item sequence field
			agrLiList = APT_AgreementLineItemsSelector.newInstance().selectByContractIdsAndLineType(
				new Set<id>{(Id)dsrRecord.APT_Contract__c},
				new Set<String>{'Product/Service','Option'},
				new Set<Object>{
				APT_AgreementLineItemsSelector.Options.WITH_CONTRACT,
				APT_AgreementLineItemsSelector.Options.WITH_PROPOSAL,
				APT_AgreementLineItemsSelector.Options.WITH_OPTION,
				APT_AgreementLineItemsSelector.Options.WITH_AGREEMENT_ATTRIBUTE_VALUE,
				APT_AgreementLineItemsSelector.Options.WITH_APPLIED_PSR,
				APT_AgreementLineItemsSelector.Options.ORDER_BY_ITEM_SEQUENCE_ASC
			});
			if(agrLiList.size() > 0){
				// bundle line item with 'Product/Service' which has Applied PSR populated, maps to quoteId on payload
				activateRatePlan.quoteId = agrLiList[0].Apttus_CMConfig__AttributeValueId__r.Applied_PSR__r.Compass_Quote_Reference__c != null ? agrLiList[0].Apttus_CMConfig__AttributeValueId__r.Applied_PSR__r.Compass_Quote_Reference__c : ''; // Compass Quote Id needs to be sent

				List<BillingAccountWrapper.eventData> eventDataList = new List<BillingAccountWrapper.eventData>();

				BillingAccountWrapper.data ratingPlanData = new BillingAccountWrapper.data();
				BillingAccountWrapper.eventData eventData = new BillingAccountWrapper.eventData();
				ratingPlanData.ratingPlanId = ''; // blank
				ratingPlanData.customer = ''; // blank
				//CI-613 Populate the validFrom and validTo dates in RatingPlanActivation from SCD and SED in ContractLineItem
				ratingPlanData.validFrom=agrLiList[0].Apttus_CMConfig__EffectiveDate__c > System.TODAY() ? String.valueOf(agrLiList[0].Apttus_CMConfig__EffectiveDate__c) :String.valueOf(System.TODAY()+1).substring(0,10);
				ratingPlanData.validTo=String.valueOf(agrLiList[0].Apttus_CMConfig__EndDate__c);
				ratingPlanData.newValidTo = ''; // blank

				// Map APPC product fields' details to request payload
				ratingPlanData.ratingModel = agrLiList[1].Apttus_CMConfig__OptionId__r.SAP_Rating_Model__c;
				ratingPlanData.ratingGroup = agrLiList[1].Apttus_CMConfig__OptionId__r.SAP_Rating_Group__c;
				ratingPlanData.contractRef = dsrRecord.APT_Contract__r.Apttus__FF_Agreement_Number__c;
				ratingPlanData.weightRounding = agrLiList[1].Apttus_CMConfig__AttributeValueId__r.SAP_Weight_Rounding__c != null ? agrLiList[1].Apttus_CMConfig__AttributeValueId__r.SAP_Weight_Rounding__c : '';
				ratingPlanData.status = 'R';
				ratingPlanData.description = dsrRecord.Opportunity__r.Opportunity_Number__c;
				ratingPlanData.cubingFlag = String.valueOf(agrLiList[1].Apttus_CMConfig__AttributeValueId__r.APT_Cubic_Status__c);
				ratingPlanData.cubicConvFac = agrLiList[1].Apttus_CMConfig__AttributeValueId__r.SAP_Cubic_Conversion_Factor__c != null ? String.valueOf(Integer.valueOf((agrLiList[1].Apttus_CMConfig__AttributeValueId__r.SAP_Cubic_Conversion_Factor__c))) : '';
				ratingPlanData.cubicDWTConvFac = agrLiList[1].Apttus_CMConfig__AttributeValueId__r.APT_Cubic_Factor__c != null ? String.valueOf(agrLiList[1].Apttus_CMConfig__AttributeValueId__r.APT_Cubic_Factor__c) : '';

				eventData.action = NEW_STANDARD_RATING_PLAN_ACTION_LABEL;
				eventData.actionId = NEW_STANDARD_RATING_PLAN_ACTION_ID;
				List<BillingAccountWrapper.item> ratingPlanItemList = new List<BillingAccountWrapper.item>();
				// Below flags are used to iterate only once for agreement line items with identical product classification
				Boolean completeFeatureMappingOnce = false;
				Boolean completeSurchargesMappingOnce = false;
				Boolean completeReturnMappingOnce = false;
				Boolean completeFuelSurchargesMappingOnce = false;
				// Loop through each agreement line item and map product related fields to the payload
				for(Apttus__AgreementLineItem__c agreementLineItem : agrLiList){
					BillingAccountWrapper.item ratePlanItemRef;
					// Mapping for APPC-Standard and APPC-Premium product classification
					if((APPC_SPEED_STANDARD_PRODUCT_CLASSIFICATION.equalsIgnoreCase(agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Apttus_Product_Classification__c)
						|| APPC_SPEED_PREMIUM_PRODUCT_CLASSIFICATION.equalsIgnoreCase(agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Apttus_Product_Classification__c)) &&
						agreementLineItem.APT_Option_Name_Without_Tier__c != null){
						ratePlanItemRef = new BillingAccountWrapper.item();
						ratePlanItemRef.ratingPlanItemId = '';
						ratePlanItemRef.rateCardCategory = agreementLineItem.Apttus_CMConfig__OptionId__r.SAP_Product_Code__c != null ? agreementLineItem.Apttus_CMConfig__OptionId__r.SAP_Product_Code__c : '';
						ratePlanItemRef.lodgementZoneType = agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Lodgement_Zone_Code__c != null ? agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Lodgement_Zone_Code__c : '';
						ratePlanItemRef.destinationZoneType = agreementLineItem.APT_Price_Structure__c;
						ratePlanItemRef.customerTier = agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Customer_Tier__c != null ? agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Customer_Tier__c : '';
						ratePlanItemRef.customRef = agreementLineItem.SAP_Custom_Reference__c != null ? agreementLineItem.SAP_Custom_Reference__c : '';
					}
					// Mapping for APPC-Feature product classification
					if(APPC_FEATURES_PRODUCT_CLASSIFICATION.equalsIgnoreCase(agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Apttus_Product_Classification__c) && !completeFeatureMappingOnce) {
						ratePlanItemRef = new BillingAccountWrapper.item();
						ratePlanItemRef.ratingPlanItemId = '';
						ratePlanItemRef.rateCardCategory = agreementLineItem.Apttus_CMConfig__OptionId__r.SAP_Product_Code__c != null ? agreementLineItem.Apttus_CMConfig__OptionId__r.SAP_Product_Code__c : '';
						ratePlanItemRef.lodgementZoneType = agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Lodgement_Zone_Code__c != null ? agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Lodgement_Zone_Code__c : '';
						ratePlanItemRef.destinationZoneType = agreementLineItem.APT_Price_Structure__c;
						ratePlanItemRef.customerTier = agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Customer_Tier__c != null ? agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Customer_Tier__c : '';
						ratePlanItemRef.customRef = agreementLineItem.SAP_Custom_Reference__c != null ? agreementLineItem.SAP_Custom_Reference__c : '';
						BillingAccountWrapper.feature feature = new BillingAccountWrapper.feature();
						// populate feature node if transit cover type is not blank
						if(agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Transit_Cover_Type__c != null ||
							!String.isBlank(agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Transit_Cover_Type__c)){
								feature.totDeclaredCover = Integer.valueOf(agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c);
								// T-COVER1 for Adhoc transit cover type, else TCOVER-NR
								if(agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Transit_Cover_Type__c == TRANSIT_COVER_TYPE_ADHOC){
									feature.pricePoint = PRICE_POINT_ADHOC;
								}
								else{
									feature.pricePoint = PRICE_POINT_ALWAYS_ON;
								}
								ratePlanItemRef.features = new List<BillingAccountWrapper.feature>{feature};
						}
						completeFeatureMappingOnce = true;
					}
					// Mapping for APPC-Surcharge product classification
					if(APPC_SURCHARGES_PRODUCT_CLASSIFICATION.equalsIgnoreCase(agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Apttus_Product_Classification__c) && !completeSurchargesMappingOnce) {
						ratePlanItemRef = new BillingAccountWrapper.item();
						ratePlanItemRef.ratingPlanItemId = '';
						ratePlanItemRef.rateCardCategory = agreementLineItem.Apttus_CMConfig__OptionId__r.SAP_Product_Code__c != null ? agreementLineItem.Apttus_CMConfig__OptionId__r.SAP_Product_Code__c : '';
						ratePlanItemRef.lodgementZoneType = agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Lodgement_Zone_Code__c != null ? agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Lodgement_Zone_Code__c : '';
						ratePlanItemRef.destinationZoneType = agreementLineItem.APT_Price_Structure__c;
						ratePlanItemRef.customerTier = agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Customer_Tier__c != null ? agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Customer_Tier__c : '';
						ratePlanItemRef.customRef = agreementLineItem.SAP_Custom_Reference__c != null ? agreementLineItem.SAP_Custom_Reference__c : '';
						completeSurchargesMappingOnce= true;
					}
					// Mapping for APPC-Return product classification
					if(APPC_RETURNS_PRODUCT_CLASSIFICATION.equalsIgnoreCase(agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Apttus_Product_Classification__c) && !completeReturnMappingOnce) {
						ratePlanItemRef = new BillingAccountWrapper.item();
						ratePlanItemRef.ratingPlanItemId = '';
						ratePlanItemRef.rateCardCategory = agreementLineItem.Apttus_CMConfig__OptionId__r.SAP_Product_Code__c != null ? agreementLineItem.Apttus_CMConfig__OptionId__r.SAP_Product_Code__c : '';
						ratePlanItemRef.lodgementZoneType = agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Lodgement_Zone_Code__c != null ? agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Lodgement_Zone_Code__c : '';
						ratePlanItemRef.destinationZoneType = agreementLineItem.APT_Price_Structure__c;
						ratePlanItemRef.customerTier = agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Customer_Tier__c != null ? agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Customer_Tier__c : '';
						ratePlanItemRef.customRef = agreementLineItem.SAP_Custom_Reference__c != null ? agreementLineItem.SAP_Custom_Reference__c : '';
						completeReturnMappingOnce = true;
					}
					// Mapping for APPC-FuelSurcharge product classification
					if(APPC_FUEL_SURCHARGES_PRODUCT_CLASSIFICATION.equalsIgnoreCase(agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Apttus_Product_Classification__c) && !completeFuelSurchargesMappingOnce) {
						ratePlanItemRef = new BillingAccountWrapper.item();
						ratePlanItemRef.ratingPlanItemId = '';
						ratePlanItemRef.rateCardCategory = agreementLineItem.Apttus_CMConfig__OptionId__r.SAP_Product_Code__c != null ? agreementLineItem.Apttus_CMConfig__OptionId__r.SAP_Product_Code__c : '';
						ratePlanItemRef.lodgementZoneType = agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Lodgement_Zone_Code__c != null ? agreementLineItem.Apttus_CMConfig__OptionId__r.APT_Lodgement_Zone_Code__c : '';
						ratePlanItemRef.destinationZoneType = agreementLineItem.APT_Price_Structure__c;
						ratePlanItemRef.customerTier = agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Customer_Tier__c != null ? agreementLineItem.Apttus_CMConfig__AttributeValueId__r.APT_Customer_Tier__c : '';
						ratePlanItemRef.customRef = agreementLineItem.SAP_Custom_Reference__c != null ? agreementLineItem.SAP_Custom_Reference__c : '';
						completeFuelSurchargesMappingOnce = true;
					}

					if(ratePlanItemRef != null){
						ratingPlanItemList.add(ratePlanItemRef);
					}
				}
				ratingPlanData.item = ratingPlanItemList;
				eventData.data = ratingPlanData;
				eventDataList.add(eventData);
				activateRatePlan.eventData = eventDataList;
			}
			return activateRatePlan;
		}catch (Exception e) {
			throw new AuraHandledException('Error occurred while generating rating plan activation payload: ' + e.getMessage());
		}
	}

	/**
	 * @description		This method asynchronously update the contract relationship field on Apttus Contract, regardless of rating plan integration status
	 * @param			id contractId, String billingAccountOrOrganisation
	 * @return			void
	 */
	@future
	public static void updateApttusContract(id contractId, String billingAccountOrOrganisation){
		Apttus__APTS_Agreement__c updateApttusCon = new Apttus__APTS_Agreement__c();
		updateApttusCon.Id = contractId;
		updateApttusCon.Contract_Relationship__c = billingAccountOrOrganisation;
		try{
			ApplicationDatabase.getInstance().dmlUpdate(new List<Apttus__APTS_Agreement__c>{updateApttusCon});
		}catch(Exception ex){
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'B&G Sales', 'CreateBillingAccountHelper' , 'updateApttusContract', null, LoggingLevel.ERROR);
		}
	}

	/**
	 * @description		This method creates External Onboarding Request prior to rating plan activation creation and its record Id will be passed as one of the attribute called as Transaction Id in request payload.
	 * @param			BillingAccountWrapper ratingPlanWrapper, String onboardingRequestId, String requestObjId
	 * @return			ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation wrapper
	 */
	public static ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation externalOnboardingRequestDetailsForRatingPlanActivation(BillingAccountWrapper ratingPlanWrapper, String onboardingRequestId, String requestObjId){
		/*
			A new custom Metadata to configure if the org is integration with SAP for billing account creation/rating plan.
			If yes then actual Integration flow will be executed . If not then a mocking framework will
			be used to create the event and further billing account/rating plan record within salesforce.
		*/
		ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation externalOnboardingRequestWithConnectionDetailsVar = new ExternalOnboardingRequestWithConnectionDetailsForRatingPlanActivation();
		try{
			List<SAP_Integration__mdt> sapIntegrationRecord = getSAPIntegrationMetadataRecords('Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'');
			// Live Connection
			if(sapIntegrationRecord[0].Connected__c =='Yes'){
				externalOnboardingRequestWithConnectionDetailsVar.connected = true;
				externalOnboardingRequestWithConnectionDetailsVar.onboardingRequestId = onboardingRequestId;
				externalOnboardingRequestWithConnectionDetailsVar.ratingPlanWrapper = ratingPlanWrapper;
			}else{
				// Create a mock response for Rating Plan Creation
				Integer len = 8;
				String str = string.valueof(Math.abs(Crypto.getRandomLong()));
				String randomNumber = str.substring(0, len);
				Integer numberOfReq = ratingPlanWrapper.ratingPlanActivation.customer.size();
				// each rating plan payload
				for(Integer i=0;i<numberOfReq;i++){
					BillingAccountCreationEvent__e ratingPlan = new BillingAccountCreationEvent__e();
					ratingPlan.Additional_Info__c =  APT_Constants.RATING_PLAN_ACTIVATION_LABEL;
					ratingPlan.Billing_Account_Number__c =  ratingPlanWrapper.ratingPlanActivation.customer[i].objectId;
					ratingPlan.Request_Object_Id__c = ratingPlanWrapper.ratingPlanActivation.customer[i].requestObjId;
					ratingPlan.Source_System__c = 'SAP';
					ratingPlan.Transaction_Id__c = onboardingRequestId;
					ratingPlan.Status__c= 'Success';
					ratingPlan.Status_Description__c = 'Mocking the response - Rating plan '+ randomNumber + ' is activated';
					ratingPlan.Rating_Plan_Id__c= randomNumber;
					EventBus.publish(ratingPlan);
				}
				// final rollup payload for DSR
				BillingAccountCreationEvent__e finalPayload = new BillingAccountCreationEvent__e();
				finalPayload.Additional_Info__c =  APT_Constants.RATING_PLAN_ACTIVATION_LABEL;
				finalPayload.Request_Object_Id__c = requestObjId;
				finalPayload.Status__c= 'Completed';
				finalPayload.Status_Description__c = 'Mocking the response - All rating plans have been activated';
				finalPayload.Transaction_Id__c = onboardingRequestId;
				EventBus.publish(finalPayload);

				CreateBillingAccountController.ratingPlanInfo ratingPlanDetails = new CreateBillingAccountController.ratingPlanInfo();
				ratingPlanDetails.hasAPPCProduct = true;
				ratingPlanDetails.isBillingAccountPlusRatingPlanFlow = false;
				updateDSRAndChargeAccount(requestObjId, null, onboardingRequestId, finalPayload.Status__c, finalPayload.Status_Description__c, ratingPlanDetails);
				externalOnboardingRequestWithConnectionDetailsVar.connected = false;
				externalOnboardingRequestWithConnectionDetailsVar.onboardingRequestId = onboardingRequestId;
				externalOnboardingRequestWithConnectionDetailsVar.ratingPlanWrapper = ratingPlanWrapper;
			}
		}catch(Exception ex){
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'B&G Sales', 'CreateBillingAccountHelper' , 'externalOnboardingRequestDetailsForRatingPlanActivation', null, LoggingLevel.ERROR);
		}

		return externalOnboardingRequestWithConnectionDetailsVar;
	}
}