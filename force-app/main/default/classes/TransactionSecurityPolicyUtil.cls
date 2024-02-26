/**
 * @description Util class for TransactionSecurityPolicyManager
 * @author Naveen Rajanna
 * @date 2024-02-20
 * @group Tests
 * @changelog
 * 2024-02-20 - Naveen Rajanna - created - REQ3445775.
*/

public class TransactionSecurityPolicyUtil {
	public static final String WINDOWS_PLATFORM = 'WINDOWS';

	private static final Decimal CONSTANT_ROWS_PROCESSED = 10;
	private static final List<String> CONSTANT_DATA_SENSITIVITY_LEVEL = new List<String>{'OFFICIAL_SENSITIVE_PERSONAL'};
	private static final List<String> CONSTANT_OPERATION = new List<String>{'ReportExported','ReportExportedAsynchronously','ReportExportedUsingExcelConnector'};
	private static final List<String> CONSTANT_SENSITIVE_FIELDS_OBJECT = new List<String>{'Compensation__c','APT_Credit_Assessment__c','Apttus__APTS_Agreement__c','Billing_Account__c','Contact','Account'};

	public static final Decimal CONFIG_ROWS_PROCESSED = transactionSecurityPolicyConfigMap.get('ReportEventRowsProcessed')?.ConfigNumberValue__c ?? CONSTANT_ROWS_PROCESSED;
	public static final List<String> CONFIG_DATA_SENSITIVITY_LEVEL = transactionSecurityPolicyConfigMap.get('ReportEventFieldDataSensitivityLevel')?.ConfigTextAreaValue__c?.split(',') ?? CONSTANT_DATA_SENSITIVITY_LEVEL;
	public static final List<String> CONFIG_OPERATION = transactionSecurityPolicyConfigMap.get('ReportEventOperation')?.ConfigTextAreaValue__c?.split(',') ?? CONSTANT_OPERATION;
	public static final List<String> CONFIG_SENSITIVE_FIELDS_OBJECT = transactionSecurityPolicyConfigMap.get('ReportEventSensitiveFieldsObject')?.ConfigTextAreaValue__c?.split(',') ?? CONSTANT_SENSITIVE_FIELDS_OBJECT;
	
	public static Map<String, TransactionSecurityPolicyConfig__mdt> transactionSecurityPolicyConfigMap {
		get {
			if(transactionSecurityPolicyConfigMap == null) {
				transactionSecurityPolicyConfigMap = TransactionSecurityPolicyConfig__mdt.getAll();
			}
			return transactionSecurityPolicyConfigMap;
		}
		private set;
	}

	@TestVisible
	private static final String CACHE_KEY_TSP_SENSITIVE_FIELDS_BY_OBJECT = 'TSP_SENSITIVE_FIELDS_BY_OBJECT';
	private static final Map<SObjectType, Set<SObjectField>> USER_FIELD_OVERRIDES = new Map<SObjectType, Set<SObjectField>>{
		User.SObjectType => new Set<SObjectField>{ User.ProfileId },
		Profile.SObjectType => new Set<SObjectField>{ Profile.Name }
	};


	/**
	 * Validate if supplied userId is System Support User
	 * @param userId
	 * @return `Boolean`
	*/
	public static Boolean isSystemSupportUser(Id userId) {
		return userId.equals(ConfigSetting__c.getInstance().AutomatedCaseUser__c);
	}

	/**
	 * Validate if supplied userId profile is System Administrator
	 * @param userId
	 * @return `Boolean`
	*/
	public static Boolean isSystemAdministrator(Id userId) {
		return ![SELECT Id FROM User WHERE Id = :userId AND Profile.Name = 'System Administrator'].isEmpty();
	}

