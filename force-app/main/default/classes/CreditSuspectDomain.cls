/**
 * @description Domain class to handle CreditSuspect
 * @group Domains
 * @domain CreditSuspect
 */
public inherited sharing class CreditSuspectDomain extends ApplicationDomain {
	public static CreditSuspectDomain newInstance(List<SObject> sObjectList) {
		return (CreditSuspectDomain) ApplicationDomain.newInstance(CreditSuspectDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		registerModule(CreditSuspectGenericModule.class);
	}

	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return CreditSuspectDomain.newInstance(sObjectList);
		}
	}
}