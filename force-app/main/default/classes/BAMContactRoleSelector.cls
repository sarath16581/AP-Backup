/**
 * @author Hasantha Liyanage
 * @date 2023-09-27
 * @group selector
 * @domain BAM
 * @description BAMContactRole__c selector
 * @changelog
 * 2023-09-27 - Hasantha Liyanage  - Created
 */
public virtual inherited sharing class BAMContactRoleSelector extends ApplicationSelector {

	public enum Options {
		WITH_CONTACT_APPLICATION
	}
	public static BAMContactRoleSelector newInstance() {
		return (BAMContactRoleSelector)Application.Selectors.newInstance(BAMContactRoleSelector.class);
	}

	public virtual override SObjectType getSObjectType() {
		return BAMContactRole__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				BAMContactRole__c.Id, BAMContactRole__c.Name, BAMContactRole__c.ContactApplication__c, BAMContactRole__c.ApplicationRole__r.Name
		};
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		if (selectorOptions.contains(Options.WITH_CONTACT_APPLICATION)) {
			builder.addRelatedFields(BAMContactApplicationsSelector.newInstance()
					.newQueryBuilder(new Set<Object>{BAMContactApplicationsSelector.Options.WITH_CONTACT}), 'ContactApplication__r');
		}
		return builder;
	}

	public virtual List<BAMContactRole__c> selectRolesByRoleAndOrgId(Set<String> roles, Set<Id> orgIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions.add(new QueryBuilder.SimpleCondition('ApplicationRole__r.Role__c in : roles' ));
		conditions.add(new QueryBuilder.SimpleCondition('ContactApplication__r.Contact__r.AccountId in : orgIds' ));
		conditions.add(new QueryBuilder.CompareCondition(BAMContactRole__c.Status__c ).eq('Active'));
		conditions.add(new QueryBuilder.CompareCondition('ContactApplication__r.Status__c').eq('Active'));
		conditions.add(new QueryBuilder.CompareCondition('ContactApplication__r.Contact__r.Status__c').eq('Active'));
		conditions.add(new QueryBuilder.CompareCondition('ContactApplication__r.Application__r.AppKey__c').eq(BAMUserUtility.ACCESS_MANAGEMENT_APP_KEY));
		String soql = conditions.endConditions().toSoqlString();
		system.debug(soql);
		return (List<BAMContactRole__c>)Database.query(soql);
	}

}