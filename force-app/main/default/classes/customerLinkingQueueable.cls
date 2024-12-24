public with sharing class customerLinkingQueueable implements Queueable {
	Account customer;
	String userId;
	Deal_Support_Request__c customerlinkingdsr;

	public customerLinkingQueueable(Account customer, String userId, Deal_Support_Request__c customerlinkingdsr) {
		this.customer = customer;
		this.userId = userId;
		this.customerlinkingdsr = customerlinkingdsr;
	}
	
	public void execute(QueueableContext context) {
		try {
			// Start the validations here
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'CustomerLinking', 'customerLinkingQueueable', 'CustomerLinking', null, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

}