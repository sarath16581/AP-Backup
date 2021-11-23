@isTest
private class BatchableEventMessageEventIdUpdater_Test {
	static testMethod void testBatch() {
		Article__c a = new Article__c();
		a.Name = '12345';
		a.ArticleId__c = '12345';
		insert a;
		
		DateTime dt = System.now();
		
		EventMessage__c em = new EventMessage__c();
		em.Article__c = a.Id;
		em.EventType__c = 'ET';
		em.ActualDateTime__c = dt;
		em.SenderID__c = 'SI';
		em.EventId__c = a.ArticleID__c + em.EventType__c + em.ActualDateTime__c.format('ddMMyyyyHHmmssSSS', 'Australia/Melbourne') + em.SenderID__c;
		insert em;
		        
        Test.startTest();
        BatchableEventMessageEventIdUpdater.run();
        Test.stopTest();
        
        em = [SELECT Article__r.ArticleID__c, EventType__c, ActualDateTime__c, SenderID__c, EventId__c FROM EventMessage__c WHERE Id = :em.Id];
        
        
        System.assertEquals(em.Article__r.ArticleID__c + em.EventType__c + em.ActualDateTime__c.formatGMT('ddMMyyyyHHmmssSSS') + em.SenderID__c, 
        		em.EventId__c);
    }
}