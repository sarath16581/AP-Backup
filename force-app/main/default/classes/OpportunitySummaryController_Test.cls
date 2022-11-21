/**
 * @author Naveen Rajanna
 * @date 2022-03-29
 * @group Tests
 * @description 
 * @changelog
 * 2022-03-30   Naveen Rajanna  REQ2782290 - Changed api version to 52
 */
@IsTest
private class OpportunitySummaryController_Test {
    
    public static testmethod void testOppSummary(){        
        Profile prof = [SELECT Id,Name FROM profile where Name = 'System Administrator' LIMIT 1];
        User usr = TestUtility.createUser('Wayne',prof.id,null);
        insert usr;
        System.runAs(usr){
            RecordType rectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
            Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            Update standardPricebook;
            
            //create account
            Account ca = new Account(name='test1', phone='123', email__c='test@test.com', recordtypeid=rectype.id);
            insert ca;
            
            //create product
            Product2 prod = new Product2(name='test prod', off_the_shelf__c=false, isactive=true);
            insert prod;
            
            //create pricebook entry
            PricebookEntry pentry = new PricebookEntry(pricebook2id=standardPricebook.id, product2id=prod.id, unitprice=0, isactive=true);
            insert pentry;
            
            //create opportunity
            Opportunity opp = new Opportunity(name='test opp', accountid=ca.Id, stagename='Identify', Probability = 3, closedate=date.today());
            insert opp;
            
            OpportunityLineItem oppitem = new OpportunityLineItem(opportunityid=opp.id, off_the_shelf_check__c=false, 
                            pricebookentryid=pentry.id, quantity=1, totalprice=0,
                    Contract_End_Date__c = system.today()+10,
                    Contract_Start_Date__c = system.today());
            insert oppitem;
            
            Test.startTest();
            //Test coverage for the VF page
            PageReference pageRef = Page.LinkAccount;
            pageRef.getParameters().put('id', opp.id); 
            Test.setCurrentPageReference(pageRef);
    
            //Create an instance of the controller
            Apexpages.StandardController stdController = new Apexpages.StandardController(opp);                            
            OpportunitySummaryController oppSum = new OpportunitySummaryController(stdController);
            
            //oppSum.OffTheShelf;
            oppSum.OffTheShelf = null;
            
            system.AssertEquals(false, oppSum.OffTheShelf);
            
            Test.stopTest();
        }
    }
}