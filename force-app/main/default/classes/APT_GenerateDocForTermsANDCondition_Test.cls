/**
Description - This apex class is test class for apex class - APT_GenerateDocForTermsANDCondition.
Created By - Sagar Jogi
Created Date - 12th July, 2016
Last Modified By -
Last Modified Date -
**/
/***************
 * @Modified By : Aditya Shetty 
 * @Modified On : 20/03/2020
 * @Description : Changes to skip validations on CreateOpportunity
 * *************/
@isTest
public class APT_GenerateDocForTermsANDCondition_Test {
    /**
    Creating test data
    **/
    @testSetup
    private static void testSetup(){
       
            PageReference myVfPage = Page.c__APT_GenerateDocForT_C;
            
            Contact con= APT_TestUtils.createContact();
            insert con;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;
            /* Change: Aditya Shetty: Changes to skip validations on CreateOpportunity  */
            Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
            insert opp;
            /* Change: Aditya Shetty: Changes to skip validations on CreateOpportunity  */
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: APT_Constants.STRING_SYSTEM_ADMINISTRATOR limit 1];
            
            Test.startTest();
            
            
            RecordType QuoteRecordType = [SELECT Id, Name FROM RecordType WHERE Name = :APT_Constants.RECORD_TYPE_PROPOSAL AND sObjectType = :APT_Constants.SOQL_PROPOSAL_OBJECT  limit 1];

            
            //create proposal
            List<Apttus_Proposal__Proposal__c> proposallist = new List<Apttus_Proposal__Proposal__c>();
            Apttus_Proposal__Proposal__c aptProposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,APT_Constants.RECORD_TYPE_PROPOSAL,APT_Constants.PROPOSAL_NAME,priceList.id);
            aptProposal.Exempted_Product_Type__c = 'Workforce Verification';//define exempted product fpr proposal
            proposallist.add(aptProposal);
            insert proposallist;
            
            Attachment attachment = new Attachment();  
            //Need to modify the code
            attachment.ParentId = aptProposal.Id;  
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
                
                
                APT_GenerateDocForTermsANDCondition con = new APT_GenerateDocForTermsANDCondition();
                
                
                PageReference pageRef = con.generate();
                
                Test.stopTest();
                
                //System.assertNotEquals(null,pageRef);
                
                /*
                String attachmentId = [SELECT Id FROM Attachment LIMIT 1].Id;
                
                
                //Verify the pageRef parameters as well
                Map<String,String> pageParameters = pageRef.getParameters();
            
                System.assertEquals('/' + attachmentId, pageRef.getUrl());
                */
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
            tmp.Apttus__IsActive__c = true;
            insert tmp;
            
            APT_R2T_System_Properties__c systemProperties = new APT_R2T_System_Properties__c();            
            systemProperties.APT_Terms_Condition_Template__c = APT_Constants.STRING_TEMPLATE;
            insert systemProperties;
            
            test.startTest();
	    //set proposal id as current page id
            Apttus_Proposal__Proposal__c proposal = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_PARENTID,proposal.id);
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_TEMPLATENAME,APT_Constants.STRING_TEMPLATE);
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_TEMPLATEID,tmp.id);
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_DOC_FORMAT,APT_Constants.DOCUMENT_TYPE_DOCX_LOWER);   
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_DOC_FORMAT,APT_Constants.DOCUMENT_TYPE_PDF_LOWER);
            ApexPages.currentPage().getParameters().put(APT_Constants.URL_DOC_FORMAT,APT_Constants.DOCUMENT_TYPE_RTF_LOWER);
            APT_GenerateDocForTermsANDCondition con = new APT_GenerateDocForTermsANDCondition();
            PageReference pgRef = con.generate();
            
            
            test.stopTest();
            //System.assert(pgRef != null);
        }
    }
}