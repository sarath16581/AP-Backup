/* Old Class

  2015-05-28 - C.McIntyre - Added "with sharing" as part of security audit.
  2022-03-30   Naveen Rajanna  REQ2782290 - Changed api version to 52
*/

public with sharing class OpportunitySummaryController {
    
    private final Opportunity opp;
    private Integer itemcount = 0;    
    
    public OpportunitySummaryController(ApexPages.StandardController stdController) {
        this.opp = (Opportunity) stdController.getRecord();
    }

    public Boolean OffTheShelf{
        get{
            if (OffTheShelf==null) itemcount = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId=:opp.Id and Off_the_shelf_check__c=false].size();
            return itemcount == 0;
        }set;
    }        
}