/**
 * @description Domain class to handle all generic capability related to Opportunity.
 * @author Ranjeewa Silva
 * @date 2023-05-04
 * @group Domains
 * @domain Core
 * @test OpportunityGenericDomain_Test
 * @changelog
 * 2023-05-04 - Ranjeewa Silva - Created.
 */
public inherited sharing class OpportunityGenericDomain extends ApplicationDomain {

	public static OpportunityGenericDomain newInstance(List<SObject> sObjectList) {
		return (OpportunityGenericDomain)ApplicationDomain.newInstance(OpportunityGenericDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		registerModule(SalesOpportunityContributionSplitsModule.class);
	}

}