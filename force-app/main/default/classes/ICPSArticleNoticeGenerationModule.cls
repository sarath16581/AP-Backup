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
	public static ICPSArticleNoticeGenerationModule newInstance() {
		return (ICPSArticleNoticeGenerationModule)Application.Utilities.newInstance(ICPSArticleNoticeGenerationModule.class);
	}

	public ICPSArticleNoticeGenerationModule() {
		getTriggerEvents().enableAfterInsert();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			concatICPSArticleNumbers(records, uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getUserId(), 'ICPS', ICPSArticleNoticeGenerationModule.class.getName(), 'onAfterInsert', 'ICPSArticleTrigger', LoggingLevel.ERROR);
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
					names.add(a.Name);
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
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) ICPSArticleNoticeGenerationModule.newInstance();
		}
	}
}