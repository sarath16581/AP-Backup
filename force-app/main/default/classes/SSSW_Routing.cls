/**
  * @author       :
  * @date         :
  * @description  : AP Routing service class
  * @test SSSW_Routing_Test, CaseCommonUtility_Test, ChasBaseTest
--------------------------------------- History ------------------------------------------------------------------------------------
* 10.28.2020             naseer.abbasi@auspost.com.au            Updated to cater for Strategic cases
* 2020-10-28 - Ranjeewa Silva - Refactored 'assignCasesAndDescription' to move population of description into it's own method.
* 2020-11-17 - Ranjeewa Silva - Allow Social cases to be routed based on social post tags on Case.
* 2021-03-10 - Hara Sahoo - Included getRules() within an inner class to allow all profiles(including guest users) to access the method
* 2021-06-30 - Steve Judd - Replaced getStrategicCustomerMappings with getArticleAttributesMap to return Extra Cover(Boolean) as well as isStrategic(Boolean)
* 2021-06-30 - Steve Judd - Modified assignCasesAndDescription to allow Extra Cover cases to be routed along with Strategic Cases.
* 2021-08-17 - Alex Volkov - Swapped out Automated_Network_Assignment__c for more generic ByPassRoutingRulesOnCreation__c
* 2022-10-11 - Noel Lim - route Cases to a holding queue Omni Default Queue if it requires an Article to be fetched from SAP-EM via MyCustomerCaseArticleModule queueable.
* 2022-10-26 - Noel Lim - change of existing boolean parameter's name and logic in assignCasesAndDescription(), from 'matchArticleRequiredRulesOnly' to 'isFinalPass'. 
**/

public class SSSW_Routing {

    /**
     * Mapping between the SSRS_Routing field and the corresponding Case field, provides flexibility
     * in terms of dealing with the option of adding/removing fields from the Case routing rules
     * We could potentially put this in a custom setting or dynamically load these from the
     * Sobject definition, at this point this degree of flexibility is not required
     * SSSW Routing Rule Field => Case Field..
     */
    private static final Map<String, String> fieldsMapping = new Map<String, String>{
        'Origin__c' => 'Origin',
        'High_Level_Complaint_Flag__c' => 'IsHLC__c',
        'EnquirySubType__c' => 'EnquirySubType__c',
        'Customer_Recovery_Flag__c' => 'IsCR__c',
        'CaseType__c' => 'Type',
        'CustomerQueueType__c' => 'Customer_Type__c',
        'ProductCategory__c' => 'ProductCategory__c',
        'ProductSubCategory__c' => 'ProductSubCategory__c',
        'Status__c' => 'Status',
        'IsNew__c' => 'IsNewForRouting__c',
        'SocialPostTags__c' => 'SocialPostTags__c'
    };

    /**
     * Mapping between SSSW_Routing field and the matcher to use when matching case field values.
     * If a matcher is not specified for the SSSW_Routing field, the default "Exact Match" matcher is used.
     */
    private static final Map<String, MatcherType> matcherTypeMapping = new Map<String, MatcherType>{
        'SocialPostTags__c' => MatcherType.ANY_EXACT_PHRASE_MATCH
    };

    /**
     * Routing fields to use when matching
     *
     * IsStrategic__c doesn't have a mapped case field, instead
     * its value is determined i.e. case->article->billingAccount.Organization.IsAPStrategicSupportCustomer
     */
    private static final List<String> routingFields = new List<String>{
        'Origin__c',
        'High_Level_Complaint_Flag__c',
        'EnquirySubType__c',
        'Customer_Recovery_Flag__c',
        'CaseType__c',
        'CustomerQueueType__c',
        'ProductCategory__c',
        'ProductSubCategory__c',
        'Status__c',
        'IsNew__c',
        'IsStrategic__c',
        'SocialPostTags__c',
        'HasExtraCover__c'
    };

    /**
     * NPS fields to use when matching
     */
    private static final List<String> npsFields = new List<String>{
        'Origin__c',
        'High_Level_Complaint_Flag__c',
        'EnquirySubType__c',
        'Customer_Recovery_Flag__c',
        'CaseType__c',
        'CustomerQueueType__c',
        'ProductCategory__c',
        'ProductSubCategory__c'
    };

    /**
     * AutoEscalation fields to use when matching
     */
    private static final List<String> autoEscalateFields = new List<String>{
        'Origin__c',
        'High_Level_Complaint_Flag__c',
        'EnquirySubType__c',
        'Customer_Recovery_Flag__c',
        'CaseType__c',
        'CustomerQueueType__c',
        'ProductCategory__c',
        'ProductSubCategory__c'
    };
    private static final String LOC_INTERNATIONAL = 'International';
    private static final Map<String,String> CUST_TYPE_QUEUE_MAP = new Map<String,String>{
        'International' => 'SSSWInternationalBackOffice',
        'Consumer' => 'SSSW_Consumer_Back_Office_Low_Priority',
        'Enterprise' => 'SSSWEnterpriseBackOffice',
        'SMB' => 'SSSWBusinessBackOffice',
        'Gold' => 'SSSWBusinessBackOffice',
        'MyPost Business' => 'SSSW_MyPost_Business_Back_Office'
    };

