/**
 * @description       :Domain class to handle Contact Point Email triger logic
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 08-18-2022
 * @last modified by  : Sreenish Krishnan
 **/
public inherited sharing class ContactPointEmailDomain extends ApplicationDomain {
	public static ContactPointEmailDomain newInstance(List<sObject> sObjectList) {
		return (ContactPointEmailDomain) ApplicationDomain.newInstance(ContactPointEmailDomain.class, sObjectList);
	}

	public override void registerModules() {
		if (ContactService.getInstance().checkCurrentUserIsIntegrationUser(UserInfo.getUserId())) {
			registerModule(ContactPointEmailContactSyncModule.class);
		}
	}

	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return ContactPointEmailDomain.newInstance(sObjectList);
		}
	}
}