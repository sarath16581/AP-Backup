/**
 * @description Yet another Test data factory for Campaigns
 * @author Ashapriya Gadi
 * @date 2022-01-27
 * @group Tests
 * @tags mocking, apex mocks, tests, data factory, test data
 * @changelog
 * 2022-01-27 - Ashapriya Gadi - Added getCampaigns and getCampaignContactAssignments for campaignSurveyModule
 * 2022-06-11 - Prerna Rahangdale - Added the New method for generating the campaign Contact
 */
@IsTest
public with sharing class ApplicationTestDataFactoryCampaigns {
	//Added by Asha | For CampaignAssignCampaignMembersModule
	public static List<Campaign> getCampaigns(integer count, Boolean generateIds){
		return (List<Campaign>)maybeGenerateIds(populateSObjects(Campaign.SObjectType, new Map<SObjectField, Object> {
				Campaign.Name => 'Campaign Name %count%'
		}, count), generateIds);
	}
	//Added by Asha | For CampaignAssignCampaignMembersModule
	public static List<CampaignContactAssignment__c> getCampaignContactAssignments(integer count,Id AccountId,Id campaignId, Boolean generateIds){
		return (List<CampaignContactAssignment__c>)maybeGenerateIds(populateSObjects(CampaignContactAssignment__c.SObjectType, new Map<SObjectField, Object> {
				CampaignContactAssignment__c.Organisation__c => AccountId,
				CampaignContactAssignment__c.Campaign__c => campaignId
		}, count), generateIds);
	}
	
    //Added by Mathew | Campaign feedback replacement
    public static List<CampaignMember> getCampaignMembers(integer count, Boolean generateIds, Id campaignId, Id contactId){
        return (List<CampaignMember>)maybeGenerateIds(populateSObjects(CampaignMember.SObjectType, new Map<SObjectField, Object> {
            CampaignMember.CampaignId => campaignId,
            CampaignMember.ContactId => contactId
        }, count), generateIds);
    }

	public static List<CampaignContactAssignment__c> getCampaignContactAssignments(integer count,Set<Id> accountIds,Id campaignId, Boolean generateIds){
		return (List<CampaignContactAssignment__c>)maybeGenerateIds(populateSObjects(CampaignContactAssignment__c.SObjectType, new Map<SObjectField, Object> {
				CampaignContactAssignment__c.Organisation__c => accountIds,
				CampaignContactAssignment__c.Campaign__c => campaignId
		}, count), generateIds);
	}

	public static List<SObject> maybeGenerateIds(List<SObject> records, Boolean generateIds) {
		if(generateIds) {
			generateRecordIds(records);
		}
		
		return records;
	}
	public static void generateRecordIds(List<SObject> records) {
		for(SObject record : records) {
			record.Id = fflib_IDGenerator.generate(record.getSObjectType());
		}
	}
	public static List<SObject> populateSObjects(SObjectType sObjectType, Map<SObjectField, Object> fields, Integer count) {
		List<SObject> output = new List<SObject>();
		for(Integer i=0;i<count;i++) {
			SObject record = sObjectType.newSObject();
			for(SObjectField fieldName : fields.keySet()) {
				Object value = fields.get(fieldName);
				if(!String.isEmpty(String.valueOf(value)) && String.valueOf(value).contains('%count%')) {
					value = normaliseDataType(fieldName, String.valueOf(value).replace('%count%', String.valueOf(i+1)));
				
				}
				if(value instanceof List<Id>) {
					record.put(fieldName, ((List<Id>) value).get(i));
				} else if(value instanceof Set<Id>) {
					record.put(fieldName, (new List<Id>((Set<Id>)value)).get(i));
				} else {
					record.put(fieldName, value);
				}
			}
			output.add(record);
		}
		
		return output;
	}
	private static Object normaliseDataType(SObjectField fieldName, String value) {
		DescribeFieldResult result = fieldName.getDescribe();
		if(result.getType() == Schema.DisplayType.CURRENCY || result.getType() == Schema.DisplayType.DOUBLE || result.getType() == Schema.DisplayType.PERCENT) {
			return Decimal.valueOf(value);
		} else if(result.getType() == Schema.DisplayType.INTEGER) {
			return Integer.valueOf(value);
		} else if(result.getType() == Schema.DisplayType.LONG) {
			return Long.valueOf(value);
		} else {
			return value;
		}
	}
}