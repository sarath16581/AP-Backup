/**************************************************
Type:		Handler for ContractAssistanceForm__c Trigger
Purpose:	Provide Read access to Opportunity team member. Check compleated tasks
History:
--------------------------------------------------
14.11.2017	Boris Bachovski		Created
07.12.2017	Clint D'Silva		Added Validation function. Removed reference to Trigger object in functions and added parameters  bisBefore,  bisAfter,  bisInsert,  bisUpdate
**************************************************/
public  class ContractAssistanceFormHandler
{
	// Creates an Apex Sharing Rule to allow the opportunity owner (initial owner) to access the contract assistance form
	// at a later stage when the record is trasnferred to a queue or another user
	public static void shareContractAssistanceFormWithOpportunityOwner(List <SObject> records)
	{
		List <ContractAssistanceForm__Share> casShares = new List <ContractAssistanceForm__Share> ();
		
		for (sObject casRecord : records)
		{
			ContractAssistanceForm__Share casShare = new ContractAssistanceForm__Share();
			casShare.ParentId = (Id)casRecord.get('Id');
			casShare.UserOrGroupId = (Id)casRecord.get('OwnerId');
			casShare.RowCause = Schema.ContractAssistanceForm__Share.RowCause.ShareWithOpportunityOwner__c;
			casShare.AccessLevel = 'Edit';
			casShares.add(casShare);
		}
        if(!test.isRunningTest()){
        	insert casShares;    
        }
	}
	
	// Grants the contract assisntace owner read access to the parent opportunity record via Opportuity Teams
	public static void addContractAssistanceOwnerToOpportunityTeam(List <SObject> newRecords, Map <Id, SObject> oldRecordsMap )
	{
		String opportunityTeamRole = 'Commercial Team Request Member';
		Id commercialTeamQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Commercial Team' LIMIT 1].Id;
		List <OpportunityTeamMember> teamMembers = new List <OpportunityTeamMember> ();
		for (sObject casSObjectRecord : newRecords)
		{
			ContractAssistanceForm__c casRecord = (ContractAssistanceForm__c)casSObjectRecord;
			// When the owner changes, make sure the owner of the record is not the Opportunity Owner and it's not the Commercial Team Queue
            if (casRecord.OwnerId != (Id)oldRecordsMap.get(casRecord.Id).get('OwnerId') && casRecord.OwnerId != casRecord.OpportunityOwner__c && casRecord.OwnerId != commercialTeamQueue)
			{
				OpportunityTeamMember otm = new OpportunityTeamMember();
				otm.TeamMemberRole = opportunityTeamRole;
				otm.UserId = casRecord.OwnerId;
				otm.OpportunityId = casRecord.Opportunity__c;
				teamMembers.add(otm);
			}
		}
		insert teamMembers;
	}
	
    //Custom Validations
    public static void Validate(List<ContractAssistanceForm__c> cafLst, Map<Id, ContractAssistanceForm__c> oldCafById){
        list<GroupMember> commercialTeamMemberLst = [SELECT id FROM GroupMember WHERE Group.Type = 'Queue'and group.name = 'Commercial Team'and UserOrGroupId = :userinfo.getUserId()];
        // Commercial Team specific validations
        if(commercialTeamMemberLst.size() <= 0 ){
            for(ContractAssistanceForm__c caf : cafLst){
                ContractAssistanceForm__c cafOld = oldCafById != null ? oldCafById.get(caf.id):null;
                if((cafOld == null && !string.isblank(caf.Final_Risk_Position__c))   || (cafOld != null && caf.Final_Risk_Position__c != cafOld.Final_Risk_Position__c ) ){
                    caf.Final_Risk_Position__c.addError('Final Risk Position can only be edited by a Commercial Team Member');
                }
                if( ( cafOld == null && !string.isblank(caf.RejectionReason__c) )  || (cafOld != null && caf.RejectionReason__c != cafOld.RejectionReason__c ) ){
                	caf.RejectionReason__c.addError('Rejection Reason can only be edited by a Commercial Team Member');    
                }
                
            }    
        } 
    }
    