    /**
     * TODO: Only retrieve queues for Case Object.... this is pretty inefficient at the moment
     */
    private static Map<String, Group> groupNameMap {
        get {
            if(groupNameMap == null) {
                Map<Id, Group> groupIdMap = Utility.getGroups(SSSWConstants.QUEUE);

                groupNameMap = new Map<String, Group>();
                for (Group grp : groupIdMap.values()) {   // fetch queues to create group map
                    groupNameMap.put(grp.DeveloperName, grp);
                }
            }
            return groupNameMap;
        }
        set;
    }

    /* Date Modified: 22/06/2021
     * Removed - using articleWrapper instead
     * Stores a cached mapping of the existing articles already queried and their mappings to whether they are Extra Cover or not
     * Key is Article__c.ArticleID__c
     * Value is true/ false i.e. Strategic Support Customer or not.
     */

    // private static Map<String, Boolean> strategicCustomerMappings = new Map<String, Boolean>();

    /**
     * Date added: 22/06/2021
     * Map for storing linked articles and article attributes for determining strategic customers and Extra cover articles
     * Neither of these attributes has a case field to map to. Key is referenceId
     */
    private static  Map<String, ArticleAttributes> articleAttributesMap = new Map<String, ArticleAttributes>();

    /**
     * Stores cases that are needed to be rerouted later in the context once the Article is linked
     */
    @TestVisible
    private static List<Case> casesForReroutingAttempt = new List<Case>();

    /**
     * Stores list of Map case values that are used as the 'original state' when cases flagged for potentially strategic rerouting are processed in the MyCustomerCaseArticlesModule queueable
     * NOTE: These are stored as a map since some of the values we need to keep are formulas which aren't writable directly to the case record
     */
    @TestVisible
    private static List<Map<String, Object>> casesWithOriginalValues = new List<Map<String, Object>>();

    // Avoid Description change from Reassign Button
    public static Boolean reassignDescription = false;

    // Avoid Queue Check change from Reassign Button
    public static Boolean reassignNoCheckOwnerQueue = false;

    // Date Modified : 12/03/2021- Moving getRules() to an inner class GetRulesForAllProfiles. 
    // This is to allow guest profiles as well to access the method
    /**
     * Load the rules from the routing table based on the Recordtype passed in
     *      NPS, Escalation or Routing
     */
    /*private static List<SSSWRouting__c> getRules(String recordTypeName) {
        System.debug('recordTypeName--->'+recordTypeName);
        List<String> sswFields = new List<String>();
        //sswFields.addAll(fieldsMapping.keyset());
        sswFields.addAll(routingFields);
        String queryString = String.format('select {0},Sequence__c, Match_Rules_On__c, NPS_criteria__c, AutoEscalate__c, Recordtype.DeveloperName, ' +
                'Queue_ID__c, DefaultCaseDetails__c from SSSWRouting__c WHERE IsActive__c = true and Match_Rules_On__c != null and ' +
                '(RecordType.DeveloperName=\'\'{1}\'\') order by Sequence__c',
                new List<String>{
                    String.escapeSingleQuotes(String.join(sswFields, ',').removeEnd(',')),
                    (recordTypeName)
                });

        System.debug('queryString--->'+queryString);
        System.debug('sswFields--->'+sswFields);

        return (List<SSSWRouting__c>)Database.query(queryString);
    }*/
    /**
      * @description       This inner class is created to allow guest user profiles access the getRules() method.
                           This would help cases created by guest users to have the case description populated 
                           by retrieving the rules set in the SSSW_Routing object.
      *                    As due to critical update “Secure Object Permissions for Guest Users”
      *                    guest users can’t have more than read access.
	*/
    private without sharing class GetRulesForAllProfiles {
        
        public List<SSSWRouting__c> getRules(String recordTypeName) {
            List<String> sswFields = new List<String>();
            sswFields.addAll(routingFields);
            String queryString = String.format('select {0},Sequence__c, Match_Rules_On__c, NPS_criteria__c, AutoEscalate__c, Recordtype.DeveloperName, ' +
                                               'Queue_ID__c, DefaultCaseDetails__c, RuleRequiresArticleAttributes__c from SSSWRouting__c WHERE IsActive__c = true and Match_Rules_On__c != null and ' +
                                               '(RecordType.DeveloperName=\'\'{1}\'\') order by Sequence__c',
                                               new List<String>{
                                                   String.escapeSingleQuotes(String.join(sswFields, ',').removeEnd(',')),
                                                       (recordTypeName)
                                                       });
            return (List<SSSWRouting__c>)Database.query(queryString);
        }
    }
    

