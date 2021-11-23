/**************************************************
	Type:	LiveChat Transcript Trigger Test
	History:
--------------------------------------------------
	29-10-2018: TDO-22 : xiang.zheng@auspost.com.au Unit tests
**************************************************/
@isTest
private class LiveChatTranscriptTriggerTest {
    /**
	 * SCENARIO: insert case first, query the Case and LiveChatTranscript with the same chatKey, the Case Id equals to the caseId field in LiveChatTranscript.
	 */
	@isTest static void testLiveChatTranscript_addCaseId() {
        Contact con = TestDataProvider.createTestContact();
        insert con;
        
	    Case case1 = new Case();
        case1.RecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'New';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.ContactId = con.Id;
        case1.ReferenceID__c = '123';
        case1.ChatKey__c = '8f441452-eb7d-4142-8ae6-5b3f4a44f7d0';
        insert case1;
        
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        
        LiveChatTranscript testScript = new LiveChatTranscript();
        testScript.ChatKey =  '8f441452-eb7d-4142-8ae6-5b3f4a44f7d0';
        testScript.Body = 'test';
        testScript.LiveChatVisitorid = lcv.id;
        insert testScript;

	    LiveChatTranscript testScript1 = [select CaseId from LiveChatTranscript where Id = :testScript.Id];
        system.assert(case1.Id == testScript1.CaseId);
	}
	
	 /**
	 * SCENARIO:  insert case first, query the Case and LiveChatTranscript with the different chatKey, the Case Id not equals to the caseId field in LiveChatTranscript.
	 */
	@isTest static void testLiveChatTranscript_addCaseId_notMatch() {
        Contact con = TestDataProvider.createTestContact();
        insert con;
        
	    Case case1 = new Case();
        case1.RecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'New';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.ContactId = con.Id;
        case1.ReferenceID__c = '123';
        case1.ChatKey__c = '8f441452-eb7d-4142-8ae6';
        insert case1;
        
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        
        LiveChatTranscript testScript = new LiveChatTranscript();
        testScript.ChatKey =  '8f441452-eb7d-4142-8ae6-5b3f4a44f7d0';
        testScript.Body = 'test';
        testScript.LiveChatVisitorid = lcv.id;
        insert testScript;

	    LiveChatTranscript testScript1 = [select CaseId from LiveChatTranscript where Id = :testScript.Id];
        system.assert(case1.Id != testScript1.CaseId);
	}
	
	 /**
	 * SCENARIO: insert LiveChatTranscript first,  query the Case and LiveChatTranscript with the same chatKey, the Case Id equals to the caseId field in LiveChatTranscript.
	 */
	@isTest static void testLiveChatTranscript_addCaseId_insertScriptFirst() {
	    Test.startTest();
	    LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        
        LiveChatTranscript testScript = new LiveChatTranscript();
        testScript.ChatKey =  '8f441452-eb7d-6162-8ae6-5b3f4a44f7d0';
        testScript.Body = 'test';
        testScript.LiveChatVisitorid = lcv.id;
        insert testScript;
        
        Contact con = TestDataProvider.createTestContact();
        insert con;
        
	    Case case1 = new Case();
        case1.RecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'New';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.ContactId = con.Id;
        case1.ReferenceID__c = '123';
        case1.ChatKey__c = '8f441452-eb7d-6162-8ae6-5b3f4a44f7d0';
        insert case1;
        Test.stopTest();
        
	    LiveChatTranscript testScript1 = [select CaseId from LiveChatTranscript where Id = :testScript.Id];
        system.assert(case1.Id == testScript1.CaseId);
	}
    
    @IsTest(SeeAllData=true)
    public static void addLiveChatTranscripttoFeedItem(){
		
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;

        Contact con = TestDataProvider.createTestContact();
        insert con;
        
        Case case1 = new Case();
        case1.RecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'New';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.ContactId = con.Id;
        case1.ReferenceID__c = '123';
        case1.ChatKey__c = '8f441452-eb7d-6162-8ae6-5b3f4a44f7d0';
        insert case1;

        LiveChatTranscript testScript = new LiveChatTranscript();
        testScript.CaseId = case1.Id;
        testScript.ChatKey =  '8f441452-eb7d-6162-8ae6-5b3f4a44f7d0';
        testScript.Body = 'test123';
		testScript.Status = 'Completed';
        testScript.LiveChatVisitorid = lcv.id;
        insert testScript;
        
        List<LiveChatTranscript> lstLiveChatTrans = new List<LiveChatTranscript>();
        lstLiveChatTrans.add(testScript);
        
        Test.startTest();
        LiveChatTranscriptUtility.addLiveChatTranscripttoFeedItem(lstLiveChatTrans);
        Test.stopTest();        
    }
    
    @IsTest(SeeAllData=true)
    public static void AfterUpdateTestMethod(){
		
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;

        Contact con = TestDataProvider.createTestContact();
        insert con;
        
        Case case1 = new Case();
        case1.RecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'New';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.ContactId = con.Id;
        case1.ReferenceID__c = '123';
        case1.ChatKey__c = '8f441452-eb7d-6162-8ae6-5b3f4a44f7d0';
        insert case1;

        LiveChatTranscript testScript = new LiveChatTranscript();
        testScript.CaseId = case1.Id;
        testScript.ChatKey =  '8f441452-eb7d-6162-8ae6-5b3f4a44f7d0';
        testScript.Body = 'test123';
		testScript.Status = 'Completed';
        testScript.LiveChatVisitorid = lcv.id;
        insert testScript;
        
        List<LiveChatTranscript> lstLiveChatTrans = new List<LiveChatTranscript>();
        lstLiveChatTrans.add(testScript);
        
        Test.startTest();
		testScript.body = 'updating body to execute after update trigger';
        update testScript;
        Test.stopTest();        
    }
}