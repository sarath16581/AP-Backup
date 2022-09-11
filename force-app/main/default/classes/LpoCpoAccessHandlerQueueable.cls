/**
 * @author Kamil Szyc
 * @date 5/8/2022
 * @description Class for handling access management to LPO and CPO accounts
 * @changelog
 * 5/8/2022 - Created by Kamil Szyc.
 */
public with sharing class LpoCpoAccessHandlerQueueable implements Queueable {
	public Map<String, Set<Id>> contactIdsByNetworkFacility { get; set; }
	public Set<Id> contactIdsToRemoveMembership { get; set; }
	public List<AccountTeamMember> membershipsToRemove { get; set; }
	public List<AccountTeamMember> membershipsToInsert { get; set; }
	public LpoCpoAccessHandlerQueueable(Map<String, Set<Id>> contactIdsByNetworkFacility, Set<Id>contactIdsToRemoveMembership, List<AccountTeamMember> membershipsToRemove, List<AccountTeamMember> membershipsToInsert) {
		this.contactIdsByNetworkFacility = contactIdsByNetworkFacility;
		this.contactIdsToRemoveMembership = contactIdsToRemoveMembership;
		this.membershipsToRemove = membershipsToRemove;
		this.membershipsToInsert = membershipsToInsert;
	}
	public void execute(QueueableContext context) {
		try {
			//stage 1 find existing membership that needs to be removed
			if (contactIdsToRemoveMembership != null && !contactIdsToRemoveMembership.isEmpty()) {
				Map<Id, User> usersMap = UsersSelector.newInstance().selectUserByContactIdAndProfileName(contactIdsToRemoveMembership, 'LPO Partner Community User', new Set<Object>());
				if (!usersMap.isEmpty()) {
					List<AccountTeamMember> membershipsToRemove = AccountTeamMembersSelector.newInstance().selectByTeamRoleAndAccountIds('Assigned LPO', null, usersMap.keySet(), new Set<Object>()).values();
					handleMembership(membershipsToRemove, true, contactIdsByNetworkFacility);
				}
				return;
			}
			//stage 2 chain membership removal until all is deleted
			if (membershipsToRemove != null && !membershipsToRemove.isEmpty()) {
				handleMembership(membershipsToRemove, true, contactIdsByNetworkFacility);
				return;
			}

			//stage 3 create membership records to insert
			if (contactIdsByNetworkFacility != null && !contactIdsByNetworkFacility.isEmpty()) {
				List<AccountTeamMember> accountTeamMemberRecords = new List<AccountTeamMember>();
				List<User> usersToUpdate = new List<User>();
				Set<Id> contactsIds = new Set<Id>();
				for (Set<Id> idsSet : contactIdsByNetworkFacility.values()) {
					contactsIds.addAll(idsSet);
				}
				//retrieve linked user records to be able to populate Network field
				Map<Id, User> usersByContactIds = getUserIdsFromContactIds(contactsIds);
				if (usersByContactIds.isEmpty()) return; //no active users
				//get accounts with WCIS code to use it on User record in Network field
				Map<Id, Account> accountsByIds = getAccountsWithNetworksByIds(contactIdsByNetworkFacility.keySet());
				for (Account acc : accountsByIds.values()) {
					for (Id contactId : contactIdsByNetworkFacility.get(acc.Post_Office_Assigned__r.Org_ID__c)) {
						User contactUser = usersByContactIds.get(contactId);
						//populate network field on User record
						if (acc != null &&
								acc.Post_Office_Assigned__c != null &&
								acc.Post_Office_Assigned__r.Org_ID__c != null &&
								contactUser.Network__c != acc.Post_Office_Assigned__r.Org_ID__c) {
							contactUser.Network__c = acc.Post_Office_Assigned__r.Org_ID__c;
							usersToUpdate.add(contactUser);
						}
						//create membership for the accounts that are managed by the network
						accountTeamMemberRecords.add(
								new AccountTeamMember(
										AccountId = acc.Id,
										UserId = contactUser.Id,
										TeamMemberRole = 'Assigned LPO'
								)
						);
					}
				}
				if (!usersToUpdate.isEmpty()) {
					ApplicationDatabase.getInstance().dmlUpdate(usersToUpdate);
				}
				if (!accountTeamMemberRecords.isEmpty()) {
					handleMembership(accountTeamMemberRecords, false, null);
					return;
				}
			}
			//stage 4 chain membership creation until all records are inserted
			if (membershipsToInsert != null && !membershipsToInsert.isEmpty()) {
				handleMembership(membershipsToInsert, false, null);
				return;

			}
		} catch (Exception exc) {
			UTIL_LoggingService.logHandledException(exc, UserInfo.getOrganizationId(), 'LPO/CPO handling', LpoCpoAccessHandlerQueueable.class.getName(), 'execute', null, LoggingLevel.ERROR);
		}
	}
	/**
	 * @param accountMembership list of AccountTeamMember to be inserted or deleted
	 * @param isDelete indicates if the records are to be deleted. Inserted if the flag is set to false
	 * @param contactIdsByNetworkFacility map of sets of contacts by WCIS codes
	 */
	private static void handleMembership(List<AccountTeamMember> accountMembership, Boolean isDelete, Map<String, Set<Id>> contactIdsByNetworkFacility) {
		//set DML records limit
		Integer recordLimit = 9000;
		LPO_CPO_Job_Setting__c dmlSetting = LPO_CPO_Job_Setting__c.getValues('Default');
		if (dmlSetting != null) {
			recordLimit = Integer.valueOf(dmlSetting.DML_Record_Limit__c);
		}
		List<AccountTeamMember> accessList = new List<AccountTeamMember>();
		for (Integer i = 0; i < recordLimit; i++) {
			if (accountMembership.isEmpty()) {
				break;
			}
			accessList.add(accountMembership.remove(0));
		}
		if (!accessList.isEmpty()) {
			if (isDelete) {
				ApplicationDatabase.getInstance().dmlDelete(accessList);
			} else {
				ApplicationDatabase.getInstance().dmlInsert(accessList);
			}
		}
		if (isDelete) {
			//proceed to the next step, either continue deletions if there are leftovers or insertion of new membership records
			System.enqueueJob(new LpoCpoAccessHandlerQueueable(contactIdsByNetworkFacility, null, accountMembership, null));
		} else {
			//if not all records were inserted (due to DML limit set earlier) continue to chain next iteration of the class and keep inserting new records
			if (!accountMembership.isEmpty()) {
				System.enqueueJob(new LpoCpoAccessHandlerQueueable(null, null, null, accountMembership));
			}
		}
	}
	/**
	 * @description retrieves user ids for linked contacts
	 * @param contactIds set of ids of the linked contacts
	 *
	 * @return set of user ids
	 */
	private static Map<Id, User> getUserIdsFromContactIds(Set<Id> contactIds) {
		Map<Id, User> userByContactId = new Map<Id, User>();
		for (User aUser : UsersSelector.newInstance(0, new Set<SObjectField>{
				User.ContactId, User.Network__c
		}).selectActiveUserByProfileName(contactIds, 'LPO Partner Community User', new Set<Object>()).values()) {
			userByContactId.put(aUser.ContactId, aUser);
		}
		return userByContactId;
	}
	/**
	 * @param orgIds Set of Org_ID__c for the account's parent network
	 *
	 * @return accounts with their networks linked via Post Office Assigned field
	 */
	private static Map<Id, Account> getAccountsWithNetworksByIds(Set<String> orgIds) {
		Map<SObjectType, Set<SObjectField>> fieldsMap = new Map<SObjectType, Set<SObjectField>>{
				Account.SObjectType => new Set<SObjectField>{
						Account.Id, Account.Post_Office_Assigned__c
				},
				Network__c.SObjectType => new Set<SObjectField>{
						Network__c.Org_ID__c
				}
		};
		Map<Id, Account> accountsByIds = AccountsSelector.newInstance(
				0,
				fieldsMap
		).selectByPostOfficeAssigned(orgIds, new Set<Object>{
				AccountsSelector.Options.WITH_POSTOFFICEASSIGNED
		});
		return accountsByIds;
	}

}