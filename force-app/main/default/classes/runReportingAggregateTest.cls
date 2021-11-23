/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 * 
 * * @changelog
 * 2021-08-06 - Seth Heang - uplift SF API version to 52, the class is pending for decommission in future date
*/
@isTest
class runReportingAggregateTest {
    

    // keep in mind that the methods run in schduler class already have test coverage, so simply providing
    // cover to the global schedule implementer class
    static testMethod void test() {
        List<User> userList = [Select id, UserRole.Name from User where isActive = TRUE Limit 2];
        Pricebook2 p = new Pricebook2(Name = 'Standard Price Book');
        insert p;
        List<PriceBookEntry> pbeList = new List<PriceBookEntry>([Select id from PriceBookEntry where Pricebook2Id =:p.Id limit 3]);
        
        // now insert account, opptys and oppty line items
        RecordType rectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        //create account
        Account ca=new Account(name='test1', phone='123', email__c='test@test.com', recordtypeid=rectype.id);
        insert ca;
        
        //create opportunity
        Opportunity opp=new Opportunity(Closed_Reason__c = 'test', name='test opp', Probability = 0, accountid=ca.Id, stagename='Closed Lost', closedate=date.today(), Pricebook2Id = p.Id);
        opp.StageName = 'Identify';    // 09/07 - Added for test class failure
        opp.Probability = 10;             // 09/07 - Added for test class failure
        insert opp;
        
        // add oppty line items
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for(PricebookEntry pbe : pbeList) { 
            oliList.add(new OpportunityLineItem(OpportunityId = opp.id, PricebookEntryId = pbe.id, Quantity = 1, UnitPrice = 2));
        }
        Opportunity oppy = TestDataProvider.createTestOpportunity();
        insert oppy;
        Test.startTest();
            runReportingAggregates r = new runReportingAggregates();
            String sch = '0 0 23 * * ?';
            system.schedule('Test aggregate build', sch, r);
        Test.stopTest();
    }
}