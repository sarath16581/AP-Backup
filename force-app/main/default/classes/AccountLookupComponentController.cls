global with sharing class AccountLookupComponentController {
    public string componentId {get;set;}
    public string assignToElement {get;set;}
    public string onSelectFunctionCallback {get;set;}
    
    global class AutoCompleteData{
        public AutoCompleteData(string label, string value, string accountType, string accountId, string accountNumber, string accountName){
            this.label = label;
            this.value = value;
            this.accountType = accountType;
            this.accountId = accountId;
            this.accountNumber = accountNumber;
            this.accountName = accountName;
        }
        
        public string label {get;set;}
        public string value {get;set;}
        public string accountType {get;set;}
        public string accountId {get;set;}
        public string accountNumber {get;set;}
        public string accountName {get;set;}
    }
    
    
    @RemoteAction
    global static List<AutoCompleteData> getData(string term, boolean useAccountNumber){
    	
    	string whereClause = 'Name like \'%' + string.escapeSingleQuotes(term) + '%\'';
        string orderBy = 'Name';
    	if(useAccountNumber) {
            whereClause = 'ABN__c like \'%' + string.escapeSingleQuotes(term) + '%\'';
            orderBy = 'ABN__c';
        } 
    	
    	string queryString = 'Find \'"' + string.escapeSingleQuotes(term.trim()) + '*"\' IN ALL FIELDS RETURNING Account(ABN__c, Name where IsPersonAccount = false and ' + whereClause + ' order by ' + orderBy + ' limit 10)';  
    	
        List<AutoCompleteData> result = new List<AutoCompleteData>();       
        List<List<SObject>> queryResults = search.query(queryString);
        List<Account> accounts = (List<Account>)queryResults[0];
            
        String nullAcctNum;
        for(Account acc: accounts){
             if(useAccountNumber) {
                result.add(new AutoCompleteData(acc.ABN__c + ' (' + acc.name + ')', acc.ABN__c, 'Organisations', acc.id, acc.ABN__c, acc.name));
             }else
             {
                 if(String.isEmpty(acc.ABN__c))
                 {
                    nullAcctNum = 'Unknown';
                 }
                 else
                 {
                    nullAcctNum = acc.ABN__c;
                 }
                result.add(new AutoCompleteData(acc.name + ' (' + nullAcctNum   + ')', acc.name, 'Organisations', acc.id, acc.ABN__c, acc.name));
             }
        }   
        
        whereClause = 'Name like \'%' + string.escapeSingleQuotes(term) + '%\'';
        orderBy = 'Name';
        
        if(useAccountNumber) {
            whereClause = 'LEGACY_ID__c like \'%' + string.escapeSingleQuotes(term) + '%\'';
            orderBy = 'LEGACY_ID__c';
        }
        
        queryString = 'Find \'"' + string.escapeSingleQuotes(term.trim()) + '*"\' IN ALL FIELDS RETURNING Billing_Account__c(LEGACY_ID__c, Name where ' + whereClause + ' order by ' + orderBy + ' limit 10)';
        
        queryResults = search.query(queryString);
        List<Billing_Account__c> billingAccounts = (List<Billing_Account__c>)queryResults[0];
        
        for(Billing_Account__c acc: billingAccounts){
            if(useAccountNumber) {
                result.add(new AutoCompleteData(acc.LEGACY_ID__c + ' (' + acc.name + ')', acc.LEGACY_ID__c, 'Billing Accounts', acc.id, acc.LEGACY_ID__c, acc.name));
             }
            else
            {
                 if(String.isEmpty(acc.LEGACY_ID__c))
                 {
                    nullAcctNum = 'Unknown';
                 }
                 else
                 {
                    nullAcctNum = acc.LEGACY_ID__c;
                 }
                result.add(new AutoCompleteData(acc.name + ' (' + nullAcctNum + ')', acc.name, 'Billing Accounts', acc.id, acc.LEGACY_ID__c, acc.name));
            }
        } 
                
        return result;
    }
}