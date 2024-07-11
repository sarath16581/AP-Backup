/**
 * @description Case Hand-off Mapping selector
 * @author Vasu Gorakati
 * @date 2024-06-18
 * @changelog
 * 2024-06-18 - Vasu Gorakati - Case Hand-off
 **/
public class CaseHandoffMappingSelector extends ApplicationSelector {
  public static CaseHandoffMappingSelector newInstance() {
	return (CaseHandoffMappingSelector) Application.Selectors.newInstance(
	  CaseHandoffMappingSelector.class
	);
  }

  public override SObjectType getSObjectType() {
	return CaseHandOffMapping__mdt.getSObjectType();
  }

  public override Set<SObjectField> getSObjectFieldList() {
	return new Set<SObjectField>{
	  CaseHandOffMapping__mdt.Id,
	  CaseHandOffMapping__mdt.BusinessUnit__c,
	  CaseHandOffMapping__mdt.UnifiedRecordTypeDeveloperName__c,
	  CaseHandOffMapping__mdt.Mapping__c
	};
  }

  public static CaseHandoffMappingSelector newInstance(
	Set<SObjectField> fieldOverrides
  ) {
	return (CaseHandoffMappingSelector) Application.Selectors.newInstance(
		CaseHandoffMappingSelector.class
	  )
	  .setFieldOverrides(fieldOverrides);
  }

  public virtual override QueryBuilder newQueryBuilder(
	Set<Object> selectorOptions
  ) {
	QueryBuilder builder = super.newQueryBuilder(selectorOptions);
	return builder;
  }

  /**
   * Returns case hand-off mapping based on business unit and case record type
   * @param businessUnits - business unit
   * @param recordTypeDeveloperNames  - case record types
   * @param selectorOptions - selector options to augment result set
   */

  public List<CaseHandOffMapping__mdt> selectByBusinesssUnitRecordType(
	Set<String> businessUnits,
	Set<String> recordTypeDeveloperNames,
	Set<Object> selectorOptions
  ) {
	QueryBuilder qb = newQueryBuilder(selectorOptions);
	QueryBuilder.ConditionsManager conditions = qb.addConditions();
	conditions.add(
	  new QueryBuilder.SimpleCondition(
		CaseHandOffMapping__mdt.BusinessUnit__c + ' IN :businessUnits'
	  )
	);
	if (recordTypeDeveloperNames != null) {
	  conditions.add(
		new QueryBuilder.SimpleCondition(
		  CaseHandOffMapping__mdt.UnifiedRecordTypeDeveloperName__c +
		  ' IN :recordTypeDeveloperNames'
		)
	  );
	}
	conditions.endConditions();

	return (List<CaseHandOffMapping__mdt>) Database.query(qb.toSoqlString());
  }

  public virtual override List<QueryBuilder.Order> getOrderBy() {
	return new List<QueryBuilder.Order>{
	  new QueryBuilder.Order('DeveloperName', 'Asc')
	};
  }
}