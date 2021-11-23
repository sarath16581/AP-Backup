/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ConnectorController_Test {

    static testMethod void findContactTest() {
    	Contact contact = new Contact(FirstName = 'John', LastName = 'Smith', Phone = '1234');
    	insert contact;
        Contact c = (Contact)ConnectorController.findContact('Phone', '1234');
        System.assert(c != null);
        
        c = ConnectorController.getContact(c.Id, null);
        System.assert(c != null); 
        
        /* multiple contacts */
        Contact contact2 = new Contact(FirstName = 'Foo', LastName = 'Bar', Phone = '1234');
    	insert contact2;
        c = (Contact)ConnectorController.findContact('Phone', '1234');
        System.assert(c.Id == null);
    }
    
    static testMethod void findCase() {
    	Case newCase = new Case(Subject = 'abc');
    	insert newCase;
    	
    	Case myCase = [SELECT CaseNumber FROM Case WHERE Subject = :'abc'];  
        Case c = ConnectorController.findCase(myCase.CaseNumber);
        System.assert(c != null);
    }
    
    static testMethod void createTask() {
    	Map<String, String> taskMap = new Map<String, String>();
    	Contact contact = new Contact(FirstName = 'John', LastName = 'Smith', Phone = '1234');
    	insert contact;
        Contact c = (Contact)ConnectorController.findContact('Phone', '1234');
        Task task = ConnectorController.closeTask(c.Id, c.AccountId, 'a subject', 'a comment', null, null, taskMap, 10); 
        System.assert(task != null);
    }
    
    static testMethod void createCase() {
    	Map<String, String> caseMap = new Map<String, String>();
    	Contact contact = new Contact(FirstName = 'John', LastName = 'Smith', Phone = '1234');
    	insert contact;
        
    	Case c = ConnectorController.createCase(contact.Id, contact.AccountId, 'interaction', 'a subject', null, caseMap);
    	System.assert(c != null);
    }
}