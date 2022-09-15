/**
 * @description Domain class to handle the Local Business Partner capbility on the User trigger
 * NOTE: This code is only applicable for CPO that have a 1 to 1 mapping to their facility
 * This is limited to CPO based on the Contact.Account.RecordType check being Facility (All CPO users are contacts in the Facility itself)
 * LPO Licensee's might be licensed to run multiple outlets which means we wouldn't know which account teams to assign to the user after reparenting
 * Additionally, as at 08-2022, it's currently not business practice to allow LPO contacts to be reparented to another LPO Licensee
 *
 * @author Kamil Szyc
 * @date 2022-08-25
 * @group Domains
 * @changelog
 */
public with sharing class LBPContactPermissionsModule extends ApplicationDomain.Module {

	private static Set<Id> enqueuedContactIdsAddingMembership = new Set<Id>();
	private static Set<Id> enqueuedContactIdsRemovingMembership = new Set<Id>();

	private Id facilityRTId {
		get {
			if(facilityRTId == null) {
				facilityRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
			}
			return facilityRTId;
		}
		private set;
	}

	public static LBPContactPermissionsModule newInstance() {
		return (LBPContactPermissionsModule) Application.Utilities.newInstance(LBPContactPermissionsModule.class);
	}

	/**
	 * Note that this module only needs an update and not an insert
	 * When a contact is first inserted, it will have no user record attached which would make running this code pointless
	 */
	public LBPContactPermissionsModule() {
		getTriggerEvents().enableAfterUpdate();
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			maybeResetAccountTeams((List<Contact>)records, (Map<Id, Contact>)existingRecords);
		} catch (Exception e) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'LBP', LBPContactPermissionsModule.class.getName(), 'onAfterUpdate', 'Contact', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	private void maybeResetAccountTeams(List<Contact> records, Map<Id, Contact> existingRecords) {
		Map<Id, Contact> updatedContactMap = new Map<Id, Contact>((List<Contact>) records);
		Set<Id> contactsIdToRemoveMembership = new Set<Id>();
		Set<Id> processableContactIds = new Set<Id>();
		Map<Id, Set<Id>> oldAccountContactMappings = new Map<Id, Set<Id>>();


		for (Contact updatedContact : updatedContactMap.values()) {
			Contact oldContact = (Contact) existingRecords.get(updatedContact.Id);
			Id oldAccountId = oldContact.AccountId;
			if (updatedContact.AccountId != oldAccountId) {

				// store a list of contacts where the account record is updated
				// we use this to determine which user records (if any) need their AccountTeams updated
				// only add contacts if they haven't already been enqueued
				// this is to protect in the event of recursion or looping
				if(updatedContact.AccountId != null) {
					if (!enqueuedContactIdsAddingMembership.contains(updatedContact.Id)) {
						processableContactIds.add(updatedContact.Id);
					}
				}

				// use this to determine whether or not the user requires old account team to be removed
				if (oldAccountId != null) {
					if(oldAccountContactMappings.get(oldAccountId) == null) {
						oldAccountContactMappings.put(oldAccountId, new Set<Id>());
					}

					// only add contacts if they haven't already been enqueued
					// this is to protect in the event of recursion or looping
					if(!enqueuedContactIdsRemovingMembership.contains(updatedContact.Id)) {
						oldAccountContactMappings.get(oldAccountId).add(updatedContact.Id);
					}
				}
			}
		}

		// the contact has been moved from one account to another
		if (!processableContactIds.isEmpty() || !oldAccountContactMappings.isEmpty()) {
			Map<String, Set<Id>> contactIdsByNetworkFacility = new Map<String, Set<Id>>();

			if(!processableContactIds.isEmpty()) {
				// check to see whether there is an associated user to the contact record and make sure the profile of the user is a community user
				// if our prechecks line up then we can launch the queueable
				Id lbpProfileId = LBPConstants.COMMUNITY_PROFILE_ID;
				List<User> users = UsersSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
					User.SObjectType => new Set<SObjectField>{User.ContactId, User.ProfileId},
					Account.SObjectType => new Set<SObjectField>{Account.Network_Facility__c, Account.Licence_Type__c, Account.Id, Account.RecordTypeId},
					Network__c.SObjectType => new Set<SObjectField>{Network__c.Org_ID__c},
					Contact.SObjectType => new Set<SObjectField>{Contact.AccountId}
				}).search(new Map<String, Object>{
					'contactIds' => processableContactIds,
					'profileIds' => lbpProfileId
				}, new Set<Object>{UsersSelector.Options.WITH_CONTACT, ContactsSelector.Options.WITH_ACCOUNT, AccountsSelector.Options.WITH_RECORDTYPE, AccountsSelector.Options.WITH_NETWORK}, true);

				for(User userRecord : users) {
					if (userRecord?.Contact?.Account != null && userRecord?.Contact?.Account?.Network_Facility__r?.Org_ID__c != null && userRecord?.Contact?.Account?.RecordTypeId == facilityRTId) {
						if(contactIdsByNetworkFacility.get(userRecord.Contact.Account.Network_Facility__r.Org_ID__c) == null) {
							contactIdsByNetworkFacility.put(userRecord.Contact.Account.Network_Facility__r.Org_ID__c, new Set<Id>());
						}
						contactIdsByNetworkFacility.get(userRecord.Contact.Account.Network_Facility__r.Org_ID__c).add(userRecord.ContactId);

						// make sure the contact in this list do not trigger off another enqueue if they have already been enqueued
						enqueuedContactIdsAddingMembership.add(userRecord.ContactId);
					}
				}
			}

			// if the old account was a Facility record then we will most likely need to remove old account teams for the user associated to the contact
			if (!oldAccountContactMappings.isEmpty()) {
				for (Account acc : AccountsSelector.newInstance().selectById(oldAccountContactMappings.keySet(), new Set<Object>{
					AccountsSelector.Options.WITH_RECORDTYPE
				}).values()) {
					if (acc.RecordTypeId == facilityRTId) {
						contactsIdToRemoveMembership.addAll(oldAccountContactMappings.get(acc.Id));

						// make sure the contact in this list do not trigger off another enqueue if they have already been enqueued
						enqueuedContactIdsRemovingMembership.addAll(oldAccountContactMappings.get(acc.Id));
					}
				}
			}

			if (!contactIdsByNetworkFacility.isEmpty() || !contactsIdToRemoveMembership.isEmpty()) {
				ApplicationDatabase.getInstance().enqueueJob(new LpoCpoAccessHandlerQueueable(contactIdsByNetworkFacility, contactsIdToRemoveMembership, null, null));
			}
		}
	}
}