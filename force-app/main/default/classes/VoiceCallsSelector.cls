/**
 * @author 		Paul Perry
 * @date 		15-08-2024
 * @group 		Selector
 * @tag			Selector
 *
 * @description 	A very simple selector class for VoiceCall Object
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
		Set<SObjectField> result = new Set<SObjectField>{
			VoiceCall.Id,
			VoiceCall.VendorCallKey,
			VoiceCall.Division__c,
			VoiceCall.CustomerParticipantId__c
		};

		result.addAll(GenesysConstants.genesysFieldMappings.keySet());
		return result;
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

		return (List<VoiceCall>)Database.query(qb.toSoqlString());
	}


	/**
	 * @param selectorOptions Set<Object> selectorOptions
	 * @param callIds Set<Id>
	 * @description returns a list of Voice Call records base on their ConversationId
	 *
	 * @return List<VoiceCall>
	 */
	public List<VoiceCall> selectByConversationIds(Set<Object> selectorOptions, Set<Id> callIds) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.InCondition(VoiceCall.ConversationId).inCollection(callIds))
			.endConditions();

		if (selectorOptions.contains(Options.ORDERBY_OLDTONEW)) {
			qb.setOrder(new QueryBuilder.Order(VoiceCall.CreatedDate));
		}

		return (List<VoiceCall>)Database.query(qb.toSoqlString());
	}

	/**
	 * @param selectorOptions Set<Object> selectorOptions
	 * @param callIds Set<Id>
	 * @description returns a list of Voice Call records base on their PreviousCallId or NextCallId
	 *
	 * @return List<VoiceCall>
	 */
	public List<VoiceCall> selectByOriginalVoiceCalls(Set<Object> selectorOptions, Set<Id> callIds) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.InCondition(VoiceCall.OriginalVoiceCall__c).inCollection(callIds))
				.endConditions();
		return (List<VoiceCall>)Database.query(qb.toSoqlString());
	}

	/**
	 * Contruct a new QueryBuilder based on the selector options passed in
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