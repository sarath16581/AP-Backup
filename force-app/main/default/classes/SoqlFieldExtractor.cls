/***
 * @description Extract fields and relationships from a SOQL string
 *
 * NOTE: This is only a basic implementation that focuses on identifying the fields accessed during a SOQL query
 *
 * @author Nathan Franklin
 * @date 2021-03-01
 * @group Integration
 * @changelog
 */
public inherited sharing class SoqlFieldExtractor {

	private enum FieldRetrieveTypeEnum {
		ALL,
		CUSTOM,
		STANDARD
	}

	// store a transactional cache of the describe
	private static Map<String, Schema.DescribeSObjectResult> describeCache = new Map<String, Schema.DescribeSObjectResult>();
	private static Map<SObjectField, DescribeFieldResult> describeFieldCache = new Map<SObjectField, DescribeFieldResult>();

	private String soql;
	private String parentSObjectName = '';

	// Stores a copy of the original soql for any additional analysis
	public String originalSoql { get; private set; }

	// Stores the primary sobject found in the 'From [object name]'
	public String primarySObjectName { get; private set; }

	public FieldResults parsedFieldUsage { get; private set; }

	public SoqlFieldExtractor(String soql) {
		this.soql = soql;
		this.originalSoql = soql;
		this.parsedFieldUsage = new FieldResults();

		parse();
	}

	private SoqlFieldExtractor(String soql, String parentSObjectName) {
		this.soql = soql;
		this.originalSoql = soql;
		this.parentSObjectName = parentSObjectName;
		this.parsedFieldUsage = new FieldResults();

		parse();
	}

	private void parse() {
		Map<String, List<Integer>> innerSoqlStrings = new Map<String, List<Integer>>();
		Set<SoqlFieldExtractor> innerSoqls = new Set<SoqlFieldExtractor>();

		// Grab all the 'from [object]' matches
		// One of these will be the top level one that we need to use
		// We have to do it this way to find which inner soqls are before and after the primary 'from [object]' match
		// THis is because the ones before are children of the primary object and the ones after are independent
		List<List<Object>> fromObjects = new List<List<Object>>();
		Matcher fromMatcher = Pattern.compile('(?ism)\\bfrom\\s+([A-Za-z]\\w+?)(?:\\b|$)').matcher(soql);
		while(fromMatcher.find()) {
			fromObjects.add(new List<Object>{fromMatcher.group(1), fromMatcher.start(), fromMatcher.end()});
		}

		// extract all inner soql's out first
		String selectRegex = '(?ism)(\\s*?\\(\\s*?)select\\b';
		Pattern selectPattern = Pattern.compile(selectRegex);
		Matcher innerSoqlMatches = selectPattern.matcher(soql);
		while(innerSoqlMatches.find()) {

			// deal with inner soqls
			String startingValue = soql.substring(innerSoqlMatches.start()).trim();

			// get rid of the first '('
			startingValue = startingValue.substring(1);

			// grab the rest of the inner soql
			String innerSoql = getBetweenParenthesis(startingValue);

			// store the soql and the start/end position
			// we use the start/end position to understand where the inner soql is before the 'from' or after
			// if the soql is before the 'from' then it will be a relationship of the object
			// if the soql is after the 'from' then the soql will be independent
			Integer startPosition = innerSoqlMatches.start();
			Integer endPosition = innerSoqlMatches.start() + innerSoql.length() + innerSoqlMatches.group(1).length();
			innerSoqlStrings.put(innerSoql, new List<Integer>{startPosition, endPosition});

			// remove the FROM associated with this inner soql
			for(Integer i=fromObjects.size()-1;i>=0;i--) {
				if(Integer.valueOf(fromObjects[i][1]) > startPosition && Integer.valueOf(fromObjects[i][2]) <= endPosition) {
					// this is a 'from' from an inner soql so it's not relevent for us to keep it
					fromObjects.remove(i);
					break;
				}
			}
		}

		// there should only be one fromObjects element left!
		if(fromObjects.size() != 1) {
			throw new InvalidSoqlException('Invalid soql. Could not find specific from element');
		}

		// grab the priumary sobject and make sure it's lowercase
		primarySObjectName = String.valueOf(fromObjects[0][0]).toLowerCase();

		// remove all the identified inner soqls from the string
		for(String innerSoql : innerSoqlStrings.keySet()) {
			soql = soql.replace(innerSoql, '');
		}


		// find the remaining 'FROM [object]' to remove it from the soql
		fromMatcher = Pattern.compile('(?ism)\\bfrom\\s+([A-Za-z]\\w+?)(?:\\b|$)').matcher(soql);
		if(fromMatcher.find() && fromMatcher.groupCount() == 1) {
			// get rid of 'FROM [entityName]'
			soql = soql.replace(fromMatcher.group(0), '');
		}

		// convert the child relationship to it's proper object name (if necessary)
		// this would only be applicable when the parse() method identifies an inner soql and extracts it out and parses it
		if(!String.isEmpty(parentSObjectName)) {
			// this means that the entityName parsed above will be a child of the parent and we need to find the real name of the entity
			List<String> entityNameParts = primarySObjectName.split('\\.');
			if(entityNameParts.size() > 1 && entityNameParts[0].equalsIgnoreCase(parentSObjectName)) {
				// sometimes an inner soql will also include the parent entity too
				// ex: Select Id, (Select Id From Account.Contacts) From Account
				entityNameParts.remove(0);
			}

			// change the entity name to it's proper name and make sure it's lowercase
			primarySObjectName = getRealEntityNameFromChildRelationship(String.join(entityNameParts, '\\.')).toLowerCase(); // should never have a dot!
		}

		for(String innerSoqlString : innerSoqlStrings.keySet()) {

			// Check to see if the inner soql appears before or after the primary 'FROM [object]'
			// This determines whether the inner soql is considered a child relationship of the primary [object] or whether it's independent
			// Ex: Select Id, >> (Select Id From Contacts) << From Account << Contacts is relationship to Account
			//      Select Id From Account Where Case__c In >> (Select Id From Case) << Case is independent to Account

			if(Integer.valueOf(fromObjects[0][2]) < innerSoqlStrings.get(innerSoqlString)[0]) {
				// the inner soql is independent of the primary object
				innerSoqls.add(new SoqlFieldExtractor(innerSoqlString));
			} else {
				// the inner soql is related to the primary object
				innerSoqls.add(new SoqlFieldExtractor(innerSoqlString, primarySObjectName));
			}
		}

		// remove all the stuff that would interfere with getting an indication on fields
		Map<String, String> replacementPatterns = new Map<String, String>();

		replacementPatterns.put('(?ism)\\)\\s*[A-Za-z]\\w+\\b', ''); // remove aliases, assumes literal )[space/s][word]
		//replacementPatterns.put('(?ism)(?:Count|Max|Min|Avg|Sum)\\s*?\\(\\s*?([^\\)\\s]*?)\\s*?\\)\\s*?(?:[A-Za-z]\\w+\\s*?)?                                (?:,|\\sfrom\\b)', '$1');

		// TODO
		// this will be a problem when dealing with polymorphic fields...
		// this should be a fringe case but might come up at some point in time
		replacementPatterns.put('(?ism)\\bWHEN\\s+?[^\\s]+\\s*+THEN\\b', '');

		//these are a type of fail safe
		// it's probably not too necessary to do this since we do a check on all the returned values anyway to make sure the fields exist before returning them
		replacementPatterns.put('(?ism)\\b(with|data|category|security_enforced|maxdescriptorperrecord|supportsdomains|supportsdelegates|recordvisibilitycontext|above|rollup|using|grouping|scope|for|view|reference|update|format|tracking|viewstat|count|max|min|avg|sum|in|convertcurrency|calendar_year|calendar_quarter|day_in_month|end|day_in_week|day_in_year|day_only|fiscal_month|fiscal_quarter|fiscal_year|hour_in_day|week_in_month|week_in_year|geolocation|distance|hour_in_day|converttimezonein|today|typeof|offset|true|false|and|or|group|order|by|having|select|where|includes|excludes|asc|desc|like|not)(?:\\b|$)', '');

		replacementPatterns.put('(?ism)\\bNULLS\\s+(FIRST|LAST)(?:\\b|$)', '');
		replacementPatterns.put('(?ism)\\bLAST_N_DAYS\\s*?:\\s*?\\d{1,100}(?:\\b|$)', '');
		replacementPatterns.put('(?ism)\\bLIMIT\\s+\\d{1,100}(?:\\b|$)', '');
		replacementPatterns.put('(?ism)\\b\\d{1,1000}(?:\\b|$)', '');
		replacementPatterns.put('(?ism)\\b:\\b', '');
		replacementPatterns.put('(?ism)\\\'.*?(?<!\\))\\\'', ''); // literal values 'eoirfhoeirhf', 'efwef\'wefwef' etc..
		for(String pattern : replacementPatterns.keySet()) {
			soql = soql.replaceAll(pattern, replacementPatterns.get(pattern));
		}

		Set<String> possibleFields = new Set<String>();
		Pattern fieldPattern = Pattern.compile('(?ism)\\b([A-Za-z][\\w\\.\\(\\)]{1,205})(?:\\b|$)');
		Matcher fieldMatcher = fieldPattern.matcher(soql);
		while(fieldMatcher.find()) {
			possibleFields.add(fieldMatcher.group(1));
		}

		// make sure the 'possible fields' exist and traverse up the relationships to get their associating objects
		FieldResults usage = resolvePotentialFields(possibleFields);

		// make sure the usage includes the current sObject itself
		if(usage.fieldUsage.get(primarySObjectName) == null) {
			usage.fieldUsage.put(primarySObjectName, new Set<String>());
		}
		usage.dependantObjects.add(primarySObjectName);

		// determines whether or not the new fields selectors are included in the soql or not
		Boolean allFields = Pattern.compile('(?ism)\\bFIELDS\\s*?\\(\\s*?ALL\\s*?\\)').matcher(soql).find();
		Boolean allStandardFields = Pattern.compile('(?ism)\\bFIELDS\\s*?\\(\\s*?STANDARD\\s*?\\)').matcher(soql).find();
		Boolean allCustomFields = Pattern.compile('(?ism)\\bFIELDS\\s*?\\(\\s*?CUSTOM\\s*?\\)').matcher(soql).find();

		if(allFields || (allCustomFields && allStandardFields)) {
			usage.fieldUsage.get(primarySObjectName).addAll(getObjectFields(primarySObjectName, FieldRetrieveTypeEnum.ALL));
		} else {
			if(allCustomFields) {
				usage.fieldUsage.get(primarySObjectName).addAll(getObjectFields(primarySObjectName, FieldRetrieveTypeEnum.CUSTOM));
			} else if(allStandardFields) {
				usage.fieldUsage.get(primarySObjectName).addAll(getObjectFields(primarySObjectName, FieldRetrieveTypeEnum.STANDARD));
			}
		}

		// add the inner soql dependencies
		for(SoqlFieldExtractor innerSoql : innerSoqls) {
			usage.dependantObjects.addAll(innerSoql.parsedFieldUsage.dependantObjects);

			for(String objectName : innerSoql.parsedFieldUsage.fieldUsage.keySet()) {
				if(usage.fieldUsage.get(objectName) == null) {
					usage.fieldUsage.put(objectName, new Set<String>());
				}
				usage.fieldUsage.get(objectName).addAll(innerSoql.parsedFieldUsage.fieldUsage.get(objectName));
			}
		}

		this.parsedFieldUsage = usage;
	}

	/**
	 * This method will convert a child relationship into an actual entity name
	 */
	private String getRealEntityNameFromChildRelationship(String childEntityName) {

		Map<String, Schema.SObjectType> globalDescribe = CommonUtils.getGlobalDescribe();
		if(!globalDescribe.containsKey(parentSObjectName.toLowerCase())) {
			throw new InvalidSoqlException('Could not find parent entity');
		}

		DescribeSObjectResult describeResult = describeObject(parentSObjectName.toLowerCase());
		if(describeResult == null) {
			throw new InvalidSoqlException('Could not find parent entity');
		}

		for(Schema.ChildRelationship childRelationship : describeResult.getChildRelationships()) {
			if(childEntityName.equalsIgnoreCase(childRelationship.relationshipName)) {
				return String.valueOf(childRelationship.childSObject);
			}
		}

		throw new InvalidSoqlException('Could not find child entity');
	}

	private FieldResults resolvePotentialFields(Set<String> possibleFields) {
		Set<String> dependantObjects = new Set<String>();
		Map<String, Set<String>> fieldUsage = new Map<String, Set<String>>();

		for(String possibleField : possibleFields) {
			//System.debug('possibleField: ' + possibleField);

			Set<String> objectList = new Set<String>();
			String currentSObjectName = primarySObjectName;
			List<String> potentialFieldParts = possibleField.split('\\.');
			// if the user added the entityName itself in the select field
			if(potentialFieldParts[0].equalsIgnoreCase(primarySObjectName)) {
				potentialFieldParts.remove(0);
			}

			// loop through a list of the potential field extracted with our regex matching
			// remember, these might not be real fields, that why we resolve them against actual objects in Salesforce
			for(Integer i=0;i<potentialFieldParts.size();i++) {
				String potentialFieldPart = potentialFieldParts[i].trim().toLowerCase();
				DescribeSObjectResult entityDescribe = describeObject(currentSObjectName);

				// the currentSObjectName might not actually be a valid object
				// this is due the regex's to try and extract 'potential' fields which match certain formats;
				if(entityDescribe == null) {
					// skip this field altogether and continue to the next potential field
					//System.debug('Skipping Describe Reconciliation: ' + currentSObjectName);
					break;
				}

				if(i == (potentialFieldParts.size()-1)) {
					// last element in array... this will be the field (only if it's a valid field to begin with)

					Map<String, Schema.SObjectField> fields = entityDescribe.fields.getMap();
					//					for(String fieldName : fields.keySet()) {
					//						System.debug('Field: ' + fieldName);
					//					}

					if(fields.containsKey(potentialFieldPart)) {
						//System.debug('found field!');

						// store a list of all the objects that we are dependant on for this field
						dependantObjects.addAll(objectList);

						// store a reference to the field that is being used
						if(fieldUsage.get(currentSObjectName.toLowerCase()) == null) {
							fieldUsage.put(currentSObjectName.toLowerCase(), new Set<String>());
						}
						fieldUsage.get(currentSObjectName.toLowerCase()).add(potentialFieldPart);

					}
				} else {

					// based on the current entity we need to resolve the relationship to an actual object so we can keep traversing up the hierarchy to find the object linked to the field being selected
					// to do this we loop through all the fields on the current entity and find the field with the matching relationship.
					Boolean foundMatch = true;
					Map<String, Schema.SObjectField> fields = entityDescribe.fields.getMap();
					for(Schema.SObjectField field : fields.values()) {
						DescribeFieldResult fieldDescribe = describeField(field);

						if(!String.isEmpty(fieldDescribe.relationshipName) && fieldDescribe.relationshipName.equalsIgnoreCase(potentialFieldPart)) {
							foundMatch = true;

							// add this field as a dependency
							if(fieldUsage.get(currentSObjectName.toLowerCase()) == null) {
								fieldUsage.put(currentSObjectName.toLowerCase(), new Set<String>());
							}
							fieldUsage.get(currentSObjectName.toLowerCase()).add(fieldDescribe.name.toLowerCase());

							// only take into account the first relationship... this should cover 100% of custom field use cases since polymorphic custom fields can not be created
							currentSObjectName = String.valueOf(fieldDescribe.referenceTo[0]);

							// store a reference to the object in the hierarchy since it's a dependency with the SOQL being parsed
							objectList.add(currentSObjectName.toLowerCase());

							break;
						}
					}

					if(!foundMatch) {
						// skip this field altogether and continue to the next potential field
						//System.debug('Skipping Object Reconciliation: ' + potentialFieldPart);
						break;
					}
				}
			}
		}

		FieldResults results = new FieldResults();
		results.dependantObjects = dependantObjects;
		results.fieldUsage = fieldUsage;
		return results;
	}

	/**
	 * Grab a list of fields for a particular object
	 * This is to satisfy the use of FIELDS(ALL) FIELDS(STANDARD) FIELDS(CUSTOM)
	 */
	private Set<String> getObjectFields(String sObjectName, FieldRetrieveTypeEnum retrieveType) {
		Set<String> output = new Set<String>();
		DescribeSObjectResult describe = describeObject(sObjectName);
		if(retrieveType == FieldRetrieveTypeEnum.ALL) {
			output.addAll(describe.fields.getMap().keySet().clone());
		} else if(retrieveType == FieldRetrieveTypeEnum.CUSTOM) {
			for(SObjectField field : describe.fields.getMap().values()) {
				DescribeFieldResult fieldDescribe = describeField(field);
				if(fieldDescribe.custom) {
					output.add(String.valueOf(field));
				}
			}
		} else if(retrieveType == FieldRetrieveTypeEnum.STANDARD) {
			for(SObjectField field : describe.fields.getMap().values()) {
				DescribeFieldResult fieldDescribe = describeField(field);
				if(!fieldDescribe.custom) {
					output.add(String.valueOf(field));
				}
			}
		}

		return output;
	}

	/**
	 * Grab values between '(' and ')'
	 * NOTE: Do not trim() since the length of the output is used to move iteration markers
	 *
	 * @return
	 */
	private String getBetweenParenthesis(String soqlPart) {
		String value = '';
		Integer openParenthesis = 0;
		for(Integer i=0;i<soqlPart.length();i++) {
			//TODO... read upto next ( or ) for performance improvement (probably)

			if(soqlPart.substring(i, i+1) == '(') {
				openParenthesis++;
			} else if(soqlPart.substring(i, i+1) == ')') {
				openParenthesis--;

				if(openParenthesis < 0) {
					break;
				}
			}

			value = value + soqlPart.substring(i, i+1);
		}

		return value;
	}

	private DescribeSObjectResult describeObject(String objectName) {
		String objectNameLower = objectName.toLowerCase();

		if(describeCache.containsKey(objectNameLower)) {
			return describeCache.get(objectNameLower);
		} else {
			Map<String, Schema.SObjectType> globalDescribe = CommonUtils.getGlobalDescribe();
			if(!globalDescribe.containsKey(objectNameLower)) {
				return null;
			} else {
				DescribeSObjectResult describeResult = globalDescribe.get(objectNameLower).getDescribe();

				describeCache.put(objectNameLower, describeResult);

				return describeResult;
			}
		}
	}

	private DescribeFieldResult describeField(Schema.SObjectField field) {
		if(describeFieldCache.containsKey(field)) {
			return describeFieldCache.get(field);
		} else {
			DescribeFieldResult describeResult = field.getDescribe();
			describeFieldCache.put(field, describeResult);
			return describeResult;
		}
	}

	public class InvalidSoqlException extends Exception {}

	public class FieldResults {
		public Set<String> dependantObjects = new Set<String>();
		public Map<String, Set<String>> fieldUsage = new Map<String, Set<String>>();
	}

}