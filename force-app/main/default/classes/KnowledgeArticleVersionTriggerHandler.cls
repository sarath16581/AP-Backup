/**
 * @description
 * Trigger handler for KnowledgeArticleVersionTrigger
 * @author Raghav Ravipati
 * @date 2024-05-23
 * @test KnowledgeArticleVersionTriggerHandlerTst
 * @changelog
 */
public class KnowledgeArticleVersionTriggerHandler extends ApplicationTriggerHandler {
	public override SObjectType getSObjectType() {
		return Knowledge__kav.SObjectType;
	}

	public override void registerModules() {
		registerModule(DataCategoryCreationModule.class, 'eligibleRecords');
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{ Knowledge__DataCategorySelection.SObjectType };
	}
	/**Filter records Before passing to the module and service classes */
	public override Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
		Set<String> recordTypeNames = new Set<String>{ 'Critical_Incident', 'FAQ', 'How_To', 'Manager', 'Product', 'Push_EDM', 'Recovery_Team', 'Specialist_Skill', 'StarTrack_How_To', 'Support' };
		Map<String, List<SObject>> filteredRecords = new Map<String, List<SObject>>{ 'eligibleRecords' => new List<SObject>() };
		Set<Id> validRecordTypes = new RecordTypesSelector().selectByDeveloperName('Knowledge__kav', recordTypeNames).keySet();
		for (SObject record : records) {
			if (validRecordTypes.contains((Id) record.get('RecordTypeId'))) {
				filteredRecords.get('eligibleRecords').add(record);
			}
		}

		return filteredRecords;
	}
}