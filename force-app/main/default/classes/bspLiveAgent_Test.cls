/**
*  Test class for bspLiveAgent
*
@author Yuanyuan Zhang
@created 2014-07-15
@version 1.0
@since 29.0
*
@changelog
* 2014-07-15 Yuanyuan Zhang <yuanyuan.zhang@bluewolf.com>
* - Created
* - coverage 100%
*/
@isTest
private class bspLiveAgent_Test {
    @testSetup
	public static void testSetup(){

		Id deliveryEnquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StarTrack_PUD_Enquiry').getRecordTypeId();
		Id ssswGeneralRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSSWGeneralEnquiry').getRecordTypeId();
		Id ssswDeliveryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSSWDelivery').getRecordTypeId();

		CCUSettings__c setting = new CCUSettings__c(// startrack
		Exclude_case_types__c = 'LDC', StarTrackAsyncWebServiceTimeout__c = 10, BSPSyncConsignmentSearchTimeout__c = 5, Exclude_Case_Purpose__c = 'Controlled Returns', 

		// ap
		IncludedRecordTypes__c = 'SSSW%', EmailMsgKeyword__c = '%customerservice%', Max_Length_for_Consignment_Number__c = 40, Pickup_Booking_Ref_Number_Max_Length__c = 8, Pickup_Booking_Ref_Number_Min_Length__c = 7, DeliveryRecordTypeId__c = ssswDeliveryRecordTypeId, GeneralRecordTypeId__c = ssswGeneralRecordTypeId, APSyncWebServiceTimeout__c = 5, AusPostAsyncWebServiceTimeout__c = 10, UseContinuationforAPConsignSearch__c = true, DoNotShowFileNames__c = 'CN08-', APConsignmentSearchSourceSystemID__c = 'SFDC_BSP', 

		// general
		MaxEnquiryRecords__c = 500, EnquiriesPerPage__c = 15, BSPCaseStatusList__c = 'In Progress,Action Required,Resolved,Closed', CCUCommunityUserProfileId__c = [SELECT Id
		                                                                                                                                                            FROM Profile
		                                                                                                                                                            WHERE Name = 'BSP Community User'].Id, AdminCaseSubject__c = 'Enterprise Contact Registration');
		insert setting;

		//        Account defaultAcc = TestDataProvider.createAccount('Test Account', 1)[0];
		//        defaultAcc.Legacy_Id__c = '60000000';
		//        insert defaultAcc;

		Account testAccount = TestDataProvider.createAccount('Test Account', 1)[0];
		testAccount.Business_Solutions_Customer__c = true;
		testAccount.Transfer_Case_Queue__c = 'Sorry We Missed You';
		testAccount.ServiceSLA__c = 'Enterprise';
		Database.insert(testAccount);

		testAccount.Legacy_Id__c = '60000000';
		update testAccount;

		List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 4, new List<Account>{testAccount});
		testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
		testBillingAccList[0].LEGACY_ID__c = 'P123456';
		testBillingAccList[1].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
		testBillingAccList[1].LEGACY_ID__c = 'P223456';
		testBillingAccList[2].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
		testBillingAccList[2].LEGACY_ID__c = 'P323456';
		testBillingAccList[3].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
		testBillingAccList[3].LEGACY_ID__c = 'P423456';
		Database.insert(testBillingAccList);

		// create an article for each billing account
		// list<Billing_Account__c> not used lol
		List<Article__c> articles = TestDataProvider.createArticle('test subject', 4, new list<Billing_Account__c>());
		articles[0].Billing_Account__c = testBillingAccList[0].Id;
		articles[1].Billing_Account__c = testBillingAccList[1].Id;
		articles[2].Billing_Account__c = testBillingAccList[2].Id;
		articles[3].Billing_Account__c = testBillingAccList[3].Id;
		insert articles;

		Contact newCon = new Contact(FirstName = 'Nathan', LastName = 'Franklin', MobilePhone = '0400000000', Email = 'mytestemail@testingemails.com', BillingAccount__c = testBillingAccList[0].Id, AccountId = testAccount.Id, Status__c = 'Active');
		Database.insert(newCon);


		// BAM Specific functionality
		// creation of a product that is linked to the customer record to ensure BSP is enabled for the customer
		Product2 bspProduct = new Product2(Name = 'BSP');
		insert bspProduct;

		BAMApplication__c app = new BAMApplication__c(AppKey__c = 'BSP', ConfigurationModel__c = 'Per Customer', Product__c = bspProduct.Id, ServiceType__c = 'Salesforce', Status__c = 'Active');
		insert app;

