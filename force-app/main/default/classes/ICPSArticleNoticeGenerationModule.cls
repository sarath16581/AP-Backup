/**
 * @description
 * Domain Module to update ICPS related to notice generation
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 *
 * @author Harry Wang
 * @date 2022-06-30
 * @group Domain
 * @domain ICPS
 * @changelog
 * 2022-06-30 - Harry Wang - Created
*/
public inherited sharing class ICPSArticleNoticeGenerationModule extends ApplicationDomain.Module {
	/**
	 * list of field types required to be capitalized
	 */
	private static final Set<SObjectField> CAP_FIELDS {
		get {
			if (CAP_FIELDS == null) {
				CAP_FIELDS = new Set<SObjectField> {
						ICPSArticle__c.Contents__c, ICPSArticle__c.ReceiverName__c, ICPSArticle__c.ReceiverStreetLine1__c,
						ICPSArticle__c.ReceiverStreetLine2__c, ICPSArticle__c.ReceiverCity__c, ICPSArticle__c.ReceiverPostalCode__c,
						ICPSArticle__c.ReceiverState__c, ICPSArticle__c.SenderName__c, ICPSArticle__c.SenderStreetLine1__c, ICPSArticle__c.SenderStreetLine2__c,
						ICPSArticle__c.SenderCity__c, ICPSArticle__c.SenderPostalCode__c, ICPSArticle__c.SenderState__c, ICPSArticle__c.SenderCountry__c
				};
			}
			return CAP_FIELDS;
		}
		set;
	}

	public static ICPSArticleNoticeGenerationModule newInstance() {
		return (ICPSArticleNoticeGenerationModule)Application.Utilities.newInstance(ICPSArticleNoticeGenerationModule.class);
	}

	public ICPSArticleNoticeGenerationModule() {
		getTriggerEvents().enableBeforeInsert().enableAfterInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			capitalizeFields(records, null);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getUserId(), 'ICPS', ICPSAutomationModule.class.getName(), 'onBeforeInsert', 'ICPSArticleTrigger', LoggingLevel.ERROR);
		}
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			concatICPSArticleNumbers(records, uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getUserId(), 'ICPS', ICPSArticleNoticeGenerationModule.class.getName(), 'onAfterInsert', 'ICPSArticleTrigger', LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			capitalizeFields(records, existingRecords);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getUserId(), 'ICPS', ICPSAutomationModule.class.getName(), 'onBeforeUpdate', 'ICPSArticleTrigger', LoggingLevel.ERROR);
		}
	}

	/**
	 * This method is used to concatenate article names with comma on the parent ICPS record
	 * @param records list of ICPS records to be updated
	 * @param uow Unit of Work instance
	 */
	@TestVisible
	private void concatICPSArticleNumbers(List<SObject> records, ApplicationUnitOfWork uow) {
		Set<Id> icpsIds = new Set<Id>();
		for (ICPSArticle__c a: (List<ICPSArticle__c>) records) {
			if (String.isNotBlank(a.Name)) {
				icpsIds.add(a.ICPS__c);
			}
		}

		List<ICPS__c> toUpdateICPSList = new List<ICPS__c>();

		if (!icpsIds.isEmpty()) {
			for (ICPS__c icps: ICPSSelector.newInstance().selectById(icpsIds, new Set<Object>{ICPSSelector.Options.WITH_ICPS_ARTICLES})) {
				List<String> names = new List<String>();
				for (ICPSArticle__c a: icps.ICPS_Articles__r) {
					names.add(a.Name.toUpperCase());
				}
				// concatenate article names with comma for each ICPS
				String concatNames = String.join(names, ', ');
				if (String.isNotBlank(concatNames)) {
					toUpdateICPSList.add(new ICPS__c(Id = icps.Id, Articles__c = concatNames));
				}
			}
		}
		// Only update ICPS with expected article names
		if (!toUpdateICPSList.isEmpty()) {
			uow.registerDirty(toUpdateICPSList);
		}
	}

	/**
	 * Some fields are required to be capitalized
	 */
	@TestVisible
	private void capitalizeFields(List<SObject> records, Map<Id, SObject> existingRecords) {
		for (ICPSArticle__c icpsArticle: (List<ICPSArticle__c>) records) {
			for (SObjectField fieldName: CAP_FIELDS) {
				String newValue = (String)icpsArticle.get(fieldName);
				if (newValue != null && (existingRecords == null || !newValue.equals(existingRecords.get(icpsArticle.Id).get(fieldName)))) {
					icpsArticle.put(fieldName, String.isNotBlank(newValue) ? newValue.toUpperCase() : newValue);
				}
			}
		}
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) ICPSArticleNoticeGenerationModule.newInstance();
		}
	}
}