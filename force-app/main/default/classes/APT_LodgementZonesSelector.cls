/**
* @author Nasir Jawed
* @date 2022-07-25
* @description APT_LodgementZonesSelector helps to get values of all the fields with Zone Structure as "APPC".
* @changelog
*/
public virtual inherited sharing class APT_LodgementZonesSelector extends ApplicationSelector {
	public enum Options {
	}

	public static APT_LodgementZonesSelector newInstance() {
		return (APT_LodgementZonesSelector)Application.Selectors.newInstance(APT_LodgementZonesSelector.class);
	}
	public static APT_LodgementZonesSelector newInstance(Integer recordLimit) {
		return (APT_LodgementZonesSelector)Application.Selectors.newInstance(APT_LodgementZonesSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return APT_Lodgement_Zone__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			APT_Lodgement_Zone__c.Id,APT_Lodgement_Zone__c.APT_Postcode__c,
			APT_Lodgement_Zone__c.APT_Zone_Structure__c,APT_Lodgement_Zone__c.Name,APT_Lodgement_Zone__c.APTS_Ext_ID__c  
		};
	}

	/**
	* @description Run a simple query to get records based on LineItem 
	*/
	public virtual List<APT_Lodgement_Zone__c> selectByZoneStructure(Set<String> Prod, Set<String> searchLodgementPoint) {
		return selectByZoneStructure(Prod,searchLodgementPoint,new Set<Object>());
	}
    
	/**
	* @description Run a simple query to get records based on LineItem to get usage price tier
	*/
	public virtual List<APT_Lodgement_Zone__c> selectByZoneStructure(Set<String> Prod, Set<String> searchLodgementPoint, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions()
			.add(new QueryBuilder.SimpleCondition(APT_Lodgement_Zone__c.APT_Zone_Structure__c + ' = :Prod'))
			.add(new QueryBuilder.SimpleCondition(APT_Lodgement_Zone__c.APT_Postcode__c+ '=:searchLodgementPoint'))
			.endConditions();
		return (List<APT_Lodgement_Zone__c>)Database.query(qb.toSoqlString());
	}

}