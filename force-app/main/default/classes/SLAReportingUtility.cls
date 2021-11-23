/**************************************************
Description:    Utility Class for handling SLA Reporting functionality
                Create CaseActivity record for First Customer Response
                when Agent contact customer thru Case Comment, Send email thru case,
                make an outbound call, or when related case's FCR flag is ticked
History:
--------------------------------------------------
2018-12-01  John.Mapanao@auspost.com.au  created
2018-12-18  nathan.franklin@auspost.com.au  some refactoring and bug fixes
2019-02-19  ramtej.juloori@auspost.com.au   Added method to create case activity on closure of startrack case with FCR checked
2019-02-23  nathan.franklin@auspost.com.au   Additional code around FCR and recursion prevention.
**************************************************/
public with sharing class SLAReportingUtility {

    private static Map<String, CaseActivityValidTypeSettings__c> validCaseTypeMappings = CaseActivityValidTypeSettings__c.getAll();
    private static Map<Id, RecordType> validCaseRecordTypeMappings = new Map<Id, RecordType>();

    @TestVisible
    private static final String CHANNEL_CALL_LOG = 'Call Log';

    @TestVisible
    private static final String CHANNEL_EMAIL = 'Email';

    @TestVisible
    private static final String CHANNEL_CASECOMMENT = 'Comment';

    @TestVisible
    private static final String CHANNEL_INBOUND = 'Inbound Call';

    private static final String APP_SLA_REPORTING = 'SLA Reporting';
    private static final String METH_GEN_CASE_ACT = 'generateCaseActivity';
    private static final String TASK_TRIGGER_NAME = 'TaskTrigger';
    private static final String CASE_COMMENT_TRIGGER_NAME = 'CaseCommentTrigger';
    private static final String EMAIL_MESSAGE_TRIGGER_NAME = 'EmailMessageTrigger';
    private static final String CASE_TRIGGER_NAME = 'CaseCommonTrigger';
    private static final String SOBJ_NAME_CASE = 'Case';
    private static final String DIRECTION_OUTBOUND = 'Outbound';
    private static final String TASK_TYPE_PHONE_CALL = 'Phone Call';
    private static final String USER_FN_SYS_SUPP = 'System';
    private static final String USER_LN_SYS_SUPP = 'Support';
    private static final String USER_EMAIL_SYS_SUPP = 'salessystemssupport@auspost.com.au';

    static { // code executed to fetch details when class is invoked
        validCaseRecordTypeMappings = Utility.getRecordTypesAsSObjectByDevName('Case', validCaseTypeMappings.keySet());
    }

    /*
     *  Log a CaseActivity record when new case comment has been created
     *  This method will run after insert on Case Comment which means we don't need to worry about recursion.
     *  Any activity that is logged will calculate both business hours (if configured) and actual time the response took since the creation of the case.
     */
    public static void generateCaseActivity(List<CaseComment> caseCommentList) {
        try {
            // grab the case ids to verify this case comment against
            // some case comments will be ignored based on configuration
            List<CaseComment> processableCaseComments = new List<CaseComment>();
            Set<Id> caseCommentUserIds = new Set<Id>();
            Set<Id> caseCommentCaseIds = new Set<Id>();

            for (CaseComment cc : caseCommentList) {
                // we are only concerned with published case comments
                if (cc.IsPublished) {
                    // store the users so we can check if they are internal or external users.
                    caseCommentUserIds.add(cc.CreatedById);
                    processableCaseComments.add(cc);
                }
            }

            // NOTE: This is split up to ensure we only run SOQL's when we absolutely have to.
            if(!processableCaseComments.isEmpty()) {
                // one final check to remove any case comments that were created by external users.
                // any comments made by external users will be ignored
                Map<Id, User> users = new Map<Id, User>([Select Id, UserType From User Where Id In :caseCommentUserIds And UserType = 'Standard']);
                for(Integer i = (processableCaseComments.size()-1);i>=0;i--) {
                    // if the user doesn't exist in the list of standard users than remove the record to be processed
                    if(!users.keySet().contains(processableCaseComments[i].CreatedById)) {
                        processableCaseComments.remove(i);
                    } else {
                        caseCommentCaseIds.add(processableCaseComments[i].ParentId);
                    }
                }
            }

            if(!processableCaseComments.isEmpty()) {

                // get only the valid cases along with their business hours if needed
                Map<Id, Case> processableCases = getFilteredCases(caseCommentCaseIds);
                Set<Id> caseIds = processableCases.keySet();

                System.debug('>> processableCases: ' + processableCases);
                if(!processableCases.isEmpty()) {

                    // grab the correct business hours based on the value in the custom settings for the record types of the cases passed in
                    // in the custom setting, the value will either be a business hours id or the word 'Case' which signifies to use the Case business hours or Entitlement business hours
                    // NOTE: business hours may also be empty, in that case, no business hour tracking will be done
                    // NOTE: we only ever process cases that have a valid Record Type
                    Map<Id, Id> businessHoursMappings = getCaseBusinessHourMappings(processableCases);
                    System.debug('>> businessHoursMappings: ' + businessHoursMappings);

                    // grab a list of activities that already exist on the cases passed in
                    // this will help us determine whether activity just completed is a first response or not
                    // NOTE: This will ignore any activities created by external users
                    Map<Id, Set<Id>> caseAgentActivityKeys = getAgentActivityOnCases(caseIds);
                    System.debug('>> caseAgentActivityKeys: ' + caseAgentActivityKeys);

                    // loop through all the case comments added and add an activity where it needs to be added
                    // this will perform business hour calculation if necessary too.
                    List<CaseActivity__c> insertableCaseActivities = new List<CaseActivity__c>();
                    for(CaseComment caseComment : processableCaseComments) {

                        // we only process case comments that are attached to cases with type we are tracking as defined in the validCaseTypeMappings variable
                        if(caseIds.contains(caseComment.ParentId)) {
                            Case caseRec = processableCases.get(caseComment.ParentId);

                            // calculate the business hours difference if necessary
                            Decimal businessHourDiff = null;
                            if(businessHoursMappings.get(caseComment.ParentId) != null) {
                                try {
                                    businessHourDiff = BusinessHours.diff(businessHoursMappings.get(caseComment.ParentId), caseRec.CreatedDate, caseComment.CreatedDate);
                                } catch(Exception ex) {
                                    // invalid business hours string add to the custom setting... DO NOTHING
                                    System.debug('>> error in calculating business hours, maybe config is wrong? ' + ex);
                                }
                            }

                            // Set appropriate flags for this case comment
                            // NOTE: As per above, only published case comments made by interal users will make it this far.
                            Boolean isCaseFirstResponse = (caseAgentActivityKeys.get(caseComment.ParentId) == null || caseAgentActivityKeys.get(caseComment.ParentId).isEmpty());
                            Boolean isAgentFirstResponse = (caseAgentActivityKeys.get(caseComment.ParentId) == null ? true : (caseAgentActivityKeys.get(caseComment.ParentId).contains(caseComment.CreatedById) ? false : true));

                            // create a new case activity record
                            CaseActivity__c ca = createCaseActivityStub(caseRec.Id, caseComment.CreatedById, CHANNEL_CASECOMMENT,
                                                                            isCaseFirstResponse, isAgentFirstResponse, caseComment.CreatedDate,
                                                                            caseComment.Id, getActualDiff(caseRec.CreatedDate, caseComment.CreatedDate),
                                                                            businessHourDiff); //ccRec.CommentBody);
                            insertableCaseActivities.add(ca);

                            // add an entry to the agent activity keys to ensure the right 'first response' flags are set on subsequent inserts
                            // if we don't do this multiple records in the same batch might be flagged as 'first response' incorrectly
                            // NOTE: We only do this if the user is an INTERNAL USER.... any comments added by external users are ignored and not added as an activity to begin with
                            if(caseAgentActivityKeys.get(caseComment.ParentId) == null)
                                caseAgentActivityKeys.put(caseComment.ParentId, new Set<Id>());

                            caseAgentActivityKeys.get(caseComment.ParentId).add(caseComment.CreatedById);
                        }
                    }

                    if(!insertableCaseActivities.isEmpty()) {
                        // finally add the new case activity records
                        System.debug('>> insertableCaseActivities: ' + insertableCaseActivities);
                        insert insertableCaseActivities;
                    }
                }
            }
        } catch (Exception ex) {
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), APP_SLA_REPORTING,
                    SLAReportingUtility.class.getName(), METH_GEN_CASE_ACT, CASE_COMMENT_TRIGGER_NAME, LoggingLevel.ERROR);
        }
    }

    /*
     *  Method invoked from after insert task and generate case activity for SLA Reporting
     *  when outbound task has been done by Agent to contact customer.
     *  Log a CaseActivity record when new Outbound task has been
     *  inserted on case (agent did outbound call to customer)
     */
    public static void generateCaseActivity(List<Task> taskList) {
        try {
            String casePrefix = '500'; //Case.SObjectType.getDescribe().getKeyPrefix(); <-- too slow

            // Get Task record (updated / inserted) where whatId linked is not blank and its a Case
            // and Direction is Outbound. Collect whatId and Task Id and use to avoid duplicate Case Activity record
            Set<Id> taskCaseIds = new Set<Id>();
            List<Task> processableTasks = new List<Task>();

            for (Task  tt : taskList) {
                if (tt.WhatId != null && String.valueOf(tt.WhatId).startsWithIgnoreCase(casePrefix) && tt.Direction__c == DIRECTION_OUTBOUND && tt.Type == TASK_TYPE_PHONE_CALL) {
                    processableTasks.add(tt);
                    taskCaseIds.add(tt.WhatId);
                }
            }

            if (!processableTasks.isEmpty()) {
                // get only the valid cases along with their business hours if needed
                Map<Id, Case> processableCases = getFilteredCases(taskCaseIds);
                Set<Id> caseIds = processableCases.keySet();

                // grab the correct business hours based on the value in the custom settings for the record types of the cases passed in
                // in the custom setting, the value will either be a business hours id or the word 'Case' which signifies to use the Case business hours or Entitlement business hours
                // NOTE: business hours may also be empty, in that case, no business hour tracking will be done
                // NOTE: we only ever process cases that have a valid Record Type
                Map<Id, Id> businessHoursMappings = getCaseBusinessHourMappings(processableCases);
                System.debug('>> businessHoursMappings: ' + businessHoursMappings);

                // grab a list of activities that already exist on the cases passed in
                // this will help us determine whether activity just completed is a first response or not
                Map<Id, Set<Id>> caseAgentActivityKeys = getAgentActivityOnCases(caseIds);
                System.debug('>> caseAgentActivityKeys: ' + caseAgentActivityKeys);

                // loop through all the case comments added and add an activity where it needs to be added
                // this will perform business hour calculation if necessary too.
                List<CaseActivity__c> insertableCaseActivities = new List<CaseActivity__c>();
                for(Task taskRec : processableTasks) {

                    // we only process case comments that are attached to cases with type we are tracking as defined in the validCaseTypeMappings variable
                    if(caseIds.contains(taskRec.WhatId)) {
                        Case caseRec = processableCases.get(taskRec.WhatId);

                        // calculate the business hours difference if necessary
                        Decimal businessHourDiff = null;
                        if(businessHoursMappings.get(taskRec.WhatId) != null) {
                            try {
                                businessHourDiff = BusinessHours.diff(businessHoursMappings.get(taskRec.WhatId), caseRec.CreatedDate, taskRec.CreatedDate);
                            } catch(Exception ex) {
                                // invalid business hours string add to the custom setting... DO NOTHING
                                System.debug('>> error in calculating business hours, maybe config is wrong? ' + ex);
                            }
                        }

                        Boolean isCaseFirstResponse = (caseAgentActivityKeys.get(taskRec.WhatId) == null || caseAgentActivityKeys.get(taskRec.WhatId).isEmpty());
                        Boolean isAgentFirstResponse = (caseAgentActivityKeys.get(taskRec.WhatId) == null ? true : (caseAgentActivityKeys.get(taskRec.WhatId).contains(taskRec.CreatedById) ? false : true));

                        // create a new case activity record
                        CaseActivity__c ca = createCaseActivityStub(caseRec.Id, taskRec.CreatedById, CHANNEL_CALL_LOG,
                                                                        isCaseFirstResponse, isAgentFirstResponse, taskRec.CreatedDate,
                                                                        taskRec.Id, getActualDiff(caseRec.CreatedDate, taskRec.CreatedDate),
                                                                        businessHourDiff); //ccRec.CommentBody);
                        insertableCaseActivities.add(ca);

                        // add an entry to the agent activity keys to ensure the right 'first response' flags are set on subsequent inserts
                        // if we don't do this multiple records in the same batch might be flagged as 'first response' incorrectly
                        if(caseAgentActivityKeys.get(taskRec.WhatId) == null)
                            caseAgentActivityKeys.put(taskRec.WhatId, new Set<Id>());

                        caseAgentActivityKeys.get(taskRec.WhatId).add(taskRec.CreatedById);
                    }
                }

                if(!insertableCaseActivities.isEmpty()) {
                    // finally add the new case activity records
                    System.debug('>> insertableCaseActivities: ' + insertableCaseActivities);
                    insert insertableCaseActivities;
                }
            }
        } catch (Exception ex) {
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), APP_SLA_REPORTING,
                    SLAReportingUtility.class.getName(), METH_GEN_CASE_ACT, TASK_TRIGGER_NAME, LoggingLevel.ERROR);
        }
    }

    /*
     *  Log a CaseActivity record when new outbound email message is added
     *  has been inserted on case (agent did outbound call to customer)
     */
    public static void generateCaseActivity(List<EmailMessage> emailMessageList) {
        try {
            String casePrefix = '500'; // Case.SObjectType.getDescribe().getKeyPrefix(); <-- too slow
            Set<Id> emailCaseIds = new Set<Id>();
            List<EmailMessage> processableEmails = new List<EmailMessage>();

            for (EmailMessage em : emailMessageList) {
                // Only process outbound email messages and parentId is Case
                if (em.ParentId != null && String.valueOf(em.ParentId).startsWithIgnoreCase(casePrefix) && em.Incoming == false) {
                    emailCaseIds.add(em.ParentId);
                    processableEmails.add(em);
                }
            }

            System.debug('>> Generating Case Activity For Email Messages: ' + processableEmails);
            if (!processableEmails.isEmpty()) {

                // get only the valid cases along with their business hours if needed
                Map<Id, Case> processableCases = getFilteredCases(emailCaseIds);
                System.debug('>> Valid cases: ' + processableCases);
                Set<Id> caseIds = processableCases.keySet();

                // grab the correct business hours based on the value in the custom settings for the record types of the cases passed in
                // in the custom setting, the value will either be a business hours id or the word 'Case' which signifies to use the Case business hours or Entitlement business hours
                // NOTE: business hours may also be empty, in that case, no business hour tracking will be done
                // NOTE: we only ever process cases that have a valid Record Type
                Map<Id, Id> businessHoursMappings = getCaseBusinessHourMappings(processableCases);
                System.debug('>> businessHoursMappings: ' + businessHoursMappings);

                // grab a list of activities that already exist on the cases passed in
                // this will help us determine whether activity just completed is a first response or not
                Map<Id, Set<Id>> caseAgentActivityKeys = getAgentActivityOnCases(caseIds);
                System.debug('>> caseAgentActivityKeys: ' + caseAgentActivityKeys);

                // loop through all the case comments added and add an activity where it needs to be added
                // this will perform business hour calculation if necessary too.
                List<CaseActivity__c> insertableCaseActivities = new List<CaseActivity__c>();
                for(EmailMessage emailMessage : processableEmails) {

                    // we only process email messages that are attached to cases with type we are tracking as defined in the validCaseTypeMappings variable
                    // in addition to this, we also only track email activities where it was sent to the Contact on the case.
                    Case caseRec = processableCases.get(emailMessage.ParentId);
                    if(caseRec != null && isEmailSentToCaseContact(emailMessage, caseRec)) {

                        // this activity should only be logged

                        // calculate the business hours difference if necessary
                        Decimal businessHourDiff = null;
                        if(businessHoursMappings.get(emailMessage.ParentId) != null) {
                            try {
                                businessHourDiff = BusinessHours.diff(businessHoursMappings.get(emailMessage.ParentId), caseRec.CreatedDate, emailMessage.CreatedDate);
                            } catch(Exception ex) {
                                // invalid business hours string add to the custom setting... DO NOTHING
                                System.debug('>> error in calculating business hours, maybe config is wrong? ' + ex);
                            }
                        }

                        Boolean isCaseFirstResponse = (caseAgentActivityKeys.get(emailMessage.ParentId) == null || caseAgentActivityKeys.get(emailMessage.ParentId).isEmpty());
                        Boolean isAgentFirstResponse = (caseAgentActivityKeys.get(emailMessage.ParentId) == null ? true : (caseAgentActivityKeys.get(emailMessage.ParentId).contains(emailMessage.CreatedById) ? false : true));

                        // create a new case activity record
                        CaseActivity__c ca = createCaseActivityStub(caseRec.Id, emailMessage.CreatedById, CHANNEL_EMAIL,
                                                                        isCaseFirstResponse, isAgentFirstResponse, emailMessage.CreatedDate,
                                                                        emailMessage.Id, getActualDiff(caseRec.CreatedDate, emailMessage.CreatedDate),
                                                                        businessHourDiff); //ccRec.CommentBody);
                        insertableCaseActivities.add(ca);

                        // add an entry to the agent activity keys to ensure the right 'first response' flags are set on subsequent inserts
                        // if we don't do this multiple records in the same batch might be flagged as 'first response' incorrectly
                        if(caseAgentActivityKeys.get(emailMessage.ParentId) == null)
                            caseAgentActivityKeys.put(emailMessage.ParentId, new Set<Id>());

                        caseAgentActivityKeys.get(emailMessage.ParentId).add(emailMessage.CreatedById);
                    }
                }

                if(!insertableCaseActivities.isEmpty()) {
                    // finally add the new case activity records
                    System.debug('>> insertableCaseActivities: ' + insertableCaseActivities);
                    insert insertableCaseActivities;
                }
            }
        } catch (Exception ex) {
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), APP_SLA_REPORTING,
                    SLAReportingUtility.class.getName(), METH_GEN_CASE_ACT, EMAIL_MESSAGE_TRIGGER_NAME, LoggingLevel.ERROR);
        }
    }

    /*
     *  Log a CaseActivity record when a case is closed with FCR checked
     *  This occurs when either a case is inserted or updated
     */
    public static void generateCaseActivity(Map<Id, Case> caseNewMap, Map<Id, Case> caseOldMap) {
        try {
            Set<Id> fcrClosedCaseIds = new Set<Id>();

            // get only the records that need processing (either records that have never passed through here, or where the values of tracked fields have changed since it was last processed)
            List<Case> filteredCases = (List<Case>)RecursionUtility.getUnprocessedRecords('generateCaseActivityCases' + (caseOldMap == null ? 'Insert' : 'Update'), caseNewMap.values(), new Set<String>{'IsClosed', 'FCR__c'});
            System.debug('>> generateCaseActivity: ' + filteredCases);
            for (Case cs : filteredCases) {
                // only process records that are included in the overall CaseActivity functionality
                Case oldRec = (caseOldMap == null ? null : caseOldMap.get(cs.Id));

                // if the record has just been inserted OR
                //      if the record has been updated to equal Closed with FCR.
                if (cs.IsClosed && cs.FCR__c && cs.StarTrack_RecordType__c &&
                        (oldRec == null || (oldRec != null && (cs.IsClosed != oldRec.IsClosed || cs.FCR__c != oldRec.FCR__c)))) {
                    fcrClosedCaseIds.add(cs.Id);
                }
            }
            System.debug('>> fcrClosedCaseIds: ' + fcrClosedCaseIds);

            if (!fcrClosedCaseIds.isEmpty()) {
                // TODO: Implement a solution that only ever logs a maximum of 1 FCR record.

                // get only the valid cases along with their business hours and RecordType information if needed
                // NOTE: its necessary to do this to ensure we retrieve the RecordType and Entitlement objects in the case record
                Map<Id, Case> processableCases = getFilteredCases(fcrClosedCaseIds);
                System.debug('>> Valid cases: ' + processableCases);
                Set<Id> caseIds = processableCases.keySet();
                
                List<CaseActivity__c> insertableCaseActivities = new List<CaseActivity__c>();

                // grab a list of activities that already exist on the cases passed in
                // this will help us determine whether activity just completed is a first response or not
                Map<Id, Set<Id>> caseAgentActivityKeys = getAgentActivityOnCases(processableCases.keySet());

                for(Case cs : processableCases.values()){
                    Boolean isCaseFirstResponse = (caseAgentActivityKeys.get(cs.Id) == null || caseAgentActivityKeys.get(cs.Id).isEmpty());
                    Boolean isAgentFirstResponse = (caseAgentActivityKeys.get(cs.Id) == null ? true : (caseAgentActivityKeys.get(cs.Id).contains(cs.LastModifiedById) ? false : true));

                    // NOTE: An FCR on a case should be reported as taking 0 time on Case since the issue was resolved with first customer contact.
                    //          Set time differences to be zero and the Response Date/Time should be set to the Case created date
                    CaseActivity__c ca = createCaseActivityStub(cs.Id, cs.LastModifiedById, CHANNEL_INBOUND,
                                                                    isCaseFirstResponse, isAgentFirstResponse, cs.CreatedDate,
                                                                    cs.Id, 0, 0);

                    //Add last modified id into case agent activities to set isAgentFirstResponse true only once
                    //if adding multiple activities for same case
                    if(caseAgentActivityKeys.get(cs.Id) == null){
                        caseAgentActivityKeys.put(cs.Id, new Set<Id>());
                    }
                    caseAgentActivityKeys.get(cs.Id).add(cs.LastModifiedById);

                    insertableCaseActivities.add(ca);
                }
                if(!insertableCaseActivities.isEmpty()) {
                    // finally add the new case activity records
                    System.debug('>> insertableCaseActivities: ' + insertableCaseActivities);
                    insert insertableCaseActivities;
                }
            }
        } catch (Exception ex) {
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), APP_SLA_REPORTING,
                    SLAReportingUtility.class.getName(), METH_GEN_CASE_ACT, EMAIL_MESSAGE_TRIGGER_NAME, LoggingLevel.ERROR);
        }
    }

    /**
     * Emails are only logged as a Case activity if the email was sent to the contact linked to the case
     * Checks whether the Contact ID or Email address on the Contact is contain within the EmailMessage record.
     */
    private static Boolean isEmailSentToCaseContact(EmailMessage message, Case caseRec) {
        Set<String> emailAddresses = new Set<String>();
        if(caseRec.Contact != null && !String.isEmpty(caseRec.Contact.Email)) {
            emailAddresses.add(caseRec.Contact.Email);
        }
        if(caseRec.Authorised_Contacts__r != null) {
            for(AuthorisedContacts__c contact : caseRec.Authorised_Contacts__r) {
                if(String.isNotEmpty(contact.Calc_Contact_Email__c)) {
                    emailAddresses.add(contact.Calc_Contact_Email__c);
                }
            }
        }

        for(String emailAddress : emailAddresses) {
            try {
                Pattern emailPattern = Pattern.compile('.*?\\b' + emailAddress.replace('.', '\\.') + '\\b.*?');
                if (String.isNotEmpty(message.BccAddress) && emailPattern.matcher(message.BccAddress).matches()) {
                    return true;
                }
                if (String.isNotEmpty(message.CcAddress) && emailPattern.matcher(message.CcAddress).matches()) {
                    return true;
                }
                if (String.isNotEmpty(message.ToAddress) && emailPattern.matcher(message.ToAddress).matches()) {
                    return true;
                }
            } catch (Exception ex) {
                System.debug('Error with RegEx Pattern: ' + ex);
            }
        }

        // the email sent did not match the contact on the case, so now agent activity will be recorded
        return false;
    }

    /**
     * grab the correct business hours based on the value in the custom settings for the record types of the cases passed in
     * in the custom setting, the value will either be a business hours id or the word 'Case' which signifies to use the Case business hours or Entitlement business hours
     * NOTE: business hours may also be empty, in that case, no business hour tracking will be done
     * NOTE: we only ever process cases that have a valid Record Type
     */
    private static Map<Id, Id> getCaseBusinessHourMappings(Map<Id, Case> cases) {
        Map<Id, Id> businessHoursMappings = new Map<Id, Id>();
        for (Id caseId : cases.keySet()) {
            Case c = cases.get(caseId);
            if (c.RecordType != null && validCaseTypeMappings.get(c.RecordType.DeveloperName) != null) {
                try {
                    if ('Case'.equalsIgnoreCase(validCaseTypeMappings.get(c.RecordType.DeveloperName).BusinessHours__c)) {
                        // get the case specific business hours for the calculation
                        businessHoursMappings.put(c.Id, (!String.isEmpty(c.BusinessHoursId) ? c.BusinessHoursId : (c.Entitlement != null ? c.Entitlement.BusinessHoursId : '')));
                        System.debug('>>> using Case business hours for: ' + caseId + ', ' + businessHoursMappings.get(c.Id));
                    } else {
                        // get the business hours specific to the record type configuration in the custom setting
                        businessHoursMappings.put(c.Id, validCaseTypeMappings.get(c.RecordType.DeveloperName).BusinessHours__c);
                        System.debug('>>> using record type config business hours for: ' + caseId + ', ' + businessHoursMappings.get(c.Id));
                    }
                } catch(Exception ex) {
                    // invalid business hours string add to the custom setting DO NOTHING
                    // we still want the activity to create even if there is an error with business hours calculation
                    System.debug('>> error in calculating business hours, maybe config is wrong? ' + ex);
                }
            }
        }

        return businessHoursMappings;
    }

    /**
     * grab a list of agents that have previously worked on the case
     * this is used to determine whether the new activity being inserted is a first response or not.
     */
    private static Map<Id, Set<Id>> getAgentActivityOnCases(Set<Id> caseIds) {
        Map<Id, Set<Id>> caseAgentActivityKeys = new Map<Id, Set<Id>>();
        for(CaseActivity__c caseActivity : [SELECT Id, Case__c, Agent__c, SourceId__c
                                            FROM CaseActivity__c
                                            WHERE Case__c IN : caseIds
                                            Order By CreatedDate Desc]) {

            // this will be used as a way to determine whether an agent (or anyone) has created an activity for the case in question
            if(caseAgentActivityKeys.get(caseActivity.Case__c) == null)
                caseAgentActivityKeys.put(caseActivity.Case__c, new Set<Id>());

            caseAgentActivityKeys.get(caseActivity.Case__c).add(caseActivity.Agent__c);
        }

        return caseAgentActivityKeys;
    }

    /*
     * Method to calculate the time difference source's created datetime (FCR Case / Outbound Email / Case Comment / Outbound Call)
     * against its parent case's created datetime. Result will be in milliseconds. Response time from case created time
     */
    private static Decimal getActualDiff(Datetime caseCreatedDatetime, Datetime sourceCreatedDatetime) {
        Decimal caseCDT = caseCreatedDatetime.getTime();
        Decimal sourceCDT = sourceCreatedDatetime.getTime();
        Decimal milliseconds = sourceCDT - caseCDT;
        if (milliseconds < 0) {
            return 0;
        }
        return milliseconds;
    }

    /*
     *  Query related cases using caseIds and specific recordtypeids
     *  Also grab the Authorised contact email addresses for StarTrack cases to ensure we only log email agent activities where the communication is sent to the contacts on the case
     */
    private static Map<Id, Case> getFilteredCases(Set<Id> caseIds) {
        Map<Id, Case> processableCases = new Map<Id, Case>([Select Id, RecordTypeId, RecordType.DeveloperName, CreatedDate, BusinessHoursId, Entitlement.BusinessHoursId,
                                                                ClosedDate, LastModifiedById, Contact.Email, ContactId,
                                                                (Select Calc_Contact_Email__c From Authorised_Contacts__r)
                                                            From Case
                                                            Where Id In : caseIds
                                                            And RecordTypeId In : validCaseRecordTypeMappings.keySet()]);
        return processableCases;
    }

    /*
     *  Method for constructing CaseActivity__c record details to be insert
     */
    private static CaseActivity__c createCaseActivityStub(Id caseId, Id agentId, String channel,
                                                            Boolean isCaseFirstResponse, Boolean isAgentFirstResponse, Datetime dtp,
                                                            String sourceId, Decimal actualDiff, Decimal businessHourIdiff) {

        CaseActivity__c tempCA = new CaseActivity__c();
        tempCA.Case__c = caseId;
        tempCA.Agent__c = agentId;
        tempCA.Category__c = channel;
        tempCA.IsCaseFirstResponse__c = isCaseFirstResponse;
        tempCA.IsAgentFirstResponse__c = isAgentFirstResponse;
        tempCA.ResponseDateTime__c = dtp;
        tempCA.SourceId__c = sourceId;
        tempCA.TotalActualDurationMilliseconds__c = actualDiff;
        tempCA.TotalBusinessDurationMilliseconds__c = businessHourIdiff;
        return tempCA;
    }
}