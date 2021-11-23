@istest 
private class EntitlementRuleEditExtControllerTests {
	
	static testMethod void controllerTest(){	 
		Entitlement_Rule__c erule = new Entitlement_Rule__c(Entitlement_Rule_Name__c='test');
		ApexPages.StandardController controller = new ApexPages.StandardController(erule); 		
		EntitlementRuleEditExtController ctrl = new EntitlementRuleEditExtController(controller);
		ctrl.addFilter();
		ctrl.selectedIndex = 0;		
		ctrl.assignFieldType();
		ctrl.filters[0].fieldName = 'closed_date__c';
		ctrl.filters[0].operator = '=';		
		ctrl.assignFieldType();
		ctrl.filters[0].tempCase.DatePosted__c = date.today();
		ctrl.saveNow();
		ctrl.selectedIndex = 1;		
		ctrl.filters[1].fieldName = 'slaexitdate';
		ctrl.filters[1].operator = '=';		
		ctrl.assignFieldType();
		ctrl.filters[1].tempCase.ClosedDate = Datetime.now();
		ctrl.saveNow();
		ctrl.selectedIndex = 2;		
		ctrl.filters[2].fieldName = 'billing_number__c';
		ctrl.filters[2].operator = '=';		
		ctrl.assignFieldType();
		ctrl.filters[2].fieldValue = '123';
		ctrl.saveNow();
		
		Escalation_Hierarchy__c esc = new Escalation_Hierarchy__c(Name='test1');
		insert esc;
		Entitlement_Rule__c erule1 = new Entitlement_Rule__c(Entitlement_Rule_Name__c='test1', Escalation_Hierarchy__c=esc.id, Rule__c='closed_date__c>1-30-2014||customer_emoticon_value__c=annoyed||slaexitdate<3-12-2014 03:30 PM');
		insert erule1;		
		ApexPages.StandardController controller2 = new ApexPages.StandardController(erule1); 		
		EntitlementRuleEditExtController ctrl2 = new EntitlementRuleEditExtController(controller2);
		
		// insert existing rule
		try {
			Entitlement_Rule__c erule2 = new Entitlement_Rule__c(Entitlement_Rule_Name__c='test2', Escalation_Hierarchy__c=esc.id, Rule__c='customer_emoticon_value__c=annoyed||closed_date__c>1-30-2014||slaexitdate<3-12-2014 03:30 PM');
			insert erule2;
		} catch(Exception ex) {	
			Boolean duplicateError = ex.getMessage().contains('Duplicate rule found');
			System.assert(duplicateError);
		}
	}
	
}