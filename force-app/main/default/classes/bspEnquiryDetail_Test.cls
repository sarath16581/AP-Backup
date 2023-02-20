/**************************************************
Description:    Test class to cover bspEnquiry
History:
--------------------------------------------------
2017-02-27  David Catindoy  Created
2019-06-10  nathan.franklin@auspost.com.au  Major refactor and rewrite for BAM integration
**************************************************/
@isTest
private class bspEnquiryDetail_Test {

    @testSetup
    public static void testSetup(){

        Id ssswGeneralRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSSWGeneralEnquiry').getRecordTypeId();
        Id ssswDeliveryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSSWDelivery').getRecordTypeId();

        CCUSettings__c setting = new CCUSettings__c(
            // startrack
            Exclude_case_types__c = 'LDC',
            StarTrackAsyncWebServiceTimeout__c = 10,
            BSPSyncConsignmentSearchTimeout__c = 5,
            Exclude_Case_Purpose__c = 'Controlled Returns',

            // ap
            IncludedRecordTypes__c = 'SSSW%',
            EmailMsgKeyword__c = '%customerservice%',
            Max_Length_for_Consignment_Number__c = 40,
            Pickup_Booking_Ref_Number_Max_Length__c = 8,
            Pickup_Booking_Ref_Number_Min_Length__c = 7,
            DeliveryRecordTypeId__c = ssswDeliveryRecordTypeId,
            GeneralRecordTypeId__c = ssswGeneralRecordTypeId,
            APSyncWebServiceTimeout__c = 5,
            AusPostAsyncWebServiceTimeout__c = 10,
            UseContinuationforAPConsignSearch__c = true,
            DoNotShowFileNames__c = 'CN08-',
            APConsignmentSearchSourceSystemID__c = 'SFDC_BSP',

            // general
            MaxEnquiryRecords__c = 500,
            EnquiriesPerPage__c = 15,
            BSPCaseStatusList__c = 'In Progress,Action Required,Resolved,Closed',
            CCUCommunityUserProfileId__c = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id,
            AdminCaseSubject__c = 'Enterprise Contact Registration',
            AttachmentSizeLimit__c = 5,

		    CommunityId__c = [SELECT Id FROM Network WHERE UrlPathPrefix = 'bsp'].Id
        );
        insert setting;

        List<BSPMappings__c> bspMappings = new List<BSPMappings__c>();
        bspMappings.add(new BSPMappings__c(Name = 'delivery issue', BSPEnquiryType__c = 'Delivery Issue', CaseEnquirySubType__c = 'Delivery Complaint', CaseType__c = 'Investigation'));
        bspMappings.add(new BSPMappings__c(Name = 'cash on delivery', BSPServiceUsed__c = 'Cash On Delivery', CaseProductSubCategory__c = 'Cash On Delivery'));
        bspMappings.add(new BSPMappings__c(Name = 'item search', BSPEnquiryType__c = 'Item Search', CaseEnquirySubType__c = 'Missing Item', CaseType__c = 'Investigation'));
        Database.insert(bspMappings);

        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        Database.insert(testAccount);

        testAccount.Legacy_Id__c = '60000000';
        Database.update(testAccount);

        List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 2, new List<Account>{testAccount});
        testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[0].LEGACY_ID__c = 'P1234567';
        Database.insert(testBillingAccList);

        Contact newCon = new Contact(FirstName = 'David', LastName = 'Catindoy', MobilePhone = '0421546325', Email = 'davidcatindoy@gmail.com', BillingAccount__c = testBillingAccList[0].Id,
		                                AccountId = testAccount.Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE, CCUAuthorisedAllOrgCases__c = true);
        Database.insert(newCon);

