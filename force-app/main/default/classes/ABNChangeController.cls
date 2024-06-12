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
	 * Field Overrides when selecting At Risk Business
	 */
	private static final Map<SObjectType,Set<SObjectField>> AT_RISK_BUSINESS_FIELD_OVERRIDES = new Map<SObjectType,Set<SObjectField>> {
			At_Risk_Business__c.SObjectType => new Set<SObjectField> {
					At_Risk_Business__c.Id, At_Risk_Business__c.Related_Organisation__c, At_Risk_Business__c.Legal_Entity_Name__c
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
	 * Datacloud.FindDuplicates.findDuplicates is used to deduplicate contacts
	 * @param businessAtRiskId  At Risk Business Id
	 *
	 * @return Map of 'businessAtRisk' => At Risk Business, 'contacts' => list of deduplicated contacts
	 */
	@AuraEnabled(Cacheable=true)
	public static Map<String, Object> getDeduplicatedContactsAndBaR(String businessAtRiskId) {
		At_Risk_Business__c atRiskBusiness = AtRiskBusinessSelector.newInstance(AT_RISK_BUSINESS_FIELD_OVERRIDES).selectById(new Set<Id>{businessAtRiskId}, new Set<Object>{AtRiskBusinessSelector.options.WITH_RELATED_ORGANISATION})[0];
		List<Contact> oldContacts = ContactsSelector.newInstance(0, CONTACT_FIELD_OVERRIDES).selectCloneableContactsByAccount(atRiskBusiness.Legal_Entity_Name__c);

		Set<Id> duplicatedIds = new Set<Id>();
		List<Contact> uniqueContacts = new List<Contact>();

		// Assign new org on old contacts
		for (Contact c: oldContacts) {
			c.AccountId = atRiskBusiness.Related_Organisation__c;
		}

		List<Datacloud.FindDuplicatesResult> fdResults = new List<Datacloud.FindDuplicatesResult>();

		// The input array of Datacloud.FindDuplicates.findDuplicates method is limited to 50 elements. Split the list to sub lists accordingly
		List<List<Contact>> contactsList = (List<List<Contact>>)splitContacts(oldContacts, 50);
		for (List<Contact> contacts: contactsList) {
			fdResults = Datacloud.FindDuplicates.findDuplicates(contacts);
			for (Integer i = 0; i < fdResults.size(); i++) {
				for (Datacloud.DuplicateResult duplicateResult :fdResults[i].getDuplicateResults()) {
					for (Datacloud.MatchResult matchResult :duplicateResult.getMatchResults()) {
						// Collect matched Ids
						if (!duplicateResult.allowSave && matchResult.size > 0) {
							duplicatedIds.add(contacts[i].Id);
						}
					}
				}
			}
		}

		for (Integer i = 0; i < oldContacts.size(); i++) {
			if (!duplicatedIds.contains(oldContacts[i].Id)) {
				uniqueContacts.add(oldContacts[i]);
			}
		}

		return new Map<String, Object>{
				'businessAtRisk' => atRiskBusiness,
				'contacts' => uniqueContacts
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
	 */
	@AuraEnabled
	public static void cloneContacts(String newOrganisationId, List<Id> oldContactIds) {
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
				// Create new contacts asynchronously and log failed old contacts
				System.enqueueJob(new ABNChangeContactCloningQueueable(oldContacts, newContacts));
			}
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'ABNChange', ABNChangeController.class.getName(), 'cloneContacts', null, ApplicationLogger.LoggingLevel.ERROR);
		}
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

	public static List<List<Contact>> splitContacts(List<Contact> source, Integer size) {
		List<List<Contact>> ret = new List<List<Contact>>();
		if (source == null) return ret;

		// If the source size is equal to or smaller than our partition size, just return it
		if (source.size() <= size) {
			ret.add(source);
			return ret;
		}

		// Initialize the partitions
		Integer partition = 0;
		ret.add(new List<Contact>());

		for (Contact obj : source) {
			// Create a new partition when we fill one up
			if (ret[partition].size() == size) {
				partition++;
				ret.add(new List<Contact>());
			}
			// Add object to current partition
			ret[partition].add(obj);
		}

		return ret;
	}
}