/*
  Written By  : Ji Zhang (CoreTec Solutions)
  Date        : 07/10/2011
  Email       : jzhang@coretec.com.au

  Description : The controller for ContactFilteringSearch page. 
                The ContactFileringSearch page works as a popup window to only display the
                associated contacts from an account of an Opportunity record. 
                It takes two parameters. One is ‘from’ which indicates its parent page, 
                the other is ‘p’ which is either an ‘account name’ or an opportunity Id based 
                on the from page.

  History     : Version 1.0 07/10/2011

  MOD         : Louis Wang (Bluewolf) 06/01/2014 - Removed concept of Partner / Individual, such that standard Account-Contact is reestablished                            
                Clinton McIntyre 28-May-2015 - Added "with sharing" as part of security audit.
@changelog:
30-09-2021	seth.heang@auspost.com.au	Uplift the SF API Version to 52

*/
public with sharing class ContactFilteringSearchCon
{
    // opportunity(id)instance which gets passed for RelationshipPowerMap VF
    private Opportunity opp;
   
    private Set<Id> accountFromIdSet = new Set<Id>();
    
    private String fromPage;
    
    public ContactFilteringSearchCon ()
    {           
        fromPage = ApexPages.currentPage().getParameters().get('from');
        
        if(fromPage == 'opportunity')
        {       
            String accountName = ApexPages.currentPage().getParameters().get('p');
            System.debug('***accountName***' + accountName);
            // search based on account name which may have duplicated record
            List<Account> accountFromList = [SELECT Id from Account WHERE name =: accountName];
            System.debug('***accountFromList****:' + accountFromList);
            for(Account a : accountFromList)
            {
                accountFromIdSet.add(a.Id);
            }   
        }
        else if(fromPage == 'RPM' || fromPage == 'PainChain')
        {
            Id opportunityId = ApexPages.currentPage().getParameters().get('p');
            opp = [SELECT Name, AccountId from Opportunity WHERE Id =: opportunityId];
            accountFromIdSet.add(opp.AccountId);
        }
                
    }

    public list<Contact> getContacts()
    {
        list<Contact> output = [SELECT Id, Title, Status__c, Name FROM Contact WHERE AccountId IN : accountFromIdSet];
        return output;
    }
    
    public String getFromPage()
    {
        return fromPage;
    }
    
    /* 
     * API v28 onward, disallow the inclusion of testmethod in apex classes
     * Source: https://developer.salesforce.com/blogs/engineering/2013/04/apex-test-code-segregation
     * Therefore, Migrate below test code a new test class 'ContactFilteringSearchConTest'
    * ***************************************************************
    * Test Class
    *****************************************************************
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
    } */
}