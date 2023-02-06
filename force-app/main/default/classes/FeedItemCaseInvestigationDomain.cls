/**
* @description Domain class to handle FeedItem related capability
* @author Dattaraj Deshmukh
* @date 23/11/2022
* @group Domains
* @domain Generic 
* @changelog
* 23/11/2022 - Dattaraj Deshmukh - Created.
*/
public inherited sharing class FeedItemCaseInvestigationDomain extends ApplicationDomain{
	
	public static FeedItemCaseInvestigationDomain newInstance(List<SObject> sObjectList) {
		return (FeedItemCaseInvestigationDomain)ApplicationDomain.newInstance(FeedItemCaseInvestigationDomain.class, sObjectList);
	}

	//records are filtered by ParentId.
	//only filtered records are passed to domain.
	public override List<SObject> filter(List<SObject> sObjectList) {
		List<SObject> filteredRecords = new List<SObject>();

		SObjectType caseInvestigationSObjecType = CaseInvestigation__c.getSObjectType();
		for(SObject rec : sObjectList) {
			if( ((Id)rec.get('ParentId')).getSObjectType() == caseInvestigationSObjecType ) {
				filteredRecords.add(rec);
			}
		}

		return filteredRecords;
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		registerModule(FeedItemCaseInvestigationModule.class);
	}
}