/**
 * @description
 * Domain Module to handle ContactPointAddress object functionality 
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author George Nguyen
 * @group Domain
 * @domain ContactPointAddress
 * @changelog
 * 2022-05-22 - George Nguyen - Created.
 * 
 */
public with sharing class ContactPointAddressDomainModule extends ApplicationDomain.Module {
    
    public static ContactPointAddressDomainModule newInstance() {
		return (ContactPointAddressDomainModule)Application.Utilities.newInstance(ContactPointAddressDomainModule.class);
	}

	// Setup which trigger events this module should respond to
	public ContactPointAddressDomainModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate().enableAfterDelete();
	}

    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        syncContactPointAddressToContacts ((List<ContactPointAddress>)records, null);
    }

    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        syncContactPointAddressToContacts ((List<ContactPointAddress>)records, (Map<Id, ContactPointAddress>)existingRecords);
    }

	public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		syncContactPointAddressToContacts (null, new Map<Id, ContactPointAddress>((List<ContactPointAddress>)records));
	}

	private void syncContactPointAddressToContacts(List<ContactPointAddress> records, Map<Id, ContactPointAddress> existingRecords) {
        Set<Id> contactIds = new Set<Id>();
        if(records != null) { 
            for(ContactPointAddress cpa : records) {
                if(cpa.Contact__c != null) {
                    contactIds.add(cpa.Contact__c);
                }
            }
        } else if(records == null && existingRecords != null) { 
            for(ContactPointAddress cpa : existingRecords.values()) {
                if(cpa.Contact__c != null) {
                    contactIds.add(cpa.Contact__c);
                }
            }
        } 
        
        syncContactPointAddressToContacts(contactIds);
    }

    private void syncContactPointAddressToContacts(Set<Id> contactIds) {
        Map<Id, ContactPointAddress> contactIdVsContactPointAddressMailing = new Map<Id, ContactPointAddress>();
        Map<Id, ContactPointAddress> contactIdVsContactPointAddressOther = new Map<Id, ContactPointAddress>();
        for(ContactPointAddress cpa: ContactPointAddressSelector.newInstance().selectByContactWithOtherOrMailingAddressType(contactIds)) {
            if(cpa.AddressType == 'Mailing' && contactIdVsContactPointAddressMailing.containsKey(cpa.Contact__c) == false) { // only need the latest one
                contactIdVsContactPointAddressMailing.put(cpa.Contact__c, cpa);
            }
            if(cpa.AddressType == 'Other' && contactIdVsContactPointAddressOther.containsKey(cpa.Contact__c) == false) { // only need the latest one
                contactIdVsContactPointAddressOther.put(cpa.Contact__c, cpa);
            }
        }

        List<Contact> contactsToUpdate = new List<Contact>();
        for(Id contactId : contactIds) {
            Contact ct = new Contact(Id = contactId);

            if(contactIdVsContactPointAddressMailing.containsKey(contactId) == true) {
                ContactPointAddress cpa = contactIdVsContactPointAddressMailing.get(contactId);
                ct.MailingStreet = cpa.Street;
                ct.MailingStreet2__c = cpa.Street2__c;
                ct.MailingCity = cpa.City;
                ct.MailingPostalCode = cpa.PostalCode;
                ct.MailingState = cpa.State;
                ct.MailingCountry = cpa.Country;
            } else {
                ct.MailingStreet = NULL;
                ct.MailingStreet2__c = NULL;
                ct.MailingCity = NULL;
                ct.MailingPostalCode = NULL;
                ct.MailingState = NULL;
                ct.MailingCountry = NULL;
            }

            if(contactIdVsContactPointAddressOther.containsKey(contactId) == true) {
                ContactPointAddress cpa = contactIdVsContactPointAddressOther.get(contactId);
                ct.OtherStreet = cpa.Street;
                ct.OtherStreet2__c = cpa.Street2__c;
                ct.OtherCity = cpa.City;
                ct.OtherPostalCode = cpa.PostalCode;
                ct.OtherState = cpa.State;
                ct.OtherCountry = cpa.Country;
            } else {
                ct.OtherStreet = NULL;
                ct.OtherStreet2__c = NULL;
                ct.OtherCity = NULL;
                ct.OtherPostalCode = NULL;
                ct.OtherState = NULL;
                ct.OtherCountry = NULL;
            }

            contactsToUpdate.add(ct);
        }

        ApplicationDatabase.getInstance().dmlUpdate(contactsToUpdate);
    }

    /**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)ContactPointAddressDomainModule.newInstance();
		}
	}
}