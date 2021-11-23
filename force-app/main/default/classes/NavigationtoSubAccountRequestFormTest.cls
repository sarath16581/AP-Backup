/*
 * @date 2021-05-10
 * @group Proposals
 * @tag Proposal
 * @domain Core
 * @description Apex Test class for navigating from credit assesment process to Sub Account Request LWC Component
 * @changelog
 * 2021-05-10 - Dheeraj.Mandavilli@auspost.com.au - Created
 */ 
@isTest
public class NavigationtoSubAccountRequestFormTest {
    
    static testmethod void NavigationtoSubAccountRequestFormTestMethodOne(){
        
        //Test Data Setup
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        Account chargeAccount = accountList[1];
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        
        //Create a proposal
        Apttus_Proposal__Proposal__c proposal = ApplicationTestDataFactory.getApttusProposals(1,primaryContact.Id,true)[0];
        
        Test.StartTest(); 
        
        PageReference pageRef = Page.SubAcctReqFormCmpfromCreditAssesment; 
        pageRef.getParameters().put('Id', String.valueOf(proposal.Id));
        Test.setCurrentPage(pageRef);
        
        NavigationtoSubAccountRequestFormClass testPage = new NavigationtoSubAccountRequestFormClass(new ApexPages.StandardController(proposal));
        
        Test.StopTest();              
    } 

}