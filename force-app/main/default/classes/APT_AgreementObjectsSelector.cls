/* @author Sri Harsha
* @date 2022-04-22
* @group Selector
* @tag Selector
* @tag Apttus__APTS_Agreement__c
* @domain Apttus
* @description A very simple selector class for Apttus__APTS_Agreement__c to check expiration date
* @changelog:
* 2022-04-22 - Sri Harsha - Created
* 2022-05-30 - Seth Heang - updated getSObjectFieldList
* 2022-08-15 - Seth Heang - Added recordLimit, fieldOverrides to newInstance() method
* 2022-12-06 - Nasir Jawed - Added option RecordType and Proposal
* 2023-07-28 - Yatika Bansal - Added field Apttus__FF_Agreement_Number__c
*/
public virtual inherited sharing class APT_AgreementObjectsSelector extends ApplicationSelector {
	public enum Options {
		WITH_PROPOSAL,WITH_RECORDTYPE
	}

	public static APT_AgreementObjectsSelector newInstance() {
		return (APT_AgreementObjectsSelector)Application.Selectors.newInstance(APT_AgreementObjectsSelector.class);
	}
	public static APT_AgreementObjectsSelector newInstance(Integer recordLimit) {
		return (APT_AgreementObjectsSelector)Application.Selectors.newInstance(APT_AgreementObjectsSelector.class).setLimit(recordLimit);
	}
	/**
	* @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	*This approach removes data consistency and prevents possible caching of results
	*/
	public static APT_AgreementObjectsSelector newInstance(Integer recordLimit, Map<Schema.SObjectType,Set<Schema.SObjectField>> fieldOverrides) {
		APT_AgreementObjectsSelector selector = (APT_AgreementObjectsSelector)Application.Selectors.newInstance(APT_AgreementObjectsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Apttus__APTS_Agreement__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Apttus__APTS_Agreement__c.Id,Apttus__APTS_Agreement__c.Contract_Expiration_Date__c, Apttus__APTS_Agreement__c.Apttus__Account__c,
			Apttus__APTS_Agreement__c.Name,Apttus__APTS_Agreement__c.Apttus__Subtype__c,Apttus__APTS_Agreement__c.Included_Product_Lines__c,Apttus__APTS_Agreement__c.Document_Generated_by_Merge__c,Apttus__APTS_Agreement__c.APT_Contract_Type__c,
			Apttus__APTS_Agreement__c.APT_Is_Create_Contract_Batch_Job_Running__c,Apttus__APTS_Agreement__c.APT_Merge_Documents__c,Apttus__APTS_Agreement__c.APT_Remove_Standalone_Docs__c,Apttus__APTS_Agreement__c.APT_Is_Generate_Doc_Batch_Running__c,Apttus__APTS_Agreement__c.APT_New_Pricing__c,
			Apttus__APTS_Agreement__c.APT_SelectedContractAmendRenewCategory__c,Apttus__APTS_Agreement__c.APT_Require_Customer_Signature__c,Apttus__APTS_Agreement__c.Apttus_QPComply__RelatedProposalId__c,Apttus__APTS_Agreement__c.APT_Pricing_Category__c,Apttus__APTS_Agreement__c.Apttus__FF_Agreement_Number__c
		};
	}

	/**
	* @description Run a simple query to get records based on Apttus shopping cart config Id's
	*/
	public virtual List<Apttus__APTS_Agreement__c> selectByConfigId(Set<Id> configIds) {
		return selectByConfigId(configIds, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Apttus shopping cart config Id's
	*/
	public virtual List<Apttus__APTS_Agreement__c> selectByConfigId(Set<Id> configIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.ID + ' = :configIds'))
			.endConditions();
		return new List<Apttus__APTS_Agreement__c>((List<Apttus__APTS_Agreement__c>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_PROPOSAL)) {
			builder.addRelatedFields(APT_ProposalObjectsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Apttus_QPComply__RelatedProposalId__r');
		}
		if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'RecordType');
		}
		return builder;
	}

}