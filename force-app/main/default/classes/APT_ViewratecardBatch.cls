/**************************************************
Description: This batch class is called while generating the proposal document from the proposal record
History:
2016-03-16 Himanshu Jain Created
2016-10-14 Mausam Padhiyar Modified product name to product code coversion
2016-11-23 Mausam Padhiyar Modified defect 1677
2019-05-31 anshul.goyal@auspost.com.au Modified | 31052019 | select the proposal template specific to the exempted product types(Priority Product, Workforce Verification, StarTrack)
**************************************************
@ModifiedBy: Meet Desai
@ModifiedOn: 19 March, 2020
@Description: Updated code to refer Files/ Content Documents instead of Attachments
**************************************************
@ModifiedBy: Mahesh Patel
@ModifiedOn: 2020-10-20 
@Description: STP-2763 STPAC - Generate ST proposal document - Added this condition for not doing any of these calculations for StarTrack
**************************************************
2021-11-10 Sautul Mehta - CI-95 Changes for APPC product
**************************************************
2022-09-16 Talib Raza - REQ2939749: comment out the code related to pricing calculator
**************************************************/
global class APT_ViewratecardBatch implements Database.Batchable<sObject>, Database.Stateful , Database.AllowsCallouts{

    global set<String> setErrorMessage {get;set;} 
    
    public String configId;
    public String proposalId;
    String sessionId;
    String serverUrl;
    String pageUrl;
    public Map<String,String> rateCalcAttachmentIdlist = new Map<String,String>();
    public Boolean isCallFomRC  {get;set;}
    public Apttus_Proposal__Proposal__c proposalRateCAlc;
    public map<string,Apttus_Config2__LineItem__c> mapLineItem=new map<string,Apttus_Config2__LineItem__c >();
    public map<string,Apttus_Proposal__Proposal_Line_Item__c> mapLineProposalItem=new map<string,Apttus_Proposal__Proposal_Line_Item__c>();
    
    public Apttus_Config2__ProductConfiguration__c config;
    public String prodType;
    public String productType;
    
    /**
        constructor
    **/    
    global APT_ViewratecardBatch(String configId, String proposalId, String sessionId, String serverUrl, String pageUrl, Boolean isCallFromRateCalc, String prodType) {
        setErrorMessage = new set<String>();
        this.configId = configId;
        this.proposalId = proposalId;
        this.sessionId = sessionId;
        this.serverUrl = serverURL;
        this.pageUrl = pageUrl;
        this.isCallFomRC = isCallFromRateCalc;
        this.prodType = prodType;
    }
    
    /**
        Start
    **/
    global Database.QueryLocator start(Database.BatchableContext bc) {  
        system.debug('isCallFomRC---->'+isCallFomRC);
        
      for(Apttus_Proposal__Proposal_Line_Item__c lineItemProposal:[select id,name,Apttus_QPConfig__ChargeType__c,Apttus_Proposal__Proposal__c from Apttus_Proposal__Proposal_Line_Item__c where Apttus_Proposal__Proposal__c=:proposalId]){
           mapLineProposalItem.put(lineItemProposal.Apttus_QPConfig__ChargeType__c,lineItemProposal);
        
        
        }
        for(Apttus_Config2__LineItem__c  configLineItem:[select Id,APT_Rate_Card_Key__c,APT_Product_Name__c,Name,APT_Band__c,Apttus_Config2__ConfigurationId__c  from Apttus_Config2__LineItem__c  where Apttus_Config2__ConfigurationId__c=:configId]){
                mapLineItem.put(configLineItem.APT_Product_Name__c,configLineItem);
        
        }
                          
        if(!isCallFomRC){
            List<APT_Quote_Rate_Card__c> rateCardList = [Select id from APT_Quote_Rate_Card__c where APT_Line_Item__r.Apttus_Config2__ConfigurationId__c =: configId];
        
        delete rateCardList;
        
        
        Map<ID, Apttus_Proposal__Proposal_Line_Item__c> pliMap = new Map<ID, Apttus_Proposal__Proposal_Line_Item__c>([select id, Apttus_QPConfig__DerivedFromId__c from Apttus_Proposal__Proposal_Line_Item__c 
                                                                where Apttus_Proposal__Proposal__c=: proposalId]);
                                                                
         proposalRateCAlc=[select id,Name,Apttus_Proposal__Account__r.LEGACY_ID__c,Apttus_Proposal__Account__r.Name from Apttus_Proposal__Proposal__c where id=:proposalId];
    
        
        List<APT_Line_Item_Rate_Card__c> lineItemRateCardList = [Select id from APT_Line_Item_Rate_Card__c where APT_Proposal_Line_Item__c =: pliMap.keySet()];
        system.debug('*** pli ids ***'+pliMap.keySet());
        system.debug('*** pli ids > size ***'+pliMap.keySet().size());
        system.debug('*** lineItemRateCardList ***'+lineItemRateCardList);
        delete lineItemRateCardList;
        
        for(Apttus_Proposal__Proposal_Line_Item__c pli : pliMap.values()){
            pli.APT_Process_Line_Item_RateCard_on_Update__c = false;
        }
        update pliMap.values();
        
        createConsolidatedUsagePriceTiers();
        
        return Database.getQueryLocator([SELECT Id,APT_Rate_Card_Key__c,APT_Product_Name__c,Name,APT_Band__c, Apttus_Config2__PrimaryLineNumber__c, Apttus_Config2__ProductId__r.Name, Apttus_Config2__ProductId__r.ProductCode, APT_International_PCMS_or_CSP__c, APT_New__c, Apttus_Config2__ProductId__r.APT_Product_type__c FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__LineType__c <> :APT_Constants.LABEL_LINE_TYPE_OPTION 
                                            And Apttus_Config2__ConfigurationId__c =: configId  
                                            AND APT_Contracted_Line_Item__c = true]);
        }else{
             return Database.getQueryLocator([SELECT Id,APT_Rate_Card_Key__c,APT_Product_Name__c,Name,APT_Band__c, Apttus_Config2__PrimaryLineNumber__c, Apttus_Config2__ProductId__r.Name, Apttus_Config2__ProductId__r.ProductCode, APT_International_PCMS_or_CSP__c, APT_New__c  FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__LineType__c <> :APT_Constants.LABEL_LINE_TYPE_OPTION 
                                            And Apttus_Config2__ConfigurationId__c =: configId  
                                            AND APT_Contracted_Line_Item__c = true
                                            AND (Apttus_Config2__ProductId__r.ProductCode =: APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE OR Apttus_Config2__ProductId__r.ProductCode =: APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS OR Apttus_Config2__ProductId__r.ProductCode =: APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail)]);  
        }
        
        /*
        return Database.getQueryLocator([SELECT Id, Apttus_Config2__PrimaryLineNumber__c FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__LineType__c <> 'Option' 
                                            And Apttus_Config2__ConfigurationId__c =: configId  
                                            AND Apttus_Config2__IsPrimaryLine__c = true 
                                            AND Apttus_Config2__ProductId__r.Non_contracted__c = false
                                            AND Apttus_Config2__AttributeValueId__r.APT_Volume_Thresholds__c <> '0 - 250K']);
   
        */
    }
    
     /**
        This method will create usage price tiers
    **/   
    public void createConsolidatedUsagePriceTiers(){
        
        Decimal bundleNumber;
        try {
            List<APT_Consolidated_Usage_Price_Tier__c> oldConsolidatedPriceTiers = [select id from APT_Consolidated_Usage_Price_Tier__c where APT_Line_Item__r.Apttus_Config2__ConfigurationId__c =: configId];
            
            if(oldConsolidatedPriceTiers!= null && oldConsolidatedPriceTiers.size() > 0 ){
                delete oldConsolidatedPriceTiers;
            }       
                                                                
            List<Apttus_Config2__UsagePriceTier__c> usagePriceTierList = [select id, Apttus_Config2__AdjustmentAmount__c,Apttus_Config2__AdjustmentType__c,
                                                                            Apttus_Config2__Dimension1Value__c, Apttus_Config2__Dimension2Value__c,
                                                                            Apttus_Config2__Dimension3Value__c, Apttus_Config2__Dimension4Value__c,
                                                                            Apttus_Config2__Dimension5Value__c, Apttus_Config2__Dimension6Value__c,
                                                                            Apttus_Config2__FlatPrice__c, Apttus_Config2__LineItemId__r.Apttus_Config2__ChargeType__c,
                                                                            Apttus_Config2__PriceAdjustment__c, APT_Weight_Code_and_Price_Type__c,
                                                                            Apttus_Config2__UsageRate__c, Apttus_Config2__LineItemId__r.Apttus_Config2__ParentBundleNumber__c,
                                                                            Apttus_Config2__LineItemId__r.Apttus_Config2__LineType__c,
                                                                            Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__r.ProductCode,
                                                                            Apttus_Config2__LineItemId__r.Apttus_Config2__PrimaryLineNumber__c
                                                                            from Apttus_Config2__UsagePriceTier__c 
                                                                            where Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c =: configId
                                                                            AND (Apttus_Config2__LineItemId__r.Apttus_Config2__OptionId__r.APT_Consolidated_Usage_Price_Tiers__c = true
                                                                            OR Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__r.APT_Consolidated_Usage_Price_Tiers__c = true)];                                                    
            
            
            
            
            Map<Decimal, Apttus_Config2__LineItem__c> bundleNumberLineItemMap = new Map<Decimal, Apttus_Config2__LineItem__c>();
            
            for(Apttus_Config2__LineItem__c lineItem: [select id, Apttus_Config2__PrimaryLineNumber__c
                                                                from Apttus_Config2__LineItem__c 
                                                                where Apttus_Config2__ConfigurationId__c =: configId 
                                                                AND Apttus_Config2__IsPrimaryLine__c = true]){
                
                bundleNumberLineItemMap.put(lineItem.Apttus_Config2__PrimaryLineNumber__c, lineItem);
            }
           
            
            if(usagePriceTierList != null && usagePriceTierList.size() > 0 ){
                List<APT_Consolidated_Usage_Price_Tier__c> consolidatedUsagePriceTierList  = new list<APT_Consolidated_Usage_Price_Tier__c>();
                
                for(Apttus_Config2__UsagePriceTier__c usagePriceTier : usagePriceTierList){
                  if(usagePriceTier.Apttus_Config2__LineItemId__r.Apttus_Config2__LineType__c == APT_Constants.LINE_TYPE_PRODUCT_SERVICE && usagePriceTier.Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_AIRMAILLETTER){
                     bundleNumber = usagePriceTier.Apttus_Config2__LineItemId__r.Apttus_Config2__PrimaryLineNumber__c;
                    }
                else{
                    bundleNumber = usagePriceTier.Apttus_Config2__LineItemId__r.Apttus_Config2__ParentBundleNumber__c;
                    }
                    Apttus_Config2__LineItem__c pli = bundleNumberLineItemMap.get(bundleNumber);
                    
                    if(pli != null) {
                        consolidatedUsagePriceTierList.add(APT_ViewRatecardControllerAPI.getConsolidatedUsagePriceTier(usagePriceTier, pli.ID));           
                    }
                }
                
                if(consolidatedUsagePriceTierList != null && consolidatedUsagePriceTierList.size() > 0){
                    upsert consolidatedUsagePriceTierList;
                }
            }
        } catch(Exception ex){
            
            setErrorMessage.add(ex.getMessage());
        } 
    }
    
   /**
       Execute
    **/  
    global void execute(Database.BatchableContext bc, list<Apttus_Config2__LineItem__c> listLineItem){
        //execute
        try { 
            Set<ID> lineItemIdSet = new Set<ID>();
            Set<Decimal> parentBundleNumberSet = new Set<Decimal>();
            for(Apttus_Config2__LineItem__c li : listLineItem){
                system.debug('-->'  + li);
                if(!isCallFomRC){

                    APT_ViewRatecardControllerAPI ratecardAPI = new APT_ViewRatecardControllerAPI(li.id,APT_Constants.BOOLEAN_TRUE);
                    ratecardAPI.init();
                    if(li.Apttus_Config2__ProductId__r.ProductCode != APT_Constants.PRODUCT_CODE_APPC){
                        PageReference redirectPage = ratecardAPI.prestoAPI();
                        if(redirectPage == null) {
                            setErrorMessage.add(APT_Constants.STRING_LINE_ITEM + li.id + APT_Constants.STRING_VIEW_RATE_CARD_FAILED);
                        }
                    }
                    lineItemIdSet.add(li.id);
                    parentBundleNumberSet.add(li.Apttus_Config2__PrimaryLineNumber__c);
                    this.productType = li.Apttus_Config2__ProductId__r.APT_Product_type__c;
                }
                
                //Code Added for International CO - By Akansha
                /*REQ2939749: if(String.isNotBlank(li.Apttus_Config2__ProductId__r.ProductCode) && (li.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE) || li.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS) || li.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail)) && li.APT_New__c){
                    APT_ViewRatecardControllerAPI rateCardCalcAPI = new APT_ViewRatecardControllerAPI(li.id,APT_Constants.BOOLEAN_TRUE,APT_Constants.BOOL_TRUE);
                    rateCardCalcAPI.init();
                    rateCardCalcAPI.prestoAPI(APT_Constants.STRING_XLS);
                    if(!rateCardCalcAPI.hasErrors){
                        if(li.APT_International_PCMS_or_CSP__c.equalsIgnoreCase(APT_Constants.PROVISIONING_METHOD_PCMS)){
                            rateCalcAttachmentIdlist.put(APT_Constants.FILE_DIGITALCODE, rateCardCalcAPI.newAttachmentID);
                        }
                        if(li.APT_International_PCMS_or_CSP__c.equalsIgnoreCase(APT_Constants.PROVISIONING_METHOD_CSP)){
                            rateCalcAttachmentIdlist.put(APT_Constants.FILE_NDIGITALCODE, rateCardCalcAPI.newAttachmentID);
                        }
                      
                    }
                    
                }REQ2939749: */
                //Code Added for International CO - By Akansha end
               
            }
            if(lineItemIdSet.size() > 0 &&  (!isCallFomRC)){
                List<Apttus_Proposal__Proposal_Line_Item__c> pliList = [select id, Apttus_QPConfig__DerivedFromId__c from Apttus_Proposal__Proposal_Line_Item__c 
                                                                where (Apttus_QPConfig__ParentBundleNumber__c in : parentBundleNumberSet 
                                                                OR Apttus_QPConfig__PrimaryLineNumber__c in: parentBundleNumberSet) 
                                                                AND Apttus_Proposal__Proposal__c =: proposalId ];
                for(Apttus_Proposal__Proposal_Line_Item__c pli : pliList){
                    
                    pli.APT_Process_Line_Item_RateCard_on_Update__c = true;
                }
                system.debug(pliList + '-->pliToBeUpdated');
                update pliList;
                
                for(Apttus_Proposal__Proposal_Line_Item__c pli : pliList){
                    
                    pli.APT_Process_Line_Item_RateCard_on_Update__c = false;
                }
                system.debug(pliList + '-->pliToBeUpdated');
                update pliList;
                
            }
            
            
        } catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage());          
        }
    }
        
   /**
       Finish method
    **/  
    global void finish(Database.BatchableContext bc) {
        //finish
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        
        //testFutureFromBatch();
        
        //Code Added for International CO - By Akansha
        /*Start: Meet Desai: Updated code to refer ContentVersion/ ContentDocument/ ContentDocumentFile instead of Attachment */
        /*REQ2939749: if(rateCalcAttachmentIdlist !=null && rateCalcAttachmentIdlist.size() > 0){
            ContentVersion[] contentVersionList = new ContentVersion[]{};
            ContentDocumentLink[] insertFileList = new ContentDocumentLink[]{};
            DateTime dateVal = system.now();
            Attachment frmAttch  = new Attachment();
            ContentVersion toContentVersion = new ContentVersion();
            String fileName;
            for(String key : rateCalcAttachmentIdlist.keySet()){
                frmAttch = [select body from Attachment where id =:rateCalcAttachmentIdlist.get(key)];
               if(APT_Constants.FILE_DIGITALCODE==key)
               {
            if(mapLineItem.containskey(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew) && mapLineItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew).APT_Rate_Card_Key__c!=null)
            {
            fileName = proposalRateCAlc.name +'_'+ proposalRateCAlc.Apttus_Proposal__Account__r.name +'_'+ key +'_'+ mapLineItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew).APT_Band__c+'_'+mapLineItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew).APT_Rate_Card_Key__c+'_'+APT_Constants.FILENAME_CODE_INT + key  +APT_Constants.FILENAME_CODE_RATE;
            system.debug('fileName1---->'+fileName);
            }
            if(mapLineItem.containskey(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew) && mapLineItem.get( APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew).APT_Rate_Card_Key__c==null){
            fileName = proposalRateCAlc.name +'_'+ proposalRateCAlc.Apttus_Proposal__Account__r.name +'_'+ key +'_'+ mapLineItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew).APT_Band__c +'_'+ mapLineProposalItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew).Name+'_'+ APT_Constants.FILENAME_CODE_INT + key  +APT_Constants.FILENAME_CODE_RATE;
            system.debug('fileNameelseif1---->'+fileName);
            
            }
            
             
             if(mapLineItem.containskey(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail_new) && mapLineItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail_new).APT_Rate_Card_Key__c!=null)
            {
            fileName = proposalRateCAlc.name +'_'+ proposalRateCAlc.Apttus_Proposal__Account__r.name +'_'+ key +'_'+ mapLineItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail_new).APT_Band__c+'_'+mapLineItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail_new).APT_Rate_Card_Key__c+'_'+APT_Constants.FILENAME_CODE_INT + key  +APT_Constants.FILENAME_CODE_RATE;
            system.debug('fileName2---->'+fileName);
            }
            if(mapLineItem.containskey(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail_new) && mapLineItem.get( APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail_new).APT_Rate_Card_Key__c==null){
            fileName = proposalRateCAlc.name +'_'+ proposalRateCAlc.Apttus_Proposal__Account__r.name +'_'+ key +'_'+ mapLineItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail_new).APT_Band__c +'_'+ mapLineProposalItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail_new).Name+'_'+ APT_Constants.FILENAME_CODE_INT + key  +APT_Constants.FILENAME_CODE_RATE;
            system.debug('fileNameelseif2---->'+fileName);
            
            }
           }
           else
           {
            if(mapLineItem.containskey(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE_new) && mapLineItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE_new).APT_Rate_Card_Key__c!=null)
            {
            fileName = proposalRateCAlc.name +'_'+ proposalRateCAlc.Apttus_Proposal__Account__r.name +'_'+ key +'_'+ mapLineItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE_new).APT_Band__c+'_'+mapLineItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE_new).APT_Rate_Card_Key__c+'_'+APT_Constants.FILENAME_CODE_INT + key  +APT_Constants.FILENAME_CODE_RATE;
            system.debug('fileName3---->'+fileName);
            }
            if(mapLineItem.containskey(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE_new) && mapLineItem.get( APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE_new).APT_Rate_Card_Key__c==null){
            fileName = proposalRateCAlc.name +'_'+ proposalRateCAlc.Apttus_Proposal__Account__r.name +'_'+ key +'_'+ mapLineItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE_new).APT_Band__c +'_'+ mapLineProposalItem.get(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE_new).Name+'_'+ APT_Constants.FILENAME_CODE_INT + key  +APT_Constants.FILENAME_CODE_RATE;
            system.debug('fileNameelseif3---->'+fileName);
            
            }
            }
            //else
            //{
             //    fileName = currentDate +'_'+ proposalRateCAlc.name +'_'+ proposalRateCAlc.Apttus_Proposal__Account__r.LEGACY_ID__c +'_'+ proposalRateCAlc.Apttus_Proposal__Account__r.name + APT_Constants.FILENAME_CODE_INT + key  +APT_Constants.FILENAME_CODE_RATE;
             //}
                 system.debug('fN---->'+fileName);
                 toContentVersion = new ContentVersion(Title = fileName, PathOnClient = fileName, VersionData = frmAttch.body);
                 contentVersionList.add(toContentVersion);
            }

            if(contentVersionList.size() > 0){
                insert contentVersionList;
            }

            Set<Id> contentVersionIdSet = new Set<Id>();
            for(ContentVersion contentVersion : contentVersionList){
                contentVersionIdSet.add(contentVersion.Id);
            }

            List<ContentDocument> contentDocumentList = [select Id from ContentDocument where LatestPublishedVersionId in: contentVersionIdSet];
            for (ContentDocument contentDocument : contentDocumentList){
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.LinkedEntityId = proposalId;
                contentDocumentLink.ContentDocumentId = contentDocument.Id;
                insertFileList.Add(contentDocumentLink);
            }

            if(insertFileList.size() > 0){
                insert insertFileList;
            }
        }REQ2939749: */
        /*End: Meet Desai: Updated code to refer ContentVersion/ ContentDocument/ ContentDocumentFile instead of Attachment */
        //Code Added for International CO - By Akansha end
            
        if(!isCallFomRC){

            //STP-3419 query the use offline rates flag from the proposal record
            Boolean useOfflineRates = [SELECT Id, APT_Use_Offline_Rates__c FROM Apttus_Proposal__Proposal__c WHERE Id = :proposalId].APT_Use_Offline_Rates__c;

            APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
            //get email addresses
            String defaultProposalTemplateName;
            string proposalTemplateName;

            Map <String,String> prodTypeToTemplateName= new Map <String,String> ();
            Map <String,String> proposalTemplates= new Map <String,String> ();

            //31052019- added for fetching the exempted prod types from the custom metadata "R2T_Exempted_Proposal_Settings__mdt"
            for(R2T_Exempted_Proposal_Settings__mdt propSetting:  [SELECT MasterLabel, Proposal_template_Name__c FROM R2T_Exempted_Proposal_Settings__mdt]){
                prodTypeToTemplateName.put(propSetting.MasterLabel.toLowerCase(),propSetting.Proposal_template_Name__c);
            }

            //STP-2763 STPAC - Generate ST proposal document. Get Template from custom metadata "R2T_Non_Exempted_Proposal_Settings__mdt"
            if(!useOfflineRates)
            {
                for(R2T_Non_Exempted_Proposal_Settings__mdt proposalSetting:  [SELECT MasterLabel, APT_Template_Name__c FROM R2T_Non_Exempted_Proposal_Settings__mdt]){
                    proposalTemplates.put(proposalSetting.MasterLabel.toLowerCase(), proposalSetting.APT_Template_Name__c);
                }
                proposalTemplateName = proposalTemplates != null && !proposalTemplates.isEmpty() && this.productType != null && proposalTemplates.containsKey(this.productType.toLowerCase()) ? proposalTemplates.get(this.productType.toLowerCase()) : null;
            }

            //31052019 - added the condition for the product type other than (Priority Product, Workforce Verification, StarTrack)
            if((r2tSystemProperties != null) && (String.isBlank(prodType))){
                defaultProposalTemplateName = r2tSystemProperties.APT_Default_Proposal_Template__c;
            }
            //31052019 - added the condition for the product type (Priority Product, Workforce Verification, StarTrack Offline)
            //STP-2763 STPAC - Generate ST proposal document. Get Template from custom metadata "R2T_Non_Exempted_Proposal_Settings__mdt"
            else if((!prodTypeToTemplateName.isEmpty()) && (String.isNotBlank(prodType)) && 
                    (this.productType != APT_Constants.PRODUCTTYPE_STARTRACK || (this.productType == APT_Constants.PRODUCTTYPE_STARTRACK && useOfflineRates))) {
                defaultProposalTemplateName = prodTypeToTemplateName.get(prodType.toLowerCase());
            }
            else if(proposalTemplateName != null && !useOfflineRates){
                defaultProposalTemplateName = proposalTemplateName;
            }
            if(String.IsBlank(defaultProposalTemplateName)) {
                defaultProposalTemplateName = APT_Constants.STRING_R2T_PROPOSAL_TEMPLATE;
                
            }
            system.debug('****Default Proposal Template Name*****'+defaultProposalTemplateName);
            system.debug('****Prod Type*****'+prodType);
            Apttus__APTS_Template__c template = null;
            if(this.productType == APT_Constants.PRODUCT_TYPE_PARCEL_CONTRACT)
            {
                // pulling the setting for APPC_Proposal template.
                //R2T_Exempted_Proposal_Settings__mdt setting = [Select Proposal_template_Name__c, DeveloperName from R2T_Exempted_Proposal_Settings__mdt where DeveloperName = :APT_Constants.TEMPLATE_APPC_PROPOSAL limit 1];
                R2T_Exempted_Proposal_Settings__mdt setting = R2T_Exempted_Proposal_Settings__mdt.getInstance('APPC_Proposal');
                String templateName = setting.Proposal_template_Name__c;
                //template = [select id from Apttus__APTS_Template__c where name=: templateName Limit 1];
                template =APT_TemplateObjectSelector.newInstance(1).selectByConfigId(new Set<String>{templateName}).values()[0];
            } else {
                //template = [select id from Apttus__APTS_Template__c where name=: defaultProposalTemplateName Limit 1];
                template =APT_TemplateObjectSelector.newInstance(1).selectByConfigId(new Set<String>{defaultProposalTemplateName}).values()[0];
            }
            
            String pLevel = APT_Constants.ACCESS_LEVEL_EDIT;
            String docFormat = APT_Constants.DOCUMENT_TYPE_PDF;
            Boolean isDraft = false;
            System.debug('sessionId-->' + sessionId);
        try{
            
            If(!Test.isRunningTest()) {
               //String attId = Apttus_Proposal.MergeWebService.generateDoc2(template.ID, proposalId, pLevel, docFormat, 
                String attId = Apttus_Proposal.MergeWebService.submitGenerateDoc(template.ID, proposalId, pLevel, docFormat, 
                            isDraft, sessionId, serverUrl);            
            }
            
        } catch(Exception ex){
            
            setErrorMessage.add(ex.getMessage());
            //updateProposalInCaseOfDocAPIFail();
        } 
        
        
        finally{
            List<Apttus_Proposal__Proposal_Line_Item__c> pliList = [select id, Apttus_Proposal__Product__r.Name, Apttus_QPConfig__DerivedFromId__c from Apttus_Proposal__Proposal_Line_Item__c 
                                                                where Apttus_Proposal__Proposal__c=: proposalId];
        
            if(pliList!= null && pliList.size() > 0 ){
                for(Apttus_Proposal__Proposal_Line_Item__c pli : pliList){
                    pli.APT_Process_Line_Item_RateCard_on_Update__c = false;
                    pli.Product_Name_Text__c = pli.Apttus_Proposal__Product__r.Name;
                }
                update pliList;
            }
            Apttus_Proposal__Proposal__c prop = new Apttus_Proposal__Proposal__c();
            prop.id = proposalId;
            
            prop.APT_Create_Proposal_Batch_Id__c= bc.getJobId();
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Name ,CreatedBy.Email, ExtendedStatus 
                            FROM AsyncApexJob 
                            WHERE Id = :bc.getJobId()];
                            
            if(a.NumberOfErrors > 0) {
                setErrorMessage.add(a.ExtendedStatus);
            }
            String errorMessage;
            for(String errorMessage1 : setErrorMessage) {
                if(errorMessage != null) {
                    errorMessage += APT_Constants.SEPERATOR_NEW_LINE + errorMessage1;
                } else {
                    errorMessage = errorMessage1;
                }
            }
            //Handle Batch Error Message
            Integer iErrorCount = setErrorMessage.size();
                    
            String mailTextBody = APT_Constants.STRING_PDEAR+ a.CreatedBy.Name + APT_Constants.STRING_TAG_P;
            
            //add Batch Error Message in Email
            if(String.isBlank(prodType)) {
                if (errorMessage != null) {
                    mailTextBody = mailTextBody + APT_Constants.STRING_VIEW_RATE_CARDS_BATCH_JOB + a.TotalJobItems + APT_Constants.BATCHES_WITH + iErrorCount + APT_Constants.EMAIL_PLAIN_TEXT_PART_3 + errorMessage;
                } else {
                    mailTextBody = mailTextBody + APT_Constants.STRING_VIEW_RATE_CARDS_BATCH_JOB + a.TotalJobItems + APT_Constants.BATCHES_WITH + iErrorCount + APT_Constants.EMAIL_PLAIN_SUCCESS_PART_2;
                }
            } 
            //<a href="'+ URL.getSalesforceBaseUrl().toExternalForm() + '/' + accountId + '">' + account.Name+'</a> </p>';
            
            mailTextBody = mailTextBody + APT_Constants.STRING_YOUR_PROPOSAL_HAS_BEEN_GENERATED  + pageUrl 
                                        + APT_Constants.SEPERATOR_BACKWARD_SLASH + proposalId + APT_Constants.SEPARATOR_GREATER_THAN_CHANGE + APT_Constants.STRING_LINKA
                                        + APT_Constants.STRING_AND_GO_TO_NOTES_AND_ATTACHMENTS;
                  
            prop.APT_Batch_Error_Message__c = mailTextBody ;
            update prop;
        }
            
        }else{
            Apttus_Proposal__Proposal__c proposal = new Apttus_Proposal__Proposal__c();
            proposal.ID = proposalId;
            proposal.APT_Document_Generation_in_Progress__c = APT_Constants.BOOL_FALSE;
            upsert proposal;
            //Code For sending Mail for International CO
            sendMailForRateCardGenaration(bc); 
        }
        
        //Apttus_Config2.CPQWebService.finalizeConfiguration(configId);
        /*
        Apttus_CPQApi.CPQ.SynchronizeCartRequestDO request = new Apttus_CPQApi.CPQ.SynchronizeCartRequestDO();  
        request.CartId = configId;            //Product Configuration record id
        Apttus_CPQApi.CPQ.SynchronizeCartResponseDO response = Apttus_CPQApi.CPQWebService.synchronizeCart(request);
        */
    }
    /**
        This method will update proposal
    **/
    @testVisible
    private void updateProposalInCaseOfDocAPIFail(){
        Apttus_Proposal__Proposal__c proposal = new Apttus_Proposal__Proposal__c();
        proposal.ID = proposalId;
        proposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_GENERATED;
        upsert proposal;
    }
    
    @testVisible
    private void sendMailForRateCardGenaration(Database.BatchableContext bc){
        List<String> setErrorMessage = new List<String>();
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email,CreatedBy.Name, ExtendedStatus 
                        FROM AsyncApexJob 
                        WHERE Id = :bc.getJobId()];
                                
        if(a.NumberOfErrors > 0) {
            setErrorMessage.add(a.ExtendedStatus);
        }
        String errorMessage;
        Integer errorCount = setErrorMessage.size();
        for(String errorMessage1 : setErrorMessage) {
            if(errorMessage != null) {
                errorMessage += APT_Constants.SEPERATOR_NEW_LINE + errorMessage1;
            } else {
                errorMessage = errorMessage1;
            }
        }
                   
                        
        String mailBody = APT_Constants.STRING_PDEAR+ a.CreatedBy.Name + APT_Constants.STRING_TAG_P;
        
        //add Batch Error Message in Email
        if(errorMessage != null) {
            mailBody = mailBody +  APT_Constants.STRING_RATE_CALC_BATCH_JOB + a.TotalJobItems + APT_Constants.BATCHES_WITH+ errorCount + APT_Constants.EMAIL_PLAIN_TEXT_PART_3 + errorMessage;
        } else {
            mailBody = mailBody  + APT_Constants.STRING_RATE_CALC_BATCH_JOB + a.TotalJobItems + APT_Constants.BATCHES_WITH+ errorCount + APT_Constants.EMAIL_PLAIN_SUCCESS_PART_2;
        }
        mailBody = mailBody + APT_Constants.STRING_YOUR_RATE_CARD_HAS_BEEN_GENERATED  + pageUrl 
                                    + APT_Constants.SEPERATOR_BACKWARD_SLASH + proposalId+ APT_Constants.SEPARATOR_GREATER_THAN_CHANGE + APT_Constants.STRING_LINKA
                                    + APT_Constants.STRING_AND_GO_TO_NOTES_AND_ATTACHMENTS_RC;
        
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        list<String> toAddresses = new list<String>();
        toAddresses.add(a.CreatedBy.Email);
        mail.setToAddresses(toAddresses);
        mail.setSubject(APT_Constants.MAIL_SUBJECT_RC);
        mail.setHtmlBody(mailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
    }
    
    
}