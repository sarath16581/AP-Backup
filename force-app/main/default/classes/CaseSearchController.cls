public with sharing class CaseSearchController {
	public List<Case> case_results { get; set; }
	public string caseNumber { get; set; }
	public string subject { get; set; } 
	public string ixnId { get; set; }
  
	public CaseSearchController() {
		caseNumber = System.currentPageReference().getParameters().get('caseNumber');
		subject = System.currentPageReference().getParameters().get('subject');
		ixnId = System.currentPageReference().getParameters().get('id');
		system.debug('ixnId=' + ixnId + ', caseNumber=' + caseNumber);
		  
	  	if ((caseNumber != '' && caseNumber != null) ||
			(subject != '' && subject != null)) {
			performSearch();  
		}
	}
	
	public void performSearch() {
		system.debug('performSearch for ' + caseNumber +  ', ' + subject);
		case_results = new List<Case>(); 

		if (caseNumber != null && caseNumber != '') {
			string term = '%' + caseNumber + '%'; 
			List<Case> results = [select Id, Contact.Id, CaseNumber, Subject, Account.Name, Contact.Name, CreatedDate 
					from case where CaseNumber like :term];
			case_results.addAll(results);
		}
		
		if (subject != null && subject != '') {
			string term = '%' + subject + '%'; 
			List<Case> results = [select Id, Contact.Id, CaseNumber, Subject, Account.Name, Contact.Name, CreatedDate 
					from case where subject like :term];
			case_results.addAll(results);
		}
		
		system.debug('*** TOTAL case_results= ' + case_results);
	}
}