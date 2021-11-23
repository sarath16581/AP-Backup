/*
 * @changelog
 * 2021-08-27 - Seth Heang - Migrating test method from accountStructureController Apex Class and uplift SF API version to 52
 * 							 The class is pending for decommission in future date
*/
@isTest
public class accountStructureController_Test {
	static testmethod void TestAccountStructureController(){
        
        RecordType rectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        //create accounts
        Account ca1=new Account(name='test1', phone='123', email__c='test@test.com', recordtypeid=rectype.id);
        insert ca1;
        
        Account ca2=new Account(name='test2', phone='123', email__c='test@test.com', recordtypeid=rectype.id, parentid = ca1.id);
        insert ca2;
        
        Account ca3=new Account(name='test2', phone='123', email__c='test@test.com', recordtypeid=rectype.id, parentid = ca2.id, Legacy_ID__c = '60000000');
        insert ca3;
        
        //create billing account
        Billing_Account__c ba = new Billing_Account__c(organisation__c=ca3.Id);
        insert ba;
        
        Test.startTest();
        //Test coverage for the VF page
        PageReference pageRef = Page.buildHierarchyView;
        pageRef.getParameters().put('aid', ca3.id); 
        Test.setCurrentPageReference(pageRef);

        //Create an instance of the controller
                                    
        accountStructureController baExCon = new accountStructureController();
        baExCon.getInfo();
        baExCon.toExcel();
        
        
        
        Test.stopTest();
    }
}