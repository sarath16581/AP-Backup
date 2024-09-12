/**
 * @author 		Rejeesh Raghavan
 * @date 		10-09-2024
 * @group 		Selector
 * @tag			Selector
 *
 * @description 	A very simple selector class for LiveChatTranscript Object
 */
public virtual inherited sharing class LiveChatTranscriptsSelector extends ApplicationSelector {
	public enum Options {
		WITH_OWNER
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
		Set<SObjectField> result = new Set<SObjectField>{
			LiveChatTranscript.Id,
			LiveChatTranscript.CreatedById,
			LiveChatTranscript.OwnerId

		};
		return result;
	}

	/**
	 * @param selectorOptions Set<Object> selectorOptions
	 * @param callIds Set<Id>
	 * @description returns a list of Live Chat Transcript records base on their Id
	 *
	 * @return List<LiveChatTranscript>
	 */
	public List<LiveChatTranscript> selectByIds(Set<Object> selectorOptions, Set<Id> transcriptIds) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.InCondition(LiveChatTranscript.Id).inCollection(transcriptIds))
			.endConditions();

		return (List<LiveChatTranscript>)Database.query(qb.toSoqlString());
	}

	/**
	 * Contruct a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
		}

		return builder;
	}
}