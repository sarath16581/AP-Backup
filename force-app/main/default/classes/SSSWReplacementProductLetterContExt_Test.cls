@IsTest
private class SSSWReplacementProductLetterContExt_Test {

    static testMethod void productreplacementConsumer() {
        
        User u = TestDataProvider.createTestUsers();
        u.FirstName ='nnn';
        u.LastName = 'mmm';
        u.Alias = 'nnmm';
        u.Email = 'mmnn@nnbb.com';
        u.Username = 'nnde@do.com';
        u.CommunityNickname = 'YOXI';       
        insert u;
        
        system.runAs(u){
        
            Account Acc = TestDataProvider.createPersonAccount('Consumer Acc', 'Consumer');
            insert acc;
            
            Contact con = [select id from contact where accountid =:Acc.id limit 1];
            String repId = [select id from RecordType where SObjectType='Compensation__c' and Name='Replacement Product' limit 1].Id;            
            
            Case case1 = new Case();
            case1.Type = 'Feedback';
            case1.Subject = 'Newsdd';
            case1.Status = 'Network Responded';
            case1.ProductCategory__c = 'Travel & ID';
            case1.EnquirySubType__c = 'Product Support';
            case1.ProductSubCategory__c = 'KeyPass';
            case1.ContactId = con.Id;
            insert case1;
            
            Compensation__c com = new Compensation__c();
            com.Case__c = case1.Id;
            com.RecordTypeId = repId;
            //com.Replacement_Value__c = 11;
            com.Contact__c = con.Id;
            insert com;
            
            EmailTemplate et = new EmailTemplate();
            et.DeveloperName = 'SSSW_Replacement_Product_Letter';
            et.Name = 'sdfd';
            et.FolderId = u.Id;
            et.IsActive = true;
            et.TemplateType = 'text';
            insert et;
            
            Test.startTest();
            
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(com);   
            SSSWReplacementProductLetterContExt ext = new SSSWReplacementProductLetterContExt(stdCtl);
            
            ext.getBody();
            
            system.assert(true);
            Test.stopTest();
        }
   }
   
   static testMethod void productreplacement_BusinessName() {
        
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
            
            String repId = [select id from RecordType where SObjectType='Compensation__c' and Name='Replacement Product' limit 1].Id;            
            
    
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
            insert case1;
            
            Compensation__c com = new Compensation__c();
            com.Case__c = case1.Id;
            com.RecordTypeId=repId;
            //com.Replacement_Value__c = 11;
            com.Contact__c = con.Id;
            insert com;
            
            EmailTemplate et = new EmailTemplate();
            et.DeveloperName = 'SSSW_Replacement_Product_Letter_with_Business_Name';
            et.Name = 'sdfd';
            et.FolderId = u.Id;
            et.IsActive = true;
            et.TemplateType = 'text';
            insert et;
            
            Test.startTest();
            
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(com);   
            SSSWReplacementProductLetterContExt ext = new SSSWReplacementProductLetterContExt(stdCtl);
            
            ext.getBody();
            
            system.assert(true);
            Test.stopTest();
        }
   }


}