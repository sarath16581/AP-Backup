public without sharing class ScheduledExactTargetBacklog implements ScheduledDispatcher.IScheduleDispatched {

	public void execute(SchedulableContext sc){
		processBacklogs();
	}
	
	void processBacklogs(){
		List<ExactTargetBacklog__c> backlogs = [select id,EmailContentJSON__c,EmailMessageObjectsJSON__c,IsBatchEmail__c,Attempts__c,ErrorMessage__c from ExactTargetBacklog__c where DateSent__c = null];
		if(!backlogs.isEmpty()) {
			ExactTargetEmail et = new ExactTargetEmail();
			ExactTargetEmail.ExactTargetSentResult sendResult = null;
			for(ExactTargetBacklog__c b: backlogs){
				sendResult = et.sendBacklog(b.EmailContentJSON__c.unescapeHtml4(), b.IsBatchEmail__c);
				if(sendResult.isSuccessful){
					if(b.EmailMessageObjectsJSON__c != null) {
						List<EmailMessage> listOfEmailMessages = (List<EmailMessage>)JSON.deserialize(b.EmailMessageObjectsJSON__c, List<EmailMessage>.class);
						insert listOfEmailMessages;
					}
					b.DateSent__c = DateTime.now();
				} else {
					b.Attempts__c++;
					b.ErrorMessage__c = sendResult.message;
				}
			}
			
			update backlogs;
		}
	}
	
}