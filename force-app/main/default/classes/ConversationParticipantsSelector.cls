/**
 * @description A very simple selector class for ConversationParticipant Object
 * @author SteveL
 * @date 2024-09-09
 * @changelog
 * 2024-09-09 - SteveL - created
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
}