/**
 * @description Domain class to handle ContactPointPhone related capability
 * @author George Nguyen
 * @group Domains
 * @domain ContactPointPhone
 * @changelog
 * 2022-05-31 - George Nguyen - Created.
 */
public inherited sharing class ContactPointPhoneDomain extends ApplicationDomain {
	public static ContactPointPhoneDomain newInstance(List<SObject> sObjectList) {
		return (ContactPointPhoneDomain) ApplicationDomain.newInstance(ContactPointPhoneDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		registerModule(ContactPointPhoneDomainModule.class);
	}

	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return ContactPointPhoneDomain.newInstance(sObjectList);
		}
	}
}