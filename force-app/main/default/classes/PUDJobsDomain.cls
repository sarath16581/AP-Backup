/**
* @description Domain class to handle PUD Job related capability
* @author Ranjeewa Silva
* @date 2021-08-12
* @group Domains
* @domain PUD
* @changelog
* 2021-08-12 - Ranjeewa Silva - Created.
*/

public inherited sharing class PUDJobsDomain extends ApplicationDomain {

	public static PUDJobsDomain newInstance(List<SObject> sObjectList) {
		return (PUDJobsDomain)ApplicationDomain.newInstance(PUDJobsDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		registerModule(PUDJobDispatchSystemSyncModule.class);
	}

	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return PUDJobsDomain.newInstance(sObjectList);
		}
	}

}