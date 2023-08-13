/**
 * @description Test class for covering MerchantPortalRegHandlerService
 * @author Mahesh Parvathaneni
 * @date 2023-08-08
 * @changelog
*/

@IsTest
private with sharing class MerchantPortalRegHandlerService_Test {

	/**
	 * Scenario:
	 * Makes sure that augmented attributes are populated from the attribute map
	 */
	@IsTest
	private static void testGetAugmentedAttributes() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		Auth.UserData userData = getUserData(contacts[0], user);
		String cNumber = userData.attributeMap.get('https://auspost/cnumber');
		String fedId = cNumber + '.merchant';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MerchantPortalRegHandlerService service = MerchantPortalRegHandlerService.getInstance();
		Map<String, String> augmentedAttributes = service.getAugmentedAttributes(userData.attributeMap);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		System.assertEquals(true, augmentedAttributes.containsKey('federation_identifier'), 'Expected federation_identifier attribute in augmentedAttributes');
		System.assertEquals(true, augmentedAttributes.containsKey('cnumber'), 'Expected cnumber attribute in augmentedAttributes');
		System.assertEquals(augmentedAttributes.get('federation_identifier'), fedId, 'Incorrect federation_identifier attribute returned');
		System.assertEquals(augmentedAttributes.get('cnumber'), cNumber, 'Incorrect cnumber attribute returned');
	}

	/**
	 * Scenario:
	 * Makes sure that attributes are populated for reg handler to match the user
	 */
	@IsTest
	private static void testValidateAssertion() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		Auth.UserData userData = getUserData(contacts[0], user);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MerchantPortalRegHandlerService service = MerchantPortalRegHandlerService.getInstance();
		List<String> validationErrors = service.validateAssertion(new Map<String, String>{ 'test_key' => 'test_value' });

		// =====================================
		// VERIFY
		// =====================================
		//no valid attributes are passed, expected validation errors
		System.assert(validationErrors.size() > 0, 'Expected validation errors to be returned');
		System.assertEquals(true, validationErrors.contains('First Name attribute is missing'), 'Expected validation error for First Name');
		System.assertEquals(true, validationErrors.contains('Last Name attribute is missing'), 'Expected validation error for Last Name');

		//test again with attributes
		validationErrors = service.validateAssertion(userData.attributeMap);
		// federation_identifier and cnumber attributes are missing, expected validation errors
		System.assertEquals(2, validationErrors.size(), 'Expected validation errors to be returned');
		System.assertEquals(true, validationErrors.contains('Username attribute is missing'), 'Expected validation error for UserName');
		System.assertEquals(true, validationErrors.contains('CNumber attribute is missing'), 'Expected validation error for CNumber');

		//test again with augmented attributes
		Map<String, String> augmentedAttributes = service.getAugmentedAttributes(userData.attributeMap);
		validationErrors = service.validateAssertion(augmentedAttributes);
		// federation_identifier and cnumber attributes are populated, expected no validation errors
		System.assertEquals(0, validationErrors.size(), 'Expected validation errors to be returned');
		System.assertEquals(false, validationErrors.contains('Username attribute is missing'), 'Expected validation error for UserName');
		System.assertEquals(false, validationErrors.contains('CNumber attribute is missing'), 'Expected validation error for CNumber');
	}

	private static Auth.UserData getUserData(Contact contact, User user) {
		// set our user data mock from the Auth Provider
		Id networkId = '0DB000000000000001';
		String identifier = '_randomIdentifier' + Datetime.now().getTime();
		Map<String, String> attributeMap = new Map<String, String>{
			'sub' => identifier,
			'name' => contact.LastName + ', ' + contact.FirstName,
			'given_name' => contact.FirstName,
			'family_name' => contact.LastName,
			'email' => contact.Email,
			'https://auspost/apcn' => '123',
			'https://auspost/cnumber' => 'C0000000001',
			'sfdc_networkid' => networkId
		};
		Auth.UserData userData = new Auth.UserData(identifier, contact.FirstName, contact.LastName, contact.FirstName + ' ' + contact.LastName,
													contact.Email, null, user.Username, null, 'Open ID Connect', 'https://communityurl/', attributeMap);
		return userData;
	}
}