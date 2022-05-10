/**
* @description Domain class to handle common logic for all EmailMessage types
* @author Naveen Rajanna
* @date 2022-02-10
* @group Domains
* @changelog
* 2022-02-22	Naveen Rajanna	created - REQ2723199
*/

public inherited sharing class StarTrackEmailMessagesDomain extends ApplicationDomain{
	public static StarTrackEmailMessagesDomain newInstance(List<SObject> sObjectList) {
		return (StarTrackEmailMessagesDomain)ApplicationDomain.newInstance(StarTrackEmailMessagesDomain.class, sObjectList);
	}
	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		registerModule(StarTrackEmailMessagesModule.class);
	}
	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return StarTrackEmailMessagesDomain.newInstance(sObjectList);
		}
	}
}