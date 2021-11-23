/***
 * @author Unknown
 * @date 2014-09-12
 * @changelog
 * 2021-08-15 - Seth Heang - Uplift the SOQL query to use 'selector' framework and decommision usage of 'al' managed package
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52, the class is pending for decommission in the future date
*/
global with sharing class CTIScreenPopController {
	final static String APPLICATION_NAME = 'applicationName';
    final static String APPLICATION_KEY = 'appKey';
    final static String SERVICE_NAME = 'serviceName';
    final static String TOKEN_DURATION = 'tokenDuration';
    final static String TOKEN_REQUEST = 'tokenRequest';
    
	public string token {get;set;}
	public string addressSearchURL {get;set;}
	public string addressDetailsURL {get;set;}
	
    //public Cookie cContactId { get; set; }        
    //public Cookie cCaseId { get; set; }
                
    public CTIScreenPopController(){
        //cContactId = ApexPages.currentPage().getCookies().get('currentContactId');
        //cCaseId = ApexPages.currentPage().getCookies().get('currentCaseId');
        token = '';
		addressSearchURL = '';
		addressDetailsURL = '';
		
		AusPostSettings__c setting = AusPostSettings__c.getValues('AddressValidation');
		if(setting != null){
			token = setting.Token__c;
			addressSearchURL = setting.URL2__c;
			addressDetailsURL = setting.URL3__c;
		}          
    }
    
    @RemoteAction   
    global static string getToken(boolean refreshToken) {
        string result = '';
        AusPostSettings__c addressValidationSetting = AusPostSettings__c.getValues('AddressValidation');
        result = addressValidationSetting.Token__c;
        if(result.trim() == '')
        	refreshToken = true;
	        
	    if(refreshToken) {
	        HttpRequest req = new HttpRequest();
	        String username = addressValidationSetting.Username__c;
	        String password= addressValidationSetting.Password__c;
	        Http http = new Http();
	        req.setEndpoint(addressValidationSetting.URL__c);
	        req.setMethod('POST');
	        Blob headerValue = Blob.valueOf(username +':' +password);
	        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
	        System.debug('Encoder Value' + EncodingUtil.base64Encode(headerValue));
	        req.setHeader('Authorization', authorizationHeader);
	        req.setHeader('Content-Type','application/json');
	        JSONGenerator gen = JSON.createGenerator(true);
	        gen.writeStartObject();
	        gen.writeFieldName(TOKEN_REQUEST);
	        gen.writeStartObject();
	        gen.writeStringField(APPLICATION_NAME, addressValidationSetting.ApplicationName__c);
	        gen.writeStringField(APPLICATION_KEY, addressValidationSetting.AppKey__c);
	        gen.writeStringField(SERVICE_NAME, addressValidationSetting.ServiceName__c);
	        gen.writeStringField(TOKEN_DURATION, addressValidationSetting.TokenDuration__c);
	        gen.writeEndObject();
	        gen.writeEndObject();
	        req.setBody(gen.getAsString());
	        //HttpResponse res = http.send(req);
	        // modified by shengpeng.xiao@bluewolf.com at 2014.7.14 start
	        // as http.send not surpport in test method
	        HttpResponse res;
	        if(Test.isRunningTest()) {
	        	res = new Httpresponse();
	        	res.setBody('{"userTokenx": "userToken"}');
	        }else {
	        	res = http.send(req);
	        }
	        // modified by shengpeng.xiao@bluewolf.com at 2014.7.14 end
	        JSONParser parser = JSON.createParser(res.getBody());
	        while(parser.nextToken()!=null) 
	        {
	            if(parser.getCurrentName() == 'userToken' && parser.getText() != 'userToken') 
	            {
	                result = parser.getText();
	                if(result != '') {
	                	addressValidationSetting.Token__c = result;
	                	update addressValidationSetting;
	                	system.debug('Got new token from AusPost: ' + result);
	                	break;
	                }
	            }
	        }
	    }
        return result;
    }
    
    public static searchResult getContactByPhone(string strPhone) {
        // Do some phone validation here
        system.debug('**** Incoming phone number: ' + strPhone);
        
        // Prepare result
        searchResult result = new searchResult();
        
        try {
            List<Contact> contacts = ContactsSelector.newInstance(2).selectByLikedAnyPhoneOrderByName(strPhone).values();
            
            if (contacts.size() == 1) {
                result.recordId = contacts[0].Id;
                result.isFound = true;
            } else {
                result.isFound = false;
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Something went wrong: ' + e));
        }
          
        return result;        
    }
   

    public static searchResult getCaseByArticleId(string strArticleId) {
        // Prepare result
        searchResult result = new searchResult();   
        
        try {
            List<Case> cases = CasesSelector.newInstance(1).selectByReferenceIdOrderByCreatedDate(new Set<String>{strArticleId}).values();
            
            if (!cases.isEmpty()) { 
                result.recordId = cases[0].Id;
                result.isFound = true;
            } else {
                result.isFound = false;
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Something went wrong: ' + e));        
        }   
        
        return result;
   }
       
    @RemoteAction
    global static string createActivity (string whatId, string subject, string callOutcome, string callDesc, string callDuration, integer callDurationSecs, string refID, string callProduct, string inPhone) {
        string result = '';
        string whoId = null;
        
        if (whatId != '' && whatId != null){
            if(whatId.startsWith(Account.SObjectType.getDescribe().getKeyPrefix())){
                Account[] c = [select id, PersonContactId from Account where id = :whatId.trim() LIMIT 1];
                if (!c.isEmpty()) 
                    whoId = c[0].PersonContactId; 
                    
                if(whoId == null) {
                    whatId = c[0].id;
                }
            } 
            else if(whatId.startsWith(Case.SObjectType.getDescribe().getKeyPrefix())){
                Case[] c = [select contactId from case where id = :whatId.trim() LIMIT 1];
                if (!c.isEmpty()) 
                    whoId = c[0].ContactId; 
                    
                if(whoId == null)
                    whatId = null;
            } 
            else if(whatId.startsWith(Contact.SObjectType.getDescribe().getKeyPrefix())){
                whoId = whatId.trim();
                whatId = null;
            } 
            else {
                // default to the logged in user;
                whoId = null;
                whatId = null;
            }
            
            ID recordTypeID = [select Id from RecordType where SObjectType = 'Task' and DeveloperName = 'SSSWCall' limit 1].Id;
            Task task = new Task(ActivityDate = Date.today(),
                            RecordTypeId = recordTypeId,
                            CallDisposition =  callOutcome, //'Contact left a message',
                            CallType = 'Inbound',
                            Description = callDesc,
                            Phone__c = inPhone,
                            Status = 'Completed',
                            Subject = subject,
                            Type = 'Call',
                            CallDuration__c = callDuration,
                            CallDurationInSeconds = callDurationSecs,
                            ReferenceID__c = refID,
                            WhoId = whoId,
                            WhatId = whatId);
                
            insert task;
            result = task.Id;
        }
        return result;
    }
   
    @RemoteAction
    global static searchResult getCaseOrContact(string strArticleId, string strPhone){          
        system.debug('**** getCaseOrContact - strArticleId : ' + strArticleId);
        system.debug('**** getCaseOrContact - strPhone : ' + strPhone);
        
        searchResult result = new searchResult();
        
        if (strArticleId != '' && strArticleId != null){
            result = getCaseByArticleId(strArticleId);
        } else if (strPhone != '' && strPhone != null){
            result = getContactByPhone(strPhone);
        }
        
        system.debug('**** getCaseOrContact - result : ' + result);
        
        return result;
    }
       
    global class searchResult {
        public String recordId;  
        public Boolean isFound;
    }

}