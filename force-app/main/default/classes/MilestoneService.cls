/**
 * @description Servive class for calculating the milestone violation date time based on the Entitlement Rules and Escalation_Hierarchy objects configuration
 * @author Mahesh Parvathaneni
 * @date 26/01/2023
 * @changelog
 * 2023-02-23	Mahesh Parvathaneni	- Changed logic to calculate the violation datetime based on hours
 */

public inherited sharing class MilestoneService {

	//constants
	private static final Set<String> STRING_TYPES = new Set<String>{'string', 'picklist', 'email', 'phone', 'textarea', 'multipicklist', 'reference', 'url', 'id'};
    private static final Set<String> NUMERIC_TYPES = new Set<String>{'double', 'currency'};
	private static final String SSSW_SYDNEY = 'SSSWSydney';
	private static Map<String, List<String>> ruleIdRuleUnitsMap;
	private static Map<Id, Entitlement_Rule__c> entitlementRuleMap;
	private static Map<String, String> ciFieldTypeMap;
	private static Id businessHourId;

	/**
	* Grabs a new instance of this class
	* Using Application.Utilities allows us to override this interface with a mock class for unit testing
	*/
	public static MilestoneService getInstance() {
		return (MilestoneService)Application.Utilities.getInstance(MilestoneService.class);
	}

	//get the map of entitlement rule ids to rule units
	@TestVisible
	private static Map<String, List<String>> getActiveEntitlementRuleUnitByRecordType(String recTypeDevName) {
		if (ruleIdRuleUnitsMap == null) {
			ruleIdRuleUnitsMap = new Map<String, List<String>>();
			for (Entitlement_Rule__c er : entitlementRuleMap.values()) {
				ruleIdRuleUnitsMap.put(er.Id, er.Rule__c.split('\\|\\|'));
			}
		}
		return ruleIdRuleUnitsMap;
	}

	//get the map of active entitlement rules based on the record type
	@TestVisible
	private static Map<Id, Entitlement_Rule__c> getActiveEntitlementRulesByRecordType(String recTypeDevName) {
		if (entitlementRuleMap == null) {
			entitlementRuleMap = EntitlementRulesSelector.newInstance().selectActiveRulesByRecordTypeDevNames(new Set<String>{recTypeDevName}, new Set<Object>{EntitlementRulesSelector.Options.WITH_ESCALATION_HIERARCHY});
		}
		return entitlementRuleMap;
	}

	//get the field type map for case investigation
	private static Map<String, String> getCaseInvestigationFieldTypeMap(Set<String> entitlementRuleFields) {
		if (ciFieldTypeMap == null) {
			ciFieldTypeMap = new Map<String, String>();

			//Get the map of field tokens for SObject. Then do field describes selectively only for those fields
			//referenced in active entitlement rules.
			Map<String, Schema.SObjectField> allCaseInvestigationFieldsMap = Schema.SObjectType.CaseInvestigation__c.fields.getMap();

			//Fields to select from  SObject.
			for (String fieldName : entitlementRuleFields) {
				//Check if fieldName is a valid field on SObject. Only do field describes
				//for valid fields referenced in active rules.
				if (allCaseInvestigationFieldsMap.containsKey(fieldName)) {
					Schema.SObjectField field = allCaseInvestigationFieldsMap.get(fieldName);
					Schema.DescribeFieldResult fieldResult = field.getDescribe();
					String fieldType = String.valueOf(fieldResult.getType()).toLowerCase();
					ciFieldTypeMap.put(fieldName, fieldType);
				}
			}
		}
		return ciFieldTypeMap;
	}

	//get the business for the SSSWSydney
	private static Id getSSSWSydneyBusinessHour(){
        if(businessHourId == null){
            businessHourId = BusinessHoursSelector.newInstance().selectByName(new Set<String> {'SSSWSydney'})[0].Id;
        }
        return businessHourId;
    }

	/**
	 * This method calculates and returns the next violation date based on the matching entitlement rules configured passed records for CaseInvestigation SobjectType
	 * @param recIds Ids of records to be processed
	 * @param entitlementRuleRecTypeDevName Record type developer name for the EntitlementRule
	 * @param milestoneTierType Milestone tier type represented by the fields on the Entitlement Hierarchy
	 */
	public Map<Id, Datetime> calculateNextViolationDateForCaseInvestigation(Set<Id> recIds, String entitlementRuleRecTypeDevName, String milestoneTierType) {
		Map<Id, Datetime> violationDatetimeResult = new Map<Id, Datetime>();
		Map<Id, CaseInvestigation__c> caseInvestigations;

		//get active entitlement rules configured in Entitlement_Rule__c object based on the record type
		entitlementRuleMap = getActiveEntitlementRulesByRecordType(entitlementRuleRecTypeDevName);
        ruleIdRuleUnitsMap = getActiveEntitlementRuleUnitByRecordType(entitlementRuleRecTypeDevName);

		//determine the distinct fields referenced in active entitlement rules
        Set<String> entitlementRuleFields = getFieldsReferencedInEntitlementRules(ruleIdRuleUnitsMap);

		//get the case investigation records
		if (recIds.size() > 0) {
			caseInvestigations = CaseInvestigationsSelector.newInstance().selectById(recIds);
		}

		//Field Types map for fields referenced in entitlement rules
        //key = field name, value = field type
        ciFieldTypeMap = getCaseInvestigationFieldTypeMap(entitlementRuleFields);

		//map to store the case investigation to the matching entitlement rule
		Map<Id, String> ciEntitlementRuleMatchingMap = getMatchingEntitlementRule(caseInvestigations);

		if (ciEntitlementRuleMatchingMap.size() > 0) {
			violationDatetimeResult = getViolationDatetime(ciEntitlementRuleMatchingMap, caseInvestigations, milestoneTierType);
		}

		return violationDatetimeResult;
	}

	/**
     * Determine the set of fields referenced in active entitlement rules passed in.
     * @param entitlementRules Entitlement rule units by rule id.
     * @return a Set of field names referenced in entitlement rules.
     */
    @TestVisible
    private Set<String> getFieldsReferencedInEntitlementRules(Map<String, List<String>> ruleIdRuleUnitsMap) {

        Set<String> fieldNames = new Set<String>();
		fieldNames.add('id');

        for (List<String> ruleUnits: ruleIdRuleUnitsMap.values()) {
            for (String ruleUnit : ruleUnits) {
                if (ruleUnit.contains('=') || ruleUnit.contains('<') || ruleUnit.contains('>')) {
                    String fieldName = ruleUnit.split('[=<>]')[0];
                    fieldNames.add(fieldName.toLowerCase().trim());
                }
            }
        }

        return fieldNames;
    }

	@TestVisible
	private Map<Id, String> getMatchingEntitlementRule(Map<Id, CaseInvestigation__c> caseInvestigations) {
		Map<Id, String> ciEntitlementRuleMatchingMap = new Map<Id, String>();

		//loop through case investigations
		for (CaseInvestigation__c ci : caseInvestigations.values()) {
			Map<String, Integer> ruleIDUnitFullyMatched = new  Map<String, Integer>();

			//loop through the rule units of entitlement rule records
			for (String ruleID : ruleIdRuleUnitsMap.keyset()) {
				List<String> ruleUnits = ruleIdRuleUnitsMap.get(ruleID);

				Integer ruleUnitCounter = ruleUnits.size();
				Integer ruleUnitMatched = 0;

				for (String aUnit : ruleUnits) {
					String fieldName;
					String fieldType;
					String value;
					Boolean isMatched = false;
					if (aUnit.contains('=')) {
						fieldName = aUnit.split('=')[0];
						value = aUnit.split('=')[1];

						if (ciFieldTypeMap.containsKey(fieldName)) {

							fieldType = ciFieldTypeMap.get(fieldName);
							if (STRING_TYPES.contains(fieldType)) {
								isMatched = ci.get(fieldName) == value;
							} else if (NUMERIC_TYPES.contains(fieldType)) {
								isMatched = (Double)ci.get(fieldName) == Double.valueOf(value);
							} else if (fieldType == 'boolean') {
								isMatched = (Boolean)ci.get(fieldName) == stringToBoolean(value);
							} else if (fieldType == 'date') {
								isMatched = (Date)ci.get(fieldName) == stringToDate(value);
							} else if (fieldType == 'datetime') {
								isMatched = (Datetime)ci.get(fieldName) == stringToDatetime(value);
							}
						} else {
							//field not found, go to the next rule
							break;
						}
					}

					if (isMatched) {
						ruleUnitMatched++;
					}
				}

				//All rule units are matched only
				if (ruleUnitCounter == ruleUnitMatched) {
					ruleIDUnitFullyMatched.put(ruleID,ruleUnitMatched);
				}
			}

			String ruleID = '';
			Integer maxRuleUnitMatched=0;

			//if full match is found
			if (ruleIDUnitFullyMatched.size() > 0){
					//get maximum ruleUnitMatched
				for (String s:ruleIDUnitFullyMatched.keyset()) {
					if (ruleIDUnitFullyMatched.get(s) > maxRuleUnitMatched) {
						maxRuleUnitMatched = ruleIDUnitFullyMatched.get(s);
						ruleID = s;
					}
				}
			}

			if (ruleID != '') {
				ciEntitlementRuleMatchingMap.put(ci.Id, ruleID);
			}
		}

		return ciEntitlementRuleMatchingMap;
	}

	// convert string (MM-dd-yyyy) to date
	@TestVisible
	private Date stringToDate(String strDate) {
		Date tempDate = null;
		if (strDate != '' && strDate != null) {
			try {
				String[] dtPart = strDate.split('-');
				if (dtPart.size() == 3) {
					tempDate = Date.valueOf(dtPart[2]+'-'+dtPart[0]+'-'+dtPart[1] + ' 00:00:00');
				}
			} catch (Exception e) {
				return null;
			}
		}
		return tempDate;
	}

	// convert string (MM-dd-yyyy hh:mm a) to datetime
	@TestVisible
	private Datetime stringToDatetime(String strDatetime) {
		Datetime tempDatetime = null;
		if (strDatetime != '' && strDatetime != null) {
			try {
				String[] dtPart = strDatetime.split('-');
				if (dtPart.size() == 3) {
					tempDatetime = Datetime.valueOf(dtPart[2].left(4)+'-'+dtPart[0]+'-'+dtPart[1] + ' ' + dtPart[2].substring(5,10) + ':00');
				}
			} catch (Exception e) {
				return null;
			}
		}
		return tempDatetime;
	}

	// convert string to Boolean
	@TestVisible
	private Boolean stringToBoolean(String yesNo) {
        return yesNo.toLowerCase() == 'yes';
    }

	/**
	 * function that sets the next violation date based on the configuration from Escalation Hierarchy
	 * checks the calculated date time falls within business hours or not
	 */
	@TestVisible
	private Map<Id, Datetime> getViolationDatetime(Map<Id, String> ciEntitlementRuleMatchingMap, Map<Id, CaseInvestigation__c> caseInvestigations, String milestoneTierType) {
		Map<Id, Datetime> result = new Map<Id, Datetime>();

		for (CaseInvestigation__c ci : caseInvestigations.values()) {
			if (ciEntitlementRuleMatchingMap.containsKey(ci.Id)) {
				Datetime violationDatetime;
				String formattedMilestoneTierTypeField;
				Entitlement_Rule__c er = entitlementRuleMap.get(ciEntitlementRuleMatchingMap.get(ci.Id));
				Escalation_Hierarchy__c eh = er.Escalation_Hierarchy__r;
				formattedMilestoneTierTypeField = milestoneTierType + '_' + String.valueOf(ci.NetworkMilestoneCurrentTier__c.intValue()) + '__c';

				//checks the tier has value in escalation hierarchy config
				if (eh.get(formattedMilestoneTierTypeField) != null) {
					Integer configuredMins = Integer.valueOf(eh.get(formattedMilestoneTierTypeField));
					Integer hours = configuredMins/60 ;
					if (ci.NetworkMilestoneNextViolationDatetime__c == null && ci.MilestoneTimeStartDatetime__c != null) {
						//Check if new date is within working days
						violationDatetime = checkWithinBusinessHours(ci.MilestoneTimeStartDatetime__c, hours);
					} else {
						//Check if new date is within working days
						violationDatetime = checkWithinBusinessHours(ci.NetworkMilestoneNextViolationDatetime__c, hours);
					}
					result.put(ci.Id, violationDatetime);
				}
			}
		}

		return result;
	}

	//function to check the target date is within business hours
	private Datetime checkWithinBusinessHours(Datetime violationDatetime, Integer hours) {
		Integer hour = violationDatetime.hour();
		Integer minute = violationDatetime.minute();
		Integer second = violationDatetime.second();

		for (Integer elapsed = 0; elapsed < hours; elapsed++) {
			//Add 1 hour
			violationDatetime = violationDatetime.addHours(1);

			//check if new date is within business hours
			if (!BusinessHours.isWithin(getSSSWSydneyBusinessHour(), violationDatetime)) {
				//If new date is not within working days, get new working day
				violationDatetime = BusinessHours.nextStartDate(getSSSWSydneyBusinessHour(), violationDatetime);
			}	
		}

		violationDatetime = Datetime.newInstance(violationDatetime.year(), violationDatetime.month(), violationDatetime.day(), hour, minute, second);
		return violationDatetime;
	}

	//function to return the business hours diff in minutes by using BusinessHours class
	public Decimal getBusinessHoursDiffInMinutes(String businessHourId, Datetime startTime, Datetime endTime) {
		Long diffInMilliSeconds = BusinessHours.diff(businessHourId, startTime, endTime);
		return ((diffInMilliSeconds/1000)/60); //convert to minutes
	}
}