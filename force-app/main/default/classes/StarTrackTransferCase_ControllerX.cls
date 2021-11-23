/**************************************************
Type:       Case Transfer Controller Extension
Purpose:    Case Transfer Controller extension, used for publisher action
History:
--------------------------------------------------
Aug-2015:  Fahad.Akhtar@cloudsherpas.com  Created
September 7, 2015 - Patrick James Franco - Added initial value for ownerid
September 8, 2015 - David Catindoy - Added additional method to define status picklist values.
November 4, 2015 - Patrick James Franco - Added logic to set default owner according to Enquiry Type for Pickup Booking Case
November 25, 2015 - Patrick James Franco - Removed StandardController in order to use with Quick Action PA
March 2, 2016 - David Catindoy - Added new logic that default the case owner when a case record has related next flight consignment.
September 26 - Steve Judd - Added variable and logic for isAutocloseEnabled to allow pilot rollout for MW0004540
**************************************************/
public with sharing class StarTrackTransferCase_ControllerX {

    //private varilable to hold context case record
    public Case c {get; set;}
    
    //capture all specified transfer case rules
    public List<StarTrack_Transfer_Case_Rule__c> tc_rules {get; set;}

    //capture initial owner id
    private String ownerid;

    //render ownership reason field on UI
    public boolean showOwnershipReason {get; set;}

    //validation flag
    public boolean validation {get; set;}

    //auto close case from task  permission
    public Boolean isAutoCloseEnabled { get; set; }

    /* The extension constructor initializes the private member
       variable c by using the getRecord method from the standard
     controller. */
    public StarTrackTransferCase_ControllerX() {
        
        this.c = [SELECT Id, Call_Purpose__c, RecordTypeId, RecordType.Name, Enquiry_Type__c, Network__r.OwnerId, Business_Solutions_Customer__c, Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c, Network__r.Name, Initial_Caller_Type__c,
                  Status, OwnerId, Article_Service_Type__c, ArticleTest__r.Product_Group__c, Account.StarTrack_Customer_Stream__c FROM Case WHERE Id =: ApexPages.CurrentPage().getParameters().get('Id')];
                  
        tc_rules = [SELECT Id, Business_Solutions_Customer__c, Case_Purpose__c, Case_RecordType__c, Case_Type__c, Customer_Stream__c, Initial_Caller_Type__c,Service_Cloud_Rule__c, Order__c, Product_Group__c, Queue_Name__c
                    FROM StarTrack_Transfer_Case_Rule__c ORDER BY Order__c];

        //hide transfer reason by default
        showOwnershipReason = false;

        //validation is failed by default, check before redirecting if validation is passed.
        validation = false;
        c.OwnerId = null;
        ownerid = c.OwnerId;
        //onload();
        isAutoCloseEnabled = StarTrack_Constants.CURRENT_USER_CAN_AUTO_CLOSE_CASE_FROM_TASK;
    }

    //Onload owner field value logic
    public PageReference onload(){
        
        Boolean ruleSatisfied = false;
        for(StarTrack_Transfer_Case_Rule__c tc_rule : tc_rules){
            if((String.isNotBlank(tc_rule.Case_Purpose__c) ? c.Call_Purpose__c == tc_rule.Case_Purpose__c : true) && (String.isNotBlank(tc_rule.Case_RecordType__c) ? c.RecordType.Name == tc_rule.Case_RecordType__c : true) &&
                      (String.isNotBlank(tc_rule.Case_Type__c) ? c.Enquiry_Type__c == tc_rule.Case_Type__c : true) && (String.isNotBlank(tc_rule.Customer_Stream__c) ? c.Account.StarTrack_Customer_Stream__c == tc_rule.Customer_Stream__c : true) &&
                      (String.isNotBlank(tc_rule.Initial_Caller_Type__c) ? c.Initial_Caller_Type__c == tc_rule.Initial_Caller_Type__c : true) && (String.isNotBlank(tc_rule.Product_Group__c) ? c.ArticleTest__r.Product_Group__c == tc_rule.Product_Group__c : true) &&
                      (tc_rule.Business_Solutions_Customer__c ? c.Business_Solutions_Customer__c == tc_rule.Business_Solutions_Customer__c : true) && tc_rule.Service_Cloud_Rule__c){
                if(tc_rule.Queue_Name__c == StarTrack_Constants.TRANSFER_QUEUE) {
                    if (String.isBlank(c.Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c)) {
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, StarTrack_Error_Messages__c.getValues('Queue not present') != null ?
                                StarTrack_Error_Messages__c.getValues('Queue not present').Value__c : 'Please populate queue on associated legal entity (Field: Transfer Case Queue) or billing account (Field: BSC Transfer Queue)'));
                        c.OwnerId = null;
                    } else {
                        c.OwnerId = queryQueue(c.Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c);
                    }
                    ruleSatisfied = true;
                    break;
                } else if(tc_rule.Queue_Name__c == StarTrack_Constants.ST_NETWORK_CUST_NOTIF && !isAutoCloseEnabled) {
                    ruleSatisfied = false;
                    continue;
                } else{
                    c.OwnerId = queryQueue(tc_rule.Queue_Name__c);
                    ruleSatisfied = true;
                    break;
                }
            }
        }
        
        if(!ruleSatisfied && String.isNotBlank(c.Network__r.OwnerId)){
            c.OwnerId = c.Network__r.OwnerId;
        }

        ownerid = c.OwnerId;
        return null;
    }
    
    public Id queryQueue(String queueName){
        try{
            return [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :queueName].Id;
        }catch(QueryException e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, StarTrack_Error_Messages__c.getValues('Queue not found') != null ?
            StarTrack_Error_Messages__c.getValues('Queue not found').Value__c : 'Queue not found. Please make sure to reference the correct queue name.'));
            return null;
        }
    }

    //Case save override for no redirect and validation
    public PageReference saveOverride(){
        try{
            if(validate()){
                update c;
                validation = true;
            }else{
                validation = false;
            }

        } catch(DmlException e){
            validation = false;
            System.debug('~~ DmlException : ' + e.getMessage());
        }
        return null;
    }

    //Ownership transfer reason field in UI, it should have a value
    public boolean validate(){
        if(showOwnershipReason && String.isEmpty(c.Transfer_Override_Reason__c))
            return false;
        return true;
    }

    //On change of owner field render ownership reason field.
    public PageReference onChangeOfOwner(){
        showOwnershipReason = true;
        if(String.isNotEmpty(c.Ownerid) && ownerid != c.Ownerid){
            return null;
        }
        showOwnershipReason = false;
        return null;
    }
    
    public void refreshPage(){
        c = [SELECT Id, Call_Purpose__c, RecordTypeId, RecordType.Name, Enquiry_Type__c, Network__r.Ownerid,
             Business_Solutions_Customer__c, Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c, Network__r.Name, Initial_Caller_Type__c,
             Status, OwnerId, Article_Service_Type__c, ArticleTest__r.Product_Group__c, Account.StarTrack_Customer_Stream__c
             FROM Case WHERE ID =: c.Id];
             
        tc_rules = [SELECT Id, Business_Solutions_Customer__c, Case_Purpose__c, Case_RecordType__c, Case_Type__c, Customer_Stream__c,Service_Cloud_Rule__c, Initial_Caller_Type__c, Order__c, Product_Group__c, Queue_Name__c
                    FROM StarTrack_Transfer_Case_Rule__c ORDER BY Order__c];

        showOwnershipReason = false;
        c.OwnerId = null;
        onload();
    }
}