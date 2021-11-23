/***************************************
*    Type: Utility Class
*    Purpose: Utility Class for Opportunity Access Level
*
*    Used By: Opportunity, Opportunity Share
*    ---------------------------------------------------------------
*    History:
*
*    10-Dec-2012    Mat Isidro (Cloud Sherpas)     Created
*
****************************************/
public with sharing class OpportunityUserWrapper {

    public Id opptyId {get; set;}
    public Id userId {get; set;}

    public OpportunityUserWrapper() {
    
    }
    
    public OpportunityUserWrapper(Id oId, Id uId) {
        opptyId = oId;
        userId = uId;     
    }     

}