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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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
	public static void productIssue_MailProducts_24By7ParcelLocker() {
		Boolean isSuccess = true;

		try {
			TestData vTestData = wizardDataSetUp();

			// vTestData.productAndSrvWizardData.put('selectedRadio1Name','Item not left in a safe location');
			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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
			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			Test.startTest();
			ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
			Test.stopTest();
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

			vTestData.productAndSrvWizardData.put('selectedRadio1Name', 'Accessibility and disability');
			vTestData.productAndSrvWizardData.put('accessibilityIssueTypeName', 'Post Office');

			Test.startTest();
			ChasBase.CaseWrapper caseWrapper = ChasProductsAndServicesController.createCaseFromProductsAndServices(
				vTestData.productAndSrvWizardData,
				vTestData.authUserData
			);
			Test.stopTest();
		} catch (Exception e) {
			System.debug('productIssue_Accessibility_PostOffice()::error==>' + e.getMessage());
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

			Test.startTest();
			ChasBase.CaseWrapper caseWrapper = ChasProductsAndServicesController.createCaseFromProductsAndServices(
				vTestData.productAndSrvWizardData,
				vTestData.authUserData
			);
			Test.stopTest();
		} catch (Exception e) {
			System.debug('productIssue_Accessibility_Delivery()::error==>' + e.getMessage());
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

			Test.startTest();
			ChasBase.CaseWrapper caseWrapper = ChasProductsAndServicesController.createCaseFromProductsAndServices(
				vTestData.productAndSrvWizardData,
				vTestData.authUserData
			);
			Test.stopTest();
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
}