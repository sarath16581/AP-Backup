/**
 * @author Harry Wang
 * @date 2024-05-17
 * @group Controller
 * @tag Controller
 * @tag CSP
 * @description Service Controller class for ABN Update
 * @changelog
 * 2024-05-17 - Harry Wang - Created
 */
public with sharing class ABNChangeController {

	/**
	 * Field Overrides when selecting At Risk Business; Only old and new organisations required
	 */
	private static final Map<SObjectType,Set<SObjectField>> AT_RISK_BUSINESS_FIELD_OVERRIDES = new Map<SObjectType,Set<SObjectField>> {
			At_Risk_Business__c.SObjectType => new Set<SObjectField> {
					At_Risk_Business__c.Related_Organisation__c, At_Risk_Business__c.Legal_Entity_Name__c
			},
			Account.SObjectType => new Set<SObjectField> {
					Account.Name
			}
	};

	/**
	 * Field Overrides when selecting old and new contacts
	 */
	private static final Set<SObjectField> CONTACT_FIELD_OVERRIDES = new Set<SObjectField>{Contact.FirstName, Contact.LastName, Contact.Name, Contact.Title, Contact.Email, Contact.Phone, Contact.Has_Online_Credential__c};

	/**
	 * This method is used to get deduplicated contacts and related At Risk Business between contacts from old organisation (legal entity) and new organisation (related organisation)
	 * @param businessAtRiskId  At Risk Business Id
	 *
	 * @return Map of 'businessAtRisk' => At Risk Business, 'contacts' => list of deduplicated contacts
	 */
	@AuraEnabled(Cacheable=true)
	public static Map<String, Object> getDeduplicatedContactsAndBaR(String businessAtRiskId) {
		At_Risk_Business__c atRiskBusiness = AtRiskBusinessSelector.newInstance(AT_RISK_BUSINESS_FIELD_OVERRIDES).selectById(new Set<Id>{businessAtRiskId}, new Set<Object>{AtRiskBusinessSelector.options.WITH_RELATED_ORGANISATION})[0];
		List<Contact> oldContacts = ContactsSelector.newInstance(0, CONTACT_FIELD_OVERRIDES).selectCloneableContactsByAccount(new Set<Id>{atRiskBusiness.Legal_Entity_Name__c});
		List<Contact> newContacts = ContactsSelector.newInstance(0, CONTACT_FIELD_OVERRIDES).selectByAccount(new Set<Id>{atRiskBusiness.Related_Organisation__c}).values();

		List<Contact> deduplicatedContacts = ContactDuplicateChecker.findUniqueContacts(oldContacts, newContacts);
		return new Map<String, Object>{
				'businessAtRisk' => atRiskBusiness,
				'contacts' => deduplicatedContacts
		};
	}

	/**
	 * @description Get datatable columns for contacts from field set ABNChangeContactColumn
	 * @return list of datatable column wrapper
	 */
	@AuraEnabled(cacheable=true)
	public static List<DataTableColumn> retrieveColumns() {
		try {
			List<DataTableColumn> dataTableColumnList = new List<DataTableColumn>();

			for (Schema.FieldSetMember fs: SObjectType.Contact.fieldSets.ABNChangeContactColumn.getFields()) {
				DataTableColumn datatableColumn = new DataTableColumn(fs.getLabel(), fs.getFieldPath(), String.valueOf(fs.getType()));
				dataTableColumnList.add(datatableColumn);
			}
			return dataTableColumnList;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Clone contacts to the new organisation with fields retrieved from ABNChangeContactCloning field set
	 * Support partial success and log dml failures on Exception Log
	 * DML option used to bypass alert type duplicate rule
	 * Unexpected exception will be logged as well
	 * @param newOrganisationId Id of new organisation where the contacts will be cloned to
	 * @param oldContactIds list of old contact Ids
	 *
	 * @return list of succeeded contact Ids
	 */
	@AuraEnabled
	public static List<String> cloneContacts(String newOrganisationId, List<Id> oldContactIds) {
		List<String> savedContactsIds = new List<String>();
		try {
			// Select old contacts by Ids with fields from ABNChangeContactCloning field set
			Set<SObjectField> contactCloningFields = new Set<SObjectField>();
			Set<String> contactCloningFieldNames = new Set<String>();
			Schema.FieldSet fieldSet = Schema.SObjectType.Contact.fieldSets.getMap().get('ABNChangeContactCloning');
			for (Schema.FieldSetMember fieldSetMember: fieldSet.getFields()) {
				contactCloningFields.add(fieldSetMember.getSObjectField());
				contactCloningFieldNames.add(fieldSetMember.getFieldPath());
			}
			List<Contact> oldContacts = ContactsSelector.newInstance(0, contactCloningFields).selectById(new Set<Id>(oldContactIds)).values();

			// Extract fields from old contacts and map to new contacts to be inserted
			// Bypass duplicate alert
			Database.DMLOptions opt = new Database.DMLOptions();
			opt.duplicateRuleHeader.allowSave = true;
			opt.optAllOrNone = false;

			List<Contact> newContacts = new List<Contact>();
			for (Contact oldContact: oldContacts) {
				Contact c = new Contact();
				c.AccountId = newOrganisationId;
				for (String fieldName: contactCloningFieldNames) {
					c.put(fieldName, oldContact.get(fieldName));
				}
				newContacts.add(c);
			}

			if (newContacts.size() > 0) {
				String logBody = '';
				Integer failureCount = 0;
				// dmlOption will only bypass alert type duplicate rule and will not bypass enforced duplicate rule (contacts under same org)
				//TODO: Approval from tech lead before using this method in ApplicationDatabase
				List<Database.SaveResult> results = ApplicationDatabase.getInstance().dmlInsert(newContacts, opt);
				for (Integer i = 0; i < results.size(); i++) {
					if (results[i].isSuccess()) {
						savedContactsIds.add(results[i].getId());
					} else {
						failureCount ++;
						logBody += oldContacts[i].Id + ' cloned failed with status code: ' +results[i].getErrors()[0].getStatusCode() + ', message: ' + results[i].getErrors()[0].getMessage() + '\n';
					}
				}
				if (failureCount > 0) {
					ApplicationLogger.getInstance().logMessage(new List<String>{failureCount + ' contacts cloned failed. Please check Additional Info.'}, new List<String>{logBody}, 'ABNChange', ABNChangeController.class.getName(), 'cloneContacts', '', ApplicationLogger.LoggingLevel.ERROR);
				}
			}
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'ABNChange', ABNChangeController.class.getName(), 'cloneContacts', null, ApplicationLogger.LoggingLevel.ERROR);
		}
		return savedContactsIds;
	}

	public class DataTableColumn {
		@AuraEnabled
		public String label {get;set;}
		@AuraEnabled
		public String fieldName {get;set;}
		@AuraEnabled
		public String type {get;set;}

		public DataTableColumn(String label, String fieldName, String type)
		{
			this.label = label;
			this.fieldName = fieldName;
			if (fieldName == 'Phone') {
				this.type = 'phone';
			} else {
				this.type = type.toLowerCase();
			}
		}
	}
}