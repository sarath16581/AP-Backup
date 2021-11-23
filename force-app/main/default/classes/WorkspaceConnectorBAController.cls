global class WorkspaceConnectorBAController {
     
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
           List<Case> cases = [SELECT CaseNumber FROM Case WHERE CaseNumber= :num];            
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
                
        if(activityMap.get('sfdc Object Id')!= ''){
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