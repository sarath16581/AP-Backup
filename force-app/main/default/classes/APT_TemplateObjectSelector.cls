/**
* @author Nasir Jawed
* @date 2022-04-27
* @description APT_Templatecontroller helps to get id of all the Template.
* @changelog
  2022-12-06 - Nasir Jawed - Added method selectByRefrenceId 
*/
public virtual inherited sharing class APT_TemplateObjectSelector extends ApplicationSelector {
	public enum Options {
	}

	public static APT_TemplateObjectSelector newInstance() {
		return (APT_TemplateObjectSelector)Application.Selectors.newInstance(APT_TemplateObjectSelector.class);
	}
	public static APT_TemplateObjectSelector newInstance(Integer recordLimit) {
		return (APT_TemplateObjectSelector)Application.Selectors.newInstance(APT_TemplateObjectSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return Apttus__APTS_Template__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Apttus__APTS_Template__c.Id,Apttus__APTS_Template__c.Name,Apttus__APTS_Template__c.Apttus__ReferenceId__c,
			Apttus__APTS_Template__c.Apttus__Category__c 
				};
					}

	/**
	* @description Run a simple query to get records based on Apttus shopping cart config Id's
	*/
	public virtual Map<Id, Apttus__APTS_Template__c> selectByConfigId(Set<String> configIds) {
		return selectByConfigId(configIds, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Apttus shopping cart config Id's
	*/
	public virtual Map<Id, Apttus__APTS_Template__c> selectByConfigId(Set<string> configIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus__APTS_Template__c.Name + ' = :configIds'))
			.endConditions();
		return new Map<Id, Apttus__APTS_Template__c>((List<Apttus__APTS_Template__c>)Database.query(qb.toSoqlString()));
	}


		
	/**
	* @description Run a simple query to get records based on Apttus shopping cart reference Id's
	*/
	public virtual List<Apttus__APTS_Template__c> selectByRefrenceId(List<String> refrenceIds) {
		return selectByRefrenceId(refrenceIds, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Apttus shopping cart reference Id's
	*/
	public virtual List<Apttus__APTS_Template__c> selectByRefrenceId(List<string> refrenceIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus__APTS_Template__c.Apttus__ReferenceId__c + ' IN :refrenceIds'))
			.endConditions();
		return new List<Apttus__APTS_Template__c>((List<Apttus__APTS_Template__c>)Database.query(qb.toSoqlString()));
	}
}