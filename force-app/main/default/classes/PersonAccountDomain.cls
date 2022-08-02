/**
* @description Domain class to handle Person Account related capability
* @author George Nguyen
* @group Domains
* @domain Account
* @changelog
* 2022-05-31 - George Nguyen - Created.
*/
public inherited sharing class PersonAccountDomain extends ApplicationDomain {

	public static PersonAccountDomain newInstance(List<SObject> sObjectList) {
		return (PersonAccountDomain)ApplicationDomain.newInstance(PersonAccountDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		registerModule(PersonAccountDomainCtPointSyncModule.class);
	}

	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return PersonAccountDomain.newInstance(sObjectList);
		}
	}

}