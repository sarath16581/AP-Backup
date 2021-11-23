/**
This apex class is used as controller for vf component - APT_CartApprovalsComponent and APT_STCartApprovalsComponent.
Created By - Mausam Padhiyar
Created Date - 17th Feb, 2016
Last Modified By - Krishna Velani
Last Modified Date - 27th April, 2021
**/
public with sharing class APT_CartApprovalsComponentController {
    
    public Apttus_Approval__Approval_Request__c approvalRequestSO {get; set;}
    public String cartSOId {get; set;}
    public String proposalSOId {get; set;}
    public String lineItemSOId {get; set;}
    public String opportunitySOId {get; set;}
    public String accountSOId {get; set;}
   
    public String getdelegateComments()
    {
        List<String> delegateCommentsList =  approvalRequestSO.Apttus_Approval__Approver_Comments__c.split('\n');
        String delegateCommentsTemp = '';
        for(String tempText : delegateCommentsList)
        {
            if(tempText.startsWithIgnoreCase('Reassigned with comments - '))
            {
                delegateCommentsTemp += '&nbsp;&nbsp;&nbsp;'+tempText.replace('Reassigned with comments - ','')+' : ';
            }
            if(tempText.startsWithIgnoreCase('User comments - '))
            {
                delegateCommentsTemp += tempText.replace('User comments - ','')+'<br/>';
            }
            
        }
        return delegateCommentsTemp;
    }
    /**
    Get line item
    **/
    public Apttus_Config2__LineItem__c getLineItemSO() {
    System.Debug('________Kushal+lineItemSOId'+lineItemSOId);
    System.Debug('________Kushal+approvalRequestSO '+approvalRequestSO );
    System.Debug('________Kushal+cartSOId '+cartSOId );
    System.Debug('________Kushal+proposalSOId '+proposalSOId );
    
        if(!String.isEmpty(lineItemSOId)) {
        Apttus_Config2__LineItem__c lineSO = [SELECT Id, Name, APT_Pricing_Reason__c, Apttus_Config2__AttributeValueId__c,
                Apttus_Config2__AttributeValueId__r.Category__c,
                Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c,
                Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name,
                Apttus_Config2__AttributeValueId__r.APT_Industry__c,
                Apttus_Config2__AttributeValueId__r.APT_Band__c,
                Apttus_Config2__AttributeValueId__r.APT_Band_Original_Value__c,
                Apttus_Config2__AttributeValueId__r.Revenue_Committment__c,
                Apttus_Config2__ProductId__r.Name,
                Apttus_Config2__AdjustmentAmount__c, 
                APT_Display_Adjustment_Amount__c,               
                Apttus_Config2__ProductId__r.ProductCode,
                Apttus_CQApprov__Approval_Status__c,
                APT_Previous_Discount__c,
                APT_Rate_Card_Key__c,
                APT_Product_Family__c,
                APT_Volume_Thresholds__c,
                APT_Service_Type__c,
                Apttus_Config2__ProductId__c,
                APT_Channel_PostBillPay__c,
                APT_PostBillPay_Customer_Type__c,
                Apttus_Config2__AdjustmentType__c,
                APT_Product_Name__c,
                Service_Type_Print_Post__c,
                APT_PostBillPay_Channel__c,
                APT_Approval_Required3__c,
                APT_Apply_Round_Off__c,
                Apttus_Config2__Description__c,
                Apttus_Config2__AttributeValueId__r.APT_Approved_Tier_After_Adjustment__c,
                Apttus_Config2__ConfigurationId__c,                            
                Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c,
                Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c,
                Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Tier_Adjustment_Justification__c,
                Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__c
                FROM Apttus_Config2__LineItem__c
                WHERE Id =:lineItemSOId];
                opportunitySOId=lineSO.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c;
                accountSOId=lineSO.Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__c;
            System.Debug('________Kushal+lineSO'+lineSO);
            System.Debug('Opportunity'+opportunitySOId);
            System.Debug('+Account'+accountSOId);
            return lineSO;
        } else {
            return new Apttus_Config2__LineItem__c();
        }        
    }
    
   /* public String getConfigurationURL() {
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues('System Properties');
        String configurationURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + '/' + cartSOId;
        return configurationURL;
    }*/
    
    /**
        This method will return proposal url
    **/
    public String getProposalURL() {
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        String proposalURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.SEPERATOR_BACKWARD_SLASH + proposalSOId;
        System.Debug('________Kushal+proposalURL'+proposalURL);
        return proposalURL;
    }
    /**
        This method will return opportunity url
    **/
    public String getOpportunityURL() {
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        String opportunityURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.SEPERATOR_BACKWARD_SLASH + opportunitySOId;
        return opportunityURL;
    }
    /**
        This method will return account(legal entity name) url
    **/
    public String getAccountURL() {
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        String accountURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.SEPERATOR_BACKWARD_SLASH + accountSOId;
        return accountURL;
    }    
    /**
    Get Approval Request
    **/
    public String getApprovalRequestURL() {
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        String approvalRequestURL= configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.SEPERATOR_BACKWARD_SLASH + approvalRequestSO.id ;
        return approvalRequestURL;
    }
    //Get all Line items to display in Table
    public List<Apttus_Config2__LineItem__c> getLineItems(){
        List<Apttus_Config2__LineItem__c> lineItems= new List<Apttus_Config2__LineItem__c>();
        lineItems= [Select Id,Apttus_Config2__Description__c,APT_ST_Service_Type__c,Apttus_Config2__AttributeValueId__r.APT_Approved_Tier_After_Adjustment__c,
                    Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_STE_Pricing_Tier__c, Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Tier_Adjustment_Type__c
                    from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:cartSOId AND Apttus_Config2__LineType__c=:APT_Constants.LINE_TYPE_PRODUCT_SERVICE AND Apttus_Config2__Description__c !=:APT_Constants.OPERATIONAL_SCHEDULE_SECURITY_SERVICES_PRODUCT];
        return lineItems;
    } //logic ends
    
}