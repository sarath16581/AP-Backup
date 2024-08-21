/**
 *  @changelog
 * 2023-05-10 - Mahesh Parvathaneni - Added @AuraEnabled tags to reuse in lwc (myNetworkStarTrackCaseArticlesService)
 */
global with sharing class PostcodeSuburbLookupController {

    global class AutoCompleteData{
        public AutoCompleteData(string label, string value, string suburb, string postcode, string state, string localityId){
            this.label = label;
            this.value = value;
            this.postcode = postcode;
            this.suburb = suburb;
            this.state = state;
            this.localityId = localityId;
        }
        
        @AuraEnabled
        public string label {get;set;}
        @AuraEnabled
        public string value {get;set;}
        @AuraEnabled
        public string postcode {get;set;}
        @AuraEnabled
        public string suburb {get;set;}
        @AuraEnabled
        public string state {get;set;}
        
        // added by shengpeng.xiao@bluewolf.com at 2014.7.21
        @AuraEnabled
        public string localityId {get;set;}
    }

    @AuraEnabled(cacheable=true)
    @RemoteAction
    global static List<AutoCompleteData> getData(string display, string term){
        term = term.trim();
        List<AutoCompleteData> result = new List<AutoCompleteData>();
        if(term != '') {
            string query = 'SELECT Name,Suburb__c,State__c,Locality_Postcode_ID__c FROM Postcode__c';
            string clause = '';
            if(term.isNumeric()){
                clause = ' where Name like \'' + term + '%\'';
            } else {
                clause = ' where Suburb__c like \'%' + term + '%\'';
            }
            List<Postcode__c> pList = Database.query(query + clause + ' order by State__c,Suburb__c');
            for(Postcode__c p :pList){
                if(display == 'postcode'){
                    result.add(new AutoCompleteData(p.Name + ' - ' + p.Suburb__c + ' (' + p.State__c + ')', p.Name, p.Suburb__c, p.Name, p.State__c, p.Locality_Postcode_ID__c));
                } else if(display == 'suburb'){
                    result.add(new AutoCompleteData(p.Suburb__c + ' (' + p.Name + ') - ' + p.State__c, p.Suburb__c, p.Suburb__c, p.Name, p.State__c, p.Locality_Postcode_ID__c));
                } else {
                    if(term.isNumeric()){
                        result.add(new AutoCompleteData(p.Name + ' - ' + p.Suburb__c + ' (' + p.State__c + ')', p.Name, p.Suburb__c, p.Name, p.State__c, p.Locality_Postcode_ID__c));
                    } else { 
                        result.add(new AutoCompleteData(p.Suburb__c + ' (' + p.Name + ') - ' + p.State__c, p.Suburb__c, p.Suburb__c, p.Name, p.State__c, p.Locality_Postcode_ID__c));
                    }
                }
            }
        }
        return result;
    }
}