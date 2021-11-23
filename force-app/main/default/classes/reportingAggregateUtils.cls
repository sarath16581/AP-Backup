/* 
 * Report Aggregate Util class built by Carl Vescovi (Australia Post) 14/11/11
 * Purpose of the Class is to provide two methods - deleteAggegates and generateAggregates
 * Aggregates are custom object records of 'Report Aggregate' sObject, that exists to 
 * pull together opportunity, line item, product and other information in a way that allows std
 * reporting engine to generate a weekly summary of top 3 OLI values and Oppty details per product family.
 * this is a requirement of the Sales Management Team reporting pack for R1
 * 
 * May-2015:  scherukuwada@salesforce.com	Added LIMIT 100
 * 2021-08-06 seth.heang@auspost.com.au     Migrate test method to reportingAggregateUtils_Test Apex Class, as part of API version uplift effort
 */

public class reportingAggregateUtils {

// delete all pre-existing records

    public static void deleteAggregates() {
        // remove existing
        List<reportAggregate__c> delList = new List<reportAggregate__c>();
        delList = [Select id from reportAggregate__c LIMIT 100];
        if (delList.size()>0) delete delList;
    }


    public static void generateAggregatesForFamily() {
        // generate reportAggregate records for the calendar week prior
        
        // scheduled logic
        
        // build a map of user to role
        Map<Id,String> userRoleMap = new Map<Id,String>();
        for(List<User> userList :[ Select id, Company_Role__c from User where IsActive = TRUE and isPortalEnabled =false]) {
            for(User u : userList) userRoleMap.put(u.id, u.Company_Role__c);
        }

        // get a list of the active products 
        Id stdPriceBook = [Select id from PriceBook2 where Name ='Standard Price Book' limit 1].id;
        Map<Id,String> productFamilyMap = new Map<Id,String>();
        for(List<PricebookEntry> pbeList : [Select Product2.Family, Product2.Id from PricebookEntry where Pricebook2Id =: stdPriceBook and Product2.IsActive = TRUE]) {
            for(PricebookEntry p : pbeList) productFamilyMap.put(p.Product2.Id, p.Product2.Family);
        }
        
        // now have a list of the Products, need to get highest grossing from previous week

        // date range to check
        Date startdate = date.today().toStartofWeek().addDays(-7); // get first day of last week 
        Date enddate = startdate.addDays(7); // end date of week

        // query for top 3 grossing OLIs where product is in the pfamily set

        // first grab all the oli's from closed won opps from last week, ordered highest value to lowest
        
        Map<String,Integer> pfamilyCount = new Map<String,Integer>(); // used to track count per product family
        List<OpportunityLineItem> oliUpdates = new List<OpportunityLineItem>(); // used to track ids of olis we'll flag as being top value

        for(List<OpportunityLineItem> oliList : [Select o.Opportunity.Prorata_Rev_week_before__c, 
                                            o.Opportunity.Annual_Rev_week_before__c,
                                            o.Opportunity.Prorata_Rev_last_week__c, 
                                            o.Opportunity.Annual_Rev_last_week__c, 
                                            o.Opportunity.IsWon, 
                                            o.Opportunity.IsClosed, 
                                            o.Opportunity.CloseDate, 
                                            o.Opportunity.Amount, 
                                            o.Opportunity.Id, 
                                            o.Opportunity.OwnerId,
                                            o.OpportunityId,
                                            o.TotalPrice, 
                                            o.Id,
                                            o.PricebookEntry.Product2Id 
                                            From OpportunityLineItem o where 
                                            o.Opportunity.IsClosed = true and 
                                            o.Opportunity.IsWon = true and
                                            o.Opportunity.CloseDate >=:startdate and 
                                            o.Opportunity.CloseDate<:enddate
                                            ORDER By o.TotalPrice DESC]) {
                
                for(OpportunityLineItem o : oliList) {
                    // the following section focuses on grouping top 3 olis by product family
                    //
                    Integer c = 0;
                    // this next bit maintains a count of up to 3 'hits' of a oppty line item per product family. 
                    if (pfamilyCount.containskey(productFamilyMap.get(o.PriceBookEntry.Product2Id))) { c = pfamilyCount.get(productFamilyMap.get(o.PriceBookEntry.Product2Id)); }
                        if (c<3) 
                             { c = c + 1;
                                pfamilyCount.put(productFamilyMap.get(o.PriceBookEntry.Product2Id),c); 
                                oliUpdates.add(o); 
                    }
                    // - end of product family grouping logic
                    
                 
                } // end of oliList loop
                
                
                
            }
        

        // now we have a list of olis that are all top 3 in their product family for the previous week closed won opptys.
        // need to now generate a list of reporting aggregate records to use for reporting purposes.
        deleteAggregates(); // first remove all the existing aggregates.
        
        List<reportAggregate__c> newAggregates = new List<reportAggregate__c>();
        
        // now cleared, generate and insert the new list for reporting
        for(OpportunityLineItem oli : oliUpdates) {
            newAggregates.add(new reportAggregate__c(Opportunity__c = oli.Opportunity.id,
                                                     Product__c = oli.PricebookEntry.Product2Id,
                                                     Total_Value__c = oli.TotalPrice,
                                                     Product_Family__c = productFamilyMap.get(oli.PricebookEntry.Product2Id)
                                                     ));
        // TODO - need to fix the annualised value reference. Suggest this is done using workflow for now.  
            
        }
        
        
        
        
        if (newAggregates.size()>0) insert newAggregates;
    }
    
    
    public static void generateAggregatesforSector() {
        // generate reportAggregate records for the calendar week prior
        
        // scheduled logic
        
        // build a map of user to role
        Map<Id,String> userToSectorMap = new Map<Id,String>();
        for(List<User> userList :[ Select id, Sector__c from User where IsActive = TRUE and IsPortalEnabled = false]) {
            for(User u : userList) userToSectorMap.put(u.id, u.Sector__c);
        }

        // now have a map, need to get highest value opptys from previous week

        // date range to check
        Date startdate = date.today().toStartofWeek().addDays(-7); // get first day of last week 
        Date enddate = startdate.addDays(7); // end date of week

        // query for closed won opptys from last week

        Map<String,Integer> sectorCount = new Map<String,Integer>(); // used to track count per product family
        List<Opportunity> opptyUpdates = new List<Opportunity>(); // used to track ids of olis we'll flag as being top value

        for(List<Opportunity> oList : [Select id, Amount, OwnerId From Opportunity where 
                                            IsClosed = true and 
                                            IsWon = true and
                                            CloseDate >=:startdate and 
                                            CloseDate<:enddate
                                            ORDER By Amount DESC]) {
                for(Opportunity o : oList) {
                    // the following section focuses on grouping top 3 opptys by owner (user) sector
                    //
                    Integer c = 0;
                    // this next bit maintains a count of up to 3 'hits' of a oppty line item per product family. 
                    if (sectorCount.containskey(userToSectorMap.get(o.OwnerId))) { c = sectorCount.get(userToSectorMap.get(o.OwnerId)); }
                        if (c<3) 
                             { c = c + 1;
                                sectorCount.put(userToSectorMap.get(o.OwnerId),c); 
                                opptyUpdates.add(o); 
                        }
                 } // end of o loop
        }
        
        // now we have a list of opptys that are all top 3 in their sector for the previous week closed won opptys.
        // need to now generate a list of reporting aggregate records to use for reporting purposes.
        
        //deleteAggregates(); // first remove all the existing aggregates. CV - This step not required as is done in other sibling method
        
        List<reportAggregate__c> newAggregates = new List<reportAggregate__c>();
        
        // now cleared, generate and insert the new list for reporting
        for(Opportunity o : opptyUpdates) {
            newAggregates.add(new reportAggregate__c(Opportunity__c = o.id,
                                                     Amount__c = o.Amount,
                                                     Sector__c = userToSectorMap.get(o.OwnerId)
                                                     ));
        
        }
        if (newAggregates.size()>0) insert newAggregates;
    }
    
    
    // this class used by a visualforce page command button - during manual testing. TODO - automate on a weekly scheduled apex job.
    public PageReference build(){
        generateAggregatesForFamily();
        generateAggregatesforSector();
        return null;
    }
    
    
    /*
     * Following Summer '13 release or API 28.0 or later, 
     * Test methods are no longer be able to compile in the same Apex class. Therefore, the test code is now moved to reportingAggregateUtils_Test()
     * Source: https://developer.salesforce.com/blogs/engineering/2013/04/apex-test-code-segregation
     *
    private static testMethod void testAggregatorUtils() {
        // setup data for testing
        // retrieve existing product, pricebook (if required), pricebook entry
        List<User> userList = [Select id, UserRole.Name from User where isActive = TRUE Limit 2];
        Id sPBId = [Select p.Name, p.Id From Pricebook2 p where p.Name = 'Standard Price Book' limit 1].id;
        List<PriceBookEntry> pbeList = new List<PriceBookEntry>([Select id from PriceBookEntry where Pricebook2Id =:sPBId limit 3]);
        
        // now insert account, opptys and oppty line items
        RecordType rectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        //create account
        Account ca=new Account(name='test1', phone='123', email__c='test@test.com', recordtypeid=rectype.id);
        insert ca;
        
        //create opportunity
        Opportunity opp=new Opportunity(name='test opp', accountid=ca.Id, stagename='Identify', closedate=date.today(), Pricebook2Id = sPBId);
        insert opp;
        
        // add oppty line items
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for(PricebookEntry pbe : pbeList) { 
            oliList.add(new OpportunityLineItem(OpportunityId = opp.id, PricebookEntryId = pbe.id, Quantity = 1, UnitPrice = 2));
        }
        
        // now run the aggregator via page button
        reportingAggregateUtils rau = new reportingAggregateUtils();
        rau.build();
        
        
    }*/
    
    
}