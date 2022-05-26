/***
 * @description Provides an ability to switch features on and off as needed
 * This covers 2 primary scenarios:
 * 1. Fringe scenarios where specific capability should be switched off that causes conflicts or issues (Example: 1 async worker which triggers another async worker that retriggers the original async worker)
 * 2. Changes that go into production which shouldn't be activated yet (TODO: Implement custom metadata / custom settings)
 * @author Nathan Franklin
 * @date 2022-02-23
 * @changelog
 */
public inherited sharing class ApplicationFeatures {

	@TestVisible
	private static final Boolean FEATURE_DEFAULT_BEHAVIOUR = true;

	private Boolean featuresLoaded = false;
	private Map<String, Boolean> applicationFeatures = new Map<String, Boolean>();

	public static ApplicationFeatures getInstance() {
		return (ApplicationFeatures)Application.Utilities.getInstance(ApplicationFeatures.class);
	}

	/**
	 * Used sparingly with strong justification.
	 * NOTE, SFDX packaging may prevent using the actual Type. In this case, pass MODULE_[String of type name]
	 */
	public Boolean isModuleActive(Type moduleType) {
		return isFeatureActive('MODULE_' + String.valueOf(moduleType));
	}

	/**
	 * Used sparingly with strong justification.
	 * NOTE, SFDX packaging may prevent using the actual Type. In this case, pass MODULE_[String of type name]
	 */
	public Boolean isDomainActive(Type domainType) {
		return isFeatureActive('DOMAIN_' + String.valueOf(domainType));
	}

	/**
	 * Determines whether a specific feature defined in code should run or not.
	 * NOTE: This should be fully understand and justified why to use this before using it :)
	 */
	public Boolean isFeatureActive(String feature) {
		if(!featuresLoaded) {
			// lazy load features
			loadFeatures();
		}

		if(applicationFeatures.get(feature) == null) {
			return FEATURE_DEFAULT_BEHAVIOUR;
		} else {
			return applicationFeatures.get(feature);
		}
	}

	public void setFeatureStatus(String feature, Boolean isActive) {
		applicationFeatures.put(feature, isActive);
	}

	public void setModuleStatus(Type moduleType, Boolean isActive) {
		applicationFeatures.put('MODULE_' + String.valueOf(moduleType), isActive);
	}

	public void setDomainStatus(Type domainType, Boolean isActive) {
		applicationFeatures.put('DOMAIN_' + String.valueOf(domainType), isActive);
	}

	/**
	 * Load features from custom metadata or custom settings
	 */
	private void loadFeatures() {
		// TODO: Implement
	}

}