/**
 * @author alexvolkov
 * @date 27/2/20
 * @description Service class containing Data Dictionary related methods
 * --------------------------------------- History --------------------------------------------------
	27.02.2020		alex.volkov@auspost.com.au		Initial creation
	03.03.2020		alex.volkov@auspost.com.au		Added method getFieldTripDetails
	04.03.2020		alex.volkov@auspost.com.au		Added method getFieldUsageDetails
**/
public with sharing class BG_DataDictionaryService
{
	/**
	 * @description Retrieves field metadata details available on FieldDefinition object and via Tooling API
	 * @param pObjectAPIName Object API Name
	 * @param pFieldAPIName Field API Name
	 * @return FieldDetails
	 */
	@AuraEnabled(Cacheable=true)
	public static FieldDetails getFieldDetails(String pObjectAPIName, String pFieldAPIName)
	{
		List<FieldDefinition> vFieldDefList = [SELECT LastModifiedById, LastModifiedBy.Name, LastModifiedDate, ComplianceGroup, DeveloperName, Label, DataType, Description, SecurityClassification, BusinessOwnerId, BusinessOwner.Name FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :pObjectAPIName AND QualifiedApiName = :pFieldAPIName LIMIT 1];
		//the vFieldDef.isEmpty() check before executing the tooling query is needed to avoid redundant callouts and risks of SOQL injections in callout query
		if(!vFieldDefList.isEmpty())
		{
			FieldDefinition vFieldDef = vFieldDefList[0];
			/** Certain metadata is only available via Tooling API - CreatedBy, CreatedDate, HelpText */
			ToolingResponse vToolingData =  (ToolingResponse)JSON.deserialize(executeToolingQuery('SELECT CreatedById, CreatedBy.Name, CreatedDate, InlineHelpText FROM CustomField WHERE EntityDefinition.QualifiedApiName = \'' + pObjectAPIName + '\' AND DeveloperName = \'' + vFieldDef.DeveloperName + '\'').getBody(), ToolingResponse.class);
			FieldDetails vRes = new FieldDetails();
			vRes.FieldLabel = vFieldDef.Label;
			vRes.Description = vFieldDef.Description;
			vRes.DataType = vFieldDef.DataType;
			vRes.ComplianceCategorization = vFieldDef.ComplianceGroup;
			vRes.DataOwnerLink = vFieldDef.BusinessOwnerId;
			vRes.DataOwnerName = vFieldDef.BusinessOwner.Name;
			vRes.DataSensitivityLevel = vFieldDef.SecurityClassification;
			vRes.LastModifiedLink = vFieldDef.LastModifiedById;
			vRes.LastModifiedName = vFieldDef.LastModifiedBy.Name;
			vRes.LastModifiedDate = vFieldDef.LastModifiedDate;
			/** If Tooling API call returned anything (it might not, e.g. for standard fields) */
			if (!vToolingData.records.isEmpty())
			{
				FieldDescRecord lRec = vToolingData.records[0];
				vRes.HelpText = lRec.InlineHelpText;
				vRes.CreatedDate = lRec.CreatedDate;
				vRes.CreatorLink = lRec.CreatedById;
				vRes.CreatorName = lRec.CreatedBy.Name;
			}
			return vRes;
		}
		else
		{
			return null;
		}
	}

	/**
	 * @description Retrieves Field Trip reports results for a particular field
	 * @param pObjectAPIName Object API Name
	 * @param pFieldAPIName Field API Name
	 * @return List<Field_Trip__Field_Analysis__c>
	 */
	@AuraEnabled(Cacheable=true)
	public static List<Field_Trip__Field_Analysis__c> getFieldTripDetails(String pObjectAPIName, String pFieldAPIName)
	{
		return [SELECT Id, CreatedDate, Field_Trip__Populated_On__c, Field_Trip__Populated_On_Percent__c, Field_Trip__Object_Analysis__r.Name FROM Field_Trip__Field_Analysis__c WHERE Field_Trip__Object_Analysis__r.Field_Trip__Object_Name__c = :pObjectAPIName AND Name = :pFieldAPIName ORDER BY CreatedDate DESC LIMIT 10000];
	}

	/**
	 * @description Retrieves Field Dependencies available via Metadata Dependency API for a given field
	 * @param pObjectAPIName Object API Name
	 * @param pFieldAPIName Field API Name
	 * @return List<DependencyRecord>
	 */
	@AuraEnabled(Cacheable=true)
	public static List<DependencyRecord> getFieldUsageDetails(String pObjectAPIName, String pFieldAPIName)
	{
		List<FieldDefinition> vFieldDefList = [SELECT DurableId FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :pObjectAPIName AND QualifiedApiName = :pFieldAPIName LIMIT 1];
		if(!vFieldDefList.isEmpty())
		{
			// Durable Id starts with object name, need only the actual Id
			String vDurableId = vFieldDefList[0].DurableId.substringAfterLast('.');
			// Run a query against Metadata Dependency API
			String vQuery = 'SELECT MetadataComponentId, MetadataComponentName, MetadataComponentType FROM MetadataComponentDependency WHERE RefMetadataComponentId = \'' + vDurableId + '\'';
			Dependency vResponse = (Dependency)JSON.deserialize(executeToolingQuery(vQuery).getBody(), Dependency.class);
			return vResponse.records;
		}
		else
		{
			return null;
		}
	}

	/**
	* @description Callout to Tooling API to execute a query
	* @param pQuery Query to execute
	* @return HttpResponse
	*/
	private static HttpResponse executeToolingQuery(String pQuery)
	{
		HttpRequest vReq = new HttpRequest();
		vReq.setHeader('Content-Type', 'application/json');
		vReq.setEndpoint('callout:Salesforce_API' + '/v47.0/tooling/query/?q=' + EncodingUtil.urlEncode(pQuery, 'UTF-8'));
		vReq.setMethod('GET');
		Http vHttp = new Http();
		return vHttp.send(vReq);
	}

	private class ToolingResponse
	{
		List<FieldDescRecord> records;
	}

	private class FieldDescRecord
	{
		CreatedByUser CreatedBy;
		Id CreatedById;
		Datetime CreatedDate;
		String InlineHelpText;
	}

	private class CreatedByUser
	{
		String Name;
	}

	public class FieldDetails
	{
		@AuraEnabled public String FieldLabel{get;set;}
		@AuraEnabled public String DataType{get;set;}
		@AuraEnabled public String Description{get;set;}
		@AuraEnabled public String HelpText{get;set;}
		@AuraEnabled public String DataOwnerLink{get;set;}
		@AuraEnabled public String DataOwnerName{get;set;}
		@AuraEnabled public String CreatorLink{get;set;}
		@AuraEnabled public String CreatorName{get;set;}
		@AuraEnabled public Datetime CreatedDate{get;set;}
		@AuraEnabled public String LastModifiedLink{get;set;}
		@AuraEnabled public String LastModifiedName{get;set;}
		@AuraEnabled public Datetime LastModifiedDate{get;set;}
		@AuraEnabled public String DataSensitivityLevel{get;set;}
		@AuraEnabled public String ComplianceCategorization{get;set;}
	}

	private class Dependency
	{
		List<DependencyRecord> records;
	}

	public class DependencyRecord
	{
		@AuraEnabled public Id MetadataComponentId{get;set;}
		@AuraEnabled public String MetadataComponentName{get;set;}
		@AuraEnabled public String MetadataComponentType{get;set;}
	}
}