/***
* @description Selector class for Auspost_Vendors_Email_Address__mdt custom emtadata type
* @author Deepak Kemidi
* @date 2022-04-18
* @changelog
*/
public virtual inherited sharing class AuspostVendorEmailSelector extends ApplicationSelector {
	public enum Options { }

	public static AuspostVendorEmailSelector newInstance() {
		return newInstance(0, new Set<SObjectField>());
	}

	public static AuspostVendorEmailSelector newInstance(Integer recordLimit) {
		return newInstance(recordLimit, new Set<SObjectField>());
	}

	public static AuspostVendorEmailSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		return newInstance(recordLimit, new Map<SObjectType, Set<SObjectField>>{Auspost_Vendors_Email_Address__mdt.SObjectType => fieldOverrides});
	}

	public static AuspostVendorEmailSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		AuspostVendorEmailSelector selector = (AuspostVendorEmailSelector)Application.Selectors.newInstance(AuspostVendorEmailSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return Auspost_Vendors_Email_Address__mdt.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Auspost_Vendors_Email_Address__mdt.Id, Auspost_Vendors_Email_Address__mdt.Vendor_Email__c
		};
	}


	//Query to get records based on Names
	public List<Auspost_Vendors_Email_Address__mdt> selectByName(Set<String> recordNames) {
		return selectByName(recordNames, new Set<Object>());
	}

	public List<Auspost_Vendors_Email_Address__mdt> selectByName(Set<String> recordNames, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Auspost_Vendors_Email_Address__mdt.DeveloperName + ' in :recordNames')).endConditions();
		return (List<Auspost_Vendors_Email_Address__mdt>)Database.query(qb.toSoqlString());
	}

	// Query to get all records and their email addresses
	public List<Auspost_Vendors_Email_Address__mdt> selectAllRecords() {
		QueryBuilder qb = newQueryBuilder().addFields(new Set<SObjectField>{ Auspost_Vendors_Email_Address__mdt.Id, Auspost_Vendors_Email_Address__mdt.Vendor_Email__c });
		return (List<Auspost_Vendors_Email_Address__mdt>)Database.query(qb.toSoqlString());
	}

	public List<Auspost_Vendors_Email_Address__mdt> selectByVendorEmails(Set<String> vendorEmails) {
		return selectByVendorEmails(vendorEmails, new Set<Object>());
	}

	//Query to get records based on Vendor Emails
	public List<Auspost_Vendors_Email_Address__mdt> selectByVendorEmails(Set<String> vendorEmails, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Auspost_Vendors_Email_Address__mdt.Vendor_Email__c + ' in :vendorEmails')).endConditions();
		return (List<Auspost_Vendors_Email_Address__mdt>)Database.query(qb.toSoqlString());
	}

	public virtual override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order('DeveloperName', 'Asc')};
	}
}
