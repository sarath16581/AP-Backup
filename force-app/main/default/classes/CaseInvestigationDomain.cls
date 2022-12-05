/**
 * @description       : Domain class to handle CaseInvestigation trigger logic
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 **/
public inherited sharing class CaseInvestigationDomain extends ApplicationDomain {
	public static CaseInvestigationDomain newInstance(List<sObject> sObjectList) {
		return (CaseInvestigationDomain) ApplicationDomain.newInstance(CaseInvestigationDomain.class, sObjectList);
	}

	public override void registerModules() {
		registerModule(CaseInvestigationArticleModule.class);
	}

	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return CaseInvestigationDomain.newInstance(sObjectList);
		}
	}
}