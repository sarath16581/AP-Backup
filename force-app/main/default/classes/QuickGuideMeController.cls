/**************************************************
Description:    Controller for the Quick Guide Me detail page button on Account
History:
--------------------------------------------------
2019-09-25  shashwat.a.nath@accenture.com  Created
**************************************************/

public with sharing class QuickGuideMeController {
    // Class Level Variables
    public List<Account> accountRecordList;
    public pagereference pageRef;
    // Constructor
    public QuickGuideMeController(ApexPages.StandardController controller)
    {
        String accountId = apexpages.currentpage().getparameters().get('id');
        System.debug('Account Id =>' +accountId);
        if(String.isNotBlank(accountId)){
            accountRecordList = [SELECT ID, Role_Type_Roll_Up__c FROM Account where id =: accountId Limit 1];
        }

    }
    /**
    *  This Method is called When as an action on QuickGuideMe Page which is invoked when the Quick Guide Me or Quick Proposal button is clicked on the Account Detail page
    *  Method creates an opportunity and on successful opportunity creation redirects the user to APT_GuideMe Page
    */
    public pagereference createOpportunity(){
        try{
                String pageParameter = apexpages.currentpage().getparameters().get('pageParam');
                System.debug('Page Param =>' +pageParameter);
                if(pageParameter.equalsIgnoreCase('quickGuideMe')){
                    opportunity opportunityRecord = new opportunity();
                    opportunityRecord.Name = Label.Opp_Name_for_Quick_Guide_Me;
                    opportunityRecord.AccountId = accountRecordList[0].Id;
                    opportunityRecord.Offering_Type__c = Label.OfferTypeQuickGuideMe;
                    opportunityRecord.StageName = Label.OppStageQuickGuideMe;
                    opportunityRecord.CloseDate = system.today();
                    if(accountRecordList[0].Role_Type_Roll_Up__c == 'Customer') {
                        opportunityRecord.Type = 'Existing Customer';
                    }
                    else{
                        opportunityRecord.Type = 'New Customer';
                    }

                    database.Insert(opportunityRecord);
                    pageRef = new Pagereference('/apex/APT_GuideMe?opportunityId=' + opportunityRecord.id + '&accountId='+accountRecordList[0].Id);
                }
                else if(pageParameter.equalsIgnoreCase('quickProposal')){
                    opportunity opportunityRecord = new opportunity();
                    opportunityRecord.Name = 'Quick Opportunity';
                    opportunityRecord.AccountId = accountRecordList[0].Id;
                    opportunityRecord.Offering_Type__c = 'Product';
                    opportunityRecord.StageName = Label.OppStageQuickGuideMe;
                    opportunityRecord.CloseDate = system.today();
                    opportunityRecord.Type = 'Existing Customer';
                    database.Insert(opportunityRecord);
                    pageRef = new Pagereference('/apex/Apttus_Proposal__OpportunityProposalNew?opportunityId=' + opportunityRecord.id + '&accountId='+accountRecordList[0].Id);
                }
             }
        catch(exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            return null;
        }
        return pageRef;
    }
}