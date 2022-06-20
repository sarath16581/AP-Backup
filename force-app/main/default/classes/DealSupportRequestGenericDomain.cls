/**
 * @auth: Dattaraj Deshmukh (dattaraj.deshmukh@slalom.com)
 * @date: 2022-06-02
 * @desc: Generic Domain class created to perform logic as per trigger framework.
 * @change log:
 * Dattaraj Deshmukh - 2022-06-02  - Created
 */
public with sharing class DealSupportRequestGenericDomain  extends ApplicationDomain{
    public static DealSupportRequestGenericDomain newInstance(List<SObject> sObjectList) {
		return (DealSupportRequestGenericDomain)ApplicationDomain.newInstance(DealSupportRequestGenericDomain.class, sObjectList);
	}
	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		registerModule(DealSupportRequestMilestonesTrackModule.class);
	}
	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return DealSupportRequestGenericDomain.newInstance(sObjectList);
		}
	}
}