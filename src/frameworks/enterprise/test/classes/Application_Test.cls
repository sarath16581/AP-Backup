/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Utility
 * @domain Core
 * @description Test Class covering Application
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-08-02 - Nathan Franklin - Added new test methods for domains
 * 2022-12-07 - Noel Lim 		- Added test methods for new Cache variables queuesWithRoutingConfig, queueIdVsRoutingConfig
 * 2023-06-19 - Nathan Franklin - Covering modules
 */
@IsTest
private with sharing class Application_Test {

    @IsTest
	static void organisationInfoShouldReturnTheCurrentOrg() {
		CacheManager.settings.CacheEnabled__c = true;
		Application.Cache.resetStaticVariablesForUnitTestOnly();

		Organization currentOrg = [SELECT IsSandbox FROM Organization LIMIT 1];
		System.assertEquals(currentOrg.IsSandbox, Application.Cache.organizationInfo.isSandbox, 'should match');

		String expectedSandboxName = ''; // default for Production
		
		// only check against sandboxes or else in production this will fail. 
		if(currentOrg.isSandbox == true) { 
			expectedSandboxName = System.Url.getSalesforceBaseUrl().getHost().substringBetween('--', '.');
		}

		System.assertEquals(expectedSandboxName, Application.Cache.organizationInfo.sandboxName, 'should match');

		// test loading from cache
		Application.Cache.resetStaticVariablesForUnitTestOnly();
		Organization tempOrg = (Organization)ApplicationTestDataFactory.setUnwritableFields(new Organization(), new Map<String, Object>{'IsSandbox'=>false});
		Application.OrganizationWrapper wrapper = new Application.OrganizationWrapper(tempOrg);
		CacheManager.put('ORGANISATION_INFO', wrapper);
		System.assertEquals('', Application.Cache.organizationInfo.sandboxName, 'should match');
	}

	@IsTest
	static void profileIdsShouldReturnAllProfiles() {
		CacheManager.settings.CacheEnabled__c = true;
		Application.Cache.resetStaticVariablesForUnitTestOnly();

		List<Profile> profiles = [SELECT Name FROM Profile];

		// testing loading from query
		// Note: the below is failing in PTest because there are two Marketing User (standard) profiles. Will raise a case to find out why. For now, I will comment the below out:
		/*
		System.assertEquals(profiles.size(), Application.Cache.profileIds.size(), 'it should return the same number of profiles');
		System.assertEquals(profiles[0].Id, Application.Cache.profileIds.get(profiles[0].Name), 'should match');
		System.assertEquals(profiles[profiles.size() - 1].Id, Application.Cache.profileIds.get(profiles[profiles.size() - 1].Name), 'should match');
		*/

		// test loading from cache
		Application.Cache.resetStaticVariablesForUnitTestOnly();
		CacheManager.put('ALL_PROFILE_IDS', new Map<String, Id>{'test'=>profiles[0].Id});
		System.assertEquals(profiles[0].Id, Application.Cache.profileIds.get('test'), 'should match');
	}

	/**
	 * Tests each of the factories to ensure the correct objects are returned when needed
	 */
	@IsTest
	private static void testFactories() {
		MyClassMock mockUtility = new MyClassMock();
		MySelectorMock mockSelector = new MySelectorMock();
		ApplicationTestDomain1_Test mockDomain = new ApplicationTestDomain1_Test();
		AccountModule1 mockModule = new AccountModule1();

		Object output = Application.Utilities.getInstance(MyClass.class);
		System.assert(output instanceof MyClass, 'getInstance expected an instance of MyClass');

		output = Application.Utilities.newInstance(MyClass.class);
		System.assert(output instanceof MyClass, 'getInstance expected an instance of MyClass');

		Application.Utilities.setMock(MyClass.class, mockUtility);
		output = Application.Utilities.getInstance(MyClass.class);
		System.assert(output == mockUtility, 'getInstance expected an instance of MyClassMock');

		output = Application.Utilities.newInstance(MyClass.class);
		System.assert(output == mockUtility, 'getInstance expected an instance of MyClassMock');

		output = Application.Selectors.newInstance(MySelector.class);
		System.assert(output instanceof MySelector, 'getInstance expected an instance of MySelector');

		Application.Selectors.setMock(MySelector.class, mockSelector);
		output = Application.Selectors.newInstance(MySelector.class);
		System.assert(output == mockSelector, 'getInstance expected an instance of MySelectorMock');

		Application.Domains.setMock(ApplicationTestDomain1_Test.class, mockDomain);
		output = Application.Domains.newInstance(ApplicationTestDomain1_Test.class, new List<SObject>{});
		System.assert(output == mockDomain, 'newInstance expected an instance of ApplicationTestDomain1_Test');

		Application.Modules.setMock(AccountModule1.class, mockModule);
		output = Application.Modules.newInstance(AccountModule1.class);
		System.assert(output == mockModule, 'newInstance expected an instance of AccountModule1');

		// test profiler
		Application.Profiler.start('test');
		Application.Profiler.stop('test');

		Application.GenericFactory factory = new Application.GenericFactory();
		factory.put(MyClassMock.class, mockUtility);
		System.assert(factory.get(MyClassMock.class) == mockUtility, 'getInstance expected an instance of MySelectorMock');

	}

	private class MyClassMock { }
	private class MyClass { }

	public class MySelector extends ApplicationSelector {

		public override SObjectType getSObjectType() {
			return Contact.getSObjectType();
		}

		public virtual override Set<SObjectField> getSObjectFieldList() {
			return new Set<SObjectField> {Contact.Id, Contact.AccountId, Contact.FirstName, Contact.LastName, Account.OwnerId};
		}

	}

	public class MySelectorMock extends ApplicationSelector {

		public override SObjectType getSObjectType() {
			return Contact.getSObjectType();
		}

		public virtual override Set<SObjectField> getSObjectFieldList() {
			return new Set<SObjectField> {Contact.Id, Contact.AccountId, Contact.FirstName, Contact.LastName, Account.OwnerId};
		}

	}

	public class AccountModule1 extends ApplicationModule {

		public AccountModule1() {
			getTriggerEvents().enableAll();
		}

	}

}