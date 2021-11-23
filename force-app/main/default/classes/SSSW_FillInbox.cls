/**
*
@changelog
* 2015-05-12 Matthew Watson (matthew.watson@salesforce.com)
* -  Modified to add ", CreatedDate ASC" to the end of the available cases query, 
*    to ensure that for cases with equal/blank Priority & SLA Target Date are
*    allocated in chronological order
*/
/***** History *******
4th Nov, 2015    Kalpita T  updated the fill in box logic to add the new case management process
18 Mar, 2016     Eric Shen  update to partially sovle the race condition issue-INC0617498. 
21-Mar, 2016     Eric Shen   hotfix to add Bypass_Data_enforcement__c to assigntocase variable
30-Mar, 2016     Eric Shen   fix a potential exception on case team member deletion
09-Aug, 2016     Eric Shen   fix bug that users with multi-queues failed to get a case
4.03.2017        kalpita T-  updated code check for case visiblity issue for myNetwork 
13-Apr, 2017     Eric Shen   refine this class to enhance the locking mechanism 
16-Sep, 2019     rajesh.punjabi@mav3rik.com Replaced old logic with new simplified logic base on Priority and Created date only.
**********************/

global class SSSW_FillInbox {
    
    public static Boolean checkFillInboxClicked = false; // created boolean for verifying status tracking records while case owner is changed from Fill Inbox
    
    /** 
      * @name: fillInboxClicked 
      * @desciption: getter setter for  checking if fill in box clicked
      * @param: NA
      * @return: NA
      *
      */
    public static Boolean fillInboxClicked {
        get {
            if (fillInboxClicked == null) {
                fillInboxClicked = false;
            }
            return fillInboxClicked;
        }
        private set;
    }
  
    public SSSW_FillInbox(){ }


    /**
    * @description Get the list of group(s) for current user.
    * @author rajesh.punjabi@mav3rik.com | 9/18/2019 
    * @return Set<Id> 
    **/
    public static Set<Id> getGroupforUser(){
        List<GroupMember> lstGroupMembers = [SELECT GroupId, Id, SystemModstamp, UserOrGroupId 
                                            FROM GroupMember 
                                            WHERE UserOrGroupId = :UserInfo.getUserId()
                                            AND Group.Type = 'Queue'];
        Set<Id> setGroupIds = new Set<Id>();

        for(GroupMember gm: lstGroupMembers){
            setGroupIds.add(gm.GroupId);
        }

        return setGroupIds;
    }
    
    /**
    * @description Case Prioritization .. Case will be assigned to agent based on Priority and Case Created Date.
    * @description WF (SSSW - Queue Priority NCCC) will update the priority based on defined criteria. 
    * @author rajesh.punjabi@mav3rik.com | 9/16/2019 
    * @return String 
    **/
    public static String fetchCase(){
        Integer iMaxLimit = 1;
        FillInboxSettings__c setting = FillInboxSettings__c.getInstance();
        String returnValue = (String)setting.MyCaseQueueID__c;
        Set<String> statues = new Set<String>();
        //.. get settings for Fillinbox
        if(setting.CommaSeparatedStatus__c != null) {
            statues = new Set<String>(setting.CommaSeparatedStatus__c.split(','));
            for(string s: statues) {
                s = s.trim();
            }
        }
        else {
            statues.add('New');
        }

        if(setting.MaxNumberOfCasesToAssign__c != null){
               iMaxLimit = (Integer)setting.MaxNumberOfCasesToAssign__c;
        }
        //.. Check if agents already owns a case(s).
        Integer assignedCases = [SELECT Count() FROM Case WHERE OwnerId=:UserInfo.getUserId() AND isClosed=false AND Status NOT IN:statues];

        Case oLockedCase = new Case();    
        //.. Check if agent can be assigned more cases.
        if(assignedCases < iMaxLimit){
            Set<Id> setGroupIds = getGroupforUser();
            // .. Get new case for agent Criteria: Priority + Created Date.
            List<Case> oSelectedCase = [SELECT Id FROM Case WHERE OwnerId IN:setGroupIds 
                                            AND isClosed = false AND ParentId = null 
                                            ORDER BY PriorityNumber__c DESC NULLS LAST, CreatedDate ASC LIMIT 1];
            if(oSelectedCase.size()>0 && oSelectedCase!=null){
            //.. lock the case and assign to agent.
            oLockedCase = [SELECT Id, Status, Bypass_Data_enforcement__c, OwnerId FROM Case WHERE Id=: oSelectedCase[0].Id FOR UPDATE];
            if(oLockedCase != null && setGroupIds.contains(oLockedCase.OwnerId)){
                oLockedCase.OwnerId = UserInfo.getUserId(); 
                oLockedCase.Bypass_Data_enforcement__c=true;
                if (oLockedCase.Status == 'New' || statues.contains(oLockedCase.Status))
                {
                    oLockedCase.Status='In Progress';
                }
                checkFillInboxClicked=true;
                Database.update(oLockedCase);
                }
                else if (oLockedCase.OwnerId != userInfo.getUserId()) {  //.. return error message.
                    returnvalue=Label.SSSW_Filling_Inbox_Alert;
                }
            }
        }
        else{ //.. return error message
            returnvalue=Label.SSSW_Filling_Inbox_Alert2;
        }
        return returnValue;
    }

    /** 
      * @name: wsFillInbox()
      * @desciption: method call onclick of button to assign a case to agent based on situations
      * @param: NA
      * @return: String
      *
      */
    @remoteAction
    public static string wsFillInbox(){
        String returnValue;
        try{
            returnValue = fetchCase();
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW', 
                                                    'SSSW_FillINBox', 'wsFillInbox', 
                                                    null, LoggingLevel.ERROR);
        }

        return returnValue;
        
        // FillInboxSettings__c setting = FillInboxSettings__c.getInstance();
     
        //     Set<String> statues = new Set<String>();
        //     if(setting.CommaSeparatedStatus__c != null) {
        //         statues = new Set<String>(setting.CommaSeparatedStatus__c.split(','));
        //         for(string s: statues) {
        //             s = s.trim();
        //         }
        //     }
        //     else {
        //         statues.add('New');
        //     }
            
        //     if(setting.MaxNumberOfCasesToAssign__c == null){
        //         setting.MaxNumberOfCasesToAssign__c = 1;
        //     }
            
        //     /** Code Related to New Case Management Process : Kalpita **/
        //     List<CaseTeamMember> ctmList = new List<CaseTeamMember>();
        //     List<CaseTeamMember> delCtmList = new List<CaseTeamMember>();
        //     List<String> userInEliQueue = new List<String>();
        //     //Set<Id> queueNamesId = new Set<Id>();
        //     Set<String> queueNames = new Set<String>();
        //     Set<Id> userInEliQueueId = new Set<Id>();
        //     //Map<Id,String> queueIdNameMap = new Map<Id,String>();
        //     CaseTeamRole ctrole = new CaseTeamRole();
        //     Case assgnCase;
        //     Case lockassigncase = new Case();   
        //     String returnvalue =setting.MyCaseQueueID__c;
            
        //     //change the try block under the variable declaration for returnvalue to work  Eric Shen 18-Mar-16
        //     try { 
        //     system.debug('XXXBWXXX: statues======================');
        //     system.debug(statues);
        //     system.debug('XXXBWXXXs: groups = ' + groupIdNames.keySet().size());
        //     system.debug(groupIdNames.keySet());
        //     system.debug('XXXBWXXX: userid = ' + UserInfo.getUserId());
        //     integer assignedCases = [Select count() from Case where OwnerId =: UserInfo.getUserId()  and isClosed = false AND Status not in :statues];
        //     system.debug('XXXBWXXX: assigned Cases = ' + assignedCases);
        //     system.debug('XXXBWXXX: groupsids = ' + groupIdNames.keySet());
            
            
           
      
        //     //check if the logged in user is part of queue which is eligible
        //     for(EligibleQueue_FillInBox__c eligQue : EligibleQueue_FillInBox__c.getAll().values()) {
        //         queueNames.add(eligQue.Name);   
        //     }

        //     // get only group ids belonging to eligible queues
        //     for(Group grp: groupIdNames.Values()) {

                
        //             if(queueNames.contains(grp.name)) {

        //                 userInEliQueueId.add(grp.ID);
        //             }
           
        //     }
            
 
        //     /*uery for ids of all eligible queues
        //     for(GroupMember grp: [select UserOrGroupId, Group.Name, Group.Id from GroupMember where  
        //                     GroupId IN: [select id, Name from Group where type='Queue' AND Name in :queueNames]]) {
        //         queueNamesId.add(grp.Group.ID);
        //     }
            
        //     //query queues from set above where logged in user is a member
        //     for(GroupMember grp: [select UserOrGroupId, Group.Name, Group.Id from GroupMember where UserOrGroupId = :Userinfo.getUserId() and 
        //                     GroupId IN: [select id, Name from Group where type='Queue' AND Name in :queueNames]]) {
        //         userInEliQueue.add(grp.Group.Name);
        //         userInEliQueueId.add(grp.Group.ID);
        //         queueIdNameMap.put(grp.Group.ID,grp.Group.Name);
        //     }

        //     --end of added by kalpita for New Case Management Process

        //     */
            
        //     /** Code Related to HLC CR - REQ0490484 : Nandan N **/
        //     String queueType = HLCUtility.getAgentQueueType(UserInfo.getUserId());      // get the queue type agent is part of 
            
        //     Boolean isHLCorCR = HLCUtility.QUEUE_SEC_MAP.containsKey(queueType) ? true : false; // flag indicating agent is part of HLC or CR queue
        //     String roleName = '';                
        //     Boolean hasTeamMem = false;
        //     List<Case> availableCases = new List<Case>();
        //     List<Case> lockavailableCases = new List<Case>();  //13-Apr-17 Eric Shen add it to lock list of available cases
        //     if( assignedCases < setting.MaxNumberOfCasesToAssign__c ) {
        //         // Removed restriction of number of cases an HLC agent can have in their queue : Nandan N
        //         integer limitGet = isHLCorCR ? setting.MaxNumberOfCasesToAssign__c.intValue() : (setting.MaxNumberOfCasesToAssign__c.intValue() - assignedCases);
        //         List<Case> cases2update = new List<Case>();    
                
                
                
        //         if(isHLCorCR || String.isNotBlank(queueType)){ // Condition check to assign HLC/CR cases first to agents part of HLC or CR queue
        //             if(HLCUtility.AGENT_QUEUE.HLC.name().equalsIgnoreCase(queueType)){
        //                 availableCases = [SELECT Id, OwnerId, Status FROM Case WHERE OwnerId in :groupIdNames.keySet() AND isHLC__c = true 
        //                                     AND isClosed = false AND ParentId = null 
        //                                     ORDER BY PriorityNumber__c DESC NULLS LAST LIMIT :limitGet];
        //             }
        //             else{
        //                 availableCases = [SELECT Id, OwnerId, Status FROM Case WHERE OwnerId in :groupIdNames.keySet()
        //                                     AND isCR__c = true AND isClosed = false AND ParentId = null 
        //                                     ORDER BY PriorityNumber__c DESC NULLS LAST LIMIT :limitGet];
        //             }
        //         }
        //         else {       
        //             /** Code Related to New Case Management Process : Kalpita **/
        //             ctmList = new List<CaseTeamMember>();
                    
        //             CaseTeamMember tempTeamMem = new CaseTeamMember ();
        //             //get all open cases where user is in case team member
        //             List<id> parentCaseIdLst = new List<Id>();
        //             for(CaseTeamMember ctm: [Select parentId from CaseTeamMember where MemberId=: userinfo.getuserId()]) {
        //                 parentCaseIdLst.add(ctm.parentId);
        //             }


        //             //check if user in eligible queue 
        //             if(!userInEliQueueId.isEmpty()) {
                        
        //                 //get all cases from the queue 
        //                 for(Case cse : [Select Id, OwnerId from Case where Id In : parentCaseIdLst and 
        //                             //and parentId = null and DatePosted__c!=null and DescriptionofContents__c!=null 
        //                             //and ValueofContents__c!=null and
        //                             isClosed = false 
        //                             and OwnerId in: userInEliQueueId
        //                             order by PriorityNumber__c  DESC NULLS LAST, SLATargetDate__c ASC NULLS LAST, 
        //                                       CreatedDate ASC  limit 1]) {
        //                     roleName = groupIdNames.get(cse.OwnerId).name;
        //                     cse.OwnerId = userInfo.getUserId(); 
        //                     cse.Bypass_Data_enforcement__c=True;   //21 Mar 16 Eric Shen hotfix to bypass all case VRs. 

        //                     if (cse.Status == 'New' || statues.contains(cse.Status)) {
        //                         cse.Status = 'In Progress';
        //                     }                       
        //                     assgnCase  = cse;
        //                 }
        //                 //no case where user is already in caseTeam then query all cases from queue
        //                 if(assgnCase == null) {
        //                     for(Case cse : [Select Id, OwnerId from Case where parentId = null and isClosed = false 
        //                             //and DatePosted__c!=null 
        //                             //and DescriptionofContents__c!=null and ValueofContents__c!=null 
        //                             //10-Aug-16 Eric Shen   change ownerID in the only eligible queues
        //                             and OwnerId in :userInEliQueueId order by IsNewForRouting__c DESC,
        //                             PriorityNumber__c DESC NULLS LAST, SLATargetDate__c ASC NULLS LAST, 
        //                                       CreatedDate ASC  limit 1]) {
        //                         roleName = groupIdNames.get(cse.OwnerId).name;
        //                         cse.OwnerId = userInfo.getUserId(); 
        //                         cse.Bypass_Data_enforcement__c=True;   //21 Mar 16 Eric Shen hotfix to bypass all case VRs. 
                                
        //                         if (cse.Status == 'New' || statues.contains(cse.Status)) {
        //                             cse.Status = 'In Progress';
        //                         }
        //                         assgnCase  = cse;
                                
        //                     } 
        //                     if(assgnCase != null)  {
        //                         //check if case already has a caseTeamMember
        //                         // add and MemberId!=Userinfo.getUserId() into SOQL query 30-Mar-16 Eric Shen
        //                         for(CaseTeamMember teamMem : [Select Id, ParentId,TeamRoleId, MemberId from CaseTeamMember where 
        //                                                         ParentId =:assgnCase.Id and MemberId!= :Userinfo.getUserId()]) {
        //                             //if yes delete old member
        //                             //and replace with new user
        //                           //4.03.2017 -kalpita -  updated for case visiblity issue for myNetwork 
        //                            if(tempTeamMem.MemberId == userInfo.getUserId()) {
        //                                hasTeamMem = true;
        //                                delCtmList.add(teamMem);
        //                                tempTeamMem.ParentId = assgnCase.Id;
        //                                tempTeamMem.MemberId = userInfo.getUserId();
        //                                tempTeamMem.TeamRoleId = teamMem.TeamRoleId;
        //                            }
        //                         }
                                
                            
        //                         //if no teamMember insert user as caseteamMember
        //                         if(!hasTeamMem) {
        //                             Boolean hasRole = false;
        //                             for( CaseTeamRole ct : [SELECT Name, Id FROM CaseTeamRole where Name = :roleName ]) {
        //                                 hasRole = true;
        //                                 ctrole = ct;
        //                             }
        //                             if(!hasRole && !String.isBlank(roleName)) {
        //                                 ctRole = new CaseTeamRole (Name = roleName, AccessLevel='Edit' );
        //                                 insert ctRole;
        //                             }
        //                             ctmList.add(new CaseTeamMember(ParentId = assgnCase.Id, MemberId = userInfo.getUserId(), TeamRoleId = ctrole.Id));  
        //                         }
        //                         else {
        //                             ctmList.add(tempTeamMem );
        //                         }
        //                     }
        //                 }
                    
        //             }
        //             else{       // scenario for agents not part of HLC or CR queue
        //                 availableCases = [Select Id, OwnerId, Status from Case Where OwnerId in :groupIdNames.keySet() 
        //                                 AND isClosed = false and Parentid = null and PriorityNumber__c = 10 limit :limitGet];
                    
                    
        //                 if(availableCases == null || availableCases.size()==0) {
        //                     availableCases = [Select Id, OwnerId, Status from Case Where OwnerId in :groupIdNames.keySet() 
        //                                       AND isClosed = false and Parentid = null ORDER BY IsNewForRouting__c DESC, 
        //                                       PriorityNumber__c DESC NULLS LAST, SLATargetDate__c ASC NULLS LAST, 
        //                                       CreatedDate ASC limit :limitGet];
        //                 }
        //             }
        //             for(Case c: availableCases) 
        //             {
        //                 c.OwnerId = UserInfo.getUserId();
        //                 c.Bypass_Data_enforcement__c = true;
        //                 if (c.Status == 'New' || statues.contains(c.Status))
        //                 {
        //                     c.Status = 'In Progress';
        //                 }
        //                // cases2update.add(c);   //18-Mar-16 Eric Shen remove as a redudant variable with no update need
        //             }
        //             /*else { // if user not part of eligible queues
        //                 for(Case cse : [Select Id, OwnerId, Status from Case Where Id In 
        //                                   : parentCaseIdLst and OwnerId in :groupIds AND isClosed = false 
        //                                   and Parentid = null order by PriorityNumber__c DESC limit :limitGet] ) {
        //                     cse.OwnerId = userInfo.getUserId(); 
        //                     cse.Bypass_Data_enforcement__c = true;
        //                     if (cse.Status == 'New' || statues.contains(cse.Status)) {
        //                         cse.Status = 'In Progress';
        //                     }
        //                     roleName = cse.OwnerId;
        //                     availableCases.add(cse);
        //                     hasTeamMem = true;
                            
        //                 }
        //                 if((availableCases == null || availableCases.size()==0 ) && assgnCase == null) {
        //                     for(Case cse : [Select Id, OwnerId, Status from Case Where OwnerId in :groupIds AND isClosed = false 
        //                                       and Parentid = null ORDER BY IsNewForRouting__c DESC, 
        //                                       PriorityNumber__c DESC NULLS LAST, SLATargetDate__c ASC NULLS LAST, 
        //                                       CreatedDate ASC limit :limitGet]) {
        //                         cse.OwnerId = userInfo.getUserId(); 
        //                         cse.Bypass_Data_enforcement__c = true;
        //                         if (cse.Status == 'New' || statues.contains(cse.Status)) {
        //                             cse.Status = 'In Progress';
        //                         }
        //                         roleName = cse.OwnerId;
        //                         availableCases.add(cse);
        //                     }
        //                 }
        //             }*/
        //         }
                
        //         system.debug('XXXBWXXX: Available Cases = ' + availableCases.size());
                
        //         /** Code Related to New Case Management Process : Kalpita **/
        //         if(!availableCases.isEmpty() && !hasTeamMem) {
                    
        //             Boolean hasRole = false;
        //             for( CaseTeamRole ct : [SELECT Name, Id FROM CaseTeamRole where Name = :roleName ]) {
        //                 hasRole = true;
        //                 ctrole = ct;
        //             }
        //             if(!hasRole) {
        //                 for( CaseTeamRole ct : [SELECT Name, Id FROM CaseTeamRole where Name = 'Co-Work']) {
        //                     hasRole = true;
        //                     ctrole = ct;
        //                 }
        //             }
        //             for(Case cse : availableCases) {
        //                 ctmList.add(new CaseTeamMember(ParentId = cse.Id, MemberId = userInfo.getUserId(), TeamRoleId = ctrole.Id));  
        //             }
        //         }
        //     }
            
        //     //new to test by Eric  18-Mar-16 This is to solve race condition issue. 
        //     //lockassigncase= [select id,status, OwnerId from case where id= :assgnCase.id for update] ; 
        //     //add assigncase check to avoid null pointer error

        //     if(assgnCase != null)  {

        //         lockassigncase= [select id,status, Bypass_Data_enforcement__c, OwnerId from case where id= :assgnCase.id for update] ;  //11-Apr-17 Eric Shen add Bypass_Data_enforcement__c

            
        //     //add condition to check lockassignedcase's owner is the current user  10-Aug-16 Eric Shen
        //     if (userInEliQueueId.contains(lockassigncase.OwnerId) ||lockassigncase.OwnerId == userInfo.getUserId()) {

        //         if(userInEliQueueId.contains(lockassigncase.OwnerId)) {
        //                     lockassigncase.OwnerId = userInfo.getUserId(); 

        //                     }
        //             if (lockassigncase.Status == 'New' || statues.contains(lockassigncase.Status)) {
        //                     lockassigncase.Status = 'In Progress';
        //              }
                     
        //         checkFillInboxClicked = true;
        //         //11-Apr-17 Eric Shen Ensure this bypass field is true before update
        //         lockassigncase.Bypass_Data_enforcement__c = True;
        //         database.update(lockassigncase);
        //         } 


        //     else if (lockassigncase.OwnerId != userInfo.getUserId()){
                

        //         returnvalue=Label.SSSW_Filling_Inbox_Alert ;
  

        //          }
            
        //     }


        //     if(availableCases!=null && !availableCases.isEmpty()) 
        //     {
                
        //        // lockavailableCases = [select id,status, Bypass_Data_enforcement__c, OwnerId from case where id in  for update] ;
        //         checkFillInboxClicked = true;
        //         database.update(availableCases); 
        //     }
                
        //    /* if(lockassigncase!=null) {                 
        //         checkFillInboxClicked = true;
        //         database.update(lockassigncase); 
        //     }
        //     */
            
        //     if(!ctmList.isEmpty()) { database.upsert(ctmList); }
            
        //     if(!delCtmList.isEmpty()) { database.delete(delCtmList); }
        
        // } catch(Exception exp){
        //     // Error Logged to Exception object for analysis
        //     UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW', 
        //                                             'SSSW_FillINBox', 'wsFillInbox', 
        //                                             null, LoggingLevel.ERROR);
        // }
        
        // //either return the my cases listview ID or the error alert from custom label  22-Mar-16 Eric Shen         
        // return returnvalue; 
    } 
    
    /** 
      * @name: groupIdNames 
      * @desciption: getter setter variable to get the groups the logged in user is part of
      * @param: NA
      * @return: Map<ID,Group>
      *
      *  22-Mar-16 Eric Shen adjust return type to a Map so that group name is also returned. 
      */
 
