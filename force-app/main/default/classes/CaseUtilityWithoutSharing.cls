/************************************
 * History
 * May-2015:  scherukuwada@salesforce.com	Added LIMIT 100
 * 2021-10-05 - Nathan Franklin - Deprecated class - EMPTY TEST - CaseCommonUtility_Test
 *                  Destructive change in JUL-2022
 * **********************************/
public without sharing class CaseUtilityWithoutSharing {
//	 public static void createSignatureAttachmentsAfterUpdate(Map<Id, Case> newCases, Map<Id, Case> oldCases) {
//		Map<Id, List<Case>> articleToCases = new Map<Id, List<Case>>();
//		for (Case c : newCases.values()) {
//			Case cOld = oldCases.get(c.Id);
//			if (c.ArticleTest__c != null && c.ArticleTest__c != cOld.ArticleTest__c) {
//				List<Case> clist = articleToCases.get(c.ArticleTest__c);
//				if (clist == null) {
//					clist = new List<Case>();
//				}
//				clist.add(c);
//				articleToCases.put(c.ArticleTest__c, clist);
//			}
//		}
//
//		createSignatureAttachments(articleToCases);
//	}
//
//	public static void createSignatureAttachmentsAfterInsert(Map<Id, Case> newCases) {
//		Map<Id, List<Case>> articleToCases = new Map<Id, List<Case>>();
//		for (Case c : newCases.values()) {
//			if (c.ArticleTest__c != null) {
//				List<Case> clist = articleToCases.get(c.ArticleTest__c);
//				if (clist == null) {
//					clist = new List<Case>();
//				}
//				clist.add(c);
//				articleToCases.put(c.ArticleTest__c, clist);
//			}
//		}
//
//		createSignatureAttachments(articleToCases);
//	}
//
//	public static void createSignatureAttachments(Map<Id, List<Case>> articleToCases) {
//		if (articleToCases != null && articleToCases.size() > 0) {
//			List<EventMessage__c> emList = new List<EventMessage__c>();
//			if(articleToCases.size()>0) {
//				for (EventMessage__c em : [SELECT Article__c, EventType__c, EventDescription__c, SignatoryName__c, SignatureXString__c FROM EventMessage__c WHERE Article__c IN :articleToCases.keySet()]) {
//					if (em.SignatureXString__c != null) {
//						emList.add(em);
//					}
//				}
//			}
//
//			List<Attachment> attachments = EventMessageUtil.createSignatureAttachments(emList, articleToCases);
//
//			if (attachments.size() > 0) {
//				insert attachments;
//			}
//		}
//	}
//
//	public static void attachEventMessagesToCases(SET<id> newCasestoMap){
//		List<Case> newCases = [select Lodgement_Network__c, ArticleTest__c from Case where id in :newCasestoMap];
//		System.debug('XXXBWXXX:Setting Lodgement Point');
//		Map<String, List<Case>> articleIdCaseMap = new Map<String, List<Case>>();
//		for(Case c: newCases){
//			if(c.Lodgement_Network__c == null && !string.isBlank(c.ArticleTest__c)) {
//				if(!articleIdCaseMap.containsKey(c.ArticleTest__c)){
//					articleIdCaseMap.put(c.ArticleTest__c, new List<Case>());
//				}
//				articleIdCaseMap.get(c.ArticleTest__c).add(c);
//			}
//		}
//		System.debug('XXXBWXXX:articleIdCaseMap:'+articleIdCaseMap);
//		Set<String> eventCodes = new Set<String>();
//		for(LodgementPointMapping__c m: [select SAPEMEventCode__c from LodgementPointMapping__c LIMIT 100]){
//			eventCodes.add(m.SAPEMEventCode__c);
//		}
//		System.debug('XXXBWXXX:eventCodes:'+eventCodes);
//		Map<String, EventMessage__c> eventMessages = new Map<String, EventMessage__c>();
//		for(EventMessage__c e: [select Article__c, EventType__c,Facility__c from EventMessage__c where Facility__c != null AND Article__c in :articleIdCaseMap.keySet() and EventType__c in :eventCodes order by Article__c,CreatedDate]){
//			if(!eventMessages.containsKey(e.Article__c)){
//				eventMessages.put(e.Article__c, e);
//			}
//		}
//		System.debug('XXXBWXXX:eventMessages:'+eventMessages);
//		List<Case> casesThatNeedUpdate = new List<Case>();
//		for(String articleId: articleIdCaseMap.keySet()){
//			EventMessage__c e = eventMessages.get(articleId);
//			if(e != null) {
//				for(Case c: articleIdCaseMap.get(articleId)){
//					c.Lodgement_Network__c = e.Facility__c;
//					c.Bypass_Data_enforcement__c = true;
//					casesThatNeedUpdate.add(c);
//				}
//			}
//		}
//		if(!casesThatNeedUpdate.isEmpty()){
//			update casesThatNeedUpdate;
//		}
//	}
	
}