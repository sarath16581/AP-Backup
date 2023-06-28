/**
 * @description Domain class to handle At Risk Business records
 * @author Pratyush Chalasani
 * @group Domains
 * @domain AtRiskBusiness
 * @changelog
 * 2023-04-21 - Pratyush Chalasani - Created
 */
public inherited sharing class AtRiskBusinessDomain extends ApplicationDomain {
	public static AtRiskBusinessDomain newInstance(List<SObject> sObjectList) {
		return (AtRiskBusinessDomain) ApplicationDomain.newInstance(AtRiskBusinessDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		registerModule(AtRiskBusinessModule.class);
	}
}