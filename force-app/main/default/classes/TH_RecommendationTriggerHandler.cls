/**
 * @author alexvolkov
 * @date 23/1/20
 * @description Handler class for TH_RecommendationTrigger
 */
/**
--------------------------------------- History --------------------------------------------------
23.01.2020    alex.volkov@auspost.com.au    Initial creation
**/

public with sharing class TH_RecommendationTriggerHandler
{
	/**
	 * @description Before Insert Handler
	 * @param pRecs New records
	 */
	public static void handleBeforeInsert(List<TH_Recommendation__c> pRecs)
	{
		validateRecords(pRecs);
	}

	/**
	 * @description Before Update Handler
	 * @param pRecs Updated records
	 * @param pOldRecs Old records
	 */
	public static void handleBeforeUpdate(List<TH_Recommendation__c> pRecs, Map<Id, TH_Recommendation__c> pOldRecs)
	{
		validateRecords(pRecs, pOldRecs);
	}

	/**
	 * @description Validate record values for new records
	 * @param pRecs Updated records
	 */
	private static void validateRecords(List<TH_Recommendation__c> pRecs)
	{
		validateRecords(pRecs, new Map<Id, TH_Recommendation__c>());
	}

	/**
 	* @description Record values validation logic. Checks Object and Field API Names for validity.
 	* @param pRecs Updated records
 	* @param pOldRecs Old records
 	*/
	private static void validateRecords(List<TH_Recommendation__c> pRecs, Map<Id, TH_Recommendation__c> pOldRecs)
	{
		/* Populate a map of all recommendations needing validation grouped by SObject the recommendations are displayed for*/
		Map<String, List<TH_Recommendation__c>> vSObjectNamesMap = new Map<String, List<TH_Recommendation__c>>();
		for (TH_Recommendation__c rec : pRecs)
		{
			String oldAPIName;
			String oldFieldName;
			/* if updating a record, get old values*/
			if (pOldRecs.get(rec.Id) != null)
			{
				oldAPIName = pOldRecs.get(rec.Id).Object_API_Name__c;
				oldFieldName = pOldRecs.get(rec.Id).Field_Name_Constraint__c;
			}
			/* if display parameters changed, add record for validation */
			if ((rec.Object_API_Name__c != null && rec.Object_API_Name__c != oldAPIName)
					|| (rec.Field_Name_Constraint__c != null && rec.Field_Name_Constraint__c != oldFieldName)
					)
			{
				if (!vSObjectNamesMap.containsKey(rec.Object_API_Name__c))
				{
					vSObjectNamesMap.put(rec.Object_API_Name__c, new List<TH_Recommendation__c>
					{
							rec
					});
				}
				else
				{
					vSObjectNamesMap.get(rec.Object_API_Name__c).add(rec);
				}
			}
		}
		/* if there is anything to validate, check SObject name on the record against the schema */
		if (!vSObjectNamesMap.isEmpty())
		{
			//add errors to records with non-existent SObject API names and remove from the map
			Map<String, Schema.SObjectType> vGlobalDesc = Schema.getGlobalDescribe();
			for (String objectName : vSObjectNamesMap.keySet())
			{
				if (!vGlobalDesc.containsKey(objectName))
				{
					for (TH_Recommendation__c rec : vSObjectNamesMap.get(objectName))
					{
						rec.addError('SObject with API name ' + objectName + ' not found');
					}
					vSObjectNamesMap.remove(objectName);
				}
			}
			if (!vSObjectNamesMap.isEmpty())
			//if anything left to validate, check field names
			{
				//describe the objects recommendations are linked to
				Map<String, Set<String>> vDescribeSObjectResults = new Map<String, Set<String>>();
				for (Schema.DescribeSObjectResult descResult : Schema.describeSObjects(new List<String>(vSObjectNamesMap.keySet())))
				{
					vDescribeSObjectResults.put(descResult.getName(), descResult.fields.getMap().keySet());
				}
				//check field names against field lists for each object
				for (String objectName : vSObjectNamesMap.keySet())
				{
					for (TH_Recommendation__c rec : vSObjectNamesMap.get(objectName))
					{
						if (rec.Field_Name_Constraint__c != null && !vDescribeSObjectResults.get(objectName).contains(rec.Field_Name_Constraint__c.toLowerCase()))
						{
							rec.addError('Field with API name ' + rec.Field_Name_Constraint__c + ' not found on object ' + objectName);
						}
					}
				}
			}
		}
	}
}