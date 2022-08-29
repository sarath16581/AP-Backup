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
public virtual inherited sharing class ContactPointEmailSelector extends ApplicationSelector {
	public enum Options {
		FILTER_VERIFIED_FALSE,
		WITH_CONTACT
	}

	public static ContactPointEmailSelector newInstance() {
		return (ContactPointEmailSelector) Application.Selectors.newInstance(ContactPointEmailSelector.class);
	}

	public static ContactPointEmailSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		ContactPointEmailSelector selector = (ContactPointEmailSelector) Application.Selectors.newInstance(ContactPointEmailSelector.class)
			.setLimit(recordLimit)
			.setFieldOverrides(fieldOverrides);

		return selector;
	}

	public static ContactPointEmailSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		ContactPointEmailSelector selector = (ContactPointEmailSelector) Application.Selectors.newInstance(ContactPointEmailSelector.class)
			.setLimit(recordLimit)
			.setFieldOverrides(fieldOverrides);

		return selector;
	}

	public override SObjectType getSObjectType() {
		return ContactPointEmail.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
			ContactPointEmail.Id,
			ContactPointEmail.ParentId,
			ContactPointEmail.Contact__c,
			ContactPointEmail.EmailAddress,
			ContactPointEmail.Verified__c,
			ContactPointEmail.Preferred__c,
			ContactPointEmail.IsCredential__c
		};
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.FILTER_VERIFIED_FALSE)) {
			builder.addConditions().add(new QueryBuilder.SimpleCondition(ContactPointEmail.Verified__c + ' = FALSE'));
		}

		if (selectorOptions.contains(Options.WITH_CONTACT)) {
			builder.addRelatedFields(ContactsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE}), 'Contact__r');
		}

		return builder;
	}

	public List<ContactPointEmail> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	public List<ContactPointEmail> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(ContactPointEmail.Id + ' in :ids'))
			.endConditions();
		return (List<ContactPointEmail>) Database.query(qb.toSoqlString());
	}

	public List<ContactPointEmail> selectByContact(Set<Id> contactIds, Set<Object> selectorOptions) {
		return selectByContactAndEmail(contactIds, null, selectorOptions);
	}

	public List<ContactPointEmail> selectByContactAndEmail(
		Set<Id> contactIds,
		List<String> emailAddresses,
		Set<Object> selectorOptions
	) {
		QueryBuilder.ConditionsManager cm = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(ContactPointEmail.Contact__c + ' in :contactIds'));

		if (emailAddresses != null) {
			cm.add(new QueryBuilder.SimpleCondition(ContactPointEmail.EmailAddress + ' in :emailAddresses'));
		}

		QueryBuilder qb = cm.endConditions();

		return (List<ContactPointEmail>) Database.query(qb.toSoqlString());
	}

	public List<ContactPointEmail> selectByParentId(Set<Id> parentIds, Set<Object> selectorOptions) {
		QueryBuilder.ConditionsManager cm = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(ContactPointEmail.ParentId + ' in :parentIds'));

		QueryBuilder qb = cm.endConditions();
		return (List<ContactPointEmail>) Database.query(qb.toSoqlString());
	}
}
