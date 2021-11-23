/**
 * @author Seth Heang
 * @date 2021-08-12
 * @group Tests
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-08-12 - Seth Heang - migrated the testmethod from BillingAccountLinkExCon_v2 as part of API version uplift in the main class
 */
@isTest
public class BillingAccountLinkExCon_v2Test {
 	static testmethod void TestBAlink(){
        
        Account ca1 = ApplicationTestDataFactory.getAccounts(1,false)[0];
        insert ca1;
        ca1.Legacy_Id__c = '60000000';
        update ca1;
        
        Account ca2 = ApplicationTestDataFactory.getAccounts(1,false)[0];
        insert ca2;
        
        Billing_Account__c ba = ApplicationTestDataFactory.getBillingAccounts(1, ca1.Id, 'SAP ERP', false)[0];
        insert ba;
        
        Test.startTest();
        //Test coverage for the VF page
        PageReference pageRef = Page.LinkAccount_v2;
        pageRef.getParameters().put('id', ba.id); 
        Test.setCurrentPageReference(pageRef);

        //Create an instance of the controller
        Apexpages.StandardController stdController = new Apexpages.StandardController(ba);                            
        BillingAccountLinkExCon_v2 baExCon = new BillingAccountLinkExCon_v2(stdController);
        
        baExCon.searchText = 'test2';
        baExCon.results = null;
        baExCon.doSearch();
        baExCon.CustId = ca2.Id;
        baExCon.SelectCustomer();
        
        system.AssertEquals(true,baExCon.searchText!=null);
        system.AssertEquals(true,baExCon.results!=null);
        
        Test.stopTest();
    }
}