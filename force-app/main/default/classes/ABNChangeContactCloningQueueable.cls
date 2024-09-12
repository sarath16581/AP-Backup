/**
 * @author Harry Wang
 * @date 2024-06-05
 * @tag Queueable
 * @tag CSP
 * @description Queueable class to clone contacts from old organisation to new organisation
 * @changelog
 * 2024-06-05 - Harry Wang - Created
 */
public with sharing class ABNChangeContactCloningQueueable implements Queueable {
	private List<Contact> oldContacts;
	private List<Contact> newContacts;

	public ABNChangeContactCloningQueueable(List<Contact> oldContacts, List<Contact> newContacts) {
		this.oldContacts = oldContacts;
		this.newContacts = newContacts;
	}

	public void execute(QueueableContext context) {
		try {
			// Bypass duplicate alert
			Database.DMLOptions opt = new Database.DMLOptions();
			opt.duplicateRuleHeader.allowSave = true;
			opt.optAllOrNone = false;

			String logBody = '';
			Integer failureCount = 0;
			// dmlOption will only bypass alert type duplicate rule and will not bypass enforced duplicate rule (contacts under same org)
			List<Database.SaveResult> results = ApplicationDatabase.getInstance().dmlInsert(newContacts, opt);
			for (Integer i = 0; i < results.size(); i++) {
				if (!results[i].isSuccess()) {
					failureCount ++;
					logBody += oldContacts[i].Id + ' cloned failed with status code: ' +results[i].getErrors()[0].getStatusCode() + ', message: ' + results[i].getErrors()[0].getMessage() + '\n';
				}
			}
			if (failureCount > 0) {
				ApplicationLogger.getInstance().logMessage(new List<String>{failureCount + ' contacts cloned failed. Please check Additional Info.'}, new List<String>{logBody}, 'ABNChange', ABNChangeController.class.getName(), 'cloneContactsQueueable', '', ApplicationLogger.LoggingLevel.ERROR);
			}
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'ABNChange', ABNChangeController.class.getName(), 'cloneContactsQueueable', null, ApplicationLogger.LoggingLevel.ERROR);
		}
	}
}