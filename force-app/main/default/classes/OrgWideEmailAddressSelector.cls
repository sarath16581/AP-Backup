/* @author Seth Heang
 * @date 2020-12-18
 * @group Selector
 * @tag Selector
 * @tag OrgWideEmailAddress
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 */
public virtual inherited sharing class OrgWideEmailAddressSelector extends ApplicationSelector {
    public static OrgWideEmailAddressSelector newInstance() {
        return (OrgWideEmailAddressSelector)Application.Selectors.newInstance(OrgWideEmailAddressSelector.class);
    }
    public static OrgWideEmailAddressSelector newInstance(Integer recordLimit) {
        return (OrgWideEmailAddressSelector)Application.Selectors.newInstance(OrgWideEmailAddressSelector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return OrgWideEmailAddress.getSObjectType();
    }    
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            OrgWideEmailAddress.Id,OrgWideEmailAddress.DisplayName, OrgWideEmailAddress.Address
        };
    }

	/**
	 * @description Run a simple query to get records based on developer name
	 */
	public virtual Map<Id, OrgWideEmailAddress> selectByAddress(String addr) {
		return selectByAddress(addr, new Set<Object>());
    }
    
    /**
     * @description Run a simple query to get records based on developer name
     */
    public virtual Map<Id, OrgWideEmailAddress> selectByAddress(String addr, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
        .add(new QueryBuilder.SimpleCondition(OrgWideEmailAddress.Address + ' =: addr '))
        .endConditions();
        return new Map<Id, OrgWideEmailAddress>((List<OrgWideEmailAddress>)Database.query(qb.toSoqlString()));
    }
}