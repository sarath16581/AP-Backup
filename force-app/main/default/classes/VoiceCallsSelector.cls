/**
 * @description A very simple selector class for VoiceCall Object
 * @author Paul Perry
 * @date 2024-08-15
 * @changelog
 * 2024-08-15 - Paul Perry - created
 */
public virtual inherited sharing class VoiceCallsSelector extends ApplicationSelector {
	public enum Options {
		ORDERBY_OLDTONEW,WITH_CALLER,WITH_RECIPIENT
	}

	public static VoiceCallsSelector newInstance() {
		return (VoiceCallsSelector)Application.Selectors.newInstance(VoiceCallsSelector.class);
	}

	public static VoiceCallsSelector newInstance(Integer recordLimit) {
		return (VoiceCallsSelector)Application.Selectors.newInstance(VoiceCallsSelector.class).setLimit(recordLimit);
	}

	public static VoiceCallsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		return (VoiceCallsSelector) Application.Selectors.newInstance(VoiceCallsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
	}

	public virtual override SObjectType getSObjectType() {
		return VoiceCall.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{ VoiceCall.Id };
	}

	/**
	 * @param selectorOptions Set<Object> selectorOptions
	 * @param callIds Set<Id>
	 * @description returns a list of Voice Call records base on their Id
	 *
	 * @return List<VoiceCall>
	 */
	public List<VoiceCall> selectByIds(Set<Object> selectorOptions, Set<Id> callIds) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.InCondition(VoiceCall.Id).inCollection(callIds))
			.endConditions();

		if (selectorOptions.contains(Options.ORDERBY_OLDTONEW)) {
			qb.setOrder(new QueryBuilder.Order(VoiceCall.CreatedDate));
		}

		return (List<VoiceCall>)Database.query(qb.toSoqlString());
	}

	/**
	 * Contruct a new QueryBuilder based on the selector options passed in
	 * @param selectorOptions Set<Object>
	 * @return QueryBuilder
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		if(selectorOptions.contains(Options.WITH_CALLER)) {
			builder.addRelatedFields(ConversationParticipantsSelector.newInstance().newQueryBuilder(), 'Caller');
		}
		if(selectorOptions.contains(Options.WITH_RECIPIENT)) {
			builder.addRelatedFields(ConversationParticipantsSelector.newInstance().newQueryBuilder(), 'Recipient');
		}
		return builder;
	}
}