    public static boolean processAny(Case cs, SSSWRouting__c rule, List<String> matchingFields) {

        String referenceId = (String.isEmpty(cs.ReferenceID__c) ? '' : cs.ReferenceID__c.toLowerCase());
        Boolean ruleMatched = false;

        for (String matchingField : matchingFields) {
            String ruleValues = rule.get(matchingField) != null && !String.isEmpty(String.valueOf(rule.get(matchingField))) ? String.valueOf(rule.get(matchingField)) : '';
            // get the case value, defaults to empty String
            String caseValue;
            /**
             * Modified 2021-06-30 changed to use articleAttributesMap
             * IsStrategic doesn't have a corresponding case field defined in the routing mappings
             * HasExtraCover also does not have a corresponding case field defined in the routing mappings
             * IsStrategic value is determined by a static defined articleAttributesMap.isStrategic
             * Has ExtraCover is determined by a static defined articleAttributesMap.hasExtraCover
             */
            if(!matchingField.equalsIgnoreCase('IsStrategic__c') && !matchingField.equalsIgnoreCase('HasExtraCover__c')) {
                caseValue = cs.get(fieldsMapping.get(matchingField)) != null && !String.isEmpty(String.valueOf(cs.get(fieldsMapping.get(matchingField)))) ? String.valueOf(cs.get(fieldsMapping.get(matchingField))) : '';
                system.debug('case value in processANY:::'+caseValue);
            } else if(matchingField.equalsIgnoreCase('IsStrategic__c') && articleAttributesMap.get(referenceId) != null ) {
                caseValue = (!String.isEmpty(String.valueOf(articleAttributesMap.get(referenceId).isStrategic)) ? String.valueOf(articleAttributesMap.get(referenceId).isStrategic) : '');
            } else if(matchingField.equalsIgnoreCase('HasExtraCover__c') && articleAttributesMap.get(referenceId) != null ) {
                caseValue = (!String.isEmpty(String.valueOf(articleAttributesMap.get(referenceId).hasExtraCover)) ? String.valueOf(articleAttributesMap.get(referenceId).hasExtraCover) : '');
            }

            if(ruleValues != null && ruleValues != '' && ruleValues != 'false') {
                for (String ruleValue : (String.valueOf(ruleValues)).split(SSSWRoutingController.MULTI_SELECT_DELIM)) {
                    if (valueMatches(matchingField, caseValue, ruleValue)) {
                        ruleMatched = true;
                        break;
                    }
                }
            }
        }
        System.debug(LoggingLevel.ERROR, 'Against Rule ' + rule.Sequence__c + ':  ' + rule);
        System.debug(LoggingLevel.ERROR, 'Rule Match: ' + ruleMatched);

        if(ruleMatched){
            System.debug(LoggingLevel.ERROR, 'Match identified with rule at Sequence: ' + rule.Sequence__c);
        }
        return ruleMatched;
    }

    public static boolean processAll(Case cs, SSSWRouting__c rule, List<String> matchingFields) {
        String referenceId = (String.isEmpty(cs.ReferenceID__c) ? '' : cs.ReferenceID__c.toLowerCase());
        Map<String, Boolean> valueMatches = new Map<String, Boolean>();

        for (String matchingField : matchingFields) {
            // in some cases this will be a comma sparated list
            String ruleValues = (!String.isEmpty(String.valueOf(rule.get(matchingField))) ? String.valueOf(rule.get(matchingField)) : '');

            // get the case value, defaults to empty String
            String caseValue;
            /**
             * IsStrategic doesn't have a corresponding case field defined in the routing mappings
             * Its value is determined by a static defined 'articleAttributesMap' Map
             * Modified 21/6/2021: HasExtraCover__c is defined in 'extraCoverArticleMappings' Map
             */
            if(!matchingField.equalsIgnoreCase('IsStrategic__c') && !matchingField.equalsIgnoreCase('HasExtraCover__c')) {
                caseValue = cs.get(fieldsMapping.get(matchingField)) != null && !String.isEmpty(String.valueOf(cs.get(fieldsMapping.get(matchingField)))) ? String.valueOf(cs.get(fieldsMapping.get(matchingField))) : '';
            system.debug('caseValue:::: in processAll '+caseValue);
            } else if(matchingField.equalsIgnoreCase('IsStrategic__c') && articleAttributesMap.get(referenceId) != null ) {
                caseValue = (!String.isEmpty(String.valueOf(articleAttributesMap.get(referenceId).isStrategic)) ? String.valueOf(articleAttributesMap.get(referenceId).isStrategic) : '');
            } else if(matchingField.equalsIgnoreCase('HasExtraCover__c') && articleAttributesMap.get(referenceId) != null ) {
                caseValue = (!String.isEmpty(String.valueOf(articleAttributesMap.get(referenceId).hasExtraCover)) ? String.valueOf(articleAttributesMap.get(referenceId).hasExtraCover) : '');
            }
            system.debug('ruleValues in processALL:::'+ruleValues);
            if(ruleValues != null && ruleValues != '' && ruleValues != 'false') {
                System.debug(LoggingLevel.ERROR, 'RuleValues: ' + ruleValues);
                System.debug(LoggingLevel.ERROR, 'caseValue: ' + caseValue);

                for (String ruleValue : (String.valueOf(ruleValues)).split(SSSWRoutingController.MULTI_SELECT_DELIM)) {
                    if (valueMatches(matchingField, caseValue, ruleValue)) {
                        valueMatches.put(matchingField, true);
                        break;
                    } else {
                        valueMatches.put(matchingField, false);
                    }
                }
            }
        }

        System.debug(LoggingLevel.ERROR, 'Against Rule ' + rule.Sequence__c + ':  ' + rule);
        System.debug(LoggingLevel.ERROR, 'MatchMap: ' + valueMatches);

        Boolean ruleMatched = false;
        if(valueMatches.values().size() > 0) {
            ruleMatched = true;
            for (Boolean b : valueMatches.values()) {
                if(!b) {
                    ruleMatched = false;
                    break;
                }
            }
        }
        if(ruleMatched) {
            System.debug(LoggingLevel.ERROR, 'Match identified with rule at Sequence: ' + rule.Sequence__c);
        }
        return ruleMatched;
    }

