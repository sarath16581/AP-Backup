

public with sharing class PUDContainersDomain extends ApplicationDomain {
    public static PUDContainersDomain newInstance(List<SObject> sObjectList) {
		return (PUDContainersDomain)ApplicationDomain.newInstance(PUDContainersDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		registerModule(PUDContainerTypeSyncModule.class);
	}

	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return PUDContainersDomain.newInstance(sObjectList);
		}
	}
}
