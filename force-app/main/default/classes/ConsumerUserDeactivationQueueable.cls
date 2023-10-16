/**
  * @author: Steve L
  * @date: 27/9/2023
  * @description this class is used to deactivate portal users when a Consumer Account get off boarded
  */

public inherited sharing class ConsumerUserDeactivationQueueable implements Queueable{
	public Set<Id> contactIds {get; set;}

	public ConsumerUserDeactivationQueueable(Set<Id> contactIds) {
		this.contactIds = contactIds;
	}

	public void execute(QueueableContext context) {
		try {
			deactivateConsumerUsers(contactIds);
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'ConsumerUserDeactivationQueueable', ConsumerUserDeactivationQueueable.class.getName(), 'execute', 'ConsumerUserDeactivationQueueable', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * @param contactIds the of the Users that need to be deactivated
	 * @description make it static and using contactIds as a parameter rather the access the class attribute so this methods can be invoked elsewhere
	 */
	public static void deactivateConsumerUsers(Set<Id> contactIds) {
		List<User> usersToBeDeactivated = UsersSelector.newInstance().selectByContactId(contactIds)?.values();
		if (usersToBeDeactivated == null) {
			return;
		}

		for (User user : usersToBeDeactivated) {
			user.IsPortalEnabled = false;
			user.APCN__c = null;
			user.OID_ID__c = null;
			user.FederationIdentifier = null;
		}

		ApplicationDatabase.getInstance().dmlUpdate(usersToBeDeactivated);
	}
}