    /**
     * Checks if the field value match the rule value based on the matcher type defined for the SSSW_Routing field.
     *
     * @param fieldName SSSW_Routing field. Determines the matcher to use.
     * @param fieldValue Field value specified in the case field.
     * @param ruleValue SSSW_Routing rule value to match
     *
     * @return true if match succefful, false otherwise.
     */
    @TestVisible private static Boolean valueMatches(String fieldName, String fieldValue, String ruleValue) {
        if  (matcherTypeMapping.get(fieldName) == MatcherType.ANY_EXACT_PHRASE_MATCH) {
            String regex = '(?i)(:?^|,)(' + ruleValue.trim() + ')(:?$|,)';
            return (Pattern.compile(regex).matcher(fieldValue).find());
        }

        // No special matcher types defined for the field. Use the default - exact match.
        return ruleValue.trim().equalsIgnoreCase(fieldValue);
    }

    /**
     * Method overridden, see next method.
     */
    public static void assignCasesAndDescription(list<Case> cases, Map<Id,Case> oldMap, Boolean isInsert) {
        assignCasesAndDescription(cases, oldMap, isInsert, false, false);
    }

    /**
     * Modified 2021-06-30 steve.judd6@auspost.com.au now caters for Has Extra Cover routing
     * Method serves below on the basis of rules defined in the SSSWRouting object.
     * 1. to route cases to the right Queue based on Routing rules
     * 2. to set Description on cases based on Description rules
     *
     *
     * Strategic Customer Cases have (Organization.IsStrategicSupportCustomer = true)
     * Extra Cover cases have ArticleTest.Article__c.Insurance_Amount__c > 0 && Article.MLID__c = null.
     * Routing engine skips routing in beforeInsert if:
     * 1. Rule is IsStrategic or hasExtraCover
     * 2. ArticleTest__c is null
     * Such cases to be re-routed once the ArticleTest__c gets populated in After Insert.
     *
     * H&S cases tracked via Automated_Network_Assignment__c flag to skip the routing
     * H&S will set ByPassRoutingRulesOnCreation__c flag for direct assignment
     *
     * @param skipDescriptionRules is meant to skip Description Rules and used only in context of Strategic cases
     * @param isFinalPass If routing was deferred because a rule was trigger that required article attributes, the second time routing is called from the MyCustomersCaseArticleModule, this flag will be true
     *                    It implies that on final pass, if the article exists and is linked to a case, the rule can be processed, if the article does not exist (error quering sap-em or not found), then skip the article rule and move to the next
     *
     */
    public static void assignCasesAndDescription(list<Case> cases, Map<Id,Case> oldMap, Boolean isInsert, Boolean skipDescriptionRules, Boolean isFinalPass) {
        String recType = SSSWConstants.RECTYPEROUTING + '\' OR RecordType.DeveloperName=\'' + SSSWConstants.RECTYPEDESCRIPTION;

        //Replacing it with GetRulesForAllProfiles
        //List<SSSWRouting__c> rules = getRules(recType);
        GetRulesForAllProfiles obj = new GetRulesForAllProfiles ();
        List<SSSWRouting__c> rules = obj.getRules(recType);
        System.debug('rules--->'+rules);
        List<SSSWRouting__c> routeRule = new List<SSSWRouting__c>();
        List<SSSWRouting__c> descRule = new List<SSSWRouting__c>();
        for(SSSWRouting__c rule : rules){
            if(rule.DefaultCaseDetails__c != '' && rule.RecordType.DeveloperName == SSSWConstants.RECTYPEDESCRIPTION) {
                descRule.add(rule);
            } else if(rule.Queue_ID__c != '' && rule.RecordType.DeveloperName == SSSWConstants.RECTYPEROUTING) {
                routeRule.add(rule);
            }
        }
        // system caches mapping for cases articles(based on ReferenceID__c) to strategic customers
        // Where strategic customer value is determined by Organization.IsStrategicSupportCustomer
        // skipDescriptionRules explicitly gets set from queueable in MyCustomerCaseArticleModule
        // Where we are re-attempting to route the cases that have Article linked to them
        Set<String> referenceIds = new Set<String>();
        for(Case c : cases) {
            if(!String.isEmpty(c.ReferenceID__c)) {
                referenceIds.add(c.ReferenceID__c);
            }
        }
        system.debug('referenceIDs:::'+referenceIds);
        if(!referenceIds.isEmpty()) {
            getArticleAttributesMap(referenceIds);
            system.debug('reference ids after getRelatedArticleMappings: '+referenceIds );            
        }

        for (Case cs : cases) {
            Id routingOwner; 
            Case oldCase = oldMap != null ? oldMap.get(cs.Id) : null;

            // we only want to process the routing rules in these scenarios:
            // 1. if the case is being reassigned (through the ui) - CaseDetails page
            // 2. If a reroute is triggered by setting allocatetoqueue__c = true)
            //
            // There are some fringe scenarios where routing should be excluded and due to the mess in workflows a new attribute was introduced to achieve this  (ByPassRoutingRulesOnCreation__c)
            if((reassignNoCheckOwnerQueue || (cs.AllocateToQueue__c != null && cs.AllocateToQueue__c == true)) && !(isInsert && cs.ByPassRoutingRulesOnCreation__c)) {

                for (SSSWRouting__c rule : routeRule) {
                    System.debug(LoggingLevel.ERROR, 'cs.Type >> ' + cs.Type);
                    if (rule.Match_Rules_On__c.equals('ANY')) {
                        System.debug(LoggingLevel.ERROR, '**Processing ANY rule');

                        // Ensuring cases follow the default routing logic if rule is not Strategic
                        // Also ensuring incase of a Strategic rule (ordered by sequence__c and ArticleID isn't present),
                        // then skip such cases for later queue assignment since ArticleId gets determined later in the context.
                        // We will check for Article Id in SF once in beforeInsert (in MyCustomerCaseArticlesModule),
                        // if found in SF, system will make an explicit call to assignCasesAndDescription() to find the queue.
                        // if not found in SF, system to search SAP-EM in afterInsert (queueable in MyCustomerCaseArticlesModule),
                        // if found in SAP-EM, explicit call to assignCasesAndDescription() to find the queue
                        //TODO: have to set AllocateToQueue = false for portal cases
                        // Network cases to be skipped from routing in Insert Context
                        //
                        // Modified 25/6/2021 to use RuleRequiresArticleAttributes__c ( true when either IsStrategic OR HasExtraCover is true)
                        // cases follow default logic if it is not either of these.
                        if (!rule.RuleRequiresArticleAttributes__c || (rule.RuleRequiresArticleAttributes__c && cs.ArticleTest__c != null)) {
                            if (processAny(cs, rule, routingFields)) {
                                System.debug(LoggingLevel.ERROR, 'Inside ANY rule Assign Case--->' + rule);
                                routingOwner = rule.Queue_ID__c;

                                system.debug('rule routing owner id: ' + routingOwner);

                                // set the new owner
                                setRoutingCaseOwner(cs, routingOwner);

                                // setting flag on case since selected routing rule is a strategic one
                                // its required to avoid triggering the specific workflow rules that might reset the case owner
                                cs.LastRoutingRuleIsStrategic__c = rule.RuleRequiresArticleAttributes__c ? true : false;

                                break;
                            }

                            // Cases being created from H&S can be routed direct to network (currently via a queueable)
                            // In this scenario we ignore any strategic routing checks
                        } else if (rule.RuleRequiresArticleAttributes__c && cs.ArticleTest__c == null && !isFinalPass && ((!isInsert && !String.isEmpty(cs.ReferenceID__c)) || (isInsert && !String.isEmpty(cs.ReferenceID__c) && !cs.ByPassRoutingRulesOnCreation__c)) && !casesForReroutingAttempt.contains(cs)) {

                            // if this is strategic customer routing rule but the case has no articlee linked, we store this to be routed later in MyCustomerCaseArticleModule (where the SAP EM queueable run that links the case to an article)
                            // NOTE that we skip this rerouting assignment if the case is created and directly assigned to a network.
                            // we skip this to ensure we don't overwrite the network owner
                            casesForReroutingAttempt.add(cs);

                            // as part of the strategic rerouting attempt we need to make, we need to route it based on the current case values as they are here
                            // workflows and other code may change these but we still need to route the case based on the original values when it entered into the routing method
                            // since we may not have the ID of the case yet, we store these in a list that corresponds to the index in the casesForReroutingAttempt
                            casesWithOriginalValues.add(getCaseWithFieldsMapping(cs));

                            //Throw an exception if the default Queue has not been set, but allow the Case to be created
                            String omniDefaultQueue = QM__c.getOrgDefaults().OmniDefaultQueueId__c;
                            if (String.isEmpty(omniDefaultQueue) == false) {
                                setRoutingCaseOwner(cs, omniDefaultQueue);
                            }

                            break;
                        }
                    } else if (Rule.Match_Rules_On__c.equals('ALL')) {
                        System.debug(LoggingLevel.ERROR, '**Processing ALL rule');

                        // Ensuring cases follow the default routing logic if rule is not Strategic
                        // Also ensuring incase of a Strategic rule (ordered by sequence__c and ArticleID isn't present),
                        // then skip such cases for later queue assignment since ArticleId gets determined later in the context.
                        // We will check for Article Id in SF once in beforeInsert (in MyCustomerCaseArticlesModule),
                        // if found in SF, system will make an explicit call to assignCasesAndDescription() to find the queue.
                        // if not found in SF, system to search SAP-EM in afterInsert (queueable in MyCustomerCaseArticlesModule),
                        // if found in SAP-EM, explicit call to assignCasesAndDescription() to find the queue
                        //TODO: have to set AllocateToQueue = false for portal cases
                        // Network cases to be skipped from routing in Insert context
                        system.debug('Rule required article attributes::: ' + rule.RuleRequiresArticleAttributes__c);
                        system.debug('match strategic rule only::: ' + isFinalPass);
                        if (!rule.RuleRequiresArticleAttributes__c || (rule.RuleRequiresArticleAttributes__c && cs.ArticleTest__c != null && (!isInsert || (isInsert && !cs.ByPassRoutingRulesOnCreation__c)))) {
                            if (processAll(cs, rule, routingFields) && rule.recordtype.developerName == SSSWConstants.RECTYPEROUTING) {
                                System.debug(LoggingLevel.ERROR, 'Inside ALL rule Assign Case--->' + rule);
                                routingOwner = rule.Queue_ID__c;

                                // set the new owner
                                setRoutingCaseOwner(cs, routingOwner);

                                // setting flag on case since selected routing rule is a strategic one
                                // its required to avoid triggering the specific workflow rules that might reset the case owner
                                cs.LastRoutingRuleIsStrategic__c = rule.RuleRequiresArticleAttributes__c ? true : false;

                                break;
                            }
                            // Cases being created from H&S can be routed direct to network (currently via a queueable)
                            // In this scenario we ignore any strategic routing checks
                        } else if (rule.RuleRequiresArticleAttributes__c && cs.ArticleTest__c == null && !isFinalPass && ((!isInsert && !String.isEmpty(cs.ReferenceID__c)) || (isInsert && !String.isEmpty(cs.ReferenceID__c) && !cs.ByPassRoutingRulesOnCreation__c)) && !casesForReroutingAttempt.contains(cs)) {
                            // if this is strategic customer routing rule but the case has no articlee linked, we store this to be routed later in MyCustomerCaseArticleModule (where the SAP EM queueable run that links the case to an article)
                            // NOTE that we skip this rerouting assignment if the case is created and directly assigned to a network.
                            // we skip this to ensure we don't overwrite the network owner
                            casesForReroutingAttempt.add(cs);

                            // as part of the strategic rerouting attempt we need to make, we need to route it based on the current case values as they are here
                            // workflows and other code may change these but we still need to route the case based on the original values when it entered into the routing method
                            // since we may not have the ID of the case yet, we store these in a list that corresponds to the index in the casesForReroutingAttempt
                            casesWithOriginalValues.add(getCaseWithFieldsMapping(cs));

                            //Throw an exception if the default Queue has not been set, but allow the Case to be created
                            String omniDefaultQueue = QM__c.getOrgDefaults().OmniDefaultQueueId__c;
                            if (String.isEmpty(omniDefaultQueue) == false) {
                                setRoutingCaseOwner(cs, omniDefaultQueue);
                            }

                            break;
                        }
                    }
                }
            }

            // skipDescriptionRules is false for cases in the normal context
            // its only set to true in re-routing context for Strategic cases
            if(!skipDescriptionRules) {
                //Evaluating description rules and set description field on case
                setCaseDescription(cs, oldCase, descRule);
            }
        }
    }
    @TestVisible
    private static Boolean setRoutingCaseOwner(case cs, Id routingOwner){
        //if(cs.AllocateToQueue__c != null && cs.AllocateToQueue__c){
            String queueKey = LOC_INTERNATIONAL.equalsIgnoreCase(cs.CaseLocality__c) ?
                                LOC_INTERNATIONAL : cs.Customer_Type__c;
            cs.OwnerId = (routingOwner != null) ? routingOwner : (String.isNotBlank(queueKey) && groupNameMap.containsKey(CUST_TYPE_QUEUE_MAP.get(queueKey))) ?
                                                                        groupNameMap.get(CUST_TYPE_QUEUE_MAP.get(queueKey)).Id : cs.OwnerId;
            cs.AllocateToQueue__c = false;     // disable case queue allocation

            return true;
        //}

        //return false;
    }
    public static void applyNPSRules(List<Case> cases) {
        //Replacing it with GetRulesForAllProfiles
        //List<SSSWRouting__c> rules = getRules(SSSWConstants.RECTYPENPS);
        GetRulesForAllProfiles obj = new GetRulesForAllProfiles ();
        List<SSSWRouting__c> rules = obj.getRules(SSSWConstants.RECTYPENPS);
        Boolean ruleFound = false; //Check if rule exist else set NPS details
        DateTime currentTime = Datetime.now();
        System.debug('NPS rules--->'+rules);
        for (Case cs : cases) {
            System.debug('cs.closedDate--->'+ cs.closedDate);
            for (SSSWRouting__c rule : rules) {
                if(Rule.Match_Rules_On__c.equals('ANY')) {
                    System.debug(LoggingLevel.ERROR,'**Processing ANY rule NPS');
                    if(processAny(cs, rule, npsFields)) {
                        ruleFound = true;
                        //cs.NPSRequired__c = rule.NPS_criteria__c == 'Exclude' ? false : true;
                        if(rule.NPS_criteria__c != 'Exclude') {
                            // set the NPS specific values and use  Bypass_Data_enforcement__c to ensure no validation errors will occur during the update
                            cs.NPSScheduledDate__c = currentTime.AddDays(1);
                            cs.NPSAgent__c = cs.LastModifiedById; // set NPS agent as last modified user
                            //cs.Bypass_Data_enforcement__c = true;  // by pass validation
                        }
                        break;
                    }
                } else if(Rule.Match_Rules_On__c.equals('ALL')) {
                    System.debug(LoggingLevel.ERROR,'**Processing ALL rule NPS');
                    if(processAll(cs, rule, npsFields)) {
                        ruleFound = true;
                        // cs.NPSRequired__c = rule.NPS_criteria__c == 'Exclude' ? false : true;
                        if(rule.NPS_criteria__c != 'Exclude'){
                            // set the NPS specific values and use  Bypass_Data_enforcement__c to ensure no validation errors will occur during the update
                            cs.NPSScheduledDate__c = currentTime.AddDays(1);
                            cs.NPSAgent__c = cs.LastModifiedById; // set NPS agent as last modified user
                            //cs.Bypass_Data_enforcement__c = true;  // by pass validation
                        }
                        break;
                    }
                }
            }
            //Set default value if no rule found
            if(!ruleFound){
                System.debug('Set default value if no rule found--->');
                cs.NPSScheduledDate__c = currentTime.AddDays(1);
                cs.NPSAgent__c = cs.LastModifiedById; // set NPS agent as last modified user
                //cs.Bypass_Data_enforcement__c = true;  // by pass validation
            }
        }
    }

