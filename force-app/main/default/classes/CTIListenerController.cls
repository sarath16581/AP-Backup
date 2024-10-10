/**
  * @changelog
  * 01.01.1970 Created date unknown.
  * 13.06.2024 Parveen Kaushik Added a filter in SOQL for mapping model. See CSLU-470 (JIRA) for details.
  */  
  global class CTIListenerController {
	public string txtRefID {get;set;}
	public string txtPhoneNumber {get;set;}
	public Case proxyCase {get;Set;}
	public Task proxyActivity {get;set;}
	public string salesforceBaseURL {get;private set;}
	public string forceBaseURL {get;private set;}
    
	public List<String> excludedPhoneNumbers {
		get {
			if (excludedPhoneNumbers == null) {
				excludedPhoneNumbers = new List<String>();
				for (CTIPhoneNumbers__c cp : CTIPhoneNumbers__c.getAll().values()) {
					if (cp.Exclude__c) {
						excludedPhoneNumbers.add(cp.PhoneNumber__c);
					}
				}
			}
			return excludedPhoneNumbers;
		}
		
		private set;
	}
    
    public CTIListenerController(){
    	proxyCase = new Case();
    	proxyActivity = new Task();
    	forceBaseURL = EncodingUtil.urlEncode(URL.getSalesforceBaseUrl().toExternalForm(), 'UTF-8');
    	salesforceBaseURL = EncodingUtil.urlEncode('https://' + ApexPages.currentPage().getHeaders().get('X-Salesforce-Forwarded-To'), 'UTF-8');
    }
    
    @RemoteAction
    global static id getFullID(id shortId){
    	return shortId;
    }
     
    public string CTIFieldSetFieldPaths { 
    	get{
    		string result = '';
    		for(Schema.fieldSetMember m : SObjectType.Case.FieldSets.CTIFieldSet.getFields()) {
    			result += '"' + m.getFieldPath() + '",';
    		}
    		return result.substring(0,result.lastIndexOf(','));
    	}
    }
    
    global class CTIDefaultValue{
    	public string productCategory {get;set;}
    	public string productSubcategory {get;set;}
    	public string caseType {get;set;}
    	
    	public CTIDefaultValue(MiniCaseFieldMapping__c mapping){
    		this.productCategory = mapping.ProductCategory__c;
    		this.productSubcategory = mapping.ProductSubcategory__c;
    		this.caseType = mapping.Type__c;
    	}
    	
    	public CTIDefaultValue(){
    		
    	}
    }
        
    @RemoteAction
	global static string getRecordTypeId(string variableKeysForPicklist){
		system.debug('######### checking record type id = ' + variableKeysForPicklist);
		
		string result = '';
		Savepoint sp = Database.setSavepoint();	
		
		Map<string, object> fieldsAndValues = new Map<string, object>();  
		JSONParser parser = JSON.createParser(variableKeysForPicklist.trim());
		Case tempCase = null;
		while(parser.nextToken() != null){ 
            if(parser.getCurrentToken() == JSONToken.START_OBJECT){
                tempCase = (Case)parser.readValueAs(Case.class);
            }
        }
        parser = JSON.createParser(variableKeysForPicklist.trim());
	    while(parser.nextToken() != null){              
	        if(parser.getCurrentToken() == JSONToken.FIELD_NAME){
	            string fieldName = parser.getText();
	            if(!fieldsAndValues.containsKey(fieldName)){
	                fieldsAndValues.put(fieldName, tempCase.get(fieldName));
	            }
	        }
	    }
	    
        Case c = [select id from Case where referenceId__c = 'SSSWCase' limit 1];
        updateFieldsWithValues(c, fieldsAndValues, true);
        c.ReferenceID__c = '';
		update c;
		result = [select recordTypeid from Case where id=:c.id].RecordTypeId;
		system.debug('record type = ' + result);
		
		Database.rollback(sp);
		return result;
	}
	
	 private static void updateFieldsWithValues(Case newOrExistingCase, Map<string, object> fieldsAndValues, boolean ignoreEmptyValues){
        Map<String, Schema.SObjectField> fieldNames = Schema.SObjectType.Case.fields.getMap();
        for(string key: fieldsAndValues.keySet()){
            if(fieldNames.containsKey(key)) {
                system.debug('George says: updating ' + key);
                system.debug('with value = ' + fieldsAndValues.get(key));
				if(ignoreEmptyValues) {
					if(fieldsAndValues.get(key) != null && fieldsAndValues.get(key) != '') {                
                		newOrExistingCase.put(key, fieldsAndValues.get(key));
					}
				} else {
					newOrExistingCase.put(key, fieldsAndValues.get(key));
				}
            }
        }
    }
    
    @RemoteAction
    global static CTIDefaultValue defaultValues(string customerSegment, string serviceType){
    	CTIDefaultValue result = new CTIDefaultValue();
    	string key = customerSegment.trim() + serviceType.trim();
    	if(key != ''){
    		List<MiniCaseFieldMapping__c> mappings = [select ProductCategory__c, ProductSubcategory__c, Type__c from MiniCaseFieldMapping__c where CTIKey__c like :key AND MappingModel__c =: SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL];
	    	if(mappings.size() > 0){
	    		result = new CTIDefaultValue(mappings[0]);
	    	} 
    	}
    	return result;
    }
    
     @RemoteAction
    global static string createCustomActivity (
    							string inWhoId,
    							string inWhatId, 
    							string subject, 
    							string description, 
    							string outcome, 
    							string duration, 
    							integer durationSecs, 
    							string refID, 
    							string phone,
    							string queue,
    							string serviceType,
    							string segment,
    							string interactionID,
    							string calltype,
    							string enquiryType,
    							string enquirySubtype,
    							string productCategory,
    							string productSubcategory,
    							string IWS_CallUUID,
    							string IWS_CaseUid
    							) {
        string result = '';
        string whoId = null;
        string whatId = null;
        
        if(!string.isEmpty(inWhoId) && inWhoId.startsWith(Contact.SObjectType.getDescribe().getKeyPrefix())){
        	whoId = inWhoId;
        }
        
        if(!string.isEmpty(inWhatId) && inWhatId.startsWith(Case.SObjectType.getDescribe().getKeyPrefix())){
            Case[] c = [select contactId from case where id = :inWhatId.trim() LIMIT 1];
            if (!c.isEmpty()) {
            	whatId = c[0].id;
            	
            	if(string.isEmpty(whoId)) { 
                	whoId = c[0].ContactId;
            	} 
            }   
        }  
            
        ID recordTypeID = [select Id from RecordType where SObjectType = 'Task' and DeveloperName = 'SSSWCall' limit 1].Id;
        Task task = new Task(ActivityDate = Date.today(),
                        RecordTypeId = recordTypeId,
                        CallDisposition =  outcome, //'Contact left a message',
                        CallType = calltype,
                        Description = 'For logs, please see attachment.',
                        Phone__c = phone,
                        Status = 'Completed',
                        Subject = subject,
                        Type = 'Call',
                        CallDuration__c = duration,
                        CallDurationInSeconds = durationSecs,
                        ReferenceID__c = refID,
                        WhoId = whoId,
                        WhatId = whatId,
                        Queue__c = queue,
                        ServiceType__c = serviceType,
                        Segment__c = segment,
                        Outcome__c = outcome,
                        CTIInteractionID__c = interactionID,
                        Enquiry_Type__c = enquiryType,
                        Enquiry_Sub_Type__c = enquirySubtype,
                        Product_Category__c = productCategory,
                        Product_Sub_Category__c = productSubcategory,
                        IWS_CallUUID__c = IWS_CallUUID,
                        IWS_CaseUid__c = IWS_CaseUid
                        );
            
        insert task;
        result = task.Id;
        insert new Attachment(Name = 'InboundLog.txt', parentId = task.id, body = Blob.valueOf(description));
		moveNewCasesToBackOffice();
        return result;
    }
    
    static void moveNewCasesToBackOffice(){
    	List<Case> cases = [select AllocateToQueue__c from Case where OwnerId = :UserInfo.getUserId() and createddate = today and  Status = 'New'];
    	for(Case c: cases) {
    		c.AllocateToQueue__c = true;
    		c.Bypass_Data_enforcement__c = true;
    	}
    	update cases;
    }
    
    global class JSCaseContact {
    	public JSCaseContact() {
    		caseId = '';
    		contactId = '';
    		contactName = '';
    		caseNumber = '';
    	}
		public string caseId {get;set;}
		public string contactId {get;set;}
		public string contactName {get;set;}
		public string caseNumber {get;set;}
    }
    
    @RemoteAction
    global static JSCaseContact loadCaseOrContact(string aId, string phone){
    	JSCaseContact result = new JSCaseContact();
    	try {
    		List<Case> cases = null;
    		List<Contact> contacts = null;
    		
    		if(!string.isEmpty(aId)){
        		string queryString = 'Find \'"' + string.escapeSingleQuotes(aId.trim()) + '*"\' IN ALL FIELDS RETURNING Case(id,caseNumber,contactId where ReferenceID__c = \'' + aId.trim() + '\' limit 2)';
				List<List<SObject>> caseResults = search.query(queryString);
        		if(!caseResults.isEmpty()) {
        			cases = (List<Case>)caseResults[0];
        		}
        	} 
        	
        	if (!string.isEmpty(phone)) {
        		phone = Util.reversePhoneString(phone);
	            string queryString = 'Find \'"' + string.escapeSingleQuotes(phone) + '*"\' IN ALL FIELDS RETURNING Contact(id,name where ReversePhoneFields__c like \'%' + string.escapeSingleQuotes(phone) + '%\' order by Name limit 2)';
				List<List<SObject>> contactResults = search.query(queryString);
	            if (!contactResults.isEmpty()){
		        	contacts = (List<Contact>)contactResults[0]; 
	            }  
        	} 
        	
        	id caseContactId = null;
        	if(cases != null){
        		if(cases.size() == 1){
	        		result.caseID = cases[0].id;
	        		result.caseNumber = cases[0].CaseNumber;
	        		caseContactId = cases[0].contactId;
		        }
        	}
        	
        	if(contacts != null){
        		if(contacts.size() == 1){
        			result.contactId = contacts[0].id;
        			result.contactName = contacts[0].Name;
        		} else if(caseContactId != null){
        			for(Contact c: contacts){
        				if(c.id == caseContactId){
        					result.contactId = c.id;
        					result.contactName = c.name;
        					break;
        				}
        			}
        		}
        	}
    	}catch(Exception ex){}
    	return result;
    }
      
    
    @TestVisible
    static string lookupByPhone(string ANI){
    	string result = '';
        try{
        	              
        }
        catch(QueryException e){
            // do nothing 
        } 
    	return result;
    }
     
    @RemoteAction
    global static String retrieveWorkspaceConnectorInfo(String reason)
    {   
        system.debug('*** retrieveWorkspaceConnectorInfo');
        String myId = UserInfo.getUserId();
        myId = 'GenesysConnector' + myId;
        try{
            WorkspaceConnectorInfo__c connector = [SELECT iD, objectId__c, interactionId__c From WorkspaceConnectorInfo__c WHERE genesysId__c = :myId];
            system.debug('*** connector = '+connector);
            String ret = '{"sfdcObjectId":"' + connector.objectId__c + '","id":"' + connector.interactionId__c + '"}';
            return ret;   
        }
        catch(QueryException e){
            return 'none';
        }
    }
    
    @RemoteAction
    global static string setWorkspaceConnectorInfo(String objectId, String interactionId)
    {           
        system.debug('*** setWorkspaceConnectorInfo objectId = '+objectId+' ,interactionId = '+interactionId);
        try{
            String myId = UserInfo.getUserId();
            myId = 'GenesysConnector' + myId;
            WorkspaceConnectorInfo__c myCustomObject = new WorkspaceConnectorInfo__c (
                name = 'GenesysConnector', interactionId__c = interactionId, objectId__c = objectId,genesysId__c = myId);
            //update/insert myCustomObject; 
            upsert myCustomObject genesysId__c;
            system.debug('*** myCustomObject = ' + myCustomObject );
            String urlForDetailPage = new PageReference('/' + myCustomObject.id).getUrl();
            system.debug('*** url = '+ urlForDetailPage );
            return 'success';   
        }
        catch(QueryException e){
            return 'error';
        }
    }
    
    @RemoteAction
    global static Case findCaseFromNumber(String num)
    {
        system.debug('[WSC] findCaseFromNumber using  ' + num);       
        try {
           List<Case> cases = [SELECT CaseNumber FROM Case WHERE CaseNumber= :num ];            
           if(!cases.isEmpty()) {
               // return the first case found (should only be one)                            
               for (Case c : cases) {
                   return c;
               } 
           }
        } catch(QueryException e){
            return null; 
        }
        return null; 
    }
 
   

    @RemoteAction
    global static Object findObjectFromANI(String ANI)
    {
        system.debug('*** findObjectFromANIfor '+ANI); 
        Integer listSize = 0; 
        //List<SObject> objList;
        SObject obj_found = null;     
        try{
            
            List<List<SObject>> aobjects = [FIND :ANI IN PHONE FIELDS RETURNING Account];
            if (!aobjects.isEmpty()){
              List<Account> accounts = ((List<Account>)aobjects[0]);
              listSize = accounts.size();
              system.debug('*** accounts listSize = ' + listSize);
              if(listSize > 1){
                    return 'multiple found';
              }
              if(listSize != 0){
                  for (List<SObject> objList : aobjects)
                      for (SObject aobj : objList){
                        obj_found = aobj;
                        system.debug('*** findObjectFromANI account = '+ obj_found.Id);
                  } 
              }
            }                
            

            List<List<SObject>> cobjects = [FIND :ANI IN PHONE FIELDS RETURNING Contact];
            if (!cobjects.isEmpty()){
              List<Contact> contacts= ((List<Contact>)cobjects[0]);
              listSize = contacts.size();
              system.debug('*** contacts listSize = ' + listSize);
              if(listSize > 1){
                    return 'multiple found';
              }
              if(listSize == 1 && obj_found != null){
                    return 'multiple found';
              }
              if(listSize != 0){
                  for (List<SObject> objList : cobjects)
                      for (SObject cobj : objList){
                        obj_found = cobj;
                        system.debug('*** findObjectFromANI contact = '+ obj_found.Id);
                      } 
                  }
            }  
                                   

            List<List<SObject>> lobjects = [FIND :ANI IN PHONE FIELDS RETURNING Lead];
            if (!lobjects.isEmpty()){
              List<Lead> leads= ((List<Lead>)lobjects[0]);
              listSize = leads.size();
              system.debug('*** leads listSize = ' + listSize);              
              if(listSize > 1){
                    return 'multiple found';
              }
              if(listSize == 1 && obj_found != null){
                    return 'multiple found';
              }
              if(listSize != 0){                            
                  for (List<SObject> objList : lobjects)
                      for (SObject lobj: objList){
                        obj_found = lobj;
                        system.debug('*** findObjectFromANI lead= '+obj_found.Id);
                      } 
              }
            }
            
            if(obj_found != null)              
                return obj_found; 
            return 'not found';

        }
        catch(QueryException e){
            return 'not found'; 
        }        
    }
    
    
    @RemoteAction
    global static Object findContactFromANI(String ANI)
    {
        system.debug('*** findContactFromANI '+ANI);       
        try{                                  
            List<List<SObject>> cobjects = [FIND :ANI IN PHONE FIELDS RETURNING Contact];
            Integer listSize = cobjects.size();
            system.debug('*** listSize = ' + listSize);
            if(listSize > 1){
                    return 'multiple found'; //not expected
            }
            if (!cobjects.isEmpty()){
              List<Contact> contacts = ((List<Contact>)cobjects[0]);
              listSize = contacts.size();
              system.debug('*** contacts listSize = ' + listSize);
              if(listSize > 1){
                    return 'multiple found';
              }
              if(listSize == 0){
                  return 'not found';
              }
              for (List<SObject> objList : cobjects)
                  for (SObject cobj : objList){
                    system.debug('*** findContactFromANI contact = '+ cobj.Id);
                    return cobj;
                  } 
            }                
            return null; 

        }
        catch(QueryException e){
            return null; 
        }        
    }

    @RemoteAction
    global static Object findContactFromEmailAddress(String address)
    {
        system.debug('*** findObjectFromEmailAddress' + address);       
        try {
            List<Contact> objects = [select name from contact where email= :address ];
            if (!objects.isEmpty()) {
                  for (Contact obj : objects) {
                    system.debug('*** findContactFromEmailAddress contact = '+ obj.Name);
                    return obj;
                  } 
            }                
            return null; 
        }
        catch(QueryException e){
            return null; 
        }        
    }
    
    @RemoteAction
    global static Object findContactFromChatAddress(String theName)
    {
        system.debug('*** findObjectFromChatAddress' + theName);       
        try {
            List<Contact> objects = [select name from contact where name= :theName];
            if (!objects.isEmpty()) {
                  for (Contact obj : objects) {
                    system.debug('*** findObjectFromChatAddresscontact = '+ obj.Name);
                    return obj;
                  } 
            }                
            return null; 
        }
        catch(QueryException e){
            return null; 
        }        
    }

        
    @RemoteAction
    global static Object findContactFromWorkItemAddress(String theName)
    {
        system.debug('*** findContactFromWorkItemAddress' + theName);       
        try {
            List<Contact> objects = [select name from contact where name= :theName];
            if (!objects.isEmpty()) {
                  for (Contact obj : objects) {
                    system.debug('*** findContactFromWorkItemAddress = '+ obj.Name);
                    return obj;
                  } 
            }                
            return null; 
        }
        catch(QueryException e){
            return null; 
        }        
    }    


    @RemoteAction
    global static Object findContactFromOpenMediaAddress(String theName)
    {
        system.debug('*** findContactFromOpenMediaAddress' + theName);       
        try {
            List<Contact> objects = [select name from contact where name= :theName];
            if (!objects.isEmpty()) {
                  for (Contact obj : objects) {
                    system.debug('*** findContactFromOpenMediaAddress = '+ obj.Name);
                    return obj;
                  } 
            }                
            return null; 
        }
        catch(QueryException e){
            return null; 
        }        
    }
 

    @RemoteAction global static String createActivity(Map<String,String> activityMap){
        system.debug('*** createActivity' );
        String result = 'not found';
        
        String ANI = activityMap.get('ANI');
        String lookupSource = activityMap.get('LOOKUP');
        system.debug('*** createActivity for '+lookupSource + ' - ANI = '+ANI);
        system.debug('*** duration = ' + activityMap.get('Call Duration'));
        String callType = activityMap.get('IXN Type');
        String mediaType = activityMap.get('Media Type');
        String subject = callType + ' ' + mediaType + ' ' + activityMap.get('DATE'); 
        String objectToUse = '';
        String duration = activityMap.get('Call Duration');
        String hours = duration.substring(0,2);
        String mins  = duration.substring(3,5);
        String secs  = duration.substring(6,8);
        //system.debug('*** hours = '+hours +',mins = '+mins+ ',secs = '+secs);
        
        Integer hh = Integer.valueOf(hours);
        Integer mm = Integer.valueOf(mins);
        Integer ss = Integer.valueOf(secs);  
             
        
        Integer durationInSecs = ss + (mm*60) + (hh*3600);
        system.debug('*** durationInSecs = '+ durationInSecs );
                
        if(activityMap.get('sfdc Object Id') != null && activityMap.get('sfdc Object Id') != ''){
                system.debug('*** createActivity sfdc Object Id = ' + activityMap.get('sfdc Object Id'));
                objectToUse = activityMap.get('sfdc Object Id');
        }
        
        if(objectToUse == ''){
           object objectFromLookup;

            if(callType == 'Email')
            {
                objectFromLookup = findContactFromEmailAddress(lookupSource);
            }
            else if(callType == 'Chat')
            {
                objectFromLookup = findContactFromChatAddress(lookupSource);
            }
            else if(callType == 'InteractionWorkItem')
            {    
                objectFromLookup = findContactFromWorkItemAddress(lookupSource);
            }
            else if(callType == 'OpenMedia')
            {
                objectFromLookup = findContactFromOpenMediaAddress(lookupSource);
            }
            else
            {
                objectFromLookup = findContactFromANI(lookupSource);
            }


          if(objectFromLookup != null && objectFromLookup != 'not found' && objectFromLookup != 'multiple found'){
                    Contact c = (Contact)objectFromLookup;
                    if(c != null){
                        system.debug('*** createActivity c Id = ' + c.Id);
                        objectToUse = c.Id;
                    }
          }

        }
        
        system.debug('*** createActivity for object ' + objectToUse);
        
        String accountPrefix = Schema.SObjectType.Account.getKeyPrefix();
        String contactPrefix = Schema.SObjectType.Contact.getKeyPrefix();
        String leadPrefix = Schema.SObjectType.Lead.getKeyPrefix();        
        
        String prefix = '';
        if(objectToUse != '')
            prefix = objectToUse.substring(0, 3);
        system.debug('*** prefix = '+prefix);
          

        Task t = new Task (
          Type = 'Call',
          Status = 'Completed',
          Subject = subject,
          CallDurationInSeconds = durationInSecs,            
          Interaction_Type__c = callType,
          Description = activityMap.get('Comments'),
          CallDisposition = activityMap.get('Disposition'),
          CallObject = activityMap.get('GenesysId')
        );          
        
        if(prefix == accountPrefix){
          system.debug('*** create task for account');
          t.put('WhatId',objectToUse);
        }
        else{
          t.put('WhoId',objectToUse);
        }
              
        if(prefix == contactPrefix)
        {
          Contact contact= [SELECT AccountId, Id FROM Contact WHERE Id= :objectToUse];
          system.debug('*** create task for contact');
          t.put('WhatId',contact.AccountId); 
        }
                           
        String mySFDCfield = '';
        String mySFDCvalue = '';
        if (activityMap.get('SFDC1field') != '' && (activityMap.get('SFDC1field') != null) && activityMap.get('SFDC1value') != '' && activityMap.get('SFDC1value') != null)
        {
            mySFDCfield = activityMap.get('SFDC1field');
            mySFDCvalue = activityMap.get('SFDC1value');
            system.debug('*** mySFDCfield1 ' + mySFDCfield + ' -- ' + mySFDCvalue);
            t.put(mySFDCfield,mySFDCvalue);
        }
        if (activityMap.get('SFDC2field') != '' && (activityMap.get('SFDC2field') != null) && activityMap.get('SFDC2value') != '' && activityMap.get('SFDC2value') != null)
        {
            mySFDCfield = activityMap.get('SFDC2field');
            mySFDCvalue = activityMap.get('SFDC2value');
            system.debug('*** mySFDCfield2 ' + mySFDCfield + ' -- ' + mySFDCvalue);
            t.put(mySFDCfield,mySFDCvalue);
        }
        if (activityMap.get('SFDC3field') != '' && (activityMap.get('SFDC3field') != null) && activityMap.get('SFDC3value') != '' && activityMap.get('SFDC3value') != null)
        {
            mySFDCfield = activityMap.get('SFDC3field');
            mySFDCvalue = activityMap.get('SFDC3value');
            system.debug('*** mySFDCfield3 ' + mySFDCfield + ' -- ' + mySFDCvalue);
            t.put(mySFDCfield,mySFDCvalue);
        }
        if (activityMap.get('SFDC4field') != '' && (activityMap.get('SFDC4field') != null) && activityMap.get('SFDC4value') != '' && activityMap.get('SFDC4value') != null)
        {
            mySFDCfield = activityMap.get('SFDC4field');
            mySFDCvalue = activityMap.get('SFDC4value');
            system.debug('*** mySFDCfield4 ' + mySFDCfield + ' -- ' + mySFDCvalue);
            t.put(mySFDCfield,mySFDCvalue);
        }
        if (activityMap.get('SFDC5field') != '' && (activityMap.get('SFDC5field') != null) && activityMap.get('SFDC5value') != '' && activityMap.get('SFDC5value') != null)
        {
            mySFDCfield = activityMap.get('SFDC5field');
            mySFDCvalue = activityMap.get('SFDC5value');
            system.debug('*** mySFDCfield5 ' + mySFDCfield + ' -- ' + mySFDCvalue);
            t.put(mySFDCfield,mySFDCvalue);
        }            
            
        try{                        
                insert t;
        }
        catch(QueryException e){
                 return 'not found'; 
        }
        system.debug('*** Task id = '  +t.Id);
        result = t.Id;
        return result;
     }   


/*
   @RemoteAction
    global static String findAccount(String searchFieldName, String searchFieldValue){
        system.debug('*** findAccount: searchFieldName - ' + searchFieldName +', searchFieldValue - ' + searchFieldValue);
        try{

           String query = 'SELECT Id, Name, Phone FROM Account WHERE ' + searchFieldName  + ' = \'' + searchFieldValue + '\'';
           system.debug('*** findAccount: query = ' + query);            
           List<Account> accounts = Database.query(query);
           //List<Account> accounts = [SELECT Id, Name, Phone FROM Account WHERE Phone = :searchFieldValue]; 
            if (!accounts.isEmpty()){
                Integer listSize = accounts.size();
                if(listSize > 1){
                    return 'multiple found';
                }
                for (Account a : accounts){
                    system.debug('***  Id = ' + a.Id);
                    system.debug('***  Name = '+ a.Name);
                    system.debug('*** Phone = '+ a.Phone);
                    //return json string id  and full name
                    return '{"id":"' + a.Id + '","name":"' + a.Name + '"}';
                }
            }
        }
        catch(QueryException e){
                return 'QueryException ' + e; 
        }
        //check contact
        String query = 'SELECT Id, Name, Phone FROM Contact WHERE ' + searchFieldName  + ' = \'' + searchFieldValue + '\'';
        system.debug('*** findAccount - contact: query = ' + query);            
        List<Contact> contacts = Database.query(query);
        if (!contacts.isEmpty()){
                Integer listSize = contacts.size();
                if(listSize > 1){
                    return 'multiple found';
                }
                for (Contact c: contacts ){
                    system.debug('***  Id = ' + c.Id);
                    system.debug('***  Name = '+ c.Name);
                    system.debug('*** Phone = '+ c.Phone);
                    //return json string id  and full name
                    return '{"id":"' + c.Id + '","name":"' + c.Name + '"}';
                }
            }
        
        return 'not found';
    }    
*/
  

}