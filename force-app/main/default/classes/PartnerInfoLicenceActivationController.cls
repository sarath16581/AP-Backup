/**
 * @author Naveen Rajanna
 * @date 2023-03-17
 * @description Controller for Manual ABN/Licence Activation performed by Partner Info Users
 * @test PartnerInfoLicenceActivationCont_Test
 * @changelog
 * 2024-06-15	Snigdha Sahu : REQ3429628 : Add validation for Incent Cred to be populated for nominated contact on parent org
 */
public with sharing class PartnerInfoLicenceActivationController {
	private static final Set<SObjectField> ACCOUNT_FIELDS = new Set<SObjectField>{
		Account.Id, Account.Name, Account.WCIS_Code__c, Account.Licence_Status__c, Account.ParentABN__c, Account.SAP_Vendor_ID__c,
		Account.Assignment_Effective_From_Date__c, Account.Assignment_Effective_To_Date__c, Account.CreatedDate, Account.LastModifiedDate, Account.Nominated_Partner_Contact_Incent_User__c
	};
	private static final Set<SObjectField> NETWORK_FIELDS = new Set<SObjectField>{ Network__c.State__c };
	private static final Set<SObjectField> USER_FIELDS = new Set<SObjectField>{ User.Id, User.Name };
    private static final Set<SObjectField> CONTACT_FIELDS = new Set<SObjectField>{ Contact.IncentCredential__c };

	/**
	 * Return wrapper containing IncomingLicence, Facility and OutgoingLicence records for the passed IncomingLicence Id
	 * @param incomingLicenceId
	 * @return  `InitWrapper`
	 * @exception
	 */
	@AuraEnabled(cacheable=true)
	public static InitWrapper fetchInitDetails(String incomingLicenceId) {
		InitWrapper initWrapper = null;
		try {
			// Query to get FacilityId and OutgoingLicenceId from IncomingLicenceId
			List<Account> incomingLicence = AccountsSelector.newInstance(
					1,
					new Set<SObjectField>{ Account.Id, Account.Facility__c, Account.ParentId}
				)
				.selectById(new Set<Id>{ Id.valueOf(incomingLicenceId) }, new Set<Object>{ AccountsSelector.Options.WITH_FACILITY })
				.values();

			// Query to get IncomingLicence, Facility and OutgoingLicence records
			if (!incomingLicence.isEmpty()) {
				//added IncentCredential__c
				Set<Id> idSet = new Set<Id>{ incomingLicence[0].Id, incomingLicence[0].ParentId, incomingLicence[0].Facility__c, incomingLicence[0].Facility__r?.ParentId };
				idSet.remove(null);
				Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
					Account.SObjectType => ACCOUNT_FIELDS, Network__c.SObjectType =>  NETWORK_FIELDS, User.SObjectType => USER_FIELDS, Contact.SObjectType => CONTACT_FIELDS
				};

				Map<Id, Account> accountMap = AccountsSelector.newInstance(0, fieldOverrides)
					.selectById(
						idSet,
						new Set<Object>{ 
							AccountsSelector.Options.WITH_CREATEDBY_USER, AccountsSelector.Options.WITH_LASTMODIFIEDBY_USER, 
							AccountsSelector.Options.WITH_PARENT, AccountsSelector.Options.WITH_NETWORK,  AccountsSelector.Options.WITH_CONTACT
						}
					);				
					
				// Update the wrapper with the details to be return to lwc
				initWrapper = new InitWrapper();
				initWrapper.domainURL = String.valueof(URL.getOrgDomainUrl().toExternalForm());
				initWrapper.incomingLicence = accountMap.get(incomingLicence[0].Id);
				
				if (incomingLicence[0].Facility__c != null) {
					initWrapper.facility = accountMap.get(incomingLicence[0].Facility__c);
					initWrapper.outgoingLicence = (incomingLicence[0].Facility__r.ParentId != null &&
						accountMap.containsKey(incomingLicence[0].Facility__r.ParentId))
						? accountMap.get(incomingLicence[0].Facility__r.ParentId)
						: null;
				}

				if(accountMap.containsKey(incomingLicence[0].ParentId)){
					Account parentAccount = accountMap.get(incomingLicence[0].ParentId);
					initWrapper.incentCred = parentAccount.Nominated_Partner_Contact_Incent_User__r.IncentCredential__c;
					system.debug('IncentCredential value is ' + initWrapper.incentCred);
				}
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return initWrapper;
	}

	/**
	 * Perform DML to update the Incoming and Outgoing Licence fields and return Boolean to indicate outcome
	 * @param incomingLicenceId
	 * @param outgoingLicenceId
	 * @return  `Boolean`
	 * @exception
	 */
	@AuraEnabled
	public static Boolean updateLicences(String incomingLicenceId, String outgoingLicenceId) {
		try {
			List<Account> updateable = new List<Account>();
			// set the IncomingLicence Licence Status to Active and set the Licence Manual Activation Date to Today's Date
			updateable.add(
				new Account(
					Id = Id.valueOf(incomingLicenceId),
					Licence_Status__c = AccountUtil.LICENCE_STATUS_ACTIVE,
					LicenceManualActivationDate__c = Datetime.now()
				)
			);
			if (outgoingLicenceId != null) {
				// set the OutgoingLicence Licence Manual Deactivation Date to Today's Date
				updateable.add(new Account(Id = Id.valueOf(outgoingLicenceId), LicenceManualDeactivationDate__c = Datetime.now()));
			}
			if (!updateable.isEmpty()) {
				ApplicationDatabase.getInstance().dmlUpdate(updateable);
				return true;
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return false;
	}

	/**
	 * Wrapper class for the request
	 */
	public class InitWrapper {
		@AuraEnabled
		public Account facility;
		@AuraEnabled
		public Account incomingLicence;
		@AuraEnabled
		public Account outgoingLicence;
		@AuraEnabled
		public String domainURL;
		@AuraEnabled
		public String incentCred;
	}
}