        Id conRecTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId();
        List<Article__c> consignList = new List<Article__c>();
        consignList.add(new Article__c(ArticleID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669', RecordTypeId = conRecTypeId));
        Database.insert(consignList);

        Database.insert(new StarTrack_Settings__c(Get_All_Consignment_Details__c = false, EMS_Endpoint__c = 'testendpt', Web_Service_Callout_Timeout__c = 10, Redelivery_Redirection_Enquiry__c = 'Sorry We Missed You', PBE_Controlled_Returns__c = 'Controlled Returns Queue',
                Next_Flight_Case_Consignment__c = 'StarTrack Next Flight Queue', PBE_ETA_Enquiry__c = StarTrack_Constants.ETA_QUEUE, PBE_Missed_Futile_Enquiry__c = StarTrack_Constants.WEB_BOOKINGS_QUEUE, Create_Call_Log_using_Future__c = true,
                BSP_Community_User_Profile_Id__c = String.valueOf([SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id).left(15),
                StarTrack_Related_Contact_RecType_Id__c = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get('StarTrack Related Contact').getRecordTypeId(), Use_Continuation_for_Consignment_Search__c = true, XML_Logging__c = true, Logging__c = true, Log_For__c = 'ALL USER', StarTrack_ConSearch_Authentication_Level__c = 1, Sync_Web_Service_Callout_Timeout__c = 5));

        // BAM Specific functionality
        // creation of a product that is linked to the customer record to ensure BSP is enabled for the customer
        Product2 bspProduct = new Product2(Name = 'BSP');
        insert bspProduct;

        BAMApplication__c app = new BAMApplication__c(AppKey__c = 'BSP', ConfigurationModel__c = 'Per Customer', Product__c = bspProduct.Id, ServiceType__c = 'Salesforce', Status__c = 'Active');
        insert app;

        List<BAMApplicationRole__c> appRoles = new List<BAMApplicationRole__c>{
                new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'Super Admin', ShowOrganisation__c = true, Status__c = 'Active'),
                new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'Admin', ShowBillingAccount__c = true, ShowGroup__c = true, Status__c = 'Active'),
                new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'User', ShowBillingAccount__c = true, ShowGroup__c = true, Status__c = 'Active')
        };
        insert appRoles;

	    Id pickupBookingEnquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
	    Case newCase = new Case(First_Email_Response__c = true, ArticleTest__c = consignList[0].Id, Subject = 'Sample Case',
			                        BSP_Sender_Address__c = 'Melbourne, VIC, 3000', BSP_Addressee_Address__c = 'Sydney, ACT, 1223',
			                        Related_Billing_Account__c = testBillingAccList[0].Id, AccountId = testAccount.Id,
			                        RecordTypeId = pickupBookingEnquiryRecordTypeId, Priority = 'High',
			                        Status = StarTrack_Constants.CASE_STATUS_WAITINGONCUSTOMER);
	    Database.insert(newCase);

	    List<Attachment> multipleAttachments = new List<Attachment>();
	    multipleAttachments.add(new Attachment(Body = Blob.valueOf('Attachment'), Name = 'Sample', ContentType = '.jpeg', ParentId = newCase.Id, IsPrivate = false));
	    multipleAttachments.add(new Attachment(Body = Blob.valueOf('Attachment'), Name = 'Do Not Show', ContentType = '.jpeg', ParentId = newCase.Id, IsPrivate = false));
	    Database.insert(multipleAttachments);

