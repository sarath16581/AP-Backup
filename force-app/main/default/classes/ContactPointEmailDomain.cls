/**
 * @description       :Domain class to handle Contact Point Email triger logic
 * @author            : Sreenish Krishnan
 * @domain            :
 * @last modified on  : 07-22-2022
 * @last modified by  : Sreenish Krishnan
 **/
public inherited sharing class ContactPointEmailDomain extends ApplicationDomain {
	public static ContactPointEmailDomain newInstance(List<sObject> sObjectList) {
		return (ContactPointEmailDomain) ApplicationDomain.newInstance(ContactPointEmailDomain.class, sObjectList);
	}

	public override void registerModules() {
		registerModule(ContactPointEmailDomainModule.class);
	}

	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return ContactPointEmailDomain.newInstance(sObjectList);
		}
	}
}