/**
 * @author Hasantha Liyanage
 * @date 2023-10-02
 * @group selector
 * @domain BAM
 * @description BAMContactRole__c selector
 * @changelog
 * 2023-10-02 - Hasantha Liyanage  - Created
 */
public virtual inherited sharing class BAMContactApplicationsSelector extends ApplicationSelector {
	public enum Options {
		WITH_CONTACT
	}
	public static BAMContactApplicationsSelector newInstance() {
		return (BAMContactApplicationsSelector)Application.Selectors.newInstance(BAMContactApplicationsSelector.class);
	}

	public virtual override SObjectType getSObjectType() {
		return BAMContactApplication__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				BAMContactApplication__c.Id, BAMContactApplication__c.Name, BAMContactApplication__c.Contact__c
		};
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		if (selectorOptions.contains(Options.WITH_CONTACT)) {
			builder.addRelatedFields(ContactsSelector.newInstance().newQueryBuilder(), 'Contact__r');
		}
		return builder;
	}
}