global class BatchableEventMessageEventIdUpdater implements Database.Batchable<sObject> {
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator('SELECT Article__r.ArticleID__c, EventType__c, ActualDateTime__c, SenderID__c, EventId__c FROM EventMessage__c ORDER BY LastModifiedDate DESC');
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		Map<String, EventMessage__c> emsToUpdate = new Map<String, EventMessage__c>();
		for (EventMessage__c em : (List<EventMessage__c>)scope) {
			String newId = getNewId(em);
			if (newId != em.EventId__c) {
				em.EventId__c = newId;
				if (!emsToUpdate.containsKey(newId)) {
					emsToUpdate.put(newId, em);
				}
			}
		}
		
		if (emsToUpdate.size() > 0) {
			Database.update(emsToUpdate.values(), false);
		}
	}
	
	global void finish(Database.BatchableContext BC) {		
	}

	global static Id run() {
		return Database.executeBatch(new BatchableEventMessageEventIdUpdater());
	}
	
	private String getNewId(EventMessage__c em) {
		return em.Article__r.ArticleID__c 
        	+ (em.EventType__c != null ? em.EventType__c : '')
        	+ (em.ActualDateTime__c != null ? em.ActualDateTime__c.formatGMT('ddMMyyyyHHmmssSSS') : '')
        	+ (em.SenderID__c != null ? em.SenderID__c : '');
	}
}