/**
 * @author       :
 * @date         :
 * @description  :
 *--------------------------------------- History --------------------------------------------------
 *
 * 17-Nov-2020 - Ranjeewa Silva - Updated to include new field on SSSW Rule - 'SocialPostTags__c'
 * 24-Jul-2024 - Ranjeeea Silva - Updated to return "Unified Routing" records for display only.
**/
public with sharing class SSSWSortingController {
    public String pageMode { get; set; }
    public String newSeqFrom { get; set; }
    public String newSeqFromNPS { get; set; }
    public String newSeqFromEscalate { get; set; }
    public String newSeqFromDescription { get; set; }
    public Integer delRouteNo { get; set; }
    public List<routingWrapper> rulesWithQueues { get; set; }
    public List<SSSWRouting__c> rulesForNPS { get; set; }
    public List<SSSWRouting__c> rulesForEscalate { get; set; }
    public List<SSSWRouting__c> rulesForDescription { get; set; }
    public List<RoutingWrapper> rulesForUnifiedCaseRouting { get; set; }
    public String selectedRecordType { get; set; }
    public String recType { get; set; }

    private static final List<String> routingFields = new List<String>{
        'Id', 'IsActive__c', 'Origin__c', 'Description__c',
        'ProductCategory__c', 'ProductSubCategory__c', 'CaseType__c', 
        'EnquirySubType__c', 'Network__c', 'DefaultCaseDetails__c',
        'AutoEscalate__c', 'ExcludeFromNPS__c', 'CustomerQueueType__c', 
        'Queue_ID__c', 'CaseRecordTypeId__c', 'High_Level_Complaint_Flag__c',
        'Customer_Recovery_Flag__c', 'Match_Rules_On__c', 
        'Sequence__c', 'NPS_criteria__c' , 'IsNew__c', 'IsStrategic__c', 'SocialPostTags__c', 'HasExtraCover__c',
		'PreferredAgentExpiry__c', 'Status__c'
    };

    private static List<SSSWRouting__c> getRules(String recordTypeName) {
        System.debug('recordTypeName--->'+recordTypeName);
        String queryString = String.format('select {0} ' +   
                'from SSSWRouting__c WHERE IsActive__c = true and Match_Rules_On__c != null and ' +
                'RecordType.DeveloperName=\'\'{1}\'\' order by Sequence__c',
                new List<String>{
                    String.escapeSingleQuotes(String.join(routingFields, ',').removeEnd(',')),
                    String.escapeSingleQuotes(recordTypeName)
                });
        System.debug('queryString--->'+queryString);
        System.debug('routingFields--->'+routingFields);

        return (List<SSSWRouting__c>)Database.query(queryString);
    }

    public SSSWSortingController() {
        System.debug('Inside Constructor');
        selectedRecordType = 'SSSW Routing';
        getRoutings();
        getNPS();
        getEscalate();
        getDescription();
        getUnifiedRoutingRules();
    }

    public void sortRoutings() {
        System.debug('recType--->'+recType);
        selectedRecordType = recType;
        pageMode = 'sort';
    }

    public void cancelSort() {
        System.debug('recType--->'+recType);
        selectedRecordType = recType;
        pageMode = 'detail';
    }

    public void refreshRoutings() {
        System.debug('Inside refreshRoutings');
        System.debug('Routing selectedRecordType--->'+selectedRecordType);
        pageMode = 'detail';
        getRoutings();
        selectedRecordType = recType;
    }

    public void refreshNPS() {
        System.debug('Inside refreshNPS');
        System.debug('NPS selectedRecordType--->'+selectedRecordType);
        pageMode = 'detail';
        getNPS();
        selectedRecordType = recType;
    }

    public void refreshEscalate() {
        System.debug('Inside refreshEscalate');
        System.debug('Escalate selectedRecordType--->'+selectedRecordType);
        pageMode = 'detail';
        getEscalate();
        selectedRecordType = recType;
    }

    public void refreshDescription() {
        System.debug('Inside refreshDescription');
        System.debug('Description selectedRecordType--->'+selectedRecordType);
        pageMode = 'detail';
        getDescription();
        selectedRecordType = recType;
    }

    public void saveRoutings() {
        List<SSSWRouting__c> routesToUpdate = new List<SSSWRouting__c>();
        for(routingWrapper rw : rulesWithQueues) {
            routesToUpdate.add(rw.rule);
        }
        update routesToUpdate;
        getRoutings();
        pageMode = 'detail';
        selectedRecordType = recType;
    }

    public void saveNPS() {
        List<SSSWRouting__c> routesToUpdate = new List<SSSWRouting__c>();
        for(SSSWRouting__c rw : rulesForNPS) {
            routesToUpdate.add(rw);
        }
        update routesToUpdate;
        getNPS();
        pageMode = 'detail';
        selectedRecordType = recType;
    }

    public void saveEscalate() {
        List<SSSWRouting__c> routesToUpdate = new List<SSSWRouting__c>();
        for(SSSWRouting__c rw : rulesForEscalate) {
            routesToUpdate.add(rw);
        }
        update routesToUpdate;
        getEscalate();
        pageMode = 'detail';
        selectedRecordType = recType;
    }

    public void saveDescription() {
        List<SSSWRouting__c> routesToUpdate = new List<SSSWRouting__c>();
        for(SSSWRouting__c rw : rulesForDescription) {
            routesToUpdate.add(rw);
        }
        update routesToUpdate;
        getDescription();
        pageMode = 'detail';
        selectedRecordType = recType;
    }

    public void deleteRouting() {
        List<SSSWRouting__c> routesToUpdate = new List<SSSWRouting__c>();
        for(routingWrapper rw : rulesWithQueues) {
            routesToUpdate.add(rw.rule);
        }
        try {
            for (SSSWRouting__c sr : routesToUpdate) {
                if (sr.Sequence__c > delRouteNo) {
                    sr.Sequence__c = sr.Sequence__c - 1;
                }
            }
            update routesToUpdate;
            //Minus 1 due to zero based index
            delRouteNo = delRouteNo - 1;
            delete routesToUpdate[delRouteNo];
            getRoutings();
            selectedRecordType = recType;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occured deleting your Route: ' + e));
        }
    }

    public void deleteNPS() {
        System.debug('Inside deletedNPS');
        List<SSSWRouting__c> routesToUpdate = new List<SSSWRouting__c>();
        try {
            for (SSSWRouting__c sr : rulesForNPS) {
                routesToUpdate.add(sr);
                if (sr.Sequence__c > delRouteNo) {
                    sr.Sequence__c = sr.Sequence__c - 1;
                }
            }
            update routesToUpdate;
            //Minus 1 due to zero based index
            delRouteNo = delRouteNo - 1;
            delete routesToUpdate[delRouteNo];
            getNPS();
            selectedRecordType = recType;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occured deleting your Route: ' + e));
        }
    }

    public void deleteEscalate() {
        System.debug('Inside deletedEscalate');
        List<SSSWRouting__c> routesToUpdate = new List<SSSWRouting__c>();
        try {
            for (SSSWRouting__c sr : rulesForEscalate) {
                routesToUpdate.add(sr);
                if (sr.Sequence__c > delRouteNo) {
                    sr.Sequence__c = sr.Sequence__c - 1;
                }
            }
            update routesToUpdate;
            //Minus 1 due to zero based index
            delRouteNo = delRouteNo - 1;
            delete routesToUpdate[delRouteNo];
            getEscalate();
            selectedRecordType = recType;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occured deleting your Route: ' + e));
        }
    }

    public void deleteDescription() {
        System.debug('Inside deletedDescription');
        List<SSSWRouting__c> routesToUpdate = new List<SSSWRouting__c>();
        try {
            for (SSSWRouting__c sr : rulesForDescription) {
                routesToUpdate.add(sr);
                if (sr.Sequence__c > delRouteNo) {
                    sr.Sequence__c = sr.Sequence__c - 1;
                }
            }
            update routesToUpdate;
            //Minus 1 due to zero based index
            delRouteNo = delRouteNo - 1;
            delete routesToUpdate[delRouteNo];
            getDescription();
            selectedRecordType = recType;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occured deleting your Route: ' + e));
        }
    }

    public List<SelectOption> getrecordTypes() {
        List<String> recs = new List<String>();
        List<SelectOption> recTypeOptions = new List<SelectOption>();
        List<RecordType> recType = [Select Id, name From RecordType where sobjecttype = 'SSSWRouting__c' and isActive = True order by createdDate];
        for(recordType rt: recType)
        {
            recTypeOptions.add(new SelectOption(rt.name,rt.name));
        }
        //selectedRecordType = 'SSSW Routing';
        System.debug('selectedRecordType--->'+selectedRecordType);
        return recTypeOptions;
    }

    @AuraEnabled
    public static List<RoutingRule> getRoutingRules() {
        List<SSSWRouting__c> rules = new List<SSSWRouting__c>([
            Select Id, IsActive__c, Origin__c, ProductCategory__c, ProductSubCategory__c, CaseType__c, EnquirySubType__c, Network__c, DefaultCaseDetails__c,
                AutoEscalate__c, ExcludeFromNPS__c, CustomerQueueType__c, Queue_ID__c, CaseRecordTypeId__c, High_Level_Complaint_Flag__c,
                Customer_Recovery_Flag__c, Match_Rules_On__c, Sequence__c, Description__c, IsStrategic__c, SocialPostTags__c, HasExtraCover__c,
				PreferredAgentExpiry__c,Status__c
            from SSSWRouting__c
            where Match_Rules_On__c != null
            order by Sequence__c Asc
        ]);

        Integer index = 1;
        List<RoutingRule> output = new List<RoutingRule>();
        for (SSSWRouting__c rule : rules) {
            output.add(new RoutingRule(index, rule));
            index++;
        }
        return output;

//        Integer lastIndex = 0;
//        for (SSSWRouting__c rule : rules) {
//            if (s.Sequence__c != null && s.Sequence__c > lastIndex) {
//                lastIndex = Integer.valueOf(s.Sequence__c);
//            }
//        }
//        newSeqFrom = String.valueOf(lastIndex + 1);
//
//        //Setup a wrapper of rules to queue names for the view.
//        Set<String> queueIds = new Set<String>();
//        for (SSSWRouting__c ssswrQId : ssswR) {
//            queueIds.add(ssswrQId.Queue_ID__c);
//        }
//        List<Group> queueNameList = new List<Group>([select id, Name from Group where Id in:queueIds]);
//        Map<String,String> queueNames = new Map<String,String>();
//        for (Group grp : queueNameList) {
//            if (!queueNames.containsKey(grp.Id)) {
//                queueNames.put(grp.Id, grp.Name);
//            }
//        }
//        rulesWithQueues = new List<routingWrapper>();
//        for (SSSWRouting__c ssswRule: ssswR) {
//            if (String.isNotBlank(ssswRule.Queue_ID__c)) {
//                rulesWithQueues.add(new routingWrapper(queueNames.get(ssswRule.Queue_ID__c), ssswRule));
//            }
//        }

        //return rules;
    }

    public void getRoutings() {
        System.debug('Inside getRoutings');
        List<SSSWRouting__c> ssswR = getRules(SSSWConstants.RECTYPEROUTING);
        Integer lastIndex = 0;
        for (SSSWRouting__c s : ssswR) {
            if (s.Sequence__c != null && s.Sequence__c > lastIndex) {
                lastIndex = Integer.valueOf(s.Sequence__c);
            }
        }
        newSeqFrom = String.valueOf(lastIndex + 1);

        //Setup a wrapper of rules to queue names for the view.
        Set<String> queueIds = new Set<String>();
        for (SSSWRouting__c ssswrQId : ssswR) {
            queueIds.add(ssswrQId.Queue_ID__c);
        }
        List<Group> queueNameList = new List<Group>([select id, Name from Group where Id in:queueIds]);
        Map<String,String> queueNames = new Map<String,String>();
        for (Group grp : queueNameList) {
            if (!queueNames.containsKey(grp.Id)) {
                queueNames.put(grp.Id, grp.Name);
            }
        }
        rulesWithQueues = new List<routingWrapper>();
        for (SSSWRouting__c ssswRule: ssswR) {
            if (String.isNotBlank(ssswRule.Queue_ID__c)) {
                rulesWithQueues.add(new routingWrapper(queueNames.get(ssswRule.Queue_ID__c), ssswRule));
            }
        }
        selectedRecordType = 'SSSW Routing';
        System.debug('newSeqFrom--->'+newSeqFrom);
        System.debug('rulesWithQueues--->'+rulesWithQueues);
    }

    public void getUnifiedRoutingRules() {
        rulesForUnifiedCaseRouting = new List<routingWrapper>();
        List<SSSWRouting__c> unifiedrules = getRules(SSSWConstants.SSSWROUTING_RECTYPE_UNIFIEDROUTING);
        Set<Id> groupIds = new Set<Id>();
        for (SSSWRouting__c unifiedrule: unifiedrules) {
            if (String.isNotBlank(unifiedrule.Queue_ID__c)) {
                groupIds.add(unifiedrule.Queue_ID__c);
            }
        }

        Map<Id, Group> groups = ((GroupsSelector)GroupsSelector.newInstance().setFieldOverrides(new Set<SObjectField>{Group.Id, Group.Name})).selectById(groupIds);
        for (SSSWRouting__c unifiedrule: unifiedrules) {
            if (String.isNotBlank(unifiedrule.Queue_ID__c) && groups.containsKey(unifiedrule.Queue_ID__c)) {
                rulesForUnifiedCaseRouting.add(new routingWrapper(groups.get(unifiedrule.Queue_ID__c).Name, unifiedrule));
            }
        }
    }

    public void getNPS() {
        System.debug('Inside getNPS');
        rulesForNPS = new List<SSSWRouting__c>();
        List<SSSWRouting__c> ssswR = getRules(SSSWConstants.RECTYPENPS);
        Integer lastIndex = 0;
        for (SSSWRouting__c s : ssswR) {
            if (s.Sequence__c != null && s.Sequence__c > lastIndex) {
                lastIndex = Integer.valueOf(s.Sequence__c);
                rulesForNPS.add(s);
            }
        }
        newSeqFromNPS = String.valueOf(lastIndex + 1);
        System.debug('newSeqFromNPS--->'+newSeqFromNPS);
        System.debug('Inside rulesForNPS--->'+rulesForNPS);
    }

    public void getEscalate() {
        System.debug('Inside getEscalate');
        rulesForEscalate = new List<SSSWRouting__c>();
        List<SSSWRouting__c> ssswR = getRules(SSSWConstants.RECTYPEESCALATION);
        Integer lastIndex = 0;
        System.debug('ssswR--->'+ssswR);
        for (SSSWRouting__c s : ssswR) {
            if (s.Sequence__c != null && s.Sequence__c > lastIndex) {
                lastIndex = Integer.valueOf(s.Sequence__c);
                rulesForEscalate.add(s);
            }
        }
        newSeqFromEscalate = String.valueOf(lastIndex + 1);
        System.debug('newSeqFromEscalate--->'+newSeqFromEscalate);
        System.debug('Inside rulesForEscalate--->'+rulesForEscalate);
    }

    public void getDescription() {
        System.debug('Inside getDescription');
        rulesForDescription = new List<SSSWRouting__c>();
        List<SSSWRouting__c> ssswR = getRules(SSSWConstants.RECTYPEDESCRIPTION);
        Integer lastIndex = 0;
        System.debug('ssswR--->'+ssswR);
        for (SSSWRouting__c s : ssswR) {
            if (s.Sequence__c != null && s.Sequence__c > lastIndex) {
                lastIndex = Integer.valueOf(s.Sequence__c);
                rulesForDescription.add(s);
            }
        }
        newSeqFromDescription = String.valueOf(lastIndex + 1);
        System.debug('newSeqFromDescription--->'+newSeqFromDescription);
        System.debug('Inside rulesForDescription--->'+rulesForDescription);
    }


    //Wrapper class to house the rule and it's associalted Queue name
    private class routingWrapper {
        public String queueName { get; set; }
        public SSSWRouting__c rule { get; set; }

        public routingWrapper(String queueName, SSSWRouting__c rule) {
            this.queueName = queueName;
            this.rule = rule;
        }
    }


    public class RoutingRule {
        @AuraEnabled
        public Integer ruleIndex { get; set; }

        @AuraEnabled
        public SSSWRouting__c rule { get; set; }

        public RoutingRule(Integer ruleIndex, SSSWRouting__c rule) {
            this.ruleIndex = ruleIndex;
            this.rule = rule;
        }
    }

}