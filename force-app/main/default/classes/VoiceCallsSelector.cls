/**
 * @description A very simple selector class for VoiceCall Object
 * @author Paul Perry
 * @date 2024-08-15
 * @changelog
 * 2024-08-15 - Paul Perry - created
 * 2024-09-20 - Vasu Gorakati - Added method selectByRelatedRecordIds
 */
public virtual inherited sharing class VoiceCallsSelector extends ApplicationSelector {
	public enum Options {
		WITH_CALLER,WITH_RECIPIENT,
		ORDER_BY_CREATED_DATE_ASC
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
		return new Set<SObjectField>{ VoiceCall.Id,  VoiceCall.Name, VoiceCall.CallStartDateTime, VoiceCall.CallEndDateTime, VoiceCall.CallType};
	}

	public static VoiceCallsSelector newInstance(Set<SObjectField> fieldOverrides) {
		return (VoiceCallsSelector) Application.Selectors.newInstance(VoiceCallsSelector.class)
			.setFieldOverrides(fieldOverrides);
	}


	/**
	 * @param selectorOptions Set<Object> selectorOptions
	 * @param callIds Set<Id>
	 * @description returns a list of Voice Call records base on their Id
	 *
	 * @return List<VoiceCall>
	 */
	public List<VoiceCall> selectByIds(Set<Object> selectorOptions, Set<Id> callIds) {
 		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions.add(new QueryBuilder.SimpleCondition(VoiceCall.Id + ' IN :callIds'));
		conditions.endConditions();
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

		if(selectorOptions.contains(Options.ORDER_BY_CREATED_DATE_ASC)) {
			builder.addOrder(
				new QueryBuilder.Order(VoiceCall.CreatedDate)
				.setSortingOrderAsc()
			);
		}

		return builder;
	}

 	/*
	* This method returns Voice Call records with matching case Ids
	* @param relateRecordIds - set of related record ids
	* @param selecterOptions - selector options to augment result set
	*/
	public List<VoiceCall> selectByRelatedRecordIds(Set<Id> relatedRecordIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions.add(new QueryBuilder.SimpleCondition(VoiceCall.RelatedRecordId + ' IN :relatedRecordIds'));
		conditions.endConditions();
		return (List<VoiceCall>)Database.query(qb.toSoqlString());
	}
}