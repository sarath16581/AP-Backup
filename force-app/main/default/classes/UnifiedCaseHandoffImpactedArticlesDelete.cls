/**
 * @description This is to delete impacted articles in system mode
 * @author Vasu Gorakati
 * @date 2024-07-31
 * @changelog
 * 2024-07-31 - Vasu Gorakati - Case Hand-off
 **/
public without sharing class UnifiedCaseHandoffImpactedArticlesDelete {
	/**
	 * Delete impacted articles
	 * @param  impactedArticles - List of impacted articles
	 */
	public static void impactedArticlesDelete(List<ImpactedArticle__c> impactedArticles) {
		ApplicationDatabase.getInstance().dmlDelete(impactedArticles);
	}
}
