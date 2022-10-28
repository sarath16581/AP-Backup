/**
* @description Domain class to handle the Local Business Partner capbility on the User trigger
* @author Kamil Szyc
* @date 2022-08-25
* @group Domains
* @changelog
*/
public inherited sharing class LBPContactDomain extends ApplicationDomain {

	public static LBPContactDomain newInstance(List<SObject> sObjectList) {
		return (LBPContactDomain) ApplicationDomain.newInstance(LBPContactDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		registerModule(LBPContactPermissionsModule.class);
	}
}