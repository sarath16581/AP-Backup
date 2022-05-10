/**
Description - This apex class is test class for apex class - APT_GenerateOperationalScheduleControler.
Created By - Himanshu Jain
Created Date - 27th Oct, 2015
Last Modified By -
Last Modified Date -
**/
@isTest
public class APT_GenerateOperationalSchedule_Test {
    /**
    Creating test data
    **/
    @testSetup
    private static void testSetup(){
       
            PageReference myVfPage = Page.APT_GenerateOperationalSchedule;
            
            Contact con= APT_TestUtils.createContact();
            insert con;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: APT_Constants.STRING_SYSTEM_ADMINISTRATOR limit 1];
            
            Test.startTest();
            
            
            RecordType tariffQuoteRecordType = [SELECT Id, Name FROM RecordType WHERE Name = :APT_Constants.RECORD_TYPE_SECURE_PAY_ONLINE_PAYMENTS AND sObjectType = :APT_Constants.SOQL_AGREEMENT_OBJECT limit 1];
            
            Application__c appli = new Application__c();
            //appli.Name = 'test';
            appli.Opportunity__c = opp.Id;
            appli.Account__c = tempacct.Id;
            insert appli;
            
            //create agreement
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.APT_Product__c= APT_Constants.PRODUCT_NAME_EPARCEL ;
            aptContract.Apttus__Related_Opportunity__c=opp.Id;
            aptContract.Apttus__Account__c=tempacct.Id;
            //aptContract.RecordTypeId = tariffQuoteRecordType.ID;
            //aptContract.RecordType = [Select Id, Name, DeveloperName From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            //aptContract.RecordType.DeveloperName = 'Securepay Online Payments';
            //aptContract.Apttus_QPComply__RelatedProposalId__r.APT_Method_of_Payment__c ='Charge Account';
            System.debug('aptCp');
            // System.debug('*Query:' + [Select Id, Name, DeveloperName From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1]);
            System.debug('*aptContract.'+aptContract.RecordType.DeveloperName);
           // List<Apttus__APTS_Agreement__c> agr = new List<Apttus__APTS_Agreement__c>();
            agreementList.add(aptContract);
            insert agreementList;
            
            Attachment attachment = new Attachment();  
            //Need to modify the code
            attachment.ParentId = aptContract.Id;  
            attachment.Name = APT_Constants.STRING_TEST_ATTACHMENT_FOR_PARENT; 
            
            Blob body = Blob.valueOf(APT_Constants.STRING_TEST_DATA);  
          
            attachment.Body = body; 
            insert attachment;
            
            Test.setCurrentPage(myVfPage);
            
            //Need to modify the code
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_PARENTID,APT_Constants.EMPTY_STRING);
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_TEMPLATENAME,APT_Constants.EMPTY_STRING);
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_TEMPLATEID,APT_Constants.EMPTY_STRING);
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_DOC_FORMAT,APT_Constants.EMPTY_STRING);    
            Test.stopTest();
            System.assert(myVfPage!=null);
       
    }
    /**
        Creating test data
    **/    
    private static testmethod void testGenerateOperationalSchedule(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {        
            try{
            
                Test.startTest();
                
                
                APT_GenerateOperationalScheduleControler con = new APT_GenerateOperationalScheduleControler();
                
                
                PageReference pageRef = con.generate();
                
                Test.stopTest();
                
                System.assertNotEquals(null,pageRef);
                
                
                String attachmentId = [SELECT Id FROM Attachment LIMIT 1].Id;
                
                
                //Verify the pageRef parameters as well
                Map<String,String> pageParameters = pageRef.getParameters();
            
                System.assertEquals('/' + attachmentId, pageRef.getUrl());
                
                //System.assertEquals(1,pageParameters.values().size());
                //System.assertEquals('recordId',pageParameters.get('id'));           
                
            } catch (Exception ex){
                
                System.assert(false,ex.getMessage());
            }
        }
    }
    /**
        Creating test data
    **/
    private static testmethod void testGenerateOperationalSchedule1(){  
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {    
            Apttus__APTS_Template__c tmp = new Apttus__APTS_Template__c();
            tmp.name = APT_Constants.STRING_TEMPLATE;
            insert tmp;
            
            test.startTest();
            
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_PARENTID,tmp.id);
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_TEMPLATENAME,APT_Constants.STRING_TEMPLATE);
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_TEMPLATEID,tmp.id);
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_DOC_FORMAT,APT_Constants.DOCUMENT_TYPE_DOCX_LOWER);   
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_DOC_FORMAT,APT_Constants.DOCUMENT_TYPE_PDF_LOWER);
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_DOC_FORMAT,APT_Constants.DOCUMENT_TYPE_RTF_LOWER);
            APT_GenerateOperationalScheduleControler con = new APT_GenerateOperationalScheduleControler();
            PageReference pgRef = con.generate();
            
            
            test.stopTest();
            System.assert(pgRef != null);
        }
    }
}