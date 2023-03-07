/* 
xx-xxx-2015 - Bluewolf - Created as part of SSSW Project.
Test Class - TestCalculateMilestoneTime
/*******************************  History ************************************************
    Date                User                                        Comments
    29/05/2015          C.McIntyre                                  Added LIMIT clauses to open SOQL queries as part of apex audit.
    29/09/2015          disha.kariya@auspost.com.au                 Commented Code called from Inactive Trigger CaseTrigger.trigger
	09/02/2023			Mahesh Parvathaneni							Updated the queries with record type for method ruleIDRuleUnits
*******************************  History ************************************************/

global without sharing class CaseMileStoneUtil {   
   
    public static boolean dontUpdateMilestone = false;//Added by yuanyuan zhang to avoid update milestone when send a fax
    
    // Below Code can be removed on or after 28 Feb 2019
    // @future  
    // static void updateCharterMilestones(List<id> caseIds, boolean markAsCompleted){
    //     if(!caseIds.isEmpty()) {
    //         List<MilestoneType> mTypes = [select id from MilestoneType where name = 'Charter'];
    //         if(!mTypes.isEmpty()) {
    //             List<CaseMilestone> charterMilestones = [select completionDate from caseMilestone where caseId in: caseIds and MilestoneTypeId =: mTypes[0].id and case.Permanent_Close__c = false];
    //             for(CaseMilestone m: charterMilestones){
    //                 if(markAsCompleted && m.CompletionDate == null)
    //                 {
    //                     m.CompletionDate = datetime.now();
    //                 }
    //                 else if (!markAsCompleted)
    //                 {
    //                     m.CompletionDate = null;
    //                 }
    //             }
                
    //             try {
    //                 update charterMilestones;
    //             } catch (Exception e) {
    //                 //ignore
    //             }
    //         }
    //     }
    // }
    
    // Commented Below code as was called from Inactive Trigger CaseTrigger.trigger
    // public static void updateMilestones(Map<Id, Case> newCases, Map<Id, Case> oldCases){
    //     if (!dontUpdateMilestone) {
    //         Map<id, Case> networkCases = new Map<id, Case>();
    //         Map<id, Case> customerCases = new Map<id, Case>();
    //         Map<id, Case> internalCases = new Map<id, Case>();
    //         Map<id, List<Case>> ownerChangedCases = new Map<id, List<Case>>();
            
    //         Set<id> futureUpdatedCases = new Set<id>();
                
    //         Map<id,List<Case>> networkIdAndCases = new Map<id,List<Case>>();
    //         Set<id> validRecordTypes = Utility.getRecordTypeIds('Case', 'SSSW');
    //         Map<id,List<Case>> userIdAndCases = new Map<id,List<Case>>();
    //         List<id> closedCaseIds = new List<id>(); 
            
    //         Map<id, Contact> contacts = new Map<id, Contact>();
    //         for(Case c: newCases.values()){
    //             if(c.contactId != null && contacts.get(c.contactId) == null) {
    //                 contacts.put(c.contactId, null);
    //             }
                
    //             if((c.IsClosed && !(oldCases.get(c.id).IsClosed)) || (c.Status == 'Awaiting Customer Response' && oldCases.get(c.id).Status != 'Awaiting Customer Response')){
    //                 closedCaseIds.add(c.id);
    //             }
    //         }
            
    //         if(!system.isFuture() && closedCaseIds.size() > 0) {
    //             //System.debug('---updateCharterMilestones on Case update');
    //             updateCharterMilestones(closedCaseIds, true);
    //         }
    //         if(contacts.size()>0) {
    //             for(Contact ct: getContactsFromCache(contacts.keySet())) {
    //                 contacts.put(ct.id, ct);
    //             }
    //         }
            
    //         List<id> reopenedCaseIds = new List<id>();
            
    //         for(id caseID: newCases.keySet()){
    //             Case newCase = newCases.get(caseID);
    //             Case oldCase = oldCases.get(caseID);
                
    //             if(oldCase.OwnerId != newCase.OwnerId && string.valueOf(newCase.OwnerId).startsWith('005')){
    //                 futureUpdatedCases.add(newCase.id);
    //                 if(ownerChangedCases.containsKey(newCase.OwnerId))
    //                 {
    //                     ownerChangedCases.get(newCase.OwnerId).add(newCase);
                        
    //                 }
    //                 else
    //                 {
    //                     List<Case> ownerCases = new List<Case>();
    //                     ownerCases.add(newCase);
    //                     ownerChangedCases.put(newCase.OwnerId,ownerCases);
    //                 }
    //             }
                
    //             if((oldCase.IsClosed && !newCase.IsClosed) || ((newCase.Status != 'Awaiting Customer Response' && !newCase.IsClosed) && oldCase.Status == 'Awaiting Customer Response')){
    //                 reopenedCaseIds.add(newCase.id);
    //             }
                
    //             if(newCase.RecordTypeId != null && validRecordTypes.contains(newCase.RecordTypeId)) {
                    
    //                 /*
    //                 if(newCase.Preferred_Communication_Method__c=='Email' && contacts.get(newCase.contactId) != null){
    //                     newCase.Customer_Email_Notification__c = contacts.get(newCase.contactId).Email;
    //                 }
    //                 else{
    //                     newCase.Customer_Email_Notification__c='';
    //                 }        
    //                 */
                    
    //                 if(newCase.Facility_Milestones_Violated__c > 0 
    //                     && ((newCase.Facility_Milestones_Violated__c == 5 && newCase.IsEscalated != oldCase.IsEscalated) 
    //                             || (newCase.Facility_Milestones_Violated__c != oldCase.Facility_Milestones_Violated__c))){
    //                     networkCases.put(newCase.id, newCase);  
                        
    //                     if(newCase.Network__c != null) {
    //                         if(!networkIdAndCases.containsKey(newCase.Network__c)) {
    //                             networkIdAndCases.put(newCase.Network__c, new List<Case>());
    //                         }
    //                         networkIdAndCases.get(newCase.Network__c).add(newCase); 
    //                     }
                        
    //                 }else if(newCase.Customer_Milestones_Violated__c > 0 
    //                     && ((newCase.Customer_Milestones_Violated__c == 3 && newCase.ClosedBySystem__c != oldCase.ClosedBySystem__c) 
    //                             || (newCase.Customer_Milestones_Violated__c != oldCase.Customer_Milestones_Violated__c))){
    //                     customerCases.put(newCase.id, newCase); 
                        
    //                 }else if((newCase.Internal_Milestones_Violated__c == null || newCase.Internal_Milestones_Violated__c >= 0) 
    //                         && ((newCase.Internal_Milestones_Violated__c == 3 && newCase.IsEscalated != oldCase.IsEscalated)
    //                             || (newCase.Internal_Milestones_Violated__c != oldCase.Internal_Milestones_Violated__c))) {
    //                     internalCases.put(newCase.id, newCase); 

    //                     if(newCase.ownerId != null && !((string)newCase.ownerId).startsWith('00G')){
    //                         if(!userIdAndCases.containsKey(newCase.ownerId)) {
    //                             userIdAndCases.put(newCase.ownerId, new List<Case>());
    //                         }
    //                         userIdAndCases.get(newCase.ownerId).add(newCase);
    //                     }
    //                 }   
    //             }
    //         }
            
    //          if(!system.isFuture() && reopenedCaseIds.size() > 0) {
    //             updateCharterMilestones(reopenedCaseIds, false);
    //         }
            
    //         setEscalationEmailFromNetwork(networkIdAndCases);
    //         setEscalationEmailFromUser(userIdAndCases);
    //         setEscalationEmailFromUser(ownerChangedCases); 
            
    //         List<Task> tasks = new List<Task>();
    //         List<id> smsIds = new List<id>(TaskUtil.getRecordTypesWithDevNameContains('SSSWSMS'));
    //         Map<id, StatusTracking__c> caseIdsAndCurrentStatusTrackings = new Map<id, StatusTracking__c>();
            
    //         for(Case c: networkCases.values()){          
    //             futureUpdatedCases.add(c.id);
                
    //             if(c.Facility_Milestones_Violated__c > 1) 
    //             {
    //             //    if(c.IsEscalated)
    //             //        tasks.add(new Task(whatid=c.id, whoid=c.contactid, ActivityDate=Date.today(),subject='Email: '+c.CaseNumber+': Network Milestone '+ c.Facility_Milestones_Violated__c + ' email notification has been sent' ,status='Completed'));
    //             //    else 
    //                     tasks.add(new Task(whatid=c.id, ActivityDate=Date.today(),subject='Email: '+c.CaseNumber+': Network Milestone '+ (c.Facility_Milestones_Violated__c - 1) + ' email notification has been sent' ,status='Completed'));
    //             } 
    //         }   
    //         if(networkCases.size()>0) {
    //             for(StatusTracking__c st:[SELECT Case__c,EscalationTier__c,Case__r.Facility_Milestones_Violated__c 
    //                                    FROM StatusTracking__c 
    //                                    where Case__c in:networkCases.keySet() 
    //                                    order by Case__c,StartDate__c desc]){
    //                 if(!caseIdsAndCurrentStatusTrackings.containsKey(st.Case__c)) {
    //                     st.EscalationTier__c = st.Case__r.Facility_Milestones_Violated__c;
    //                     caseIdsAndCurrentStatusTrackings.put(st.Case__c, st);
    //                 }
    //             }
    //         }
            
    //         for(Case c: customerCases.values()) {
    //             futureUpdatedCases.add(c.id);
                
    //             if(c.Customer_Milestones_Violated__c > 1) 
    //             {
    //                 system.debug('$$$$$$$$$$$$$$ Consumer Milestone communicating via ' + c.Preferred_Communication_Method__c);
    //                 //    if(c.ClosedBySystem__c)
    //                 //        tasks.add(new Task(whatid=c.id, whoid=c.contactid, ActivityDate=Date.today(),subject='Email: '+c.CaseNumber+': Customer Milestone '+ c.Customer_Milestones_Violated__c +' email notification has been sent' ,status='Completed'));
    //                 //    else
    //                 if(c.Preferred_Communication_Method__c=='Email' && !string.isEmpty(c.Customer_Email_Notification__c))
    //                 {
    //                     tasks.add(new Task(whatid=c.id, whoid=c.contactid, ActivityDate=Date.today(),subject='Email: '+c.CaseNumber+': Customer Milestone '+ (c.Customer_Milestones_Violated__c - 1) +' email notification has been sent' ,status='Completed'));
    //                 }
                    
    //                 if(c.Preferred_Communication_Method__c=='SMS' && !smsIds.isEmpty())
    //                 {
    //                     addSMSTaskIfApplicable(c, smsIds[0], tasks);
    //                 }                   
    //             }

    //         }
    //         if(customerCases.size()>0) {
    //             for(StatusTracking__c st:[SELECT Case__c,EscalationTier__c,Case__r.Customer_Milestones_Violated__c 
    //                                    FROM StatusTracking__c 
    //                                    where Case__c in:customerCases.keySet() 
    //                                    order by Case__c,StartDate__c desc]){
    //                 if(!caseIdsAndCurrentStatusTrackings.containsKey(st.Case__c)) {
    //                     st.EscalationTier__c = st.Case__r.Customer_Milestones_Violated__c;
    //                     caseIdsAndCurrentStatusTrackings.put(st.Case__c, st);
    //                 }
    //             }
    //         }
            
    //         for(Case c: internalCases.values()) {
    //             if(c.Internal_Milestones_Violated__c > 0){
    //                 futureUpdatedCases.add(c.id);
                    
    //                 if(c.Internal_Milestones_Violated__c > 1)
    //                 {
    //                 //    if((c.Internal_Milestones_Violated__c == 3 && c.IsEscalated))
    //                 //        tasks.add(new Task(whatid=c.id, whoid=c.contactid, ActivityDate=Date.today(),subject='Email: '+c.CaseNumber+': Internal Milestone '+ c.Internal_Milestones_Violated__c +' email notification has been sent' ,status='Completed'));
    //                 //    else 
    //                         tasks.add(new Task(whatid=c.id, ActivityDate=Date.today(),subject='Email: '+c.CaseNumber+': Internal Milestone '+ (c.Internal_Milestones_Violated__c - 1) +' email notification has been sent' ,status='Completed'));
    //                 }
    //             } 
    //         }     
    //         if(internalCases.size()>0) {   
    //             for(StatusTracking__c st:[SELECT Case__c,EscalationTier__c,Case__r.Internal_Milestones_Violated__c 
    //                                    FROM StatusTracking__c 
    //                                    where Case__c in:internalCases.keySet() 
    //                                    order by Case__c,StartDate__c desc]){
    //                 if(!caseIdsAndCurrentStatusTrackings.containsKey(st.Case__c)) {
    //                     st.EscalationTier__c = st.Case__r.Internal_Milestones_Violated__c;
    //                     caseIdsAndCurrentStatusTrackings.put(st.Case__c, st);
    //                 }
    //             }     
    //         }
    //         if(!system.isFuture()) {
    //             if(!tasks.isEmpty()){
    //                 if(!smsIds.isEmpty()) { 
    //                     for(Task t: tasks){
    //                         if(t.RecordTypeId == smsIds[0] && t.whoID != null && String.valueOf(t.whoId).startsWith(Contact.SObjectType.getDescribe().getKeyPrefix())) {
    //                             system.debug('$$$$$$$$$$$$$$ Getting SMS Message for task id: ' + t.id);
    //                             t.SMSMessage__c = Util.getBodyFromEmailTemplate('SMSCustomerMilestone', t.whoId, t.whatId);
    //                             system.debug('$$$$$$$$$$$$$$ message: ' + t.SMSMessage__c);
    //                         }
    //                     }
    //                 }
    //                 insert tasks;
    //             }
                
    //             if(!caseIdsAndCurrentStatusTrackings.isEmpty()){
    //                 update caseIdsAndCurrentStatusTrackings.values();
    //             }     
                
    //             if(futureUpdatedCases.size() > 0){                      
    //                 futureUpdateTheCases(new List<id>(futureUpdatedCases));
    //             }
    //         }
    //     }
    // }
        
    // @future
    // public static void futureUpdateTheCases(List<id> caseIds){
    //     List<Case> cases = [select id from Case where id in: caseIds];
    //     for(Case c: cases){
    //         c.Bypass_Data_enforcement__c = true;
    //     }
    //     update cases;
    // }
    
    // static Map<id, Contact> cachedContacts {get{if(cachedContacts == null) cachedContacts = new Map<id, Contact>(); return cachedContacts;}}
    // static List<Contact> getContactsFromCache(Set<id> keys) {
    //     List<Contact> result = new List<Contact>();
    //     Set<id> notLoadedKeys = new Set<id>();
        
    //     for(id key: keys){
    //         if(cachedContacts.containsKey(key)){
    //             if(cachedContacts.get(key) != null) {
    //                 result.add(cachedContacts.get(key));
    //             }
    //         }else{
    //             notLoadedKeys.add(key);
    //             cachedContacts.put(key, null);
    //         }
    //     }
    //     if(!notLoadedKeys.isEmpty()){
    //         for(Contact r: [select id, email from Contact where id in:notLoadedKeys]){
    //             result.add(r);
    //             cachedContacts.put(r.id, r);
    //         }
    //     }
    //     return result;
    // }
    
    // public static void insertMilestones(List<Case> newCases){
    //     List<Entitlement> entitlements = [select id, name, Account.Name from Entitlement WHERE Account.Name = 'SSSW Entitlements'];
    //     List<Case_Entitlement_Status__c> entitlementStatuses = [select Customer__c, Facility__c, Internal__c from Case_Entitlement_Status__c LIMIT 100];
    //     Set<id> validRecordTypes = Utility.getRecordTypeIds('Case', 'SSSW');
    //     Map<id,List<Case>> networkIdAndCases = new Map<id,List<Case>>();
    //     Map<id,List<Case>> userIdAndCases = new Map<id,List<Case>>();
    //     List<id> closedCaseIds = new List<id>(); 
         
    //     Map<id, Contact> contacts = new Map<id, Contact>();
    //     for(Case c: newCases){
    //         if(c.contactId != null && contacts.get(c.contactId) == null) {
    //             contacts.put(c.contactId, null);
    //         }
            
    //         //System.debug('---is calse closed: ' + c.IsClosed);
    //         if(c.IsClosed){
    //             closedCaseIds.add(c.id);
    //         }
    //     }
    //     //System.debug('--new cases: ' + newCases);
    //     if(!system.isFuture() && closedCaseIds.size() > 0) {
    //         //System.debug('---updateCharterMilestones on Case insert');
    //         updateCharterMilestones(closedCaseIds, true);
    //     }
        
    //     for(Contact ct: getContactsFromCache(contacts.keySet())) {
    //         contacts.put(ct.id, ct);
    //     }

    //     for(Case c: newCases) {
    //         if(!entitlements.isEmpty() && c.RecordTypeId != null && validRecordTypes.contains(c.RecordTypeId)){
    //             c.EntitlementId = entitlements[0].id;
    //         }
            
    //         /*
    //         if(c.Preferred_Communication_Method__c == 'Email' && contacts.get(c.contactId) != null){
    //             c.Customer_Email_Notification__c = contacts.get(c.contactId).Email;
    //         } else {
    //             c.Customer_Email_Notification__c = '';
    //         }
    //         */
            
    //         if(!entitlementStatuses.isEmpty() && c.Status != null){
    //             if(entitlementStatuses[0].Facility__c != null && entitlementStatuses[0].Facility__c.containsIgnoreCase(c.Status)){
    //                 c.Facility_Milestones_Violated__c = 1;
                    
    //                 if(c.Network__c != null) {
    //                     if(!networkIdAndCases.containsKey(c.Network__c)) {
    //                         networkIdAndCases.put(c.Network__c, new List<Case>());
    //                     }
    //                     networkIdAndCases.get(c.Network__c).add(c); 
    //                 }
                    
    //             } else if(entitlementStatuses[0].Customer__c != null && entitlementStatuses[0].Customer__c.containsIgnoreCase(c.Status)){
    //                 c.Customer_Milestones_Violated__c = 1;
                    
    //             } else if(entitlementStatuses[0].Internal__c != null && entitlementStatuses[0].Internal__c.containsIgnoreCase(c.Status)){
    //                 c.Internal_Milestones_Violated__c = 1;
    //             }
    //         }
            
    //         if((c.Internal_Milestones_Violated__c == null || c.Internal_Milestones_Violated__c == 0) && c.ownerId != null && !((string)c.ownerId).startsWith('00G')){
    //             if(!userIdAndCases.containsKey(c.ownerId)) {
    //                 userIdAndCases.put(c.ownerId, new List<Case>());
    //             }
    //             userIdAndCases.get(c.ownerId).add(c);
    //         }
    //     }
        
    //     setEscalationEmailFromNetwork(networkIdAndCases);
    //     setEscalationEmailFromUser(userIdAndCases);
    // }
    
    // static void addSMSTaskIfApplicable(Case c, id smsRecordTypeId, List<Task> tasks){
        
    //     if(c.Preferred_Communication_Method__c=='SMS') {
    //         tasks.add(new Task(whatid=c.id, 
    //                            whoid=c.contactid,  
    //                            ActivityDate=Date.today(),
    //                            recordtypeid=smsRecordTypeId,
    //                            //SMSMessage__c = 'Australia Post update for Case: ' + c.casenumber + ' is available. Please check your email. Do not reply to this message',
    //                            subject='SMS notification has been sent for Case:' + c.casenumber));
    //     }   
    // }
    
    // static void setEscalationEmailFromUser(Map<id,List<Case>> userIdAndCases) { 
    //     System.debug('###BW### Size of Users: ' + userIdAndCases.size());
    //     System.debug('###BW### Users: ' + userIdAndCases);
    //     if(!userIdAndCases.isEmpty()){
    //         Map<decimal, string> escalationIndexedEmail = null;
    //         for(User u: [Select Manager.Manager.Email,Manager.Email, email,id From User where id in: userIdAndCases.keySet()]) {
    //             escalationIndexedEmail = new Map<decimal, string>();
    //             escalationIndexedEmail.put(0, u.Manager.Email);
    //             escalationIndexedEmail.put(1, u.Email); //This should never be used by workflow - sent on number increment.
    //             escalationIndexedEmail.put(2, u.Email);
    //             escalationIndexedEmail.put(3, u.Manager.Email);
    //             escalationIndexedEmail.put(4, u.Manager.Manager.Email);
                    
    //             for(Case c: userIdAndCases.get(u.id)){
    //                 System.debug('###BW### Internal_Milestones_Violated__c = :' + c.Internal_Milestones_Violated__c);
    //                 System.debug('###BW### Setting Email = :' + escalationIndexedEmail.get(c.Internal_Milestones_Violated__c != null ? c.Internal_Milestones_Violated__c : 0));
    //                 c.Internal_Tier_Escalation_Email__c = escalationIndexedEmail.get(c.Internal_Milestones_Violated__c != null ? c.Internal_Milestones_Violated__c : 0);
    //             }
    //         }
    //     }
    // }
    
    // static void setEscalationEmailFromNetwork(Map<id,List<Case>> networkIdAndCases){
    //     if(!networkIdAndCases.isEmpty()){
    //         Map<decimal, string> escalationIndexedEmail = null;
                                                      
    //         for(Network__c n: [select Email_1__c,Email_2__c,Email_3__c,Email_4__c,Email_5__c 
    //                            from Network__c 
    //                            where id in:networkIdAndCases.keySet()]){
                                
    //             escalationIndexedEmail = new Map<decimal, string>();
    //             escalationIndexedEmail.put(1, ''); //This should never be met.
    //             escalationIndexedEmail.put(2, n.Email_1__c); //Email 1 is sent once it moves to Teir 2.
    //             escalationIndexedEmail.put(3, n.Email_2__c);
    //             escalationIndexedEmail.put(4, n.Email_3__c);
    //             escalationIndexedEmail.put(5, n.Email_4__c);
    //             escalationIndexedEmail.put(6, n.Email_5__c);
                
    //             for(Case c: networkIdAndCases.get(n.id)) {
    //                 string escalationEmail = escalationIndexedEmail.get(c.Facility_Milestones_Violated__c);
    //                 /*while(string.isEmpty(escalationEmail) && c.Facility_Milestones_Violated__c <= 5) {
    //                     escalationEmail = escalationIndexedEmail.get(++c.Facility_Milestones_Violated__c);
    //                 }*/
    //                 c.Facility_Tier_Escalation_Email__c = escalationEmail;
    //             }
    //         }
    //     }
    // }
     
    // public static void setCharterMilestones(List<Case> newCases) {
    //     Set<id> shortListed = new Set<id>();
    //     for(Case c: newCases){
    //         if(c.SLATargetDate__c == null || (c.CustomerTierSLA__c == null && c.Status == 'Awaiting Customer Response')) {
    //             shortListed.add(c.id);
    //         }
    //     }
    //     if(shortListed.size() > 0 && !System.isFuture()) {
    //         futureSetCharterMilestones(shortListed);
    //     }
    // }
    
    // @future
    // static void futureSetCharterMilestones(Set<id> caseIds){
    //     if(!caseIds.isEmpty()) {
    //         List<Case> shortListed = new List<Case>();
    //         for(Case c: [select SLATargetDate__c,CustomerTierSLA__c,Previous_Milestone_Time__c, CreatedDate, ParentId from Case where id in:caseIds and Parentid = null]){
    //             shortListed.add(c);
    //         }
            
    //         Map<id,CaseMilestone> cms = new Map<id,CaseMilestone>();
    //         for(CaseMilestone cm : [Select TargetDate, CaseId 
    //                                 From CaseMilestone 
    //                                 where caseid in:caseIds and MileStoneType.Name='Charter']) {
                
    //             if(!cms.containsKey(cm.caseId)){
    //                 cms.put(cm.caseId, cm);
    //             }
    //         }
                                    
    //         Map<id,CaseMilestone> custTier = new Map<id,CaseMilestone>();
    //         for(CaseMilestone cm : [Select TargetDate, CaseId, CaseMilestone.MilestoneType.Name
    //                                 From CaseMilestone 
    //                                 where caseid in:caseIds and MileStoneType.Name like 'Customer Tier%' order by CreatedDate asc]) 
    //         {
    //             //Will always return the newest Customer Tier to the Map for the Case.
    //             custTier.put(cm.caseId, cm);
    //         }                                   
            
    //         Map<String,Id> bHMap = new Map<String,Id>();
    //         for (BusinessHours bHour: [Select Id, Name, TimeZoneSidKey from BusinessHours LIMIT 100])
    //         {
    //             bHMap.put(bHour.Name,bHour.Id);     
    //         }
    //         User currentUser = [select TimeZoneSidKey from user where id =: UserInfo.getUserId()];
    //         id bizHourId = CaseTrackingUtility.getsopsBusinessHoursId(bHMap, currentUser.TimeZoneSidKey);
            
    //         MilestoneWarningTime__c settings = MilestoneWarningTime__c.getValues('Charter');
    //         decimal percentage = 0.2;  
    //         if(settings != null) {
    //             percentage = MilestoneWarningTime__c.getValues('Charter').Percentage__c / 100;
    //         }
            
    //         datetime now = DateTime.Now();
    //         for(Case c: shortListed) 
    //         {
    //             if(cms.containsKey(c.id)) 
    //             {
    //                 CaseMilestone cm = (CaseMilestone)cms.get(c.id);
    //                 c.SLATargetDate__c = cm.TargetDate;
                    
    //                 long bizDiffInSeconds = BusinessHours.diff(bizHourId, now, c.SLATargetDate__c);
    //                 long warningTargetInSeconds = bizDiffInSeconds - (bizDiffInSeconds * percentage).longValue();
    //                 c.MilestoneWarningTarget__c = BusinessHours.add(bizHourId, now, warningTargetInSeconds);
    //                 c.Bypass_Data_enforcement__c = true;
    //             }
                
    //             if(custTier.containsKey(c.id)) // && c.Customer_Milestones_Violated__c != null) 
    //             {
    //                 CaseMilestone custMilestone = (CaseMilestone)custTier.get(c.id);
    //                 System.debug('XXXBWXXX:MileStone - ' + custMilestone);
    //                 System.debug('XXXBWXXX:c.Customer_Milestones_Violated__c = '+c.Customer_Milestones_Violated__c);
    //                 System.debug('XXXBWXXX:Previous_Milestone_Time__c - ' + c.Previous_Milestone_Time__c);
                    
    //                 if (c.Previous_Milestone_Time__c == null)
    //                 {
    //                     c.CustomerTierSLA__c = custMilestone.TargetDate;
    //                     c.Previous_Milestone_Time__c = custMilestone.TargetDate;
    //                     c.Bypass_Data_enforcement__c = true;
    //                 }
    //                 else if (custMilestone.TargetDate > c.Previous_Milestone_Time__c)
    //                 {
    //                     c.CustomerTierSLA__c = custMilestone.TargetDate;
    //                     c.Previous_Milestone_Time__c = custMilestone.TargetDate;
    //                     c.Bypass_Data_enforcement__c = true;
    //                 }
    //             }
    //         }
    //         update shortListed;
    //     }
    // }
    
    public static Map<String, List<String>> ruleIDRuleUnits {
        get {
            if(ruleIDRuleUnits == null){
                ruleIDRuleUnits = new Map<String, List<String>>();
                for (Entitlement_Rule__c er :[Select Rule__c From Entitlement_Rule__c where Active__c = true AND RecordType.DeveloperName = 'SSSW_Case' order by lastmodifieddate desc limit 50000]) {
                    ruleIDRuleUnits.put(er.Id, er.Rule__c.split('\\|\\|'));                     
                }
            }
            return ruleIDRuleUnits;
        } private set;
    }
    
    public static Map<id, Entitlement_Rule__c> cachedEntitlementRules {
        get{
            if(cachedEntitlementRules == null){
                cachedEntitlementRules = new Map<id, Entitlement_Rule__c>([Select Escalation_Hierarchy__c From Entitlement_Rule__c LIMIT 200]);
            }
            return cachedEntitlementRules;
        } private set;
    }
    
    public static Map<id, MileStoneType> cachedMileStoneTypes {
        get {
            if(cachedMileStoneTypes == null) {
                cachedMileStoneTypes = new Map<id, MileStoneType>([select name from MileStoneType LIMIT 100]);
            }
            return cachedMileStoneTypes;
        } private set;
    }
    
    public static Map<id, Escalation_Hierarchy__c> cachedEscalationHierarchies {
        get{
            if(cachedEscalationHierarchies == null){
                cachedEscalationHierarchies = new Map<id, Escalation_Hierarchy__c>([Select Internal_Tier_1__c, Internal_Tier_3__c, Internal_Tier_2__c ,Facility_Tier_4__c,Facility_Tier_5__c,Facility_Tier_3__c, Facility_Tier_2__c, Facility_Tier_1__c, Customer_Tier_3__c, Customer_Tier_2__c, Customer_Tier_1__c From Escalation_Hierarchy__c LIMIT 100]);
            }
            return cachedEscalationHierarchies;
        } private set;
    }
}