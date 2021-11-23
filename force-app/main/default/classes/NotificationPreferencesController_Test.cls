/***
 * @author Disha kariya
 * @date 2021-05-20
 * @group Tests
 * @description Test Scenarios for Notification Preferences Controller
 * @changelog
 */
@IsTest
public with sharing class NotificationPreferencesController_Test {
	
	@IsTest
	private static void testAPCNAttributes() {
		
		// =====================================
		// Data Preparation
		// =====================================
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.APCN__pc = '123456789';
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'PersonContactId' => personContact.Id});
		
		// =====================================
		// Stubbing
		// =====================================
		SSSWAccountsSelector mockAccountsSelector = (SSSWAccountsSelector)MockUtility.mockSelector(SSSWAccountsSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{personAccount.Id => personAccount});
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		Test.setCurrentPage(Page.NotificationPreferencesWrapper);
		
		ApexPages.StandardController standardController = new ApexPages.StandardController(personAccount);
		NotificationPreferencesController controller = new NotificationPreferencesController(standardController);
		
		System.assertNotEquals(0, controller.searchString.get('apcn').size(), 'APCN is not matched');
	
	}
	
	@IsTest
	private static void testOtherAttributes() {
		
		// =====================================
		// Data Preparation
		// =====================================
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.Email__c = 'test@test.com';
		personAccount.APCN__pc = '';
		personAccount.Phone = '000000';
		personAccount.VerifiedMobile__pc = '000000';
		personAccount.PersonMobilePhone = '000000';
		
//		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
//		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'PersonContactId' => personContact.Id});
		
		// =====================================
		// Stubbing
		// =====================================
		SSSWAccountsSelector mockAccountsSelector = (SSSWAccountsSelector)MockUtility.mockSelector(SSSWAccountsSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{personAccount.Id => personAccount});
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		Test.setCurrentPage(Page.NotificationPreferencesWrapper);
		
		ApexPages.StandardController standardController = new ApexPages.StandardController(personAccount);
		NotificationPreferencesController controller = new NotificationPreferencesController(standardController);
		String attributes = controller.attributes;
		System.assertNotEquals(0, controller.searchString.get('email').size(), 'Email not found');
		System.assertNotEquals(0, controller.searchString.get('phone').size(), 'Phone not found');
	
	}
}