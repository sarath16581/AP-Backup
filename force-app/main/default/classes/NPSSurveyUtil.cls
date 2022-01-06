/**************************************************
Description:    Utility Class for handling NPS functions
History:
--------------------------------------------------
2018-07-09  nathan.franklin@auspost.com.au  refactored code. added NPS methods into class
**************************************************/
public with sharing class NPSSurveyUtil {

    public static Boolean isCheckNPSOrigin = false;      // flag to prevent recursive NPS check invoke

    // cache a list of email exclusions to be checked when flagging a case for NPS
    // certain email-to-case emails and contacts are excluded
    private static Map<String, Map<Integer, List<String>>> emailExclusions = new Map<String, Map<Integer, List<String>>>();

    public static void linkAgentIdFromCase(List<NPSSurvey__c> newList){
        //Map<Id, NPSSurvey__c> shortListed = new Map<Id, NPSSurvey__c>();
        List<NPSSurvey__c> shortListed  = new List<NPSSurvey__c>();    // Nandan : Changed map to  list
        Set<Id> relatedCaseIds = new Set<Id>();
        for(NPSSurvey__c n: newList){
            if(n.Source__c == 'Online' && n.Case__c != null){
                relatedCaseIds.add(n.Case__c);
                //shortListed.put(n.id, n);
                shortListed.add(n);    // Nandan : adding values to list  list
            }
        }
        System.debug('** shortListed ==>'+shortListed); // Nandan : Added to debug
        Map<id, Case> relatedCases = new Map<id, Case>([select NPSAgent__c from Case where id in :relatedCaseIds]);
        System.debug('** relatedCases ==>'+relatedCases ); // Nandan : Added to debug
        for(NPSSurvey__c n: shortListed ){    // Nandan : Changed from shortListed.values() to shortListed
            n.Agent__c = relatedCases.get(n.Case__c).NPSAgent__c;
            System.debug('** n.Agent__c ==>'+n.Agent__c);    // Nandan : Added to debug
        }
        System.debug('** shortListed ==>'+shortListed);    // Nandan : Added to debug
    }

    /**
      * Check to see whether a case should be flagged for NPS or not
      * A case type prefix is also passed in which checks the RecordType developer name prefix to see if the case should be included in this check or not.
      *         Currently, only used by SSSW cases
      */
    public static void maybeFlagNPS(List<Case> caseList, Map<Id, Case> oldMap, String caseTypePrefix) {
        // only allow NPS processing to occur once
        if(isCheckNPSOrigin)
            return;

        // get all valid record types for processing NPS
        Set<Id> validRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()), caseTypePrefix);

        System.debug('validRecTypes---->'+validRecTypes);
        try {
            Set<Id> contactIds = new Set<Id>();
            List<Case> casesToUpdate = new List<Case>();

            for(Case caseRec : caseList){
                if(Utility.isValidRecordType(validRecTypes, caseRec.RecordTypeId)){  // verify if its SSSW recordtype
                    Case oldCase = oldMap.get(caseRec.Id);  // get old values of case
                    System.debug('caseRec.IsChildCase__c--->'+caseRec.IsChildCase__c);
                    System.debug('caseRec.Status--->'+caseRec.Status+'<---oldCase.Status--->'+oldCase.Status);
                    System.debug('caseRec.IsClosed--->'+caseRec.IsClosed);
                    System.debug('caseRec.NPSScheduledDate__c--->'+caseRec.NPSScheduledDate__c);
                    System.debug('caseRec.ContactId--->'+caseRec.ContactId);
                    // make sure only closed cases that haven't already been flagged will be considered.
                    // also make sure the case isn't a child case
                    if(caseRec.IsChildCase__c == false && oldCase != null && ((caseRec.Status != oldCase.Status && caseRec.Status == 'Closed') ||
                            caseRec.IsClosed) && caseRec.NPSScheduledDate__c == null && caseRec.ContactId != null) {
                        contactIds.add(caseRec.ContactId);  // capture contact to get LastNPSDate from Contact
                        casesToUpdate.add(caseRec); // cases to be updated
                    }
                }
            }

            // only process NPS criteria if there are cases to process
            System.Debug('>> found cases to maybe be flagged for NPS: ' + casesToUpdate);
            if(!casesToUpdate.isEmpty()) {
                AusPostSettings__c npsSetting = AusPostSettings__c.getValues(SSSWConstants.NPS_CUTOFF_CUST_SETTING);
                Integer npsCutOffDays = npsSetting != null ? npsSetting.Number1__c.intValue() : SSSWConstants.NPS_CUTOFF_DAYS;

                Map<Id, Contact> conMap = new Map<Id, Contact>([Select LastNPSDate__c, email From Contact Where Id IN :contactIds]);
                List<Case> caseNPS = new List<Case>();
                DateTime currentTime = Datetime.now();

                Map<Id, Boolean> caseEmailExclusions = isCaseExcludedByEmail(casesToUpdate, conMap, caseTypePrefix);

                for(Case caseRec : casesToUpdate) {
                    //c heck whether the case should be excluded based on either email-to-case email or contact email
                    if(caseEmailExclusions.get(caseRec.Id))
                        continue;

                    // set NPS required to true if there is no NPS on contact or over 7 days
                    DateTime lastNPSDate = conMap.get(caseRec.contactId).LastNPSDate__c;   // get case contact details
                    if (lastNPSDate == null || lastNPSDate.addDays(npsCutOffDays) < currentTime) {
                        caseNPS.add(caseRec);
                    }
                }

                if(!caseNPS.isEmpty()) {
                    // after all preprocessing, pass these cases into the rules engine to set the NPS required field to true if necessary
                    SSSW_Routing.applyNPSRules(caseNPS);

                    // make sure cases aren't flagged for nps again
                    isCheckNPSOrigin = true;        // set recursive flag
                }
            }
        } catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                'NPSSurveyUtil', 'maybeFlagNPS', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }

    /**
     * Get a list of all the email addresses that should be considered when determining whether a case should be flagged for NPS
     *      certain email-to-case emails and contacts are excluded
     *
     * Rule Type = 1 denotes email-to-case record
     * Rule Type = 2 denotes a contact email address
     */
    private static Map<Integer, List<String>> getNPSEmailExclusions(String caseTypePrefix) {
        if(!emailExclusions.keySet().contains(caseTypePrefix)) {
            Map<Integer, List<String>> emailAddresses = new Map<Integer, List<String>>();

            for(NPS_Case_Email_Exclusion__c exclusion : [Select Rule_Type__c, Email_Address_Formula__c From NPS_Case_Email_Exclusion__c
                                                                Where Target_Case_Record_Type_Prefix__c = :caseTypePrefix]) {

                Integer ruleType = Integer.valueOf(exclusion.Rule_Type__c);
                if(emailAddresses.get(ruleType) == null)
                    emailAddresses.put(ruleType, new List<String>());

                emailAddresses.get(ruleType).add(exclusion.Email_Address_Formula__c);
            }

            // drop each of the rules into a cache map for later access
            emailExclusions.put(caseTypePrefix, emailAddresses);
        }

        return emailExclusions.get(caseTypePrefix);
    }

    /**
     * Set a list of cases that should be excluded based on the email address exclusion rules
     */
    private static Map<Id, Boolean> isCaseExcludedByEmail(List<Case> cases, Map<Id, Contact> contacts, String caseTypePrefix) {

        Map<Id, Boolean> caseExclusions = new Map<Id, Boolean>();
        Map<Integer, List<String>> emailExclusions = getNPSEmailExclusions(caseTypePrefix);
        System.debug('emailExclusions--->'+emailExclusions);
        List<String> emailToCaseExclusions = (emailExclusions.get(1) == null ? new List<String>() : emailExclusions.get(1));
        List<String> contactExclusions = (emailExclusions.get(2) == null ? new List<String>() : emailExclusions.get(2));
        System.debug('contactExclusions--->'+contactExclusions);
        List<Pattern> emailToCaseExclusionPatterns = new List<Pattern>();
        List<Pattern> contactExclusionPatterns = new List<Pattern>();

        // precompile the patterns for emailToCase to handle bulk operations better
        for(String emailToCaseExclusion : emailToCaseExclusions) {
            try {
                // case insensitive matching
                emailToCaseExclusionPatterns.add(Pattern.compile('(?i)' + emailToCaseExclusion));
            } catch(Exception ex) { /* invalid rule format... ignore */ }
        }
        System.debug('emailToCaseExclusionPatterns--->'+emailToCaseExclusionPatterns);
        // precompile the patterns for contact matches to handle bulk operations better
        for(String contactExclusion : contactExclusions) {
            try {
                // case insensitive matching
                contactExclusionPatterns.add(Pattern.compile('(?i)/' + contactExclusion));
            } catch(Exception ex) { System.debug('Error contactExclusionPatterns >>>'+ex); }
        }
        System.debug('contactExclusionPatterns--->'+contactExclusionPatterns);
        for(Case c : cases) {
            String caseContactEmail = contacts.get(c.ContactId).Email;   // get case contact details
            System.Debug('>> Checking case contact email: ' + caseContactEmail);

            // the email address that this case was received from (if email-to-case)
            String emailToCase = (String.isEmpty(c.EmailToCaseAddress__c) ? '' : c.EmailToCaseAddress__c);
            System.Debug('>> Checking case email to case email: ' + emailToCase);

            // by default a case shouldn't be excluded
            caseExclusions.put(c.Id, false);

            // check whether the case will be excluded based on the contact email address
            Boolean excluded = false;
            for(Pattern contactExclusionPattern : contactExclusionPatterns) {
                try {
                    // case insensitive matching
                    System.debug('contactExclusionPattern--->'+contactExclusionPattern);
                    if(contactExclusionPattern.matcher(caseContactEmail).find()) {
                        excluded = true;
                        break;
                    }
                } catch(Exception ex) { /* invalid rule format... ignore */ }
            }

            // the contact on the case caused the case to be excluded from NPS processing
            if(excluded) {
                caseExclusions.put(c.Id, true);
                continue;
            }
            System.debug('After Contact Pattern caseExclusions--->'+caseExclusions);
            // check for email-to-case exclusions
            excluded = false;
            for(Pattern emailToCaseExclusionPattern : emailToCaseExclusionPatterns) {
                try {
                    // case insensitive matching
                    if(emailToCaseExclusionPattern.matcher(emailToCase).matches()) {
                        excluded = true;
                        break;
                    }
                } catch(Exception ex) { /* invalid rule format... ignore */ }
            }

            // the contact on the case caused the case to be excluded from NPS processing
            if(excluded) {
                caseExclusions.put(c.Id, true);
            }
            System.debug('After emailToCase Pattern caseExclusions--->'+caseExclusions);
        }

        return caseExclusions;
    }

}