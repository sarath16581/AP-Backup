/**
 * @author Seth Heang
 * @date 2024-08-15
 * @description - Controller for the Lightning Web Component `UnifiedCustomerCreation`
 *				This controller manages the creation of consumer including a PersonAccount, Organisation or Contact including appropriate error handling back to LWC.
 * @changelog
 * 2024-08-15 - Seth Heang - created
 * 2024-08-26 - Seth Heang - added without-sharing inner class to link Organisation to Contact due to technical challenge related to criteria-based sharing rule order of execution
 * 2024-08-27 - Seth Heang - remove savepoint/rollback as unnecessary and split error message to get only validation rule message and discarded unnecessary technical details
 */
public with sharing class UnifiedCustomerCreationController {
	// Customer type segments
	@TestVisible
	private static final String CUSTOMER_TYPE_CONSUMER = 'CONSUMER';
	@TestVisible
	private static final String CUSTOMER_TYPE_ORGANISATION = 'ORGANISATION';
	private static final String ACCOUNT_OBJECT_NAME = 'Account';
	private static final String CONTACT_OBJECT_NAME = 'Contact';
	private static final String CONSUMER_BLOCK_DUPLICATE_RULE_DEVELOPER_NAME = 'Block_Dupe_Consumers_SSSW_Agents';
	@TestVisible
	private static final String DUPLICATE_ORGANISATION_ERROR_MESSAGE = 'An organisation with these details already exists. Use existing organisation record.';
	@TestVisible
	private static final String DUPLICATE_CONTACT_MESSAGE = 'A contact with these details already exists. Use existing contact record.';
	@TestVisible
	private static final String GENERIC_ERROR_MESSAGE = 'An unexpected error occurred. Please check the data you\'ve entered and try again. If this error persists, please inform your manager.';
	private static final String MOBILE_PREFIX = '04';

	@TestVisible
	private static final Id CONSUMER_RECORD_TYPE_ID {
		get {
			if (CONSUMER_RECORD_TYPE_ID == null) {
				CONSUMER_RECORD_TYPE_ID = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{ 'PersonAccount' }).values()[0].Id;
			}
			return CONSUMER_RECORD_TYPE_ID;
		}
		private set;
	}

	@TestVisible
	private static final Id ORGANISATION_RECORD_TYPE_ID {
		get {
			if (ORGANISATION_RECORD_TYPE_ID == null) {
				ORGANISATION_RECORD_TYPE_ID = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{ 'Business_Account' }).values()[0].Id;
			}
			return ORGANISATION_RECORD_TYPE_ID;
		}
		private set;
	}

	/**
	 * @description Create new customer and consider below scenarios:
	 *				1x new PersonAccount OR
	 *				1x new Contact and linked with existing Organisation OR
	 *				1x new Contact and linked with 1x new Organisation
	 *				Also, roll back changes if there is a partial failure, for instance; a new Organisation is created but failed to create a new contact
	 * @param request inputs from customer creation LWC form
	 *
	 * @return Id - New Customer Id (Contact.Id or Account.PersonContactId)
	 */
	@AuraEnabled
	public static Id createNewCustomer(CustomerCreationRequest request) {
		try {
			SObject newCustomer;
			// populate field attribute mappings for contact, organisation, personaccount
			newCustomer = buildConsumerDataForInsert(request);
			// insert contact or personAccount
			return insertCustomer(newCustomer);
		} catch (AuraHandledException ex) {
			AuraHandledException ae = new AuraHandledException(ex.getMessage());
			ae.setMessage(ex.getMessage());
			throw ae;
		} catch (Exception ex) {
			AuraHandledException ae = new AuraHandledException(GENERIC_ERROR_MESSAGE);
			ae.setMessage(GENERIC_ERROR_MESSAGE);
			throw ae;
		}
	}

	/**
	 * @description Insert a customer of type Account/Contact and return back contactId or personContactId
	 * @param newCustomer SObject instance of Account(PersonAccount), Contact
	 * @return Id - New Customer Id (Contact.Id or Account.PersonContactId)
	 */
	private static Id insertCustomer(SObject newCustomer) {
		Id customerId; // Contact.Id or PersonAccount.PersonContactId
		Boolean requireLinkOrganisationToContact = (newCustomer instanceof Contact) && !String.isBlank(((Contact)newCustomer).AccountId);
		Id accountId;
		if(requireLinkOrganisationToContact){
			accountId = ((Contact)newCustomer).AccountId; // save accountId for later update
			((Contact)newCustomer).AccountId = null; // set to null to allow successful insert
		}
		List<Database.SaveResult> srs = ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{
				newCustomer
		}, false); // set allOrNothing to false, to get duplicate errors
		Database.SaveResult sr = srs[0];
		if (!sr.isSuccess()) {
			handleDatabaseError(sr);
		}

		// successful insert
		if (newCustomer instanceof Account && ((Account)newCustomer).RecordTypeId == CONSUMER_RECORD_TYPE_ID) {
			// need SOQL to get PersonContactId because only SObject.Id is returned from successful insert
			customerId = AccountsSelector.newInstance(1, new Set<SObjectField>{Account.PersonContactId})
					.selectById(new Set<Id>{ sr.getId() }).values()[0].PersonContactId;
		} else {
			customerId = sr.getId();
			if (requireLinkOrganisationToContact && accountId != null) {
				// Note: link new organisation id to contact, in without sharing mode because the criteria-based sharing rule for Account is calculated only after the end of current transaction.
				// And asynchronous operation is not desirable, due to impact to front-end user experience and also technical difficulty posed for rollback capability
				WithoutSharingDataAccessHelper innerClassWithoutSharing = new WithoutSharingDataAccessHelper();
				innerClassWithoutSharing.linkOrganisationToContact(customerId, accountId);
			}
		}
		return customerId;
	}

	/**
	 * @description handle duplicate error and customise the error message prior to throwing AuraHandledException back to creation form LWC
	 * @param sr Database.SaveResult
	 */
	private static void handleDatabaseError(Database.SaveResult sr) {
		for (Database.Error error : sr.getErrors()) {
			if (error instanceof Database.DuplicateError) {
				Datacloud.DuplicateResult dupRes = ((Database.DuplicateError) error).getDuplicateResult();
				// Customise Error Message for Account/PersonAccount object
				if (dupRes.duplicateRuleEntityType == ACCOUNT_OBJECT_NAME) {
					// Note: Because 'PersonAccount' is treated as 'Account', thus adding a check on the only active duplicate rule name for PersonAccount.
					if (dupRes.getDuplicateRule() == CONSUMER_BLOCK_DUPLICATE_RULE_DEVELOPER_NAME) {
						AuraHandledException ae = new AuraHandledException(DUPLICATE_CONTACT_MESSAGE);
						ae.setMessage(DUPLICATE_CONTACT_MESSAGE);
						throw ae;
					} else {
						// Customise a generic duplicate error message for all Account-related objects
						AuraHandledException ae = new AuraHandledException(DUPLICATE_ORGANISATION_ERROR_MESSAGE);
						ae.setMessage(DUPLICATE_ORGANISATION_ERROR_MESSAGE);
						throw ae;
					}
				}
				// Customise Duplicate error message for Contact object
				else if (dupRes.duplicateRuleEntityType == CONTACT_OBJECT_NAME) {
					AuraHandledException ae = new AuraHandledException(DUPLICATE_CONTACT_MESSAGE);
					ae.setMessage(DUPLICATE_CONTACT_MESSAGE);
					throw ae;
				}
			}
			// Added below code to split error.getMessage() where error message sometimes returns one long string with technical details (e.g. Update failed. First exception on row 0 with id ...)
			// Thus, split the error message to only display the message from validation rule
			String updatedErrorMessage;
			if(error.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
				updatedErrorMessage = error.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
			}else {
				updatedErrorMessage = error.getMessage();
			}
			// pass through other DML-related error (e.g. validation rule's message)
			AuraHandledException ae = new AuraHandledException(updatedErrorMessage);
			ae.setMessage(updatedErrorMessage);
			throw ae;
		}
	}

	/**
	 * @description build and populate Consumer SObject with either PersonAccount or Contact data mapping from the Request payload
	 * @param request payload from LWC
	 * @return SObject with appropriate data populated
	 */
	@TestVisible
	private static SObject buildConsumerDataForInsert(CustomerCreationRequest request){
		SObject newCustomer;
		if (request.customerType.equalsIgnoreCase(CUSTOMER_TYPE_CONSUMER)) {
			// build and map attribute for PersonAccount
			newCustomer = buildPersonAccountDataForInsert(request);
		}
		else if (request.customerType.equalsIgnoreCase(CUSTOMER_TYPE_ORGANISATION)) {
			// build and map attribute for Organisation
			newCustomer = buildContactDataForInsert(request);

			// require new organisation creation
			if(!String.isBlank(request.organisationName) && String.isBlank(request.organisationAccountId)){
				Account newOrganisation = buildOrganisationDataForInsert(request);
				Id organisationId = insertCustomer(newOrganisation);
				// link new organisation id to contact, on successful insert
				((Contact) newCustomer).AccountId = organisationId;
			}
		}
		return newCustomer;
	}

	/**
	 * @description Build and map attribute values for new PersonAccount creation
	 * @param request wrapper object passed from the customer creation LWC form
	 * @return Account
	 */
	@TestVisible
	private static Account buildPersonAccountDataForInsert(CustomerCreationRequest request) {
		Account newAccount = new Account();
		newAccount.RecordTypeId = CONSUMER_RECORD_TYPE_ID;
		newAccount.FirstName = request.firstName;
		newAccount.LastName = request.lastName;
		newAccount.Preferred_Name__pc = request.preferredName;
		newAccount.PersonEmail = request.emailAddress;
		if (request?.phoneNumber != null && request?.phoneNumber.startsWith(MOBILE_PREFIX)){
			newAccount.PersonMobilePhone = request?.phoneNumber;
		} else {
			newAccount.Phone = request?.phoneNumber;
		}
		newAccount.PersonMailingStreet = request.addressStreet;
		newAccount.PersonMailingCity = request.addressCity;
		newAccount.PersonMailingState = request.addressState;
		newAccount.PersonMailingPostalCode = request.addressPostalCode;
		newAccount.MailingDPID__pc = request.addressDPID;
		newAccount.PersonMailingLongitude = request.addressLongitude;
		newAccount.PersonMailingLatitude = request.addressLatitude;
		return newAccount;
	}

	/**
	 * @description Build and map attribute values for new Contact creation
	 * @param request wrapper object passed from the customer creation LWC form
	 *
	 * @return Contact
	 */
	@TestVisible
	private static Contact buildContactDataForInsert(CustomerCreationRequest request) {
		Contact newContact = new Contact();
		newContact.FirstName = request.firstName;
		newContact.LastName = request.lastName;
		newContact.Preferred_Name__c = request.preferredName;
		newContact.Email = request.emailAddress;
		if (request?.phoneNumber != null && request?.phoneNumber.startsWith(MOBILE_PREFIX)){
			newContact.MobilePhone = request?.phoneNumber;
		} else {
			newContact.Phone = request?.phoneNumber;
		}
		newContact.MailingStreet = request.addressStreet;
		newContact.MailingCity = request.addressCity;
		newContact.MailingState = request.addressState;
		newContact.MailingPostalCode = request.addressPostalCode;
		newContact.MailingDPID__c = request.addressDPID;
		newContact.MailingLongitude = request.addressLongitude;
		newContact.MailingLatitude = request.addressLatitude;
		newContact.AccountId = request.organisationAccountId;
		return newContact;
	}

	/**
	 * @description Build and map attribute values for a new shell Organisation creation
	 * @param request wrapper object passed from the customer creation LWC form
	 * @return Account
	 */
	@TestVisible
	private static Account buildOrganisationDataForInsert(CustomerCreationRequest request) {
		Account newAccount = new Account();
		newAccount.RecordTypeId = ORGANISATION_RECORD_TYPE_ID;
		newAccount.Name = request.organisationName;
		newAccount.ShippingStreet = request.addressStreet;
		newAccount.ShippingCity = request.addressCity;
		newAccount.ShippingState = request.addressState;
		newAccount.ShippingPostalCode = request.addressPostalCode;
		newAccount.Shipping_DPID__c = request.addressDPID;
		newAccount.ShippingLongitude = request.addressLongitude;
		newAccount.ShippingLatitude = request.addressLatitude;
		return newAccount;
	}

	/**
	 * @description A wrapper class used to receive inputs from the CustomerCreation form in LWC
	 */
	public class CustomerCreationRequest {
		@AuraEnabled
		public String firstName { get; set; }

		@AuraEnabled
		public String lastName { get; set; }

		@AuraEnabled
		public String preferredName { get; set; }

		@AuraEnabled
		public String emailAddress { get; set; }

		@AuraEnabled
		public String phoneNumber { get; set; }

		@AuraEnabled
		public String customerType { get; set; }

		@AuraEnabled
		public String addressStreet { get; set; }

		@AuraEnabled
		public String addressCity { get; set; }

		@AuraEnabled
		public String addressState { get; set; }

		@AuraEnabled
		public String addressPostalCode { get; set; }

		@AuraEnabled
		public Double addressLongitude { get; set; }

		@AuraEnabled
		public Double addressLatitude { get; set; }

		@AuraEnabled
		public String addressDPID { get; set; }

		@AuraEnabled
		public Id organisationAccountId { get; set; }

		@AuraEnabled
		public String organisationName { get; set; }
	}


	/**
	 * Private inner class that elevates access privileges of the current user to link Organisation to Contact without being limited by
	 * sharing settings. This is implemented due to a niche-case limitation where criteria-based sharing rule is calculated only after the end of current transaction.
	 * And making asynchronous operation would impact the user experience on the front-end LWC and posed difficulty for rollback functionality
	 *
	 * IMPORTANT: Not intended for general use. Only for handling special scenarios as described above.
	*/
	private without sharing class WithoutSharingDataAccessHelper {
		private void linkOrganisationToContact(Id contactId, Id organisationId){
			Contact updatableContact = new Contact(Id = contactId, AccountId = organisationId);
			try{
				List<Database.SaveResult> srs = ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{
						updatableContact
				}, false); // set allOrNothing to false, to get duplicate errors
				Database.SaveResult sr = srs[0];
				if (!sr.isSuccess()) {
					handleDatabaseError(sr);
				}
			}catch(Exception ex){
				AuraHandledException ae = new AuraHandledException(ex.getMessage());
				ae.setMessage(ex.getMessage());
				throw ae;
			}
		}
	}
}