/**
 * @description A very simple selector class for LiveChatTranscript Object
 * @author George Nguyen
 * @date 2024-09-24
 * @changelog
 * 2024-09-24 - George Nguyen - created
 */
public virtual inherited sharing class LiveChatTranscriptsSelector extends ApplicationSelector {
	public enum Options {
		WITH_CASE
	}

	public static LiveChatTranscriptsSelector newInstance() {
		return (LiveChatTranscriptsSelector)Application.Selectors.newInstance(LiveChatTranscriptsSelector.class);
	}

	public static LiveChatTranscriptsSelector newInstance(Integer recordLimit) {
		return (LiveChatTranscriptsSelector)Application.Selectors.newInstance(LiveChatTranscriptsSelector.class).setLimit(recordLimit);
	}

	public static LiveChatTranscriptsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		return (LiveChatTranscriptsSelector) Application.Selectors.newInstance(LiveChatTranscriptsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
	}

	public virtual override SObjectType getSObjectType() {
		return LiveChatTranscript.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() { 
		return new Set<SObjectField>{ LiveChatTranscript.Id,  LiveChatTranscript.CaseId };
	}
   
	/**
	 * @param selectorOptions Set<Object> selectorOptions
	 * @param ids Set<Id>
	 * @description returns a list of records base on their Id
	 *
	 * @return List<LiveChatTranscript>
	 */
	public List<LiveChatTranscript> selectByIds(Set<Object> selectorOptions, Set<Id> ids) {		
 		QueryBuilder qb = newQueryBuilder(selectorOptions);  
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions.add(new QueryBuilder.SimpleCondition(LiveChatTranscript.Id + ' IN :ids'));
		conditions.endConditions();
		return (List<LiveChatTranscript>)Database.query(qb.toSoqlString());
	}

	/**
	 * Contruct a new QueryBuilder based on the selector options passed in
	 * @param selectorOptions Set<Object>
	 * @return QueryBuilder
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		
		if(selectorOptions.contains(Options.WITH_CASE)) {
			builder.addRelatedFields(CasesSelector.newInstance().newQueryBuilder(), 'Case');
		}
		
		return builder;
	}
}