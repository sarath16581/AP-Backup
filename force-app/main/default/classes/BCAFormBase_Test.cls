/**
* Created by avula.jansirani@auspost.com.au on 19/04/2021.
*/

@IsTest
public class BCAFormBase_Test {
    
    @testSetup static void setup() {
        // Create common test accounts
        List<Account> testAccts = new List<Account>();
        for(Integer i=0;i<2;i++) {
            testAccts.add(new Account(Name = 'TestAcct'+i));
        }
        insert testAccts;        
    }
    
    @IsTest
    private static void testCSSettings() {
        // =====================================
        // Data Preparation
        // =====================================
        BCA_Settings__c bcaSetting1 = new BCA_Settings__c();
        bcaSetting1.Name = BCAFormConstants.CREDIT_LIMIT_TIMES;
        bcaSetting1.Number_Value__c = 2;
        bcaSetting1.Boolean_Value__c = false;
        bcaSetting1.Text_Value__c = 'https://www.google.com';
        
        // =====================================
        // Stubbing
        // =====================================
        // N/A
        CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector)MockUtility.mockSelector(CustomsSettingsSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        
        // Database
        MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>)fflib_Match.anyObject()))
            .thenReturn(new Map<String, BCA_Settings__c>{
                BCAFormConstants.CREDIT_LIMIT_TIMES => bcaSetting1
                    });
        MockUtility.Mocks.stopStubbing();
        
        // =====================================
        // Testing
        // =====================================
        //insert bcaSetting;
        Test.startTest();
        BCAFormBase.getSummryTCDownloadURL();
        BCAFormBase.getMinimumCreditLimit();
        BCAFormBase.noOfTimesCreditLimit();
        BCAFormBase.getDirectDebitTCDownloadURL();
        BCAFormBase.getSummryPrivacyNoticeURL();
        System.assertEquals(2,  BCAFormBase.noOfTimesCreditLimit().get('noOfTimes'), 'success');
        
        Boolean underMaintenance = BCAFormBase.getIsUnderMaintenance();
        System.assertEquals(bcaSetting1.Boolean_Value__c, underMaintenance
                            , 'Under Maintenance setting incorrect, expected:' + bcaSetting1.Boolean_Value__c + ' got:' + underMaintenance);
        Test.stopTest();
        
    }
    
    @IsTest
    private static void testGetArticles()
    {
        // =====================================
        // Data Preparation
        // =====================================
        String testMessage = 'test message';
        Business_Credit_Account__kav ka = new Business_Credit_Account__kav();
        ka.Message__c = testMessage;
        
        // =====================================
        // Stubbing
        // =====================================
        // N/A
        KnowledgeArticleVersionsSelector kavSelector = (KnowledgeArticleVersionsSelector)MockUtility.mockSelector(KnowledgeArticleVersionsSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        
        // Database
        MockUtility.Mocks.when(kavSelector.selectByStatusLanguageType(fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString()))
            .thenReturn(new List<SObject>{ka});
        MockUtility.Mocks.stopStubbing();
        
        // =====================================
        // Testing
        // =====================================
        //insert bcaSetting;
        Test.startTest();
        System.assertEquals(ka, BCAFormBase.getWelcomeMessage(), 'Welcome failed');
        System.assertEquals(ka, BCAFormBase.getDirectTC(), 'Direct T&C failed');
        System.assertEquals(ka, BCAFormBase.getSummaryTC(), 'Summary T&C failed');
        //System.assertEquals(ka, BCAFormBase.getSummaryPrivacyContent(), 'Summary Privacy Content failed');
        
        Test.stopTest();
        
    }
    
    @IsTest
    private static void testWelcomeAndTCText() {
        // =====================================
        // Data Preparation
        // =====================================
        Business_Credit_Account__kav kv = new Business_Credit_Account__kav();
        kv.Message__c='Welcome Text';
        kv.Title='Welcome';
        kv.Type__c='Welcome';
        kv.Urlname='Welcomexxx';
        kv.language='en_US';
        insert kv;
        Business_Credit_Account__kav k = [Select KnowledgeArticleId from Business_Credit_Account__kav where ID = :kv.Id];
        KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);
        
        Test.startTest();
        BCAFormBase.getWelcomeMessage();
        System.assertEquals(kv.Message__c,  BCAFormBase.getWelcomeMessage().Message__c, 'success');
        Test.stopTest();
        
    }
    
    @IsTest
    private static void testDirectTC() {
        // =====================================
        // Data Preparation
        // =====================================
        Business_Credit_Account__kav kv = new Business_Credit_Account__kav();
        kv.Message__c='Terms and conditions...';
        kv.Title='TC Direct Debit';
        kv.Type__c='Direct Debit T&C';
        kv.Urlname='TC-Direct-Debit-xxx';
        kv.language='en_US';
        insert kv;
        Business_Credit_Account__kav k = [Select KnowledgeArticleId from Business_Credit_Account__kav where ID = :kv.Id];
        KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);
        Test.startTest();
        BCAFormBase.getDirectTC();
        System.assertEquals(kv.Message__c,  BCAFormBase.getDirectTC().Message__c, 'success');
        Test.stopTest();
        
    }
    
    
    @IsTest
    private static void testSummaryTC() {
        // =====================================
        // Data Preparation
        // =====================================
        Business_Credit_Account__kav kv = new Business_Credit_Account__kav();
        kv.Message__c='Summary TC';
        kv.Title='summary TC';
        kv.Type__c='Summary T&C';
        kv.Urlname='Summary-T-C-xxx';
        kv.language='en_US';
        insert kv;
        Business_Credit_Account__kav k = [Select KnowledgeArticleId from Business_Credit_Account__kav where ID = :kv.Id];
        KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);
        Test.startTest();
        BCAFormBase.getSummaryTC();
        System.assertEquals(kv.Message__c,  BCAFormBase.getSummaryTC().Message__c, 'success');
        Test.stopTest();
        
    }
    
    @IsTest
    private static void testAccountDuplicateCheck() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Account> accList = [SELECT Id,ABN__c FROM Account Limit 2 ];
        for(Account acc : accList){
            acc.ABN__c = '31061621832';
            
        }
        update accList;
        Test.startTest();
        Boolean isDuplicate = BCAFormBase.containDuplicateABNACN(accList, accList[0].Id);
        Test.stopTest();
        System.assertEquals(true, isDuplicate);
        
    }
    
    @IsTest
    private static void testGetIndustryDivisionValues() {
        // =====================================
        // Data Preparation
        // =====================================
        ANZSIC_code__c anzCode = new ANZSIC_code__c();
        anzCode.ANZSIC_Division__c = 'A Agriculture, Forestry and Fishing xxx';
        anzCode.Code_Description__c  = 'Apple & Pear Growing xxx';
        insert anzCode;
        Test.startTest();
        List<bspEnquiryUplift.SelectOptionCustom> option1List1= BCAFormBase.getIndustryDivisionValues();
        List<bspEnquiryUplift.SelectOptionCustom> option1List2= BCAFormBase.getObjectRecordFieldValues('ANZSIC_Code__c', 'Code_Description__c', 'WHERE ANZSIC_Division__c=\'A Agriculture, Forestry and Fishing xxx\'', false);
        System.assertEquals(1, option1List2.size(), 'success');
        System.assertEquals(1, option1List1.size(), 'success');
        Test.stopTest();
        
        
    }
    
    @IsTest
    private static void testForExistingBillingAccountUser() {
        Account testAccount = [SELECT Id,ABN__c FROM Account Limit 1];
        Billing_Account__c b = ApplicationTestDataFactory.getBillingAccounts(1,testAccount.Id, 'SAP ERP', false)[0];
        b.Type__c ='CUST';
        b.SAP_marked_for_deletion__c = false;
        // =====================================
        // Data Preparation
        // =====================================
        // create user
        
        Contact c = ApplicationTestDataFactory.getContacts(1, new Set<Id>{testAccount.Id}, false)[0];
        insert c;
        Id bcaProfileId = [SELECT Id from Profile WHERE Name='Mypost Business Help & Support Community User' Limit 1].Id;
        User bcaUser = new User(Alias = 'bcaUser', Email='user@testorg.a', ContactId = c.Id, EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = bcaProfileId, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
        
        Database.insert(bcaUser);
        
        Test.startTest();
        System.runAs(bcaUser){
            BCAFormBase.UserDetails uDetails = BCAFormBase.checkUserAccessToBCACreation(bcaUser.Id);
            System.debug('uDetails='+uDetails);
            System.assertEquals(uDetails.allowBCACreation, true, 'Success');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    private static void testForExistingCreditAssesment() {
        Account testAccount = [SELECT Id,ABN__c FROM Account Limit 1];
        
        APT_Credit_Assessment__c caRecord = new APT_Credit_Assessment__c();
        caRecord.APT_ABN__c = '11111111111';
        caRecord.APT_Email_Address__c = 'test@example.com';
        caRecord.APT_Credit_Assessment_Status__c=BCAFormConstants.CREDIT_ASSESSMENT_STATUS_WORK_IN_PROGRESS;
        caRecord.APT_Organisation_Name__c = testAccount.Id;
        caRecord.APT_Legal_Entity_Name__c = 'Text xxx';
        insert caRecord;
        
        Contact c = ApplicationTestDataFactory.getContacts(1, new Set<Id>{testAccount.Id}, false)[0];
        insert c;
        Id bcaProfileId = [SELECT Id from Profile WHERE Name='Mypost Business Help & Support Community User' Limit 1].Id;
        User bcaUser = new User(Alias = 'bcaUser', Email='user@testorg.a', ContactId = c.Id, EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = bcaProfileId, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
        
        Database.insert(bcaUser);
        
        Test.startTest();
        BCAFormBase.UserDetails uDetails = BCAFormBase.checkUserAccessToBCACreation(bcaUser.Id);
        Test.stopTest();
        
        System.assertEquals(uDetails.allowBCACreation, false, 'Success');
        
    }

    @IsTest
    private static void testValidateBSB()
    {
        // =====================================
        // Data Preparation
        // =====================================
        BSB__c bsb = new BSB__c();
        bsb.Name = '003048';

        // =====================================
        // Stubbing
        // =====================================
        // N/A
        CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector)MockUtility.mockSelector(CustomsSettingsSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();

        // Database
        MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>)fflib_Match.anyObject()))
                .thenReturn(new Map<String, BSB__c>{
                bsb.Name => bsb
        });
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        //insert bcaSetting;
        Test.startTest();
        BCAFormBase.BSB_Result result = BCAFormBase.validateBSB(bsb.Name);
        System.assertEquals(bsb.Name,  result.name, 'incorrect bsb result:' + result);
        Test.stopTest();

    }
    

	@IsTest
	private static void testCreditSuspectRegisterCheck() {

		// =====================================
        // Data Preparation
        // =====================================
        BCA_Settings__c bcaSetting1 = new BCA_Settings__c();
        bcaSetting1.Name = BCAFormConstants.BCASETTING_AUTO_APPROVAL_MAX_CREDIT_LIMIT;
        bcaSetting1.Number_Value__c = 10000;

		BCA_Settings__c bcaSetting2 = new BCA_Settings__c();
        bcaSetting2.Name = BCAFormConstants.BCASETTING_CREDIT_SUSPECT_MATCH_THRESHOLD;
        bcaSetting2.Number_Value__c = 0.6;

		final String FIND_DUPLICATES_RESULT = String.join(new String[] {
			'  [',
			'	{',
			'	  "duplicateResults": [',
			'		{',
			'		  "matchResults": [',
			'			{',
			'			  "entityType": "CreditSuspect__c",',
			'			  "matchRecords": [',
			'				{',
			'				  "matchConfidence": 83.0,',
			'				  "record": {',
			'					"attributes": {',
			'					  "type": "CreditSuspect__c",',
			'					  "url": "/services/data/v58.0/sobjects/CreditSuspect__c/aEg0k0000008OWwCAM"',
			'					},',
			'					"LastName__c": "First",',
			'					"Id": "aEg0k0000008OWwCAM",',
			'					"FirstName__c": "Last",',
			'					"Email__c": "first.last@auspost.com.au",',
			'					"Name": "K-00009"',
			'				  }',
			'				}',
			'			  ],',
			'			  "rule": "SuspectMatcher1",',
			'			  "size": 1,',
			'			  "success": true',
			'			}',
			'		  ]',
			'		}',
			'	  ],',
			'	  "errors": [],',
			'	  "success": true',
			'	}',
			'  ]'
		}, '\r\n');

		List<Datacloud.FindDuplicatesResult> mockedFindDuplicatesResult = (List<Datacloud.FindDuplicatesResult>)
			JSON.deserialize(
				FIND_DUPLICATES_RESULT,
				List<Datacloud.FindDuplicatesResult>.class
			);

		APT_Credit_Assessment__c creditAssessment = new APT_Credit_Assessment__c(
			Id = fflib_IDGenerator.generate(APT_Credit_Assessment__c.SObjectType),
			APT_Applicant_1_Last_Name__c = 'LastName1',
			APT_Applicant_1_First_Name__c = 'FirstName1',
			APT_Applicant_1_Telephone__c = '0400000000',
			APT_Applicant_1_Email_Address__c = 'first.last@auspost.com.au',
			APT_Applicant_1_Date_of_Birth__c = Date.newInstance(2010, 6, 5),
			APT_Applicant_1_Street_Name__c = 'StreetAddress',
			APT_Applicant_1_Suburb__c = 'Suburb',
			APT_Applicant_1_Postcode__c = '3000',
			APT_Applicant_1_State__c = 'VIC',
			Contact_First_Name__c = 'LastName2',
			Contact_Last_Name__c = 'FirstName2',
			APT_Telephone__c = '0400000000',
			APT_Email_Address__c = 'first.last@auspost.com.au'
		);

        // =====================================
        // Stubbing
        // =====================================
        // N/A
        CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector)MockUtility.mockSelector(CustomsSettingsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        
		// set up our responses
        MockUtility.Mocks.startStubbing();
        
        // Database
        MockUtility.Mocks.when(
			settingsSelector.selectByNames((Set<String>)fflib_Match.anyObject())
		).thenReturn(new Map<String, BCA_Settings__c>{
			BCAFormConstants.CREDIT_LIMIT_TIMES => bcaSetting1,
			BCAFormConstants.BCASETTING_CREDIT_SUSPECT_MATCH_THRESHOLD => bcaSetting2
		});
		
		MockUtility.Mocks.when(
			mockDatabase.findDuplicates((List<SObject>)fflib_Match.anyObject())
		).thenReturn(
			mockedFindDuplicatesResult
		);

		MockUtility.Mocks.stopStubbing();
        
        // =====================================
        // Testing
        // =====================================
        Test.startTest();

		Set<BCAFormHelper.AssessmentEntityType> matchingEntities = BCAFormHelper.performSuspectRegisterCheck(creditAssessment);

		System.assert(
			matchingEntities.contains(BCAFormHelper.AssessmentEntityType.MAIN_APPLICANT),
			'Expecting matching results for main applicant'
		);

		System.assert(
			matchingEntities.contains(BCAFormHelper.AssessmentEntityType.CONTACT),
			'Expecting matching results for contact'
		);
		
		Test.stopTest();		
	}
}