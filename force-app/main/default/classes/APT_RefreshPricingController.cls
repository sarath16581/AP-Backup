/**
 * This apex class is controller for visual force page - APT_RefreshPricing
 * Created By - Mausam Padhiyar
 * Created Date - 21st Sept, 2016
 
 * Last Modified By - Mausam Padhiyar
 * Last Modified Date - 23rd Nov, 2016 | Defect 1791 | reset adjustment amount and adjustment type fields
 */
public with sharing class APT_RefreshPricingController {
    
    public String quoteId;
    public String configId;
    public String configRequestId;
    public String flow;
    
    public boolean haserrorMessages {get; set;}
    public map<string,string> mapUrlParam = new map<string,string>();
    
    /**
     * constructor
     */
    public APT_RefreshPricingController() {
        init();
    }
    
    /**
     * init method
     */
    public void init() {
        haserrorMessages = false;
        quoteId = Apexpages.currentpage().getparameters().get(APT_Constants.URL_BUSINESS_OBJECT_ID);
        configId = Apexpages.currentpage().getparameters().get(APT_Constants.URL_ID);
        configRequestId = Apexpages.currentpage().getparameters().get(APT_Constants.URL_CONFIG_REQUEST_ID);
        flow = Apexpages.currentpage().getparameters().get(APT_Constants.LABEL_FLOW);
        
        URL u = new URL(ApexPages.currentPage().getHeaders().get(APT_Constants.URL_REFERER));
        getCartParameters(u);
    }
    
    /**
     * get cart parameters
     */
    public void getCartParameters(URL u) {
        String parentPageURL = u.getQuery(); 
        if(String.isNotBlank(parentPageURL)){
            for(string s:parentPageURL.split(APT_Constants.SEPERATOR_AND)){
                List<string> lstParam = s.split(APT_Constants.SEPERATOR_EQUAL);
                if(lstParam.size()==2){
                  mapUrlParam.put(lstParam[0],lstParam[1]);
                }     
            }
        }
    }
    
    /**
     * Refresh Pricing
     */
    public PageReference refreshPrice() {
        try {
            if(configId != null) {
                list<Apttus_Config2__LineItem__c> listLineItem = new list<Apttus_Config2__LineItem__c>();
                for(Apttus_Config2__LineItem__c li : [SELECT Id, Apttus_Config2__ProductId__r.APT_Contract_Pricing__c,
                                                    Apttus_Config2__OptionId__r.APT_Contract_Pricing__c,
                                                    Apttus_CQApprov__Approval_Status__c, Apttus_Config2__ContractNumbers__c,
                                                    Apttus_Config2__PricingStatus__c,
                                                    Apttus_Config2__AdjustmentType__c, Apttus_Config2__AdjustmentAmount__c
                                                    FROM Apttus_Config2__LineItem__c
                                                    WHERE Apttus_Config2__ConfigurationId__c = :configId
                                                    AND Apttus_Config2__ContractNumbers__c != null
                                                    AND (Apttus_Config2__ProductId__r.APT_Contract_Pricing__c = true
                                                    OR Apttus_Config2__OptionId__r.APT_Contract_Pricing__c = true)]) {
                    
                    li.Apttus_Config2__PricingStatus__c = APT_Constants.LABEL_LINE_STATUS;
                    li.Apttus_Config2__ContractNumbers__c = null;
                    
                    //1791
                    li.Apttus_Config2__AdjustmentAmount__c = null;
                    li.Apttus_Config2__AdjustmentType__c = null;
                    li.APT_Pricing_Reason__c = null;
                    li.APT_Competitors__c = null;
                    //1791
                    
                    listLineItem.add(li);
                }
                
                if(listLineItem.size() > 0) {
                    update listLineItem;
                }
            }
            
            PageReference cartPage = Page.Apttus_Config2__Cart;
            cartPage.getParameters().put(APT_Constants.LABEL_FLOW, flow);
            cartPage.getParameters().put(APT_Constants.URL_ID, configId);
            cartPage.getParameters().put(APT_Constants.URL_CONFIG_REQUEST_ID, configRequestId);
            cartPage.getParameters().put(APT_Constants.URL_LAUNCH_STATE, mapUrlParam.get(APT_Constants.URL_LAUNCH_STATE));
            
            return cartPage;
        } catch(system.exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        
        return null;
    }
}