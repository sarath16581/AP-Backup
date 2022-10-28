/* @author Seth Heang
 * @date 2022-06-28
 * @group Tests
 * @tag Apttus_CMConfig__AgreementProductAttributeValue__c
 * @domain Apttus
 * @description A very simple selector class that sits in the Apttus domain
 * @changelog
 * 2022-06-28 - Seth Heang - Created
 * 2022-08-15 - Seth Heang - Added recordLimit, fieldOverrides to newInstance() method
 */
public with sharing class AgreementProductAttributeValuesSelector extends ApplicationSelector{
    public enum Options {
	}
	public static AgreementProductAttributeValuesSelector newInstance() {
		return (AgreementProductAttributeValuesSelector)Application.Selectors.newInstance(AgreementProductAttributeValuesSelector.class);
	}

	/**
	* @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	*						  This approach removes data consistency and prevents possible caching of results
	*/
	public static AgreementProductAttributeValuesSelector newInstance(Integer recordLimit, Map<Schema.SObjectType,Set<Schema.SObjectField>> fieldOverrides) {
		AgreementProductAttributeValuesSelector selector = (AgreementProductAttributeValuesSelector)Application.Selectors.newInstance(AgreementProductAttributeValuesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	
	public virtual override SObjectType getSObjectType() {
		return Apttus_CMConfig__AgreementProductAttributeValue__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Apttus_CMConfig__AgreementProductAttributeValue__c.Id, Apttus_CMConfig__AgreementProductAttributeValue__c.Name, Apttus_CMConfig__AgreementProductAttributeValue__c.SAP_Weight_Rounding__c, 
			Apttus_CMConfig__AgreementProductAttributeValue__c.APT_Cubic_Status__c, Apttus_CMConfig__AgreementProductAttributeValue__c.SAP_Cubic_Conversion_Factor__c, Apttus_CMConfig__AgreementProductAttributeValue__c.SAP_Rating_Plan_DWT_Conversion_Factor__c,
			Apttus_CMConfig__AgreementProductAttributeValue__c.APT_Customer_Tier__c, Apttus_CMConfig__AgreementProductAttributeValue__c.APT_Transit_Cover_Type__c, Apttus_CMConfig__AgreementProductAttributeValue__c.APT_Price_Point__c,
			Apttus_CMConfig__AgreementProductAttributeValue__c.APT_Min_Transit_Cover_Amount_Per_Article__c, Apttus_CMConfig__AgreementProductAttributeValue__c.APT_Cubic_Factor__c
		};
	}
	
}