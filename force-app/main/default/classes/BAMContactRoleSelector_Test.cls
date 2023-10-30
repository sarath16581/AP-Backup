/**
 * @author Hasantha Liyanage
 * @date 2023-10-02
 * @group Test
 * @domain BAM
 * @description BAMContactRoleSelector selector Test
 * @changelog
 * 2023-10-02 - Hasantha Liyanage  - Created
 */
@IsTest
private class BAMContactRoleSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BAMContactRoleSelector selector = BAMContactRoleSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom BAMContactRole__c\\b').matcher(soql).find(), 'Resulting query does not select from BAMContactRole__c');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BAMContactRoleSelector selector = BAMContactRoleSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{
				BAMContactRoleSelector.Options.WITH_CONTACT_APPLICATION
		});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)ContactApplication__r\\..*?\\bfrom BAMContactRole__c\\b').matcher(soql).find(), 'Resulting query does not select Contact fields');
		Test.stopTest();
	}

	/**
		* Test:
		*  Ensures that the selectors QueryBuilder is generating the correct output
		*/
	@IsTest
	public static void integrationTest() {
		// =====================================
		// Data Preparation
		// =====================================
		//Create test data
		Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
		Id orgId = recordIdMap.get('acc');

		// creating BAM User who we will run this test as
		Contact bamUserContact = BAMTestUtility.createTestContact(orgId, 'Some org Id');
		bamUserContact.Email = 'test@extrasafty.com.au.lk';
		bamUserContact.FirstName = 'Jammy Sim';
		insert bamUserContact;

		BAMApplication__c bamApp = BAMTestUtility.createBamApplication('BAM');
		bamApp.appKey__c ='BAM';
		insert bamApp;

		Asset prod = BAMTestUtility.createAsset(orgId, bamApp.Product__c, true);
		insert prod;

		BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(bamApp);
		appRole.Role__c = BAMUserUtility.ACCESS_MANAGEMENT_SUPER_ADMIN;
		insert appRole;

		BAMContactApplication__c conApp = BAMTestUtility.createTestContactApplication(bamUserContact.Id, bamApp.Id);
		insert conApp;

		BAMContactRole__c conRole = BAMTestUtility.createTestContactRole(conApp.Id, appRole.Id);
		insert conRole;

		User portalUser = BAMTestUtility.createBusinessPortalUser(bamUserContact, BspConstants.BSP_COMMUNITY_PROFILE_NAME);
		portalUser.Username = System.currentTimeMillis() + portalUser.Username;
		insert portalUser;

		// creating different org
		Account testAccount = BAMTestUtility.createTestAccount('1234');
		insert testAccount;
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		// Get portal user Id
		Test.startTest();
		Id businessPortalUserId = recordIdMap.get('User');
		User businessPortalUser = [SELECT Id, AccountId FROM User WHERE Id =: businessPortalUserId];
		System.runAs(businessPortalUser) {
			BAMContactRoleSelector selector = BAMContactRoleSelector.newInstance();
			List<BAMContactRole__c> contactRoles = selector.selectRolesByRoleAndOrgId(new Set<String>{BAMUserUtility.ACCESS_MANAGEMENT_SUPER_ADMIN},
					new Set<Id>{businessPortalUser.AccountId},
					new Set<Object>{BAMContactRoleSelector.Options.WITH_CONTACT_APPLICATION});
			//Set<String> roles, Set<Id> orgIds, Set<Object> selectorOptions
			system.debug('contactRoles RESULT '+contactRoles);
			System.assertNotEquals(0, contactRoles.size());
		}
		Test.stopTest();
	}
}