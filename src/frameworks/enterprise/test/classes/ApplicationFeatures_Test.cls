/***
 * @description Test class to cover ApplicationFeatures
 * @author Nathan Franklin
 * @date 2022-04-23
 * @changelog
 * 14/10/2022 George Nguyen: Add Unit test for "loadFeatures" method that pulls settings from Custom Settings (ApplicationFeatures__c)
 */
@IsTest
private class ApplicationFeatures_Test {

	/**
	 Scenario. Tests to ensure all the module feature capability works as expected
	 */
	@IsTest
	public static void testModuleFeatures() {

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

		System.assertEquals(ApplicationFeatures.FEATURE_DEFAULT_BEHAVIOUR, ApplicationFeatures.getInstance().isModuleActive(MyModule.class));

		ApplicationFeatures.getInstance().setModuleStatus(MyModule.class, true);
		System.assert(ApplicationFeatures.getInstance().isModuleActive(MyModule.class));

		ApplicationFeatures.getInstance().setModuleStatus(MyModule.class, false);
		System.assertEquals(false, ApplicationFeatures.getInstance().isModuleActive(MyModule.class));

		insert new ApplicationFeatures__c(Name = String.valueOf(MyModule.class), IsModule__c = true, Disabled__c = false);
		ApplicationFeatures.getInstance().featuresLoaded = false; // forcing a new reload to get the setting from Custom Setting
		System.assertEquals(true, ApplicationFeatures.getInstance().isModuleActive(MyModule.class));

		Test.stopTest();

	}

	/**
	 Scenario. Tests to ensure all the Domain feature capability works as expected
	 */
	@IsTest
	public static void testDoaminFeatures() {

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

		System.assertEquals(ApplicationFeatures.FEATURE_DEFAULT_BEHAVIOUR, ApplicationFeatures.getInstance().isDomainActive(MyDomain.class));

		ApplicationFeatures.getInstance().setDomainStatus(MyDomain.class, true);
		System.assert(ApplicationFeatures.getInstance().isDomainActive(MyDomain.class));

		ApplicationFeatures.getInstance().setDomainStatus(MyDomain.class, false);
		System.assertEquals(false, ApplicationFeatures.getInstance().isDomainActive(MyDomain.class));

		insert new ApplicationFeatures__c(Name = String.valueOf(MyDomain.class), IsDomain__c = true, Disabled__c = false);
		ApplicationFeatures.getInstance().featuresLoaded = false; // forcing a new reload to get the setting from Custom Setting
		System.assertEquals(true, ApplicationFeatures.getInstance().isDomainActive(MyDomain.class));

		Test.stopTest();

	}

	/**
	 Scenario. Tests to ensure all the feature feature capability works as expected
	 */
	@IsTest
	public static void testFeatureFeatures() {

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

		System.assertEquals(ApplicationFeatures.FEATURE_DEFAULT_BEHAVIOUR, ApplicationFeatures.getInstance().isFeatureActive('MyFeature'));

		ApplicationFeatures.getInstance().setFeatureStatus('MyFeature', true);
		System.assert(ApplicationFeatures.getInstance().isFeatureActive('MyFeature'));

		ApplicationFeatures.getInstance().setFeatureStatus('MyFeature', false);
		System.assertEquals(false, ApplicationFeatures.getInstance().isFeatureActive('MyFeature'));

		insert new ApplicationFeatures__c(Name = 'MyFeature', Disabled__c = false);
		ApplicationFeatures.getInstance().featuresLoaded = false; // forcing a new reload to get the setting from Custom Setting
		System.assertEquals(true, ApplicationFeatures.getInstance().isFeatureActive('isFeatureActive'));

		Test.stopTest();

	}

	public class MyDomain extends ApplicationDomain { }

	public class MyModule extends ApplicationDomain.Module {
		public MyModule() {
			getTriggerEvents().disableAll();
		}
	}

}