/* @author Nasir Jawed
* @date 2022-12-07
* @group Selector
* @tag Selector
* @tag Apttus__APTS_Related_Agreement__c 
* @domain Apttus
* @description APT_RelatedAgreementsSelector_Test to validate Related Agreement
*/

@IsTest
public class APT_RelatedAgreementsSelector_Test {

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */      
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString(){ 
		Test.startTest();
		APT_RelatedAgreementsSelector selector = APT_RelatedAgreementsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus__APTS_Related_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select from agreement');
					
		Test.stopTest();                    

	}

	/**
	 * Test:
	 *  Ensures that the selectors method is returning the correct query result
	 */
	@IsTest
	private static void testEnsureSelectorMethodsReturnCorrectResult() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		ID testRecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();

		//create Agreement to set contract from agreement for related agreement
		Apttus__APTS_Agreement__c agreementLetter= APT_TestDataFactory.getAgreementRecord(1,false)[0];       
		agreementLetter.Included_Product_Lines__c = 'Print Post';
		agreementLetter.RecordTypeID = testRecordTypeID;         
		agreementLetter.APT_Pricing_Category__c='Offline Rates'; 
		agreementLetter.Apttus__Subtype__c='Letter of Intent'; 
		agreementLetter.APT_Contract_Type__c='Migrated Contract';      
		insert agreementLetter;
		//create aggrement to set contract from agreement for related agreement
		Apttus__APTS_Agreement__c agreementLetter2 = APT_TestDataFactory.getAgreementRecord(1, false)[0];        
		agreementLetter2.Included_Product_Lines__c = 'Workforce Verification';
		agreementLetter2.RecordTypeID = testRecordTypeID ;          
		agreementLetter2.APT_Pricing_Category__c='Offline Rates'; 
		agreementLetter2.Apttus__Subtype__c='Letter of Intent'; 
		agreementLetter2.APT_Contract_Type__c='Migrated Contract';        
		insert agreementLetter2;


		//create related agreement and set to and from contracts
		List<Apttus__APTS_Related_Agreement__c> relAgreementList = new List<Apttus__APTS_Related_Agreement__c>();


		Apttus__APTS_Related_Agreement__c relatedAgreementLetter = APT_TestDataFactory.getRelatedAgreementRecord(1,agreementLetter.id,agreementLetter2.id,false)[0];       
		insert relatedAgreementLetter;
		relAgreementList.add(relatedAgreementLetter);  
		Test.startTest();
		APT_RelatedAgreementsSelector selector = APT_RelatedAgreementsSelector.newInstance();
		List<Apttus__APTS_Related_Agreement__c> results = selector.selectByAgreementId(new Set<ID>{agreementLetter2.id},new Set<Object>{APT_RelatedAgreementsSelector.Options.WITH_AGREEMENT}); 
		system.assertEquals(agreementLetter2.Apttus__Subtype__c,'Letter of Intent', 'Incorrect sub type');    
		Test.stopTest();

	}
}