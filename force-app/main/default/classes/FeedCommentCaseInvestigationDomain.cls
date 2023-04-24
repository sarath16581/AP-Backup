/**
* @description Domain class to handle FeedComment related capability for case investigation
* @author Mahesh Parvathaneni
* @date 04/04/2023
* @group Domains
* @domain CaseInvestigation 
* @changelog
*/
public inherited sharing class FeedCommentCaseInvestigationDomain extends ApplicationDomain {
	
	public static FeedCommentCaseInvestigationDomain newInstance(List<SObject> sObjectList) {
		return (FeedCommentCaseInvestigationDomain)ApplicationDomain.newInstance(FeedCommentCaseInvestigationDomain.class, sObjectList);
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
		registerModule(FeedCommentCaseInvestigationModule.class);
	}
}