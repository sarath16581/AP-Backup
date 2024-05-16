/****************************************
 * Description: Test Class for OpportunityClosureController
 * Author: Ken McGuire
 * History
* 11.06.2023 Ken McGuire - cleanup
* 2023-08-30 - Merged changes by Ranjeewa Silva in dev - Updates to existing tests to ensure test data conforms to new sales pipeline governance validations on Opportunity.
* 2023-09-14 - Ranjeewa Silva - Removing an invalid test case. This test has been made to pass, but it has not been asserting anything meaningful.
 ********************************************/
@isTest
private class OpportunityClosureControllerTest {
	@TestSetup
	static void setupTestData(){

		//create products
		List<Product2> productList = new List<Product2>();
		Product2 bundle1 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('International Bundle', TRUE);
		productList.add(bundle1);

		Product2 bundle2 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('Road Express - STE', TRUE);
		productList.add(bundle2);

		Product2 bundle3 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('eParcel Express', TRUE);
		productList.add(bundle3);

		Product2 bundle4 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('Boxes and Bags Others', TRUE);
		productList.add(bundle4);

		insert productList;

		//Create your pricebook entry
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry pbEntry = new PricebookEntry();

		List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
		for(Product2 testProd : productList){
			pbEntry = new PricebookEntry();
			pbEntry.Pricebook2Id = pricebookId;
			pbEntry.Product2Id = testProd.Id;
			pbEntry.UnitPrice = 100.00;
			pbEntry.IsActive = true;
			pbEntryList.add(pbEntry);
		}

		insert pbEntryList;

		//Create Account
		Account organisation = new Account();
		organisation.Name = 'org1';
        organisation.RecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{'Business_Account'}).values()[0].Id;
		organisation.Type = 'Enterprise';
		organisation.ShippingCity = 'TestCity';
		organisation.ShippingState = 'TestState';
		organisation.ShippingPostalCode = '123456';
		organisation.ShippingStreet = '111 Bourke Street';
		insert organisation;

		// key contact is mandatory on opportunity
		Contact keyContact = ApplicationTestDataFactory.getContacts(1, organisation.Id, false)[0];
		insert keyContact;

		Organisation_Role__c orgRole = [ Select Id, Role_Type__c, Organisation__c from Organisation_Role__c where Organisation__c =: organisation.Id LIMIT 1];
		orgRole.Role_Type__c = 'Customer';
		update orgRole;

        //Create Opportunity 
        Opportunity opty = new Opportunity(); 
        opty.Name = 'opty1';
        opty.AccountId = organisation.Id;
        opty.Type = 'New Customer';
        opty.StageName = 'Identify';
        opty.CloseDate = date.Today();
        opty.Offering_Type__c = 'Product';
        opty.Pricebook2Id = pricebookId;
        opty.Offline_Contract_Received__c  = true;
        opty.Pre_Entry__c = true;
        opty.Description = 'test';
        opty.KeyContact__c = keyContact.Id;
        opty.Monthly_Executive_Summary__c = 'test';
        insert opty;

		OpportunityLineItem lineItem = new OpportunityLineItem();
		lineItem.OpportunityId = opty.Id;
		lineItem.Product2Id = [Select Id from Product2 where Name='Road Express - STE'].Id;
		lineItem.Contract_Start_Date__c = date.Today();
		lineItem.Contract_End_Date__c = date.Today().addDays(36);
		lineItem.Quantity = 12;
		lineItem.TotalPrice = 1200;
		insert lineItem;

		Id bidDSRRecordTypeId = [Select Id from RecordType where Name='Bids Support Request' and sObjectType='Deal_Support_Request__c'].Id;
		Id busSalesImpDSRRecTypeId = [Select Id from RecordType where Name='Bids Support Request' and sObjectType='Deal_Support_Request__c'].Id;

		Deal_Support_Request__c dsr1 = new Deal_Support_Request__c();
		dsr1.Stage__c = 'New';
		dsr1.Status__c = 'Draft';
		dsr1.Start_Date__c = date.Today();
		dsr1.Due_Date__c = date.Today().addDays(25);
		dsr1.Document_Type__c = 'RFP';
		dsr1.RecordTypeId = bidDSRRecordTypeId;
		dsr1.Opportunity__c = opty.Id;
		insert dsr1;

        Deal_Support_Request__c dsr2 = new Deal_Support_Request__c();
        dsr2.Stage__c = 'New';
        dsr2.Status__c = 'Draft';
        dsr2.Start_Date__c = date.Today();
        dsr2.Due_Date__c = date.Today().addDays(25); 
        dsr2.Document_Type__c = 'RFP'; 
        dsr2.Opportunity__c = opty.Id;
        dsr2.RecordTypeId = busSalesImpDSRRecTypeId;
        insert dsr2;

        // recording competitors mandatory on opportunity to progress to close won
        List<Competitor__c> competitors = ApplicationTestDataFactorySales.getCompetitors(1, opty.Id, false);
        insert(competitors);

