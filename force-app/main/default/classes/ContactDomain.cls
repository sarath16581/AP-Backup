/**
 * @description Domain class to handle Contact related capability
 * @author George Nguyen
 * @group Domains
 * @domain Contact
 * @changelog
 * 2022-05-31 - George Nguyen - Created.
 */
public inherited sharing class ContactDomain extends ApplicationDomain {
	public static ContactDomain newInstance(List<SObject> sObjectList) {
		return (ContactDomain) ApplicationDomain.newInstance(ContactDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		registerModule(ContactDomainFormattingModule.class);
	}

	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return ContactDomain.newInstance(sObjectList);
		}
	}
}