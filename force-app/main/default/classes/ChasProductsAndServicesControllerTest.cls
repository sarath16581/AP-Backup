/**
 * @author Hasantha Liyanage
 * @date 2022-06-06
 * @group Chas
 * @tag productAndServices
 * @tag DDS-10974
 * @domain Help & Support
 * @description DDS-10974 Testing the create case functionality for product and services.
 * @changelog
 * 2022-06-06 - Hasantha Liyanage - Created
 * 2022-07-15 - Hasantha Liyanage - DDS-11324 added mocking basics as a part of refactor phase 2
 * 2023-06-07 - Talib Raza - REQ3209253: API version uplifted to v57.0
 */
@IsTest(IsParallel=true)
public with sharing class ChasProductsAndServicesControllerTest {
	private class TestData {
		Map<String, String> productAndSrvWizardData;
		Map<String, String> authUserData;
	}
	private static TestData gTestData;
	private static TestData wizardDataSetUp() {
		if (gTestData == null) {
			gTestData = new TestData();
			gTestData.productAndSrvWizardData = new Map<String, String>();
			gTestData.authUserData = new Map<String, String>();

			//-- Authenticateduser Data setup
			gTestData.authUserData.put('userContactEmail', 'useremail@gmail.com');
			gTestData.authUserData.put('userContactPhone', '21324235');
			gTestData.authUserData.put('userContactFirstName', 'UserFN');
			gTestData.authUserData.put('userContactLastName', 'UserLN');

			//--Product Issue wizardData setup
			gTestData.productAndSrvWizardData.put('selectedRadio1Name', 'Mail products');
			gTestData.productAndSrvWizardData.put('mailProductsEnquiryType', '24/7 Parcel Locker');
			gTestData.productAndSrvWizardData.put('transferTrackingNumber', '125367478855');
			gTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType', 'Other');
			gTestData.productAndSrvWizardData.put('orderNumber', '12345');
			gTestData.productAndSrvWizardData.put('orderTrackingNumber', '12345678');
			gTestData.productAndSrvWizardData.put('selectedRadio3Name', 'Bank@Post');
			gTestData.productAndSrvWizardData.put('selectedRadio2Name', 'Yes');
			gTestData.productAndSrvWizardData.put('deliveryAddressLine1', 'Add Line 1');
			gTestData.productAndSrvWizardData.put('deliveryAddressLine2', 'AddLine 2');
			gTestData.productAndSrvWizardData.put('deliveryCity', 'City');
			gTestData.productAndSrvWizardData.put('deliveryState', 'State');
			gTestData.productAndSrvWizardData.put('deliveryPostcode', '1234');

			gTestData.productAndSrvWizardData.put('enquiryDetails', 'complaintDetails');
		}

		return gTestData.clone();
	}

	@IsTest
	public static void productIssue_DeleteMyPostAccount() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'ID, documents & accounts');
			vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType', 'Delete MyPost account');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();


			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_DeleteMyPostAccount()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_MailProducts_24By7ParcelLocker() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_MailProducts_24By7ParcelLocker()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}
	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_MailProducts_ExpressPost() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('mailProductsEnquiryType', 'Express Post');
			//-- more than 255 chars of issue details text
			vTestData.productAndSrvWizardData.put(
				'enquiryDetails',
				'complaintDetails complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails ' +
				'complaintDetails complaintDetails complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails' +
				'complaintDetails complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails complaintDetails ' +
				'complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails complaintDetails complaintDetails' +
				'complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails'
			);

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

            Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_MailProducts_ExpressPost()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_MailProducts_Letter() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('mailProductsEnquiryType', 'Letter');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

            Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_MailProducts_Letter()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}
	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_MailProducts_Parcel() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('mailProductsEnquiryType', 'Parcel');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

            Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_MailProducts_Parcel()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}
	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_MailProducts_ParcelCollect() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('mailProductsEnquiryType', 'Parcel Collect');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

            Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_MailProducts_ParcelCollect()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_MailProducts_POBoxAndPrivateBag() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('mailProductsEnquiryType', 'PO Box and Private Bag');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

            Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_MailProducts_POBoxAndPrivateBag()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_MailProducts_Tracking() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('mailProductsEnquiryType', 'Tracking');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

            Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_MailProducts_Tracking()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_MailProducts_Transfer() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('mailProductsEnquiryType', 'Transfer');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

            Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_MailProducts_Transfer()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_PostOffice() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'Post office');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();
            Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_PostOffice()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_IdDocuments() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'ID, documents & accounts');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

            Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_IdDocuments()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_IdDocuments_Idheck() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'ID, documents & accounts');
			vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType', 'ID check');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

            Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_IdDocuments_Idheck()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_IdDocuments_LandTitle() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'ID, documents & accounts');
			vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType', 'Land title');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_IdDocuments_LandTitle()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}
	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_IdDocuments_Letter() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'ID, documents & accounts');
			vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType', 'Letter');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_IdDocuments_Letter()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_IdDocuments_MyPost() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'ID, documents & accounts');
			vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType', 'MyPost');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_IdDocuments_MyPost()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_IdDocuments_Passport() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'ID, documents & accounts');
			vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType', 'Passport');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_IdDocuments_Passport()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_IdDocuments_PoliceCheck() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'ID, documents & accounts');
			vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType', 'Police check');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

            Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_IdDocuments_PoliceCheck()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}
	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_IdDocuments_TFN() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'ID, documents & accounts');
			vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType', 'Tax file number (TFN)');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_IdDocuments_TFN()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_IdDocuments_Other() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'ID, documents & accounts');
			vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType', 'Other');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_IdDocuments_Other()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_OnlineShop() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'Online shop');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_OnlineShop()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_Money_BankPost() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'Money');
			vTestData.productAndSrvWizardData.put('selectedRadio3Name', 'Bank@Post');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_Money_BankPost()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Success Case for : Procu Issue
	 * */
	@IsTest
	public static void productIssue_Money_PostBillPay() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'Money');
			vTestData.productAndSrvWizardData.put('selectedRadio3Name', 'Post Billpay');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_Money_PostBillPay()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assert(isSuccess);
	}

	/**
	 * Accessibility and disability - when Post office is selected
	 */
	@IsTest
	public static void productIssue_Accessibility_PostOffice() {
        Boolean isSuccess = true;

        try {

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'Money');
            vTestData.productAndSrvWizardData.put('accessibilityIssueTypeName', 'Post Office');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

            Test.startTest();
            ChasBase.CaseWrapper caseWrapper = ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

        } catch (Exception e) {
            System.debug('productIssue_Money_PostBillPay()::error==>' + e.getMessage());
            System.debug('productIssue_Money_PostBillPay()::error==>' + e.getStackTraceString());
            isSuccess = false;
        }
		System.assertEquals(isSuccess, true, 'Case should be created for Accessibility and disability - Post Office');
	}

	/**
	 * Accessibility and disability - when Delivery is selected
	 */
	@IsTest
	public static void productIssue_Accessibility_Delivery() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'Accessibility and disability');
			vTestData.productAndSrvWizardData.put('accessibilityIssueTypeName', 'Delivery');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

			Test.startTest();
			ChasBase.CaseWrapper caseWrapper = ChasProductsAndServicesController.createCaseFromProductsAndServices(
				vTestData.productAndSrvWizardData,
				vTestData.authUserData
			);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_Accessibility_Delivery()::error==>' + e.getMessage());
			System.debug('productIssue_Accessibility_Delivery()::error==>' + e.getStackTraceString());
			isSuccess = false;
		}

		System.assertEquals(isSuccess, true, 'Case should be created for Accessibility and disability - Delivery');
	}

	/**
	 * Accessibility and disability - when Website or app is selected
	 */
	@IsTest
	public static void productIssue_Accessibility_WebsiteOrApp() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'Accessibility and disability');
			vTestData.productAndSrvWizardData.put('accessibilityIssueTypeName', 'Website or app');

            // mocking and stubbing common data
			ApplicationDatabase mockDatabase = mockTestData();

			Test.startTest();
			ChasBase.CaseWrapper caseWrapper = ChasProductsAndServicesController.createCaseFromProductsAndServices(
				vTestData.productAndSrvWizardData,
				vTestData.authUserData
			);
			Test.stopTest();

            ((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) fflib_Match.anyObject());

		} catch (Exception e) {
			System.debug('productIssue_Accessibility_WebsiteOrApp()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assertEquals(isSuccess, true, 'Case should be created for Accessibility and disability - Website or app');
	}

	/**
	 * Accessibility and disability - generate comments when Website or app is selected
	 */
	@IsTest
	public static void productIssue_Accessibility_Case_Comments_WebsiteOrApp() {
		Boolean isSuccess = true;

		try {
			Map<String, String> web = new Map<String, String>{
				'accessibilityIssueTypeName' => 'Website or app',
				'selectedAssistiveTypeName' => 'assis type ',
				'accessibilityVisualOption' => 'false',
				'accessibilityOtherOption' => 'true',
				'accessibilitySeizuresOption' => 'true',
				'accessibilityOtherReason' => 'something for test'
			};

			Test.startTest();
			String comment = ChasProductsAndServicesController.getAccessibilityComments(web);
			system.debug('comment');
			system.debug(comment);
			Test.stopTest();

			System.assertEquals(
				comment.containsIgnoreCase('Issue Category - Website or app'),
				true,
				'productIssue_Accessibility_Case_Comments_WebsiteOrApp : invalid comments content'
			);
		} catch (Exception e) {
			System.debug('productIssue_Accessibility_Case_Comments_WebsiteOrApp()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assertEquals(isSuccess, true, 'productIssue_Accessibility_Case_Comments_WebsiteOrApp');
	}

	/**
	 * Accessibility and disability - generate comments when Delivery is selected
	 */
	@IsTest
	public static void productIssue_Accessibility_Case_Comments_Delivery() {
		Boolean isSuccess = true;

		try {
			Map<String, String> web = new Map<String, String>{
				'accessibilityIssueTypeName' => 'Delivery',
				'selectedAssistiveTypeName' => 'assis type ',
				'accessibilityVisualOption' => 'false',
				'accessibilityOtherOption' => 'true',
				'accessibilitySeizuresOption' => 'true',
				'accessibilityOtherReason' => 'something for test'
			};

			Test.startTest();
			String comment = ChasProductsAndServicesController.getAccessibilityComments(web);
			system.debug('comment');
			system.debug(comment);
			Test.stopTest();

			System.assertEquals(
				comment.containsIgnoreCase('Issue Category - Delivery'),
				true,
				'productIssue_Accessibility_Case_Comments_Delivery : invalid comments content'
			);
		} catch (Exception e) {
			System.debug('productIssue_Accessibility_Case_Comments_Delivery()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assertEquals(isSuccess, true, 'productIssue_Accessibility_Case_Comments_Delivery');
	}

	/**
	 * Accessibility and disability - generate comments when Post Office is selected
	 */
	@IsTest
	public static void productIssue_Accessibility_Case_Comments_PostOffice() {
		Boolean isSuccess = true;

		try {
			Map<String, String> web = new Map<String, String>{
				'accessibilityIssueTypeName' => 'Post Office',
				'selectedAssistiveTypeName' => 'assis type ',
				'accessibilityVisualOption' => 'false',
				'accessibilityOtherOption' => 'true',
				'accessibilitySeizuresOption' => 'true',
				'accessibilityOtherReason' => 'something for test'
			};

			Test.startTest();
			String comment = ChasProductsAndServicesController.getAccessibilityComments(web);
			system.debug('comment');
			system.debug(comment);
			Test.stopTest();

			System.assertEquals(
				comment.containsIgnoreCase('Issue Category - Post Office'),
				true,
				'productIssue_Accessibility_Case_Comments_PostOffice : invalid comments content'
			);
		} catch (Exception e) {
			System.debug('productIssue_Accessibility_Case_Comments_PostOffice()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assertEquals(isSuccess, true, 'productIssue_Accessibility_Case_Comments_Delivery');
	}

	/**
	 * Accessibility and disability - generate comments when Other issue type is selected
	 */
	@IsTest
	public static void productIssue_Accessibility_Case_Comments_OtherIssueType() {
		Boolean isSuccess = true;

		try {
			Map<String, String> web = new Map<String, String>{
				'accessibilityIssueTypeName' => 'Other issue type',
				'selectedAssistiveTypeName' => 'assis type ',
				'accessibilityVisualOption' => 'false',
				'accessibilityOtherOption' => 'true',
				'accessibilitySeizuresOption' => 'true',
				'accessibilityOtherReason' => 'something for test'
			};

			Test.startTest();
			String comment = ChasProductsAndServicesController.getAccessibilityComments(web);
			system.debug('comment');
			system.debug(comment);
			Test.stopTest();

			System.assertEquals(
				comment.containsIgnoreCase('Issue Category - Other issue type'),
				true,
				'productIssue_Accessibility_Case_Comments_OtherIssueType : invalid comments content'
			);
		} catch (Exception e) {
			System.debug('productIssue_Accessibility_Case_Comments_OtherIssueType()::error==>' + e.getMessage());
			isSuccess = false;
		}
		System.assertEquals(isSuccess, true, 'productIssue_Accessibility_Case_Comments_OtherIssueType');
	}

	/**
	 * Keeping the mocking related common stubbing in a one place
     * @return mockDatabase to be used for verification
     */
    private static ApplicationDatabase mockTestData() {
        // =====================================
        // Data Preparation
        // =====================================
        Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
        Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
        personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'PersonContactId' => personContact.Id});
        ProfilesSelector profilesSelector = ProfilesSelector.newInstance(1);
        Id profileID = profilesSelector.selectByName(new Set<String>{'Consumer Help and Support Profile'}).values()[0].Id;

        User user = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{personContact.Id} ,profileID,true)[0];
        user = (User)ApplicationTestDataFactory.setUnwritableFields(user, new Map<String, Object>{'ContactId' => personContact.Id});

        Case caseRecord = ApplicationTestDataFactory.getCases(1, true)[0];
        caseRecord = (Case)ApplicationTestDataFactory.setUnwritableFields(caseRecord, new Map<String, Object>{'CaseNumber' => '1002938'});

        // =====================================
        // Stubbing
        // =====================================

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
        UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
        ContactsSelector mockContactsSelector = (ContactsSelector)MockUtility.mockSelector(ContactsSelector.class);
        AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockUsersSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>{user.Id => user});
        MockUtility.Mocks.when(mockAccountsSelector.selectById(new Set<Id>{personAccount.Id})).thenReturn(new Map<Id, Account>{personAccount.Id => personAccount});
        MockUtility.Mocks.when(mockContactsSelector.selectById(new Set<Id>{personContact.Id})).thenReturn(new Map<Id, Contact>{personContact.Id => personContact});
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());

        MockUtility.Mocks.stopStubbing();
        return mockDatabase;
    }
}