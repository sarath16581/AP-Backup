/**
 * @author George Nguyen
 * @group Selector
 * @tag Selector
 * @tag ContactPoints
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2022-06-07 - George Nguyen - Created
 */
public virtual inherited sharing class ContactPointPhoneSelector extends ApplicationSelector {
	public enum Options {
		FILTER_HOMEPHONE,
		FILTER_MOBILEPHONE,
		FILTER_VERIFIED_FALSE,
		FILTER_PREFERRED_TRUE,
		WITH_CONTACT
	}

	public static ContactPointPhoneSelector newInstance() {
		return (ContactPointPhoneSelector) Application.Selectors.newInstance(ContactPointPhoneSelector.class);
	}

	public static ContactPointPhoneSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		ContactPointPhoneSelector selector = (ContactPointPhoneSelector) Application.Selectors.newInstance(ContactPointPhoneSelector.class)
			.setLimit(recordLimit)
			.setFieldOverrides(fieldOverrides);

		return selector;
	}

	public static ContactPointPhoneSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		ContactPointPhoneSelector selector = (ContactPointPhoneSelector) Application.Selectors.newInstance(ContactPointPhoneSelector.class)
			.setLimit(recordLimit)
			.setFieldOverrides(fieldOverrides);

		return selector;
	}

	public override SObjectType getSObjectType() {
		return ContactPointPhone.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
			ContactPointPhone.Id,
			ContactPointPhone.ParentId,
			ContactPointPhone.Contact__c,
			ContactPointPhone.TelephoneNumber,
			ContactPointPhone.PhoneType,
			ContactPointPhone.Verified__c,
			ContactPointPhone.Preferred__c,
			ContactPointPhone.UniqueMobile__c
		};
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.FILTER_HOMEPHONE)) {
			builder.addConditions().add(new QueryBuilder.SimpleCondition(ContactPointPhone.PhoneType + ' = \'Home\'')); // These are fixed standard values
		}
		if (selectorOptions.contains(Options.FILTER_MOBILEPHONE)) {
			builder.addConditions().add(new QueryBuilder.SimpleCondition(ContactPointPhone.PhoneType + ' = \'Mobile\'')); // These are fixed standard values
		}
		if (selectorOptions.contains(Options.FILTER_VERIFIED_FALSE)) {
			builder.addConditions().add(new QueryBuilder.SimpleCondition(ContactPointPhone.Verified__c + ' = FALSE'));
		}
		if (selectorOptions.contains(Options.FILTER_PREFERRED_TRUE)) {
			builder.addConditions().add(new QueryBuilder.SimpleCondition(ContactPointPhone.Preferred__c + ' = TRUE'));
		}
		if (selectorOptions.contains(Options.WITH_CONTACT)) {
			builder.addRelatedFields(ContactsSelector.newInstance(recordLimit,fieldOverrides).newQueryBuilder(), 'Contact__r');
		}
		return builder;
	}

	public List<ContactPointPhone> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	public List<ContactPointPhone> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(ContactPointPhone.Id + ' in :ids'))
			.endConditions();
		return (List<ContactPointPhone>) Database.query(qb.toSoqlString());
	}

	public List<ContactPointPhone> selectByContact(Set<Id> contactIds, Set<Object> selectorOptions) {
		return selectByContactAndPhoneNumber(contactIds, null, selectorOptions);
	}

	public List<ContactPointPhone> selectByContactAndPhoneNumber(
		Set<Id> contactIds,
		List<String> phoneNumbers,
		Set<Object> selectorOptions
	) {
		QueryBuilder.ConditionsManager cm = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(ContactPointPhone.Contact__c + ' in :contactIds'));

		if (phoneNumbers != null) {
			cm.add(new QueryBuilder.SimpleCondition(ContactPointPhone.TelephoneNumber + ' in :phoneNumbers'));
		}

		QueryBuilder qb = cm.endConditions();

		return (List<ContactPointPhone>) Database.query(qb.toSoqlString());
	}

	public List<ContactPointPhone> selectByParentId(Set<Id> parentIds, Set<Object> selectorOptions) {
		QueryBuilder.ConditionsManager cm = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(ContactPointPhone.ParentId + ' in :parentIds'));

		QueryBuilder qb = cm.endConditions();
		return (List<ContactPointPhone>) Database.query(qb.toSoqlString());
	}
}