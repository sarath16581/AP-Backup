global with sharing class CountryLookupController {
 	global class AutoCompleteData{
        public AutoCompleteData(string label, string value, string name, string code){
            this.label = label;
            this.value = value;
            this.name = name;
            this.code = code;
        }
        
        public string label {get;set;}
        public string value {get;set;}
        public string name {get;set;}
        public string code {get;set;}
    }
    
    @RemoteAction
    global static List<AutoCompleteData> getData(string display, string term){
        term = term.trim();
        List<AutoCompleteData> result = new List<AutoCompleteData>();
        if(term != '') {
            string query = 'SELECT Name, Alpha2__c FROM CountryCodes__c';
            string clause = '';
            if(term.length() > 2){
                clause = ' where Name like \'%' + term + '%\' order by Name';
            } else {
            	clause = ' where Alpha2__c like \'' + term + '%\' order by Alpha2__c';
            }
            List<CountryCodes__c> pList = Database.query(query + clause);
            for(CountryCodes__c p :pList){
            	string value = display == 'code' ? p.Alpha2__c : p.Name;
            	if(term.length() > 2){
            		result.add(new AutoCompleteData(p.Name + ' (' + p.Alpha2__c + ')', value, p.Name, p.Alpha2__c));
            	} else {
            		result.add(new AutoCompleteData(p.Alpha2__c + ' - ' + p.Name, value, p.Name, p.Alpha2__c));
            	}
            }
        }       
        return result;
    } 
}