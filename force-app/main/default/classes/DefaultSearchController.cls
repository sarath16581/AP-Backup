public with sharing class DefaultSearchController {
    public List<Contact> contact_results { get; set; }
	public string phoneNumber { get; set; }
	public string name { get; set; }
	public string email { get; set; }
	public string ixnId { get; set; }
	
	public DefaultSearchController() {
		phoneNumber = System.currentPageReference().getParameters().get('phoneNumber');
		name = System.currentPageReference().getParameters().get('name');
		email = System.currentPageReference().getParameters().get('email');
		ixnId = System.currentPageReference().getParameters().get('id');
		system.debug('ixnId=' + ixnId + ', phoneNumber=' + phoneNumber);
		
		if ((phoneNumber != '' && phoneNumber != null) ||
				(name != '' && name != null) ||
				(email != '' && email != null)) {
			performSearch();  
		}
	}
   
	public void performSearch() {
		system.debug('performSearch for ' + phoneNumber + ', ' + name +  ', ' + email);
		List<List<SObject>> objs = null;
		contact_results = new List<Contact>();
		
		if (phoneNumber != null && phoneNumber != '') {
			objs = [find :phoneNumber in phone fields returning Contact(Account.Name, Id, 
					Name,
					MailingStreet, 
					EMail, Phone)];
			List<Contact> contacts = null;
			if (!objs.isEmpty()) {
				contact_results.addAll((List<Contact>) objs[0]);
			}
		} 
			
		if (name != null && name != '') {
			string term = '%' + name + '%'; 
			List<Contact> results = [select  Account.Name, Id, 
					Name,
					MailingStreet, 
					EMail, Phone 
					from contact where Name like :term];
			contact_results.addAll(results);
		}

		if (email != null && email != '') {
			string term = '%' + email + '%';
			List<Contact> results = [select Account.Name, Id, 
					Name,
					MailingStreet, 
					EMail, Phone 
					from contact where Email like :term];
			contact_results.addAll(results);
		}     
		    
		system.debug('*** TOTAL contact_results= ' + contact_results);
	}
}