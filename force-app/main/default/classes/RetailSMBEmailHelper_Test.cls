/*
    @Author      :  Snigdha.Sahu@auspost.com.au
    @Name        :  RetailSMBEmailHelper_Test
    @Date        :  10/05/2016
    @Description :  Test Class for for RetailSMBEmailHelper. 
*/
@isTest
public class RetailSMBEmailHelper_Test{
     
     static testMethod void RetailSMBEmailHelper_01()
     {
         Profile test_profile = [SELECT Name, Id FROM Profile WHERE Name ='Standard User']; 
         User test_user = [SELECT Id FROM User WHERE ProfileId = :test_profile.Id AND isActive = TRUE LIMIT 1 ];
         Document doc = new Document
                  (                     
                   ContentType = 'application/pdf', 
                   DeveloperName = 'test_document', 
                   IsPublic = true, 
                   Name = 'My Test Document',
                   FolderId = [select id from folder where name = 'Retail_SMB'].id
                   );
		insert doc;
         
        
        system.debug('id of the doc ' + doc.Id);
         
         System.runAs(test_user )
         {
             test.startTest(); 
             Test.setCurrentPageReference(new PageReference('Page.RetailSMBKnowledgeSearchTop5')); 
		     System.currentPageReference().getParameters().put('fileparam', String.valueOf(doc.Id));
             RetailSMBEmailHelper.email = 'abc@test.com.au';
             //RetailSMBEmailHelper.fileparam = '='+String.valueOf(doc.Id);
             //RetailSMBEmailHelper.file=String.valueOf(doc.Id);
             //system.debug('RetailSMBEmailHelper.file ' + RetailSMBEmailHelper.file);
             RetailSMBEmailHelper.SendEmail();           

         }
         
     } 


}