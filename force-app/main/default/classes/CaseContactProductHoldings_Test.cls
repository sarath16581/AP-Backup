/**
    * This Class is as as test class for Product Holding chart on case and contact view.
    * 
    * @Author kalpita.talwadekar@auspost.com.au
    * @Date 21/10/2015
    *   
    */
@isTest
public with sharing class CaseContactProductHoldings_Test{
    
    /** 
    * @name: casePodHoldTableTestMethod1()
    * @desciption: test method for testing the retrieval of product holdings
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void casePodHoldTableTestMethod1() {
        Profile pr = [SELECT Id FROM Profile WHERE Name='SSSW - Service Agent']; 
        User usr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='TestingAgnt', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = pr.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduserkpt@testorg.com');
        

        //Account c = [Select Id,PersonContactId from Account where PersonContactId!=null and APCN__pc!=null and APCN__pc='1001439913' limit 1];
        Account c = TestDataProvider.createPersonAccount('Tom',Constants.RECORDTYPE_NAME_ACCOUNT_PERSONACCOUNT);
        c.APCN__pc = '1001439913';
        database.insert(c);
        system.runAs(usr) {
            Test.startTest();
                //setting pageRefernce and checking on code functionality
                PageReference pageRef = page.CaseContactSidePanelProductHoldings;
                Test.setCurrentPageReference(pageRef);
                ApexPages.CurrentPage().getparameters().put('id', c.PersonContactId);
                ApexPages.StandardController sc = new ApexPages.standardController(c);
                ContactProductHoldingTableCompController caseExt = new ContactProductHoldingTableCompController();
                caseExt.contId = c.PersonContactId;
                caseExt.retrieveProdtHoldings(c.PersonContactId);
                caseExt.getlistOfProdHold();
                caseExt.first();
                caseExt.last();
                caseExt.previous();
                caseExt.next(); 
                Boolean hN = caseExt.hasNext;
                Boolean hP = caseExt.hasPrevious;                
                Integer N = caseExt.pageNumber;                
                //Integer num = caseExt.pageNumber!=null ? caseExt.pageNumber : 0;
                //Boolean p = caseExt.hasPrevious!=null ? caseExt.hasPrevious : false;                                   
                //p = caseExt.hasNext;          
                //  system.assertEquals(c.Id, caseExt.myCase.id);
            Test.stopTest();
        }
    }
    
    /** 
    * @name: casePodHoldTableTestMethod1()
    * @desciption: test method for testing the retrieval of product holdings
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void casePodHoldTableTestMethod2() {
        Profile pr = [SELECT Id FROM Profile WHERE Name='SSSW - Service Agent']; 
        User usr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='TestingAgnt', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = pr.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduserkpt@testorg.com');
        
        ProductHolding_IconColor_Settings__c phSett = new ProductHolding_IconColor_Settings__c(Name='Active',Value__c='1234',isColor__c=false);
        insert(phSett);
        ProductHolding_IconColor_Settings__c phSett2 = new ProductHolding_IconColor_Settings__c(Name='Other',Value__c='1234',isColor__c=true);
        insert(phSett2);

        //Account c = [Select Id,PersonContactId from Account where PersonContactId!=null and APCN__pc!=null and APCN__pc='1001439913' limit 1];
        Account c = TestDataProvider.createPersonAccount('Tom',Constants.RECORDTYPE_NAME_ACCOUNT_PERSONACCOUNT);
        c.APCN__pc = '1001439913';
        database.insert(c);
        
         Contact perAcc2 = [Select id from Contact where AccountId=:c.Id limit 1];
        
        system.runAs(usr) {
            Test.startTest();
            try {
                //setting pageRefernce and checking on code functionality
                PageReference pageRef = page.CaseContactSidePanelProductHoldings;
                Test.setCurrentPageReference(pageRef);
                ApexPages.CurrentPage().getparameters().put('id', c.PersonContactId);
                ApexPages.StandardController sc = new ApexPages.standardController(c);
                ContactProductHoldingTableCompController caseExt = new ContactProductHoldingTableCompController();
                caseExt.contId = c.PersonContactId;
                caseExt.retrieveProdtHoldings(perAcc2.Id);
                caseExt.getlistOfProdHold();
                caseExt.listOfProdHold = new List<ContactProductHoldingTableCompController.ProdHoldWrapp>();
                caseExt.listOfProdHold.add(new ContactProductHoldingTableCompController.ProdHoldWrapp('',system.today(),'','',''));
                caseExt.first();
                caseExt.last();
                caseExt.previous();
                caseExt.next(); 
                caseExt.typePrdHld = 'MYPOST_CARD';
                caseExt.showPopup();
                caseExt.typePrdHld = 'MYDELIVERIES';
                caseExt.showPopup();
                caseExt.typePrdHld = 'PARCEL_LOCKER';
                caseExt.showPopup();
                caseExt.typePrdHld = 'PARCEL_COLLECT';
                caseExt.showPopup();
                caseExt.typePrdHld = 'POB';
                caseExt.showPopup();
                caseExt.closePopup();
                Map<String,String> test2 = caseExt.prdHoldIconMap;
                String str = caseExt.statusKeyValues ;
                caseExt.previousAdd();
                caseExt.nextAdd();
                Boolean hP = caseExt.hasPreviousAdd;
                Boolean hN = caseExt.hasNextAdd;
                caseExt.getlistOfAdd();
             }
             catch(Exception exp) {
             
             }   
                //Integer num = caseExt.pageNumber!=null ? caseExt.pageNumber : 0;
                //Boolean p = caseExt.hasPrevious!=null ? caseExt.hasPrevious : false;                                   
                //p = caseExt.hasNext;          
                //  system.assertEquals(c.Id, caseExt.myCase.id);
            Test.stopTest();
        }
    }
    
}