/**************************************************
Type: TIBCOArticleComponentCont_Test
History:
--------------------------------------------------
24-June-2014	:	di.chen@bluewolf.com Created
04-July-2018	:	dilshan.egodawela@auspost.com.au Updated
13.06.2024 Parveen Kaushik Added default value for mapping model on test data.
**************************************************/

/**
*  This test class is for TIBCOArticleComponentCont.
*
@author Frank Chen
@created 2014-06-24
@version 1.0
@since 20.0
*
@changelog
* 2014-06-24 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  89%
*/
@isTest
global class TIBCOArticleComponentCont_Test {
	
	//setup data
	@testSetup static void setup() {
		
		//create config record
		AusPostSettings__c oa = new AusPostSettings__c();
        oa.Password__c = 'w@X2mb?SbMi%';
        oa.Username__c = 'sssw_sts';
        oa.URL3__c = 'https://digitalapi-ptest.npe.auspost.com.au/auth/token';
        oa.URL2__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/pobLease/';
        oa.Name = 'SAPEMCustomerArticles';
        insert oa;
        
        MiniCaseFieldMapping__c mn = new MiniCaseFieldMapping__c(ProductCategory__c='eParcel', ProductSubcategory__c='eParcel Standard', Type__c='testing', SAPProductCategory__c ='eParcele', SAPProductSubcategory__c ='Parcel Standard', MappingModel__c = SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL);
		insert mn;
		
	}
	
	/********************************************
    Scenario:Test set Article method on the controller
    if successful, productCategory values on the  controller should be same as the Article
    *********************************************/
	static testMethod void testArticleRetrival(){
		//create new article
		Article__c article = new Article__c();
	    	article.Name = '123';
	    	article.ArticleLodgementDate__c = date.today();
	    	article.SenderPostcode__c = '123';
	    	article.ReceiverPostcode__c = '3002';
	    	article.ArticleType__c = 'Regular Parcel';
	    	article.ReceiverName__c = '123';
	    	article.ReceiverEmail__c = 'dsf@163.com';
	    	article.ArticleLodgementDate__c = date.today();
	    	article.ProductCategory__c = 'eParcel';
	    	article.ArticleTransitAmountValue__c = 1;
	    	article.SubProduct__c = 'eParcel Standard';
	    	article.ActualWeight__c = 2;
	    	article.DeliveryInstructions__c = '99bb';
		article.ArticleID__c = 'HJJKJ5465KM';
	    	insert article;
	    	
	    	//craete new event message
	    	EventMessage__c message = new EventMessage__c();
        message.Article__c = article.Id;
        message.SenderID__c = 'bg';
        message.ActualDateTime__c = date.today() + 1;
        message.EventType__c = 'DD-ER13';
        message.SignatureXString__c = '1';
        insert message;
        
        //craete a map with event messages for each article
        Map<Id, List<EventMessage__c>> articleToEventMessages = new Map<Id, List<EventMessage__c>>();
	    	List<EventMessage__c> messageList = new List<EventMessage__c>();
	    	messageList.add(message);
	    	
	    	articleToEventMessages.put(article.Id,messageList);
	    	
	    	Test.startTest();
        
    		TIBCOArticleWrapper articleWrapper = new TIBCOArticleWrapper(article,articleToEventMessages);
    		TIBCOArticleComponentCont tib = new TIBCOArticleComponentCont();
		//set bound article
        tib.setBoundArticle(articleWrapper);
		tib.getBoundArticle();
		
		Test.stopTest();
		//Check product category
		System.assertEquals('eParcel',tib.productCategory, 'TIBCOArticleComponentCont_Test : check prodcutCategory ');
		
		//Check productSubcategory
		System.assertEquals('eParcel Standard',tib.productSubcategory, 'TIBCOArticleComponentCont_Test : check productSubcategory ');
		
		//Check caseType
		System.assertEquals('testing',tib.caseType, 'TIBCOArticleComponentCont_Test : check caseType ');
	}
	
	/********************************************
    Scenario:Test Request to Safedrop and unset Safedrop funtionalities.
    To request safedrop, an Article firstly should be eligible. And Only eligible articles can be safe dropped.
    to Unset/remove safedrop on an Article, Safedrop has be requested previously.
    *********************************************/
	static testMethod void testSafeDropEligibility() {
		
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MyPostHttpMock());
        
        String eligibilityMessage = TIBCOArticleComponentCont.saveToSAPEM('HJJKJ5465ELG','');
        String removeSafeDropMessage = TIBCOArticleComponentCont.unsetSafeDrop('HJJKJ5465ELG','');
        Test.stopTest();
        System.assertEquals('Safe Drop request submitted successfully.',eligibilityMessage, '');
        System.assertEquals('Remove Safe Drop request submitted successfully.',removeSafeDropMessage, '');
	}
	
	/********************************************
    Scenario:Test Request to get Safedrop ineligibility reason
    To request safedrop, an Article firstly should be eligible. And Only eligible articles can be safe dropped.
    *********************************************/
	static testMethod void testSafeDropIneligibilityCodes() {
		
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MyPostHttpMock());
        
        String ineligibilityMessage = TIBCOArticleComponentCont.getSAPEMValues('HJJKJ5465INELG','');
        Test.stopTest();
        String msg = [SELECT id,Reason__c,MasterLabel FROM Ineligibility_Reason__mdt where MasterLabel= '1'].Reason__c;
        System.assertEquals('Ineligible: '+msg,ineligibilityMessage, '');
	}
	
	/********************************************
    Scenario:Test response with unrecognised ineligibility codes
    when a unrecognised eligibility code is returned, the reason should be blank.
    *********************************************/
	static testMethod void testUnrecognisedIneligibilityCodes() {
		
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MyPostHttpMock());
        
        String ineligibilityMessage = TIBCOArticleComponentCont.getSAPEMValues('HJJKJ5465INELG2','');
        Test.stopTest();
        System.assertEquals('',ineligibilityMessage, '');
	}
	
	/********************************************
    Scenario:Test response with empty ineligibility code
    *********************************************/
	static testMethod void testEmptyIneligibilityCodes() {
		
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MyPostHttpMock());
        
        String ineligibilityMessage = TIBCOArticleComponentCont.getSAPEMValues('HJJKJ5465INELG1','');
        Test.stopTest();
        System.assertEquals('Ineligible: Could not find reason for Ineligibility.',ineligibilityMessage, '');
	}

	global class MyPostHttpMock implements HttpCalloutMock{
		global HttpResponse respond(HTTPRequest req){
			HttpResponse res = new HttpResponse();
			if(req.getEndpoint().endsWith('HJJKJ5465ELG\')/SafeDropStatus?$format=json')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"d": {"ArticleID": "HJJKJ5465KM","StatusValue": "Eligible"}}');
				return res;
			}
			else if(req.getEndpoint().endsWith('token')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"foo":"bar"}');
				return res;
			}
			else if(req.getEndpoint().endsWith('\'ADD\'&$format=json')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"d": {"ArticleID": "HMM000154201000605008","StatusValue": "Eligible"}}');
				return res;
			}
			else if(req.getEndpoint().endsWith('HJJKJ5465INELG\')/SafeDropStatus?$format=json')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"d": {"ArticleID": "HJJKJ5465KM","StatusValue": "Ineligible"}}');
				return res;
			}
			else if(req.getEndpoint().endsWith('HJJKJ5465REQ\')/SafeDropStatus?$format=json')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"d": {"ArticleID": "HJJKJ5465KM","StatusValue": "Requested"}}');
				return res;
			}
			else if(req.getEndpoint().endsWith('HJJKJ5465CAN\')/SafeDropStatus?$format=json')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"d": {"ArticleID": "HJJKJ5465KM","StatusValue": "Cancelled"}}');
				return res;
			}
			else if(req.getEndpoint().endsWith('\'DELETE\'&$format=json')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"d": {"ArticleID": "HMM000154201000605008","StatusValue": "Eligible"}}');
				return res;
			}
            else if(req.getEndpoint().endsWith('HJJKJ5465INELG1\')/SafeDropStatus?$format=json')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"d": {"ArticleID": "HJJKJ5465KM","StatusValue": "Ineligible"}}');
				return res;
			}
            else if(req.getEndpoint().endsWith('HJJKJ5465INELG2\')/SafeDropStatus?$format=json')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"d": {"ArticleID": "HJJKJ5465KM","StatusValue": "Ineligible"}}');
				return res;
			}
			else if(req.getEndpoint().endsWith('HJJKJ5465INELG\')/SafeDropInfo?$format=json')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"d": {"ArticleID": "HJJKJ5465KM","IneligibilityReason": "1"}}');
				return res;
			}
			else if(req.getEndpoint().endsWith('HJJKJ5465INELG2\')/SafeDropInfo?$format=json')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"d": {"ArticleID": "HJJKJ5465KM","IneligibilityReason": "99"}}');
				return res;
			}
			else if(req.getEndpoint().endsWith('HJJKJ5465INELG1\')/SafeDropInfo?$format=json')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"d": {"ArticleID": "HJJKJ5465KM","IneligibilityReason": ""}}');
				return res;
			}
			return res;
		}
	}
}