    public static Boolean checkAutoEscalate(Case cs) {
        Boolean retValue = false;
        //Replacing it with GetRulesForAllProfiles
        //List<SSSWRouting__c> rules = getRules(SSSWConstants.RECTYPEESCALATION);
        GetRulesForAllProfiles obj = new GetRulesForAllProfiles ();
        List<SSSWRouting__c> rules = obj.getRules(SSSWConstants.RECTYPEESCALATION);
        DateTime currentTime = Datetime.now();
        for (SSSWRouting__c rule : rules) {
            if(Rule.Match_Rules_On__c.equals('ANY')) {
                System.debug(LoggingLevel.ERROR,'**Processing ANY rule Escalate');
                if(processAny(cs, rule, autoEscalateFields)) {
                    retValue = rule.AutoEscalate__c;
                    break;
                }
            } else if(Rule.Match_Rules_On__c.equals('ALL')) {
                System.debug(LoggingLevel.ERROR,'**Processing ALL rule Escalate');
                if(processAll(cs, rule, autoEscalateFields)) {
                    retValue = rule.AutoEscalate__c;
                    break;
                }
            }
        }
        return retValue;
    }

    /**
    * Modified 22/6/2021: changed from returning single map to return multiple article
    * attributes
    * Determine if the Customer related to an article is a Strategic Support Customer
    * @param - Set of case key i.e. Reference Id
    * @return - Maps of ReferenceId and ArticleAttributes (Boolean  IsStrategicSupportCustomer__c i.e. True/False
    * and Boolean for HasExtraCover i.e. True/False)
     */
    public static Map<String, ArticleAttributes> getArticleAttributesMap(Set<String> referenceIdSet) {

        Set<String> queryableReferenceIds = new Set<String>(referenceIdSet);

        queryableReferenceIds.removeAll(articleAttributesMap.keySet());
        system.debug('articleAttributesMap inside getRelatedArticleMappings: '+articleAttributesMap);
        system.debug('queryableReferenceIds inside getRelatedArticleMappings: '+queryableReferenceIds);

        if(!queryableReferenceIds.isEmpty()) {
            SSSWCaseRelatedData obj = new SSSWCaseRelatedData();
            List<Article__c> articles = obj.getArticles(queryableReferenceIds);
            
            for(Article__c a : articles) {
                ArticleAttributes attributes = new ArticleAttributes();
                // initialise values to false
                attributes.isStrategic = false;
                if(!String.isEmpty(a.ArticleID__c) && a.Billing_Account__r != null && a.Billing_Account__r.Organisation__r != null && a.Billing_Account__r.Organisation__r.IsStrategicSupportCustomer__c !=  null) {
                    attributes.isStrategic = a.Billing_Account__r.Organisation__r.IsStrategicSupportCustomer__c;
                }
                attributes.hasExtraCover = a.HasExtraCover__c;
                articleAttributesMap.put(a.ArticleID__c.toLowerCase(), attributes);
            }
        }
        System.debug('getRelatedArticleMappings :'+articleAttributesMap);
        return articleAttributesMap;
    }

