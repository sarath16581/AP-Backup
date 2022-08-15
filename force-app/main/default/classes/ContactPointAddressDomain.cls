/**
 * @description Domain class to handle ContactPointAddress related capability
 * @author George Nguyen
 * @group Domains
 * @domain ContactPointAddress
 * @changelog
 * 2022-05-31 - George Nguyen - Created.
 */
public inherited sharing class ContactPointAddressDomain extends ApplicationDomain {
	public static ContactPointAddressDomain newInstance(List<SObject> sObjectList) {
		return (ContactPointAddressDomain) ApplicationDomain.newInstance(ContactPointAddressDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		if (ContactService.getInstance().checkCurrentUserIsIntegrationUser(UserInfo.getUserId())) {
			registerModule(ContactPointAddressDomainModule.class);
		}
	}

	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return ContactPointAddressDomain.newInstance(sObjectList);
		}
	}
}