//   static Map<ID, Group> groupIdNames {
//         get {

//               groupIdNames = new map<ID, Group>();
              
//             if(groupIdNames.isempty()) {
                
              

//                // Set<String> queueNames = new Set<String>();
//                // set<id> userRolesId = new set<id>();
//                // set<id> groupRelatedId = new set<id>();
                   
//                 //Disabling Role Check.
//                 /*
//                 if(UserInfo.getUserRoleId() != null)
//                     userRolesId.add(UserInfo.getUserRoleId());
                
//                 if(userRolesId.size()>0)
//                 {
//                   for(Group g : [Select id, g.RelatedId from Group g where relatedid IN :userRolesId])
//                   {
//                       groupRelatedId.add(g.id);
//                   }
//                 }
//                 */

//               //return login users' all queues ID and name as a map
                           
//                 for(GroupMember gm:[Select Group.Id, Group.Name From GroupMember 
//                                     where UserOrGroupId = :UserInfo.getUserId() //OR UserOrGroupId IN :groupRelatedId) 
//                                             and Group.Type = 'Queue']) {
//                     groupIdNames.put(gm.Group.Id, gm.Group);
//                     system.debug('groupidnames are' +groupidnames.values()) ;
//                 }
//             }
        
//             return groupIdNames;
//         }
//     }
    
}