    /**
     * Get the cached list of cases that need to be rerouted
     * @param - N/A
     * @return - Case list
     */
    public static List<Case> getAttemptableReroutableCases() {
        return casesForReroutingAttempt;
    }

    /**
     * Grabs a list of cases
     * These cases contain original values for routing fields
     * @param - N/A
     * @return - String
     */
    public static List<Map<String, Object>> getCaseOriginalValuesForReroutingAttempt() {
        return casesWithOriginalValues;
    }

    /**
     *
     * @param - N/A
     * @return - N/A
     */
    public static void FlipReassignDescription() {
        reassignDescription = True;
    }

    /**
     * Get the defined SSSWRouting fields to Case field mappings
     * @param - N/A
     * @return - Map of SSSWRouting to Case fields
     */
    public static Map<String, String> getFieldsMapping() {
        return fieldsMapping;
    }

    /**
     * Get a map of the provided case for routing fields (for fields defined in fieldsMapping)
     * @param - Case record
     * @return - Map of case fields (field -> value)
     */
    private static Map<String, Object> getCaseWithFieldsMapping(Case currentCase) {

        // grab all the populated fields on the case
        // clone this since getPopulatedFieldsAsMap returns a read only collection
        Map<String, Object> populatedValues = currentCase.getPopulatedFieldsAsMap().clone();

        // grab a list of the fields not in the fieldsMapping var
        Set<String> fieldsToRemove = populatedValues.keySet().clone();
        fieldsToRemove.removeAll(fieldsMapping.values());

        // remove all the fields not in the fieldMapping
        populatedValues.keySet().removeAll(fieldsToRemove);

        return populatedValues;
    }

