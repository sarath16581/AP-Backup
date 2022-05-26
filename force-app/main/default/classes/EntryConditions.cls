/***
 * @author Ken McGuire
 * @date 2022-04-26
 * @description Determines whether the record values of a specified SObject meets a collection of entry criteria.
 * @changelog
 */
public inherited sharing class EntryConditions {

	/*
	 * Creates a new instance of the utility to facilitate dependency injection for mocking
	 * @return the new instance
	 */
	public static EntryConditions getInstance() {
		return (EntryConditions) Application.Utilities.getInstance(EntryConditions.class);
	}

	// String literal for the "Any" condition (see conditionRquirements below)
	private static final String ANY_REQUIRED = 'Any';
    // String literal for comparison types
    private static final String CONTAINS = 'contains';
    private static final String NOT_CONTAINS = 'notContains';
    
    // Maps a specified conditions Name to Entry Conditions 
    // (example a particular survey to its entry conditions)
    private Map<String,Conditions> entryConditionsMap {
        get {
            if (entryConditionsMap == null) entryConditionsMap = new Map<String,Conditions>();
            return entryConditionsMap;
        }
        set;
    }
    
	/*
	 * specifies the condition requirements and builds the entry conditions that are to be used 
	 * @param Name A referece to the entity these conditions relate to (example, a particular survey name)
	 * @param entryConditionsFieldValueMap Maps a Field Name to the requisite Value(s) which can be either a String or a List<String>
	 * @param conditionRequirements contains either "Any" or "All" to specify how the conditions are evaluated. 
	 */
	public void createEntryConditions(String name, Map<String, Object> entryConditionsFieldValueMap, String conditionRequirements) {
		if (!isCreated(name)) entryConditionsMap.put(name, new Conditions(entryConditionsFieldValueMap,conditionRequirements));
	}
    
    public Boolean meetsEntryConditions(String name, SObject record) {
        if (!hasEntryConditions(name)) return false;
        return entryConditionsMap.get(name).meetsEntryConditions(record);
    }
    
    public Boolean isCreated(String name) {
        return entryConditionsMap.containsKey(name);
    }
    
    public Boolean hasEntryConditions(String name) {
        if (!isCreated(name)) return false;
        return entryConditionsMap.get(name).hasEntryConditions();            
    }
    

    /*========================================================================================
     * Conditions subclass
     * ========================================================================================*
     
	/*
	 * A data structure used to evaluate a collection of entry conditions agaist an SObject
	*/
    
    public class Conditions {
       	// determins whether any or all conditions must be met. Contains the value "Any" or "All"
		private String conditionRequirements; 
        // The list of conditions that must be met for the entry to be succesful
		private List<Condition> entryConditions;
        // Constructor
        public Conditions(Map<String, Object> entryConditionsFieldValueMap, String conditionRequirements) {
        	this.conditionRequirements = conditionRequirements;
			entryConditions = new List<Condition>();
            for (String currentConditionType : entryConditionsFieldValueMap.keySet()) {
                Object value = entryConditionsFieldValueMap.get(currentConditionType);
                if (value instanceOf Map<String,Object>) {
                    // Conditon type is a comparison : Map of field-value set
                	addEntryConditions((Map<String,Object>)value, currentConditionType); 
                }
                // Conditon type is a field-value set
                else entryConditions.add(new Condition(currentConditionType, entryConditionsFieldValueMap.get(currentConditionType)));
            }
        }
        /*
        * Appends a list of Conditions from a Map of fields and their requisite values.
        * @param entryConditionsFieldValueMap Maps a Field Name to the desired Value(s) which can be either a String or a List<String>
        */
        private void addEntryConditions(Map<String, Object> entryConditionsFieldValueMap, string comparison) {
            for (String currentFieldName : entryConditionsFieldValueMap.keySet()) {
                entryConditions.add(new Condition(currentFieldName, entryConditionsFieldValueMap.get(currentFieldName),comparison));
            }
        }
        
		/*
         * Determines whether the values of an SOBject record meet the entry criteria.
         * @param record the SObject record to test against the entry criteria
         * @return true if the entry criteria are met, otherwise false.
         */
        public Boolean meetsEntryConditions(SObject record) {
            Boolean anyRequired = conditionRequirements == ANY_REQUIRED;
            for (Condition currentCondition : entryConditions) {
                
                if (currentCondition.isMet(record) == anyRequired) {
                    return anyRequired;
                }
            }
            return !anyRequired;
        }
    
        /*
         * Determines whether the entry conditions have any entry criteria.
         * @return true if the entry conditions has beeen loaded with entry critera.
         */
        public Boolean hasEntryConditions() {
            if (entryConditions == null) return false;
            return entryConditions.size() >0;  
        }
    }
    
    
   	/*========================================================================================
     * Condition subclass
     * ========================================================================================*/

	/*
	 * A data structure used to evaluate an entry condition agaist a field value
	 */
	public class Condition {

		// The name of the field to test against specified values
		private String fieldName { get; set; }
        
        private String comparison {get; set;}

		// a list of requeiste values that the field is tested against
		private List<String> fieldValues { get; set; }

		// Constructors
        public Condition (String name, Object values, String comparison) {

            this.comparison = comparison;
            fieldName = name;
            setFieldValues(values);
        }
		public Condition(String name, Object values) {

			fieldName = name;
			setFieldValues(values);

		}
       
       /*
		* sets the requred value(s) that the field is tested against
		* @param values either a string  or a List<string>
		*/
        private void setFieldValues(Object values) {
        	if (values instanceof List<Object>) {
                
                fieldValues = new List<String>();
                for (Object currentItem :(List<Object>) values) fieldValues.add((String)currentItem);
                
            }
            else {
                
                fieldValues = new List<String>{(String) values};
                    
            }  
        }
		
		/*
		* Determines if a record field meets the requisite condition.
		* @param condition the Condition under test
		* @param record the SObject data record being tested against the requisite value(s)
		*/
		public Boolean isMet(SObject record) {

            string fieldValue = String.valueOf(record.get(fieldName));
            if (fieldValue == null) fieldValue = 'null';
            
            if (comparison == CONTAINS) {
                return isMetOnContains(fieldValue);
            }
            else if (comparison == NOT_CONTAINS) {
                return !isMetOnContains(fieldValue);
            }
            else return isMetOnEquality(fieldValue);
		
        }
        /*
		* Determines if a record field meets the requisite condition for "Equals".
		* @param value the value under test
		*/
        private Boolean isMetOnEquality (string value) {

            return fieldValues.contains(value);
        }
        /*
		* Determines if a record field meets the requisite condition for "contains" or "notContains".
		* @param value the value under test
		* @param isContains whether the value under test should be contained or not contained by the field values
		*/
        private Boolean isMetOnContains(String value) {
            for (String currentValue : fieldValues) {

                if (value.contains(currentValue)) {
                    return true;
                }
            }
            return false;
        }
	}
}