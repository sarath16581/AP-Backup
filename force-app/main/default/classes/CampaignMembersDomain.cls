/**
* @description Domain class to handle common logic for all CampaignMembers
* @author Mathew Jose
* @date 2021-12-15
* @group Domains
* @changelog
*/
public inherited sharing class CampaignMembersDomain extends ApplicationDomain {
	public static CampaignMembersDomain newInstance(List<SObject> sObjectList) {
		return (CampaignMembersDomain)ApplicationDomain.newInstance(CampaignMembersDomain.class, sObjectList);
	}
	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		registerModule(CampaignMemberSurveysModule.class);
	}
	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return CampaignMembersDomain.newInstance(sObjectList);
		}
	}
}