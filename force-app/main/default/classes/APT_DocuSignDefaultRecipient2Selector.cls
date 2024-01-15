/**
Description: This apex class selector for Apttus_DocuApi__DocuSignDefaultRecipient2__c object
Created By: Nasir Jawed
Created Date: 1725-03-2023
Last Modified By:
Last Modified Date:
@changelog:
*/

public with sharing class APT_DocuSignDefaultRecipient2Selector extends ApplicationSelector{

	public enum Options{
		WITH_RECORDTYPE
	}
	public static APT_DocuSignDefaultRecipient2Selector newInstance(){
		return (APT_DocuSignDefaultRecipient2Selector)Application.Selectors.newInstance(APT_DocuSignDefaultRecipient2Selector.class);
	}
	public static APT_DocuSignDefaultRecipient2Selector newInstance(Integer recordLimit){
		return (APT_DocuSignDefaultRecipient2Selector)Application.Selectors.newInstance(APT_DocuSignDefaultRecipient2Selector.class).setLimit(recordLimit);
	}
	public virtual override SObjectType getSObjectType(){
		return Apttus_DocuApi__DocuSignDefaultRecipient2__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList(){
		return new Set<SObjectField> {
			Apttus_DocuApi__DocuSignDefaultRecipient2__c.Id,Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__UserId__c,Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__Email__c,
			Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__RecipientType__c,Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__EmailTemplateUniqueName__c,Apttus_DocuApi__DocuSignDefaultRecipient2__c.recordTypeId,
			Apttus_DocuApi__DocuSignDefaultRecipient2__c.APT_Docusign_Recipient_Type__c,Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__SigningOrder__c,Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__Note__c ,
			Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__ContactId__c,Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__ReadOnlyFirstName__c,Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__ReadOnlyLastName__c,
			Apttus_DocuApi__DocuSignDefaultRecipient2__c.APT_Name__c,Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__ReadOnlyEmail__c
		};
	}

	/**
	*@description Run a simple query to get records based on Id's
	*/
	public virtual list<Apttus_DocuApi__DocuSignDefaultRecipient2__c> selectById(Set<Id> ids){
		return selectById(ids, new Set<Object>());
	}

	/**
	*@description Run a simple query to get records based on Id's
	*/

	public virtual list<Apttus_DocuApi__DocuSignDefaultRecipient2__c> selectById(Set<Id> ids, Set<Object> selectorOptions){
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Apttus_DocuApi__DocuSignDefaultRecipient2__c.Id  + ' in :ids')).endConditions();
		return new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>((List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>)Database.query(qb.toSoqlString()));
	}
	/**
	*@description Run a simple query to get records based on Agreement Id's
	*/
	public virtual list<Apttus_DocuApi__DocuSignDefaultRecipient2__c> selectByAgreementId(Set<Id> ids){
		return selectByAgreementId(ids, new Set<Object>());
	}

	/**
	*@description Run a simple query to get records based on Agreement Id's
	*/

	public virtual list<Apttus_DocuApi__DocuSignDefaultRecipient2__c> selectByAgreementId(Set<Id> ids, Set<Object> selectorOptions){
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_CMDSign__AgreementId__c  + ' in :ids')).endConditions();
		return new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>((List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions){
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
		}
		return builder;
	}
}