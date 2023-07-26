/**
 * @description Test class for LeadConversionAutomationModule
 * @author Harry Wang
 * @date 2023-06-30
 * @group Domain
 * @domain LeadGenericDomain
 * @changelog
 * 2023-06-30 - Harry Wang - Created
*/
@IsTest
public class LeadConversionAutomationModule_Test {
	/**
	* Test:
	*  Ensure map additional fields on lead conversion is working as expected
	*/
	@IsTest
	public static void testMapAdditionalFieldsOnLeadConversion() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<Lead> leads = ApplicationTestDataFactory.getLeads(2, true);
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(2, accounts[0].Id, true);
		contacts[0].OtherCountry = 'Australia';
		accounts[0] = (Account)ApplicationTestDataFactory.setChildRelationships(accounts[0], new Map<String, List<SObject>>{'Contacts' => contacts, 'Opportunities' => opportunities});
		leads[0].Street = '123 Test Street';
		leads[0].Country = 'Australia';
		leads[0].Description = 'Test description';
		leads[0] = (Lead)ApplicationTestDataFactory.setUnwritableFields(leads[0], new Map<String, Object>{
				'IsConverted' => true,
				'ConvertedAccountId' => accounts[0].Id,
				'ConvertedContactId' => contacts[0].Id,
				'ConvertedOpportunityId' => opportunities[0].Id
		});
		leads[1] = (Lead)ApplicationTestDataFactory.setUnwritableFields(leads[1], new Map<String, Object>{'IsConverted' => false} );
		leads[1].Id = leads[0].Id;
		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector mockSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByIdWithContactsAndOpportunities((Set<Id>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject()))
				.thenReturn(accounts);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		LeadConversionAutomationModule module = new LeadConversionAutomationModule();
		module.mapAdditionalFieldsOnLeadConversion(new List<SObject>{leads[0]}, new Map<Id, Lead>{leads[1].Id => leads[1]}, mockUow);
		Test.stopTest();

		fflib_ArgumentCaptor updatableRecords = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 3)).registerDirty((SObject)updatableRecords.capture(), fflib_Match.anyBoolean(), fflib_Match.anyString());
		System.assertEquals(3, updatableRecords.getAllValues().size(), 'three objects expected');

		for (Object obj: updatableRecords.getAllValues()) {
			SObject sObj = (SObject)obj;
			if (sObj.getSObjectType() === Account.getSObjectType()) {
				System.assertEquals('123 Test Street', sObj.get('ShippingStreet'), 'Shipping street expected in Account');
				System.assertEquals('Australia', sObj.get('ShippingCountry'), 'Shipping country expected in Account');
			} else if (sObj.getSObjectType() === Contact.getSObjectType()) {
				System.assertEquals('123 Test Street', sObj.get('OtherStreet'), 'Other street expected in Contact');
				// OtherCountry is not expected as target contact already has this field populated in Data Preparation
				System.assert(sObj.get('OtherCountry') == null, 'Other Country should not exist in Contact');
			} else if (sObj.getSObjectType() === Opportunity.getSObjectType()) {
				System.assertEquals('Test description', sObj.get('Description'), 'Description expected in Opportunity');
			}
		}
	}
}