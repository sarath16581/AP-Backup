/**************************************************
Type:       |
Purpose:    To delete Articles meeting following criteria,
			- Created 1 Month ago and
			- Not used by any open Cases or Cases closed within 2 months
Used By:             
History:
--------------------------------------------------
09.05.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/
global class BatchableArticleDeleter implements Database.Batchable<sObject> {
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator('SELECT Id, ArticleID__c FROM Article__c WHERE CreatedDate < LAST_N_DAYS:30');
	}
	
	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		Set<String> articleIds = new Set<String>();
		for (Article__c a : (List<Article__c>)scope)
		{
			articleIds.add(a.ArticleID__c);
		}
		
		Set<String> undeletableArticles = new Set<String>();
		for (Case c : [SELECT ReferenceID__c FROM Case WHERE ReferenceID__c IN :articleIds AND (ClosedDate = null OR ClosedDate = LAST_N_DAYS:60)]) 
		{
			undeletableArticles.add(c.ReferenceID__c);
		}
		
		List<Article__c> articlesToDelete = new List<Article__c>();
		for (Article__c a : (List<Article__c>)scope)
		{
			if (!undeletableArticles.contains(a.ArticleID__c))
			{
				articlesToDelete.add(a);
			}
		}
		
		if (articlesToDelete.size() > 0)
		{
			delete articlesToDelete;
		}
	}
	
	global void finish(Database.BatchableContext BC) {
	}
}