        Task opportunityTask = ApplicationTestDataFactory.getTasks(1, opty.Id, false)[0];
        opportunityTask.ActivityDate=System.today();
        opportunityTask.Subject='test';
        opportunityTask.Status = 'Completed';
        insert opportunityTask;
    }

		@isTest
		static void testValidateOpportunityStage() {
		Opportunity opp = [Select Id, StageName, Next_Step__c from Opportunity where Name='opty1' LIMIT 1];
		opp.StageName = 'Qualify';
		opp.Next_Step__c = 'Confirm issues, needs and desired outcomes';
		update opp;

		opp.StageName = 'Propose';
		opp.Next_Step__c = 'Develop proposal';
		update opp;

        List<Deal_Support_Request__c> supportRequests = [Select Id, Stage__c, Status__c from Deal_Support_Request__c];
        for (Deal_Support_Request__c supportRequest: supportRequests) {
            supportRequest.Stage__c = 'Closed';
        }
        update(supportRequests);

        Test.startTest();
        OpportunityClosureController.validateOpportunityStage('Closed Won', 'Confirm issues, needs and desired outcomes', 'test comments', 'Capability', opp.Id); 
        Test.stopTest();

		Opportunity oppUpdated = [Select Id, StageName, Next_Step__c from Opportunity where Name='opty1' LIMIT 1];

		System.assertEquals(oppUpdated.StageName, 'Propose');
	}

	@isTest
	static void testUpdateOpportunityStage() {
		Opportunity opp = [Select Id, StageName, Next_Step__c from Opportunity where Name='opty1' LIMIT 1];
		opp.StageName = 'Qualify';
		opp.Next_Step__c = 'Confirm issues, needs and desired outcomes';
		update opp;

		opp.StageName = 'Propose';
		opp.Next_Step__c = 'Develop proposal';
		update opp;

        List<Deal_Support_Request__c> supportRequests = [Select Id, Stage__c, Status__c from Deal_Support_Request__c];
        for (Deal_Support_Request__c supportRequest: supportRequests) {
            supportRequest.Stage__c = 'Closed';
        }
        update(supportRequests);

        Test.startTest();
        OpportunityClosureController.updateOpportunityStage('Closed Won', 'Confirm issues, needs and desired outcomes', 'test comments', 'Capability', opp.Id); 
        Test.stopTest();

        Opportunity oppUpdated = [Select Id, StageName, Next_Step__c from Opportunity where Name='opty1' LIMIT 1]; 

        System.assertEquals(oppUpdated.StageName, 'Closed Won');
    }

    @isTest
    static void testExceptionForUpdateOpportunityStage() {

        Exception exceptionMessage;

		Opportunity opp = [Select Id, StageName, Next_Step__c from Opportunity where Name='opty1' LIMIT 1];
		opp.StageName = 'Qualify';
		opp.Next_Step__c = 'Confirm issues, needs and desired outcomes';
		update opp;

		opp.StageName = 'Propose';
		opp.Next_Step__c = 'Develop proposal';
		opp.CloseDate = date.Today().addDays(25);
		update opp;

        Test.startTest();
        try {
            OpportunityClosureController.updateOpportunityStage('Closed Won', 'Confirm issues, needs and desired outcomes', 'test comments', 'Capability', opp.Id);
        }
        catch(Exception e)
        {
            exceptionMessage = e;
        }

        Test.stopTest();

        System.assertNotEquals(null, exceptionMessage, 'Exception Should be thrown');
    }

	@isTest
	static void testgetDealSupportRequests() {

		Opportunity opp = [Select Id, StageName, Next_Step__c from Opportunity where Name='opty1' LIMIT 1];
		List<OpportunityClosureController.DealSupportWrapper> lstDSR = new List<OpportunityClosureController.DealSupportWrapper>();
		Test.startTest();
		lstDSR = OpportunityClosureController.getOpenDealSupportRequests(opp.Id);
		Test.stopTest();

		System.assertEquals(lstDSR.size(), 2);

	}

	@isTest
	static void testCloseDealSupportRequests() {

		List<Deal_Support_Request__c> lstDSR = new List<Deal_Support_Request__c>();
		lstDSR = [Select Id, Name, Stage__c, Status__c, RecordType.Name from Deal_Support_Request__c where Opportunity__r.Name = 'opty1'];
		List<OpportunityClosureController.DealSupportWrapper> wrapperLst = new List<OpportunityClosureController.DealSupportWrapper>();

		for(Deal_Support_Request__c dsr: lstDSR)
		{
			OpportunityClosureController.DealSupportWrapper wrapper = new OpportunityClosureController.DealSupportWrapper();
			wrapper.Id = dsr.Id;
			wrapper.Name = dsr.Name;
			wrapper.Stage = dsr.Stage__c;
			wrapper.Type = dsr.RecordType.Name;
			wrapperLst.add(wrapper);
		}

		Test.startTest();
		OpportunityClosureController.closeDealSupportRequests(wrapperLst);
		Test.stopTest();

		List<Deal_Support_Request__c> lstUpdateDSR = new List<Deal_Support_Request__c>();
		lstUpdateDSR = [Select Id, Name, Stage__c, Status__c, RecordType.Name from Deal_Support_Request__c where Opportunity__r.Name = 'opty1' and Stage__c = 'Closed'];

		System.assertEquals(lstUpdateDSR.size(), 2);

	}

	@isTest
	static void testExceptionForCloseDealSupportRequests() {

		Exception exceptionMessage;
		List<Deal_Support_Request__c> lstDSR = new List<Deal_Support_Request__c>();
		lstDSR = [Select Id, Name, Stage__c, Status__c, RecordType.Name from Deal_Support_Request__c where Opportunity__r.Name = 'opty1'];
		List<OpportunityClosureController.DealSupportWrapper> wrapperLst = new List<OpportunityClosureController.DealSupportWrapper>();

		for(Deal_Support_Request__c dsr: lstDSR)
		{
			OpportunityClosureController.DealSupportWrapper wrapper = new OpportunityClosureController.DealSupportWrapper();
			wrapper.Name = dsr.Name;
			wrapper.Stage = dsr.Stage__c;
			wrapper.Type = dsr.RecordType.Name;
			wrapperLst.add(wrapper);
		}

		Test.startTest();
		try {
		OpportunityClosureController.closeDealSupportRequests(wrapperLst);
		} catch (Exception e) {
		exceptionMessage = e;
		}

		Test.stopTest();

		System.assertNotEquals(null, exceptionMessage, 'Exception Should be thrown');

	}
}