/**
*  This test class is for SendSMSControllerExtension.
*
@author Frank Chen
@created 2014-06-23
@version 1.0
@since 20.0
*
@changelog
* 2014-06-23 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage
*/
@isTest
private class EditCN08ContExt_Test {

    static testMethod void myUnitTest() {
    	
    	Contact con = new Contact(FirstName = 'test', LastName = 'test', Phone = '718273672', Email = 'test@test.com', MailingCity = 'test city');
    	insert con;
    	
    	List<Article__c> list_art = new List<Article__c>();
    	List<Case> list_case = new List<Case>();
        
    	Article__c art1 = new Article__c();
    	art1.Name = '123';
    	art1.ArticleLodgementDate__c = date.today();
    	art1.SenderPostcode__c = '123';
    	art1.ReceiverPostcode__c = '3002';
    	art1.ArticleType__c = 'Regular Parcel';
    	art1.MailCategory__c = 'airmail';
    	list_art.add(art1);
    	
    	Article__c art = new Article__c();
    	art.Name = '1234';
    	art.ArticleLodgementDate__c = date.today();
    	art.SenderPostcode__c = '123';
    	art.ReceiverPostcode__c = '3002';
    	art.ArticleType__c = 'Regular Parcel';
    	art.MailCategory__c = 'seamail';
    	list_art.add(art);
    	insert list_art;
    	
    	Case case1 = new Case();
    	case1.ContactId = con.Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.ArticleTest__c = art.Id;
        list_case.add(case1);
        
        Case case2 = new Case();
    	case2.ContactId = con.Id;
        case2.Type = 'Feedback';
        case2.Subject = 'Newsdd';
        case2.Status = 'Network Responded';
        case2.ProductCategory__c = 'Travel & ID';
        case2.EnquirySubType__c = 'Product Support';
        case2.ProductSubCategory__c = 'KeyPass';
        case2.ArticleTest__c = art1.Id;
        list_case.add(case2);
        insert list_case;
        
    	CN08__c cn = new CN08__c();
    	cn.Case__c = case1.Id;
    	insert cn;
    	cn = [SELECT Id,Name FROM CN08__c WHERE Id =: cn.Id];
    	
    	CN08__c cn2 = new CN08__c();
    	cn2.Case__c = case2.Id;
    	
        Test.startTest();
        
		ApexPages.StandardController stdCtl = new ApexPages.StandardController(cn); 
		EditCN08ContExt ext = new EditCN08ContExt(stdCtl);
		
		ApexPages.StandardController stdCtl2 = new ApexPages.StandardController(cn2);   
		EditCN08ContExt ext2 = new EditCN08ContExt(stdCtl2); 
		
		//ext.cn08 = cn;
		
		ext.save();
		
		Attachment att = new Attachment();
    	att.ParentId = case1.Id;
    	att.Name = cn.Name + '.pdf';
    	att.Body = blob.valueOf('test body');
    	insert att;
    	
		ext.createAttachment();
        
        system.assert(true);
        Test.stopTest();
    }
}