/**
This apex class is used as controller for vf component - APT_CartApprovalsComponent.
Created By - Kushal Bhalodiya
Created Date - 13th July, 2016

Last Modified By - Mausam Padhiyar
Last Modified Date - 29th Sept, 2016 | Defect 742
**/
public class APT_TermAndConditionController{
   public ID getcontractID() { 
       return contractID;
   }
    public Id contractId;
    public void setcontractID (ID s){
        contractID = s;
        APT_TermAndConditionController();
    }

    public Apttus_Approval__Approval_Request__c approvalRequestSO {get; set;}
    public Apttus__APTS_Agreement__c agreementSO {get;set;}
    public void APT_TermAndConditionController()
    {
        init();      
    }
    
    /**
     * init method
     */
    public void init () {
        if(null != contractID)
        {
            agreementSO = [select ID,Name, APT_Legal_Entity_Name__c, APT_Customer_Number__c,
                                                            Apttus__Related_Opportunity__r.Opportunity_Number__c,
                                                            Apttus__FF_Agreement_Number__c,
                                                            Owner.Name, RecordType.Name,
                                                            APT_Price_Plan__c,
                                                            Included_Product_Lines__c
                                                            from Apttus__APTS_Agreement__c where ID =:contractID];
         }
    }
    
    /**
    Get line item
    **/
    public String getContractURL() {
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        String contractURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.SEPERATOR_BACKWARD_SLASH + contractID;
        return contractURL;
    }
    
    /**
     * return header image url
     */
    public String getHeaderURL() {
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        Document headerDoc = [SELECT Id FROM Document  WHERE Name = :APT_Constants.R2T_CONTRACT_LETTER_HEAD];
        if(configSystemProperties != null && headerDoc != null) {
            String headerURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.SERVLET + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.SERVLET + APT_Constants.SEPERATOR_DOT + APT_Constants.IMAGE_SERVER + APT_Constants.PARMA_ID + headerDoc.Id + APT_Constants.PARMA_O_ID + UserInfo.getOrganizationId();
            return headerURL;
        }
        return null;
    }
    
     /**
     * return footer image url
     */
    public String getFooterURL() {
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        Document footerDoc = [SELECT Id FROM Document  WHERE Name = :APT_Constants.R2T_QUOTE_LETTER_HEAD_FOOTER];
        if(configSystemProperties != null && footerDoc != null) {
            String footerURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.SERVLET + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.SERVLET + APT_Constants.SEPERATOR_DOT + APT_Constants.IMAGE_SERVER + APT_Constants.PARMA_ID + footerDoc.Id + APT_Constants.PARMA_O_ID + UserInfo.getOrganizationId();
            return footerURL;
        }
        return null;
    }
}