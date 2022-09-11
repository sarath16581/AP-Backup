/**
 * @description
 * Domain Module to handle Contact object functionality 
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author George Nguyen
 * @group Domain
 * @domain Contact
 * @Test PersonAccountDomainCtPointSyncMod_Test
 * @changelog
 * 2022-05-22 - George Nguyen - Created.
 * 
 */
public inherited sharing class PersonAccountDomainCtPointSyncModule extends ApplicationDomain.Module {
    
	enum CONTACT_POINT_PHONE_TYPE {
        MOBILE,
        HOME
    }

    public static PersonAccountDomainCtPointSyncModule newInstance() {
		return (PersonAccountDomainCtPointSyncModule)Application.Utilities.newInstance(PersonAccountDomainCtPointSyncModule.class);
	}

	// Setup which trigger events this module should respond to
	public PersonAccountDomainCtPointSyncModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate().enableAfterUpdate();
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		syncPersonAccountsToContactPoints((List<Account>)records, (Map<Id, Account>)existingRecords, uow);
    }
	
    private void syncPersonAccountsToContactPoints(List<Account> records, Map<Id, Account> existingRecords, ApplicationUnitOfWork uow) {

        Map<Id, String> contactIdsVsHomePhones = new Map<Id, String>();        
        Map<Id, String> contactIdsVsMobilePhones = new Map<Id, String>();
        Map<Id, String> contactIdsVsEmails = new Map<Id, String>();
        Map<Id, Contact> contacts = new Map<Id, Contact>();
        if(existingRecords != null && existingRecords.isEmpty() == false) {
            for(Account acc: records) {
                if(acc.isPersonAccount == true) {
                    contacts.put(acc.PersonContactId, new Contact(Id = acc.PersonContactId, AccountId = acc.Id));

                    if(acc.PersonHomePhone != existingRecords.get(acc.Id).PersonHomePhone) {
                        contactIdsVsHomePhones.put(acc.PersonContactId, acc.PersonHomePhone);
                    }
                    if(acc.PersonMobilePhone != existingRecords.get(acc.Id).PersonMobilePhone) {
                        contactIdsVsMobilePhones.put(acc.PersonContactId, acc.PersonMobilePhone);
                    }
                    if(acc.PersonEmail != existingRecords.get(acc.Id).PersonEmail) {
                        contactIdsVsEmails.put(acc.PersonContactId, acc.PersonEmail);
                    }
                }
            }
        }

        if(contactIdsVsHomePhones.isEmpty() == false) {
            uow.registerUpsert(generateContactPointPhone(contacts, contactIdsVsHomePhones, CONTACT_POINT_PHONE_TYPE.HOME, uow));
        }

        if(contactIdsVsMobilePhones.isEmpty() == false) {
            uow.registerUpsert(generateContactPointPhone(contacts, contactIdsVsMobilePhones, CONTACT_POINT_PHONE_TYPE.MOBILE, uow));
        }

        if(contactIdsVsEmails.isEmpty() == false) {
            uow.registerUpsert(generateContactPointEmails(contacts, contactIdsVsEmails, uow));
        }
    }
    
    private List<ContactPointPhone> generateContactPointPhone(Map<Id, Contact> contacts, Map<Id, String> contactIdsVsNumbers, CONTACT_POINT_PHONE_TYPE type, ApplicationUnitOfWork uow) {
        List<ContactPointPhone> newContactPointPhones = new List<ContactPointPhone>();
        if(contactIdsVsNumbers.isEmpty() == false) {
            ContactPointPhoneSelector cpPhoneSelector = ContactPointPhoneSelector.newInstance();        
            Set<Object> selectionOptions = new Set<Object>();
            String phoneType = '';
            switch on type {
                when HOME {
                    selectionOptions.add(ContactPointPhoneSelector.Options.FILTER_HOMEPHONE);
                    phoneType = 'Home';
                }
                when MOBILE {
                    selectionOptions.add(ContactPointPhoneSelector.Options.FILTER_MOBILEPHONE);
                    phoneType = 'Mobile';
                }
            }
            
            for(ContactPointPhone cpp: cpPhoneSelector.selectByContactAndPhoneNumber(contactIdsVsNumbers.keySet(), contactIdsVsNumbers.values(), selectionOptions)) {
                contactIdsVsNumbers.remove(cpp.Contact__c);
            }

            selectionOptions.add(ContactPointPhoneSelector.Options.FILTER_VERIFIED_FALSE);
            
            if(contactIdsVsNumbers.isEmpty() == false) {
                uow.registerDeleted(cpPhoneSelector.selectByContact(contactIdsVsNumbers.keySet(), selectionOptions));
            }
                
            
            for(Id contactId: contactIdsVsNumbers.keySet()) {
                Contact ct = contacts.get(contactId);
                String value = contactIdsVsNumbers.get(contactId);
                if(String.isBlank(value) == false) {
                    newContactPointPhones.add(new ContactPointPhone(
                        ParentId = ct.accountId,
                        Contact__c = contactId,
                        PhoneType = phoneType,
                        TelephoneNumber = value,
                        Verified__c = FALSE,
                        Preferred__c = FALSE,
                        UniqueMobile__c = FALSE
                    ));
                }
            }
        }

        return newContactPointPhones;
    }

    private List<ContactPointEmail> generateContactPointEmails(Map<Id, Contact> contacts, Map<Id, String> contactIdsVsEmails, ApplicationUnitOfWork uow) {
        List<ContactPointEmail> newContactPointEmails = new List<ContactPointEmail>();
        if(contactIdsVsEmails.isEmpty() == false) {
            ContactPointEmailSelector cpEmailelector = ContactPointEmailSelector.newInstance();        
            Set<Object> selectionOptions = new Set<Object>();
            for(ContactPointEmail cpe: cpEmailelector.selectByContactAndEmail(contactIdsVsEmails.keySet(), contactIdsVsEmails.values(), selectionOptions)) {
                contactIdsVsEmails.remove(cpe.Contact__c);
            }

            selectionOptions.add(ContactPointEmailSelector.Options.FILTER_VERIFIED_FALSE);

            if(contactIdsVsEmails.isEmpty() == false) {
                uow.registerDeleted(cpEmailelector.selectByContact(contactIdsVsEmails.keySet(), selectionOptions));
            }
            
            for(Id contactId: contactIdsVsEmails.keySet()) {
                Contact ct = contacts.get(contactId);
                String value = contactIdsVsEmails.get(contactId);
                if(String.isBlank(value) == false) {
                    newContactPointEmails.add(new ContactPointEmail(
                        ParentId = ct.accountId,
                        Contact__c = contactId,
                        EmailAddress = value,
                        Verified__c = FALSE,
                        Preferred__c = FALSE,
                        AuthenticationEmail__c = FALSE,
                        Communication_Email__c = TRUE
                    ));
                }
            }
        }
        return newContactPointEmails;
    }

    /**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)PersonAccountDomainCtPointSyncModule.newInstance();
		}
	}
}
