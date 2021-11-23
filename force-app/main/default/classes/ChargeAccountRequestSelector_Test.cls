/* @author Nathan Franklin
 * @date 2020-10-06
 * @group Tests
 * @tag Selector
 * @tag ProposaltSelector 
 * @domain Core
 * @description Test Class covering ChargeAccountRequestSelector
 * @changelog
 * 2020-10-06 - Shashwat.Nath@austpost.com.au - Created
 */
@IsTest
private class ChargeAccountRequestSelector_Test{

  /**
   * Test:
   *  Ensures that the selectors QueryBuilder is generating the correct output
   */
  @IsTest
  public static void testEnsureQueryBuilderProducesCorrectString() {

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

    ChargeAccountRequestSelector selector = ChargeAccountRequestSelector.newInstance();
    QueryBuilder qb = selector.newQueryBuilder();
    String soql = qb.toSoqlString();

    System.assertEquals(true, Pattern.compile('(?ism)\\bfrom APT_Charge_Account__c\\b').matcher(soql).find(), 'Resulting query does not select from charge Account');

    Test.stopTest();

  }

  /**
   * Test:
   *  Ensures that the selectors QueryBuilder is generating the correct output
   */
  @IsTest
  public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

    ChargeAccountRequestSelector selector = ChargeAccountRequestSelector.newInstance(1);
    QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ChargeAccountRequestSelector.Options.WITH_OWNER});
    String soql = qb.toSoqlString();
    System.assertEquals(true, Pattern.compile('(?ism)owner\\..*?\\bfrom APT_Charge_Account__c\\b').matcher(soql).find(), 'Resulting query does not select owner field');

    Test.stopTest();

  }

  /**
   * Test:
   *  Ensures that the selectors QueryBuilder is generating the correct output
   */
  @IsTest
  public static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

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

    ChargeAccountRequestSelector selector = ChargeAccountRequestSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
        APT_Charge_Account__c.SObjectType => new Set<SObjectField>{APT_Charge_Account__c.Name,APT_Charge_Account__c.Ownerid}
    });
    QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ChargeAccountRequestSelector.Options.WITH_OWNER, AccountsSelector.Options.WITH_RECORDTYPE});
    String soql = qb.toSoqlString();
    System.assertEquals(true, Pattern.compile('(?ism)owner.*?\\bfrom APT_Charge_Account__c\\b').matcher(soql).find(), 'Resulting query does not select owner field: ' + soql);
    System.assertEquals(true, Pattern.compile('(?ism)Name.*?\\bfrom APT_Charge_Account__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);

    Test.stopTest();

  }

  /**
   * Executes a query to ensure it returns expected results with actual inserted data
   */
  @IsTest
  public static void testSelectorIntegration() {

    // =====================================
    // Data Preparation
    // =====================================
    MockUtility.disableTriggerExecution();
    
    List<APT_Charge_Account__c> chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,false);
    insert chargeAccountRequest;
    
    Map<Id, APT_Charge_Account__c> mappedChargeAccounts = new Map<Id, APT_Charge_Account__c>(chargeAccountRequest);

    // =====================================
    // Stubbing
    // =====================================
    // None!

    // =====================================
    // Testing
    // =====================================
    Test.startTest();

    ChargeAccountRequestSelector selector = ChargeAccountRequestSelector.newInstance(1, new Set<SObjectField>());
    Map<Id, APT_Charge_Account__c> results = selector.selectById(mappedChargeAccounts.keySet());
    System.assertEquals(1, results.size(), 'Result count was wrong');

    Test.stopTest();

  }
}