/***
 * @author
 * @date
 * @domain Core
 * @description Test class for CompensationSelector
 * @changelog
 * 2023-07-25 - Hasantha Liyanage - Modified
 */
@isTest
private with sharing class CompensationSelectorTest
{
    @TestSetup
    private static void setUpCampFire()
    {
        // setting
        Consumer_Help_and_Support__c hs = new Consumer_Help_and_Support__c();
        hs.Encoded_Crypto_Key__c = 'APa7UFswqp/Xp8/v9VAO88nS0vOdDQC+jBUZCpCyYOM=';
        hs.Compensation_Max_Attemps__c = 5;
        insert hs;
        // account
        Account a = TestDataProvider.createAccount('Account', 1)[0];
        insert a;

        // contact
        Contact c = TestDataProvider.createContact('Contact', a.Id, null);
        insert c;

        // case
        Case iCase = TestDataProvider.createCase('subject', 'description', null);
        iCase.ContactId = c.Id;
        iCase.ReferenceID__c = 'REF001';
        insert iCase;

        // EFT record type
        RecordType rc = [SELECT Id FROM RecordType WHERE DeveloperName = 'EFT' AND SobjectType = 'Compensation__c'];

        // compensation
        Compensation__c compensation = new Compensation__c();
        compensation.Contact__c = c.Id;
        compensation.RecordTypeId = rc.Id;
        compensation.Case__c = iCase.Id;
        compensation.Compensation_Amount__c = 50;
        compensation.Cover_Type__c = 'T&C Cover	';
        insert compensation;
    }

    @isTest
    private static void testEnsureQueryBuilderProducesCorrectString()
    {
        Test.startTest();

		CompensationSelector selector = CompensationSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Compensation__c\\b').matcher(soql).find(), 'Resulting query does not select from Compensation');

		Test.stopTest();
    }

    @isTest
    private static void testWithRelatedCase()
    {
        CompensationSelector selector = CompensationSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{CompensationSelector.Options.WITH_CASE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Case__r\\..*?\\bfrom Compensation__c\\b').matcher(soql).find(), 'Resulting query does not select Case fields');
    }

    @isTest
    private static void testWithRelatedRecordType()
    {
        CompensationSelector selector = CompensationSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{CompensationSelector.Options.WITH_RECORD_TYPE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)RecordType\\..*?\\bfrom Compensation__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
    }

    @isTest
    private static void testOverrideRelatedCase()
    {
        CompensationSelector selector = CompensationSelector.newInstance(0);
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{CompensationSelector.Options.WITH_OVERRIDE_CASE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Case__r\\..*?\\bfrom Compensation__c\\b').matcher(soql).find(), 'Resulting query does not select Case fields');
    }

    @isTest
    private static void testOverrideRelatedRecordType()
    {
        CompensationSelector selector = CompensationSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{CompensationSelector.Options.WITH_OVERRIDE_RECORD_TYPE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)RecordType\\..*?\\bfrom Compensation__c\\b').matcher(soql).find(), 'Resulting query does not select Case fields');
    }

    @isTest
    private static void testFieldOverride_1()
    {
        CompensationSelector selector = CompensationSelector.newInstance(0, new Set<SObjectField>{Compensation__c.Name});
        QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Name.*?\\bfrom Compensation__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);
    }

    @isTest
    private static void testFieldOverride_2()
    {
        CompensationSelector selector = CompensationSelector.newInstance(new Set<SObjectField>{Compensation__c.Name});
        QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Name.*?\\bfrom Compensation__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);
    }

    @isTest
    private static void testGetCompensationByToken()
    {
        String token = '123456789';
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];
        compensation.Compensation_Form_Token__c = token;
        update compensation;

        CompensationSelector selector = new CompensationSelector();

        Set<Object> options = new Set<Object>{
            CompensationSelector.Options.WITH_OVERRIDE_CASE, 
            CompensationSelector.Options.WITH_OVERRIDE_RECORD_TYPE
        };

        List<Compensation__c> compensations = selector.getByToken(token, options);

        System.assertEquals(1, compensations.size());
    }

    @isTest
    private static void testGetCompensationByToken_WrongToken()
    {
        String token = '123456789';
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];
        compensation.Compensation_Form_Token__c = token;
        update compensation;

        CompensationSelector selector = new CompensationSelector();

        Set<Object> options = new Set<Object>{
            CompensationSelector.Options.WITH_OVERRIDE_CASE, 
            CompensationSelector.Options.WITH_OVERRIDE_RECORD_TYPE
        };

        List<Compensation__c> compensations = selector.getByToken(token + '_', options);

        System.assertEquals(0, compensations.size());
    }

    @isTest
    private static void testGetCompensationById()
    {
        String token = '123456789';
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];
        compensation.Compensation_Form_Token__c = token;
        update compensation;

        CompensationSelector selector = new CompensationSelector();

        Set<Object> options = new Set<Object>{
            CompensationSelector.Options.WITH_OVERRIDE_CASE, 
            CompensationSelector.Options.WITH_OVERRIDE_RECORD_TYPE
        };

        List<Compensation__c> compensations = selector.getById(compensation.Id, options);

        System.assertEquals(1, compensations.size());
    }

    @isTest
    private static void testGetCompensationById_WrongId()
    {
        String token = '123456789';
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];
        compensation.Compensation_Form_Token__c = token;
        update compensation;

        CompensationSelector selector = new CompensationSelector();

        Set<Object> options = new Set<Object>{
            CompensationSelector.Options.WITH_OVERRIDE_CASE, 
            CompensationSelector.Options.WITH_OVERRIDE_RECORD_TYPE
        };

        List<Compensation__c> compensations = selector.getById(compensation.Id + '_', options);

        System.assertEquals(0, compensations.size());
    }


    @isTest
    private static void testSelectByCaseIds(){

        String subject = 'subject';
        Case cse = [SELECT Id FROM Case];
        cse.Subject = subject;

        CompensationSelector selector = new CompensationSelector();

        List<Compensation__c> compensations = selector.selectByCaseIds(new Set<Id>{cse.Id}, new Set<Object>());

        System.assertEquals(1, compensations.size());

    }

    // @isTest
    // private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields()
    // {
    //     Test.startTest();

	// 	CompensationSelector selector = CompensationSelector.newInstance();

	// 	//Testing field override
	// 	CompensationSelector selectorNew = CompensationSelector.newInstance(0, new Set<SObjectField>{Compensation__c.Name});

	// 	qb = selectorNew.newQueryBuilder();
	// 	soql = qb.toSoqlString();
    //     System.debug('test :: ' + soql);
	// 	System.assertEquals(true, Pattern.compile('(?is)Name.*?\\bfrom Compensation__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);

	// 	Test.stopTest();
    // }
}