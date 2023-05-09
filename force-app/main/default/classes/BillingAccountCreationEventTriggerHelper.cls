	/*
	* @date 2020-11-18
	* @group BillingAccounts
	* @tag BillingAccount
	* @domain Core
	* @description Helper class for BillingAccountCreationEvent__e Trigger. Contains logic to Create Billing accounts
	*              and associate it to the Organisation Record and also update the billing account on related objects as:
	*              1. Apttus Contract
	*              2. DSR
	*              3. Charge Account Request
	* @changelog
	* 2020-11-18 - shashwat.nath@auspost.com.au - Created
	* 2021-05-14 - avaula.jansirani@auspost.com.au - updated (for BCA billing account creation)
	* 2021-05-21 - seth.heang@auspost.com.au - Updates to process Sub-Account Requests response from Camunda, update related fields and bell notification
	* 2021-07-23 - seth.heang@auspost.com.au - Bug Fix STP5550 Remove Filter on Known or Prospect Role in SOQL query on Account and update logic check on HoldingRole Mapping
	* 2021-07-27 - naveen.rajanna@auspost.com.au - REQ2540323 - Changed to use DeveloperName instead of Label for Deal_Enablement_Centre_Queue
	* 2022-02-18 - Naveen.Rajanna@auspost.com.au - INC1911242 - Include RoleType check
	* 2022-08-28 - seth.heang@auspost.com.au - Added method to handle the platform event for rating plan activation response
	* 2022-09-05 - nasir.jawed@auspost.com.au - populating the lodgement point on billing account and charge account
	* 2023-03-01 - deepak.kemidi@auspost.com.au - CI-703 added conditions for DSR creation based on selection of APPC product during Sub Account creation process
	*/

	public with sharing class BillingAccountCreationEventTriggerHelper {
	// Class level Variables
	public static final String ORGID = UserInfo.getOrganizationId();
	public static Map<id,Account> organisationMap ;
	public static Map<id,Deal_Support_Request__c> dealsupportRequestMap ;
	public static Map<id,Organisation_Role__c> organisationToOrganisationRoleMap ;
	public static Map<id,id> dsrIdorganisationIdMap = new Map<id,id>();
	public static Map<string ,id> billingAccountNumberDSRMap= new Map<string,id>();

	public static Map<id,id> caIdorganisationIdMap = new Map<id,id>();
	public static Map<string ,id> billingAccountNumberCAMap= new Map<string,id>();

	public static List<BillingAccountCreationEvent__e> billingAccountEvents = new List<BillingAccountCreationEvent__e>();
	public static Map<String,Billing_Account__c> billingAccountMap = new Map<String,Billing_Account__c>();
	public static Map<String,BillingAccountCreationEvent__e> platformEventsMap= new Map<String,BillingAccountCreationEvent__e>();
	public static Set<String> parentBillingAccountNumberSet = new Set<String>();
	public static Map<Id,APT_Sub_Account__c> subAccountMap;
	private static final String DSR_OBJECT = 'Deal_Support_Request__c';
	private static final String CA_OBJECT = 'APT_Credit_Assessment__c';
	private static final String SUB_ACCOUNT_REQUEST = 'APT_Sub_Account__c';
	private static final String AGREEMENT_LODGEMENT_POINT_OBJ = 'APT_Agreement_Lodgement_Point__c';
	private static final String RATING_MODEL_PD = 'PD';
	public static Map<String, Billing_Account__c> newlyCreatedBillingAccountsMap;
	public static String objectName;
	public static Map<id,Deal_Support_Request__c> dealSupportRequestUpdate;
	public static Map<id,APT_Credit_Assessment__c> caMap;
	public static Map<id,Deal_Support_Request__c> dsrFINAL;
	public Static Set<Id> dsrIdSet = new Set<Id>();
	public Static Set<Id> caIdSet = new Set<Id>();


	/* Shashwat.Nath@Auspost.com has created this method to handle the billing account creation platform events
		published by CAMUNDA to create the billing account in salesforce and associate it to the respective organisation.
		The method takes list of platform events as an input parameter
		*/
	public static void createBillingAccount(List<BillingAccountCreationEvent__e> listEvents) {
		List<Billing_Account__c> billingAccountList  = new List<Billing_Account__c>();
		List<sObject> updateRelatedRecords = new List<sObject>();
		Set<id> organisationIdSet = new Set<Id>();
		Set<id> loggingRequestIdSet = new Set<Id>();
		Set<id> subAccountRequestId = new Set<Id>();
		dsrFINAL = new Map<id,Deal_Support_Request__c>();

		List<BAMExternalOnboardingRequest__c> onboardingRequestTobeUpdated = new List<BAMExternalOnboardingRequest__c>();
		billingAccountEvents = listEvents;
		/* Iterating on List of platform events */
		try{
			String objectName = '';
			for(BillingAccountCreationEvent__e billingAccountEvent : listEvents){
				loggingRequestIdSet.add(billingAccountEvent.Transaction_Id__c);
				platformEventsMap.put(billingAccountEvent.Billing_Account_Number__c , billingAccountEvent);
				organisationIdSet.add(billingAccountEvent.Organisation_Record_Id__c);
				objectName = String.valueOf(id.valueOf(billingAccountEvent.Request_Object_Id__c)?.getsobjecttype());

				if(CA_OBJECT.equalsIgnoreCase(objectName)){
					caIdSet.add(billingAccountEvent.Request_Object_Id__c);
					// Map of CA record ID to respective Organisation ID
					caIdorganisationIdMap.put(billingAccountEvent.Request_Object_Id__c , billingAccountEvent.Organisation_Record_Id__c );//not using this for now
					// Map of Billing Account Number to the CA Record Id
					billingAccountNumberCAMap.put(billingAccountEvent.Billing_Account_Number__c , billingAccountEvent.Request_Object_Id__c); //not using this for now
				}else if(DSR_OBJECT.equalsIgnoreCase(objectName)){
					dsrIdSet.add(billingAccountEvent.Request_Object_Id__c);
					billingAccountNumberDSRMap.put(billingAccountEvent.Billing_Account_Number__c , billingAccountEvent.Request_Object_Id__c);
				}

				if(billingAccountEvent.Sub_Account_Request_Id__c != null){
					subAccountRequestId.add(billingAccountEvent.Sub_Account_Request_Id__c);
				}

				if(billingAccountEvent.Parent_Account_Number__c != null){
					parentBillingAccountNumberSet.add(billingAccountEvent.Parent_Account_Number__c);
				}
			}

			/* Querying the Organisations and its Related Roled based on the Organisation Id's populated on the platform Events . To be used in populating the
				Billing account details at the time of creation of the Billing Account and updating the Role of the Organisation from
				Prospect to customer
				*/
			// Bug Fix STP5550 - Remove Filter on Known or Prospect Role in Account SOQL query
			organisationMap = AccountsSelector.newInstance().selectById(organisationIdSet , new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES, AccountsSelector.Options.WITH_HOLDINGROLE});
			// Creating a Map of Organisation to its Associated Role
			organisationToOrganisationRoleMap = new Map<id,Organisation_Role__c>();
			for(Account acc : organisationMap.values()){
				for(Organisation_Role__c orgRole : acc.Organisation_Roles__r){
					organisationToOrganisationRoleMap.put(acc.id,orgRole);
				}
			}

			system.debug('***Organisation Map***' +organisationToOrganisationRoleMap);
			/* Querying the Deal Support request records from the ID's populated on the platform Events and storing it in a Map if the Requesting
				object is DSR */

			// Jansi :  Get the map of CA id and CA records
			caMap = CreditsAssessmentSelector.newInstance(getCAFieldsSet()).selectById(caIdSet);
			dealsupportRequestMap = DealSupportRequestsSelector.newInstance().selectById(dsrIdSet ,
									new Set<object>{
										DealSupportRequestsSelector.Options.WITH_OWNER,
										DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT,
										DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST,
										DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT,
										DealSupportRequestsSelector.Options.WITH_CONTRACT,
										DealSupportRequestsSelector.Options.WITH_ORGANISATION
									});
			subAccountMap = new Map<Id,APT_Sub_Account__c>(SubAccountRequestsSelector.newInstance().selectById(subAccountRequestId));

			Map<id, BAMExternalOnboardingRequest__c > externalOnboardingRequestMap = new Map<id, BAMExternalOnboardingRequest__c >();
			externalOnboardingRequestMap = ExternalOnboardingRequestSelector.newInstance().selectById(loggingRequestIdSet);
			BAMExternalOnboardingRequest__c loggingRequestRecord = new BAMExternalOnboardingRequest__c();
			Boolean isSubAccountReq = false;
			Boolean hasParentAccount = false;

			for(BillingAccountCreationEvent__e billingAccountEvent : listEvents){
				/* Creating Instances of the External Onboarding object records associated to each Request made to
					CAMUNDA for Logging Purpose
				*/
				if(billingAccountEvent.Request_Object_Id__c != null){
					objectName = String.valueOf(id.valueOf(billingAccountEvent.Request_Object_Id__c)?.getsobjecttype());
				}

				isSubAccountReq = billingAccountEvent.Sub_Account_Request_Id__c != null;
				hasParentAccount = billingAccountEvent.Parent_Account_Number__c != null;
				loggingRequestRecord.id = billingAccountEvent.Transaction_Id__c;
				loggingRequestRecord.Status__c = billingAccountEvent.Status__c;
				if(externalOnboardingRequestMap.get(billingAccountEvent.Transaction_Id__c)?.Response_Payload__c == null){
					loggingRequestRecord.Response_Payload__c = JSON.serialize(billingAccountEvent);
				}
				else if(externalOnboardingRequestMap.get(billingAccountEvent.Transaction_Id__c)?.Response_Payload__c != null){
					loggingRequestRecord.Response_Payload__c =  externalOnboardingRequestMap.get(billingAccountEvent.Transaction_Id__c).Response_Payload__c +',\n' + JSON.serialize(billingAccountEvent);
				}

				/* Setting up the Billing Account Details when the Status of the Platform event publised by Camunda is a Success.
					Billing account number and MLID are provided as a response attributes from SAP-> CAMUNDA->Salesforce while
					other details of the Billing account are populated from the Organisation record to which the Billing account would
					get associated to
					*/

				if(billingAccountEvent.Status__c.containsIgnoreCase('Success') && billingAccountEvent.Organisation_Record_Id__c != null ){
					/* Populate the billing account details */

					Billing_Account__c billingAccountRecord = getBillingAccountFromEvent(billingAccountEvent);
					// Adding billing accounts to a list
					billingAccountList.add(billingAccountRecord);
				}
				System.debug('----isSubAccountReq:'+isSubAccountReq);
				System.debug('----hasParentAccount:'+hasParentAccount);
				//Both 'success' and 'Error' scenarios of DSR
				if(objectName == DSR_OBJECT && !isSubAccountReq && !hasParentAccount){
					if('TEAM'.equalsIgnoreCase(billingAccountEvent.Source_System__c)){
						updateRelatedRecords.add(updateDSR(billingAccountEvent));
					}
					else{
						System.debug('----else');
						updateDSR(billingAccountEvent);
					}
				}
				else if(objectName == CA_OBJECT && billingAccountEvent.Status__c.containsIgnoreCase('Error')){
					updateRelatedRecords.add(updateCA(billingAccountEvent, ''));
				}
			}

			if(loggingRequestRecord.id != null){
				onboardingRequestTobeUpdated.add(loggingRequestRecord);
			}

			/* Update the Onboarding Requests record with the Status and Response Payload for Logging Purpose */
			if(!onboardingRequestTobeUpdated.isEmpty()){
				ApplicationDatabase.getInstance().dmlUpdate(onboardingRequestTobeUpdated);
			}

			system.debug('billing account to be inserted' +billingAccountList);
			/* Inserting the Billing Accounts */
			if(!billingAccountList.isEmpty()){
				ApplicationDatabase.getInstance().dmlInsert(billingAccountList);
			}
			system.debug('billing account inserted' +billingAccountList);
			/* On successful creation of Billing accounts in salesforce preparing all the realted records to be
				updated accordingly with the newly created billing Account
			*/

			updateRelatedRecords.addAll(updateRelatedObjects(billingAccountList, billingAccountEvents));
			system.debug('In Here 2'+updateRelatedRecords);

			/* Updating Related records which includes DSR , Apttus contract , Charge Account Request , Organisation Role
				in one go */
			if(!updateRelatedRecords.isEmpty()){
				ApplicationDatabase.getInstance().dmlUpdate(updateRelatedRecords);
			}

			Map<Id,APT_Sub_Account__c> eparcelEnabledSubAccountReqMap = new Map<Id,APT_Sub_Account__c>();
			for(sObject obj : updateRelatedRecords){
				if(SUB_ACCOUNT_REQUEST.equalsIgnoreCase(String.ValueOf(obj.Id?.getsobjecttype()))

					//APT_Sub_Account__c subAccReq = (APT_Sub_Account__c)obj;
					&& 'Success'.equalsIgnoreCase(((APT_Sub_Account__c)obj).APT_Sub_Account_Request_Status__c)
					&& 'Yes'.equalsIgnoreCase(subAccountMap.get(((APT_Sub_Account__c)obj).id).APT_eParcel_Enabled__c)
					&& 'Billing Account'.equalsIgnoreCase(subAccountMap.get(((APT_Sub_Account__c)obj).id).APT_Source_of_Sub_Account_Request__c)
					//CI-703 Add the condition to create DSR only if (Is_Parcel_Send_Login_Required__c =='No' && Product__c!='APPC') OR Is_Parcel_Send_Login_Required__c=='Yes'
					&& ((subAccountMap.get(((APT_Sub_Account__c)obj).id).Is_Parcel_Send_Login_Required__c =='No' && subAccountMap.get(((APT_Sub_Account__c)obj).id).Product__c!='APPC') || (subAccountMap.get(((APT_Sub_Account__c)obj).id).Is_Parcel_Send_Login_Required__c =='YES'))){
						eparcelEnabledSubAccountReqMap.put(obj.id, (APT_Sub_Account__c)obj);

				}
			}

			List<Deal_Support_Request__c> dsrListforCustomNotification = new List<Deal_Support_Request__c>();
			if(!eparcelEnabledSubAccountReqMap.isEmpty()){
				system.debug('**elms enabled complete Sub Account Request**' +eparcelEnabledSubAccountReqMap);
				dsrListforCustomNotification = createDSRforSubAccounts(eparcelEnabledSubAccountReqMap);
			}

			/* Sending Custom Notifications to the owners of the DSR from where the Billing account creation request
				was Initiated both on Success and failure
			*/
			sendCustomNotificationforEachBillingAccount(listEvents,dsrListforCustomNotification);

		}
		catch(Exception ex) {
			UTIL_LoggingService.logHandledException(ex, ORGID, 'Sales', 'BillingAccountCreationEventTriggerHelper' , 'createBillingAccount', 'BillingAccountCreationEventTrigger', LoggingLevel.ERROR);
		}
	}

	/**
	 * @description This method handles the billing account creation platform events for rating plan activation response payload
	 * 				published by CAMUNDA and create APT_SAP_Contracts__c records and update other appropriate records including DSR and Agreement Lodgement Point.
	 * @param		List<BillingAccountCreationEvent__e>
	 * @return		void
	 * */
	public static void activateRatingPlan(List<BillingAccountCreationEvent__e> listEvents){
		try{
			List<BAMExternalOnboardingRequest__c> onboardingRequestTobeUpdated = new List<BAMExternalOnboardingRequest__c>();
			Set<Id> loggingRequestIdSet = new Set<Id>();
			List<SObject> updatedRecords = new List<SObject>();
			List<SObject> insertedRecords = new List<SObject>();
			Set<String> billingAccNumberSet = new Set<String>();
			Map<String,Billing_Account__c> billingAccNumMap = new Map<String,Billing_Account__c>();

			Deal_Support_Request__c dsr = new Deal_Support_Request__c();
			// Save a list of External Onboarding request(log) Id or Transaction Id
			for(BillingAccountCreationEvent__e ratingPlanEvent : listEvents){
				loggingRequestIdSet.add(ratingPlanEvent.Transaction_Id__c);
				if(ratingPlanEvent.Billing_Account_Number__c != null || !String.isBlank(ratingPlanEvent.Billing_Account_Number__c)){
					billingAccNumberSet.add(ratingPlanEvent.Billing_Account_Number__c);
				}
			}

			if(billingAccNumberSet.size() > 0){
				// Query Billing Account records based on billing account number for SAP contract creation
				for(Billing_Account__c ba: BillingAccountsSelector.newInstance().selectByAccountNumber(billingAccNumberSet).values()){
					billingAccNumMap.put(ba.LEGACY_ID__c, ba);
				}
			}

			// Query and update to append BAMExternalOnboardingRequest__c response payload with each new platform event with the same external onboarding request Id
			Map<id, BAMExternalOnboardingRequest__c > externalOnboardingRequestMap = new Map<id, BAMExternalOnboardingRequest__c >();
			externalOnboardingRequestMap = ExternalOnboardingRequestSelector.newInstance().selectById(loggingRequestIdSet);
			// Query DSR details based on Request_Object_Id__c from External Onboarding Request Id
			dsr = DealSupportRequestsSelector.newInstance().selectById(new Set<Id>{externalOnboardingRequestMap.values()[0].Request_Object_Id__c},
							new Set<object>{
								DealSupportRequestsSelector.Options.WITH_ORGANISATION
							}).values()[0];

			Map<Id, BAMExternalOnboardingRequest__c> loggingRequestMap = new Map<Id, BAMExternalOnboardingRequest__c>();
			Map<Id, Deal_Support_Request__c> ratinPlanDSRMap = new Map<Id, Deal_Support_Request__c>();
			// Loop and process each rating plan platform event
			for(BillingAccountCreationEvent__e ratingPlanEvent : listEvents){
				BAMExternalOnboardingRequest__c loggingRequestRecord = new BAMExternalOnboardingRequest__c();
				// update external onboarding record with status from platform event
				loggingRequestRecord.Id = ratingPlanEvent.Transaction_Id__c;
				loggingRequestRecord.Status__c = ratingPlanEvent.Status__c;

				// update response payload if blank or update to append response payload in a new line if already exists
				if(externalOnboardingRequestMap.get(ratingPlanEvent.Transaction_Id__c)?.Response_Payload__c == null){
					loggingRequestRecord.Response_Payload__c = JSON.serialize(ratingPlanEvent);
				}
				else if(externalOnboardingRequestMap.get(ratingPlanEvent.Transaction_Id__c)?.Response_Payload__c != null){
					loggingRequestRecord.Response_Payload__c =  externalOnboardingRequestMap.get(ratingPlanEvent.Transaction_Id__c).Response_Payload__c +',\n' + JSON.serialize(ratingPlanEvent);
				}
				loggingRequestMap.put(loggingRequestRecord.Id, loggingRequestRecord);

				/**
				 * Check request_object_id from platform event if it's of DSR type or Agreement lodgement point type
				 * For each rating plan activation request, a platform event for rating plan is received from Camunda with request_object_id of Agreement lodgement point type
				 * Finally, an additional final rollup platform event for all rating plan requests per same transaction is received from Camunda with request_object_id of DSR type
				 *  */
				String objectName = String.valueOf(id.valueOf(ratingPlanEvent.Request_Object_Id__c)?.getsobjecttype());
				if(AGREEMENT_LODGEMENT_POINT_OBJ.equalsIgnoreCase(objectName)){
					// update agreement lodgment point with rating plan status and description from platform event
					APT_Agreement_Lodgement_Point__c alp = updateAgreementLodgementPoint(ratingPlanEvent);
					updatedRecords.add(alp);
					// create SAP Contract record for only successful rating plan creation
					if('Success'.equalsIgnoreCase(ratingPlanEvent.Status__c)){
						Id billingAccId;
						if(billingAccNumMap.get(ratingPlanEvent.Billing_Account_Number__c) != null){
							billingAccId = billingAccNumMap.get(ratingPlanEvent.Billing_Account_Number__c).Id;
						}
						APT_SAP_Contracts__c newSAPCon = createSAPContract(externalOnboardingRequestMap.get(ratingPlanEvent.Transaction_Id__c), ratingPlanEvent, dsr, billingAccId);
						insertedRecords.add(newSAPCon);
					}
				}
				// Final Platform Event to rollup status on DSR
				else if(DSR_OBJECT.equalsIgnoreCase(objectName)){
					// update DSR with rating plan status and description details
					Deal_Support_Request__c updateDSR = updateRatingDSR(ratingPlanEvent);
					ratinPlanDSRMap.put(updateDSR.Id, updateDSR);
					// send bell notification for all statuses; Completed, Partial Success, Error
					sendCustomNotificationforEachRatingPlan(ratingPlanEvent, dsr);
				}
			}
			// Add BAM logs and DSR for DML update
			if(loggingRequestMap.size() > 0){
				updatedRecords.addAll((List<SObject>)loggingRequestMap.values());
			}
			if(ratinPlanDSRMap.size() > 0){
				updatedRecords.addAll((List<SObject>)ratinPlanDSRMap.values());
			}
			if(updatedRecords.size() > 0){
				ApplicationDatabase.getInstance().dmlUpdate(updatedRecords);
			}
			if(insertedRecords.size() > 0){
				ApplicationDatabase.getInstance().dmlInsert(insertedRecords);
			}
		}catch(Exception ex){
			UTIL_LoggingService.logHandledException(ex, ORGID, 'Sales', 'BillingAccountCreationEventTriggerHelper' , 'activateRatingPlan', 'BillingAccountCreationEventTrigger', LoggingLevel.ERROR);
		}
	}


	/**
	 * @description		This method update Rating plan integration related field on DSR from Rating Plan platform event received from Camunda
	 * @param 			BillingAccountCreationEvent__e ratingPlanPE
	 * @return 			Deal_Support_Request__c
	 */
	public static Deal_Support_Request__c updateRatingDSR(BillingAccountCreationEvent__e ratingPlanPE){
		Deal_Support_Request__c dsrUpdate = new Deal_Support_Request__c();
		dsrUpdate.Id = ratingPlanPE.Request_Object_Id__c;
		dsrUpdate.Rating_Integration_Status__c = ratingPlanPE.Status__c;
		dsrUpdate.Rating_Integration_Status_Description__c = ratingPlanPE.Status_Description__c;
		dsrUpdate.Rating_Integration_Transaction_Id__c = ratingPlanPE.Transaction_Id__c;
		return dsrUpdate;
	}

	/**
	 * @description		This method create SAP Contract record and populate appropriate field values based on successful Rating Plan activation request
	 * @param			BAMExternalOnboardingRequest__c bamRecord, BillingAccountCreationEvent__e ratingPlanPE, Deal_Support_Request__c dsr, Id billingAccId
	 * @return 			APT_SAP_Contracts__c
	 */
	public static APT_SAP_Contracts__c createSAPContract(BAMExternalOnboardingRequest__c bamRecord, BillingAccountCreationEvent__e ratingPlanPE, Deal_Support_Request__c dsr, Id billingAccId){
		APT_SAP_Contracts__c sapCon = new APT_SAP_Contracts__c();
		sapCon.APT_SAP_Contract_Number__c = ratingPlanPE.Rating_Plan_Id__c;
		sapCon.APT_Apttus_Contract__c = dsr.APT_Contract__c;
		sapCon.SAP_Contract_Status__c  = APT_Constants.ACTIVE;
		sapCon.APT_Material_Material_Description__c = RATING_MODEL_PD;
		sapCon.APT_Comments_1__c = dsr.Name; // DSR Number
		sapCon.Organisation__c = dsr.Organisation__c; // Use account id lookup on DSR to skip a SOQL based on Account Legacy Id to get Account Id
		if(ratingPlanPE.Billing_Account_Number__c != null || !String.isBlank(ratingPlanPE.Billing_Account_Number__c)){
			sapCon.APT_Contract_Sold_To_Billing_Account__c = ratingPlanPE.Billing_Account_Number__c;
			sapCon.APT_Billing_Account__c  = billingAccId;
		}else if(ratingPlanPE.Organisation_Record_Id__c != null || !String.isBlank(ratingPlanPE.Organisation_Record_Id__c)){
			sapCon.APT_Contract_Sold_To_Billing_Account__c = ratingPlanPE.Organisation_Record_Id__c;
		}
		sapCon.APT_Contract_Start_Date__c = Date.valueOf(bamRecord?.createdDate) + 1;
		// maximum acceptable date by Salesforce is 31 Dec 4000
		// source: https://help.salesforce.com/s/articleView?id=sf.fields_date_range.htm&type=5
		sapCon.APT_Contract_End_Date__c  = Date.newInstance(4000, 12, 31);
		return sapCon;
	}

	/* Shashwat.Nath@auspost.com has created this method to prepare the Billing account records based on the values on each of the incoming platform
		Events from CAMUNDA for both Charge Account and Sub Account.
	*/
	public static Billing_Account__c getBillingAccountFromEvent(BillingAccountCreationEvent__e billingAccountEvent){
		Billing_Account__c billingAccountRecord = new Billing_Account__c();
		String objectName = String.valueOf(id.valueOf(billingAccountEvent.Request_Object_Id__c)?.getsobjecttype());

		if('SAP'.equalsIgnoreCase(billingAccountEvent.Source_System__c)) {
			billingAccountRecord.Source_System__c = 'SAP ERP';
			billingAccountRecord.Credit_Group__c = billingAccountEvent.Credit_Group__c;
			billingAccountRecord.Type__c = billingAccountEvent.Type__c;
			billingAccountRecord.Search_Term__c = billingAccountEvent.Billing_Account_Name__c.left(20);
		}
		if ('TEAM'.equalsIgnoreCase(billingAccountEvent.Source_System__c)) {
			billingAccountRecord.Credit_Person_Phone__c = billingAccountEvent.Credit_Officer_Phone__c;
			billingAccountRecord.ST_Priority_Customer__c = organisationMap.get(billingAccountEvent.Organisation_Record_Id__c).Is_Strategic_Account_StarTrack__c;
			billingAccountRecord.Source_System__c = billingAccountEvent.Source_System__c;
		}

		if(CA_OBJECT.equalsIgnoreCase(objectName)){

			billingAccountRecord.Organisation__c = billingAccountEvent.Organisation_Record_Id__c;
			billingAccountRecord.name = billingAccountEvent.Billing_Account_Name__c;
			billingAccountRecord.LEGACY_ID__c = billingAccountEvent.Billing_Account_Number__c;
			billingAccountRecord.Credit_Person_Code__c = billingAccountEvent.Credit_Person_Code__c;
			billingAccountRecord.Credit_Person__c = billingAccountEvent.Credit_Person__c;
			//billingAccountRecord.Source_System__c = billingAccountEvent.Source_System__c;

			APT_Credit_Assessment__c ca = caMap.get(billingAccountEvent.Request_Object_Id__c);
			billingAccountRecord.ABN__c = ca?.APT_ABN__c;
			billingAccountRecord.ACN__c = ca?.APT_ACN__c;
			billingAccountRecord.Street__c = (ca?.APT_Postal_Address_Line_1__c + (ca.APT_Postal_Address_Line_2__c != null ? (' '+ca.APT_Postal_Address_Line_2__c) : '')).left(60);
			billingAccountRecord.Suburb__c = ca?.APT_Postal_City__c;
			billingAccountRecord.Postal_Code__c = ca?.APT_Postal_Postcode__c;
			billingAccountRecord.State__c = ca?.APT_Postal_State__c;
			billingAccountRecord.Country__c = ca?.APT_Postal_Country__c;
			billingAccountRecord.Is_this_a_sub_account__c = 'No';
			billingAccountRecord.Phone_Number__c = ca?.APT_Telephone__c;
			billingAccountRecord.Email__c = ca?.APT_Correspondence_Email_Address__c;
			billingAccountRecord.Customer_Name_2__c = ca?.APT_Legal_Entity_Name__c;
			billingAccountRecord.Credit_Limit__c = ca?.APT_Requested_Credit_Limit__c;

		}
		else if(billingAccountEvent.Sub_Account_Request_Id__c != null){
			billingAccountRecord.Street__c = subAccountMap.get(billingAccountEvent.Sub_Account_Request_Id__c)?.APT_Postal_Address_Street_Name__c;
			billingAccountRecord.Suburb__c = subAccountMap.get(billingAccountEvent.Sub_Account_Request_Id__c)?.APT_Postal_Address_Suburb__c;
			billingAccountRecord.Postal_Code__c = subAccountMap.get(billingAccountEvent.Sub_Account_Request_Id__c)?.APT_Postal_Address_Street_Postcode__c;
			billingAccountRecord.State__c = subAccountMap.get(billingAccountEvent.Sub_Account_Request_Id__c)?.APT_Postal_Address_State__c;
			billingAccountRecord.Country__c = subAccountMap.get(billingAccountEvent.Sub_Account_Request_Id__c)?.APT_Postal_Address_Country_Code__c;
			billingAccountRecord.Phone_Number__c = subAccountMap.get(billingAccountEvent.Sub_Account_Request_Id__c)?.APT_Sub_Account_Contact_Telephone__c;
			billingAccountRecord.Credit_Person_Code__c = billingAccountEvent.Credit_Person_Code__c;
			billingAccountRecord.Organisation__c = billingAccountEvent.Organisation_Record_Id__c;
			billingAccountRecord.name = subAccountMap.get(billingAccountEvent.Sub_Account_Request_Id__c)?.Name;
			billingAccountRecord.Customer_Name_2__c = subAccountMap.get(billingAccountEvent.Sub_Account_Request_Id__c)?.APT_Account_Name_2__c;
			billingAccountRecord.Email__c = subAccountMap.get(billingAccountEvent.Sub_Account_Request_Id__c)?.APT_Sub_Account_Contact_Email_Address__c;
			billingAccountRecord.LEGACY_ID__c = billingAccountEvent.Billing_Account_Number__c;
			billingAccountRecord.Is_this_a_sub_account__c = 'Yes';
			APT_Sub_Account__c sar = subAccountMap.get(billingAccountEvent.Sub_Account_Request_Id__c);

			if('Yes'.equalsIgnoreCase(sar.APT_eParcel_Enabled__c)){
				billingAccountRecord.MLID__c = billingAccountEvent.MLID__c;
			}
		}
		else{

			Account org = organisationMap.get(billingAccountEvent.Organisation_Record_Id__c);
			Deal_Support_Request__c dsr = dealsupportRequestMap.get(billingAccountEvent.Request_Object_Id__c);

			billingAccountRecord.Organisation__c = billingAccountEvent.Organisation_Record_Id__c;
			billingAccountRecord.name = billingAccountEvent.Billing_Account_Name__c;
			billingAccountRecord.LEGACY_ID__c = billingAccountEvent.Billing_Account_Number__c;
			billingAccountRecord.Credit_Person_Code__c = billingAccountEvent.Credit_Person_Code__c;
			billingAccountRecord.Credit_Person__c = billingAccountEvent.Credit_Person__c;
			billingAccountRecord.ABN__c = org?.ABN__c;
			billingAccountRecord.ACN__c = org?.ACN__c;
			billingAccountRecord.Street__c = org?.BillingStreet;
			billingAccountRecord.Suburb__c = org?.BillingCity;
			billingAccountRecord.Postal_Code__c = org?.BillingPostalCode;
			billingAccountRecord.State__c = org?.BillingState;
			/*Shashwat.Nath@auspost.com Updated the Country code population as there is a chance that it would be blank at the Related Organisation Level however it
				needs to be populated on the Billing Account as AU if its blank  */
			if(!String.IsBlank(org.BillingCountry)){
				billingAccountRecord.Country__c = org.BillingCountry;
			}
			else{
				billingAccountRecord.Country__c = 'AU';
			}
			billingAccountRecord.Is_this_a_sub_account__c = 'No';
			// billingAccountRecord.Credit_Group__c = billingAccountEvent.Credit_Group__c;
			//billingAccountRecord.Type__c = billingAccountEvent.Type__c;
			billingAccountRecord.Business_Solutions_Contact__c = org ?.Primary_Business_Solutions_Contact__c;
			// billingAccountRecord.Search_Term__c = billingAccountEvent.Billing_Account_Name__c.left(20);
			billingAccountRecord.Phone_Number__c = dsr?.APT_Contract__r?.Apttus__Primary_Contact__r?.phone != null ? dsr?.APT_Contract__r?.Apttus__Primary_Contact__r?.phone : dsr?.APT_Contract__r?.Apttus__Primary_Contact__r?.MobilePhone;
			billingAccountRecord.Fax_Number__c = dsr?.APT_Contract__r?.Apttus__Primary_Contact__r?.Fax;
			billingAccountRecord.Email__c = dsr?.APT_Contract__r?.Apttus__Primary_Contact__r?.Email;

			if ('SAP'.equalsIgnoreCase(billingAccountEvent.Source_System__c)) {
				if(org?.Organisation_Trading_Name__c !=null){
					billingAccountRecord.Customer_Name_2__c =  org?.Name;
				}
				billingAccountRecord.MLID__c = billingAccountEvent.MLID__c;
				billingAccountRecord.Credit_Limit__c = dsr?.APT_Contract__r?.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.Aus_Post_Proposed_for_New_Account__c;
			}else  if ('TEAM'.equalsIgnoreCase(billingAccountEvent.Source_System__c)) { //[Jansi added - 07-05-2021]
				billingAccountRecord.Credit_Limit__c = dsr?.APT_Contract__r?.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.StarTrack_Proposed_for_New_Account__c;
			}
		}

		return billingAccountRecord;
	}

	/* Shashwat.Nath@auspost.com has created this method to prepare the DSR records to be updated with the Billing account
		details on success and error details on Error
	*/
	public static Deal_Support_Request__c updateDSR(BillingAccountCreationEvent__e billingAccountEvent){
		Deal_Support_Request__c dsrTobeUpdated = new Deal_Support_Request__c();
		try{
			if('Success'.equalsIgnoreCase(billingAccountEvent.Status__c) || 'Partial Success'.equalsIgnoreCase(billingAccountEvent.Status__c)){
				dsrTobeUpdated.Billing_Number__c = billingAccountEvent.Billing_Account_Number__c;
			}

			dsrTobeUpdated.id = billingAccountEvent.Request_Object_Id__c;
			dsrTobeUpdated.Integration_Status__c = billingAccountEvent.Status__c;
			dsrTobeUpdated.Integration_Transaction_Id__c = billingAccountEvent.Transaction_Id__c;
			dsrTobeUpdated.Integration_Status_Description__c = billingAccountEvent.Status_Description__c;
			System.debug('+++dealSupportRequestUpdate:' + dealSupportRequestUpdate);
			System.debug('+++dsrTobeUpdated:' + dsrTobeUpdated);
			dealSupportRequestUpdate = new Map<Id,Deal_Support_Request__c>();
			dealSupportRequestUpdate.put(dsrTobeUpdated.id, dsrTobeUpdated);

		}
		catch(Exception ex) {
			UTIL_LoggingService.logHandledException(ex, ORGID, 'Sales', 'BillingAccountCreationEventTriggerHelper' , 'updateDSR', 'BillingAccountCreationEventTrigger', LoggingLevel.ERROR);
		}

		return dsrTobeUpdated;
	}


	/* avula.jansirani@auspost.com.au has created this method to prepare the CA records to be updated with the Billing account
		details on success and error details on Error
	*/
	public static APT_Credit_Assessment__c  updateCA(BillingAccountCreationEvent__e billingAccountEvent, String billingRecordId){
		APT_Credit_Assessment__c caTobeUpdated = new APT_Credit_Assessment__c();

		//-- If billing account created successfully then populating Billing number in CA record
		if(String.isNotEmpty(billingRecordId) &&
			('Success'.equalsIgnoreCase(billingAccountEvent.Status__c) || 'Partial Success'.equalsIgnoreCase(billingAccountEvent.Status__c))){
				caTobeUpdated.Billing_Account__c = billingRecordId;
				//wiping out the 'direct debit' info on success scenario
				caTobeUpdated.Direct_Debit_Account_Name__c = '';
				caTobeUpdated.Direct_Debit_Bank_Name__c = '';
				caTobeUpdated.Direct_Debit_BSB_Number__c = '';
				caTobeUpdated.Direct_Debit_Account_Number__c = '';
			}
		//-- populating integration status and its description in 'CA' record
		caTobeUpdated.id = billingAccountEvent.Request_Object_Id__c;
		caTobeUpdated.Integration_Status__c = billingAccountEvent.Status__c;
		caTobeUpdated.Integration_Transaction_Id__c = billingAccountEvent.Transaction_Id__c;
		caTobeUpdated.Integration_Status_Description__c = billingAccountEvent.Status_Description__c;
		System.debug('+++caTobeUpdated:' + caTobeUpdated);

		return caTobeUpdated;
	}

	/**
	 * @description		check if this platform event is for APPC product
	 * @param			N/A
	 * @return			true for APPC product, false for non-APPC product (eg. eParcel/International)
	 */
	public static boolean validateAPPCProduct(){
		for(Deal_Support_Request__c dsr : dealsupportRequestMap.values()){
			if(dsr.APT_Contract__r.APT_APPC_Count__c > 0){
				return true;
			}
		}
		return false;
	}

	/* Shashwat.Nath@auspost.com has created this method to prepare all the other related records to be updated with the
		billing account after successful creation . This includes apttus contract , Charge Account Request , Organisation role
		and Organisation
	*/
	public static List<sObject> updateRelatedObjects (List<Billing_Account__c> billingAccountList , List<BillingAccountCreationEvent__e> billingAccountEvents){
		List<sObject> relatedObjectsToBeUpdated = new List<sObject>();
		newlyCreatedBillingAccountsMap = new Map<String, Billing_Account__c>();
		system.debug('****Parent number set ****'+parentBillingAccountNumberSet);
		system.debug('****billingAccountList ****'+billingAccountList);
		//for(Billing_Account__c billAcc :[Select id , PAYER_ACCOUNT_ID__c , Organisation__c, LEGACY_ID__c from Billing_Account__c Where id IN :billingAccountList OR LEGACY_ID__c  IN:parentBillingAccountNumberSet] ){
		boolean hasAPPCProduct = validateAPPCProduct();
		Id contractId = dealsupportRequestMap.get(billingAccountEvents[0].Request_Object_Id__c)?.APT_Contract__c;
		List<APT_Agreement_Lodgement_Point__c> alpList;
		// For APPC product only, Query Agreement Lodgement Point based on contract Id and update the Billing Account Number
		if(hasAPPCProduct == true){
			alpList = APT_AgreementLodgementPointsSelector.newInstance().selectByApttusContractId(new set<Id>{contractId}, new set<Object>{APT_AgreementLodgementPointsSelector.Options.WITH_NETWORK}).values();
		}

		for(Billing_Account__c billAcc : BillingAccountsSelector.newInstance().selectByIdorAccountNumber(billingAccountList , parentBillingAccountNumberSet).Values()){
			newlyCreatedBillingAccountsMap.put(billAcc.LEGACY_ID__c, billAcc);
		}
		system.debug('****Billing Account List****'+newlyCreatedBillingAccountsMap);
		try{
			List<Holding_Role_Reference__c> newAccHoldingRoleList =  HoldingReferenceRoleSelector.newInstance().selectByName('New Accounts' ).values();
			// added by Jansi - 13 -05-2021
			Holding_Role_Reference__c newAccountHoldingRole = !newAccHoldingRoleList.isEmpty() ? newAccHoldingRoleList[0] : null;

			for(Billing_Account__c billingAccountRecord :  newlyCreatedBillingAccountsMap.Values()){

				if(platformEventsMap.containsKey(billingAccountRecord.LEGACY_ID__c) &&
				String.isBlank(platformEventsMap.get(billingAccountRecord.LEGACY_ID__c).Sub_Account_Request_Id__c) &&
				String.isBlank(platformEventsMap.get(billingAccountRecord.LEGACY_ID__c).Parent_Account_Number__c)){
					// Setting up apttus contract to be updated

					//Jansi : Only for DSR. For CA billingAccountNumberDSRMap will be blank.
					if(billingAccountRecord?.LEGACY_ID__c != null && billingAccountNumberDSRMap.get(billingAccountRecord?.LEGACY_ID__c) !=null){
						Apttus__APTS_Agreement__c apttusContract = new Apttus__APTS_Agreement__c();
						apttusContract.id = dealsupportRequestMap.get(billingAccountNumberDSRMap.get(billingAccountRecord?.LEGACY_ID__c))?.APT_Contract__c;
						if(apttusContract.id!=null){
							apttusContract.Billing_Account__c = billingAccountRecord.id;
							relatedObjectsToBeUpdated.add(apttusContract);
						}
					}
					// Setting up charge Account to be updated
					//Jansi : Only for DSR. For CA billingAccountNumberDSRMap will be blank.
					if(billingAccountRecord?.LEGACY_ID__c != null && billingAccountNumberDSRMap.get(billingAccountRecord?.LEGACY_ID__c) !=null){
						APT_Charge_Account__c car = new APT_Charge_Account__c();
						car.id = dealsupportRequestMap.get(billingAccountNumberDSRMap.get(billingAccountRecord?.LEGACY_ID__c))?.APT_Contract__r?.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.APT_Charge_Account__c;
						if(car.id!=null) {
							if(hasAPPCProduct == true){
								//Populating the new field APPC_Primary_Lodgement_Point__c on the billing Account and on charge Account on field APT_Principal_Lodgement_Location__c
								for(APT_Agreement_Lodgement_Point__c alp : alpList){
									// rating plan linked at Charge Account Request level or Org level
									if(alp.APT_Charge_Account__c != null ||
										(alp.APT_Charge_Account__c == null && alp.APT_Sub_Account__c == null && alp.APT_Billing_Account__c == null)) {
										//populate Lodgement point
										car.APT_Principal_Lodgement_Location__c = alp.APT_Lodgement_Point_Lookup__r.Post_Code__c;

										//populate LP on the respected Billing account record
										billingAccountRecord.APPC_Primary_Lodgement_Point__c = alp.APT_Lodgement_Point_Lookup__r.Post_Code__c;
										relatedObjectsToBeUpdated.add(billingAccountRecord);
									}
								}
							}
							car.Billing_Account__c = billingAccountRecord.id;
							car.Status__c = 'Completed';
							relatedObjectsToBeUpdated.add(car);
						}
					}
					// Setting up Organisation role and account to be updated
					//Jansi : For both DSR & CA. We need to update Organisation role and holding role reference.
					// Need to check with Min choon if this is only needed for DSR records?
					if(organisationToOrganisationRoleMap.containskey(billingAccountRecord.Organisation__c) &&
						organisationToOrganisationRoleMap.get(billingAccountRecord.Organisation__c)!=null){
						Organisation_Role__c  orgRole = new Organisation_Role__c();
						orgRole.id = organisationToOrganisationRoleMap.get(billingAccountRecord.Organisation__c).id;
						// Only Update Role to "Customer" When Holding Role is "Known" or "Prospect"
						String roleType = organisationToOrganisationRoleMap.get(billingAccountRecord.Organisation__c).Role_Type__c; // Bug Fix INC1911242
						// Only Update Role to "Customer" When Holding Role is "Known" or "Prospect"
						if(orgRole.id!=null && ('Known'.equalsIgnoreCase(roleType) || 'Prospect'.equalsIgnoreCase(roleType))){
							orgRole.Role_Type__c = 'Customer';
							relatedObjectsToBeUpdated.add(orgRole);
						}
						// Setting up Account for updating the holding Role to New Accounts
						Account acc = new Account();
						acc.id = billingAccountRecord.Organisation__c;
						String holdingRole = organisationMap.get(billingAccountRecord.Organisation__c).Holding_Role_Reference__r.Name;
						// Bug Fix STP-5550 OR REQ2571490: Only Update Holding Role to "New Accounts" When Holding Role is "Known" or "Prospect"
						if(acc.id!=null && newAccountHoldingRole!=null && ('Known'.equalsIgnoreCase(holdingRole) || 'Prospect'.equalsIgnoreCase(holdingRole))){
							acc.Holding_Role_Reference__c = newAccountHoldingRole.id;
							relatedObjectsToBeUpdated.add(acc);
						}
					}

					String objectName = String.valueOf(id.valueOf(platformEventsMap.get(billingAccountRecord.LEGACY_ID__c).Request_Object_Id__c)?.getsobjecttype());
					//-- only for CA
					if(CA_OBJECT.equalsIgnoreCase(objectName)){
						relatedObjectsToBeUpdated.add(updateCA(platformEventsMap.get(billingAccountRecord.LEGACY_ID__c), billingAccountRecord.Id));
					}
				}
				else{
					//This can be also executed for CA records.
					billingAccountMap.put(billingAccountRecord.LEGACY_ID__c, billingAccountRecord );
					if(platformEventsMap.get(billingAccountRecord.LEGACY_ID__c) != null){
						billingAccountRecord.PAYER_ACCOUNT_ID__c =  newlyCreatedBillingAccountsMap.get(platformEventsMap.get(billingAccountRecord.LEGACY_ID__c).Parent_Account_Number__c).Id;
						billingAccountRecord.Credit_Person_Code__c = newlyCreatedBillingAccountsMap.get(platformEventsMap.get(billingAccountRecord.LEGACY_ID__c).Parent_Account_Number__c).Credit_Person_Code__c;
						billingAccountRecord.Credit_Person__c = newlyCreatedBillingAccountsMap.get(platformEventsMap.get(billingAccountRecord.LEGACY_ID__c).Parent_Account_Number__c).Credit_Person__c;
						relatedObjectsToBeUpdated.add(billingAccountRecord);
					}
				}
			}
			// flag to represent sub-account request originated from Proposal
			Boolean isProposalFlow = false;
			Integer subAccCount = 0;
			//Integer subAccErrorCount = 0;
			Deal_Support_Request__c dsrUpdate;
			boolean isSAP = false;
			for(BillingAccountCreationEvent__e evnt : billingAccountEvents ){
				String objectName = String.valueOf(id.valueOf(evnt.Request_Object_Id__c)?.getsobjecttype());
				if(!CA_OBJECT.equalsIgnoreCase(objectName) &&'SAP'.equalsIgnoreCase(evnt.Source_System__c)){
					isSAP = true;
				}
				//Will check Min choon if this will come for CA record or not.
				// Platform Event is for Sub-Account
				if(evnt.Parent_Account_Number__c != null){
					subAccCount++;
					APT_Sub_Account__c subAccountRequestRecord = new APT_Sub_Account__c();
					subAccountRequestRecord.id = evnt.Sub_Account_Request_Id__c;
					subAccountRequestRecord.Sub_Account_Number__c = evnt.Billing_Account_Number__c;

					// For APPC product, update "Sub Account Request" level Agreement Lodgement Point with Billing Account lookup Id
					if(hasAPPCProduct == true){
						for(APT_Agreement_Lodgement_Point__c alp : alpList){
							if(alp.APT_Sub_Account__c == subAccountRequestRecord.id){
								alp.APT_Billing_Account__c = newlyCreatedBillingAccountsMap.get(evnt.Billing_Account_Number__c)?.Id;
								relatedObjectsToBeUpdated.add(alp);
							}
						}
					}
					if('Success'.equalsIgnoreCase(evnt.Status__c) || 'Partial Success'.equalsIgnoreCase(evnt.Status__c)){
						subAccountRequestRecord.APT_Sub_Account_Request_Status__c = evnt.Status__c;
						// Check source of sub account request - only allow Proposal source to update DSR
						if(subAccountMap.get(subAccountRequestRecord.id).APT_Source_of_Sub_Account_Request__c == 'Proposal'){
							isProposalFlow = true;
							Deal_Support_Request__c dsrSubAcc = new Deal_Support_Request__c();
							if(dealsupportRequestMap!=null && dealsupportRequestMap.get(evnt.Request_Object_Id__c)!=null){
								dsrSubAcc = dealsupportRequestMap.get(evnt.Request_Object_Id__c);
							}
							// Append ";" after each sub-account number received from camunda and populate to DSR's sub-account number field
							if((String.ISBLANK(dsrSubAcc.Sub_Accounts__c) || dsrSubAcc.Sub_Accounts__c == null)){
								dsrSubAcc.Sub_Accounts__c = subAccountRequestRecord.Sub_Account_Number__c;
							}else if(!String.ISBLANK(dsrSubAcc.Sub_Accounts__c) && dsrSubAcc.Sub_Accounts__c != null
									&& !dsrSubAcc.Sub_Accounts__c.contains(subAccountRequestRecord.Sub_Account_Number__c) && subAccountRequestRecord.Sub_Account_Number__c != null){
								dsrSubAcc.Sub_Accounts__c = dsrSubAcc.Sub_Accounts__c + ';' + subAccountRequestRecord.Sub_Account_Number__c;
							}
							// Retrieve DSR from dealSupportRequestUpdate Map and populate the sub-account number field
							Deal_Support_Request__c dsrChargeSubAcc;
							if(dealSupportRequestUpdate!=null && dealSupportRequestUpdate.get(evnt.Request_Object_Id__c)!=null){
								dsrChargeSubAcc = dealSupportRequestUpdate.get(evnt.Request_Object_Id__c);
							}
							if(dsrChargeSubAcc!= null && dsrChargeSubAcc.id == dsrSubAcc.id && dsrChargeSubAcc != null){
								dsrChargeSubAcc.Sub_Accounts__c = dsrSubAcc.Sub_Accounts__c;
							}
							// Save DSR with latest details in the final map
							if(dsrChargeSubAcc != null){
								dsrFINAL.put(dsrChargeSubAcc.id,dsrChargeSubAcc);
							}else{
								dsrFINAL.put(dsrSubAcc.id,dsrSubAcc);
							}
						}
					}
					else if('Error'.equalsIgnoreCase(evnt.Status__c)){
						subAccountRequestRecord.APT_Sub_Account_Request_Status__c = evnt.Status__c;
						//subAccErrorCount++;
					}

					subAccountRequestRecord.Sub_Account_Request_Status_Description__c = evnt.Status_Description__c;
					subAccountRequestRecord.Transaction_Id__c = evnt.Transaction_Id__c;
					if(newlyCreatedBillingAccountsMap.get(evnt.Parent_Account_Number__c) != null){
						subAccountRequestRecord.APT_Billing_Account__c = newlyCreatedBillingAccountsMap?.get(evnt.Parent_Account_Number__c).id;
					}
					relatedObjectsToBeUpdated.add(subAccountRequestRecord);
				}
				// Platform Event is for Billing Account
				else{
					// Add DSR object
					if(dealSupportRequestUpdate!=null && dealSupportRequestUpdate.get(evnt.Request_Object_Id__c)!=null){
						dsrUpdate = dealSupportRequestUpdate.get(evnt.Request_Object_Id__c);
					}
					// For APPC product, update "Charge Account Request" level Agreement Lodgement Point with Billing Account lookup Id
					if(hasAPPCProduct == true){
						for(APT_Agreement_Lodgement_Point__c alp : alpList){
							if( alp.APT_Charge_Account__c != null && alp.APT_Sub_Account__c == null && alp.APT_Billing_Account__c == null){
								alp.APT_Billing_Account__c = newlyCreatedBillingAccountsMap.get(evnt.Billing_Account_Number__c)?.Id;
								relatedObjectsToBeUpdated.add(alp);
								break;
							}
						}
					}
				}
			}
			// is Proposal Flow, add DSR to list to be DML updated
			if(isSAP && isProposalFlow && subAccCount > 0){
				relatedObjectsToBeUpdated.add(dsrFINAL.values());
			}
			System.debug('---subAccCount: ' + subAccCount);
			//System.debug('---dsrUpdate.Id' + dsrUpdate.Id);
			System.debug('---dsrUpdate: ' + dsrUpdate);

			// Charge Account only scenario, add DSR to list to be DML updated
			if(isSAP && subAccCount == 0 && dsrUpdate != null){
				dsrFINAL.put(dsrUpdate.id,dsrUpdate);
				relatedObjectsToBeUpdated.add(dsrFINAL.values());
			}
		}
		catch(Exception ex) {
			UTIL_LoggingService.logHandledException(ex, ORGID, 'Sales', 'BillingAccountCreationEventTriggerHelper' , 'updateDSR', 'BillingAccountCreationEventTrigger', LoggingLevel.ERROR);
		}

		return relatedObjectsToBeUpdated ;
	}


	/**
	 * @description		This method send custom bell notification to DSR's owner with appropriate message based on Rating Plan integration status("Completed", "Partial Success", "Error")
	 * 					in the final platform event sent from Camunda
	 * @param			BillingAccountCreationEvent__e eachEvent, Deal_Support_Request__c dsr
	 * @return 			void
	 *
	 */
	public static void sendCustomNotificationforEachRatingPlan(BillingAccountCreationEvent__e eachEvent, Deal_Support_Request__c dsr) {
		/**
		 * Querying the custom notification Type:
		 * Selector Framework fails on ApplicationSelector.QueryBuilder.addFields(getSObjectFieldList()) with below error message
		 * 		System.NoAccessException: Insufficient Privileges: You do not have the level of access necessary to perform the operation you requested.
		 * 		Please contact the owner of the record or your administrator if access is necessary.
		 * This may be due to immutability property of CustomNotificationType metadata obj:
		 * https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_customnotificationtype.htm
		 */
		CustomNotificationType customNotifType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Custom_Notification' LIMIT 1];
		if(customNotifType != null){
			Messaging.CustomNotification notification = new Messaging.CustomNotification();
			notification.setSenderId(Userinfo.getUserId());
			notification.setNotificationTypeId(customNotifType.id);
			notification.setTargetId(dsr.Id);
			if('Completed'.equalsIgnoreCase(eachEvent.Status__c)) {
				notification.setBody('Click here to go to the DSR record');
				notification.setTitle('Rating Plan activation request for '+ dsr.Organisation__r.Name +' is completed');
			}
			else if('Partial Success'.equalsIgnoreCase(eachEvent.Status__c)) {
				notification.setBody('Click here to navigate to exception description and remedial action');
				notification.setTitle('Rating Plan creation has been successful, one or more rating plan activation has failed.');
			}
			else if('Error'.equalsIgnoreCase(eachEvent.Status__c)) {
				notification.setBody('Click here to go to the DSR record. Once error has been remediated, click on the Rating Plan Retry button.');
				notification.setTitle('Rating Plan activation request for '+ dsr.Organisation__r.Name +' has encountered an Error. Please Reach out to the IT Support Team.');
			}
			notification.send(new Set<String>{
				dsr.OwnerId
			});
		}
	}

	/* Shashwat.Nath@auspost.com created this method to send bell notifications to the owners of the DSR on successful and
		unsuccessful Billing Account creation
		*/
	public static void sendCustomNotificationforEachBillingAccount(List<BillingAccountCreationEvent__e> listEvents , List<Deal_Support_Request__c> dsrList) {
		try{
			// Querying the custom notification Type
			List<CustomNotificationType> customNotificationTypeList = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Custom_Notification' LIMIT 1];
			if(!customNotificationTypeList.isEmpty()){
				for (BillingAccountCreationEvent__e eachEvent : listEvents) {

					String objectName = String.valueOf(id.valueOf(eachEvent.Request_Object_Id__c)?.getsobjecttype());
						//[Jansi:] Ignoring the email notification for CA
					if(!CA_OBJECT.equalsIgnoreCase(objectName)){
					if(eachEvent.Request_Object_Id__c != null){
						objectName = String.valueOf(id.valueOf(eachEvent.Request_Object_Id__c)?.getsobjecttype());
					}
					if(eachEvent.Sub_Account_Request_Id__c !=null){
						objectName = String.valueOf(id.valueOf(eachEvent.Sub_Account_Request_Id__c)?.getsobjecttype());
					}
					// Setting up Notifications on Sucess
					if('Success'.equalsIgnoreCase(eachEvent.Status__c)) {
						Messaging.CustomNotification notification = new Messaging.CustomNotification();
						notification.setSenderId(Userinfo.getUserId());
						notification.setNotificationTypeId(customNotificationTypeList[0].id);
						if (eachEvent.Request_Object_Id__c != null && objectName == DSR_OBJECT && dealsupportRequestMap.containskey(eachEvent.Request_Object_Id__c)) {
							//TargetObjectId
							notification.setTargetId(eachEvent.Request_Object_Id__c);
							notification.setBody('Click here to go to the DSR record');
							notification.setTitle('Billing account creation request for ' + organisationMap.get(eachEvent.Organisation_Record_Id__c) ?.name + ' is completed');
							notification.send(new Set<String>{
									dealsupportRequestMap.get(eachEvent.Request_Object_Id__c) ?.ownerId
							});
						}
						else if(eachEvent.Sub_Account_Request_Id__c !=null && objectName == SUB_ACCOUNT_REQUEST){
							notification.setTargetId(billingAccountMap.get(eachEvent.Billing_Account_Number__c).id);
							notification.setBody('Click here to go to the Sub Account record');
							notification.setTitle('Sub Account-' + eachEvent.Billing_Account_Number__c + ' for SAP Billing Account-' + eachEvent.Parent_Account_Number__c + ' has been Successfully Completed.');
							if(DSR_OBJECT.equalsIgnoreCase(String.valueOf(id.valueOf(eachEvent.Request_Object_Id__c)?.getsobjecttype()))){
								notification.send(new Set<String>{
									dealsupportRequestMap.get(eachEvent.Request_Object_Id__c) ?.ownerId
								});
							}else{
								notification.send(new Set<String>{
									subAccountMap.get(eachEvent.Sub_Account_Request_Id__c) ?.ownerId
								});
							}
						}
					}
					// Setting up Notifications on Partial Success
					if('Partial Success'.equalsIgnoreCase(eachEvent.Status__c)){
						Messaging.CustomNotification notification = new Messaging.CustomNotification();
						notification.setSenderId(Userinfo.getUserId());
						notification.setNotificationTypeId(customNotificationTypeList[0].id);
						if (eachEvent.Request_Object_Id__c != null && objectName == DSR_OBJECT && dealsupportRequestMap.containskey(eachEvent.Request_Object_Id__c)) {
							//TargetObjectId
							notification.setTargetId(eachEvent.Request_Object_Id__c);
							notification.setBody('Click here to navigate to exception description and remedial action');
							notification.setTitle('New Charge and/or Sub Account - '+ eachEvent.Billing_Account_Number__c + ' has been created with exceptions in SAP ERP. Review and remediation actions required to ensure Billing Account is fully operational.');
							notification.send(new Set<String>{
									dealsupportRequestMap.get(eachEvent.Request_Object_Id__c) ?.ownerId
							});
						}
						else if(eachEvent.Sub_Account_Request_Id__c !=null && objectName == SUB_ACCOUNT_REQUEST){
							notification.setTargetId(billingAccountMap.get(eachEvent.Billing_Account_Number__c).id);
							notification.setBody('Click here to navigate to exception description and remedial action');
							notification.setTitle('New Charge and/or Sub Account - '+ eachEvent.Billing_Account_Number__c + ' has been created with exceptions in SAP ERP. Review and remediation actions required to ensure Billing Account is fully operational.');
							if(DSR_OBJECT.equalsIgnoreCase(String.valueOf(id.valueOf(eachEvent.Request_Object_Id__c)?.getsobjecttype()))){
								notification.send(new Set<String>{
									dealsupportRequestMap.get(eachEvent.Request_Object_Id__c) ?.ownerId
								});
							}else{
								notification.setTargetId(eachEvent.Sub_Account_Request_Id__c);
								notification.send(new Set<String>{
									subAccountMap.get(eachEvent.Sub_Account_Request_Id__c) ?.ownerId
								});
							}
						}
					}
					// Setting up Notifications on Failure
					if('Error'.equalsIgnoreCase(eachEvent.Status__c)) {
						Messaging.CustomNotification notification = new Messaging.CustomNotification();
						notification.setNotificationTypeId(customNotificationTypeList[0].id);
						notification.setSenderId(Userinfo.getUserId());
						if (eachEvent.Request_Object_Id__c != null && objectName == DSR_OBJECT && dealsupportRequestMap.containskey(eachEvent.Request_Object_Id__c)) {
							notification.setBody('Click here to go to the DSR record');
							notification.setTitle('Billing account creation request for ' + organisationMap.get(eachEvent.Organisation_Record_Id__c) ?.name + ' has encountered an Error . Please Reach out to the IT Support Team');
							notification.setTargetId(eachEvent.Request_Object_Id__c); // target object id
							notification.send(new Set<String>{
									dealsupportRequestMap.get(eachEvent.Request_Object_Id__c) ?.ownerId
							});
						}
						else if(eachEvent.Sub_Account_Request_Id__c !=null && objectName == SUB_ACCOUNT_REQUEST){
							notification.setTargetId(eachEvent.Sub_Account_Request_Id__c);
							notification.setBody('Click here to go to the SAR record');
							notification.setTitle('Sub Account request for SAP Billing Account-'+ eachEvent.Parent_Account_Number__c +' has encountered an Error. Please raise a Service Now Ticket via Report a Fault, and follow the required error handling sub account business process to ensure request is successfully completed.');
							if(DSR_OBJECT.equalsIgnoreCase(String.valueOf(id.valueOf(eachEvent.Request_Object_Id__c)?.getsobjecttype()))){
								notification.send(new Set<String>{
									dealsupportRequestMap.get(eachEvent.Request_Object_Id__c) ?.ownerId
								});
							}else{
								notification.send(new Set<String>{
									subAccountMap.get(eachEvent.Sub_Account_Request_Id__c) ?.ownerId
								});
							}
						}
					}
					}
				}
				for(Deal_Support_Request__c dsr : dsrList ){
					Messaging.CustomNotification notification = new Messaging.CustomNotification();
					notification.setSenderId(Userinfo.getUserId());
					notification.setNotificationTypeId(customNotificationTypeList[0].id);
					notification.setTargetId(dsr.Id);
					notification.setBody('Click here to go to the DSR record');
					notification.setTitle(dsr.name +' has been submitted to the Contract Administration Team to add contract rates to Sub Account '+ dsr.Sub_Accounts__c +' .');
					notification.send(new Set<String>{
							dsr.Requestor__c
					});
				}
			}
		}
		catch(Exception ex) {
			UTIL_LoggingService.logHandledException(ex, ORGID, 'Sales', 'BillingAccountCreationEventTriggerHelper' , 'sendCustomNotificationforEachBillingAccount', 'BillingAccountCreationEventTrigger', LoggingLevel.ERROR);
		}
	}

	/* Shashwat.Nath@auspost.com has created this method to prepare the DSR records to be created as part of ADD contract rates Sub Account
		Creation . This would also initiate Custom Notifications to the DSR Requestor .
	*/
	public static List<Deal_Support_Request__c> createDSRforSubAccounts(Map<Id,APT_Sub_Account__c> eparcelEnabledSubAccountRequestMap){

		system.debug('**Inside DSR Method**');
		//List<Group> dealEnablementCentre = [Select id from Group where DeveloperName='Deal_Enablement_Centre_Queue' and type ='Queue' LIMIT 1];
		List<Group> dealEnablementCentre = GroupsSelector.newInstance().selectByGroupTypeAndDeveloperName(new Set<String>{'queue'}, new Set<String>{'Deal_Enablement_Centre_Queue'}).values();
		List<Deal_Support_Request__c> dsrToBeInserted = new List<Deal_Support_Request__c>();
		List<Deal_Support_Request__c> dsrSuccessfullyInserted = new List<Deal_Support_Request__c>();
		try{
			for(APT_Sub_Account__c subAcc: SubAccountRequestsSelector.newInstance().selectById(eparcelEnabledSubAccountRequestMap.keyset()).values()){
				Deal_Support_Request__c dsrRecord = new Deal_Support_Request__c();
				dsrRecord.recordtypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Deal_Enablement_Centre').getRecordTypeId();
				dsrRecord.Organisation__c = newlyCreatedBillingAccountsMap.get(subAcc.Sub_Account_Number__c).Organisation__c;
				dsrRecord.Requestor__c = subAcc.ownerId;
				dsrRecord.ownerId = dealEnablementCentre[0].id;
				dsrRecord.Stage__c = 'Submitted';
				dsrRecord.Status__c = 'Submitted';
				dsrRecord.Billing_Number__c = subAcc.APT_Billing_Account_Number__c;
				dsrRecord.Billing_Account__c = newlyCreatedBillingAccountsMap.get(subAcc.Sub_Account_Number__c).id;
				dsrRecord.Sub_Accounts__c = subAcc.Sub_Account_Number__c;
				dsrRecord.CustomerContact1__c = subAcc.SubAccountContact__c;
				dsrRecord.Work_Type__c = 'Add Contract Rates';
				dsrRecord.Support_Work_Type__c = 'Deal Processing';
				dsrRecord.Lodgement_Point_to_Work_Centre_Code__c = subAcc.Lodgement_Point_to_Work_Centre_Code__c;
				dsrRecord.Description__c = 'Add contract rates to new sub account';

				//CI-703 For Is_Parcel_Send_Login_Required__c =='Yes' populate product in DSR with product from sub account
				//If Is_Parcel_Send_Login_Required__c =='No' and Product in SubAccount contains APPC along with other products, just populate the other products
				//If Is_Parcel_Send_Login_Required__c =='No' and Product in SubAccount='APPC'
				if(subAcc.Is_Parcel_Send_Login_Required__c =='Yes') dsrRecord.Product__c=subAcc.Product__c;
				If(subAcc.Is_Parcel_Send_Login_Required__c =='No') {
					If(!subAcc.Product__c.equalsIgnoreCase('APPC')){
						if(subAcc.Product__c.containsIgnoreCase('APPC')) {
							List<String> products = subAcc.Product__c.split(';');
							for(string prod :products){
								if(!prod.equalsIgnoreCase('APPC') && string.isNotEmpty(prod)) {
									if(String.isEmpty(dsrRecord.Product__c)) dsrRecord.Product__c=prod;
									else dsrRecord.Product__c +=';'+prod;
								}
							}
						} else dsrRecord.Product__c = subAcc.Product__c;
					}
				}

				dsrToBeInserted.add(dsrRecord);

			}

			if(!dsrToBeInserted.isEmpty()){
				ApplicationDatabase.getInstance().dmlInsert(dsrToBeInserted);
				//dsrSuccessfullyInserted = [SELECT ID ,NAME , Requestor__c , Sub_Accounts__c from Deal_Support_Request__c where id in : dsrToBeInserted ];
				dsrSuccessfullyInserted = DealSupportRequestsSelector.newInstance().selectByRecordList(dsrToBeInserted).values();
			}
		}
		catch(Exception ex) {
			UTIL_LoggingService.logHandledException(ex, ORGID, 'Sales', 'BillingAccountCreationEventTriggerHelper' , 'createDSRforSubAccounts', 'BillingAccountCreationEventTrigger', LoggingLevel.ERROR);
		}


		return dsrSuccessfullyInserted;

	}

	/*
		* @description	This method updates Agreement Lodgement Point record with appropriate values coming from Camunda's rating plan platform event
		* @param			BillingAccountCreationEvent__e
		* @return			APT_Agreement_Lodgement_Point__c
	*/
	public static APT_Agreement_Lodgement_Point__c updateAgreementLodgementPoint(BillingAccountCreationEvent__e ratingPlanEvent){
		APT_Agreement_Lodgement_Point__c alp = new APT_Agreement_Lodgement_Point__c();
		alp.Id = ratingPlanEvent.Request_Object_Id__c;
		alp.Integration_Status__c = ratingPlanEvent.Status__c;
		alp.Integration_Status_Description__c = ratingPlanEvent.Status_Description__c;
		alp.Rating_Plan_Id__c = ratingPlanEvent.Rating_Plan_Id__c;
		return alp;
	}

	/**
	 * Credit Assessment object fields
	 * */
	private static Set<SobjectField> getCAFieldsSet(){
		return new Set<SObjectField> {
			APT_Credit_Assessment__c.Id,
			APT_Credit_Assessment__c.APT_ABN__c,
			APT_Credit_Assessment__c.APT_ACN__c,
			APT_Credit_Assessment__c.APT_Postal_Address_Line_1__c,
			APT_Credit_Assessment__c.APT_Postal_Address_Line_2__c,
			APT_Credit_Assessment__c.APT_Requested_Credit_Limit__c,
			APT_Credit_Assessment__c.APT_Postal_City__c,
			APT_Credit_Assessment__c.APT_Postal_Postcode__c,
			APT_Credit_Assessment__c.APT_Postal_State__c,
			APT_Credit_Assessment__c.APT_Postal_Country__c,
			APT_Credit_Assessment__c.APT_Telephone__c,
			APT_Credit_Assessment__c.APT_Correspondence_Email_Address__c,
			APT_Credit_Assessment__c.APT_Business_Name__c,
			APT_Credit_Assessment__c.APT_Requested_Credit_Limit__c,
			APT_Credit_Assessment__c.APT_Legal_Entity_Name__c
		};
	}
}