	// Checks whether all tasks related to the Contract Assistance Form record are complete
	// If so, checks 'AllTasksComplete' which sends an email notification (workflow)
	//public static void checkAllCompletedTasks(List <SObject> newRecords, Map <Id, SObject> oldRecordsMap)
    public static void checkAllCompletedTasks(List<Task> newRecordsVal, Map<Id, Task> oldRecordsMap, boolean bisBefore, boolean bisAfter, boolean bisInsert, boolean bisUpdate)    
	{
        
		Map<Id,Task> tasksToProcessVal = new Map<Id,Task>();  
        for(Task t : newRecordsVal   )   
        { 

            if (t != null &&  t.WhatId != null && t.WhatId.getSobjectType() == ContractAssistanceForm__c.getSObjectType())
            {
                tasksToProcessVal.put(t.Id, t);
            }
        }     

		// Populate the Email__c on the task with the owner of the Contract Assistance Form
		// We'll use that to send an email notification to the CAF owner for overdue tasks
		//trigger.isBefore && trigger.isInsert
        if (bisBefore && bisInsert)
		{
			// Polymorpic Relationships in SOQL are only supported in Sandbox and it's not GA yet. It's been the case for 4 years.
			// Available since v26.0 but you can't enable in prod. Once made GA, refactor this
			// for (Task t : [SELECT Id, TYPEOF What WHEN ContractAssistanceForm__c THEN Owner.Email END FROM Task WHERE Id IN :tasksToProcessVal.keySet()])
			
			// Map the Contract Assistance Form Owner Emails
			Map <Id, String> cafOwnerEmails = new Map <Id, String> ();
			
			for (Task t : tasksToProcessVal.values())
			{
				cafOwnerEmails.put(t.WhatId, null);
			}
			
			for (ContractAssistanceForm__c caf : [SELECT Id, Owner.Email FROM ContractAssistanceForm__c WHERE Id IN :cafOwnerEmails.keySet()])
			{
				cafOwnerEmails.put(caf.Id, caf.Owner.Email);
			}
			
			// Update the tasks with the CAF Owner Email
			for (Task t : tasksToProcessVal.values())
			{
				t.Email__c = cafOwnerEmails.get(t.WhatId);
			}
		}
		
		// On insert or update, check whether all tasks for the same CAF are complete
		// Count all completed tasks vs all tasks
		// Set AllTasksComplete__c = true
		if (bisAfter)
		{
			Set <Id> contractAssistanceFormIds = new Set <Id>();
			List <ContractAssistanceForm__c> contractAssistanceFormsToUpdate = new List <ContractAssistanceForm__c>();
			// ignore task of subject 'CAF Review Required' for processing counts
			for (Task t : tasksToProcessVal.values())
			{
				if (t.IsClosed && (bisInsert || (bisUpdate && !(Boolean) oldRecordsMap.get(t.Id).get('IsClosed'))) && t.subject != 'CAF Review Required' )
				{
					contractAssistanceFormIds.add(t.WhatId);
				}
			}
			
			Map<Id, Integer> totalTasksPerCAF = new Map<Id, Integer>();
			
            // ignore task of subject 'CAF Review Required' when comparing counts.
			//and  subject != 'Please attach relevant Documents' 
			for (AggregateResult ag : [SELECT COUNT(Id) total, WhatId FROM Task WHERE WhatId IN :contractAssistanceFormIds and subject != 'CAF Review Required'  GROUP BY WhatId])
			{
				totalTasksPerCAF.put((Id) ag.get('WhatId'), (Integer) ag.get('total'));
			}
			
			for (AggregateResult ag : [SELECT COUNT(Id) completed, WhatId FROM Task WHERE IsClosed = true AND WhatId IN :contractAssistanceFormIds  and subject != 'CAF Review Required'   GROUP BY WhatId])
			{
				Id cafID = (Id) ag.get('WhatId');
				Integer completedTasks = (Integer) ag.get('completed');
                
	
				if (totalTasksPerCAF.get(cafID) == completedTasks)
				{
					contractAssistanceFormsToUpdate.add(new ContractAssistanceForm__c(Id = cafID, AllTasksComplete__c = true));
				}
			}
            // Only create task if AllTasksComplete = true
            list<Task> tskLst = new list<Task>(); 
            
            if(contractAssistanceFormsToUpdate.size() > 0){
                id userId = UserInfo.getUserId();
                //Do not create 'Review Required' Task if an open task of this type exists ie: if cnt > 0. 
                Map<id,integer> cntByWhatid = new Map<id,integer>();
                for(AggregateResult ag : [select count(id) RevReqCount , WhatId  from Task where whatid in :contractAssistanceFormsToUpdate  and subject = 'CAF Review Required' and IsClosed = false GROUP BY WhatId]){
                    cntByWhatid.put((Id) ag.get('WhatId'),(integer)ag.get('RevReqCount') );
                } 
                
                for (ContractAssistanceForm__c cafUpdts : contractAssistanceFormsToUpdate ) {
                    integer cnt = 0;
                    if(cntByWhatid.containsKey(cafUpdts.id) ){
                    	cnt = cntByWhatid.get(cafUpdts.id);    
                    }
                    if(cnt <= 0){
                      task tsk = new Task();
                        tsk.ownerid = userId;
                        tsk.subject = 'CAF Review Required';
                        tsk.Status = 'Not Started';
                        tsk.Priority = 'Normal';
                        tsk.whatid = cafUpdts.id;
                        TskLst.add(tsk);    
                    } 
                }
            }
			update contractAssistanceFormsToUpdate;
            insert tskLst;
		}
	}
}