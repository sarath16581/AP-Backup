/**
* @author Disha Kariya
* @date 2020-08-21
* @group Selector
* @tag Selector
* @tag Networks
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-08-21 - Disha kariya - Created
* 2020-09-23 - Disha kariya - Added method to get Network by Org Id (WCC)
* 2021-03-15 - Seth Heang - Added method selectByNameAndOrgId(), selectByNetworkNameAndOrgIdAndNotID
* 2021-04-01 - Victor Cheng - Added method selectByMaxDistance()
* 2021-07-20 - Seth Heang - Added method selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING()
* 2021-07-27 - Naveen Rajanna - Added method selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING_OR_WORKCENTRE()
* 2022-03-23 - Ranjeewa Silva - Added methods to select by name
*/
public virtual inherited sharing class NetworksSelector extends ApplicationSelector {

	public enum Options {
		WITH_RECORDTYPE, WITH_OWNER
	}

    public static String sortOrder ='Desc';
    public static String sortfieldAPIName = 'CreatedDate';

	public static NetworksSelector newInstance() {
		return (NetworksSelector)Application.Selectors.newInstance(NetworksSelector.class);
	}
	public static NetworksSelector newInstance(Integer recordLimit) {
		return (NetworksSelector)Application.Selectors.newInstance(NetworksSelector.class).setLimit(recordLimit);
	}

    public static NetworksSelector newInstance(String sortField, String order){
        // store them anyway, and logic of whether or not to use them in getOrderBy()
		sortfieldAPIName = sortField;
		sortOrder = order;
        return (NetworksSelector)Application.Selectors.newInstance(NetworksSelector.class);
    }

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static NetworksSelector newInstance(Set<SObjectField> fieldOverrides) {
		NetworksSelector selector = (NetworksSelector)Application.Selectors.newInstance(NetworksSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static NetworksSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		NetworksSelector selector = (NetworksSelector)Application.Selectors.newInstance(NetworksSelector.class).setLimit(recordLimit);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}
    
    /**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *                          This approach removes data consistency and prevents possible caching of results
	 */
	public static NetworksSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		NetworksSelector selector = (NetworksSelector)Application.Selectors.newInstance(NetworksSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Network__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Network__c.Id, Network__c.Name, Network__c.OwnerId, Network__c.RecordTypeId, Network__c.AlwaysShown__c, Network__c.Email__c, Network__c.Contact_Facility__c, 
            Network__c.Email_1__c, Network__c.Email_2__c, Network__c.Email_3__c, Network__c.Email_4__c, Network__c.Email_5__c, Network__c.Fax_Number__c, 
            Network__c.Org_ID__c, Network__c.Org_Unit_Type__c, Network__c.Network_Address__c,Network__c.Post_Code__c,
            //Network__c.Id, Network__c.Name, Network__c.Org_ID__c, Network__c.Org_Unit_Type__c
            // Added by Raman for Process Builder replacement
            Network__c.Business_Hours__c
		};
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Network__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Network__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Network__c.Id + ' in :ids')).endConditions();
		return new Map<Id, Network__c>((List<Network__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on WCC
	 */
	public virtual Map<Id, Network__c> selectByOrgId(Set<String> orgIds) {
		return selectByOrgId(orgIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Network__c> selectByOrgId(Set<String> orgIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Network__c.Org_ID__c + ' in :orgIds')).endConditions();
		return new Map<Id, Network__c>((List<Network__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records with Exact Match on Network Name and Work Centre Code
	 */
	public virtual Map<Id, Network__c> selectByNameAndOrgId(Set<String> names, Set<String> orgIds) {
		return selectByNameAndOrgId(names, orgIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records with Exact Match on Network Name and Work Centre Code
	 */
	public virtual Map<Id, Network__c> selectByNameAndOrgId(Set<String> names, Set<String> orgIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
		.add(new QueryBuilder.SimpleCondition(Network__c.Name + ' in :names'))
		.add(new QueryBuilder.SimpleCondition(Network__c.Org_ID__c + ' in :orgIds')).endConditions();
		return new Map<Id, Network__c>((List<Network__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on:
	 * 	LIKE match: on Network Name
	 *  EXACT match: on Organisation Unit Type Code
	 *  EXACT match: Not Equal to the Network ID passed in
	 */
	public virtual Map<Id, Network__c> selectByNetworkNameAndOrgIdAndNotID(String name, Set<String> orgUnitCodes, Set<String> notIds) {
		return selectByNetworkNameAndOrgIdAndNotID(name, orgUnitCodes, notIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on:
	 * 	LIKE match: on Network Name
	 *  EXACT match: on Organisation Unit Type Code
	 *  EXACT match: Not Equal to the Network ID passed in
	 */
	public virtual Map<Id, Network__c> selectByNetworkNameAndOrgIdAndNotID(String name, Set<String> orgUnitCodes, Set<String> notIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
		.add(new QueryBuilder.LikeCondition(Network__c.Name).likeAnyBoth(name))
		.add(new QueryBuilder.SimpleCondition(Network__c.Org_Unit_Type__c + ' IN :orgUnitCodes'))
		.add(new QueryBuilder.SimpleCondition(Network__c.Id + ' NOT IN :notIds'))
		.endConditions();
		return new Map<Id, Network__c>((List<Network__c>)Database.query(qb.toSoqlString()));
	}

	public virtual List<Network__c> selectByMaxDistance(Integer distance, Decimal latitude, Decimal longitude, String networkFilter) {
		// new query string
		QueryBuilder qb = newQueryBuilder();

		// using geolocation
		String sDistance = ' DISTANCE( Geolocation__c, GEOLOCATION( ' + latitude + ', ' + longitude + ' ), \'km\' ) ';
		qb.addFields(new List<SObjectField> {Network__c.Org_ID__c, Network__c.Network_Address__c
				, Network__c.ORG_UNIT_ADDR_1__c, Network__c.ORG_UNIT_ADDR_2__c, Network__c.ORG_UNIT_ADDR_3__c
				, Network__c.Post_Code__c, Network__c.State__c, Network__c.Geolocation__Latitude__s, Network__c.Geolocation__Longitude__s});
		qb.addField(sDistance + ' dist');

		QueryBuilder.ConditionsManager cm = qb.conditionsManager;
		if(networkFilter != '') {
			cm.add(new QueryBuilder.SimpleCondition('Org_Unit_Type__c in (' + networkFilter + ')'));
		}
		//cm.add(new QueryBuilder.SimpleCondition('RecordType.DeveloperName = \'Retail_2\''));
		cm.add(new QueryBuilder.SimpleCondition(Network__c.Status__c + ' != \'Closed\''));
		cm.add(new QueryBuilder.SimpleCondition(sDistance + ' < ' + distance));
		cm.endConditions();

		qb.addOrderAsc(sDistance);
		System.debug('QB Network :: ' + qb.toSoqlString());
		return Database.query((qb.toSoqlString()));
	}

	// for overriding base class defaults
	public virtual override List<QueryBuilder.Order> getOrderBy() {

		if(!String.isEmpty(sortfieldAPIName) && !String.isEmpty(sortOrder))
			return new List<QueryBuilder.Order>{new QueryBuilder.Order(sortfieldAPIName, sortOrder)};
		else
			return new List<QueryBuilder.Order>();
	}


	/**
	 * @description Run a simple query to get records based on:
	 *  LIKE match: on Network Name
	 *  EXACT match: on Organisation Unit Type Code
	 *  EXACT match: Not Equal to the Network ID passed in
	 *  Condition: (1 AND 2 AND 3) OR (1 AND 3 AND 4)
	 */
	public virtual Map<Id, Network__c> selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING(String name, Set<String> orgUnitCodes, Set<String> notIds, String subString) {
		return selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING(name, orgUnitCodes, notIds, subString, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on:
	 *  LIKE match: on Network Name
	 *  EXACT match: on Organisation Unit Type Code
	 *  EXACT match: Not Equal to the Network ID passed in
	 *  Condition: (1 AND 2 AND 3) OR (1 AND 3 AND 4)
	 */
	public virtual Map<Id, Network__c> selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING(String name, Set<String> orgUnitCodes, Set<String> notIds, String subString, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
		.add(new QueryBuilder.LikeCondition(Network__c.Name).likeAnyBoth(name))
		.add(new QueryBuilder.SimpleCondition(Network__c.Org_Unit_Type__c + ' IN :orgUnitCodes'))
		.add(new QueryBuilder.SimpleCondition(Network__c.Id + ' NOT IN :notIds'))
		.add(new QueryBuilder.LikeCondition(Network__c.Name).likeAnyLeft(subString))
		.setConditionOrder('(1 AND 2 AND 3) OR (1 AND 3 AND 4)')
		.endConditions();
		return new Map<Id, Network__c>((List<Network__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on:
	 *  LIKE match: on Network Name
	 *  EXACT match: on Organisation Unit Type Code
	 *  EXACT match: Not Equal to the Network ID passed in
	 *  LIKE match: on Network Name ending with DWS
	 *  LIKE match: on Work Centre Code
	 *  Condition: (1 AND 2 AND 3) OR (1 AND 3 AND 4) OR (2 AND 3 AND 5) OR (3 AND 4 AND 5)
	 */
	public virtual Map<Id, Network__c> selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING_OR_WORKCENTRE(String name, Set<String> orgUnitCodes, Set<String> notIds, String subString) {
		return selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING_OR_WORKCENTRE(name, orgUnitCodes, notIds, subString, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on:
	 *  LIKE match: on Network Name
	 *  EXACT match: on Organisation Unit Type Code
	 *  EXACT match: Not Equal to the Network ID passed in
	 *  LIKE match: on Network Name ending with DWS
	 *  LIKE match: on Work Centre Code
	 *  Condition: (1 AND 2 AND 3) OR (1 AND 3 AND 4) OR (2 AND 3 AND 5) OR (3 AND 4 AND 5)
	 */
	public virtual Map<Id, Network__c> selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING_OR_WORKCENTRE(String name, Set<String> orgUnitCodes, Set<String> notIds, String subString, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
		.add(new QueryBuilder.LikeCondition(Network__c.Name).likeAnyBoth(name))
		.add(new QueryBuilder.SimpleCondition(Network__c.Org_Unit_Type__c + ' IN :orgUnitCodes'))
		.add(new QueryBuilder.SimpleCondition(Network__c.Id + ' NOT IN :notIds'))
		.add(new QueryBuilder.LikeCondition(Network__c.Name).likeAnyLeft(subString))
		.add(new QueryBuilder.LikeCondition(Network__c.Org_ID__c).likeAnyBoth(name))
		.setConditionOrder('(1 AND 2 AND 3) OR (1 AND 3 AND 4) OR (2 AND 3 AND 5) OR (3 AND 4 AND 5)')
		.endConditions();
		return new Map<Id, Network__c>((List<Network__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Query Network records by name.
	 * @param names Network names to select (exact match)
	 *
	 * @return list of networks matching the names supplied
	 */
	public List<Network__c> selectByName(Set<String> names) {
		return selectByName(names, new Set<Object>());
	}

	/**
	 * @description Query Network records by name.
	 * @param names Network names to select (exact match)
	 * @param selectorOptions additional selector options
	 *
	 * @return list of networks matching the names supplied
	 */
	public List<Network__c> selectByName(Set<String> names, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Network__c.Name + ' in :names')).endConditions();
		return (List<Network__c>)Database.query(qb.toSoqlString());
	}
	
	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
		}

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
		}

		return builder;
	}

}