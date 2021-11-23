/**
 * @description
 * Class to get trailhead recommendations based for the current user
 * This is an addon to Trail Tracker from SalesforceCloudServices (https://github.com/SalesforceCloudServices/Trailhead-Badge-and-Mix-Assignments-LWC)
 *
 */
/**
--------------------------------------- History --------------------------------------------------
23.01.2020    alex.volkov@auspost.com.au    Updated getRecommendedEntries with includeCompleted parameter
											and field constraints
**/

public without sharing class TH_Recommendations
{

	/**
	 * @description Determines the recommended entries for a given record
	 * @param recordId (Id) - id of the record we want to find recommendations for.
	 * @param includeCompleted Whether to include completed training
	 * @returns TH_Assignments.TrailheadEntry[] - list of trialhead entries
	 */
	@AuraEnabled(Cacheable=false)
	public static TH_Assignments.TrailheadEntry[] getRecommendedEntries(Id recordId, Boolean includeCompleted)
	{

		/** Final list of all the trailhead entries we will return */
		TH_Assignments.TrailheadEntry[] results = new TH_Assignments.TrailheadEntry[]
		{
		};

		/** current user id */
		Id userId = UserInfo.getUserId();

		/** collection of ids for all the badges to recommend */
		Set<Id> Badges = new Set<Id>();
		/** collection of ids for all the trailmixes to recommend */
		Set<Id> Trailmixes = new Set<Id>();

		/** collection of recommendations */
		List<TH_Recommendation__c> recommendations = new List<TH_Recommendation__c>();

		//-- determine all the recommendations
		if (recordId <> null)
		{
			/* Query all fields on the record as recommendations can be filtered on any field */
			String sObjName = recordId.getSobjectType().getDescribe().getName();
			String query = 'SELECT';
			Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap();
			for (String s : objectFields.keySet())
			{
				query += ' ' + s + ',';
			}
			/* Remove the trailing comma */
			if (query.substring(query.length() - 1, query.length()) == ',')
			{
				query = query.substring(0, query.length() - 1);
			}
			/* Add object name and WHERE clause and execute query*/
			query += ' FROM ' + sObjName + ' WHERE Id = :recordId';
			SObject lObject = Database.query(query);
			/* query and filter all relevant recommendations*/
			for (TH_Recommendation__c rec : [SELECT Badge__c, Trailmix__c, Field_Name_Constraint__c, Field_Value_Constraint__c FROM TH_Recommendation__c WHERE Object_API_Name__c = :sObjName])
			{
			//	system.debug(rec);
				if (rec.Field_Name_Constraint__c != null)
				{
					/* check if the constraint field on the object is in the allowed list*/
					if (rec.Field_Value_Constraint__c != null && rec.Field_Value_Constraint__c.split(',').contains((String)lObject.get(rec.Field_Name_Constraint__c)))
					{
						recommendations.add(rec);
					}
				}
				/* if there's no constraint, add to list straight away*/
				else
				{
					recommendations.add(rec);
				}
			}
		}
		else
		{
			recommendations = [SELECT Id, Badge__c, Trailmix__c, OwnerId FROM TH_Recommendation__c WHERE OwnerId = :userId];
		}

		//-- determine the ids of all the badges and trailmixes to be recommended
		for (TH_Recommendation__c thr : recommendations)
		{
			if (thr.Badge__c <> null) Badges.add(thr.Badge__c);
			if (thr.Trailmix__c <> null) Trailmixes.add(thr.Trailmix__c);
		}

		/** Final list of all the trailhead entries we will return */
		results = TH_Assignments.determineEntriesByTrailheadId(Badges, Trailmixes, userId, includeCompleted);

		return results;
	}
}