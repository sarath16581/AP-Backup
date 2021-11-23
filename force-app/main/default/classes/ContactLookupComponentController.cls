/***
 * @author Frank Chen
 * @date 2014-09-12
 * @changelog
 * 2021-08-15 - Seth Heang - Uplift the SOQL query to use 'selector' framework and decommision usage of 'al' managed package
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52, the class is pending for decommission in the future date
*/
global with sharing class ContactLookupComponentController {
    public string componentId {get;set;}
    public string assignToElement {get;set;}
    public string onSelectFunctionCallback {get;set;}
    
    global class AutoCompleteData{
        public AutoCompleteData(string label, string value, string contactType, string contactId, string contactName){
            this.label = label;
            this.value = value;
            this.contactType = contactType;
            this.contactId = contactId;
            this.contactName = contactName;
        }
        
        public string label {get;set;}
        public string value {get;set;}
        public string contactType {get;set;}
        public string contactId {get;set;}
        public string contactName {get;set;}
    }
    
    
    @RemoteAction
    global static List<AutoCompleteData> getData(string term){
        List<AutoCompleteData> result = new List<AutoCompleteData>();       

        for(Contact ct: ContactsSelector.newInstance(10).selectByLikedNameOrderByConsumerAndNameNullFirst(term, new set<Object>{ContactsSelector.Options.WITH_ACCOUNT}).values()){
             result.add(new AutoCompleteData(ct.name, ct.name, ct.Account.IsPersonAccount ? 'Consumer' : 'Account Holder', ct.id, ct.Account.name));
        }   
                
        return result;
    }
}