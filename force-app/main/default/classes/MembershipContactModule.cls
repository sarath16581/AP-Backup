/* @author    : kennethleroy.mcguire3@auspost.com.au
* @date       : 04/10/2022
* @description  : Generic Membership Contact Module to execute universal business logic
* @test : MembershipContactModule_Test
* @changelog :
*/

public  inherited sharing class MembershipContactModule extends ApplicationDomain.Module {
   
	@testVisible private static final String TASK_SUBJECT = 'Police Checks Completed'; 
	private static final String TASK_STATUS = 'Not Started';
    private static final String TASK_TYPE_OTHER = 'Other';
    private static final String TASK_CATEGORY_SERVICE = 'Service';
       
	public static MembershipContactModule newInstance() {

        return (MembershipContactModule)Application.Utilities.newInstance(MembershipContactModule.class);
   
    }
       
   // Setup which triggers this module should respond to
   public MembershipContactModule() {

      getTriggerEvents().enableBeforeUpdate().enableBeforeInsert().enableAfterInsert().enableAfterUpdate();
   
    }
    
   public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
       
        // When a record is created, set the Last Status Changed Date to Today.
		for(SObject currentSObject : records) {
            ((MembershipContact__c)currentSObject).LastStatusChangedDate__c = date.today();
        }
    }
    
   
    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        
        // create a police checks completed task once all membership contact records
        // associated with a membership have been completed.
		createTasksForNewlyCompletedMemberships(records,uow);

   }
    
   public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        // Set the last status changed date to today for any records in which
        // the status has changed value.
        updateLastStatusChangedDate(records,existingRecords);
   }

   
   public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
    	// create a police checks completed task once all membership contact records
        // associated with a membership have been completed.
        createTasksForNewlyCompletedMemberships(records,existingRecords,uow);
   }

    // Update the Last Status Changed date for records with a changed status. 
    private void updateLastStatusChangedDate(List<SObject> records, Map<Id, SObject> existingRecords) {
        for(SObject currentSObject : records) {
            MembershipContact__c currentRecord = (MembershipContact__c) currentSObject;
            MembershipContact__c existingRecord = (MembershipContact__c) existingRecords.get(currentRecord.id);
            if (currentRecord.Status__c != existingRecord.Status__c) {
                currentRecord.LastStatusChangedDate__c = date.today();
            }
        }
    }

    /* create a police checks completed task in the case that:
    * A new contact membership record is created AND
    * the status for this record is Completed AND
    * Any other contact membership records associated with the membership are also completed. */
    private void createTasksForNewlyCompletedMemberships(List<SObject> records,ApplicationUnitOfWork uow) {

        createTasksForNewlyCompletedMemberships(records, new Map<Id,SObject>(),uow);

    }

    /* create a police checks completed task in the case that:
    * An existing contact membership record has been modified AND
    *  the status for this record has been changed to Completed AND
    * Any other contact membership records associated with the membership are also completed.
    * existingRecords Map will be empty for newly insered records. */
    private void createTasksForNewlyCompletedMemberships(List<SObject> records, Map<Id, SObject> existingRecords,ApplicationUnitOfWork uow) {
        
        // Retrieve a collection of Memberships that may now be completed together with their associated managers.
        // These memberships must be checked for completion by checking all the associated membership contact records for 
        // status = completed.
        Map<Id,Id> maybeCompletedMembershipOwnerMap = getMaybeCompletedMembershipOwnerMap(records,existingRecords);
        // Retrieve the ids of memberships which remain incomplete from the list of memberships to check for completion.
        Set<Id> incompleteMembershipIds = getIncompleteMembershipIds(maybeCompletedMembershipOwnerMap.keyset());
        // Create tasks for any memberships  whose associated membership contacs are now all completed.
        createTasksForNewlyCompletedMemberships(maybeCompletedMembershipOwnerMap,incompleteMembershipIds, uow);
    }

    /* Inserts membership assocated tasks for all newly completed memberships.
    * A membership is considered "newly completed" when 
    * The status of atleast one of the membership contacts has been changed to "Completed" AND
    * All other membership contact records associated with the membership are also complete. */
    private void createTasksForNewlyCompletedMemberships(Map<Id,Id> maybeCompletedMembershipOwnerMap, Set<Id> incompleteMembershipIds, ApplicationUnitOfWork uow) {
        
        List<Task> membershipTasks = new List<Task>();
        
        for (id currentMembershipId : maybeCompletedMembershipOwnerMap.keyset()) {
            
            if(!incompleteMembershipIds.contains(currentMembershipId))  {
                // Add a task to the membership, setting the owner of the task to the membership manager.
                membershipTasks.add(createPoliceChecksCompletedTask(currentMembershipId, maybeCompletedMembershipOwnerMap.get(currentMembershipId)));
                
            }

        }
        if(!membershipTasks.isEmpty()) {
            //register the tasks to insert with the UOW and the work will be committed in ApplicationDomainTriggerHandler
            uow.registerNew(membershipTasks);
        }
    }

    /* create a Police Check Completed Task for a membership  */ 
    private Task createPoliceChecksCompletedTask(Id currentMembershipId, Id ownerId) {
        return  new Task(
            Status = TASK_STATUS,
            Subject = TASK_SUBJECT,
            OwnerId = ownerId,
            whatId = currentMembershipId,
            ActivityDate = date.today(),
            Type = TASK_TYPE_OTHER,
            Category__c = TASK_CATEGORY_SERVICE);
    }
    
    
    /* Construct a Map of (Membership Id, Membership Manager Id) for records in which 
    * The status has changed to Completed */ 
    private Map<Id,Id> getMaybeCompletedMembershipOwnerMap(List<SObject> records, Map<Id, SObject> existingRecords) {
        Map<Id,Id> maybeCompletedMembershipOwnerMap = new Map<Id,Id>();
        for(SObject currentSObject : records) {
        	MembershipContact__c currentRecord = (MembershipContact__c) currentSObject;
            if (currentRecord.Status__c == MembershipContactsSelector.MEMBERSHIP_CONTACT_STATUS_COMPLETED) {
              boolean statusHasChanged = existingRecords.containsKey(currentRecord.id) ? ((MembershipContact__c)existingRecords.get(currentRecord.id)).Status__c  != MembershipContactsSelector.MEMBERSHIP_CONTACT_STATUS_COMPLETED : true;
              if (statusHasChanged) {
                maybeCompletedMembershipOwnerMap.put(currentRecord.Membership__c,currentRecord.MebershipManagerId__c);
              } 
            } 
        }
        return maybeCompletedMembershipOwnerMap;
    } 

    // Retrieve a set of membership ids for memberships having one or more
    // incomplete associated membership contact records.
    private Set<Id> getIncompleteMembershipIds(Set<Id> membershipIdsToCheck) {

        Set<Id> incompleteMembershipIds = new Set<Id>();

        for (AggregateResult incompleteMemberships :  MembershipContactsSelector.newInstance().selectIncompleteMembershipsByMembershipIds(membershipIdsToCheck, new Set<Object>(), new Set<SObjectField>{MembershipContact__c.Membership__c})) {
            incompleteMembershipIds.add((id)incompleteMemberships.get('Membership__c'));                                                  
   		}
        
        return incompleteMembershipIds;
    }
}