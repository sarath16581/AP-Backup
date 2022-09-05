/**
 * @description
 * Domain module to handle the synchronisation of LPO/CPO permissions (Account Teams) when a new user is created
 * NOTE: All users that enter this module will be LBP Community users
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Nathan Franklin
 * @date 2022-08-24
 * @changelog
 */
public with sharing class LBPUserPermissionsModule extends ApplicationDomain.Module {

	static final Map<SObjectType, Set<SObjectField>> CPO_LPO_ACCOUNT_FIELDS = new Map<SObjectType, Set<SObjectField>>{
		Account.SObjectType => new Set<SObjectField>{
			Account.WCIS_Code__c
		}
	};
	static final String NETWORK_VALIDATION_ERROR = 'Invalid network value provided';

	public static LBPUserPermissionsModule newInstance() {
		return (LBPUserPermissionsModule) Application.Utilities.newInstance(LBPUserPermissionsModule.class);
	}

	// Setup which trigger events this module should respond to
	public LBPUserPermissionsModule() {
		getTriggerEvents().enableBeforeInsert();
	}

	/**
	 * Handles the validation and access synchronisation of LBP users when they are first created
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			Map<String, Set<Id>> contactIdsByNetworkFacility = new Map<String, Set<Id>>();
			Map<Id, User> usersByContactIds = new Map<Id, User>();

			for(User u : (List<User>)records) {
				usersByContactIds.put(u.ContactId, u);
			}

			if(!usersByContactIds.isEmpty()) {
				//validate that the network field provided on the user is corresponding to the network linked to the parent account
				if(!validateNetworkFieldOnUser(usersByContactIds)) {
					return;
				}

				for (User validatedUser : usersByContactIds.values()) {
					if (String.isNotBlank(validatedUser.Network__c)) {
						String networkWcisCode = validatedUser.Network__c.trim();
						if(contactIdsByNetworkFacility.get(networkWcisCode) == null) {
							contactIdsByNetworkFacility.put(networkWcisCode, new Set<Id>());
						}
						contactIdsByNetworkFacility.get(networkWcisCode).add(validatedUser.ContactId);
					}
				}

				if (!contactIdsByNetworkFacility.isEmpty()) {
					ApplicationDatabase.getInstance().enqueueJob(new LpoCpoAccessHandlerQueueable(contactIdsByNetworkFacility, null, null, null));
				}

			}

		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'LBP', LBPUserPermissionsModule.class.getName(), 'onBeforeInsert', 'User', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Validates whether or not the Network__c field entered on the users record matches a Facility they are connected to through the account hierarchy
	 */
	private static Boolean validateNetworkFieldOnUser(Map<Id, User> usersByContactIds) {
		Boolean hasPassed = true;

		// used to track which user record are valid
		Set<User> validUserRecords = new Set<User>();

		if (usersByContactIds != null && !usersByContactIds.isEmpty()) {
			Map<Id, Set<Id>> contactsIdsByAccountsIds = new Map<Id, Set<Id>>();

			// 1. get accounts linked to the contacts
			for (Contact aContact : ContactsSelector.newInstance(0, new Set<SObjectField>{
				Contact.AccountId
			}).selectById(usersByContactIds.keySet()).values()) {
				// group contacts by their parent accounts to be able to retrieve related CPO and LPO accounts
				if(contactsIdsByAccountsIds.get(aContact.AccountId) == null) {
					contactsIdsByAccountsIds.put(aContact.AccountId, new Set<Id>());
				}
				contactsIdsByAccountsIds.get(aContact.AccountId).add(aContact.Id);
			}

			// 2. get parent CPO and LPO accounts
			if (!contactsIdsByAccountsIds.isEmpty()) {
				// return all CPO and LPO facilities accounts to access WCIS code for network validation
				List<Account> lpoAndCpoAccounts = AccountsSelector.newInstance(0, CPO_LPO_ACCOUNT_FIELDS).selectLPOAndCPOAccountsByAccIds(contactsIdsByAccountsIds.keySet(), new Set<Object>{AccountsSelector.Options.WITH_GRANDPARENT}).values();
				if (!lpoAndCpoAccounts.isEmpty()) {
					for (Account anAccount : lpoAndCpoAccounts) {

						// CPO scenario: "flat" hierarchy where contact is linked to an account that has WCIS code therefore contacts for that account are retrieved with contactsIdsByAccountsIds.get(anAccount.Id);
						// LPO scenario: WCIS code is on the grandchild level therefore linked contacts are retrieved with contactsIdsByAccountsIds.get(anAccount.Parent.Parent.Id)
						Set<Id> contactIds = contactsIdsByAccountsIds.get(anAccount.Id) == null ? contactsIdsByAccountsIds.get(anAccount.Parent.Parent.Id) : contactsIdsByAccountsIds.get(anAccount.Id);
						if (contactIds != null && !contactIds.isEmpty() && !usersByContactIds.isEmpty()) {
							for (Id contactId : contactIds) {
								User newUser = usersByContactIds.get(contactId);

								// 3. validate if the user is linked to correct facility
								Boolean validNetworkLink = anAccount.WCIS_Code__c != null && anAccount.WCIS_Code__c == newUser.Network__c;
								if (validNetworkLink) {
									//flag this user record as valid
									validUserRecords.add(newUser);
								}
							}
						}
					}

					// add errors to any records which wen't validated
					for (User userRecord : usersByContactIds.values()) {
						if(!String.isEmpty(userRecord.Network__c) && !validUserRecords.contains(userRecord)) {
							userRecord.addError(NETWORK_VALIDATION_ERROR);
							hasPassed = false;
						}
					}
				}
			}
		}

		return hasPassed;
	}

}