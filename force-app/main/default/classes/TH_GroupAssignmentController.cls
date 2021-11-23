/**
 * @author alexvolkov
 * @date 12/2/20
 * @description Controller for TH_GroupAssignment component (trailhead modules assignment to groups)
 */

/**
--------------------------------------- History --------------------------------------------------
12.02.2020    alex.volkov@auspost.com.au    Initial creation
**/

public with sharing class TH_GroupAssignmentController implements Queueable
{
	private List<Id> groupIds;
	private List<Id> badgeIds;
	private List<Id> mixIds;
	private Datetime dueDate;

	public static Boolean RUN_RECURSIVELY = true;

	/**
	 * @description Constructor for initialization as a Queueable
	 * @param pGroupIds List of groups to assign training to
	 * @param pBadgeIds List of badges for assignment
	 * @param pMixIds List of trailmixes for assignment
	 * @param pDueDate Training due date
	 */
	public TH_GroupAssignmentController(List<Id> pGroupIds, List<Id> pBadgeIds, List<Id> pMixIds, Datetime pDueDate)
	{
		this.groupIds = pGroupIds;
		this.badgeIds = pBadgeIds;
		this.mixIds = pMixIds;
		this.dueDate = pDueDate;
	}

	/**
	 * @description Main assignment method
	 * @param pGroupIds List of groups to assign training to
	 * @param pBadgeIds List of badges for assignment
	 * @param pMixIds List of trailmixes for assignment
	 * @param pDueDate Training due date
	 */
	@AuraEnabled
	public static void assignTrainingToGroups(List<Id> pGroupIds, List<Id> pBadgeIds, List<Id> pMixIds, Datetime pDueDate)
	{
		if (!pGroupIds.isEmpty())
		{
			/** Pick the first group for processing, leave everything else for recursive runs */
			Id vCurrentGroupId = pGroupIds[0];
			pGroupIds.remove(0);
			Set<Id> vUserIds = new Set<Id>();
			for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :vCurrentGroupId])
			{
				/** Split the group members into 2 sets - users and nested groups */
				if (((String) gm.UserOrGroupId).startsWith('005'))
				{
					vUserIds.add(gm.UserOrGroupId);
				}
				/** Add nested groups to the processing list */
				else if (((String) gm.UserOrGroupId).startsWith('00G') && !pGroupIds.contains(gm.UserOrGroupId))
				{
					pGroupIds.add(gm.UserOrGroupId);
				}
			}
			if (!vUserIds.isEmpty())
			{
				/**Remove inactive or non-standard users */
				for (User u: [SELECT IsActive, UserType FROM User WHERE Id IN :vUserIds])
				{
					if (!u.IsActive || u.UserType != 'Standard')
					{
						vUserIds.remove(u.Id);
					}
				}
				List<SObject> vListToInsert = new List<SObject>();
				/** Add badges */
				if (!pBadgeIds.isEmpty())
				{
					Map<Id, Set<Id>> vBadgeMap = new Map<Id, Set<Id>>();
					for (Id badgeId : pBadgeIds)
					{
						vBadgeMap.put(badgeId, vUserIds);
					}
					/** Remove already assigned or completed badges*/
					for (trailheadapp__User_Badge__c bAsgs : [SELECT trailheadapp__Badge__c, trailheadapp__User__c FROM trailheadapp__User_Badge__c WHERE trailheadapp__Badge__c IN :pBadgeIds AND trailheadapp__User__c IN :vUserIds])
					{
						vBadgeMap.get(bAsgs.trailheadapp__Badge__c).remove(bAsgs.trailheadapp__User__c);
					}
					/** Add everything that's left */
					for (Id badgeId : vBadgeMap.keySet())
					{
						for (Id userId : vBadgeMap.get(badgeId))
						{
							vListToInsert.add(new trailheadapp__User_Badge__c(trailheadapp__Badge__c = badgeId, trailheadapp__User__c = userId, trailheadapp__Due_Date__c = pDueDate));
						}
					}
				}
				/** Add trailmixes */
				if (!pMixIds.isEmpty())
				{
					Map<Id, Set<Id>> vMixMap = new Map<Id, Set<Id>>();
					for (Id MixId : pMixIds)
					{
						vMixMap.put(MixId, vUserIds);
					}

					/** Remove already assigned, completed and pending assignment trailmixes */
					for (trailheadapp__User_Trailmix__c mAsgs : [SELECT trailheadapp__Trailmix__c, trailheadapp__User__c FROM trailheadapp__User_Trailmix__c WHERE trailheadapp__Trailmix__c IN :pMixIds AND trailheadapp__User__c IN :vUserIds])
					{
						vMixMap.get(mAsgs.trailheadapp__Trailmix__c).remove(mAsgs.trailheadapp__User__c);
					}
					for (trailheadapp__Trailmix_Assignment__c mPendingAsgs : [SELECT trailheadapp__Trailmix__c, trailheadapp__User__c FROM trailheadapp__Trailmix_Assignment__c WHERE trailheadapp__Trailmix__c IN :pMixIds AND trailheadapp__User__c IN :vUserIds])
					{
						vMixMap.get(mPendingAsgs.trailheadapp__Trailmix__c).remove(mPendingAsgs.trailheadapp__User__c);
					}
					/** Add everything that's left */
					for (Id MixId : vMixMap.keySet())
					{
						for (Id userId : vMixMap.get(MixId))
						{
							vListToInsert.add(new trailheadapp__Trailmix_Assignment__c(trailheadapp__Trailmix__c = MixId, trailheadapp__User__c = userId, trailheadapp__Due_Datetime__c = pDueDate));
						}
					}
				}
				/** Insert all assignments*/
				if (!vListToInsert.isEmpty())
				{
					Database.insert(vListToInsert);
				}
			}
			/** If running recursively, enqueue the next group (one group at a time currently)*/
			if (RUN_RECURSIVELY && !pGroupIds.isEmpty())
			{
				System.enqueueJob(new TH_GroupAssignmentController(pGroupIds, pBadgeIds, pMixIds, pDueDate));
			}
		}
	}

	/**
	* @description Queueable execute method
	* @param pQC Context
	*/
	public void execute(QueueableContext pQC)
	{
		assignTrainingToGroups(groupIds, badgeIds, mixIds, dueDate);
	}
}