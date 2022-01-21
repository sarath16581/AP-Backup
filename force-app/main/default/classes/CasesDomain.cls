/**
* @description Domain class to handle common logic for all case types
* @author Ashapriya Gadi
* @date 2021-12-06
* @group Domains
* @changelog
*/

public inherited sharing class CasesDomain extends ApplicationDomain{
	public static CasesDomain newInstance(List<SObject> sObjectList) {
		return (CasesDomain)ApplicationDomain.newInstance(CasesDomain.class, sObjectList);
	}
	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		registerModule(CaseOwnerMetricsModule.class);
	}
	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return CasesDomain.newInstance(sObjectList);
		}
	}
}