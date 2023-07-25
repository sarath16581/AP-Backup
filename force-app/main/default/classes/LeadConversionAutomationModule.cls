/**
 * @description
 * Domain Module to handle Lead Conversion related functionality
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Harry Wang
 * @date 2023-06-21
 * @group Domain
 * @domain LeadGenericDomain
 * @changelog
 * 2023-06-21 - Harry Wang - Created
 *
 */
public inherited sharing class LeadConversionAutomationModule extends ApplicationModule {
	private static final Map<SObjectField, SObjectField> ACCOUNT_FIELD_MAPPINGS = new Map<SObjectField, SObjectField>{
			Lead.City => Account.ShippingCity,
			Lead.Country => Account.ShippingCountry,
			Lead.DPID__c => Account.Shipping_DPID__c,
			Lead.PostalCode => Account.ShippingPostalCode,
			Lead.State => Account.ShippingState,
			Lead.Street => Account.ShippingStreet,
			Lead.Email => Account.Email__c
	};
	private static final Map<SObjectField, SObjectField> CONTACT_FIELD_MAPPINGS = new Map<SObjectField, SObjectField>{
			Lead.City => Contact.OtherCity,
			Lead.Country => Contact.OtherCountry,
			Lead.DPID__c => Contact.Other_DPID__c,
			Lead.PostalCode => Contact.OtherPostalCode,
			Lead.State => Contact.OtherState,
			Lead.Street => Contact.OtherStreet
	};
	private static final Map<SObjectField, SObjectField> OPPORTUNITY_FIELD_MAPPINGS = new Map<SObjectField, SObjectField>{
			Lead.Description => Opportunity.Description,
			Lead.Campaign__c => Opportunity.CampaignId,
			Lead.ConvertedContactId => Opportunity.KeyContact__c,
			Lead.Opportunity_Initial_Estimate__c => Opportunity.Amount
	};

	public LeadConversionAutomationModule() {
		getTriggerEvents().enableAfterUpdate();
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		mapAdditionalFieldsOnLeadConversion(records, existingRecords, uow);
	}

	/**
	 * This method is used to convert lead to related Account, Contact and Opportunity
	 * Lead fields that are not supported using standard mapping behaviour and "Map Leads Fields" configuration should be put into this method
	 * @param records list of new leads to be updated
	 * @param existingRecords list of existing leads
	 * @param uow Application unit of work
	 */
	@TestVisible
	private void mapAdditionalFieldsOnLeadConversion(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			Map<Id, Id> convertedLeadOrgMapping = new Map<Id, Id>();
			Set<Id> convertedContactIds = new Set<Id>();
			Set<Id> convertedOpportunityIds = new Set<Id>();

			// IsConverted is monitored by application recursion framework so when it changes from false to true the first time changeRecords will be generated
			Set<SObjectField> monitoredFields = new Set<SObjectField>{Lead.IsConverted};
			List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('LeadConversionAutomation', records, existingRecords, monitoredFields);
			for (ApplicationRecursion.RecordState recordState: changedRecords) {
				Lead leadRecord = (Lead) recordState.record;

				// check if monitored fields have changed. 'IsConverted' will only change once in current transaction.
				// cater for scenarios where other process automation (e.g. workflow rules,  process builder) have updated
				// other monitored fields in the current transaction after the initial call to this method.
				if (leadRecord.IsConverted && recordState.changedFields.contains(Lead.IsConverted)) {
					if (leadRecord.ConvertedAccountId != null) {
						convertedLeadOrgMapping.put(leadRecord.Id, leadRecord.ConvertedAccountId);
					}
					if (leadRecord.ConvertedContactId != null) {
						convertedContactIds.add(leadRecord.ConvertedContactId);
					}
					if (leadRecord.ConvertedOpportunityId != null) {
						convertedOpportunityIds.add(leadRecord.ConvertedOpportunityId);
					}
				}
			}

			if (!convertedLeadOrgMapping.isEmpty()) {
				Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{};
				fieldOverrides.put(Account.SObjectType, new Set<SObjectField>(ACCOUNT_FIELD_MAPPINGS.values()));
				fieldOverrides.put(Contact.SObjectType, new Set<SObjectField>(CONTACT_FIELD_MAPPINGS.values()));
				fieldOverrides.put(Opportunity.SObjectType, new Set<SObjectField>(OPPORTUNITY_FIELD_MAPPINGS.values()));

				Map<Id, Account> accounts = new Map<Id, Account>((List<Account>)AccountsSelector.newInstance(0, fieldOverrides).selectByIdWithContactsAndOpportunities(convertedContactIds, convertedOpportunityIds, new Set<Id>(convertedLeadOrgMapping.values()), new Set<Object>()));
				Map<Id, Lead> leadRecords = new Map<Id, Lead>((List<Lead>)records);

				for (Id convertedLeadId: convertedLeadOrgMapping.keySet()) {
					Lead leadRecord = leadRecords.get(convertedLeadId);
					registerUpdatableRecords(leadRecord, accounts.get(leadRecord.ConvertedAccountId), uow);
				}
			}
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'LeadConversionAutomation', LeadConversionAutomationModule.class.getName(), 'onAfterUpdate', 'Lead', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	private void registerUpdatableRecords(Lead leadRecord, Account accountRecord, ApplicationUnitOfWork uow) {
		Account updatableAccount = (Account) getUpdatable(leadRecord, accountRecord, ACCOUNT_FIELD_MAPPINGS);
		if (updatableAccount != null) {
			uow.registerDirty(updatableAccount, false, 'LeadConversionAutomationModule.registerUpdatableRecords');
		}

		if (accountRecord.Contacts != null && !accountRecord.Contacts.isEmpty()) {
			Contact updatableContact = (Contact) getUpdatable(leadRecord, accountRecord.Contacts[0], CONTACT_FIELD_MAPPINGS);
			if (updatableContact != null) {
				uow.registerDirty(updatableContact, false, 'LeadConversionAutomationModule.registerUpdatableRecords');
			}
		}

		if (accountRecord.Opportunities != null && !accountRecord.Opportunities.isEmpty()) {
			Opportunity updatableOpportunity = (Opportunity) getUpdatable(leadRecord,  accountRecord.Opportunities[0], OPPORTUNITY_FIELD_MAPPINGS);
			if (updatableOpportunity != null) {
				uow.registerDirty(updatableOpportunity, false, 'LeadConversionAutomationModule.registerUpdatableRecords');
			}
		}
	}

	private SObject getUpdatable(Lead leadRecord, SObject targetRecord, Map<SObjectField, SObjectField> fieldMapping) {
		SObject updatable = null;
		for (SObjectField leadField: fieldMapping.keySet()) {
			SObjectField updatableField = fieldMapping.get(leadField);

			if (leadRecord.get(leadField) != null && targetRecord.get(updatableField) == null) {
				if (updatable == null) {
					updatable = targetRecord.getSObjectType().newSObject(targetRecord.Id);
				}
				updatable.put(fieldMapping.get(leadField), leadRecord.get(leadField));
			}
		}
		return updatable;
	}
}