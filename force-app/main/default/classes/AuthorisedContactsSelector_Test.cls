/***
 * @author Madhusudhan
 * @date 2021-06-28
 * @group Tests
 * @domain Core
 * @description: Test Class covering AuthorisedContactsSelector
 * @changelog
 * 2023-11-20 - Steve L - added test for selectByCaseId
 * 2024-04-25 - Vasu Gorakati - Added test method for selectByCaseId
 */

 @IsTest
 private class AuthorisedContactsSelector_Test {
   /**
	* Test:
	*  Ensures that the selectors QueryBuilder is generating the correct output
	*/
   @IsTest
   private static void testEnsureQueryBuilderProducesCorrectString() {
	 // =====================================
	 // Data Preparation
	 // =====================================
	 // None!
 
	 // =====================================
	 // Stubbing
	 // =====================================
	 // None!
 
	 // =====================================
	 // Testing
	 // =====================================
	 Test.startTest();
 
	 AuthorisedContactsSelector selector = AuthorisedContactsSelector.newInstance();
	 QueryBuilder qb = selector.newQueryBuilder();
	 String soql = qb.toSoqlString();
 
	 System.assertEquals(
	   true,
	   Pattern.compile('(?ism)\\bfrom AuthorisedContacts__c\\b').matcher(soql).find(),
	   'Resulting query does not select from CaseMilestone: ' + soql
	 );
 
	 Test.stopTest();
   }
 
   /**
	* Executes a query to ensure it returns expected results with actual inserted data
	*/
   @IsTest
   private static void testSelectorIntegration() {
	 // =====================================
	 // Data Preparation
	 // =====================================
 
	 // create a case to assign to the authorised contact
	 List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
	 cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
 
	 // =====================================
	 // Testing
	 // =====================================
 
	 test.startTest();
 
	 insert cases;
 
	 // create an authorised contact and assign the case
	 AuthorisedContacts__c authCon = new AuthorisedContacts__c();
	 authCon.First_Name__c = 'Test';
	 authCon.Last_Name__c = 'AuthorisedContact';
	 authCon.Initial_Contact__c = true;
	 authCon.Case__c = cases[0].Id;
 
	 insert authCon;
 
	 Map<Id, Case> casesContacts = CasesSelector.newInstance()
	   .selectById(new Set<Id>{ cases[0].Id }, new Set<Object>{ CasesSelector.Options.WITH_CHILDINITIALCONTACT });
	 List<AuthorisedContacts__c> authContactList = casesContacts.get(cases[0].Id).Authorised_Contacts__r;
	   
	 Set<SObjectField> authContactFields = new Set<SObjectField>{AuthorisedContacts__c.Id, AuthorisedContacts__c.Initial_Contact__c};
 
	 AuthorisedContactsSelector authConsSelector = AuthorisedContactsSelector.newInstance(authContactFields);
	 
	 List<AuthorisedContacts__c> authorisedContacts = authConsSelector.selectByCaseId(new Set<Id>{cases[0].Id});
	 List<AuthorisedContacts__c> authContacts = AuthorisedContactsSelector.newInstance()
	  .selectByCaseIdOrderByName(new Set<Id>{ cases[0].Id }, new Set<Object>());
	 test.stopTest();
 
	 // ensure the query is producing correct result
	 System.assertEquals(1, authContactList.size(), 'Expected result size of 1');
	 System.assertEquals(1, authorisedContacts.size(), 'Expected result size of 1');
	 System.assertEquals(1, authContacts.size(), 'Expected result size of 1');
   }
 }