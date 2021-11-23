/*
 * @changelog
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52, the class is pending for decommission in the future date
*/
global with sharing class LogACallControllerExtension {
	public string txtSubject {get;set;}
	public string txtDescription {get;set;}
	public string txtContactName {get;set;}
	public string hfContactId {get;set;}
	public string hfCaseId {get;set;}
	private Case c;
	
	public LogACallControllerExtension(ApexPages.StandardController theController){
		c = [select contactId from Case where id=:theController.getRecord().id limit 1];
		List<Contact> cts = [select name from Contact where id=:c.ContactId limit 1];
		if(cts.size() > 0) {
			txtContactName = cts[0].name;
			hfContactId = cts[0].id;
		}
	}
	
	@RemoteAction
	global static string createLog(string caseId, string contactId, string contactName, string subject, string description){
		string result = '';
		system.debug('George says: caseId=' + caseId + ',contactId='+contactId);
		
		Task t = new Task();
		if(contactId != '')
			t.whoId = contactId;
			
		if(t.whoId == null && contactName.trim() != ''){
			string searchForName = '%' + contactName.trim() + '%';
			List<Contact> l = [select name from Contact where name like :searchForName];
			if(l.size() == 1)
				t.whoId = l[0].id;
			else if(l.size() > 1)
				result = 'Error: Multiple matches found for the specified contact name. Please select one from the list';	
			else
				result = 'Error: Unable to find a contact with the specified name';			
		}

		if(result == '') {
			t.whatId = caseId;
			t.Subject = subject;
			t.Description = description;
			try {
				insert t;
				result = 'Success';			
			} catch(DmlException ex) {
				result = 'Error: ' + ex.getDmlMessage(0);			
			}	
		}
		system.debug('George says: result = ' + result);
		
		return result;
	}
}