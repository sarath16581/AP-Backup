/**
 * @author Paul Perry
 * @domain Core
 * @description Test class for CreditSuspectGenericModule 
 **/
@isTest
class CreditSuspectGenericModule_Test {
   
	@isTest
	static void testDoBFormatting() {
		// =====================================
		// Data
		// =====================================
		Date csDoB = Date.newInstance(1980, 1, 1);
		String formattedDoB = DateTime.newInstanceGmt(
			csDoB,
			Time.newInstance(0, 0, 0, 0)
		).format('yyyy-MM-dd');

		Id csId = fflib_IDGenerator.generate(CreditSuspect__c.SObjectType);

		Map<String,Object> csRecordMap =  new Map<String,Object>{
			String.valueOf(CreditSuspect__c.Birthdate__c) => 'old value',
			String.valueOf(CreditSuspect__c.FirstName__c) => 'First',
			String.valueOf(CreditSuspect__c.LastName__c) => 'Last',
			String.valueOf(CreditSuspect__c.Phone__c) => '0400000000',
			String.valueOf(CreditSuspect__c.PostCode__c) => '3000',
			String.valueOf(CreditSuspect__c.State__c) => 'VIC',
			String.valueOf(CreditSuspect__c.StreetAddress__c) => '287 Elizabeth St',
			String.valueOf(CreditSuspect__c.Suburb__c) => 'MELBOURNE',
			String.valueOf(CreditSuspect__c.Email__c) => 'test@example.com',
			String.valueOf(CreditSuspect__c.Date_of_Birth__c) => csDoB
		};

		// new CreditSuspect__c to verify insert
		List<CreditSuspect__c> insertCreditSuspects = new List<CreditSuspect__c>{
			(CreditSuspect__c)ApplicationTestDataFactory.setUnwritableFields(
				CreditSuspect__c.SObjectType.newSObject(),
				csRecordMap
			)
		};

		// new CreditSuspect__c to verify update
		List<CreditSuspect__c> updateCreditSuspects = new List<CreditSuspect__c>{
			(CreditSuspect__c)ApplicationTestDataFactory.setUnwritableFields(
				CreditSuspect__c.SObjectType.newSObject(csId),
				csRecordMap
			)
		};

		// existing CreditSuspect__c to verify update
		List<CreditSuspect__c> existingCreditSuspects = new List<CreditSuspect__c>{
			(CreditSuspect__c)ApplicationTestDataFactory.setUnwritableFields(
				CreditSuspect__c.SObjectType.newSObject(csId),
				csRecordMap
			)
		};

		// Difference in Date_of_Birth__c field
		existingCreditSuspects[0].Date_of_Birth__c = csDob.addDays(-1);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CreditSuspectGenericModule.newInstance().onBeforeInsert(insertCreditSuspects, mockUow);		
		CreditSuspectGenericModule.newInstance().onBeforeUpdate(
			updateCreditSuspects,
			new Map<Id,CreditSuspect__c>(existingCreditSuspects),
			mockUow
		);
		
		Test.stopTest();

		System.assertEquals(formattedDoB, insertCreditSuspects[0].Birthdate__c, 'Incorrect DoB format');
		System.assertEquals(formattedDoB, updateCreditSuspects[0].Birthdate__c, 'Incorrect DoB format');
	}
}