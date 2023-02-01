/**
 * @description       : Domain class to handle CaseInvestigation trigger logic
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 * 2022-01-15 - Dattaraj Deshmukh - Added STCaseInvestigationLifeCycleModule. Removed Constructor class and 'IConstructableModule' interface implementation. 
 **/
public inherited sharing class STCaseInvestigationDomain extends ApplicationDomain {

	public static STCaseInvestigationDomain newInstance(List<sObject> sObjectList) {
		return (STCaseInvestigationDomain) ApplicationDomain.newInstance(STCaseInvestigationDomain.class, sObjectList);
	}

	public override void registerModules() {
		registerModule(STCaseInvestigationArticleModule.class);
		registerModule(STCaseInvestigationLifecycleModule.class);

	}

	/**
	 * Prefilter the records passed in to ensure this domain class only processes applicable records.
	 */
	public override List<SObject> filter(List<SObject> records) {
		Set<Id> validRecordTypes = new RecordTypesSelector().selectByDeveloperNameLike(CaseInvestigation__c.class.getName(), 'StarTrack').keySet();
		List<SObject> output = new List<SObject>();
		for(SObject record : records) {
			if(validRecordTypes.contains((Id)record.get('RecordTypeId'))) {
				output.add(record);
			}
		}
		return output;
	}
}