    /**
     * Populate 'Description' field on the cases passed on based on the rules in SSSWRouting__c records.
     * All description case rules have 'SSSWDescription' record type.
     *
     * @param cases list of case records to populate description
     * @param oldMap  old versions of case records if records are updated. Pass null otherwise.
     */
    public static void populateCaseDescriptionFromDescriptionRules(List<Case> cases, Map<Id,Case> oldMap) {

        // Replacing it with GetRulesForAllProfiles
        //List<SSSWRouting__c> rules = getRules(SSSWConstants.RECTYPEDESCRIPTION);
        GetRulesForAllProfiles obj = new GetRulesForAllProfiles ();
        List<SSSWRouting__c> rules = obj.getRules(SSSWConstants.RECTYPEDESCRIPTION);
        List<SSSWRouting__c> descRule = new List<SSSWRouting__c>();
        for(SSSWRouting__c rule : rules){
            if(rule.DefaultCaseDetails__c!='' && rule.recordtype.developerName == SSSWConstants.RECTYPEDESCRIPTION){
                descRule.add(rule);
            }
        }

        for (Case cs : cases) {
            Case oldCase = oldMap != null ? oldMap.get(cs.Id) : null;
            setCaseDescription(cs, oldCase, descRule);
        }
    }

    /**
     * Evaluate description rules passed in and populate case description based on the rules.
     * Code orginally in assignCasesAndDescription() moved into a own method to promote reuse.
     *
     * @param newCase case record to populate description
     * @param oldCase old version of case record if case is updated. Pass null otherwise.
     * @param descriptionRules list of description rules (SSSWRount__c) to evaluate
     */
    private static void setCaseDescription(Case newCase, Case oldCase, List<SSSWRouting__c> descriptionRules) {

        //NOTE - Code initially in assignCasesAndDescription(). Moved here for re-use.

        for(SSSWRouting__c rule : descriptionRules){
            if(rule.Match_Rules_On__c.equals('ANY')) {
                System.debug(LoggingLevel.ERROR,'**Processing ANY rule');
                if(processAny(newCase, rule, routingFields) && (String.isBlank(newCase.Description) || oldCase == null) && !reassignDescription){
                    System.debug(LoggingLevel.ERROR,'Inside ANY rule Description--->'+rule);
                    newCase.Description = (newCase.Description !=null && !String.isEmpty(newCase.Description)?newCase.Description +'\n' :'')
                            + (rule.DefaultCaseDetails__c!=null &&!String.isEmpty(rule.DefaultCaseDetails__c) ? rule.DefaultCaseDetails__c:'');
                    break;
                }
            } else if(Rule.Match_Rules_On__c.equals('ALL')) {
                System.debug(LoggingLevel.ERROR,'Inside ALL rule Description--->'+rule);
                if(processAll(newCase, rule, routingFields) && (String.isBlank(newCase.Description) || oldCase == null) && !reassignDescription){
                    newCase.Description = (newCase.Description !=null && !String.isEmpty(newCase.Description)?newCase.Description +'\n' :'')
                            + (rule.DefaultCaseDetails__c!=null &&!String.isEmpty(rule.DefaultCaseDetails__c) ? rule.DefaultCaseDetails__c:'');
                    break;
                }
            }
        }
    }
    