	/**
	 * Parses report event column headers.
	 * @param columnHeaders
	 * @return `Map<String, Set<String>>`
	*/
	public static Map<String, Set<String>> parseFieldsByObjectFromColumnHeaders(String columnHeaders) {
		Map<String, Set<String>> reportFieldsByObjectMap = new Map<String, Set<String>>();
		if(!String.isBlank(columnHeaders)) {
			// Extract column API names from column headers
			String columnAPINames = columnHeaders.substringBetween('[', ']') ?? '';
			
			// Remove brackets and spaces, then split into individual field names
			List<String> rawFieldNames = new List<String>(columnAPINames.replaceAll('[\\[\\]\\s]', '').split(','));
			
			// Process each field name
			for (String fieldName : rawFieldNames) {
				List<String> fieldParts = fieldName.split('\\.');
				
				// If field name has object hierarchy, extract the object and field name
				String extractedFieldName = (fieldParts.size() > 2) ? fieldParts[fieldParts.size() - 2] + '.' + fieldParts[fieldParts.size() - 1] : fieldName;
				if(fieldParts.size() > 1) {
					String objectName = extractedFieldName.split('\\.')[0];
					if (!reportFieldsByObjectMap.containsKey(objectName)) {
						reportFieldsByObjectMap.put(objectName, new Set<String>());
					}
					reportFieldsByObjectMap.get(objectName).add(extractedFieldName);  
				}
			}
		}
		
		return reportFieldsByObjectMap;
	}
	
	/**
	 * Retrieves sensitive fields by object from Platform Cache if exists else query and retrieve
	 * @param sensitiveObjectsToQuery
	 * @param sensitiveObjects
	 * @param dataSensitivityLevel
	 * @return `Set<String>`
	*/
	@TestVisible
	public static Set<String> getSensitiveFieldsByObjects(Set<String> sensitiveObjectsToQuery) {
		Set<String> sensitiveFieldSet = new Set<String>();
		Map<String, Set<String>> sensitiveFieldsByObjectMap = (Map<String, Set<String>>) CacheManager.get(CACHE_KEY_TSP_SENSITIVE_FIELDS_BY_OBJECT);
		sensitiveFieldsByObjectMap = sensitiveFieldsByObjectMap ?? new Map<String, Set<String>>();
		Set<String> objectsToQuery = new Set<String>();

		if(sensitiveFieldsByObjectMap.isEmpty()) {
			// if cache is empty then query all sensitive objects
			objectsToQuery.addAll(CONSTANT_SENSITIVE_FIELDS_OBJECT);
		} else {
			// else only query those doesn't exist and is required
			objectsToQuery.addAll(sensitiveObjectsToQuery);
			objectsToQuery.removeAll(sensitiveFieldsByObjectMap.keySet());
		}

		if (!objectsToQuery.isEmpty()) {			
			List<FieldDefinition> fieldDefinitions = [SELECT QualifiedApiName, EntityDefinition.QualifiedApiName 
														FROM FieldDefinition 
														WHERE EntityDefinition.QualifiedApiName IN :objectsToQuery 
														AND SecurityClassification =: CONFIG_DATA_SENSITIVITY_LEVEL];
			for (FieldDefinition field : fieldDefinitions) {
				String objectName = field.EntityDefinition.QualifiedApiName;
				String fieldName = field.QualifiedApiName;

				if (!sensitiveFieldsByObjectMap.containsKey(objectName)) {
					sensitiveFieldsByObjectMap.put(objectName, new Set<String>());
				}
				sensitiveFieldsByObjectMap.get(objectName).add(objectName + '.' + fieldName);
			}
			// store all sensitive fields by Object in Cache
			CacheManager.put(CACHE_KEY_TSP_SENSITIVE_FIELDS_BY_OBJECT, sensitiveFieldsByObjectMap);
		}

		// return only the fields for the sensitiveObjectsToQuery
		sensitiveFieldsByObjectMap.keySet().retainAll(sensitiveObjectsToQuery);
		for (Set<String> values : sensitiveFieldsByObjectMap.values()) {
			sensitiveFieldSet.addAll(values);
		} 
		
		return sensitiveFieldSet;
	}
}