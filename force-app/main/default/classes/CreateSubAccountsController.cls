/*
 * @date 2021-05-12
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description Controller for createSubAccount component and used for billing account creation, contains request payload and send to Camunda for SAP integration
 * @changelog
 * 2021-05-12 - seth.heang@auspost.com.au - created
 * 2021-05-18 - Dheeraj.mandavilli@auspost.com.au - Updated SOQL query on Proposal Object to fetch Opportunity Key Contact id.
 * 2021-06-01 - Dheeraj.mandavilli@auspost.com.au - Added Logic to exclude contact when Is parcel send is set to No.
 * 01/08/2022 - prerna.rahangdale@auspost.com.au - createSubAccounts - Added the validation error if the lodegement zone selected in the Sub Account Request form is not from
 *												 the lodegement zones of proposals.
 * 2022-08-01 - nasir.jawed@auspost.com.au - Created a method validateSearchLodgementZone which defines the lodgement zone and returns boolean value.
 * 2023-01-27 - Sarath Burra - Removing the LodgmentZone Validation for APPC as the Lodgement Zones will be defaulted going forward as per story https://australiapost.jira.com/browse/CI-828
 * 								Lines Removed 125-129
 * 								Also removing the method validateSearchLodgementZone as there will be no Validation of LodgementZone in APPC going forward(Lines 370-416)
 * 2023-03-01 - Deepak Kemidi - CI-703 Add Method checkAPPCContracts to check if atleast one related APPC contracts have Contract Relationship as Billing Account
 * 2023-08-18 - Harry Wang - Refactoring getBillingAccountDetails using selector
 * 2023-10-30 - Ranjeewa Silva - Refactored 'processResponse' method after the changes to BillingAccountService.parseResponse(HttpResponse).
*/
public with sharing class CreateSubAccountsController {
	private static final Map<SObjectType, Set<SObjectField>> BILLING_ACCOUNT_FIELD_OVERRIDES = new Map<SObjectType, Set<SObjectField>>{
			Billing_Account__c.SObjectType => new Set<SObjectField>{Billing_Account__c.Id, Billing_Account__c.LEGACY_ID__c,
					Billing_Account__c.Name, Billing_Account__c.SAP_marked_for_deletion__c, Billing_Account__c.Source_System__c,
					Billing_Account__c.Type__c, Billing_Account__c.PAYER_ACCOUNT_ID__c, Billing_Account__c.LeaderAccount__c},
			Account.SObjectType => new Set<SObjectField>{Account.Name}
	};

	@TestVisible private static stateInfo stateInfoVar;

	@AuraEnabled
	public static Billing_Account__c getBillingAccountDetails(String billingAccountRecord){
		Map<Id, Billing_Account__c> billingAccountMap = BillingAccountsSelector.newInstance(1, BILLING_ACCOUNT_FIELD_OVERRIDES).selectById(new Set<Id> {billingAccountRecord}, new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION});
		if (billingAccountMap.values().size() > 0) {
			return billingAccountMap.values()[0];
		}
		return null;
	}

	//CI-703 Method to check if all the APPC contracts have Contract Relationship as Billing Account
	//If all the contracts associated with the Parent Account of the Billing Account have Contract Relationship as Billing Account, we will display a message for the user
	@AuraEnabled
	public static Boolean checkAPPCContracts(Id billingAccRecId){
		Boolean showMsg = false;
		Integer billingAccRecsCount = 0;
		Integer orgRecsCount = 0;

		// Query Billing Account details and its related Account details by Billing Account Id
		Billing_Account__c billingAccountRec = BillingAccountsSelector.newInstance().selectById(new set<Id>{billingAccRecId}, new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION}).values()[0];
		Set<Id> accIds = new set<Id>{billingAccountRec.Organisation__c};
		for(Apttus__APTS_Agreement__c contract : ApttusContractsSelector.newInstance().search(new Map<String, Object>{'accountIds' => accIds},true)) {
			if(contract.APT_APPC_Count__c != null && contract.APT_APPC_Count__c >0 &&  'Activated'.equalsIgnoreCase(contract.Apttus__Status__c) && 'In Effect'.equalsIgnoreCase(contract.Apttus__Status_Category__c)) {

				if('Billing Account'.equalsIgnoreCase(contract.Contract_Relationship__c)) {
					billingAccRecsCount = billingAccRecsCount + 1;
				} else if('Organisation'.equalsIgnoreCase(contract.Contract_Relationship__c)) {
					OrgRecsCount = OrgRecsCount + 1;
				}
			}
		}

		if(billingAccRecsCount > 0 && orgRecsCount == 0) {
			showMsg = true;
		}

		return showMsg;
	}

	@AuraEnabled
	public static List<APT_Sub_Account__c> getRelatedSubAccountRequests(String billingAccountRecord){
		List<APT_Sub_Account__c> subAccountRequestList = new List<APT_Sub_Account__c>();
		subAccountRequestList = [Select Id, Name, APT_Billing_Account__c,Sub_Account_Name__c,
										APT_Billing_Account_Number__c, APT_Account_Name_2__c , APT_Sub_Account_Contact_Email_Address__c,
										APT_eParcel_Enabled__c,APT_eLMS_Enabled__c,APT_Postal_Address_Street_Name__c,APT_Postal_Address_Suburb__c,
										APT_Postal_Address_State__c,APT_Postal_Address_Street_Postcode__c, APT_Sub_Account_Contact_Telephone__c,
										APT_Source_of_Sub_Account_Request__c,APT_Sub_Account_Request_Status__c,Lodgement_Point_to_Work_Centre_Code__c,Product__c,SubAccountContact__c,Is_Parcel_Send_Login_Required__c,Contact_Name__c
										From APT_Sub_Account__c Where APT_Billing_Account__c =: billingAccountRecord and (APT_Sub_Account_Request_Status__c = 'Draft' OR APT_Sub_Account_Request_Status__c ='Error') ];
		return subAccountRequestList;
	}

	@AuraEnabled
	public static Apttus_Proposal__Proposal__c getProposalDetails(String proposalRecord){
		return [Select Id, Name,APT_Legal_Entity_Name__c,Apttus_Proposal__Account__c,APT_Credit_Assessment__r.APT_Charge_Account__r.Name,Apttus_Proposal__Opportunity__r.KeyContact__c From Apttus_Proposal__Proposal__c Where Id=: proposalRecord];
	}

	@AuraEnabled
	public static List<APT_Sub_Account__c> getRelatedSubAccountRequestsforProposal(String proposalRecord){
		List<APT_Sub_Account__c> subAccountRequestList = new List<APT_Sub_Account__c>();
		subAccountRequestList = [Select Id, Name, APT_Billing_Account__c,Sub_Account_Name__c,
										APT_Billing_Account_Number__c, APT_Account_Name_2__c , APT_Sub_Account_Contact_Email_Address__c,
										APT_eParcel_Enabled__c,APT_eLMS_Enabled__c,APT_Postal_Address_Street_Name__c,APT_Postal_Address_Suburb__c,
										APT_Postal_Address_State__c,APT_Postal_Address_Street_Postcode__c, APT_Sub_Account_Contact_Telephone__c,
										APT_Source_of_Sub_Account_Request__c,APT_Sub_Account_Request_Status__c,Lodgement_Point_to_Work_Centre_Code__c,APT_Charge_Account__r.Name,SubAccountContact__c,Is_Parcel_Send_Login_Required__c,Contact_Name__c
		From APT_Sub_Account__c Where APT_Quote_Proposal__c =: proposalRecord and (APT_Sub_Account_Request_Status__c = 'Draft' OR APT_Sub_Account_Request_Status__c ='Error') ];
		return subAccountRequestList;
	}


	@AuraEnabled
	public static boolean  deleteSubAccounts(List<APT_Sub_Account__c> subAccountList){
		boolean recDeleted = false;
		if (subAccountList != null ) {
			ApplicationDatabase.getInstance().dmlDelete(subAccountList);
			recDeleted = true;
		}
		return recDeleted;
	}

	@AuraEnabled
	public static boolean setPendingStatus(List<APT_Sub_Account__c> subAccountList){
		List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
		boolean recUpdated = false;
		for(APT_Sub_Account__c sar : subAccountList){
			sar.APT_Sub_Account_Request_Status__c = 'Pending Charge Account';
			sarList.add(sar);
		}
		if(!sarList.isEmpty()){
			ApplicationDatabase.getInstance().dmlUpdate(sarList);
			recUpdated = true;
		}
		return recUpdated;
	}

	/**
	 * @Description  : Method updates the status of Sub-Account Request to 'Error' upon submission of the request and Error occurs between Salesforce and Camunda Connection
	 * */
	@AuraEnabled
	public static List<APT_Sub_Account__c> setFailStatus(List<APT_Sub_Account__c> subAccountList){
		List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
		for(APT_Sub_Account__c sar : subAccountList){
			sar.APT_Sub_Account_Request_Status__c = 'Error';
			sarList.add(sar);
		}
		if(!sarList.isEmpty()){
			ApplicationDatabase.getInstance().dmlUpdate(sarList);
		}
		return sarList;
	}

	@AuraEnabled
	public static APT_Sub_Account__c createSubAccounts(APT_Sub_Account__c subAccountRec,String lodgementPointWCCs) {

		//boolean recCreated = false;
		//if(lodgementPointWCCs!=null && existingLodgementPoints == null){
		if(lodgementPointWCCs!=null ){
			// deserialise the JSON and convert to the custom Sboject
			List<SObjectResult> responseDetail = (List<SObjectResult>)System.JSON.deserialize(lodgementPointWCCs, List<SObjectResult>.class);
			// track the count of lodgement point added and stored in 'Lodgement_Point_Counter__c' backend field
			Integer lPcounter = 0;
			subAccountRec.Lodgement_Point_to_Work_Centre_Code__c = '';
			for(SObjectResult so: responseDetail){
				// format the lodgement point and work centre code, and put a line break
				subAccountRec.Lodgement_Point_to_Work_Centre_Code__c += so.recName + ':' + so.recWCC + ':' + so.postCode +'\n';
				// increase the count
				lPcounter++;
			}
		}

		// Update the lodgement point counter to the DSR
		//curDSR.Lodgement_Point_Counter__c = lPcounter;
			if (subAccountRec!=null) {
				try{
					if(subAccountRec.Is_Parcel_Send_Login_Required__c == 'No'){
						subAccountRec.SubAccountContact__c = null;
					}
					subAccountRec.APT_Postal_Address_Country_Code__c = 'AU';
					upsert subAccountRec;
					}
					catch (Exception e) {
				throw new AuraHandledException(e.getMessage());
				}

			}
			return subAccountRec;
	}

	// @description Class for custom object used to store and display the data on table
	public class SObjectResult {
		@AuraEnabled
		public String recName;
		@AuraEnabled
		public String recWCC;
		@AuraEnabled
		public String recAddress;
		@AuraEnabled
		public Id recId;
		@AuraEnabled
		public String postCode;

		public SObJectResult(String recNameTemp, String recWCCTemp, String recAddressTemp, Id recIdTemp, String postCodeVal) {
			recName = recNameTemp;
			recWCC = recWCCTemp;
			recAddress = recAddressTemp;
			recId = recIdTemp;
			postCode = postCodeVal;
		}
	}

	/**
	 * @Description  : Generated the External onboading request record prior to actual billing account creation is triggered.
	 *				 Uses  CreateBillingAccountHelper.ExternalOnboardingRequestDetails() for creation.
	 * */
	@AuraEnabled
	public static CreateSubAccountHelper.externalOnboardingRequestWithConnectionDetails generateExternalOnboardingRecord(List<APT_Sub_Account__c> subAccountRecList, Id billingAccId){

		CreateSubAccountHelper.SubAccountWithEmptyFields subAccEmptyfieldsVar;
		CreateSubAccountHelper.ExternalOnboardingRequestWithConnectionDetails externalOnboardingRequestWithConnectionDetailsVar = new CreateSubAccountHelper.ExternalOnboardingRequestWithConnectionDetails();
		try {
			// Call this method to perform attributes mapping
			subAccEmptyfieldsVar = generateSubAccountCreationRequest(subAccountRecList, billingAccId);
			// Call this method to create External Onboarding Request object
			externalOnboardingRequestWithConnectionDetailsVar = CreateSubAccountHelper.externalOnboardingRequestDetails(subAccEmptyfieldsVar);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return externalOnboardingRequestWithConnectionDetailsVar;
	}

	/**
	 * @Description  : Generated the External onboading request record prior to actual sub account creation is triggered.
	 *				 Uses  CreateSubAccountHelper.externalOnboardingRequestDetails() for creation.
	 * */
	@AuraEnabled
	public static CreateSubAccountHelper.SubAccountWithEmptyFields generateSubAccountCreationRequest(List<APT_Sub_Account__c> subAccountRecList, Id billingAccId){
		List<CreateSubAccountHelper.SubAccountWithEmptyFields> subAccountRequestVarList = new List<CreateSubAccountHelper.SubAccountWithEmptyFields>();
		CreateSubAccountHelper.SubAccountWithEmptyFields subAccountRequestVar = new CreateSubAccountHelper.SubAccountWithEmptyFields();
		List<APT_Sub_Account__c> subAccountQueryList = new List<APT_Sub_Account__c>();
		// extract ID into a set of ID to perform a query on Sub Account Request
		Set<Id> subAccountIdSet = new Set<Id>();
		for(APT_Sub_Account__c sar : subAccountRecList){
			subAccountIdSet.add(sar.Id);
		}

		try{
			// Query Billing Account details and its related Account details by Billing Account Id
			Billing_Account__c billingAccountRec = BillingAccountsSelector.newInstance().selectById(new set<Id>{billingAccId}, new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION}).values()[0];
			// Mapping Section
			BillingAccountWrapper subAccountWrapper = new BillingAccountWrapper(true);
			// Query all required field from Sub Account Request ID including those are not available on the SAR form
			subAccountQueryList = SubAccountRequestsSelector.newInstance().selectByIds(subAccountIdSet, new Set<object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT}).values();

			if(subAccountQueryList.size() > 0){
				List<BillingAccountWrapper.childAccountDetail> childAccList = new List<BillingAccountWrapper.childAccountDetail>();
				for(APT_Sub_Account__c curSubAcc: subAccountQueryList){
					// Mapping attributes from Sub-Account Request from LWC to Sub-Account Wrapper attributes
					BillingAccountWrapper.childAccountDetail curChildAcc = new BillingAccountWrapper.childAccountDetail();

					// Mapping Characteristics
					BillingAccountWrapper.CharacteristicsDetail curChildAccChar = new BillingAccountWrapper.CharacteristicsDetail();

					// map Yes/No value to True/False for request payload
					if('Yes'.equals(curSubAcc?.APT_eParcel_Enabled__c)){
						curChildAccChar.pcmsFlag = true;
					}else if('No'.equals(curSubAcc?.APT_eParcel_Enabled__c)){
						curChildAccChar.pcmsFlag = false;
					}

					if('Yes'.equals(curSubAcc?.APT_eLMS_Enabled__c)){
						curChildAccChar.elmsFlag = true;
					}else if('No'.equals(curSubAcc?.APT_eLMS_Enabled__c)){
						curChildAccChar.elmsFlag = false;
					}

					// Mapping AddressInfo
					BillingAccountWrapper.addressInfoDetail curChildAccAddr = new BillingAccountWrapper.addressInfoDetail();
					curChildAccAddr.street = curSubAcc?.APT_Postal_Address_Street_Name__c;
					curChildAccAddr.city = curSubAcc?.APT_Postal_Address_Suburb__c;
					curChildAccAddr.state = curSubAcc?.APT_Postal_Address_State__c;
					curChildAccAddr.postcode = curSubAcc?.APT_Postal_Address_Street_Postcode__c;
					curChildAccAddr.country = 'AU';

					// Mapping ContactPersons
					BillingAccountWrapper.ContactDetail curChildAccContact = new BillingAccountWrapper.ContactDetail();
					curChildAccContact.firstName = curSubAcc?.SubAccountContact__r?.FirstName;
					curChildAccContact.lastName = curSubAcc?.SubAccountContact__r?.LastName;
					curChildAccContact.contactPersonId = curSubAcc?.SubAccountContact__c;
					BillingAccountWrapper.communicationInfoDetail curChildAccContactComm = new BillingAccountWrapper.communicationInfoDetail();
					curChildAccContactComm.phone = curSubAcc?.SubAccountContact__r?.Phone;
					curChildAccContactComm.mobile = curSubAcc?.SubAccountContact__r?.MobilePhone;
					curChildAccContactComm.email = curSubAcc?.SubAccountContact__r?.Email;
					curChildAccContact.communicationInfo = curChildAccContactComm;


					// CI-703 mapping the APPC products
					List<BillingAccountWrapper.ProductDetail> curChildAccProdList;
					if(!String.isEmpty(curSubAcc.Product__c) && curSubAcc.Product__c.containsIgnorecase('APPC')){
						curChildAccProdList= new List<BillingAccountWrapper.ProductDetail>();
						BillingAccountWrapper.ProductDetail curChildAccProd= new BillingAccountWrapper.ProductDetail();
						curChildAccProd.ratingModel='PD';
						curChildAccProdList.add(curChildAccProd);
						curChildAcc.products = new List<BillingAccountWrapper.ProductDetail>();
						if(!curChildAccProdList.isEmpty()){
							curChildAcc.products.addAll(curChildAccProdList);
						}
					}

					// Mapping Lodgement Point
					List<BillingAccountWrapper.lodgementPointsDetail> curChildAccLPList;
					/**
					 * Field 'Lodgement_Point_to_Work_Centre_Code__c' have value format "LodgementPoint:WorkCentreCode:PostCode"
					 * We extract the WorkCentreCode below by spliting '\n' and loop each entry and further split by colon
					 *  */
					List<String> lpWccPostcodeList = new List<String>();
					lpWccPostcodeList = curSubAcc?.Lodgement_Point_to_Work_Centre_Code__c?.split('\n');
					if(lpWccPostcodeList != null && lpWccPostcodeList.size() > 0){
						curChildAccLPList = new List<BillingAccountWrapper.lodgementPointsDetail>();
						for(String curRow : lpWccPostcodeList){
							List<String> colonSplitList = curRow.split(':');
							BillingAccountWrapper.lodgementPointsDetail curChildAccLP = new BillingAccountWrapper.lodgementPointsDetail();
							// WorkCentreCode is the second element or [1]
							curChildAccLP.lodgementPointId = colonSplitList[1];
							curChildAccLPList.add(curChildAccLP);
						}
					}
					// Assign attribute/object to Wrapper Class
					curChildAcc.characteristics = curChildAccChar;
					curChildAcc.addressInfo = curChildAccAddr;
					curChildAcc.contactPersons = new List<BillingAccountWrapper.ContactDetail>{curChildAccContact};
					curChildAcc.lodgementPoints = new List<BillingAccountWrapper.lodgementPointsDetail>();
					if(curChildAccLPList != null && curChildAccLPList.size() > 0){
						curChildAcc.lodgementPoints.addAll(curChildAccLPList);
					}
					curChildAcc.name1 = curSubAcc.Name;
					curChildAcc.name2 = curSubAcc?.APT_Account_Name_2__c;
					curChildAcc.objectId = curSubAcc.Id;
					curChildAcc.objectType = 'Sub Account';
					childAccList.add(curChildAcc);
				}
				// Populate other informations
				subAccountWrapper.targetSystem = 'SAP';
				subAccountWrapper.processType = 'PT003';
				subAccountWrapper.processTypeDesc = 'Assisted Onboarding - New Sub Account';
				subAccountWrapper.orgRecordId = billingAccountRec?.Organisation__c;
				subAccountWrapper.requestObjId = billingAccId;
				subAccountWrapper.sap.customer.objectType = 'Organisation';
				subAccountWrapper.sap.customer.customerId = billingAccountRec.Organisation__r?.LEGACY_ID__c;
				subAccountWrapper.sap.customer.name1 = billingAccountRec?.Name;
				subAccountWrapper.sap.customer.name2 = billingAccountRec?.Customer_Name_2__c;
				subAccountWrapper.sap.customer.accountGroup = billingAccountRec.Organisation__r?.Customer_Account_Group__c;
				subAccountWrapper.sap.customer.parentBillingAccNo = billingAccountRec?.LEGACY_ID__c;
				subAccountWrapper.sap.customer.childAccount = new List<BillingAccountWrapper.childAccountDetail>();
				subAccountWrapper.sap.customer.childAccount.addAll(childAccList);
				// Populate wrapper object back to custom object
				subAccountRequestVar.subAccountAttributesDetails = subAccountWrapper;
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return subAccountRequestVar;
	}

	/**
	 * @Description : Triggers the actual Billing account creation from the submit button UI at the LWC Component
	 */
	@AuraEnabled(continuation=true)
	public static Object subAccountCreationRequest(String externalOnboardingRequestWithConnectionDetailsVar){
		Boolean callOutSuccessful = false;
		String sourceSystem = 'salesforce';
		CreateSubAccountHelper.externalOnboardingRequestWithConnectionDetails externalOnboardingRequestWithConnectionDetailsRecord = (CreateSubAccountHelper.externalOnboardingRequestWithConnectionDetails)System.JSON.deserialize(externalOnboardingRequestWithConnectionDetailsVar, CreateSubAccountHelper.externalOnboardingRequestWithConnectionDetails.class);
		try {
			// Retrive SubAccount wrapper payload from External Onboarding Request wrapper
			BillingAccountWrapper subAccount = externalOnboardingRequestWithConnectionDetailsRecord.subAccountWithEmptyfieldsVar.subAccountAttributesDetails;
			// Update the Transaction Id with External Onboarding Request ID
			subAccount.transactionId = externalOnboardingRequestWithConnectionDetailsRecord.onboardingRequestId;
			// remove null attributes/objects from payload
			String subAccountJson = System.JSON.serialize(subAccount, true);
			String requestObjId = externalOnboardingRequestWithConnectionDetailsRecord.subAccountWithEmptyfieldsVar.subAccountAttributesDetails.requestObjId;
			String onboardingRequestId = externalOnboardingRequestWithConnectionDetailsRecord.onboardingRequestId;

			stateInfoVar = new stateInfo();
			stateInfoVar.requestObjId = requestObjId;
			stateInfoVar.onboardingRequestId = onboardingRequestId;

			// Call Service Method to execute the POST request to CAMUNDA with appropriate header configuration
			BillingAccountService service = BillingAccountService.getInstance();
			Continuation con = service.getContinuation(subAccountJson, onboardingRequestId, sourceSystem);
			con.state = stateInfoVar;
			con.continuationMethod = 'processResponse';
			return con;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
	/**
	 * @Description : Process response from Camunda, calling BillingAccountService to parse the response into Boolean value - True for Success and False for Error
	 * */
	@AuraEnabled
	public static Boolean processResponse(List<String> labels,
	Object state) {
		StateInfo stateInformation = (StateInfo)state;
		HttpResponse httpResponse = Continuation.getResponse(labels[0]);
		// Parse response from Camunda and determine if the transaction is successful or failed as True or False respectively
		BillingAccountService.Response response = BillingAccountService.getInstance().parseResponse(httpResponse);
		String status = (response.isSuccess ? 'Requested' : 'Error');
		CreateBillingAccountHelper.updateDSRAndChargeAccount(stateInformation.requestObjId, null, stateInformation.onboardingRequestId, status, response.getErrorMessage(), null);
		return response.isSuccess;
	}

	public class stateInfo{
		@AuraEnabled
		public string requestObjId;
		@AuraEnabled
		public string onboardingRequestId;
	}
}