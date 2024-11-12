public with sharing class ChangeOfAddressController {
	/*private static final Set<SObjectField> ACCOUNT_FIELD_OVERRIDES = new Set<SObjectField>{
			Account.Id, Account.Role_Type_Roll_Up__c, Account.Sales_Segment__c
	};

	private static final Set<SObjectField> BILLING_ACCOUNT_FIELD_OVERRIDES = new Set<SObjectField>{
			Billing_Account__c.Name, Billing_Account__c.LEGACY_ID__c, Billing_Account__c.BillingAccountType__c, Billing_Account__c.Street__c, Billing_Account__c.Suburb__c,
			Billing_Account__c.State__c, Billing_Account__c.Postal_Code__c, Billing_Account__c.Source_System__c, Billing_Account__c.PhysicalStreet__c,
			Billing_Account__c.PhysicalSuburb__c, Billing_Account__c.PhysicalState__c, Billing_Account__c.PhysicalPostalCode__c
	};

	
	

	private static String getSalesSpecialistRoleName(List<Change_Of_Address_Access_Role__mdt> accessRoles, String managerRoleName) {
		for (Change_Of_Address_Access_Role__mdt accessRole: accessRoles) {
			if (accessRole.SupervisorRole__c == managerRoleName && accessRole.RoleName__c.startsWith('Sales_Specialists')) {
				return accessRole.RoleName__c;
			}
		}
		return null;
	}

	@AuraEnabled(Cacheable=true)
	public static List<Billing_Account__c> getActiveBillingAccounts(String orgId) {
		return BillingAccountsSelector.newInstance(0, BILLING_ACCOUNT_FIELD_OVERRIDES).selectByOrgId(new Set<Id> {orgId}, new Set<Object>{BillingAccountsSelector.Options.FILTER_ACTIVE, BillingAccountsSelector.Options.WITH_PAYER_ACCOUNT_ID, BillingAccountsSelector.Options.WITH_LEADER_ACCOUNT}).values();
	}

	

	*/

	@AuraEnabled(Cacheable=true)
	public static String displayOldOrNewChangeAddress(String orgId) {
		return 'new';
	}

	@AuraEnabled(Cacheable=true)
	public static List<Account> getActiveBillingAccounts(String orgId) {
		return new List<Account>();
	}

	/**
	 * @description Get datatable columns from given field set
	 * @param objectName Object API name for the field set
	 * @param fieldSetName Name of the field set to be used to map columns
	 * @return list of datatable column wrapper
	 */
	@AuraEnabled(Cacheable=true)
	public static List<DataTableColumn> getColumns(String objectName, String fieldSetName) {
		try {
			List<DataTableColumn> dataTableColumnList = new List<DataTableColumn>();
			for (Schema.FieldSetMember fs: Schema.getGlobalDescribe().get(objectName).getDescribe().fieldSets.getMap().get(fieldSetName).getFields()) {
				DataTableColumn datatableColumn = new DataTableColumn(fs.getLabel(), fs.getFieldPath(), String.valueOf(fs.getType()));
				dataTableColumnList.add(datatableColumn);
			}
			return dataTableColumnList;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static Map<String, Object> fetchAllContactsFromDB(String orgId) {
		orgId='001Qy00000YiHpbIAF';
		Set<Id> accIds = new set<Id>{(Id)orgId};
		Set<SObjectField> CONTACT_FIELD_OVERRIDES = new Set<SObjectField>{Contact.Id, Contact.AccountId,Contact.Name,Contact.MobilePhone,Contact.Email,Contact.MailingAddress,Contact.OtherAddress,Contact.MailingStreet,Contact.MailingCity,Contact.MailingState,Contact.MailingPostalCode,Contact.MailingCountry,Contact.OtherStreet,Contact.OtherCity,Contact.OtherState,Contact.OtherPostalCode,Contact.OtherCountry,Contact.Has_Online_Credential__c,Contact.Record_Maintainer__c};
		Map<String, Object> resp = new Map<String, Object>();

		Map<Id,Contact> contactMap = ContactsSelector.newInstance(0,CONTACT_FIELD_OVERRIDES).selectByAccount(accIds);
		List<ChangeOfAddressController.contactRecordWrapper> contactsList= new List<ChangeOfAddressController.contactRecordWrapper>();
		for(Id conId :contactMap.keySet()){
			Contact con= contactMap.get(conId);
			ChangeOfAddressController.contactRecordWrapper conWrap= new ChangeOfAddressController.contactRecordWrapper();
			conWrap.contactRecord=con;
			conWrap.recordUrl='/'+conId;
			if(con.MailingAddress !=null){
				ChangeOfAddressController.AddressWrapper mAdd= new ChangeOfAddressController.AddressWrapper(con.MailingStreet, con.MailingCity, con.MailingState, con.MailingPostalCode, con.MailingCountry);
				conWrap.mailingAddress=mAdd.address;
			}else{
				conWrap.mailingAddress= new ChangeOfAddressController.AddressWrapper().address;
			}
			if(con.OtherAddress !=null){
				conWrap.physicalAddress= new ChangeOfAddressController.AddressWrapper(con.OtherStreet, con.OtherCity, con.OtherState, con.OtherPostalCode, con.OtherCountry).address;
			}else{
				conWrap.physicalAddress= new ChangeOfAddressController.AddressWrapper().address;
			}
			contactsList.add(conWrap);
		}
		resp.put('conlist', contactsList);
		return resp;
	}
	@AuraEnabled
	public static Map<String, Object> frameServicerequests(SRRequestParams reqParams){
		Map<String, Object> resp = new Map<String, Object>();
		try {
			switch on reqParams.baOptionSelected {
				when 'AP' {		
					if(reqParams.isBillingAddressChanged) {
						resp = frameAPBillingAddressDSR(reqParams);
					}
				}	
				when 'ST' {		
					if(reqParams.isBillingAddressChanged) {
						resp.putAll(frameSTBillingAddressDSR(reqParams));
					}
					if(reqParams.isPhysicalAddressChanged) {
						resp.putAll(frameSTPhysicalAddressDSR(reqParams));
					}
				}
				when else {//Covers 'Both' and default scenarios
					if(reqParams.isBillingAddressChanged) {
						resp.putAll(frameAPBillingAddressDSR(reqParams));
						resp.putAll(frameSTBillingAddressDSR(reqParams));
					}
					if(reqParams.isPhysicalAddressChanged) {
						resp.putAll(frameSTPhysicalAddressDSR(reqParams));
					}
				}
			}	
		} catch (Exception e) {
			resp.put(('error'), e.getMessage());
			throw new AuraHandledException(e.getMessage());
		}
		return resp;
	}

	private static Map<String, Object> frameAPBillingAddressDSR(SRRequestParams reqParams){
		Map<String, Object> resp = new Map<String, Object>();
		if(reqParams.accType.contains('Small Business')){
			resp.put('emailCaseAPRec',frameEmailToCase(reqParams, 'AP'));
		}else{
			resp.put('creditDSRAPRec',frameCreditDSR(reqParams, 'AP'));
		}
		return resp;
	}

	private static Map<String, Object> frameSTBillingAddressDSR(SRRequestParams reqParams){
		Map<String, Object> resp = new Map<String, Object>();
		if(reqParams.accType.contains('Small Business')){
			resp.put('emailCaseSTRec',frameEmailToCase(reqParams, 'ST'));
		}else{
			resp.put('creditDSRSTRec',frameCreditDSR(reqParams, 'ST'));
		}
		return resp;
	}

	private static Map<String, Object> frameSTPhysicalAddressDSR(SRRequestParams reqParams){
		Map<String, Object> resp = new Map<String, Object>();
			resp.put('onboardingDSRSTRec',frameOnboardingDSR(reqParams));
		return resp;
	}

	private static Deal_Support_Request__c frameCreditDSR(SRRequestParams reqParams, String productSelected){
		Deal_Support_Request__c creditDSR = new Deal_Support_Request__c();
		Id creditDSRRecTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Credit_Management_Request').getRecordTypeId();
		creditDSR.Credit_Work_Type__c = 'Change billing account details'; //Move this Constants
		creditDSR.Billing_Account_Change_of_Details_Type__c = 'Contact Information Details'; //Move this Constants
		creditDSR.Billing_Account_Change_of_Details_Sub_Ty__c = 'New Mailing Address'; //Move this Constants 
		switch on productSelected {
			when 'AP' {		
				if(reqParams.apBillingAccCount>5){
					creditDSR.Billing_Account_Change_of_Details_Desc__c = 'Please update Billing Address for Numbers(s): '+reqParams.newBillingAddress; //Move this Constants
				}else{
					creditDSR.Billing_Account_Change_of_Details_Desc__c = 'Count of Parent Accounts: '+reqParams.apBillingAccCount+' Update the Billing Address to '+reqParams.newBillingAddress+' Generate CSV for all billing accounts'; 
				}
			}	
			when 'ST' {		
				if(reqParams.stBillingAccCount>5){
					creditDSR.Billing_Account_Change_of_Details_Desc__c = 'Please update Billing Address for Numbers(s): '+reqParams.newBillingAddress; //Move this Constants
				}else{
					creditDSR.Billing_Account_Change_of_Details_Desc__c = 'Count of Parent Accounts: '+reqParams.apBillingAccCount+' Update the Billing Address to '+reqParams.newBillingAddress+' Generate CSV for all billing accounts'; 
				}
			}
		}
		creditDSR.Customer_Request_Attached__c = reqParams.customerRequestAttached; //Move this Constants
		creditDSR.RecordTypeId = creditDSRRecTypeId; //Move this Constants
		return creditDSR;
	}

	//Need to change this method recordtype params etc
	private static Deal_Support_Request__c frameOnboardingDSR(SRRequestParams reqParams){
		Deal_Support_Request__c onboardingDSR = new Deal_Support_Request__c();
			Id onboardingDSRRecTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Credit_Management_Request').getRecordTypeId();
			onboardingDSR.Credit_Work_Type__c = 'Change billing account details'; //Move this Constants
			onboardingDSR.Billing_Account_Change_of_Details_Type__c = 'Contact Information Details'; //Move this Constants
			onboardingDSR.Billing_Account_Change_of_Details_Sub_Ty__c = 'New Mailing Address'; //Move this Constants 
			if(reqParams.stBillingAccCount>5){
				onboardingDSR.Billing_Account_Change_of_Details_Desc__c = 'Please update Billing Address for Numbers(s): '+reqParams.newPhysicalAddress; //Move this Constants
			}else{
				onboardingDSR.Billing_Account_Change_of_Details_Desc__c = 'Count of Parent Accounts: '+reqParams.apBillingAccCount+' Update the Billing Address to '+reqParams.newPhysicalAddress+' Generate CSV for all billing accounts'; 
			}
			onboardingDSR.Customer_Request_Attached__c = reqParams.customerRequestAttached; //Move this Constants
			onboardingDSR.RecordTypeId = onboardingDSRRecTypeId; //Move this Constants
		return onboardingDSR;
	}

	private static SRResponseParams frameEmailToCase(SRRequestParams reqParams, String productSelected){
		SRResponseParams srp = new SRResponseParams();
		srp.senderEmail = Userinfo.getUserEmail();
		srp.receiverEmail = Userinfo.getUserEmail(); // This needs to be configurable and hold emailtocase address for Prod it has to be billing@auspost.com.au
		srp.accountId = reqParams.orgId;
		switch on productSelected {
			when 'AP' {		
				if(reqParams.apBillingAccCount>5){
					srp.description = 'Please update Billing Address for Numbers(s): '+reqParams.newBillingAddress; //Move this Constants
				}else{
					srp.description = 'Count of Parent Accounts: '+reqParams.apBillingAccCount+' Update the Billing Address to '+reqParams.newBillingAddress+' Generate CSV for all billing accounts'; 
				}
				srp.subject = 'AP billing address change';
			}	
			when 'ST' {		 
				if(reqParams.stBillingAccCount>5){
					srp.description = 'Please update Billing Address for Numbers(s): '+reqParams.newBillingAddress; //Move this Constants
				}else{
					srp.description = 'Count of Parent Accounts: '+reqParams.apBillingAccCount+' Update the Billing Address to '+reqParams.newBillingAddress+' Generate CSV for all billing accounts'; 
				}
				srp.subject = 'ST billing address change';
			}
		}
		return srp;
	}


	public class SRRequestParams{
		@AuraEnabled
		public Integer apBillingAccCount {get; set;}
		@AuraEnabled
		public Integer stBillingAccCount {get; set;}
		@AuraEnabled
		public String customerRequestAttached {get; set;}
		@AuraEnabled
		public String baOptionSelected {get; set;}
		@AuraEnabled
		public String accType {get; set;}
		@AuraEnabled
		public String newBillingAddress {get; set;}
		@AuraEnabled
		public Boolean isBillingAddressChanged {get; set;}
		@AuraEnabled
		public Boolean isPhysicalAddressChanged {get; set;}
		@AuraEnabled
		public String newPhysicalAddress {get; set;}
		@AuraEnabled
		public String orgId {get; set;}
		@AuraEnabled
		public Account orgRecord {get; set;}
		
	}

	public class SRResponseParams{
		@AuraEnabled
		public String senderEmail {get; set;}
		@AuraEnabled
		public String receiverEmail {get; set;}
		@AuraEnabled
		public String subject {get; set;}
		@AuraEnabled
		public String description {get; set;}
		@AuraEnabled
		public String customerContact {get; set;}
		@AuraEnabled
		public String accountId {get; set;}
		
	}
	public class contactRecordWrapper {
		@AuraEnabled
		public Contact contactRecord {get; set;}
		@AuraEnabled
		public String recordUrl { get; set;}
		@AuraEnabled
		public String mailingAddress {get; set;}
		@AuraEnabled
		public String physicalAddress {get; set;}
	}

	public class AddressWrapper {
		@AuraEnabled
		public String street {get; set;}
		@AuraEnabled
		public String city {get; set;}
		@AuraEnabled
		public String state {get; set;}
		@AuraEnabled
		public String postalCode {get; set;}
		@AuraEnabled
		public String country {get; set;}
		@AuraEnabled
		public String address {get; set;}
		public AddressWrapper(String street, String city, String state, String postalCode, String country){
			this.street = street;
			this.city = city;
			this.state = state;
			this.postalCode = postalCode;
			this.country = country;
			this.address = street+' '+city+' '+state+' '+postalCode+' '+country;
		}
		public AddressWrapper(){
			this.address='';
		}
	}

	public class DataTableColumn {
		@AuraEnabled
		public String label {get;set;}
		@AuraEnabled
		public String fieldName {get;set;}
		@AuraEnabled
		public String type {get;set;}

		public DataTableColumn(String label, String fieldName, String type)
		{
			this.label = label;
			this.fieldName = fieldName;
			this.type = type;
		}
	}
}