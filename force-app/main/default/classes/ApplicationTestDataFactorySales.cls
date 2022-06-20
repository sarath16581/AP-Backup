/**
 * @description 
 * @author Dattaraj Deshmukh
 * @date 2020-06-15
 * @group Tests
 * @tags mocking, apex mocks, tests, data factory, test data
 * @changelog
 * 2022-06-04 - Dattaraj Deshmukh - Created - getDealSupportRequestMilestones method for User story, SM-604
 */
@IsTest
public with sharing class ApplicationTestDataFactorySales {
    

    /**
    * @desc: Called from DealSupportRequstMilestoneSelector_Test, DealSpprtReqsMilestonesTrackModule_Test.
    *        Creates Deal Support Request milestone record for a DSR
    */
    public static List<DealSupportRequestMilestone__c> getDealSupportRequestMilestones(integer count, Id dealSupportRequestId, Boolean generateIds){
		return (List<DealSupportRequestMilestone__c>)maybeGenerateIds(populateSObjects(DealSupportRequestMilestone__c.SObjectType, new Map<SObjectField, Object> {
			DealSupportRequestMilestone__c.DealSupportRequest__c => dealSupportRequestId
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