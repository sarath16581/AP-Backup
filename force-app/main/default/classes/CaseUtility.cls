/**************************************************
Type:       Utility Class for Case Object
Purpose:    
Used By:    CaseTrigger
History:
--------------------------------------------------
27.09.2012  M. Isidro (Cloud Sherpas)   Created
03.10.2012  M. Isidro (Cloud Sherpas)   Added functionality for OPC Sales Manager Exception for Renewals (Corresponding Growth OPC should also be flagged)
17.10.2012  R. Enojas (Salesforce.com)  Commented code that flags Growth OPC once Renewal OPC is flagged
23.09.2013  C. Andronaco (Bluewolf) Added Sales Operations Code for Creating the Case Status Tracking Records.
25.03.2014  george.nguyen@bluewolf.com added assignFacilityToCase
09/07/2015  Eric.Shen@auspost.com.au     Updated    StageName = 'Identify'
31/07/2015  christopher.henschke@auspost.com.au    Updated     Added Gold SLA option
08/09/2017  maumita.bandyopadhyay@auspost.com.au   Updated     Added logic to consider only Closed cases for NPS
20/11/2017	maumita.bandyopadhyayauspost.com.au  Commented out status checking to fix INC1035423
25/06/2018  disha.kariya@auspost.com.au  Removed NPSRequired__c and commented checkNPS and checkOriginChangeForNPS method.
2018-07-09  nathan.franklin@auspost.com.au  Removed checkNPS and checkOriginChangeForNPS methods as they are not used anymore
2018-07-12  nathan.franklin@auspost.com.au  Code tidy ups, commented out all non-used code
**************************************************/
public with sharing class CaseUtility {


    public static Set<id> getRecordTypesWithDevNameContains(string devName){
        Set<id> result = new Set<id>();
        for(RecordType t: caseRecordTypes){
            if(t.DeveloperName.contains(devName)){
                result.add(t.id);
            }
        }
        return result;
    }

    public static id getRecordIdWithDevName(string devName){
        id result = null;
        for(RecordType t: caseRecordTypes){
            if(t.DeveloperName == devName){
                result = t.id;
                break;
            }
        }
        return result;
    }
    static List<RecordType> caseRecordTypes{
        get {
            if(caseRecordTypes == null){
                caseRecordTypes = [select id,developerName,name from RecordType where SObjectType='Case'];
            }
            return caseRecordTypes;
        }
    }



// Below Code can be removed on or after 28 Feb 2019

//    public static void linkCaseToArticles(Map<id, Case> newMap){
//        Set<String> refIds = new Set<String>();
//        for(Case c: newMap.values()){
//            if(c.Origin != 'Phone' && c.Origin != 'AP Retail (PM26)' && c.ArticleTest__c == null && !String.isBlank(c.referenceId__c)) {
//                refIds.add(c.referenceId__c);
//            }
//        }
//        if(!refIds.isEmpty()) {
//            linkCaseToArticles(refIds);
//        }
//    }
//
//    @future(callout=true)
//    static void linkCaseToArticles(Set<String> refIds){
//        TIBCOArticleService.searchArticles(new List<String>(refIds), true, false, false, true);
//    }
//
//    public static void setNPSScheduleDate(Map<id, Case> newMap, Map<id, Case> oldMap){
//        Map<id, Contact> relatedContacts = new Map<id, Contact>();
//        Map<id, Case> shortListed = new Map<id, Case>();
//        for(Case c: newMap.values()){
//            if(!String.isBlank(c.contactId) && c.NPSScheduledDate__c != null && newMap.get(c.id).NPSScheduledDate__c != oldMap.get(c.id).NPSScheduledDate__c){
//                relatedContacts.put(c.contactId, null);
//                shortListed.put(c.id, c);
//            }
//        }
//        if(relatedContacts.size()>0) {
//            relatedContacts = new Map<id, Contact>([select LastNPSDate__c from Contact where id in :relatedContacts.keySet()]);
//            List<Contact> contactsToUpdate = new List<Contact>();
//            for(Case c: shortListed.values()){
//                Contact currentContact = relatedContacts.get(c.contactId);
//                if(currentContact.LastNPSDate__c == null || currentContact.LastNPSDate__c < c.NPSScheduledDate__c){
//                    currentContact.LastNPSDate__c = c.NPSScheduledDate__c;
//                    contactsToUpdate.add(currentContact);
//                }
//            }
//            if(!contactsToUpdate.isEmpty()){
//                update contactsToUpdate;
//            }
//        }
//    }
//
//
//    public static void detectPermanentSpam(List<Case> newCases){
//        Map<String, List<Case>> shortListed = new Map<String, List<Case>>();
//        for(Case c: newCases){
//            if(!string.isBlank(c.SuppliedEmail)) {
//                if(shortListed.get(c.SuppliedEmail) == null){
//                    shortListed.put(c.SuppliedEmail, new List<Case>());
//                }
//                shortListed.get(c.SuppliedEmail).add(c);
//            }
//        }
//        Set<String> blackListedEmails = new Set<String>();
//        for(SpamEmail__c s: [select FromEmail__c from SpamEmail__c where FromEmail__c in :shortListed.keySet()]){
//            blackListedEmails.add(s.FromEmail__c);
//        }
//        for(String email: shortListed.keySet()){
//            if(blackListedEmails.contains(email)){
//                for(Case c: shortListed.get(email)){
//                    c.Prevent_Email__c = true;
//                }
//            }
//        }
//    }
//
//    static RecordType directEmailRecordType{
//        get{
//            if(directEmailRecordType == null){
//                directEmailRecordType = [select id from RecordType where developerName = 'NCCCDirectEmail' limit 1];
//            }
//            return directEmailRecordType;
//        }
//    }
//
//    public static Set<id> getRecordTypesWithDevNameContainsIncludingDirectEmail(string devName){
//        Set<id> result = getRecordTypesWithDevNameContains(devName);
//        if(directEmailRecordType != null) {
//            result.add(directEmailRecordType.id);
//        }
//        return result;
//    }
//    public static void validateCase(List<Case> newCases) {
//        UniqueCaseTrigger__c CanIContinue = UniqueCaseTrigger__c.getOrgDefaults();
//        if(CanIContinue.Enabled__c) {
//            List<String> uniqueValueList = new List<String>();
//            for(Case newCase : newCases) {
//                newCase.Unique_Case__c = newCase.ContactId+newCase.EnquirySubType__c+newCase.Type+newCase.ReferenceID__c+newCase.ParentId+newCase.isClosed;
//                if(newCase.ContactId != null && newCase.ReferenceID__c != '' && newCase.ReferenceID__c != null && newCase.ArticleTest__c == null) {
//                    uniqueValueList.add(newCase.Unique_Case__c);
//                }
//                if(newCase.ProductCategory__c!=null && newCase.ProductCategory__c.toLowerCase().contains(CanIContinue.CaseLocality__c.toLowerCase())) {
//                    newCase.CaseLocality__c = CanIContinue.CaseLocality__c;
//                }
//            }
//            system.debug('UNIQUE**'+CanIContinue.ProfileIds__c+' ALSO'+UserInfo.getProfileId());
//            if(uniqueValueList.size()>0 && CanIContinue.ProfileIds__c.contains(UserInfo.getProfileId().substring(0,15))) {
//                Map<String,Case> existingMatchCriteria = new Map<String,Case>();
//                for(Case newCase : [Select Id, CaseNumber, Unique_Case__c from case where Unique_Case__c in :uniqueValueList]) {
//                    existingMatchCriteria.put(newCase.Unique_Case__c,newCase);
//                }
//                for(Case newCase : newCases) {
//                    if(newCase.ContactId != null && newCase.ReferenceID__c != '' && newCase.ReferenceID__c != null && newCase.ArticleTest__c == null && existingMatchCriteria.containsKey(newCase.unique_Case__c)) {
//                        newCase.addError('The system has a similar case already:'+existingMatchCriteria.get(newCase.unique_Case__c).CaseNumber);
//                    }
//                }
//            }
//        }
//    }
//
//    public static void validateCase(Map<Id,Case> newCases) {
//        UniqueCaseTrigger__c CanIContinue = UniqueCaseTrigger__c.getOrgDefaults();
//        if(CanIContinue.Enabled__c) {
//            List<String> uniqueValueList = new List<String>();
//            for(Case newCase : newCases.values()) {
//                newCase.Unique_Case__c = newCase.ContactId+newCase.EnquirySubType__c+newCase.Type+newCase.ReferenceID__c+newCase.ParentId+newCase.isClosed;
//                if(newCase.ContactId != null && newCase.ReferenceID__c != '' && newCase.ReferenceID__c != null && newCase.ArticleTest__c == null) {
//                    uniqueValueList.add(newCase.Unique_Case__c);
//                }
//                if(newCase.ProductCategory__c!=null && newCase.ProductCategory__c.toLowerCase().contains(CanIContinue.CaseLocality__c.toLowerCase())) {
//                    newCase.CaseLocality__c = CanIContinue.CaseLocality__c;
//                }
//            }
//            system.debug('UNIQUE**'+CanIContinue.ProfileIds__c+' ALSO'+UserInfo.getProfileId());
//            if(uniqueValueList.size()>0 && CanIContinue.ProfileIds__c.contains(UserInfo.getProfileId().substring(0,15))) {
//                Map<String,Case> existingMatchCriteria = new Map<String,Case>();
//                for(Case newCase : [Select Id, CaseNumber, Unique_Case__c from case where Unique_Case__c in :uniqueValueList]) {
//                    existingMatchCriteria.put(newCase.Unique_Case__c,newCase);
//                }
//                for(Case newCase : newCases.values()) {
//                    if(newCase.ContactId != null && newCase.ReferenceID__c != '' && newCase.ReferenceID__c != null && newCase.ArticleTest__c == null && existingMatchCriteria.containsKey(newCase.unique_Case__c) && newCase.Id <> (existingMatchCriteria.get(newCase.unique_Case__c).Id)) {
//                        newCase.addError('The system has a similar case already:'+existingMatchCriteria.get(newCase.unique_Case__c).CaseNumber);
//
//                    }
//                }
//            }
//        }
//    }
//
//    public static void setArticlesSubscribed(Map<Id, Case> newCases, Map<Id, Case> oldCases) {
//        Set<Id> subscribedArticles = new Set<Id>();
//        for (Case newCase : newCases.values()) {
//            Case oldCase = oldCases.get(newCase.Id);
//
//            if (newCase.Subscribed__c && newCase.ArticleTest__c != null) {
//                subscribedArticles.add(newCase.ArticleTest__c);
//            }
//        }
//
//        if (subscribedArticles.size() > 0) {
//            List<Article__c> articlesToUpdate = new List<Article__c>();
//            for (Article__c a : [SELECT Subscribed__c FROM Article__c WHERE Id IN :subscribedArticles AND Subscribed__c = false]) {
//                a.Subscribed__c = true;
//                articlesToUpdate.add(a);
//            }
//
//            if (articlesToUpdate.size() > 0) {
//                update articlesToUpdate;
//            }
//        }
//    }
//
//    public static void createAccounts(List<Account> accList, List<Case> existingCases) {
//        if(accList.size()>0)
//        {
//            system.debug(accList);
//            insert accList;
//            for(Account myAcc : [Select PersonEmail, FirstName, LastName, PersonContactId from Account where Id in :accList])
//            {
//                for(Case c: existingCases)
//                {
//                    if(c.SuppliedEmail == myAcc.PersonEmail && c.First_Name__c == myAcc.FirstName && c.Last_Name__c == myAcc.LastName)
//                    {
//                        c.contactId = myAcc.PersonContactId;
//                    }
//                }
//            }
//        }
//    }

//    public static void assignContactIDToCase(list<Case> cases){
//        system.debug('########################## processing assignContactIDToCase...');
//        list<Case> shortListedCases = new list<Case>();
//        list<string> emails = new list<string>();
//        list<Case> shortListedCasesEmail = new list<Case>();
//        list<string> emailsOfEmailOrigin = new list<string>();
//        for(Case c: cases){
//            if(c.Origin != 'Portal' && c.Origin != 'Email' && c.contactId == null && c.SuppliedEmail != null && c.First_Name__c != null && c.Last_Name__c != null) {
//                emails.add(c.SuppliedEmail);
//                shortListedCases.add(c);
//            }
//            else if(c.Origin== 'Email' && c.SuppliedEmail != null) {
//                emailsOfEmailOrigin.add(c.SuppliedEmail);
//                shortListedCasesEmail.add(c);
//            }
//        }
//        if(emailsOfEmailOrigin.size()>0) {
//            map<string,List<Contact>> mappedContacts = new map<string,List<Contact>>();
//            for(contact ct: [select id,email from contact where email in :emailsOfEmailOrigin]){
//                List<contact> contacts = new List<contact>();
//                if(mappedContacts.get(ct.email) == null){
//                    contacts.add(ct);
//                } else {
//                    contacts = mappedContacts.get(ct.email);
//                    contacts.add(ct);
//                }
//                mappedContacts.put(ct.email,contacts);
//            }
//            for(Case c: shortListedCasesEmail){
//                if(mappedContacts.get(c.suppliedEmail)<>null && mappedContacts.get(c.suppliedEmail).size()==1) {
//                    c.contactId = mappedContacts.get(c.suppliedEmail)[0].id;
//                }
//            }
//        }
//        if(emails.size() > 0) {
//            map<string,List<Contact>> mappedContacts = new map<string,List<Contact>>();
//            for(contact ct: [select id,email,createddate,FirstName,LastName, BillingAccount__r.Customer_Number__c,
//                isPersonAccount from contact where
//                email in :emails order by email, CRMCSSOID__c Nulls Last, APCN__c Nulls Last,createddate]){
//                List<contact> contacts = new List<contact>();
//                if(mappedContacts.get(ct.email) == null){
//                    contacts.add(ct);
//                } else {
//                    contacts = mappedContacts.get(ct.email);
//                    contacts.add(ct);
//                }
//                mappedContacts.put(ct.email,contacts);
//            }
//            List<Account> accList = new List<Account>();
//            List<Case> existingCases = new List<Case>();
//            for(Case c: shortListedCases){
//                if(mappedContacts.get(c.suppliedEmail)<>null) {
//                    for(Contact ct : mappedContacts.get(c.suppliedEmail)) {
//                        if(ct != null && !string.isEmpty(ct.FirstName)&& !string.isEmpty(ct.LastName)) {
//                            system.debug('**FN, LN'+ct.FirstName+ct.LastName);
//                            system.debug('**FN, LN'+c.First_Name__c+c.Last_Name__c);
//                            if(ct.FirstName.equalsIgnoreCase(c.First_Name__c) && ct.LastName.equalsIgnoreCase(c.Last_Name__c) && ct.isPersonAccount) {
//                                c.contactId = ct.id;
//                            }
//                            else if(ct.FirstName.equalsIgnoreCase(c.First_Name__c) &&
//                                ct.LastName.equalsIgnoreCase(c.Last_Name__c) &&
//                                ct.BillingAccount__r.Customer_Number__c == c.Billing_Number__c &&
//                                !ct.isPersonAccount) {
//                                c.contactId = ct.id;
//                            }
//
//                        }
//                    }
//                }
//                if(string.isEmpty(String.valueOf(c.contactId)) && String.isEmpty(c.Billing_Number__c))
//                {
//                    Account myPA = new Account(FirstName = c.First_Name__c, LastName = c.Last_Name__c, PersonEmail= c.SuppliedEmail, PersonMobilePhone = c.SuppliedPhone);
//                    accList.add(myPA);
//                    existingCases.add(c);
//                }
//            }
//            createAccounts(accList,existingCases);
//        }
//    }
//
//    public static List<Group> queueGroups{
//        get{
//            if(queueGroups == null) {
//                queueGroups = [select id,developername,name from Group where Type='Queue'];
//            }
//            return queueGroups;
//        }
//    }
//
//    static List<Group> getMatchingQueueGroup(Set<id> routingQueueIds, Set<string> defaultQueueMappings){
//        List<Group> result = new List<Group>();
//        for(Group g: queueGroups){
//            if(routingQueueIds.contains(g.id) || defaultQueueMappings.contains(g.developerName)){
//                result.add(g);
//            }
//        }
//        return result;
//    }

//    static Map<string, SSSWRouting__c> cachedRoutings {get{if(cachedRoutings == null) cachedRoutings = new Map<string, SSSWRouting__c>(); return cachedRoutings;}}
//    public static List<SSSWRouting__c> getRoutingsFromCache(Set<string> caseKeys) {
//        List<SSSWRouting__c> result = new List<SSSWRouting__c>();
//        Set<string> notLoadedKeys = new Set<string>();
//
//        for(string key: caseKeys){
//            if(cachedRoutings.containsKey(key)){
//                if(cachedRoutings.get(key) != null) {
//                    result.add(cachedRoutings.get(key));
//                }
//            }else{
//                notLoadedKeys.add(key);
//                cachedRoutings.put(key, null);
//            }
//        }
//        if(!notLoadedKeys.isEmpty()){
//            for(SSSWRouting__c r: [select Network__c,CaseKey__c,ExcludeFromNPS__c, DefaultCaseDetails__c,Queue_ID__c,AutoEscalate__c from SSSWRouting__c where CaseKey__c in:notLoadedKeys]){
//                result.add(r);
//                cachedRoutings.put(r.CaseKey__c, r);
//            }
//        }
//        return result;
//    }
//
//    public static void assignFacilityToCase(List<Case> cases, boolean isNew)
//    {
//        Map<string, SSSWRouting__c> mappedRoutings = new Map<string, SSSWRouting__c>();
//        List<Case> shortListed = new List<Case>();
//        for(Case c : Cases) {
//            system.debug('c.Network__c: ' + c.Network__c);
//            system.debug('c.Description: ' + c.Description);
//            system.debug('c.AllocateToQueue__c: ' + c.AllocateToQueue__c);
//
//            if(c.Network__c == null || string.isEmpty(c.Description) || isNew || (c.AllocateToQueue__c != null && c.AllocateToQueue__c))
//            {
//                shortListed.add(c);
//
//                string key = '';
//                string key1 = '';
//                if(c.ProductCategory__c != null) key += c.ProductCategory__c;
//                if(c.ProductSubCategory__c != null) key += c.ProductSubCategory__c;
//                if(c.Type != null) key += c.Type;
//                if(c.EnquirySubType__c != null) key += c.EnquirySubType__c;
//                if(c.Customer_Type__c != null) key += c.Customer_Type__c;
//                if(c.IsNewForRouting__c) key += 'true'; else  key += 'false';
//                key1 = key;
//                if(c.Origin != null) key += c.Origin;
//
//
//                mappedRoutings.put(key, null);
//                mappedRoutings.put(key1, null);
//            }
//        }
//
//        Set<id> routingQueueIds = new Set<id>();
//        if(mappedRoutings.size()>0) {
//            for(SSSWRouting__c r : getRoutingsFromCache(mappedRoutings.keySet())){
//                mappedRoutings.put(r.CaseKey__c, r);
//                routingQueueIds.add(r.Queue_ID__c);
//            }
//        }
//
//        Map<string, id> defaultQueueMappings = new Map<string, id>();
//        defaultQueueMappings.put('SSSWInternationalBackOffice', null);
//        defaultQueueMappings.put('SSSWConsumerBackOffice', null);
//        defaultQueueMappings.put('SSSWEnterpriseBackOffice', null);
//        defaultQueueMappings.put('SSSWBusinessBackOffice', null);
//
//        Map<id, string> routingQueueMappings = new Map<id, string>();
//        if(defaultQueueMappings.size()>0) {
//            for(Group g: getMatchingQueueGroup(routingQueueIds, defaultQueueMappings.keySet())){
//                routingQueueMappings.put(g.id, g.developerName);
//                defaultQueueMappings.put(g.developerName, g.id);
//            }
//        }
//
//        for(Case c : shortListed) {
//            string key = '';
//            string key1 = '';
//            if(c.ProductCategory__c != null) key += c.ProductCategory__c;
//            if(c.ProductSubCategory__c != null) key += c.ProductSubCategory__c;
//            if(c.Type != null) key += c.Type;
//            if(c.EnquirySubType__c != null) key += c.EnquirySubType__c;
//            if(c.Customer_Type__c != null) key += c.Customer_Type__c;
//            if(c.IsNewForRouting__c) key += 'true'; else  key += 'false';
//            key1 = key;
//            if(c.Origin != null) key += c.Origin;
//
//            if(mappedRoutings.containsKey(key) && mappedRoutings.get(key) != null) {
//                SSSWRouting__c r = mappedRoutings.get(key);
//                if(c.Network__c == null) {
//                    c.Network__c = r.Network__c;
//                }
//
//                if(string.isEmpty(c.Description) || isNew){
//                    c.Description = (c.Description != null && !string.isEmpty(c.Description) ? c.Description +'\n' : '') + (r.DefaultCaseDetails__c != null && !string.isEmpty(r.DefaultCaseDetails__c) ? r.DefaultCaseDetails__c : '');
//                }
//
//                if(c.AllocateToQueue__c != null && c.AllocateToQueue__c && routingQueueMappings.get(r.Queue_ID__c) != null){
//                    c.OwnerId = r.Queue_ID__c;
//                    c.AllocateToQueue__c = false;
//                }
//            }
//            else if(mappedRoutings.containsKey(key1) && mappedRoutings.get(key1) != null) {
//                SSSWRouting__c r = mappedRoutings.get(key1);
//                if(c.Network__c == null) {
//                    c.Network__c = r.Network__c;
//                }
//
//                if(string.isEmpty(c.Description) || isNew){
//                    c.Description = (c.Description != null && !string.isEmpty(c.Description) ? c.Description +'\n' : '') + (r.DefaultCaseDetails__c != null && !string.isEmpty(r.DefaultCaseDetails__c) ? r.DefaultCaseDetails__c : '');
//                }
//
//                if(c.AllocateToQueue__c != null && c.AllocateToQueue__c && routingQueueMappings.get(r.Queue_ID__c) != null){
//                    c.OwnerId = r.Queue_ID__c;
//                    c.AllocateToQueue__c = false;
//                }
//            }
//            if(c.AllocateToQueue__c != null && c.AllocateToQueue__c) {
//                string queueName = '';
//                if(c.CaseLocality__c == 'International'){
//                    queueName = 'SSSWInternationalBackOffice';
//                } else {
//                    if(c.Customer_Type__c == 'Consumer') {
//                        queueName = 'SSSWConsumerBackOffice';
//                    } else if(c.Customer_Type__c == 'Enterprise') {
//                        queueName = 'SSSWEnterpriseBackOffice';
//
//                    } else if(c.Customer_Type__c == 'SMB' ||
//                        c.Customer_Type__c == 'Gold') {
//                        queueName = 'SSSWBusinessBackOffice';
//                    }
//                }
//
//                if(queueName != '' && defaultQueueMappings.get(queueName) != null){
//                    c.OwnerId = defaultQueueMappings.get(queueName);
//                }
//
//                c.AllocateToQueue__c = false;
//            }
//        }
//    }
//
//    //Warning, may need to be a @Future, as milestone should be after insert.
//    /*public static void assignCharterTarget(List<Case> cases)
//    {
//        Map<Id, Datetime> caseTarget = new Map<Id, Datetime>();
//
//        for(CaseMilestone cm : [Select CaseId, TargetDate from CaseMilestone where CaseId in :cases and MilestoneType.Name = 'Charter'])
//        {
//            caseTarget.put(cm.CaseId, cm.TargetDate);
//        }
//
//        for(Case c : cases)
//        {
//
//            c.SLATargetDate__c = caseTarget.get(c.id);
//        }
//    }*/
//
//    private static Map<Id, CaseMilestone> caseMilestoneMap = new Map<Id, CaseMilestone>();
//
//    public static void assignCharterTarget(List<Case> cases) {
//        Set<Id> caseIdsToQuery = new Set<Id>();
//        for (Case c : cases) {
//            System.debug('---case Id to assignCharterTarget: ' + c.Id);
//            if (c.Id != null && !caseMilestoneMap.containsKey(c.Id)) {
//                caseIdsToQuery.add(c.Id);
//            }
//        }
//
//        if (caseIdsToQuery.size() > 0) {
//            for(CaseMilestone cm : [Select CaseId, TargetDate from CaseMilestone where CaseId in :caseIdsToQuery and MilestoneType.Name = 'Charter']) {
//                caseMilestoneMap.put(cm.CaseId, cm);
//            }
//        }
//
//        for(Case c : cases) {
//            CaseMilestone cm = caseMilestoneMap.get(c.Id);
//            c.SLATargetDate__c = cm != null
//                ? cm.TargetDate
//                : null;
//        }
//
//        for (Case c : cases) {
//            if (c.Id != null && !caseMilestoneMap.containsKey(c.Id)) {
//                caseMilestoneMap.put(c.Id, null);
//            }
//        }
//    }

//    public static String getSalesManagerReviewExceptionRecordTypeId() {
//        Id rtId = [select id from RecordType where SObjectType='Case' and Name='Sales Manager Review Exception' limit 1].Id;
//        return rtId;
//    }
//
//    public static void updateGrowthOPCUnderReviewBySalesManagerFlag(List<String> opcGrowthIds) {
//        List<Opp_Product_Classification__c> opcList = new List<Opp_Product_Classification__c>();
//        if (opcGrowthIds.size() > 0) {
//            opcList = [select id, Under_Review_by_Sales_Manager__c from Opp_Product_Classification__c where id in :opcGrowthIds];
//            if (opcList.size() > 0) {
//                for (Opp_Product_Classification__c opc : opcList) {
//                    opc.Under_Review_by_Sales_Manager__c = true;
//                }
//                update opcList;
//            }
//        }
//    }
//
//
//    public static List<String> getGrowthOPCFromRenewalOPC(List<String> opcRenewalIds) {
//        List<String> opcGrowthIds = new List<String>();
//        Map<String, String> uniqueIdopcIdRenewalMap = new Map<String, String>();
//        Set<String> sAccount = new Set<String>();
//        Set<String> sProduct = new Set<String>();
//        Set<String> sFY = new Set<String>();
//        Set<String> sContractStart = new Set<String>();
//        Set<String> sContractEnd = new Set<String>();
//        Set<Date> dateContractStart = new Set<Date>();
//        Set<Date> dateContractEnd = new Set<Date>();
//
//        List<Revenue_Schedule__c> rsList =
//        [select Id, Opportunity__r.AccountId, Product__c, Financial_Year__c, Contract_Start_Date__c, Contract_End_Date__c, Opportunity_Product_Classification__c
//        from Revenue_Schedule__c
//        where Opportunity_Product_Classification__c in : opcRenewalIds];
//
//        for (Revenue_Schedule__c rs : rsList) {
//            String uniqueId = rs.Opportunity__r.AccountId + ':'
//            +   rs.Product__c + ':'
//            +   rs.Financial_Year__c + ':'
//            +   rs.Contract_Start_Date__c + ':'
//            +   rs.Contract_End_Date__c;
//            if (!uniqueIdopcIdRenewalMap.containsKey(uniqueId)) {
//                uniqueIdopcIdRenewalMap.put(uniqueId, rs.Opportunity_Product_Classification__c);
//            }
//
//            sAccount.add(rs.Opportunity__r.AccountId);
//            sProduct.add(rs.Product__c);
//            sFY.add(rs.Financial_Year__c);
//            sContractStart.add(String.valueOf(rs.Contract_Start_Date__c));
//            sContractEnd.add(String.valueOf(rs.Contract_End_Date__c));
//            dateContractStart.add(rs.Contract_Start_Date__c);
//            dateContractEnd.add(rs.Contract_End_Date__c);
//        }
//
//        opcGrowthIds = getOPCGrowthIds(uniqueIdopcIdRenewalMap, sAccount, sProduct, sFY, dateContractStart, dateContractEnd);
//        return opcGrowthIds;
//    }
//
//
//    public static List<String> getOPCGrowthIds(Map<String, String> uniqueIdopcIdRenewalMap, Set<String> sAccount, Set<String> sProduct, Set<String> sFY, Set<Date> dateContractStart, Set<Date> dateContractEnd) {
//        Map<String, String> uniqueIdopcIdGrowthMap = new Map<String, String>();
//        List<String> opcGrowthIds = new List<String>();
//        List<Revenue_Schedule__c> rsList =
//        [select Id, Opportunity__r.AccountId, Product__c, Financial_Year__c, Contract_Start_Date__c, Contract_End_Date__c, Opportunity_Product_Classification__c
//        from Revenue_Schedule__c
//        where Classification_c__c='Growth'
//        and Opportunity__r.AccountId in :sAccount
//        and Product__c in :sProduct
//        and Financial_Year__c in :sFY
//        and Contract_Start_Date__c in :dateContractStart
//        and Contract_End_Date__c in :dateContractEnd];
//
//        for (Revenue_Schedule__c rs : rsList) {
//            String uniqueId = rs.Opportunity__r.AccountId + ':'
//            +   rs.Product__c + ':'
//            +   rs.Financial_Year__c + ':'
//            +   rs.Contract_Start_Date__c + ':'
//            +   rs.Contract_End_Date__c;
//            if (!uniqueIdopcIdGrowthMap.containsKey(uniqueId)) {
//                uniqueIdopcIdGrowthMap.put(uniqueId, rs.Opportunity_Product_Classification__c);
//            }
//        }
//
//        // Get OPC Growth IDs
//        for (String uniqueId : uniqueIdopcIdRenewalMap.keySet()) {
//            if (uniqueIdopcIdGrowthMap.containsKey(uniqueId)) {
//                opcGrowthIds.add( uniqueIdopcIdGrowthMap.get(uniqueId) );
//            }
//        }
//
//        return opcGrowthIds;
//    }
//
//
//    @isTest(seeAllData=true)
//    public static void testCaseUtility() {
//
//        test.startTest();
//
//        User u = [SELECT Id, Manager.name
//        FROM User
//        WHERE Profile.Name = 'Customer Team'
//        AND IsActive = true
//        AND ManagerId != null
//        limit 1];
//        System.runAs(u) {
//            RecordType orgrectype = [SELECT Id
//            FROM RecordType
//            WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
//
//            //create account
//            Account bacct = new Account(
//                name='test org', recordtypeid=orgrectype.Id, type='Small Business',
//                phone='11111111', email__c='test@test.com', abn__c='12345678901', Website='www.google.com',
//                Organisation_Trading_Name__c='Trade',
//                BillingCity='City',
//                BillingCountry='Country',
//                BillingState='State',
//                BillingPostalCode='12345',
//                ShippingCity='City',
//                ShippingCountry='Country',
//                ShippingState='State',
//                ShippingStreet='Street',
//                ShippingPostalCode='12345'
//            );
//            insert bacct;
//
//            Organisation_Role__c orgRole = [SELECT Id, Role_Type__c FROM Organisation_Role__c WHERE Organisation__c =: bacct.Id limit 1];
//            orgRole.Role_Type__c='Customer';
//            update OrgRole;
//
//
//            Opportunity oppty = new Opportunity(
//                name='Opportunity',
//                StageName = 'Closed Won',
//                Contract_Number__c='CN12345',
//                closedate = date.today(),
//                Closed_Reason__c='Reason',
//                Contract_Start_Date__c=date.today() - 400,
//                Contract_End_Date__c=date.today() + 400,
//                Type='Existing Customer',
//                accountid=bacct.id
//            );
//            insert oppty;
//
//            String code = 'TEST';
//            Integer nCount = 2;
//
//            Pricebook2 pb = [select id from Pricebook2 where IsStandard = true];
//
//            List<Product2> prodList = new List<Product2>();
//            for(integer i = 0; i < nCount; i++) {
//                Product2 prod = new Product2(
//                    Name = 'Sample Product' + String.valueOf(i),
//                    IsActive = true,
//                    ProductCode = code
//                );
//                prodList.add(prod);
//            }
//            insert prodList;
//
//            List<PricebookEntry> pbeList = new List<PricebookEntry>();
//            for(integer i = 0; i < nCount; i++) {
//                PricebookEntry pbe = new PricebookEntry(
//                    Pricebook2Id = pb.Id,
//                    Product2Id = prodList[i].Id,
//                    IsActive = true,
//                    UnitPrice = 1000,
//                    UseStandardPrice=false
//                );
//                pbeList.add(pbe);
//            }
//            insert pbeList;
//
//            List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
//            List<String> strList = new List<String>{'Renewal', 'Growth'};
//            for(integer i = 0; i < nCount; i++) {
//                OpportunityLineItem oli = new OpportunityLineItem(
//                    OpportunityId = oppty.id,
//                    Classification__c = strList[Math.mod(i, 2)],
//                    PriceBookEntryId = pbeList[0].Id,
//                    Quantity = 100,
//                    TotalPrice = 1000,
//                    Contract_Start_Date__c=date.today() - 150,
//                    Contract_End_Date__c=date.today() + 150,
//                    Contract_Number__c='99999'
//                );
//                oliList.add(oli);
//            }
//            insert oliList;
//
//            List<String> oliIds = new List<String>();
//            for (OpportunityLineItem oli : oliList) {
//                oliIds.add(oli.Id);
//            }
//
//            List<Budget_and_Revenue__c> barList = new List<Budget_and_Revenue__c>();
//            for( Integer i=0; i< nCount * 10; i++){
//                Budget_and_Revenue__c bar = new Budget_and_Revenue__c(
//                    Organisation__c=bacct.id,
//                    Product__c=prodList[Math.mod(i, 2)].id,
//                    Financial_Year__c= String.ValueOf(2013 + Math.mod(i, 5)),
//                    Jan_Revenue_Amount__c=100,
//                    Feb_Revenue_Amount__c=200,
//                    Mar_Revenue_Amount__c=300,
//                    Apr_Revenue_Amount__c=400,
//                    May_Revenue_Amount__c=500,
//                    Jun_Revenue_Amount__c=600,
//                    Jul_Revenue_Amount__c=700,
//                    Aug_Revenue_Amount__c=800,
//                    Sep_Revenue_Amount__c=900,
//                    Oct_Revenue_Amount__c=1000,
//                    Nov_Revenue_Amount__c=1100,
//                    Dec_Revenue_Amount__c=1200,
//                    Jan_Original_Budget__c=1000,
//                    Feb_Original_Budget__c=2000,
//                    Mar_Original_Budget__c=3000,
//                    Apr_Original_Budget__c=4000,
//                    May_Original_Budget__c=5000,
//                    Jun_Original_Budget__c=6000,
//                    Jul_Original_Budget__c=7000,
//                    Aug_Original_Budget__c=8000,
//                    Sep_Original_Budget__c=9000,
//                    Oct_Original_Budget__c=10000,
//                    Nov_Original_Budget__c=11000,
//                    Dec_Original_Budget__c=12000
//                );
//
//                barList.add(bar);
//            }
//            insert barList;
//
//            List<Revenue_Schedule__c> revschedList = [Select Id, Opportunity_Product_Classification__r.Hidden_Under_Review__c, Opportunity__r.AccountId, Opportunity_Product_Classification__r.Hidden_Renewal_Missing_Growth__c, Product__c, Classification_c__c, CalendarYear__c, Reclassified__c,
//                Opportunity__c, Financial_Year__c, Opportunity_Product_Classification__c,
//                Product__r.Name, Opportunity__r.Customer_Name__c, Contract_Start_Date__c, Contract_End_Date__c,
//                Multi_Year__c, Exception_Override__c
//            from Revenue_Schedule__c where OpportunityLineItem__c in: oliIds];
//
//            List<Opp_Product_Classification__c> opcList = new List<Opp_Product_Classification__c>();
//            for (Revenue_Schedule__c rs : revschedList) {
//                Opp_Product_Classification__c opc = new Opp_Product_Classification__c();
//                opc.Account__c = rs.Opportunity__r.AccountId;
//                opc.Product__c = rs.Product__c;
//                opc.Classification__c = rs.Classification_c__c;
//                opc.Financial_Year__c = rs.CalendarYear__c;
//                opc.Opportunity__c = rs.Opportunity__c;
//                opcList.add(opc);
//            }
//
//            insert opcList;
//
//            for (Revenue_Schedule__c rs : revschedList) {
//                for (Opp_Product_Classification__c opc : opcList) {
//                    if ( (opc.Account__c == rs.Opportunity__r.AccountId) && (opc.Product__c == rs.Product__c) && (opc.Classification__c == rs.Classification_c__c) && (opc.Financial_Year__c == rs.CalendarYear__c) ) {
//                        rs.Opportunity_Product_Classification__c = opc.Id;
//                    }
//                }
//            }
//            update revschedList;
//
//            String opcId;
//            for (Revenue_Schedule__c rs : revschedList) {
//                if (rs.Classification_c__c == 'Renewal') {
//                    opcId = rs.Opportunity_Product_Classification__c;
//                    break;
//                }
//            }
//
//            String rtId = [select id from RecordType where SObjectType='Case' and Name='Sales Manager Review Exception' limit 1].Id;
//
//            system.runAs(u.Manager) {
//                Case kase = new Case();
//                kase.RecordTypeId = rtId;
//                kase.Originating_OPC__c = opcId;
//                kase.Opportunity_Driver1__c = u.Id;
//                insert kase;
//            }
//
//            // 09/07 - commented due to Query Exception
//            system.assertEquals(true, [select Under_Review_by_Sales_Manager__c from Opp_Product_Classification__c where id =: opcId limit 1].Under_Review_by_Sales_Manager__c);
//
//            test.stopTest();
//        }
//    }
//
//    public static void avoidCustomerClose(Map<Id, Case> newCases, Map<Id, Case> oldCases) {
//        Map<String, EnquirySubTypes__c> enqSubTypes = EnquirySubTypes__c.getAll();
//        for (Case newCase : newCases.values()) {
//            Case oldCase = oldCases.get(newCase.Id);
//            System.debug('---newCase: ' + newCase.Status + ',' + newCase.Customer_Milestones_Violated__c + ',' + newCase.ClosedBySystem__c + ',' + newCase.ResolutionCode__c);
//            System.debug('---oldCase: ' + oldCase.Status + ',' + oldCase.Customer_Milestones_Violated__c + ',' + oldCase.ClosedBySystem__c + ',' + oldCase.ResolutionCode__c);
//            if (newCase.Customer_Milestones_Violated__c == 4 && newCase.Status == 'Closed' && newcase.ClosedBySystem__c && enqSubTypes.containsKey(newCase.EnquirySubType__c) && enqSubTypes.get(newCase.EnquirySubType__c).AvoidCustomerClose__c) {
//                newCase.Status = oldCase.Status;
//                newCase.AllocateToQueue__c = true;
//                newCase.ResolutionCode__c = null;
//                newCase.ClosedBySystem__c = false;
//            }
//        }
//    }
//
//    public static void avoidUserToUserOwnerChangeFromFillInbox(Map<Id, Case> newCases, Map<Id, Case> oldCases) {
//        for (Case newCase : newCases.values()) {
//            Case oldCase = oldCases.get(newCase.Id);
//            if (SSSW_FillInbox.fillInboxClicked && newCase.OwnerId != oldCase.OwnerId && isUserId(newCase.OwnerId) && isUserId(oldCase.OwnerId)) {
//                newCase.addError('This case has already been assigned to an another user: ' + oldCase.OwnerId);
//            }
//        }
//    }
//
//    private static Set<Id> closedChildCaseIds = new Set<Id>();
//
//    public static void closeChildCases(Map<Id, Case> newCases, Map<Id, Case> oldCases) {
//        Set<Id> parentCaseIds = new Set<Id>();
//        for (Case newCase : newCases.values()) {
//            Case oldCase = oldCases.get(newCase.Id);
//            System.debug('---newCase.Status = ' + newCase.Status);
//            System.debug('---oldCase.Status = ' + oldCase.Status);
//            if (newCase.Status == 'Closed' && newCase.Status != oldCase.Status) {
//                parentCaseIds.add(newCase.Id);
//            }
//        }
//
//        if (!parentCaseIds.isEmpty()) {
//            closeChildCases(parentCaseIds);
//        }
//    }
//
//    public static void closeChildCases(Map<Id, Case> newCases) {
//        Set<Id> parentCaseIds = new Set<Id>();
//        for (Case newCase : newCases.values()) {
//            if (newCase.Status == 'Closed') {
//                parentCaseIds.add(newCase.Id);
//            }
//        }
//
//        if (!parentCaseIds.isEmpty()) {
//            closeChildCases(parentCaseIds);
//        }
//    }
//
//    public static void closeChildCases(Set<Id> parentCaseIds) {
//        if (parentCaseIds == null || parentCaseIds.isEmpty()) {
//            return;
//        }
//
//        List<Case> casesToUpdate = new List<Case>();
//        for (Case c : [SELECT Status, ResolutionCode__c, Parent.ResolutionCode__c FROM Case WHERE ParentId IN :parentCaseIds AND Id NOT IN :closedChildCaseIds AND Status != 'Closed']) {
//            c.Status = 'Closed';
//            if (String.isBlank(c.ResolutionCode__c)) {
//                c.ResolutionCode__c = c.Parent.ResolutionCode__c;
//            }
//            casesToUpdate.add(c);
//            closedChildCaseIds.add(c.Id);
//        }
//
//        if (!casesToUpdate.isEmpty()) {
//            DataBase.SaveResult[] srList = DataBase.update(casesToUpdate, false);
//
//            for (DataBase.SaveResult sr : srList) {
//                if (!sr.isSuccess()) {
//                    System.debug('---The following error has occurred when closing child case:' + sr.getId());
//                    for (DataBase.Error err : sr.getErrors()) {
//                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
//                        System.debug('Case fields that affected this error: ' + err.getFields());
//                    }
//                }
//            }
//        }
//    }
//
//    public static Boolean isUserId(String id) {
//        return String.isNotBlank(id) && id.startsWith(User.sobjectType.getDescribe().getKeyPrefix());
//    }
//
//    //Sets owner to current user if the Case status is set to 'On Hold'
//    public static void setOwnerToCurrentUser(Map<Id, Case> newCases, Map<Id, Case> oldCases) {
//        String statusValue;
//        Map<String, Case_Entitlement_Status__c> cs = Case_Entitlement_Status__c.getAll();
//        if (cs.isEmpty()) {
//            return;
//        }
//        statusValue = cs.values()[0].Internal__c;
//
//        for (Case newCase : newCases.values()) {
//            Case oldCase = oldCases.get(newCase.Id);
//
//            if (newCase.Status == statusValue && newCase.Status != oldCase.Status) {
//                newCase.OwnerId = UserInfo.getUserId();
//            }
//        }
//    }
}