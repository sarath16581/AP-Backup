/**
// christopher.henschke@auspost.com.au 17/Aug/2015 - updated error in logic for network milestones where an auto escalation
//                                                   appears to occur at Network Tier 4 regardless if there is an email in 
//                                                   Network Email 3 or not
* 2020-08-19 - Ranjeewa Silva      - Optimised the SOQL in calculateMilestoneTriggerTime method to only select Case fields
*                                    referenced in active entitlement rules.
*/
public without sharing class CalculateMilestoneTime implements Support.MilestoneTriggerTimeCalculator {
    
    
    /*two matching logic: 
    1. if multipal full match found, use the rule has most units: for example, we have two entitlement rules,
       a. case type=customer complint AND case status= open
       b. case type=customer complint AND case status= open AND case priority = high
    
       then rule b wins (we need use rule b), because rule b has more "units" than rule a
       
    2. if no full match found, but partial match is found, then use the rule has most units: for example, we have two entitlement rules,
       a. case type=customer complint AND case status= open
       b. case type=customer complint AND case priority = high AND case created date >1/1/2014
    
       the case does not FULLY match any of rules, in fact, the case matches case status for rule 1 ; matches case priority and case created date for rule 2. 
       then rule 2 wins, cause it has more units match the case
    */
    //public static boolean updateFacilityTierEmail;
    public Integer calculateMilestoneTriggerTime(String caseId, String milestoneTypeId){
        system.debug('Case id = ' + caseId + ', milestoneTypeId = ' + milestoneTypeId);
        Set<String> stringTypes = new Set<String>{'string', 'picklist', 'email', 'phone', 'textarea', 'multipicklist', 'reference', 'url', 'id'};
        Set<String> numericTypes = new Set<String>{'double', 'currency'};

        //Retrieve active entitlement rules configured in Entitlement_Rule__c object
        Map<String, List<String>> ruleIDRuleUnits = CaseMileStoneUtil.ruleIDRuleUnits;

        if (ruleIDRuleUnits.isEmpty()) {
            //No need to do additional processing, if no active entitlement rules are found
            //Simply return the default value.
            return 1;
        }

        //Determine the distinct fields referenced in active entitlement rules
        Set<String> entitlementRuleFields = getFieldsReferencedInEntitlementRules(ruleIDRuleUnits);
                       
        //Get the map of field tokens for Case object. Then do field describes selectively only for those fields
        //referenced in active entitlement rules.
        Map<String, Schema.SObjectField> allCaseFieldsMap = Schema.SObjectType.Case.fields.getMap();

        //Field Types map for fields referenced in entitlement rules
        //key = field name, value = field type
        Map<String, String> fieldTypeMap = new Map<String, String>();

        //Fields to select from Case object.
        String fieldset = '';
        for (String fieldName : entitlementRuleFields) {
            //Check if fieldName is a valid field on Case object. Only do field describes
            //for valid fields referenced in active rules.
            if (allCaseFieldsMap.containsKey(fieldName)) {
                fieldset += ', ' + fieldName;
                Schema.SObjectField field = allCaseFieldsMap.get(fieldName);
                Schema.DescribeFieldResult fieldResult = field.getDescribe();
                String fieldType = String.valueOf(fieldResult.getType()).toLowerCase();
                fieldTypeMap.put(fieldName, fieldType);
            }
        }
        
        String query = 'Select ' + fieldset.substring(1) + ' From Case where Id = \'' + caseId + '\'';
        System.debug('query: ' + query);
        Case aCase = database.query(query);
       
        EntitlementRuleEditExtController eRuleCtrl = new EntitlementRuleEditExtController();  
        
        Map<String, Integer> ruleIDUnitFullyMatched = New  Map<String, Integer>();
        Map<String, Integer> ruleIDUnitPartiallyMatched = New  Map<String, Integer>();
            
        for (String ruleID : ruleIDRuleUnits.keyset()) {            
            List<String> ruleUnits = ruleIDRuleUnits.get(ruleID);
            
            integer ruleUnitCounter = ruleUnits.size();
            integer ruleUnitMatched = 0;                    
                
            for (String aUnit : ruleUnits) {
                String fieldName, fieldType, value;
                Boolean isMatched = false;  
                System.debug('XXXBWXXX:RuleUnit:' + aUnit);
                if (aUnit.contains('=')) {
                    fieldName = aUnit.split('=')[0];
                    value = aUnit.split('=')[1];
                    System.debug('XXXBWXXX:RuleFieldName:' + fieldName);
                    System.debug('XXXBWXXX:RuleValue:' + value);
                    System.debug('XXXBWXXX:CaseValue:' + aCase.get(fieldName));

                    if (fieldTypeMap.containsKey(fieldName)) {
                        fieldType = fieldTypeMap.get(fieldName);                
                        if (stringTypes.contains(fieldType)) {
                            isMatched = aCase.get(fieldName) == value;  
                        } else if (numericTypes.contains(fieldType)) {
                            isMatched = (Double)aCase.get(fieldName) == Double.valueOf(value);
                        } else if (fieldType == 'boolean') {
                            isMatched = (Boolean)aCase.get(fieldName) == stringToBoolean(value);
                        } else if (fieldType == 'date') {
                            isMatched = (Date)aCase.get(fieldName) == eRuleCtrl.stringToDate(value);                        
                        } else if (fieldType == 'datetime') {
                            isMatched = (Datetime)aCase.get(fieldName) == eRuleCtrl.stringToDatetime(value);
                        }                                          
                    }
                } else if (aUnit.contains('<>')) {
                    fieldName = aUnit.split('<>')[0];
                    value = aUnit.split('<>')[1];
                    
                    if (fieldTypeMap.containsKey(fieldName)) {
                        fieldType = fieldTypeMap.get(fieldName);                
                        if (stringTypes.contains(fieldType)) {
                            isMatched = aCase.get(fieldName) <> value;  
                        } else if (numericTypes.contains(fieldType)) {
                            isMatched = (Double)aCase.get(fieldName) <> Double.valueOf(value);
                        } else if (fieldType == 'boolean') {
                            isMatched = (Boolean)aCase.get(fieldName) <> stringToBoolean(value);
                        } else if (fieldType == 'date') {
                            isMatched = (Date)aCase.get(fieldName) <> eRuleCtrl.stringToDate(value);                        
                        } else if (fieldType == 'datetime') {
                            isMatched = (Datetime)aCase.get(fieldName) <> eRuleCtrl.stringToDatetime(value);
                        }                                          
                    }                   
                } else if (aUnit.contains('>')) {
                    fieldName = aUnit.split('>')[0];
                    value = aUnit.split('>')[1];
                    
                    if (fieldTypeMap.containsKey(fieldName)) {
                        fieldType = fieldTypeMap.get(fieldName);                
                        if (numericTypes.contains(fieldType)) {
                            isMatched = (Double)aCase.get(fieldName) > Double.valueOf(value);                       
                        } else if (fieldType == 'date') {
                            isMatched = (Date)aCase.get(fieldName) > eRuleCtrl.stringToDate(value);                     
                        } else if (fieldType == 'datetime') {
                            isMatched = (Datetime)aCase.get(fieldName) > eRuleCtrl.stringToDatetime(value);
                        }                                          
                    }                   
                } else if (aUnit.contains('<')) {
                    fieldName = aUnit.split('<')[0];
                    value = aUnit.split('<')[1];
                    
                    if (fieldTypeMap.containsKey(fieldName)) {
                        fieldType = fieldTypeMap.get(fieldName);                
                        if (numericTypes.contains(fieldType)) {
                            isMatched = (Double)aCase.get(fieldName) < Double.valueOf(value);                       
                        } else if (fieldType == 'date') {
                            isMatched = (Date)aCase.get(fieldName) < eRuleCtrl.stringToDate(value);                     
                        } else if (fieldType == 'datetime') {
                            isMatched = (Datetime)aCase.get(fieldName) < eRuleCtrl.stringToDatetime(value);
                        }                                          
                    }                   
                }
                
                if (isMatched) {
                    System.debug('XXXBWXXX:MATCHFOUND');
                    System.debug('XXXBWXXX:fieldName:' + fieldName);
                    System.debug('XXXBWXXX:value:' + value);
                    ruleUnitMatched++;
                }
            }
                
            //All rule units are matched only
            if (ruleUnitCounter == ruleUnitMatched) {
                ruleIDUnitFullyMatched.put(ruleID,ruleUnitMatched);
            }
            
            //Partially matched
            if (ruleUnitMatched > 0 && ruleUnitCounter > ruleUnitMatched) {
                ruleIDUnitPartiallyMatched.put(ruleID,ruleUnitMatched);
            }
            
        }
            
        String ruleID = '';
        integer MaxRuleUnitMatched=0;
        
        System.debug('XXXBWXXX:FullyMatchedRules:' + ruleIDUnitFullyMatched);
        //if full match is found
        if (ruleIDUnitFullyMatched.size() > 0){
             //get maximum ruleUnitMatched
            for (String s:ruleIDUnitFullyMatched.keyset()) {                    
                if (ruleIDUnitFullyMatched.get(s) > MaxRuleUnitMatched) {
                    MaxRuleUnitMatched = ruleIDUnitFullyMatched.get(s);
                    ruleID = s;
                    System.debug('XXXBWXXX:MaxRuleUnitMatched:' + MaxRuleUnitMatched);
                    System.debug('XXXBWXXX:ruleID:' + ruleID);
                }
            }
        }
        //handle partial match
        else if(ruleIDUnitPartiallyMatched.size() >0){
            
            //reset MaxRuleUnitMatched
            MaxRuleUnitMatched=0;
            list<string> ruleIDs = new list<string>();
            //get max fields matched
            for (String s:ruleIDUnitPartiallyMatched.keyset()) {                    
                if (ruleIDUnitPartiallyMatched.get(s) > MaxRuleUnitMatched) {
                    MaxRuleUnitMatched = ruleIDUnitPartiallyMatched.get(s);
                    ruleID = s;
                }
            }
            //get rule has max fields matched
            for (String s:ruleIDUnitPartiallyMatched.keyset()) {                    
                if (ruleIDUnitPartiallyMatched.get(s) == MaxRuleUnitMatched) {
                    ruleIDs.add(s);
                }
            }
            //find the oldest rule
            List<Entitlement_Rule__c> er=[Select id From Entitlement_Rule__c Where id=:ruleIDs order by createddate limit 2];
            if(er.size() > 0) {
                ruleID = er[0].id;
            }
        }
         
        system.debug('################=============================> ruleID = '+ ruleID);
        integer result = 1;
        
        if (ruleID != '') {
            integer targetTime = returnTargerTime(ruleID, milestoneTypeId, caseID);
            if(targetTime != null)
                result = targetTime;
        }
        
        system.debug('############################## last warning: SOQL Limits at: ' + Limits.getQueries());   
        system.debug('result for calculateMilestoneTriggerTime = ' + result);
        return result;
    }   
        
    private Integer returnTargerTime (string ruleID, string milestoneTypeId,string caseID){
         //now we have entitlement rule ID, run query to get SLA mins
            Entitlement_Rule__c er = CaseMileStoneUtil.cachedEntitlementRules.get(ruleId); // [Select Escalation_Hierarchy__c From Entitlement_Rule__c Where id=:ruleID];
            Escalation_Hierarchy__c SLA = CaseMileStoneUtil.cachedEscalationHierarchies.get(er.Escalation_Hierarchy__c); // [Select Internal_Tier_1__c, Internal_Tier_3__c, Internal_Tier_2__c ,Facility_Tier_4__c,Facility_Tier_5__c,Facility_Tier_3__c, Facility_Tier_2__c, Facility_Tier_1__c, Customer_Tier_3__c, Customer_Tier_2__c, Customer_Tier_1__c From Escalation_Hierarchy__c Where id=:er.Escalation_Hierarchy__c];
                    
         //check milestone name to decide which tire should be used
            Integer targetTime;
            
            MileStoneType cms = CaseMileStoneUtil.cachedMileStoneTypes.get(milestoneTypeId);  
            
            //customers
            if(cms.name.contains('Customer') && cms.name.contains('1')){
                targetTime=Integer.valueof(SLA.customer_tier_1__c);
            }
            if(cms.name.contains('Customer') && cms.name.contains('2')){
                targetTime=Integer.valueof(SLA.customer_tier_2__c);
            }
            if(cms.name.contains('Customer') && cms.name.contains('3')){
                targetTime=Integer.valueof(SLA.customer_tier_3__c);
            }
            
            // facilities
            if(cms.name.contains('Network') && cms.name.contains('1')){
                Case c=[select Network__c,Facility_Tier_Escalation_Email__c from case where id=:caseID];
                Network__c fe = New Network__c();
                if(c.Network__c<>null){
                 fe = [select email_1__c,email_2__c,email_3__c,email_4__c,email_5__c from Network__c where id=:c.Network__c];  
                    targetTime=Integer.valueof(SLA.Facility_tier_1__c);
                }
                
            }
            if(cms.name.contains('Network') && cms.name.contains('2')){
                Case c=[select Network__c,Facility_Tier_Escalation_Email__c from case where id=:caseID];
                Network__c fe = New Network__c();
                if(c.Network__c<>null){
                 fe = [select email_1__c,email_2__c,email_3__c,email_4__c,email_5__c from Network__c where id=:c.Network__c];  
                 if (fe.Email_2__c==null && fe.Email_1__c==null){
                    targetTime=1;
                 }   
                 else{
                    targetTime=Integer.valueof(SLA.Facility_tier_2__c);
                 }
                }
            }
            if(cms.name.contains('Network') && cms.name.contains('3')){
                Case c=[select Network__c,Facility_Tier_Escalation_Email__c from case where id=:caseID];
                Network__c fe = New Network__c();
                if(c.Network__c<>null){
                 fe = [select email_1__c,email_2__c,email_3__c,email_4__c,email_5__c from Network__c where id=:c.Network__c];  
                 if (fe.Email_3__c==null && fe.Email_2__c==null){
                    targetTime=1;
                 }   
                 else{
                    targetTime=Integer.valueof(SLA.Facility_tier_3__c);
                 }
                }
            }
            if(cms.name.contains('Network') && cms.name.contains('4')){
                Case c=[select Network__c,Facility_Tier_Escalation_Email__c from case where id=:caseID];
                Network__c fe = New Network__c();
                if(c.Network__c<>null){
                 fe = [select email_1__c,email_2__c,email_3__c,email_4__c,email_5__c from Network__c where id=:c.Network__c];  
                // if (fe.Email_4__c==null && fe.Email_5__c==null){
                 if (fe.Email_4__c==null && fe.Email_3__c==null){
                    targetTime=1;
                 }   
                 else{
                    targetTime=Integer.valueof(SLA.Facility_tier_4__c);
                 }
                }
            }
            if(cms.name.contains('Network') && cms.name.contains('5')){
                Case c=[select Network__c,Facility_Tier_Escalation_Email__c from case where id=:caseID];
                Network__c fe = New Network__c();
                if(c.Network__c<>null){
                 fe = [select email_1__c,email_2__c,email_3__c,email_4__c,email_5__c from Network__c where id=:c.Network__c];  
                 if (fe.Email_5__c==null && fe.Email_4__c==null){
                    targetTime=1;
                 }   
                 else{
                    targetTime=Integer.valueof(SLA.Facility_tier_5__c);
                 }
                }
            }
            
            //Internal
            if(cms.name.contains('Internal') && cms.name.contains('1')){
                targetTime=Integer.valueof(SLA.Internal_tier_1__c);
            }
            if(cms.name.contains('Internal') && cms.name.contains('2')){
                Case c=[select ownerid,Internal_Tier_Escalation_Email__c from case where id=:caseID];
                List<User> users=[Select Manager.Manager.Email,Manager.Email, email,id From User where id =:c.ownerid limit 2];
                if(users.size() > 0) {
                    if(users[0].Manager.Email<>null){
                        //if manager.email is not null
                        targetTime=Integer.valueof(SLA.Internal_tier_2__c);
                        
                    }
                    else{
                        //if manager.email is null, then return 1 min
                        targetTime=1;
                    }
                }
            }
            if(cms.name.contains('Internal') && cms.name.contains('3')){           
                Case c=[select ownerid,Internal_Tier_Escalation_Email__c from case where id=:caseID];
                List<User> users=[Select Manager.Manager.Email,Manager.Email, email,id From User where id =:c.ownerid limit 2];
                if(users.size() > 0) {
                    if(users[0].Manager.Manager.Email<>null){
                        targetTime=Integer.valueof(SLA.Internal_tier_3__c);
                       
                    }
                    else{
                        targetTime=1;
                    }
                }
            }           
            
         system.debug('>>>>>>>>>>>>>>>>>>>>> targetTime = ' + targetTime);
         return targetTime;
    }
           
    private Boolean stringToBoolean(String yesNo) {
        return yesNo.toLowerCase() == 'yes'; 
    }

    /**
     * Determine the set of fields referenced in active entitlement rules passed in.
     * Includes id field by default.
     *
     * @param entitlementRules Entitlement rule units by rule id.
     * @return a Set of field names referenced in entitlement rules.
     */
    @TestVisible
    private Set<String> getFieldsReferencedInEntitlementRules(Map<String, List<String>> entitlementRules) {

        Set<String> fieldNames = new Set<String>();
        fieldNames.add('id');

        for (List<String> ruleUnits: entitlementRules.values()) {
            for (String ruleUnit : ruleUnits) {
                if (ruleUnit.contains('=') || ruleUnit.contains('<') || ruleUnit.contains('>')) {
                    String fieldName = ruleUnit.split('[=<>]')[0];
                    fieldNames.add(fieldName.toLowerCase().trim());
                }
            }
        }

        return fieldNames;
    }

}