		List<BAMApplicationRole__c> appRoles = new List<BAMApplicationRole__c>{new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'Super Admin', ShowOrganisation__c = true, Status__c = 'Active'), new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'Admin', ShowBillingAccount__c = true, ShowGroup__c = true, Status__c = 'Active'), new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'User', ShowBillingAccount__c = true, ShowGroup__c = true, Status__c = 'Active')};
		insert appRoles;

		// insert a group for the account
		BAMGroup__c grp = new BAMGroup__c(Organisation__c = testAccount.Id, Status__c = 'Active');
		insert grp;

		// connect some billing accounts to the BAM group so they can be surfaced in BSP
		List<BAMGroupBillingAccount__c> groupBillingAccounts = new List<BAMGroupBillingAccount__c>{new BAMGroupBillingAccount__c(Group__c = grp.Id, BillingAccount__c = testBillingAccList[0].Id), new BAMGroupBillingAccount__c(Group__c = grp.Id, BillingAccount__c = testBillingAccList[1].Id)};
		insert groupBillingAccounts;

		// add the BSP asset to the customer to ensure BSP is enabled
		Asset bspAsset = new Asset(Product2Id = bspProduct.Id, AccountId = testAccount.Id, Name = 'BSP', Status = 'Active');
		insert bspAsset;

		// create cases for verification
		List<Case> newCases = new List<Case>();

		// ST case
		Case newCase = new Case(Subject = 'Case 1', BSP_Addressee_Name__c = 'David 1', Related_Billing_Account__c = testBillingAccList[0].Id, AccountId = testAccount.Id, RecordTypeId = deliveryEnquiryRecordTypeId, Priority = 'High', Status = 'New');
		newCases.add(newCase);

		// ap case
		newCase = TestUtility.createCase('Enquiry', 'In Progress', 'General Enquiry', testAccount.Id, null, ssswDeliveryRecordTypeId);
		newCase.ProductCategory__c = 'Domestic Letters';
		newCase.Related_Billing_Account__c = testBillingAccList[1].Id;
		newCases.add(newCase);

		// st case
		newCases.add(new Case(Subject = 'Case 3', BSP_Addressee_Name__c = 'David 3', Related_Billing_Account__c = testBillingAccList[2].Id, AccountId = testAccount.Id, RecordTypeId = deliveryEnquiryRecordTypeId, Priority = 'Low', Status = 'New'));

		// ap case
		newCase = TestUtility.createCase('Enquiry', 'In Progress', 'General Enquiry', testAccount.Id, null, ssswDeliveryRecordTypeId);
		newCase.ProductCategory__c = 'Domestic Letters';
		newCase.Related_Billing_Account__c = testBillingAccList[3].Id;
		newCases.add(newCase);

		Database.insert(newCases);
	}
    
	static testmethod void tesbspLiveAgent () {
		test.startTest();
        //PageReference pageRef = Page.MpbHspEnquiry;
        //Test.setCurrentPage(pageRef);
        System.debug('URL--'+ApexPages.currentPage());
		bspLiveAgent bl = new bspLiveAgent();
		test.stopTest();
	}
    
    static testmethod void testConstructorFromValidPage() {
        test.startTest();
            PageReference pageRef = Page.MpbHspEnquiry;
            Test.setCurrentPage(pageRef);
			bspLiveAgent bl = new bspLiveAgent();
		test.stopTest();
    }
    
    static testmethod void testConstructorFromInvalidPage() {
        test.startTest();
            PageReference pageRef = Page.bspLiveChatWindowUplift;
            Test.setCurrentPage(pageRef);
			bspLiveAgent bl = new bspLiveAgent();
		test.stopTest();
    }

    static testmethod void testMiscellaneous() {
        test.startTest();
        	CCUSettings__c ccu = bspLiveAgent.getLiveAgetSettings();     	
            bspLiveAgent.hasAPBillingAccounts();       	
            //bspLiveAgent.hasSTBillingAccounts();
        test.stopTest();
    }
	private static Map<String, Billing_Account__c> mapBillingAccountsToNumber(List<Billing_Account__c> billingAccounts){
		Map<String, Billing_Account__c> output = new Map<String, Billing_Account__c>();
		for (Billing_Account__c billingAccount : billingAccounts){
			output.put(billingAccount.LEGACY_ID__c, billingAccount);
		}
		return output;
	}
}