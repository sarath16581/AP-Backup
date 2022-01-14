/**
* @description Domain class to handle Email Message capability
* @author Ashapriya Gadi
* @date 2021-11-22
* @group Domains
* @changelog
*/

public inherited sharing class ServiceAdvisorsEmailMessagesDomain extends ApplicationDomain {
	public static ServiceAdvisorsEmailMessagesDomain newInstance(List<SObject> sObjectList) {
		return (ServiceAdvisorsEmailMessagesDomain)ApplicationDomain.newInstance(ServiceAdvisorsEmailMessagesDomain.class, sObjectList);
	}
	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		registerModule(ServiceAdvisorEmailMesEntitlementsModule.class);
	}
	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return ServiceAdvisorsEmailMessagesDomain.newInstance(sObjectList);
		}
	}

}