    /**
     * @description
     * Inner class for the Strategic Customer routing requirement.
     * Specifically required for DDC Consumer Community Users creating/reading Articles.
     */
    public without sharing class SSSWCaseRelatedData {
        private List<Article__c> articleList;

        public SSSWCaseRelatedData() {
            articleList = new List<Article__c>();
        }
    
        /**
         * Get Articles by tracking ids
         * @param - Set of String i.e Referernce Ids
         * @return - Article list
         */
        public List<Article__c> getArticles(Set<String> queryableReferenceIds) {
            Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
                Article__c.SObjectType => new Set<SObjectField>{Article__c.Id, Article__c.ArticleID__c, Article__c.MLID__c, Article__c.InsuranceAmount__c, Article__c.HasExtraCover__c},
                Billing_Account__c.SObjectType => new Set<SObjectField>(),
                Account.SObjectType => new Set<SObjectField>{Account.IsStrategicSupportCustomer__c}
            };
    
            articleList = ArticlesSelector.newInstance(0, fieldOverrides).selectByTracking(queryableReferenceIds, new Set<Object>{
                ArticlesSelector.Options.WITH_BILLINGACCOUNT, BillingAccountsSelector.Options.WITH_ORGANISATION
            }, false).values();
            
            System.debug('articles >>'+articleList);
            return articleList;
        }
    }

    private enum MatcherType {
        EXACT_MATCH, // case field value should exactly match the SSSW rule field value (case insensitive).
        ANY_EXACT_PHRASE_MATCH // SSSW_Rule field value (word or a phrase) should match any one phrase in a comma separated list of phrases in the case field value.
    }
    /**
     * Holds Booleans for isStrategic and HasExtraCover
     */
    @TestVisible
    public class ArticleAttributes {
        public Boolean isStrategic {get; set;}
        public Boolean hasExtraCover {get; set;}
    }

     /**
     * Generic Error Exception 
     */
    @TestVisible
    private class ErrorException extends Exception { }

    // public static void assignDescription(list<Case> cases) {
    //     System.debug('Inside assignDescription--->');
    //     List<SSSWRouting__c> rules = getRules(SSSWConstants.RECTYPEDESCRIPTION);
    //     System.debug('rules--->'+rules);
    //     for (Case cs : cases) {
    //         for (SSSWRouting__c rule : rules) {
    //             if(Rule.Match_Rules_On__c.equals('ANY')) {
    //                 System.debug(LoggingLevel.ERROR,'**Processing ANY rule Description');
    //                 if(processAny(cs, rule, routingFields)) {
    //                     cs.Description = (cs.Description !=null && !String.isEmpty(cs.Description)?cs.Description +'\n' :'')
    //                                               + (rule.DefaultCaseDetails__c!=null &&!String.isEmpty(rule.DefaultCaseDetails__c) ? rule.DefaultCaseDetails__c:'');
    //                     break;
    //                 }
    //             } else if(Rule.Match_Rules_On__c.equals('ALL')) {
    //                 System.debug(LoggingLevel.ERROR,'**Processing ALL rule Description');
    //                 if(processAll(cs, rule, routingFields)) {
    //                     cs.Description = (cs.Description !=null && !String.isEmpty(cs.Description)?cs.Description +'\n' :'')
    //                                               + (rule.DefaultCaseDetails__c!=null &&!String.isEmpty(rule.DefaultCaseDetails__c) ? rule.DefaultCaseDetails__c:'');
    //                     break;
    //                 }
    //             }
    //         }
    //     }
    // }
}