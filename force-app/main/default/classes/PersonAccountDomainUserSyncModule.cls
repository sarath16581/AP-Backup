/**
 * @description
 * Domain Module to handle Account object sync with User object
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author George Nguyen
 * @group Domain
 * @domain Account
 * @changelog
 * 2022-08-01 - George Nguyen - Created.
 * 
 */
public inherited sharing class PersonAccountDomainUserSyncModule extends ApplicationDomain.Module {
    
    public static PersonAccountDomainUserSyncModule newInstance() {
		return (PersonAccountDomainUserSyncModule)Application.Utilities.newInstance(PersonAccountDomainUserSyncModule.class);
	}

	// Setup which trigger events this module should respond to
	public PersonAccountDomainUserSyncModule() {
		getTriggerEvents().enableAfterUpdate();
	}

    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        syncUpdatedFieldsToUserRecord((List<Account>)records, (Map<Id, Account>)existingRecords, uow);
    }

    /**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)PersonAccountDomainUserSyncModule.newInstance();
		}
	}

    // syncs updated fields on Accounts to User fields using the field mapping
    private void syncUpdatedFieldsToUserRecord(List<Account> records, Map<Id, Account> existingRecords, ApplicationUnitOfWork uow) {
        Map<Id, Account> validAccounts = new Map<Id, Account>();
        for(Account acc: records) {
            if(acc.IsPersonAccount == true && acc.OID_ID__pc != existingRecords.get(acc.Id).OID_ID__pc) {
                validAccounts.put(acc.id, acc);
            }
        }
        if(validAccounts.isEmpty() == false) {
            Map<Id, Contact> contacts = ContactsSelector.newInstance().selectByAccount(validAccounts.keySet());

            if(contacts.isEmpty() == false) {
                List<User> usersToUpdate = new List<User>();
                for(User u : UsersSelector.newInstance().selectByContactId(contacts.keySet()).values()) {
                    u.OID_ID__c = contacts.get(u.ContactId).OID_ID__c;
                    usersToUpdate.add(u);
                }
                uow.registerDirty(usersToUpdate, new List<SObjectField>{User.OID_ID__c}, 'PersonAccountDomainUserSyncModule');
            }
        }
    }

}