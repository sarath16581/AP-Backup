public with sharing class ChangeOfAddressController {
	private static final Set<SObjectField> ACCOUNT_FIELD_OVERRIDES = new Set<SObjectField>{
			Account.Id, Account.Role_Type_Roll_Up__c, Account.Sales_Segment__c
	};

	@AuraEnabled(Cacheable=true)
	public static String displayOldOrNewChangeAddress(String orgId) {
		Account org = AccountsSelector.newInstance(1, ACCOUNT_FIELD_OVERRIDES).selectById(new Set<Id>{orgId}, new Set<Object>{AccountsSelector.Options.WITH_OWNER}).values()[0];
		String accountType = [SELECT AccountType__c FROM SalesSegmentAccountType__mdt WHERE SalesSegment__c =:org.Sales_Segment__c LIMIT 1].AccountType__c;

		if (org.Role_Type_Roll_Up__c != 'Customer' || accountType == 'Government' || accountType == 'Other PP&eCS') {
			return 'old';
		}

		String profileName = ProfilesSelector.newInstance().selectById(new Set<Id>{System.UserInfo.getProfileId()}).values()[0].Name;
		if (profileName != 'BG Base' && org.Role_Type_Roll_Up__c == 'Customer') {
			return 'new';
		}

		String currentUserRoleName = UserRolesSelector.newInstance().selectById(new Set<Id>{System.UserInfo.getUserRoleId()}).values()[0].DeveloperName;
		String ownerRoleName = UserRolesSelector.newInstance().selectById(new Set<Id>{org.Owner.UserRoleId}).values()[0].DeveloperName;
		List<Change_Of_Address_Access_Role__mdt> accessRoles = Change_Of_Address_Access_Role__mdt.getAll().values();

		// check if user's role is same as owner's role or one level above or the sibling sales specialist role
		List<String> userAccessRoles = new List<String>();
		for (Change_Of_Address_Access_Role__mdt accessRole: accessRoles) {
			if (accessRole.RoleName__c == ownerRoleName) {
				userAccessRoles.add(accessRole.RoleName__c);
				if (accessRole.SupervisorRole__c != null) {
					userAccessRoles.add(accessRole.SupervisorRole__c);
				}
				userAccessRoles.add(getSalesSpecialistRoleName(accessRoles, accessRole.SupervisorRole__c));
			}
		}

		if (profileName == 'BG Base' && (org.Owner.Email.contains('holding.user') || org.OwnerId == System.UserInfo.getUserRoleId() || userAccessRoles.contains(currentUserRoleName))) {
			return 'new';
		}
		return 'none';
	}

	private static String getSalesSpecialistRoleName(List<Change_Of_Address_Access_Role__mdt> accessRoles, String managerRoleName) {
		for (Change_Of_Address_Access_Role__mdt accessRole: accessRoles) {
			if (accessRole.SupervisorRole__c == managerRoleName && accessRole.RoleName__c.startsWith('Sales_Specialists')) {
				return accessRole.RoleName__c;
			}
		}
		return null;
	}

	@AuraEnabled
	public static Map<String, Object> fetchAllContactsFromDB(String orgId) {
		orgId='001Bm00000MZ5mYIAT';
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
}