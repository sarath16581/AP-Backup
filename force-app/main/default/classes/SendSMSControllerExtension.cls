global with sharing class SendSMSControllerExtension {
	public string txtMobile {get;set;}
	public string txtMessage {get;set;}
	public Case currentCase {get;set;}
	
	public SendSMSControllerExtension(ApexPages.StandardController theController){
		currentCase = [select contactId,caseNumber from Case where id=:theController.getRecord().id limit 1];
		List<Contact> cts = [select MobilePhone from Contact where id=:currentCase.ContactId limit 1];
		if(cts.size() > 0) {
			txtMobile = cts[0].mobilePhone;
		}
	}

	@RemoteAction
	global static string sendSMS(id caseID, string caseNumber, id contactId, string message){
		string result = '';
		try {
			if(message != null && message.trim().length() > 0 && message.trim().length() <= 160) {
				Map<string, RecordType> taskRecordTypesByDeveloperName = Util.getRecordTypesByDeveloperName('Task');
				Task aTask = New Task(whatid=caseid, whoid=contactId,  ActivityDate=Date.today(),recordtypeid=taskRecordTypesByDeveloperName.get('SSSWSMS').id,subject='SMS Sent for Case:'+casenumber);
				aTask.SMSMessage__c = message;
				
				insert aTask;
				result = 'Success!';
			} else {
				result = 'Error: Max number characters allowed is 160';
			}
		} catch(Exception ex){
			result = 'Error: ' + ex.getMessage();
		}
		return result;
	}
}