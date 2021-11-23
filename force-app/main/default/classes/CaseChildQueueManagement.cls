/*************************************************************************************************************
* @Author: Carmelo Andronaco
* @Company: Bluewolf
* @Email: carmelo.andronaco@bluewolf.com
* @Date: 9/05/2014
* @Description:
*    CopyAuthorisedContacts (Map<Cases>): 
*                   This method sets the Parent Case to Allocate to the Queue when a Child is reallocated.
**************************************************************************************************************/

public without sharing class CaseChildQueueManagement
{   
    public static void updateParentCase (Map<Id,Case> newCases)
    {           
        Set<Id> parentIds = new Set<Id>();
        Map<Id,Case> caseParents = new Map<Id,Case>();
        List<Group> childQueues = new List<Group>();
        
        for(Case c : newCases.values())
        {
            system.debug('CaseChildQueueManagement.updateParentCase ==> case id: ' + c.id + ' with parentID: ' + c.Parentid);
            if(c.AllocateToQueue__c && !String.isEmpty(c.Parentid) && !newCases.containsKey(c.parentID)) // parent is already in the trigger.newMap.
            {
                parentIds.add(c.Parentid); 
            }
        }
        
        if(parentIds.size() > 0)
        {
            // Go get all related Parent Cases to current Cases
            for(Case parentCase: [Select Id, Status, ParentId, AllocateToQueue__c, SystemUpdate__c, IsClosed FROM Case WHERE Id IN:parentIds and Permanent_Close__c = false])
            {
                parentCase.Bypass_Data_enforcement__c = true;
                caseParents.put(parentCase.id,parentCase);
            }   
            childQueues = [Select Id, Name, Developername from Group where Type = 'Queue' and Developername = 'SSSWChildCases' limit 1];
        }   
        List<Case> toUpdate = new List<Case>();    
    
        if(childQueues.size() > 0) 
        {
            for(Case c: newCases.values())
            {
                if(c.AllocateToQueue__c && !String.isEmpty(c.Parentid))
                {
                    c.Ownerid = childQueues[0].id;
                    c.AllocateToQueue__c = false;
                    c.Bypass_Data_enforcement__c = true;
                    
                    if(caseParents.containsKey(c.Parentid)) 
                    {
                        caseParents.get(c.Parentid).AllocateToQueue__c = true;
                        caseParents.get(c.Parentid).SystemUpdate__c = 'Child Case Update';
                        if(caseParents.get(c.Parentid).IsClosed) {
                            caseParents.get(c.Parentid).Status = 'Child Case Update';
                        }
                    } 
                    else if(newCases.containsKey(c.parentID)) 
                    {
                        newCases.get(c.Parentid).AllocateToQueue__c = true;
                        newCases.get(c.Parentid).SystemUpdate__c = 'Child Case Update';
                        if(newCases.get(c.Parentid).IsClosed) {
                            newCases.get(c.Parentid).Status = 'Child Case Update';
                        }
                    }
                }
            }
        }
        
        if(caseParents.size() > 0)
        {
            update caseParents.values();
        }       
    }
}