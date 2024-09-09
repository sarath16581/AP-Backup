/**
 * @author 		SteveL
 * @date 		09-09-2024
 * @group 		Selector
 * @tag			Selector
 *
 * @description 	A very simple selector class for ConversationParticipant Object
 */
public virtual inherited sharing class ConversationParticipantsSelector extends ApplicationSelector {

	public static ConversationParticipantsSelector newInstance() {
		return (ConversationParticipantsSelector) Application.Selectors.newInstance(ConversationParticipantsSelector.class);
	}

	public static ConversationParticipantsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		return (ConversationParticipantsSelector) Application.Selectors.newInstance(ConversationParticipantsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
	}

	public virtual override SObjectType getSObjectType() {
		return ConversationParticipant.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		Set<SObjectField> result = new Set<SObjectField>{
				ConversationParticipant.Id,
				ConversationParticipant.ParticipantDisplayName
		};
		return result;
	}

	/**
	 * @param displayNames Set<String>
	 *
	 * @return List<ConversationParticipant>
	 */
	public List<ConversationParticipant> selectByParticipantDisplayNames(Set<String> displayNames) {
		QueryBuilder qb = newQueryBuilder(new Set<Object>())
				.addConditions()
				.add(new QueryBuilder.InCondition(ConversationParticipant.ParticipantDisplayName).inCollection(displayNames))
				.endConditions();

		return (List<ConversationParticipant>)Database.query(qb.toSoqlString());
	}
}