/**
  This test class is for SSSWCN08FormContExt.
    @author Frank Chen
    @created 2014-06-24
    @version 1.0
    @since 20.0

**************************************************
            History
2014-06-24 Frank Chen <di.chen@bluewolf.com>       Created   Test coverage  88%
16.11.2015    kalpita.talwadekar@auspost.com.au    Updated the code to check for business and consumer records and 
                                                   send template accordingly.
04.04.2022   saiswetha.pingali@auspost.com.au      REQ2723594 - Fix test class failures with validation rule error on compensation records.
2023-10-13 hasantha.liyanage@auspost.com.au Added Ref Id to test case as per new validation rule
**************************************************/
@isTest
private class SSSWCompensationLetterContExt_Test {

    /** 
      * @name: testCaseMgmt4()
      * @desciption: test method for testing the fax template for retail general customer enquiry
      * @param: NA
      * @return: NA
      *
      */
    static testMethod void myUnitTest() {
        
        User u = TestDataProvider.createTestUsers();
        u.FirstName ='nnn';
        u.LastName = 'mmm';
        u.Alias = 'nnmm';
        u.Email = 'mmnn@nnbb.com';
        u.Username = 'nnde@do.com';
        u.CommunityNickname = 'YOXI';       
        insert u;
        
        system.runAs(u){
        
            Contact con = TestDataProvider.createTestContact();
            insert con;
            
            Case case1 = new Case();
            case1.Type = 'Feedback';
            case1.Subject = 'Newsdd';
            case1.Status = 'Network Responded';
            case1.ProductCategory__c = 'Travel & ID';
            case1.EnquirySubType__c = 'Product Support';
            case1.ProductSubCategory__c = 'KeyPass';
            case1.ContactId = con.Id;
            case1.ReferenceID__c = 'REF123';
            insert case1;
            
            Compensation__c com = new Compensation__c();
            com.Case__c = case1.Id;
            com.Cover_Type__c = 'ACL';
            //com.Compensation_Type__c = 'Replacement Product';
            //com.Replacement_Value__c = 11;
            com.Contact__c = con.Id;
            com.Compensation_Amount__c =10;
            insert com;
            
            EmailTemplate et = new EmailTemplate();
            et.DeveloperName = 'SSSW_Compensation';
            et.Name = 'sdfd';
            et.FolderId = u.Id;
            et.IsActive = true;
            et.TemplateType = 'text';
            insert et;
            
            Test.startTest();
            
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(com);   
            SSSWCompensationLetterContExt ext = new SSSWCompensationLetterContExt(stdCtl);
            
            ext.getBody();
            
            system.assert(true);
            Test.stopTest();
        }
   }
   
   /** 
      * @name: testCaseMgmt4()
      * @desciption: test method for testing the fax template for retail general customer enquiry
      * @param: NA
      * @return: NA
      *
      */
   static testMethod void myUnitTest_BusinessName() {
        
        User u = TestDataProvider.createTestUsers();
        u.FirstName ='nnn';
        u.LastName = 'mmm';
        u.Alias = 'nnmm';
        u.Email = 'mmnn@nnbb.com';
        u.Username = 'nnde@do.com';
        u.CommunityNickname = 'YOXI';       
        insert u;
        
        system.runAs(u){
        
            Account acc = TestDataProvider.createAndSaveBusinessAccount('Business Acc', 'Organisation');
          //  insert acc;
            
            Contact con1 = TestDataProvider.createTestContact();
            con1.FirstName = 'SSSW';
            con1.LastName =  'Entitlements';
           insert con1;
           
           // Account con = TestDataProvider.createPersonAccount('Consumer Acc', 'Consumer');
           Contact con = TestDataProvider.createTestContact();
           con.AccountId = acc.Id;
           insert con;
            
            Case case1 = new Case();
            case1.Type = 'Feedback';
            case1.Subject = 'Newsdd';
            case1.Status = 'Network Responded';
            case1.ProductCategory__c = 'Travel & ID';
            case1.EnquirySubType__c = 'Product Support';
            case1.ProductSubCategory__c = 'KeyPass';
            case1.ContactId = con.Id;
            case1.AccountId = acc.Id;
            case1.ReferenceID__c = 'REF123';
            insert case1;
            
            Compensation__c com = new Compensation__c();
            com.Case__c = case1.Id;
            com.Cover_Type__c = 'ACL';
            //com.Compensation_Type__c = 'Replacement Product';
            //com.Replacement_Value__c = 11;
            com.Contact__c = con.Id;
            com.Compensation_Amount__c =10;
            insert com;
            
            EmailTemplate et = new EmailTemplate();
            et.DeveloperName = 'SSSW_Compensation_Business_Name';
            et.Name = 'sdfd';
            et.FolderId = u.Id;
            et.IsActive = true;
            et.TemplateType = 'text';
            insert et;
            
            Test.startTest();
            
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(com);   
            SSSWCompensationLetterContExt ext = new SSSWCompensationLetterContExt(stdCtl);
            
            ext.getBody();
            
            system.assert(true);
            Test.stopTest();
        }
   }
}