@isTest
public with sharing class SocialPostUpdateCaseTriggerTest {
	
	@isTest private static void testTrigger() {
	
		// create a Case
		Case c = new Case(subject='My Case', Type='General Enquiry', ProductCategory__c = 'Domestic Parcels', Origin = 'Phone', status='On Hold');
		insert c;
		
		// create social post
		SocialPost sp = new SocialPost(name='My Tweet', content='My Content', isOutbound = false, posted=dateTime.now(), parentId=c.Id);
		insert sp;
	
	}

}