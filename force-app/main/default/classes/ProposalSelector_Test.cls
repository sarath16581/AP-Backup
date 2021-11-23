/* @author Nathan Franklin
 * @date 2020-10-06
 * @group Tests
 * @tag Selector
 * @tag ProposaltSelector 
 * @domain Core
 * @description Test Class covering ProposaltSelector 
 * @changelog
 * 2020-10-06 - Shashwat.Nath@austpost.com.au - Created
 */
@IsTest
public with sharing class ProposalSelector_Test {
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
            ProposalSelector  selector = ProposalSelector.newInstance();
            QueryBuilder qb = selector.newQueryBuilder();
            String soql = qb.toSoqlString();
            System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Apttus_Proposal__Proposal__c\\b').matcher(soql).find(), 'Resulting query does not select from Apttus_Proposal__Proposal__c');
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
            ProposalSelector selector = ProposalSelector.newInstance(1, new Set<SObjectField>());
            QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ProposalSelector.Options.WITH_OWNER});
            String soql = qb.toSoqlString();
            System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom Apttus_Proposal__Proposal__c\\b').matcher(soql).find(), 'Resulting query does not select proposal owner fields');
            
            qb = selector.newQueryBuilder(new Set<Object>{ProposalSelector.Options.WITH_OWNER});
            soql = qb.toSoqlString();
            System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom Apttus_Proposal__Proposal__c\\b').matcher(soql).find(), 'Resulting query does not select proposal owner fields');
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
       
        Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert account;
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
        insert primaryContact ;
        Apttus_Proposal__Proposal__c apttusProposal = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, false)[0];
        insert apttusProposal;  
        
        Set<Id> proposalId = new Set<Id>{apttusProposal.Id};
        // =====================================
        // Stubbing
        // =====================================
        // None!
        
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
            ProposalSelector  selector = ProposalSelector.newInstance(1);
            Map<Id, Apttus_Proposal__Proposal__c > results = selector.selectById(proposalId);            
            System.assertEquals(1, results.size(), 'Expected result size of 1');
            results = selector.selectById(proposalId, new Set<Object>{ProposalSelector.Options.WITH_OWNER});
            System.assertEquals(1, results.size(), 'Expected result size of 1');
        Test.stopTest();
    }
    
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

         ProposalSelector selector = ProposalSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
            Apttus_Proposal__Proposal__c.SObjectType => new Set<SObjectField>{Apttus_Proposal__Proposal__c.Name}
        });
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ProposalSelector.Options.WITH_OWNER, ProposalSelector.Options.WITH_RECORDTYPE});
        String soql = qb.toSoqlString();
        System.assertEquals(false, Pattern.compile('(?ism)Name.*?\\bfrom Apttus_Proposal__Proposal__c \\b').matcher(soql).find(), 'Resulting query does not select ABN field: ' + soql);

        Test.stopTest();

    }

}