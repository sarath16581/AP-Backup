/*
* Following Summer '13 release or API 28.0 or later, 
* Test methods are no longer be able to compile in the same Apex class. 
* Source: https://developer.salesforce.com/blogs/engineering/2013/04/apex-test-code-segregation
* 
* The test code below was migrated from reportingAggregateUtils Apex Class
* @changelog
* 2021-08-06 - Seth Heang - Create test class by migrating test method from reportingAggregateUtils Apex Class, as part of API version uplift effort
							Fix code coverage issue
* 2023-08-24 - Ranjeewa Silva - Updates to existing tests to ensure test data conforms to new sales pipeline governance validations on Opportunity.
* 2023-11-02 - Mahesh Parvathaneni - Updates to existing test due to validaiton introduced as part of STP-8264 - Product quantity should be more than 1
*/
@isTest
private class reportingAggregateUtils_Test {

	static testmethod void testAggregatorUtils() {
		// setup data for testing
		// retrieve existing product, pricebook (if required), pricebook entry
		List<User> userList = [Select id, UserRole.Name from User where isActive = TRUE Limit 2];
		Id priceBookId=Test.getStandardPricebookId();
		Pricebook2 pbVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebook('Standard Price Book',true);
		insert pbVar1;
		
		Product2 prod1 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('test production','1234',false);
		insert prod1;
		PriceBookEntry pbe1 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebookEntry(priceBookId, prod1.id, 1200);
		insert pbe1;
		PriceBookEntry pbe2 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebookEntry(pbVar1.id, prod1.id, 1200);
		insert pbe2;
		
		Id sPBId = [Select p.Name, p.Id From Pricebook2 p where p.Name = 'Standard Price Book' limit 1].id;
		List<PriceBookEntry> pbeList = new List<PriceBookEntry>([Select id from PriceBookEntry where Pricebook2Id =:sPBId limit 3]);
		
		// now insert account, opptys and oppty line items
		RecordType rectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
		
		//create account
		Account ca=new Account(name='test1', phone='123', email__c='test@test.com', recordtypeid=rectype.id,ShippingCity = 'TestCity',
								ShippingState = 'TestState',ShippingPostalCode = '123456');
		insert ca;
		
		Organisation_Role__c role = [SELECT id, Organisation__c, Role_Type__c from Organisation_Role__c WHERE Organisation__c=:ca.id limit 1];
		role.Role_Type__c = 'Customer';
		update role;

		Contact keyContact = ApplicationTestDataFactory.getContacts(1, ca.Id, false)[0];
		insert keyContact;
		
		//create opportunity
		Opportunity opp=new Opportunity(name='test opp', accountid=ca.Id, stagename='Identify', closedate=date.today()-7, Pricebook2Id = sPBId);
		opp.KeyContact__c = keyContact.Id;
		opp.Type = 'New Customer';
		insert opp;
		
		// add oppty line items
		List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
		for(PricebookEntry pbe : pbeList) { 
			oliList.add(new OpportunityLineItem(OpportunityId = opp.id, PricebookEntryId = pbe.id, Quantity = 10, UnitPrice = 2, Contract_End_Date__c=date.today()+7, Contract_Start_Date__c=date.today()));
		}
		insert oliList;

		List<Competitor__c> competitors = ApplicationTestDataFactorySales.getCompetitors(1, opp.Id, false);
		insert(competitors);

		Task oppTask = ApplicationTestDataFactory.getTasks(1, opp.Id, false)[0];
		oppTask.ActivityDate=System.today();
		//oppTask.Subject='test';
		oppTask.Status = 'Completed';
		insert(oppTask);
		
		// close opportunity
		opp.Offline_Contract_Received__c = true;
		opp.Hidden_Restrict_Path_Closure__c = true;
		opp.Closed_Reason__c = 'Functionality';
		opp.StageName = Constants.CLOSED_WON;
		opp.Monthly_Executive_Summary__c = 'test';
		opp.Description = 'test desc';
		update opp;
		opp.closedate=date.today()-7;
		update opp;

		// now run the aggregator via page button
		reportingAggregateUtils rau = new reportingAggregateUtils();
		rau.build();
		
		// check that reportAggregate__c is created from the OpportunityLineItem records
		List<reportAggregate__c> reportAggList = [Select id From reportAggregate__c];
		// assert that reportAggregate__c is not empty
		System.assertNotEquals(0, reportAggList.size(), 'reportAggregate__c List should be not empty');
	}
}