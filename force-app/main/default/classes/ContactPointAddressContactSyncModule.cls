/**
 * @description
 * Domain Module to handle ContactPointAddress object functionality
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author George Nguyen
 * @group Domain
 * @domain ContactPointAddress
 * @test ContactPointAddressCtSyncModule_Test
 * @changelog
 * 2022-05-22 - George Nguyen - Created.
 *
 */
public with sharing class ContactPointAddressContactSyncModule extends ApplicationDomain.Module {
	public static ContactPointAddressContactSyncModule newInstance() {
		return (ContactPointAddressContactSyncModule) Application.Utilities.newInstance(ContactPointAddressContactSyncModule.class);
	}

	// Setup which trigger events this module should respond to
	public ContactPointAddressContactSyncModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate().enableAfterDelete();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			syncContactPointAddressToContacts((List<ContactPointAddress>) records, null, uow);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'ContactPointAddressContactSyncModule',
				CustomerDataSyncEventHandler.class.getName(),
				'onAfterInsert',
				'ContactPointAddressContactSyncModule',
				LoggingLevel.ERROR
			);
		}
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			syncContactPointAddressToContacts((List<ContactPointAddress>) records, (Map<Id, ContactPointAddress>) existingRecords, uow);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'ContactPointAddressContactSyncModule',
				CustomerDataSyncEventHandler.class.getName(),
				'onAfterUpdate',
				'ContactPointAddressContactSyncModule',
				LoggingLevel.ERROR
			);
		}
	}

	public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			syncContactPointAddressToContacts(null, new Map<Id, ContactPointAddress>((List<ContactPointAddress>) records), uow);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'ContactPointAddressContactSyncModule',
				CustomerDataSyncEventHandler.class.getName(),
				'onAfterDelete',
				'ContactPointAddressContactSyncModule',
				LoggingLevel.ERROR
			);
		}
	}

	/*
	 * This method will check for valid records to process in the overload method of syncContactPointAddressToContacts(Set<Id> contactIds, ApplicationUnitOfWork uow)
	 * Note: for Insert and Delete we only need to check for Contact__c as it will always pass in records. 
	 */
	private void syncContactPointAddressToContacts(
		List<ContactPointAddress> records,
		Map<Id, ContactPointAddress> existingRecords,
		ApplicationUnitOfWork uow
	) {
		Set<Id> contactIds = new Set<Id>();
		if (records != null && existingRecords == null) { // Insert
			for (ContactPointAddress cpa : records) {
				if (cpa.Contact__c != null) {
					contactIds.add(cpa.Contact__c);
				}
			}
		} else if (records != null && existingRecords != null) { // Update
			for (ContactPointAddress cpa : records) {
				ContactPointAddress existingCpa = existingRecords.get(cpa.Id);
				if (cpa.Contact__c != null && 
					(
						cpa.Street != existingCpa.Street || 
						cpa.Street2__c != existingCpa.Street2__c || 
						cpa.City != existingCpa.City || 
						cpa.PostalCode != existingCpa.PostalCode || 
						cpa.State != existingCpa.State || 
						cpa.Country != existingCpa.Country
					)) {
					contactIds.add(cpa.Contact__c);
				}
			}
		} else if (records == null && existingRecords != null) { // Delete
			for (ContactPointAddress cpa : existingRecords.values()) {
				if (cpa.Contact__c != null) {
					contactIds.add(cpa.Contact__c);
				}
			}
		}

		syncContactPointAddressToContacts(contactIds, uow);
	}

	/*
	 * This method will sync the address details from the Contact Point Address record to the Mailing and Other address fields on the Contact.
	 * If there more than one record for either Mailing or Other address type it will pick the latest (Ordered by in the Selector method)
	 */
	private void syncContactPointAddressToContacts(Set<Id> contactIds, ApplicationUnitOfWork uow) {
		if (contactIds.isEmpty() == false) {
			Map<Id, ContactPointAddress> contactIdVsContactPointAddressMailing = new Map<Id, ContactPointAddress>();
			Map<Id, ContactPointAddress> contactIdVsContactPointAddressOther = new Map<Id, ContactPointAddress>();
			for (
				ContactPointAddress cpa : ContactPointAddressSelector.newInstance().selectByContactWithOtherOrMailingAddressType(contactIds)
			) {
				if (cpa.AddressType == 'Mailing' && contactIdVsContactPointAddressMailing.containsKey(cpa.Contact__c) == false) {
					contactIdVsContactPointAddressMailing.put(cpa.Contact__c, cpa);
				}
				if (cpa.AddressType == 'Other' && contactIdVsContactPointAddressOther.containsKey(cpa.Contact__c) == false) {
					contactIdVsContactPointAddressOther.put(cpa.Contact__c, cpa);
				}
			}

			List<Contact> contactsToUpdate = new List<Contact>();
			for (Id contactId : contactIds) {
				Contact ct = new Contact(Id = contactId);

				if (contactIdVsContactPointAddressMailing.containsKey(contactId) == true) {
					ContactPointAddress cpa = contactIdVsContactPointAddressMailing.get(contactId);
					ct.MailingStreet = cpa.Street;
					ct.MailingStreet2__c = cpa.Street2__c;
					ct.MailingCity = cpa.City;
					ct.MailingPostalCode = cpa.PostalCode;
					ct.MailingState = cpa.State;
					ct.MailingCountry = cpa.Country;
				} else {
					ct.MailingStreet = null;
					ct.MailingStreet2__c = null;
					ct.MailingCity = null;
					ct.MailingPostalCode = null;
					ct.MailingState = null;
					ct.MailingCountry = null;
				}

				if (contactIdVsContactPointAddressOther.containsKey(contactId) == true) {
					ContactPointAddress cpa = contactIdVsContactPointAddressOther.get(contactId);
					ct.OtherStreet = cpa.Street;
					ct.OtherStreet2__c = cpa.Street2__c;
					ct.OtherCity = cpa.City;
					ct.OtherPostalCode = cpa.PostalCode;
					ct.OtherState = cpa.State;
					ct.OtherCountry = cpa.Country;
				} else {
					ct.OtherStreet = null;
					ct.OtherStreet2__c = null;
					ct.OtherCity = null;
					ct.OtherPostalCode = null;
					ct.OtherState = null;
					ct.OtherCountry = null;
				}

				contactsToUpdate.add(ct);
			}

			uow.registerDirty(
				contactsToUpdate,
				new List<SObjectField>{
					Contact.MailingStreet,
					Contact.MailingStreet2__c,
					Contact.MailingCity,
					Contact.MailingPostalCode,
					Contact.MailingState,
					Contact.MailingCountry,
					Contact.OtherStreet,
					Contact.OtherStreet2__c,
					Contact.OtherCity,
					Contact.OtherPostalCode,
					Contact.OtherState,
					Contact.OtherCountry
				},
				'ContactPointAddressContactSyncModule'
			);
		}
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) ContactPointAddressContactSyncModule.newInstance();
		}
	}
}