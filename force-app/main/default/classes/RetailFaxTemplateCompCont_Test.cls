/**
    * This Class is as as test class for RetailFaxTemplateCompCont controller.  
    * 
    * @Author kalpita.talwadekar@auspost.com.au
    * @Date 21/09/2015
    *   
    */
@isTest
public with sharing class RetailFaxTemplateCompCont_Test{

    @testSetup static void setup() {
        // Setup test data
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='SSSW - Service Agent']; 
        User usr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='TestingAgnt', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com');
    }


    /** 
    * @name: caseFaxTemplateTestMethod1()
    * @desciption: test method for testing the fax template for retail general customer enquiry
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void caseFaxTemplateTestMethod1() {
        //creating test data

        Contact con = TestDataProvider.createAndSaveContact();
        User usr = [Select Id from User limit 1];
        system.runAs(usr){

            Case c = TestDataProvider.createCase();
            c.EnquirySubType__c = 'General Enquiry';
            //c.ContactId = con.Id;
            database.insert(c);
            Test.startTest();
                //setting pageRefernce and checking on code functionality
                PageReference pageRef = page.SSSW_Case_FaxTemplateHTML;
                Test.setCurrentPageReference(pageRef);
                ApexPages.CurrentPage().getparameters().put('id', c.id);
                ApexPages.StandardController sc = new ApexPages.standardController(c);
                RetailFaxTemplateCompCont caseExt = new RetailFaxTemplateCompCont(sc);
                caseExt.getTempTitle();
                String dt = caseExt.timaestamp;
                system.assertEquals(c.Id, caseExt.myCase.id);
            Test.stopTest();
        }
    }
    
    /** 
    * @name: caseFaxTemplateTestMethod2()
    * @desciption: test method for testing the fax template for retail 'Item Transfer'
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void caseFaxTemplateTestMethod2() {
        //creating test data
        Contact con = TestDataProvider.createAndSaveContact();
        User usr = [Select Id from User limit 1];
        system.runAs(usr){
            Case c = TestDataProvider.createCase();
            c.EnquirySubType__c = 'Item Transfer';
            //c.ContactId = con.Id;
            database.insert(c);

            Test.startTest();
                //setting pageRefernce and checking on code functionality
                PageReference pageRef = page.SSSW_Case_FaxTemplateHTML;
                Test.setCurrentPageReference(pageRef);
                ApexPages.CurrentPage().getparameters().put('id', c.id);
                ApexPages.StandardController sc = new ApexPages.standardController(c);
                RetailFaxTemplateCompCont caseExt = new RetailFaxTemplateCompCont(sc);
                caseExt.getTempTitle();
                String dt = caseExt.timaestamp;
                system.assertEquals(c.Id, caseExt.myCase.id);
            Test.stopTest();
        }
    }
    
    /** 
    * @name: caseFaxTemplateTestMethod3()
    * @desciption: test method for testing the fax template for retail  'Missing Item'
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void caseFaxTemplateTestMethod3() {
        //creating test data
        Contact con = TestDataProvider.createAndSaveContact();
        User usr = [Select Id from User limit 1];
        system.runAs(usr){
            Case c = TestDataProvider.createCase();
            c.EnquirySubType__c = 'Missing Item';
            //c.ContactId = con.Id;
            c.ReferenceID__c = 'test1234';
            database.insert(c);

            Test.startTest();
                //setting pageRefernce and checking on code functionality
                PageReference pageRef = page.SSSW_Case_FaxTemplateHTML;
                Test.setCurrentPageReference(pageRef);
                ApexPages.CurrentPage().getparameters().put('id', c.id);
                ApexPages.StandardController sc = new ApexPages.standardController(c);
                RetailFaxTemplateCompCont caseExt = new RetailFaxTemplateCompCont(sc);
                caseExt.getTempTitle();
                String dt = caseExt.timaestamp;
                system.assertEquals(c.Id, caseExt.myCase.id);
            Test.stopTest();
        }
    }
    
    /** 
    * @name: caseFaxTemplateTestMethod4()
    * @desciption: test method for testing the fax template for retail  'RTS Request'
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void caseFaxTemplateTestMethod4() {
        //creating test data
        Contact con = TestDataProvider.createAndSaveContact();
        User usr = [Select Id from User limit 1];
        system.runAs(usr){
            Case c = TestDataProvider.createCase();
            c.EnquirySubType__c = 'RTS Request';
            //c.ContactId = con.Id;
            database.insert(c);

            Test.startTest();
                //setting pageRefernce and checking on code functionality
                PageReference pageRef = page.SSSW_Case_FaxTemplateHTML;
                Test.setCurrentPageReference(pageRef);
                ApexPages.CurrentPage().getparameters().put('id', c.id);
                ApexPages.StandardController sc = new ApexPages.standardController(c);
                RetailFaxTemplateCompCont caseExt = new RetailFaxTemplateCompCont(sc);
                caseExt.getTempTitle();
                String dt = caseExt.timaestamp;
                system.assertEquals(c.Id, caseExt.myCase.id);
            Test.stopTest();
        }
    }
    /** 
    * @name: caseFaxTemplateTestMethod5()
    * @desciption: test method for testing the fax template for retail 'Disputed Delivery'
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void caseFaxTemplateTestMethod5() {
        //creating test data
        Contact con = TestDataProvider.createAndSaveContact();
        User usr = [Select Id from User limit 1];
        system.runAs(usr){
            Case c = TestDataProvider.createCase();
            c.EnquirySubType__c = 'Disputed Delivery';
            //c.ContactId = con.Id;
            database.insert(c);

            Test.startTest();
                //setting pageRefernce and checking on code functionality
                PageReference pageRef = page.SSSW_Case_FaxTemplateHTML;
                Test.setCurrentPageReference(pageRef);
                ApexPages.CurrentPage().getparameters().put('id', c.id);
                ApexPages.StandardController sc = new ApexPages.standardController(c);
                RetailFaxTemplateCompCont caseExt = new RetailFaxTemplateCompCont(sc);
                caseExt.getTempTitle();
                String dt = caseExt.timaestamp;
                system.assertEquals(c.Id, caseExt.myCase.id);
            Test.stopTest();
        }
    }
    /** 
    * @name: caseFaxTemplateTestMethod6()
    * @desciption: test method for testing the fax template for 'Remmitance not recieved'
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void caseFaxTemplateTestMethod6() {
        //creating test data
        Contact con = TestDataProvider.createAndSaveContact();
        User usr = [Select Id from User limit 1];
        system.runAs(usr){
            Case c = TestDataProvider.createCase();
            c.EnquirySubType__c = 'Remmitance not recieved';
            //c.ContactId = con.Id;
            database.insert(c);

            Test.startTest();
                //setting pageRefernce and checking on code functionality
                PageReference pageRef = page.SSSW_Case_FaxTemplateHTML;
                Test.setCurrentPageReference(pageRef);
                ApexPages.CurrentPage().getparameters().put('id', c.id);
                ApexPages.StandardController sc = new ApexPages.standardController(c);
                RetailFaxTemplateCompCont caseExt = new RetailFaxTemplateCompCont(sc);
                caseExt.getTempTitle();
                String dt = caseExt.timaestamp;
                system.assertEquals(c.Id, caseExt.myCase.id);
            Test.stopTest();
        }
    }


    /** 
    * @name: caseFaxTemplateTestMethod7()
    * @desciption: test method for testing the fax template for retail 'Delivery Complaint'
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void caseFaxTemplateTestMethod7() {
        //creating test data
        Contact con = TestDataProvider.createAndSaveContact();
        User usr = [Select Id from User limit 1];
        system.runAs(usr){
            Case c = TestDataProvider.createCase();
            c.EnquirySubType__c = 'Delivery Complaint';
            //c.ContactId = con.Id;
            database.insert(c);

            Test.startTest();
                //setting pageRefernce and checking on code functionality
                PageReference pageRef = page.SSSW_Case_FaxTemplateHTML;
                Test.setCurrentPageReference(pageRef);
                ApexPages.CurrentPage().getparameters().put('id', c.id);
                ApexPages.StandardController sc = new ApexPages.standardController(c);
                RetailFaxTemplateCompCont caseExt = new RetailFaxTemplateCompCont(sc);
                caseExt.getTempTitle();
                caseExt.getItemSearchArticleFields();
                caseExt.getItemSearchEventMessagesFields();
                String dt = caseExt.timaestamp;
                system.assertEquals(c.Id, caseExt.myCase.id);
            Test.stopTest();
        }
    }
    
    /** 
    * @name: caseFaxTemplateTestMethod7()
    * @desciption: test method for testing the fax template for retail 'Delivery Complaint'
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void caseFaxTemplateTestMethod8() {
        //creating test data
        Contact con = TestDataProvider.createAndSaveContact();
        User usr = [Select Id from User limit 1];
        Article__c art = TestDataProvider.createTestArticle();
        insert art;
        EventMessage__c em = new EventMessage__c(EventId__c='1234',Article__c=art.id,ActualDateTime__c=system.now());
        insert em;
        system.runAs(usr){
            Case c = TestDataProvider.createCase();
            c.EnquirySubType__c = 'Delivery Complaint';
            c.ReferenceID__c = art.Id;
            //c.ContactId = con.Id;
            database.insert(c);

            Test.startTest();
                //setting pageRefernce and checking on code functionality
                PageReference pageRef = page.SSSW_Case_FaxTemplateHTML;
                Test.setCurrentPageReference(pageRef);
                ApexPages.CurrentPage().getparameters().put('id', c.id);
                ApexPages.StandardController sc = new ApexPages.standardController(c);
                RetailFaxTemplateCompCont caseExt = new RetailFaxTemplateCompCont(sc);
                caseExt.getTempTitle();
                caseExt.getItemSearchArticleFields();
                caseExt.getItemSearchEventMessagesFields();
                String dt = caseExt.timaestamp;
                caseExt.caseId = c.id;
                RetailFaxEventaMgmtTableContr cntr2 = new RetailFaxEventaMgmtTableContr();
                TIBCOEventMessageWrapper wrap = new TIBCOEventMessageWrapper(em);
                cntr2.emWrap = new List<TIBCOEventMessageWrapper> {wrap};
               // cntr2.emWrap = caseExt.articleDetails.eventMessages;
                
                system.assertEquals(c.Id, caseExt.myCase.id);
            Test.stopTest();
        }
    }
}