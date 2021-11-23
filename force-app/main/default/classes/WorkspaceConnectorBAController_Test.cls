@isTest
private class WorkspaceConnectorBAController_Test {

static testMethod void WorkspaceConnectorInfo_Test()
{
    String result = WorkspaceConnectorBAController.setWorkspaceConnectorInfo('123','456');
    System.assert(result == 'success');    
    result = WorkspaceConnectorBAController.retrieveWorkspaceConnectorInfo('init');
    System.assert(result != 'none');
}
    
 static testMethod void findCaseFromNumber_Test()
 {
    String test_subject = '123test321test';
    //error leg
    Case result = WorkspaceConnectorBAController.findCaseFromNumber('1');
    System.assert(result == null);
     
    //Create Case test data
    Case test_case = new Case(Subject = test_subject, Type = 'CRM Query');
    insert test_case;
    Case myCase = [SELECT CaseNumber FROM Case WHERE Subject = :test_subject];  
    result = WorkspaceConnectorBAController.findCaseFromNumber(myCase.CaseNumber);
        System.assert(result!=null);
 }
    

static testMethod void findObjectFromANI_Test() {
    
        Account acc = new Account(Name = 'testAccount',Phone = '5555'); 
        insert acc;
        Account newACC = [SELECT Id, Name, Phone FROM Account WHERE Phone = '5555'];
        Object result = WorkspaceConnectorBAController.findObjectFromANI('5555');
        System.assert(result!=null);
    
}

    
static testMethod void findContactFromANI_Test() {
        Object id;

        //Account acc = new Account(Name = 'testAccount',Phone = '5555'); 
        //insert acc;
        //Account newACC = [SELECT Id, Name, Phone FROM Account WHERE Phone = '5555'];
        
        //Create Contact test data
        Contact con1 = new Contact(FirstName = 'John', LastName = 'Doer', Phone = '4444', MobilePhone = '3333', MailingAddress__c = 'test address', MailingCity = 'test city');
        //con1.AccountId = newACC.Id;
        Contact con2 = new Contact(FirstName = 'Jane', LastName = 'Doer', Phone = '4444', MailingAddress__c = 'test address', MailingCity = 'test city');
        //con2.AccountId = newACC.Id;
        
        //error leg
        id = WorkspaceConnectorBAController.findContactFromANI('4444');
        System.assert(id == 'not found');
        
        insert con1;
        String test_phone = '4444';
        Id [] fixedSearchResults = new Id[1];
        Contact myCon = [SELECT Id FROM Contact WHERE Phone = :test_phone];
        fixedSearchResults[0] = myCon.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        System.debug('*** Id = '+myCon.Id);
           
        id = WorkspaceConnectorBAController.findContactFromANI('4444');
        System.assert(id != null && id!='not found' && id != 'multiple found');
        System.debug('*** single match');
        
        //insert con2;
        //id = WorkspaceConnectorBAController.findContactFromANI('4444');
        //System.assert(id == 'multiple found');
        //System.debug('*** multiple match');
}  


static testMethod void findContactFromEmailAddress_Test() {
        Object id;
                
        //Create Contact test data
        Contact con1 = new Contact(FirstName = 'John', LastName = 'Doer', Phone = '4444', MobilePhone = '3333',Email = 'john.doer@somewhere.com', MailingAddress__c = 'test address', MailingCity = 'test city');
        
        //error leg
        id = WorkspaceConnectorBAController.findContactFromEmailAddress('john.doer@somewhere.com');
        System.assert(id == null);
        
        insert con1;
        id = WorkspaceConnectorBAController.findContactFromEmailAddress('john.doer@somewhere.com');
        System.assert(id != null);        
}


static testMethod void findContactFromChatAddress_Test() {
        Object id;
                
        //Create Contact test data
        Contact con1 = new Contact(FirstName = 'John', LastName = 'Doer', Phone = '4444', MobilePhone = '3333',Email = 'john.doer@somewhere.com', MailingAddress__c = 'test address', MailingCity = 'test city');
        
        //error leg
        id = WorkspaceConnectorBAController.findContactFromChatAddress('John Doer');
        System.assert(id == null);
        
        insert con1;
        id = WorkspaceConnectorBAController.findContactFromChatAddress('John Doer');
        System.assert(id != null);        
}

