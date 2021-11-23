/**
 * Test Class for ContactFilteringSearchCon
 * @changelog
 * 30-09-2021 seth.heang@auspost.com.au	Migrate the testmode from the main class(ContactFilteringSearchCon) to a new test class
 * */
@isTest
public class ContactFilteringSearchConTest {
	/****************************************************************
    * Test Class
    *****************************************************************/
    static testMethod void unitTest() 
    {
        RecordType orgrectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
                
        Account accTestA = new Account(name='TestA', recordtypeid=orgrectype.id, phone='111', email__c='testa@gmail.com');
        insert accTestA;
        PageReference pageRef = Page.ContactFilteringSearch;
        Test.setCurrentPageReference(pageRef);
        system.currentPageReference().getParameters().put('from','opportunity');
        system.currentPageReference().getParameters().put('p',accTestA.name);
        ContactFilteringSearchCon cfs = new ContactFilteringSearchCon();
        cfs.getContacts();
        cfs.getFromPage();
        Opportunity opp = new Opportunity(name='oppTest',stageName='Identify',closeDate= date.Today(),accountId=accTestA.Id,Type='New Business',Contract_Number__c='99999', Contract_Start_Date__c=Date.newInstance(2012, 07 ,27),Contract_End_Date__c=Date.newInstance(2012, 07 ,27));
        insert opp; 
        ///PageReference pageRef1 = Page.ContactFilteringSearch;
        system.currentPageReference().getParameters().put('from','RPM');
        system.currentPageReference().getParameters().put('p',opp.Id);
        cfs = new ContactFilteringSearchCon();
    }
}