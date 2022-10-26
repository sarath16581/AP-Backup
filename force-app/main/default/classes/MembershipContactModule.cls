/* @author    : kennethleroy.mcguire3@auspost.com.au
* @date       : 04/10/2022
* @description  : 
* @test : MembershipContactModule_Test
* @changelog :
*/

public  inherited sharing class MembershipContactModule extends ApplicationDomain.Module {
   
	@testVisible private static final String TASK_SUBJECT = 'Police Checks Completed'; 
    @testVisible private static final String MEMBERSHIP_CONTACT_STATUS_COMPLETED = 'Completed';
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
		for(SObject currentSObject : records) 
            ((MembershipContact__c)currentSObject).LastStatusChangedDate__c = date.today();
   }
    
    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		createTasksForNewlyCompletedMemberships(records);
   }
    
   public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		updateLastStatusChangedDate(records,existingRecords);
   }

   
   public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
      createTasksForNewlyCompletedMemberships(records,existingRecords);
   }

   /**
    * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
    */
   public class Constructor implements ApplicationDomain.IConstructableModule {
      public ApplicationDomain.Module construct() {
         return (ApplicationDomain.Module)MembershipContactModule.newInstance();
      }
   }
    
    private void updateLastStatusChangedDate(List<SObject> records, Map<Id, SObject> existingRecords) {
        for(SObject currentSObject : records) {
            MembershipContact__c currentRecord = (MembershipContact__c) currentSObject;
            MembershipContact__c existingRecord = (MembershipContact__c) existingRecords.get(currentRecord.id);
            if (currentRecord.Status__c != existingRecord.Status__c) currentRecord.LastStatusChangedDate__c = date.today();
        }
    }
    
    private Map<Id,Id> getMaybeCompletedMembershipOwnerMap(List<SObject> records, Map<Id, SObject> existingRecords) {
        Map<Id,Id> maybeCompletedMembershipOwnerMap = new Map<Id,Id>();
        for(SObject currentSObject : records) {
        	MembershipContact__c currentRecord = (MembershipContact__c) currentSObject;
            if (currentRecord.Status__c == MEMBERSHIP_CONTACT_STATUS_COMPLETED) {
              boolean statusHasChanged = existingRecords.containsKey(currentRecord.id) ? ((MembershipContact__c)existingRecords.get(currentRecord.id)).Status__c  != MEMBERSHIP_CONTACT_STATUS_COMPLETED : true;
              if (statusHasChanged) maybeCompletedMembershipOwnerMap.put(currentRecord.Membership__c,currentRecord.MebershipManagerId__c);
            } 
        }
        return maybeCompletedMembershipOwnerMap;
    } 

    private Set<Id> getIncompleteMembershipIds(Set<Id> membershipIdsToCheck) {
        Set<Id> incompleteMembershipIds = new Set<Id>();
        for (AggregateResult incompleteMemberships : [SELECT Membership__c 
                                                   FROM MembershipContact__c
                                                   WHERE Membership__c IN :membershipIdsToCheck
                                                   AND CompletionDate__c = null
                                                   AND Status__c != :MEMBERSHIP_CONTACT_STATUS_COMPLETED
                                                   Group By Membership__c]) {
        	incompleteMembershipIds.add((id)incompleteMemberships.get('Membership__c'));                                                  
   		}
        return incompleteMembershipIds;
    }
    
    private void createTasksForNewlyCompletedMemberships(List<SObject> records) {
    	createTasksForNewlyCompletedMemberships(records, new Map<Id,SObject>());
    }
    
    private void createTasksForNewlyCompletedMemberships(List<SObject> records, Map<Id, SObject> existingRecords) {
        Map<Id,Id> maybeCompletedMembershipOwnerMap = getMaybeCompletedMembershipOwnerMap(records,existingRecords);
        Set<Id> incompleteMembershipIds = getIncompleteMembershipIds(maybeCompletedMembershipOwnerMap.keyset());
        createTasksForNewlyCompletedMemberships(maybeCompletedMembershipOwnerMap,incompleteMembershipIds);
    }
    
    private void createTasksForNewlyCompletedMemberships(Map<Id,Id> maybeCompletedMembershipOwnerMap, Set<Id> incompleteMembershipIds) {
        List<Task> membershipTasks = new List<Task>();
        for (id currentMembershipId : maybeCompletedMembershipOwnerMap.keyset()) {
            if(!incompleteMembershipIds.contains(currentMembershipId))  {
                Task currentTask = new Task(
               		Status = TASK_STATUS,
					Subject = TASK_SUBJECT,
                    OwnerId = maybeCompletedMembershipOwnerMap.get(currentMembershipId),
                    whatId = currentMembershipId,
                    ActivityDate = date.today(),
                    Type = TASK_TYPE_OTHER,
                    Category__c = TASK_CATEGORY_SERVICE
                );
                membershipTasks.add(currentTask);
            }
        }
        if (membershipTasks.size()>0) database.insert(membershipTasks);
    }
}