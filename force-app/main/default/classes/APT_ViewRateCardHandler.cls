/**
 * Created by: Sautul Mehta
 * Description: Class for view rate card handler
 * @changelog
 * 2021-10-05 - Sautul Mehta - Class Created as part of CI-8
 */
public class APT_ViewRateCardHandler { 
    public void process(string bundleConfigLineId){
        
        
        list<Apttus_Config2__LineItem__c> configLineItems = [select Id, APT_Product_Code__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c =: bundleConfigLineId 
                                                             and Apttus_Config2__OptionId__r.APT_Apttus_Product_Classification__c in (:APT_Constants.PRODUCT_CLASSIFICATION_APPC_STANDARD, :APT_Constants.PRODUCT_CLASSIFICATION_APPC_PREMIUM)
                                                             and Apttus_Config2__LineType__c = :APT_Constants.LABEL_LINE_TYPE_OPTION];
        
        list<string> configLines = new list<string>();
        map<string, string> lineItemIdToProductCodeMap = new map<string, string>();
        for(Apttus_Config2__LineItem__c lineItem : configLineItems){
            configLines.add(lineItem.Id);
            lineItemIdToProductCodeMap.put(lineItem.Id, lineItem.APT_Product_Code__c);
        } 
        
        list<APT_Quote_Rate_Card__c> quoteRateCardsToBeDeleted = [select Id from APT_Quote_Rate_Card__c where APT_Line_Item__c in :configLines];
        delete quoteRateCardsToBeDeleted;
        list<APT_Quote_Rate_Card__c> quoteRateCardsToBeInserted = new list<APT_Quote_Rate_Card__c>();
        APT_QuoteRateCardUtilityFactory quoteRateCardUtilityFactory = new APT_QuoteRateCardUtilityFactory();
        for(string configLine : configLines){
            APT_IQuoteRateCardUtility quoteRateCardUtility = quoteRateCardUtilityFactory.getInstance(lineItemIdToProductCodeMap.get(configLine));
            APT_DataTransformationLogic dataTranformationLogic = new APT_DataTransformationLogic(quoteRateCardUtility);
            quoteRateCardsToBeInserted.addAll(dataTranformationLogic.transformUPTToQuoteRateCard(configLine));
            System.debug('SM_Debug ' + quoteRateCardsToBeInserted.size());
        }
        
        insert quoteRateCardsToBeInserted;
    }
    
    Public void createLineItemRateCard(string cartId, string proposalId){
        try{
            Apttus_CPQApi.CPQ.SynchronizeCartRequestDO request = new Apttus_CPQApi.CPQ.SynchronizeCartRequestDO(); 
            request.CartId = cartId; 
            Apttus_CPQApi.CPQ.SynchronizeCartResponseDO response;
            if(!Test.isRunningTest()){
            	response = Apttus_CPQApi.CPQWebService.synchronizeCart(request);
            }
        }
        catch(system.exception ex){
            throw ex;
        }
    }
    
    public PageReference generateDocument(string proposalId){ 
        R2T_Exempted_Proposal_Settings__mdt customMetadata = [SELECT Id, MasterLabel, Label FROM R2T_Exempted_Proposal_Settings__mdt where MasterLabel = :APT_Constants.METADATTYPERECORD_TEMPLATE_APPC_RATE_CARD];
        String templateName = customMetadata.Label;
        Id templateId = [Select Id from Apttus__APTS_Template__c where name =: templateName LIMIT 1].Id; 
        Id sObjectId = proposalId;   
        String sObjectType = APT_Constants.SOQL_PROPOSAL_OBJECT;
        String pLevel = APT_Constants.ACCESS_LEVEL_EDIT;
        String docFormat = APT_Constants.DOCUMENT_TYPE_PDF;
        Boolean isDraft = true;
        String sessionId = UserInfo.getSessionId();
        String serverUrl = System.Url.getSalesforceBaseUrl().toExternalForm() + APT_Constants.URL_SERVICES_SOAP_V43 + UserInfo.getOrganizationId();
        string docId = '';
        if(!Test.isRunningTest()){
            docId = Apttus_Proposal.MergeWebService.generateDoc2(templateId,sObjectId,pLevel,docFormat,isDraft,sessionId,serverUrl);
        } 
        PageReference pageRef = new PageReference(URL.getSalesforceBaseUrl().toExternalForm()+APT_Constants.URL_SERVICES_SOAP_DOWNLOAD_DOCUMENT + docId + '?' + APT_Constants.URL_SERVICES_OPERATION_CONTEXT_S1);
        pageRef.setredirect(true); 
        deleteDocumentLink(docId, templateName); 
        return pageRef;
    }
    
    private void deleteDocumentLink(string docId, string templateName){
        Map<String, Schema.SObjectType> objectInfo  = Schema.getGlobalDescribe();
        
        Schema.SObjectType proposalObjectTypeInfo = objectInfo.get(APT_Constants.SOQL_PROPOSAL_OBJECT) ;
        Schema.DescribeSObjectResult proposalSchemaInfo = proposalObjectTypeInfo.getDescribe() ;
        String keyPrefix = proposalSchemaInfo.getKeyPrefix();
        
        List<ContentDocumentLink> contentDocumentLinksToBeDeleted = new List<ContentDocumentLink>(); 
        for(ContentDocumentLink contentDocumentLink : [select Id, LinkedEntityId, ContentDocumentId from ContentDocumentLink where ContentDocumentId =:docId]){
            if(string.valueOf(contentDocumentLink.LinkedEntityId)?.substring(0,3) == keyPrefix){
                contentDocumentLinksToBeDeleted.add(contentDocumentLink);
            }
        }
        
        if(!contentDocumentLinksToBeDeleted.isEmpty())
        {
            delete contentDocumentLinksToBeDeleted;
        }
        List<ContentVersion> listContentVersion = [Select Id from ContentVersion where ContentDocumentId = :docId];
        if(listContentVersion != null && !listContentVersion.isEmpty())
        {
            listContentVersion[0].APT_Template_Name__c = templateName;
            update listContentVersion;
        }
    }
}