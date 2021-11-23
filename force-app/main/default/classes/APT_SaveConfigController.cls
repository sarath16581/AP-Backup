/**
 * @description       : This class will be called from Add More Products button on the Cart and Attribute Page.
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 05-26-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   05-11-2021   Mansi Shah   Initial Version
**/
public with sharing class APT_SaveConfigController {

    private String configurationId; // Product Configuration ID
    private String businessObjectId; //Proposal ID
    private String flow; // Cart Flow
    private Apttus_Config2__ProductConfiguration__c prodConfig; // Product Configuration Record
    private String instanceURL;// Salesforce Base URL
    public String finalURL{get;set;} // PageReference to redirect to the Cart Page

    public APT_SaveConfigController() {
        instanceURL = URL.getSalesforceBaseUrl().toExternalForm();
        configurationId = ApexPages.currentPage().getParameters().get('id');
        businessObjectId = ApexPages.currentPage().getParameters().get('businessObjectId');
        flow = ApexPages.currentPage().getParameters().get('flow');
    }

    /*
    * Method Name : saveCart
    * Description : This method will save the configuration record and return the Pagereference of a Cart Page.
    * Author      : Mansi Shah
    */
    public PageReference saveCart(){
        PageReference pageRef;
        prodConfig = [SELECT Id, Apttus_Config2__Status__c,Apttus_QPConfig__Proposald__c,Apttus_QPConfig__Proposald__r.Name,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Proposal_Name__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Approval_Stage__c
                      FROM Apttus_Config2__ProductConfiguration__c 
                      WHERE Id = :configurationId];
        
        try{
            if(prodConfig != null){
                prodConfig.Apttus_Config2__Status__c = APT_Constants.URL_SAVED;
                update prodConfig;
            }
        }
        Catch(Exception e){
            System.debug('Exception occured '+e.getMessage()+' at '+e.getLineNumber());
        }
       
        
        finalURL = instanceURL;
        finalURL += '/apex/Apttus_Config2__Cart?businessObjectId='+businessObjectId;
        finalURL += '&useAdvancedApproval=true';
        finalURL += '&flow='+ flow;
        finalURL += '&productOrderByClause=APT_Most_Popular__c NULLS LAST';
        finalURL += '&launchState=catalog#!/search/';
       
        pageRef = new PageReference(finalURL); 
        pageRef.setRedirect(true);
    
        return pageRef;
    }
}