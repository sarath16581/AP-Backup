/**
 * @description
 * Domain Module to handle Account object sync with User object
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author George Nguyen
 * @group Domain
 * @domain Account
 * @changelog
 * 2022-08-01 - George Nguyen - Created.
 * 2023-10-02 - Steve L - added method to sync the closing of Consumer Person Account
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
		List<Account> unprocessed = (List<Account>)RecursionUtility.getUnprocessedRecords('syncDeactivatedUserRecords-Update', records, new Set<String>{'Status__pc'});
		syncDeactivatedUserRecords(unprocessed, (Map<Id, Account>)existingRecords);
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

	/**
     * @param records List<Account> from Trigger.new
     * @param existingRecords Map<Id, Account> from Trigger.oldMap
     *
     * @description Sync to Users using a queueable when a Consumer Person Account is closed. Note only consumers that are not part of the merging process (winning master record used to differentiate them)
     */
	private void syncDeactivatedUserRecords(List<Account> records, Map<Id, Account> existingRecords) {
		Set<Id> contactIds = new Set<Id>();
		Account oldConsumer;
		for (Account consumer : records) {
			oldConsumer = existingRecords.get(consumer.Id);
			if (consumer.Status__pc != oldConsumer.Status__pc && consumer.Status__pc == APT_Constants.INACTIVE
					&& consumer.IsPersonAccount && consumer.PersonContactId != null) {
				contactIds.add(consumer.PersonContactId);
			}
		}

		if (!contactIds.isEmpty()) {
			ConsumerUserDeactivationQueueable queueable = new ConsumerUserDeactivationQueueable(contactIds);
			System.enqueueJob(queueable);
		}
	}

}