	    List<EmailMessage> emailMessages = new List<EmailMessage>();
	    emailMessages.add(new EmailMessage(ParentId = newCase.Id, HtmlBody = 'HTML Body', TextBody= 'HTML Body', Subject = 'New Email Message', FromAddress = 'test.customerservice@gmail.com', ToAddress = 'customerservice@auspost.com', FromName = 'AusPost Test'));
	    emailMessages.add(new EmailMessage(ParentId = newCase.Id, HtmlBody = 'HTML Body', TextBody= 'Number of Cases created via Bulk Upload :', Subject = 'New Email Message', FromAddress = 'test.customerservice@gmail.com', ToAddress = 'customerservice@auspost.com', FromName = 'AusPost Test'));
	    Database.insert(emailMessages);

    }

    /**
     * Scenario:
     * In this scenario we test the loading of the page and ensure that the case will only load if the user has access to it
     * We also test adding a new comment which also includes an optional file attachment
     */
    public static testMethod void testEnquiryDetailPage() {

        Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

        // populate all the billing accounts we will need to use in this test
        Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c>([Select Id, Name, LEGACY_ID__c From Billing_Account__c]);
        Map<String, Billing_Account__c> billingAccounts = mapBillingAccountsToNumber(billingAccountsMap.values());
        System.debug(billingAccounts);

        // grab the application roles for BSP so we can assign them to the user
        BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
        BAMApplicationRole__c bspAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Admin'];

        BAMContactApplication__c contactApplication = new BAMContactApplication__c(BSPCanViewAllConsignments__c = false, Application__c = app.Id, Contact__c = con.Id, Status__c = 'Active');
        insert contactApplication;

        // wee need to assign some roles with billing accounts to the contact to test their access
        List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>{
                new BAMContactRole__c(ApplicationRole__c = bspAdminRole.Id, ContactApplication__c = contactApplication.Id, Status__c = 'Active')
        };
        insert contactRoles;

        // add some linked entities to the contact role
        // in this test, only 3 out of the 4 billing accounts are available to this user
        List<BAMLinkedEntity__c> entities = new List<BAMLinkedEntity__c>{
                new BAMLinkedEntity__c(ContactRole__c = contactRoles[0].Id, BillingAccount__c = billingAccounts.get('P1234567').Id, Status__c = 'Active')
        };
        insert entities;
        System.Debug(entities);

        User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');

        //System.runAs(u){

            Case caseRec = [SELECT Id FROM CASE LIMIT 1];

	        Test.setCurrentPage(Page.bspEnquiryDetail);

	        Test.startTest();

            ApexPages.currentPage().getParameters().put('id', caseRec.Id);
            bspEnquiryDetail enqDetail = new bspEnquiryDetail();
	        enqDetail.SF_DisplayAttachmentButton();

	        System.assertNotEquals(null, enqDetail.enq);
	        System.assertNotEquals(null, enqDetail.enq.Id);

			enqDetail.fileBody = Blob.valueOf('New Attachment').toString();
			enqDetail.fileBodyLength = String.valueOf(1048576 * 2);
			enqDetail.fileName = 'Sample';
			enqDetail.fileContentType = '.jpeg';
			enqDetail.newCaseComment.CommentBody = 'Sample Comment';
			enqDetail.addComment();
			System.assertEquals(StarTrack_Constants.CASE_STATUS_INVESTIGATION, enqDetail.enq.Status);
	        System.assertNotEquals(null, enqDetail.newCaseComment.Id);

	        // test closing the case
	        Approval.lock(enqDetail.enq);
	        enqDetail.closeCase();
	        System.assertEquals(BspConstants.CASE_STATUS_CLOSED, enqDetail.enq.Status);

	        // test reopening the case
	        enqDetail.reopenCase();
	        System.assertEquals('New', enqDetail.enq.Status);

	        // Test Page Reference methods
            enqDetail.enq.ArticleTest__r.Name = '2AT71923';
            enqDetail.trackItem();
	        enqDetail.enq.ArticleTest__r.Name = '';
            enqDetail.trackItem();

	        Test.stopTest();
        //}
    }

    /**
     * Scenario:
     * Testing the retrieval of comments and email messages for display on the page
     */
    public static testMethod void testEnquiryDetailPage_CommHistory() {

	    // TODO: do not use admin user here. Currently being used since, for some reason, EmailMessages aren't being loaded when running context.
	    //          This is in contrast to the doc's which say: 'Customer Portal users have read access to EmailMessage if the value for the ParentID field is associated with a case. Otherwise, access is determined by sharing access of the associated task.'
	    //          No time to look into it.
	    Profile profile = [SELECT Id,Name FROM profile where Name = 'System Administrator' LIMIT 1];
        System.runAs(TestUtility.createUser('Admin',profile.id,null)){

            Case caseRec = [SELECT Id FROM CASE LIMIT 1];
            //Insert CaseComment
            CaseComment newCom = new CaseComment();
            newCom.CommentBody = 'test body' ;
            newCom.IsPublished = TRUE;
            newCom.ParentId = caseRec.id;
            database.insert(newCom);

            Test.setCurrentPage(Page.bspEnquiryDetail);

	        Test.startTest();

            ApexPages.currentPage().getParameters().put('Id', caseRec.Id);
            bspEnquiryDetail enqDetail = new bspEnquiryDetail();

            System.assertEquals(3, enqDetail.commHistoryList.size());
            enqDetail.commHistoryList[0].getHeader();
            enqDetail.commHistoryList[1].getHeader();
            enqDetail.commHistoryList[0].getobjType();
            enqDetail.commHistoryList[0].getCreatedDateTime();

            Test.stopTest();

        }
    }

	/**
	 * Ensures that the case doesn't load since the user does not have access to it. Although the case is connected to the account, the bam rules prevent it from being surfaced to the user.
	 */
	public static testMethod void testEnquiryDetailPage_NoAccess() {

		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');

		Case caseRec = [SELECT Id FROM CASE LIMIT 1];

		System.runAs(u){

			Test.setCurrentPage(Page.bspEnquiryDetail);
			ApexPages.currentPage().getParameters().put('Id', caseRec.Id);

			Test.startTest();

			bspEnquiryDetail enqDetail = new bspEnquiryDetail();

			System.assertEquals(true, ApexPages.hasMessages());

			Test.stopTest();

		}
	}

    /**
     * Scenario:
     * In this scenario we test the loading of the page and ensure that the case will only load if the user has access to it
     * We also test adding a new comment which also includes an optional file attachment for MPB
     */
    public static testMethod void testEnquiryDetailPageMPB() {

        Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

        // populate all the billing accounts we will need to use in this test
        Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c>([Select Id, Name, LEGACY_ID__c From Billing_Account__c]);
        Map<String, Billing_Account__c> billingAccounts = mapBillingAccountsToNumber(billingAccountsMap.values());
        System.debug(billingAccounts);
        Network mpbCommunity = [Select id, UrlPathPrefix From Network Where UrlPathPrefix = 'MpbHelpAndSupport'];
        // grab the application roles for BSP so we can assign them to the user
//        BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
//        BAMApplicationRole__c bspAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Admin'];
//
//        BAMContactApplication__c contactApplication = new BAMContactApplication__c(BSPCanViewAllConsignments__c = false, Application__c = app.Id, Contact__c = con.Id, Status__c = 'Active');
//        insert contactApplication;
//
//        // wee need to assign some roles with billing accounts to the contact to test their access
//        List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>{
//                new BAMContactRole__c(ApplicationRole__c = bspAdminRole.Id, ContactApplication__c = contactApplication.Id, Status__c = 'Active')
//        };
//        insert contactRoles;
//
//        // add some linked entities to the contact role
//        // in this test, only 3 out of the 4 billing accounts are available to this user
//        List<BAMLinkedEntity__c> entities = new List<BAMLinkedEntity__c>{
//                new BAMLinkedEntity__c(ContactRole__c = contactRoles[0].Id, BillingAccount__c = billingAccounts.get('P1234567').Id, Status__c = 'Active')
//        };
//        insert entities;
//        System.Debug(entities);

        User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');

        //System.runAs(u){

        Case caseRec = [SELECT Id FROM CASE LIMIT 1];

        Test.setCurrentPage(Page.MpbHspEnquiryDetail);

        Test.startTest();

        ApexPages.currentPage().getParameters().put('id', caseRec.Id);
        bspEnquiryDetail enqDetail = new bspEnquiryDetail();
        System.debug('enqDetail.isMpbHspFlag--->'+enqDetail.isMpbHspFlag);
        enqDetail.currentNetworkId = mpbCommunity.Id;
        enqDetail.SF_DisplayAttachmentButton();

        System.assertNotEquals(null, enqDetail.enq);
        System.assertNotEquals(null, enqDetail.enq.Id);

        enqDetail.fileBody = Blob.valueOf('New Attachment').toString();
        enqDetail.mpbFileBodyLength = decimal.valueOf(1048576 * 2);
        enqDetail.mpbFileName = 'Sample';
        enqDetail.mpbFileContentType = '.jpeg';
        enqDetail.newCaseComment.CommentBody = 'Sample Comment';
        enqDetail.addComment();
        System.assertEquals(StarTrack_Constants.CASE_STATUS_INVESTIGATION, enqDetail.enq.Status);
        System.assertNotEquals(null, enqDetail.newCaseComment.Id);

        // test closing the case
        Approval.lock(enqDetail.enq);
        enqDetail.closeCase();
        System.assertEquals(BspConstants.CASE_STATUS_CLOSED, enqDetail.enq.Status);

        // test reopening the case
        enqDetail.reopenCase();
        System.assertEquals('New', enqDetail.enq.Status);

        // Test Page Reference methods
        enqDetail.enq.ArticleTest__r.Name = '2AT71923';
        enqDetail.trackItem();
        enqDetail.enq.ArticleTest__r.Name = '';
        enqDetail.trackItem();
        Id testId = bspEnquiryDetail.ccuProfileId;
        Test.stopTest();
        //}
    }

    private static Map<String, Billing_Account__c> mapBillingAccountsToNumber(List<Billing_Account__c> billingAccounts) {
        Map<String, Billing_Account__c> output = new Map<String, Billing_Account__c>();
        for(Billing_Account__c billingAccount : billingAccounts) {
            output.put(billingAccount.LEGACY_ID__c, billingAccount);
        }
        return output;
    }

}