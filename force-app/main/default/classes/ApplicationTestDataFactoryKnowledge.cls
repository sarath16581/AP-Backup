/**
 * @description Test data factory specifically for Knowledge
 * @author Raghav Ravipati
 * @date 2024-05-09
 * @changelog
 */
@IsTest
public with sharing class ApplicationTestDataFactoryKnowledge {
	/**
	 * generate Critical Incidents Knowledge Articles
	 */
	public static List<Knowledge__kav> getCriticalIncidents(Integer count, Boolean generateIds) {
		List<Knowledge__kav> output = (List<Knowledge__kav>) ApplicationTestDataFactory.maybeGenerateIds(
			ApplicationTestDataFactory.populateSObjects(
				Schema.SObjectType.Knowledge__kav.SObjectType,
				new Map<SObjectField, Object>{
					Knowledge__kav.Title => 'Test Title %count%',
					Knowledge__kav.UrlName => 'Test-UrlName-%count%',
					Knowledge__kav.TimeToRemind__c => System.today(),
					Knowledge__kav.language => 'en_US',
					Knowledge__kav.recordTypeId => kavRecordType('Critical_Incident')
				},
				count
			),
			generateIds
		);

		return output;
	}
	/**
	 * generate PushEDM Knowledge Articles
	 */
	public static List<Knowledge__kav> getPushEDMs(Integer count, Boolean generateIds) {
		List<Knowledge__kav> output = (List<Knowledge__kav>) ApplicationTestDataFactory.maybeGenerateIds(
			ApplicationTestDataFactory.populateSObjects(
				Schema.SObjectType.Knowledge__kav.SObjectType,
				new Map<SObjectField, Object>{
					Knowledge__kav.Title => 'Test Title %count%',
					Knowledge__kav.UrlName => 'Test-UrlName-%count%',
					Knowledge__kav.TimeToRemind__c => System.today(),
					Knowledge__kav.language => 'en_US',
					Knowledge__kav.recordTypeId => kavRecordType('Push_EDM')
				},
				count
			),
			generateIds
		);

		return output;
	}

	/**
	 * generate Business Application Knowledge Articles
	 */
	public static List<Knowledge__kav> getBCAs(Integer count, Boolean generateIds) {
		List<Knowledge__kav> output = (List<Knowledge__kav>) ApplicationTestDataFactory.maybeGenerateIds(
			ApplicationTestDataFactory.populateSObjects(
				Schema.SObjectType.Knowledge__kav.SObjectType,
				new Map<SObjectField, Object>{
					Knowledge__kav.Title => 'Test Title %count%',
					Knowledge__kav.UrlName => 'Test-UrlName-%count%',
					Knowledge__kav.TimeToRemind__c => System.today(),
					Knowledge__kav.language => 'en_US',
					Knowledge__kav.recordTypeId => kavRecordType('Business_Credit_Account')
				},
				count
			),
			generateIds
		);

		return output;
	}

	/**
	 * generate BSP Application Knowledge Articles
	 */
	public static List<Knowledge__kav> getBSPs(Integer count, Boolean generateIds) {
		List<Knowledge__kav> output = (List<Knowledge__kav>) ApplicationTestDataFactory.maybeGenerateIds(
			ApplicationTestDataFactory.populateSObjects(
				Schema.SObjectType.Knowledge__kav.SObjectType,
				new Map<SObjectField, Object>{
					Knowledge__kav.Title => 'Test Title %count%',
					Knowledge__kav.UrlName => 'Test-UrlName-%count%',
					Knowledge__kav.TimeToRemind__c => System.today(),
					Knowledge__kav.language => 'en_US',
					Knowledge__kav.WhatdoItellcustomers__c => 'test',
					Knowledge__kav.recordTypeId => kavRecordType('BSP_Announcement')
				},
				count
			),
			generateIds
		);

		return output;
	}

	/**
	 * create Data Category Selection records for the given articles.
	 */
	public static List<Knowledge__DataCategorySelection> getDataCatogories(Integer count, Boolean generateIds, Id knowledgeArticleId) {
		List<Knowledge__DataCategorySelection> output = (List<Knowledge__DataCategorySelection>) ApplicationTestDataFactory.maybeGenerateIds(
			ApplicationTestDataFactory.populateSObjects(
				Schema.SObjectType.Knowledge__DataCategorySelection.SObjectType,
				new Map<SObjectField, Object>{
					Knowledge__DataCategorySelection.DataCategoryName => 'Pickup',
					Knowledge__DataCategorySelection.DataCategoryGroupName => 'StarTrack',
					Knowledge__DataCategorySelection.parentId => knowledgeArticleId
				},
				count
			),
			generateIds
		);

		return output;
	}
	/**
	 * get Knowledge article recordtype Id
	 */
	public static Id kavRecordType(String recordTypeName) {
		Id kavRecordTypeId;

		if (String.isNotBlank(recordTypeName)) {
			kavRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Knowledge__kav' AND DeveloperName = :recordTypeName].Id;
		}

		return kavRecordTypeId;
	}
}