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
 */
@IsTest
private with sharing class Application_Test {

	/**
	 * Tests each of the factories to ensure the correct objects are returned when needed
	 */
	@IsTest
	private static void testFactories() {
		MyClassMock mockUtility = new MyClassMock();
		MySelectorMock mockSelector = new MySelectorMock();
		ApplicationTestDomain1_Test mockDomain = new ApplicationTestDomain1_Test();

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

}