/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 17/11/2015
  * @description  : This Class is Batch class to monitor the cases in queue for more than predefined time(*3hrs)
                    and assign them to queue member.
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    
    
*******************************  History ************************************************/
global without sharing class CaseManagement_Batchable implements Database.Batchable<SObject> {

    //batch class contructor
    global CaseManagement_Batchable() { }
    
    /** 
      * @name: start()
      * @desciption: start method to run the query and get the results
      * @param: Database.BatchableContext
      * @return: Database.QueryLocator
      *
      */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        TimeZone tz = UserInfo.getTimeZone();
        Datetime startDate = system.now().addSeconds(tz.getOffset(system.now())/1000);
        system.debug(startdate);
        Datetime endDate =  startDate.addhours(-3);
        Datetime btwnhours =  startDate.addhours(-6);
        system.debug(endDate);
        
        String query = 'SELECT Id, OwnerId, Status, ParentId  FROM Case WHERE CreatedDate <= :endDate and createdDate >= :btwnhours  ' +
                                      '  AND isClosed = false AND ParentId = null and status = \'New\' '+
                                      '  ORDER BY PriorityNumber__c DESC NULLS LAST';
    
        
        System.debug(System.LoggingLevel.DEBUG, '##DEBUG: START - query: ' + query);
        
        return Database.getQueryLocator(query);
    }

    /** 
      * @name: finish()
      * @desciption: method to perform tasks once the batch is complete
      * @param: NA
      * @return: NA
      *
      */
    global void finish(Database.BatchableContext BC) { }   

    /** 
      * @name: execute()
      * @desciption: execution code lies in this method- here we assign cases open for more than 3 hours to agents
      * @param: Database.BatchableContext BC, List<SObject> caseList2
      * @return: NA
      *
      */
    global void execute(Database.BatchableContext BC, List<SObject> caseList2) {
        try {
        List<Case> caseList = (List<Case>)caseList2;
        if(!caseList.isEMpty()) {
            //query for cases which have been in queue in new status for more than 3 hours
            //check if the logged in user is part of queue which is eligible
            Set<String> queueNames = new Set<String>();
            Set<Id> queueNamesId = new Set<Id>();
            
            List<CAse> toUpdateCases = new List<Case>();
            List<CaseTeamMember> ctmList = new List<CaseTeamMember>();
            CaseTeamRole ctROle = new CaseTeamRole ();
            Map<String,List<String>> queueUserMap = new Map<STring,List<STring>>();
            
            FillInboxSettings__c setting = FillInboxSettings__c.getInstance();
            Set<String> statues = new Set<String>();
            Map<STring,Set<String>> caseTemMemList = new Map<STring,Set<String>>();
            
            Set<String> ownerIdSet = new Set<String>();
            List<Id> caseIdList = new List<id>();
            
            for(EligibleQueue_FillInBox__c eligQue : EligibleQueue_FillInBox__c.getAll().values()) {
                queueNames.add(eligQue.Name);   
            }
            
            //query for ids of all eligible queues and get the members
            for(GroupMember grp: [select UserOrGroupId, Group.Name, Group.Id from GroupMember where  
                            GroupId IN: [select id, Name from Group where type='Queue' AND Name in :queueNames]]) {
                queueNamesId.add(grp.UserOrGroupId);
                if(queueUserMap==null || !queueUserMap.keySet().contains(grp.Group.Id)) {
                    queueUserMap.put(grp.Group.Id,new List<String>());
                }
                queueUserMap.get(grp.Group.Id).add( grp.UserOrGroupId);
            }
            Map<Id,Boolean> isActiveUSer = new Map<Id,Boolean>();
            for(User usr :[Select id, isActive from User where Id in : queueNamesId]) {
                isActiveUSer.put(usr.Id, usr.isActive);
            }
           
            //checking the statuses from custom setting
            if(setting.CommaSeparatedStatus__c != null) {
                statues = new Set<String>(setting.CommaSeparatedStatus__c.split(','));
                for(string s: statues) {
                    system.debug('XXXBWXXX: status = ' + s);
                    s = s.trim();
                }
            }
            else {
                statues.add('New');
            }
            
            //getting the max number of cases that can be assigned to a user
            if(setting.MaxNumberOfCasesToAssign__c == null){
                setting.MaxNumberOfCasesToAssign__c = 1;
            }
            
            //loop on the cases from the query in batch and get the owner id and case id's
            for(SObject cse: caseList) {
                //owner will be queue
                ownerIdSet.add(String.valueOf(cse.get('OwnerId')));
                caseIdList.add(String.valueOf(cse.get('Id')));
            }
            
            //get cases of users who are in the eligible queues - if they already
            Set<Id> usrId = new Set<Id>();
            Set<String> isNotAvailableForAssgn = new Set<String>();
            for(AggregateResult agR : [Select count(Id) asgndCases, OwnerId own from Case where
                             OwnerId in :queueNamesId and isClosed = false AND Status not in :statues
                             group by ownerId ]) {
                if(Integer.valueOf(agr.get('asgndCases')) > setting.MaxNumberOfCasesToAssign__c) {
                    isNotAvailableForAssgn.add(String.valueOf(agR.get('own')));
                }
            }
            
            //query caseteammembers for all cases
            for(CaseTeamMember ctm: [Select Id, ParentId,TeamRoleId, MemberId from CaseTeamMember where 
                                                                ParentId in :caseIdList] ) {
                if(caseTemMemList==null || !caseTemMemList.keySet().contains(ctm.Parentid)) {
                    caseTemMemList.put(ctm.Parentid,new Set<String>());
                }
                caseTemMemList.get(ctm.Parentid).add(ctm.MemberId);
            }
            
            for( CaseTeamRole ct : [SELECT Name, Id FROM CaseTeamRole where Name = 'Co-Work']) {
                ctrole = ct;
            }
            Set<Id> assgnedOwnerId = new Set<Id>();
            Boolean addedCaseFlag = false;
            for(Case cse : caseList) {
                system.debug(cse+'-----');
                addedCaseFlag = false;
                //if( cse.parentId != null && cse.DatePosted__c!=null && cse.DescriptionofContents__c!=null 
                //                    && cse.ValueofContents__c!=null){
                    if(queueUserMap.keySet().contains(cse.OwnerId)) {
                        for(String s: queueUserMap.get(cse.OwnerId)) {
                            if(!assgnedOwnerId.contains(s) && !isNotAvailableForAssgn.contains(s) && !addedCaseFlag) {
                             if(isActiveUSer.get(s)) {
                                    cse.OwnerId = s;
                                    if (cse.Status == 'New' || statues.contains(cse.Status)) {
                                       cse.Status = 'In Progress';
                                    }
                                    toUpdateCases.add((Case) cse);
                                    if(caseTemMemList.isEmpty()) {
                                        ctmList.add(new CaseTeamMember(ParentId = cse.Id, MemberId = s, TeamRoleId = ctrole.Id));  
                                    }
                                    else if(!caseTemMemList.isEmpty() && caseTemMemList.get(cse.Id)!=null) {
                                        if(!caseTemMemList.get(cse.Id).contains(s))
                                        ctmList.add(new CaseTeamMember(ParentId = cse.Id, MemberId = s, TeamRoleId = ctrole.Id));  
                                    }
                                    assgnedOwnerId.add(s);
                                    addedCaseFlag = true;
                                    system.debug(cse+'-----added to list');
                                    system.debug(ctmList);
                                    
                                 }
                             }
                        } 
                    }
                //    }
            }
            
            if(!toUpdateCases.isEMpty()) {
                database.update(toUpdateCases);
            }
            if(!ctmList.isEMpty()) {
                database.insert(ctmList);
            }

       }
       }
       catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW', 
                                                    'CaseManagement_Batchable', 'execute', 
                                                    null, LoggingLevel.ERROR);
        }
       
    }
    
}