/***
 * @author Frank Chen
 * @date 2014-09-12
 * @changelog
 * 2021-08-15 - Seth Heang - Uplift the SOQL query to use 'selector' framework and decommision usage of 'al' managed package
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52, the class is pending for decommission in the future date
*/
global with sharing class AccountNameComponentController {
	public string componentId {get;set;}
	public string assignToElement {get;set;}
	public string onSelectFunctionCallback {get;set;}
	
	
	global class AutoCompleteData{
		public AutoCompleteData(string label, string value, string accountType, string accountId, string accountNumber){
			this.label = label;
			this.value = value;
			this.accountType = accountType;
			this.accountId = accountId;
			this.accountNumber = accountNumber;
		}
		
		public string label {get;set;}
		public string value {get;set;}
		public string accountType {get;set;}
		public string accountId {get;set;}
		public string accountNumber {get;set;}
	}
	
	@RemoteAction
	global static List<AutoCompleteData> getData(string term){
		List<AutoCompleteData> result = new List<AutoCompleteData>();		
       	
		for(Account acc: AccountsSelector.newInstance(10000).selectByLikedNameAndPersonAccountOrderByName(term,false).values()){
			result.add(new AutoCompleteData(acc.name, acc.name, 'Organisations', acc.id, acc.AccountNumber));
		} 	
		
		for(Billing_Account__c acc: BillingAccountsSelector.newInstance(10000).selectByLikedNameOrderByName(term).values()){
			result.add(new AutoCompleteData(acc.name, acc.name, 'Billing Accounts', acc.id, acc.LEGACY_ID__c));
		} 
				
		return result;
	}
}