    static testMethod void findContactFromWorkItemAddress_Test() {
        Object id;
                
        //Create Contact test data
        Contact con1 = new Contact(FirstName = 'John', LastName = 'Doer', Phone = '4444', MobilePhone = '3333',Email = 'john.doer@somewhere.com', MailingAddress__c = 'test address', MailingCity = 'test city');
        
        //error leg
        id = WorkspaceConnectorBAController.findContactFromWorkItemAddress('John Doer');
        System.assert(id == null);
        
        insert con1;
        id = WorkspaceConnectorBAController.findContactFromWorkItemAddress('John Doer');
        System.assert(id != null);        
}
    
    static testMethod void findContactFromOpenMediaAddress_Test() {
        Object id;
                
        //Create Contact test data
        Contact con1 = new Contact(FirstName = 'John', LastName = 'Doer', Phone = '4444', MobilePhone = '3333',Email = 'john.doer@somewhere.com', MailingAddress__c = 'test address', MailingCity = 'test city');
        
        //error leg
        id = WorkspaceConnectorBAController.findContactFromOpenMediaAddress('John Doer');
        System.assert(id == null);
        
        insert con1;
        id = WorkspaceConnectorBAController.findContactFromOpenMediaAddress('John Doer');
        System.assert(id != null);        
}    
    
static testMethod void createActivity_Test() {
        String ID = '';
        Map<String,String> fieldsMap = new Map<String,String>();
        //create map
        fieldsMap.put('Genesys Call Type','Inbound');
        fieldsMap.put('LOOKUP','4444');
        fieldsMap.put('Call Duration','00.00.35');
        fieldsMap.put('DATE','June1');
        fieldsMap.put('Comments','');
        fieldsMap.put('ANI','4444');
        fieldsMap.put('IXN Type','Phone');
        fieldsMap.put('Media Type','');
        fieldsMap.put('sfdc Object Id',ID);

        //Activity created as orhpan
        String noIDResult = WorkspaceConnectorBAController.createActivity(fieldsMap);
        System.assert(noIDResult != null);
    
        //Create Account test data
        Account acc = new Account(Name = 'testAccount',Phone = '7654321'); 
        insert acc;
        Account newACC = [SELECT Id, Name, Phone FROM Account WHERE Phone = '7654321'];
        //Create Contact test data
        Contact con = new Contact(FirstName = 'John', LastName = 'Doer', Phone = '4444', MobilePhone = '3333',Email = 'john.doer@somewhere.com', MailingAddress__c = 'test address', MailingCity = 'test city');
        con.AccountId = newACC.Id;  //account id
        insert con;
        
        //Activity created under Contact using search
        String contactResult = WorkspaceConnectorBAController.createActivity(fieldsMap);
        System.assert(contactResult != null);

        fieldsMap.put('IXN Type','Email');
        fieldsMap.put('LOOKUP','john.doer@somewhere.com');
        contactResult = WorkspaceConnectorBAController.createActivity(fieldsMap);
        System.assert(contactResult != null);

        fieldsMap.put('IXN Type','Chat');
        fieldsMap.put('LOOKUP','John Doer');
        contactResult = WorkspaceConnectorBAController.createActivity(fieldsMap);
        System.assert(contactResult != null); 
        
        fieldsMap.put('IXN Type','OpenMedia');
        fieldsMap.put('LOOKUP','John Doer');
        contactResult = WorkspaceConnectorBAController.createActivity(fieldsMap);
        System.assert(contactResult != null);        
    
        //Activity created under Contact using ID
        Contact newCon = [SELECT Id FROM Contact WHERE Phone = '4444'];
        ID = newCon.Id;
        System.Debug('sfdc Object Id = '+ID);
        fieldsMap.put('sfdc Object Id',ID);
        fieldsMap.put('SFDC1field','Description');
        fieldsMap.put('SFDC1value','Test1');
        fieldsMap.put('SFDC2field','Description');
        fieldsMap.put('SFDC2value','Test2');
        fieldsMap.put('SFDC3field','Description');
        fieldsMap.put('SFDC3value','Test3');
        fieldsMap.put('SFDC4field','Description');
        fieldsMap.put('SFDC4value','Test4');
        fieldsMap.put('SFDC5field','Description');
        fieldsMap.put('SFDC5value','Test5');    
        contactResult = WorkspaceConnectorBAController.createActivity(fieldsMap);
        System.assert(contactResult != null);
    
   
        
} 

}