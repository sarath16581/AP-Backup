/**
Created By - Himanshu Jain
Created Date - 16th Mar, 2016
Last Modified By - Mahesh Patel
Last Modified Date - 13th Oct, 2020
Description -Modified to trigge Presto App for StarTrack Products
*/
public with sharing class APT_ViewRatecardControllerAPI {
    
    public boolean isBatchProcess{get; set;}
    public String LastPageURL { get; set; }
    public String lineItemID {get;set;}
    public Boolean isPrestoMode {
            get {
                return String.IsNotBlank(isPrestoModeParam) ? Boolean.ValueOf(isPrestoModeParam) : false;
            }   set;}
    public String isPrestoModeParam {get;set;}
    public String errorMessage{get;set;}
    public String AppName{get;set;}
    public String selectedLineItemId{get;set;}
    public String outputFormat = APT_Constants.STRING_PDF;
    public Boolean hasErrors {get;set;}
    public Apttus_Config2__LineItem__c ParentlineItem{get;set;}
    public boolean ratecardCalculatorMode {get;set;}
    String matchingAppName = null;
    
    /**
        Constructor
    **/
    public APT_ViewRatecardControllerAPI(){
       try {
            LastPageURL = ApexPages.currentPage().getHeaders().get(APT_Constants.URL_REFERER);
            lineItemID = Apexpages.currentPage().getParameters().get(APT_Constants.STRING_PARENTRECORDID);
            isPrestoModeParam = Apexpages.currentPage().getParameters().get(APT_Constants.STRING_ISPRESTOMODE);
            hasErrors = false;
            isBatchProcess = false;
            ratecardCalculatorMode = false;
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
           
        }  
    }

    /**
        Constructor
    **/
    public APT_ViewRatecardControllerAPI(String Lineid, String isPresto){
       try {
            LastPageURL = APT_Constants.SEPERATOR_BACKWARD_SLASH + Lineid;
            lineItemID = Lineid;
            isPrestoModeParam = isPresto;
            hasErrors = false;
            isBatchProcess = true;
            ratecardCalculatorMode = false;
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
           
        }  
    }

    /**
        Constructor
    **/
    public APT_ViewRatecardControllerAPI(String Lineid, String isPresto, String selectedLineItemId, String AppName){
        try {
             LastPageURL = APT_Constants.SEPERATOR_BACKWARD_SLASH + Lineid;
             lineItemID = Lineid;
             isPrestoModeParam = isPresto;
             hasErrors = false;
             isBatchProcess = true;
             ratecardCalculatorMode = false;
             this.selectedLineItemId = selectedLineItemId;
             this.AppName = AppName;
         } catch(system.exception ex) {
             
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            
         }  
    }
    
    /**
        Constructor
    **/
    public APT_ViewRatecardControllerAPI(String Lineid, String isPresto, boolean ratecardCalculatorMode){
       try {
            LastPageURL = APT_Constants.SEPERATOR_BACKWARD_SLASH + Lineid;
            lineItemID = Lineid;
            isPrestoModeParam = isPresto;
            hasErrors = false;
            isBatchProcess = true;
            this.ratecardCalculatorMode = ratecardCalculatorMode;
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
           
        }  
    }
    
    /**
        Init method
    **/
    public void init(){
        try {
            ParentlineItem = null;
            selectedLineItemId = lineItemID;
            
            System.Debug('isPrestoMode-->' + isPrestoMode);
            System.Debug('lineItemID-->' + lineItemID);
            System.Debug('LastPageURL-->' + LastPageURL);
            
            if(String.IsNotBlank(lineItemID))
            {
                ParentlineItem = [SELECT id,APT_Product_Code__c, Apttus_Config2__PrimaryLineNumber__c, Apttus_Config2__ProductId__r.APT_Consolidated_Usage_Price_Tiers__c, Name, Apttus_Config2__ConfigurationId__c, Apttus_Config2__ProductId__r.Name, Apttus_Config2__ProductId__r.ProductCode, Apttus_Config2__ProductId__r.APT_Product_type__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c FROM Apttus_Config2__LineItem__c WHERE id =: lineItemID];
            } 
            
            if(ParentlineItem != null && ParentlineItem.ID != null)
            {
                System.debug(ParentlineItem.Id);
                System.debug(ParentlineItem.APT_Product_Code__c);
                If (ParentlineItem.APT_Product_Code__c == APT_Constants.PRODUCT_CODE_APPC)
                {
                    // Check for Constraint Rule
                    string cartConfigId = ParentlineItem.Apttus_Config2__ConfigurationId__c;
                    Apttus_CPQApi.CPQ.ConstraintResultDO constraintResult = Apttus_CPQApi.CPQWebService.getConstraintRuleResult(cartConfigId); 
                    
                    If (constraintResult.NeedMoreProcessing == false && constraintResult.HasPendingError == false){
                        // Call new Class for to execute Data Transformation Logic
                        APT_ViewRateCardHandler viewRateCardHandler = new APT_ViewRateCardHandler();
                        viewRateCardHandler.process(ParentlineItem.Apttus_Config2__ConfigurationId__c); 
                        
                    } else {
                        hasErrors = true;
                        errorMessage = APT_Constants.ERROR_MESSAGE_CONSTRAINT_RULES;
                        return;
                    }
                    return;
                } 
                
                System.Debug('ParentlineItem.Name-->' + ParentlineItem.Apttus_Config2__ProductId__r.Name);
                System.Debug('isPrestoMode-->' + (isPrestoMode));
                
                String productName = ParentlineItem.Apttus_Config2__ProductId__r.Name;

                //Getting App Name based on Line Item
                List<APT_App_Setup__c> appSetupList = [SELECT id,APT_App_Name__r.Name,APT_Attribute_Name__c, APT_Attribute_Value__c , Apt_Product__c 
                                                        FROM  APT_App_Setup__c WHERE Apt_Product__r.Name =: productName 
                                                        AND APT_Is_Presto_App__c =: isPrestoMode
                                                        AND APT_IsRateCalculatorCall__c =:ratecardCalculatorMode];
                
                System.Debug('appSetupList-->' + appSetupList);

                if(appSetupList != null && appSetupList.size() == 1 )
                {
                    AppName = appSetupList[0].APT_App_Name__r.Name;
                } 
                else if(appSetupList != null)
                {
                    Set<String> fieldsApiNameSet = new Set<String> {APT_Constants.STIRNG_ID_CAPITAL, APT_Constants.NAME2};
                    for(APT_App_Setup__c setup : appSetupList){
                        if(null != setup.APT_Attribute_Name__c && String.IsNotBlank(setup.APT_Attribute_Name__c)){
                            fieldsApiNameSet.add(setup.APT_Attribute_Name__c);
                        }                   
                    }
                    system.debug('fieldsApiNameSet-->' + fieldsApiNameSet);

                    List<String> fieldsApiNameList = new List<String>();
                    fieldsApiNameList.addAll(fieldsApiNameSet);
                    
                    String query = APT_Constants.SOQL_SELECT + String.join(fieldsApiNameList, APT_Constants.SEPARATOR_COMMA_SPACE) + APT_Constants.SOQL_QUERY_FROM_OBJECT_LINEITEM + APT_Constants.SOQL_WHERE_ID_LINEITEM;
                                            
                    system.debug('query-->' + query);
                    Apttus_Config2__LineItem__c lineItem = Database.Query(query);
                    system.debug('lineItem-->' + lineItem);
                    
                    if(lineItem != null && String.isNotBlank(lineItem.ID))
                    {
                        for(APT_App_Setup__c setup : appSetupList)
                        {
                            String fieldValue = '';
                            if(lineItem.get(setup.APT_Attribute_Name__c) != null)
                            {
                                fieldValue = (String) lineItem.get(setup.APT_Attribute_Name__c);
                            }
                            if(((String.IsBlank(fieldValue) && setup.APT_Attribute_Value__c == null) || (fieldValue.equalsIgnoreCase(setup.APT_Attribute_Value__c)))
                                 && String.IsNotBlank(matchingAppName))
                            {
                                hasErrors = true;
                                errorMessage = errorMessage + ' ' + APT_Constants.ERROR_MULTIPLE_APPS_FOUND;
                                break;
                            } 
                            else if((String.IsBlank(fieldValue) && setup.APT_Attribute_Value__c == null) || (fieldValue.equalsIgnoreCase(setup.APT_Attribute_Value__c)))
                            {
                                matchingAppName = setup.APT_App_Name__r.Name;
                                continue;
                            } 
                            else if(String.IsBlank(fieldValue) || setup.APT_Attribute_Value__c == null)
                            {
                                continue;
                            } 
                        }

                        if(String.IsNotBlank(matchingAppName)) 
                        {
                            AppName = matchingAppName;
                        } 
                        else 
                        {
                            hasErrors = true;
                            errorMessage = errorMessage + ' ' + APT_Constants.ERROR_NO_APPS_FOUND;
                        }
                    }
                    system.debug('AppName-->' + AppName);
                } 
                else
                {
                    hasErrors = true;
                    errorMessage = errorMessage + ' ' + APT_Constants.ERROR_NO_APPS_FOUND;
                }
            
                //Option Group Lables Collection
                List<String> optionGroupLabels = new List<String>();
                optionGroupLabels.add(APT_Constants.STRING_PRICING_PRODUCTS);
                optionGroupLabels.add(APT_Constants.OG_SE_PRICING_PRODUCTS);
                optionGroupLabels.add(APT_Constants.OG_EXP_PRICING_PRODUCTS);
                optionGroupLabels.add(APT_Constants.OG_PREMIUM_PRICING_PRODUCTS);
                optionGroupLabels.add(APT_Constants.OG_SPECIAL_PRICING_PRODUCTS);
                optionGroupLabels.add(APT_Constants.OG_NEF_PRICING_PRODUCTS);

                //Getting Line Item ID for Pricing Product for Eparcel or Eparcel Express Products
                if(((null != ParentlineItem.Apttus_Config2__ProductId__r.ProductCode && 
                    (String.isNotBlank(ParentlineItem.Apttus_Config2__ProductId__r.ProductCode) && ParentlineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) || ParentlineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))) 
                    || (ParentlineItem.Apttus_Config2__ProductId__r.APT_Product_type__c != null && String.isNotBlank(ParentlineItem.Apttus_Config2__ProductId__r.APT_Product_type__c) && ParentlineItem.Apttus_Config2__ProductId__r.APT_Product_type__c.equalsIgnoreCase(APT_Constants.PRODUCTTYPE_STARTRACK))) 
                    && !hasErrors)
                {
                    String configId = ParentlineItem.Apttus_Config2__ConfigurationId__c;
                    Decimal bundleNumber = ParentlineItem.Apttus_Config2__PrimaryLineNumber__c;
                    List<Apttus_Config2__LineItem__c> pliList = [SELECT id FROM Apttus_Config2__LineItem__c 
                                                                WHERE Apttus_Config2__ConfigurationId__c =: configId 
                                                                AND Apttus_Config2__ParentBundleNumber__c =: bundleNumber 
                                                                AND Apttus_Config2__OptionGroupLabel__c IN :optionGroupLabels];
                                                                    
                    System.Debug('pliList-->' + pliList);
                    
                    if(pliList != null && pliList.Size() == 1)
                    {
                        selectedLineItemId = pliList[0].ID;
                    } 
                    else 
                    {
                        hasErrors = true;
                        errorMessage = errorMessage + ' ' +  APT_Constants.ERROR_MESSAGE_4 + ParentlineItem.Apttus_Config2__ProductId__r.Name + APT_Constants.SEPERATOR_DOT;
                    }
                    system.debug('selectedLineItemId-->' + selectedLineItemId);
                }
            } 
            else 
            {
                hasErrors = true;
                errorMessage = errorMessage + ' ' +  APT_Constants.ERROR_MESSAGE_5;
            }
            
            if(!isBatchProcess)
            {
                createConsolidatedUsagePriceTiers(ParentlineItem);
            }
            
            if(!hasErrors && !isBatchProcess ){
                
                List<APT_Quote_Rate_Card__c> rateCardList = [SELECT id FROM APT_Quote_Rate_Card__c WHERE APT_Line_Item__c =:  selectedLineItemId];
                if(rateCardList != null && rateCardList.size() > 0 ){
                    delete rateCardList;
                }
            } else {
                if(!isBatchProcess){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, errorMessage));
                }
            }
            system.debug('errorMessage-->' + errorMessage);
        } catch(system.exception ex) {
            hasErrors = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            system.debug('errorMessage-->' + errorMessage);
            system.debug('Exception-->' + ex.getMessage() + ' ' + ex.getStackTraceString());
        }  
    }
    
    public void syncConfigLineItems(){
        If (ParentlineItem.APT_Product_Code__c == APT_Constants.PRODUCT_CODE_APPC){
            APT_ViewRateCardHandler viewRateCardHandler = new APT_ViewRateCardHandler();
             
            viewRateCardHandler.createLineItemRateCard(ParentlineItem.Apttus_Config2__ConfigurationId__c,
                                                              ParentlineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c);
        }       
    }
    
     public PageReference prestoAPI(){
        If (ParentlineItem.APT_Product_Code__c == APT_Constants.PRODUCT_CODE_APPC){
            APT_ViewRateCardHandler viewRateCardHandler = new APT_ViewRateCardHandler();
    
            return viewRateCardHandler.generateDocument(ParentlineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c);
        }       
        return prestoAPI(outputFormat);
    }

    public string newAttachmentID {get;set;}
    
    /**
        Method will redirect to open in excel.
    **/
    public PageReference prestoAPI(String outputFileFormat){
        PageReference redirectPage = null;
        try{
            if(isPrestoMode && !hasErrors)
            {
                List<Attachment> oldAttachmentsList = [SELECT Id, Name FROM Attachment WHERE ParentId = :selectedLineItemId Order By SystemModStamp Desc];
                                                                                                                    
                System.debug(' -->' + AppName + '--->' + selectedLineItemId + '-->' + outputFormat);                                                                                               
                
                If(!Test.isRunningTest()) 
                {
                    Apttus_XApps.EditInExcelLaunchController editLaunch = new Apttus_XApps.EditInExcelLaunchController(AppName,selectedLineItemId,outputFileFormat);
                    Boolean returnFlag = editLaunch.doExportAPI();
                    System.debug('XAE returnFlag:' + returnFlag);
                }

                List<Attachment> newAttachmentsList = [SELECT Id, Name FROM Attachment WHERE ParentId = :selectedLineItemId Order By SystemModStamp Desc];
                Integer oldListSize  = oldAttachmentsList!=null ? oldAttachmentsList.size() : 0;
                Integer newListSize =  newAttachmentsList!=null ? newAttachmentsList.size() : 0;

                if(newListSize == oldListSize)
                {
                    errorMessage = errorMessage + ' ' +  APT_Constants.STRING_DOCUMENT_PROCESSING;
                    hasErrors = true;
                } 
                else 
                {
                    newAttachmentID  = newAttachmentsList[0].ID;
                    redirectPage = redirect(selectedLineItemId);
                    if(!isBatchProcess) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, APT_Constants.PDF_ATTACHED_TO_LINEITEM));
                    }
                }
            } 
            else if(!hasErrors)
            {
                redirectPage = Page.Apttus_XApps__EditInExcelLaunch;
                redirectPage.SetRedirect(true);
            
                redirectPage.getParameters().put(APT_Constants.STRING_PARENTRECORDID , selectedLineItemId);
                redirectPage.getParameters().put(APT_Constants.APPNAME1 , AppName);
            } 
            else 
            {
                redirectPage = null;
                if(!isBatchProcess){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, errorMessage));
                }
            }
        } 
        Catch(Exception ex)
        {
            errorMessage = errorMessage + ' ' +  ex.getMessage() + ' ' + ex.getStackTraceString();
            hasErrors = true;
            System.debug('Managed Error:' + errorMessage);
        }
        System.debug('redirectPage-->' + redirectPage);
        
        return redirectPage;
    }

    /**
        Redirect method.
    **/
    public PageReference redirect(String lineItemId){
        try {
            List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE ParentId = :lineitemID Order By SystemModStamp Desc ];
            
            if(attachments != null && attachments.size() > 0) {
                String AttachmentID = attachments[0].Id;
    
                PageReference pageRef = new PageReference(APT_Constants.SERVLET_TAG+AttachmentID);
                pageRef.setredirect(true); 
                return pageRef;
            } else {
                PageReference pageRef = new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH+lineitemID);
                pageRef.setredirect(true); 
                return pageRef;
            }
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }  
    }
    /**
        Cancel Method
    **/
    public PageReference doCancel(){
        try {
            return new PageReference(LastPageURL);
        } catch(system.exception ex) {
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                return null;
            }  
    }
    /**
      Method will create consolidated usage price tiers
    **/
    public void createConsolidatedUsagePriceTiers(Apttus_Config2__LineItem__c selectedLineItem){
       try {
            String configId = selectedLineItem.Apttus_Config2__ConfigurationId__c;
            Decimal bundleNumber = selectedLineItem.Apttus_Config2__PrimaryLineNumber__c;
            String pliID = selectedLineItem.id;
            List<APT_Consolidated_Usage_Price_Tier__c> oldConsolidatedPriceTiers = [SELECT id FROM APT_Consolidated_Usage_Price_Tier__c WHERE APT_Line_Item__c =: pliID];
            
            if(oldConsolidatedPriceTiers!= null && oldConsolidatedPriceTiers.size() > 0 ){
                delete oldConsolidatedPriceTiers;
            }
            
            List<Apttus_Config2__LineItem__c> LineItems = [SELECT id,Apttus_Config2__OptionId__r.APT_Consolidated_Usage_Price_Tiers__c, 
                                                                Apttus_Config2__ProductId__r.APT_Consolidated_Usage_Price_Tiers__c
                                                                FROM Apttus_Config2__LineItem__c 
                                                                WHERE Apttus_Config2__ConfigurationId__c =: configId 
                                                                AND Apttus_Config2__ParentBundleNumber__c =: bundleNumber];
            
            Set<Id> lineItemsId = new Set<ID>();
            if(LineItems != null && LineItems.size() > 0){
                for(Apttus_Config2__LineItem__c lineItem : LineItems){
                    if(lineItem.Apttus_Config2__OptionId__r.APT_Consolidated_Usage_Price_Tiers__c != null && lineItem.Apttus_Config2__OptionId__r.APT_Consolidated_Usage_Price_Tiers__c){
                        lineItemsId.add(lineItem.id);
                    }
                }
            }
            if(selectedLineItem.Apttus_Config2__ProductId__r.APT_Consolidated_Usage_Price_Tiers__c != null && selectedLineItem.Apttus_Config2__ProductId__r.APT_Consolidated_Usage_Price_Tiers__c ){
                lineItemsId.add(selectedLineItem.id);
            }
            
            List<Apttus_Config2__UsagePriceTier__c> usagePriceTierList = [SELECT id, Apttus_Config2__AdjustmentAmount__c,Apttus_Config2__AdjustmentType__c,
                                                                            Apttus_Config2__Dimension1Value__c, Apttus_Config2__Dimension2Value__c,
                                                                            Apttus_Config2__Dimension3Value__c, Apttus_Config2__Dimension4Value__c,
                                                                            Apttus_Config2__Dimension5Value__c, Apttus_Config2__Dimension6Value__c,
                                                                            Apttus_Config2__FlatPrice__c, Apttus_Config2__LineItemId__r.Apttus_Config2__ChargeType__c,
                                                                            Apttus_Config2__PriceAdjustment__c, APT_Weight_Code_and_Price_Type__c,
                                                                            Apttus_Config2__UsageRate__c
                                                                            FROM Apttus_Config2__UsagePriceTier__c WHERE Apttus_Config2__LineItemId__c in : lineItemsId];
            
            if(usagePriceTierList != null && usagePriceTierList.size() > 0 ){
                List<APT_Consolidated_Usage_Price_Tier__c> consolidatedUsagePriceTierList  = new list<APT_Consolidated_Usage_Price_Tier__c>();
                
                for(Apttus_Config2__UsagePriceTier__c usagePriceTier : usagePriceTierList){
                      
                    consolidatedUsagePriceTierList.add(getConsolidatedUsagePriceTier(usagePriceTier, pliID));           
                    
                }
                
                if(consolidatedUsagePriceTierList != null && consolidatedUsagePriceTierList.size() > 0){
                    upsert consolidatedUsagePriceTierList;
                }
            }
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }       
    }
    /**
     Method will retrieve consolidated usage price tier
    **/
    public static APT_Consolidated_Usage_Price_Tier__c getConsolidatedUsagePriceTier(Apttus_Config2__UsagePriceTier__c usagePriceTier,String pliID){
        try {
            APT_Consolidated_Usage_Price_Tier__c consoldatedPriceTier = new APT_Consolidated_Usage_Price_Tier__c();
                    
            consoldatedPriceTier.APT_AdjustmentAmount__c = usagePriceTier.Apttus_Config2__AdjustmentAmount__c;
            consoldatedPriceTier.APT_Adjustment_Type__c = usagePriceTier.Apttus_Config2__AdjustmentType__c;
            consoldatedPriceTier.APT_Dimension_1_Value__c = usagePriceTier.Apttus_Config2__Dimension1Value__c;
            consoldatedPriceTier.APT_Dimension_2_Value__c = usagePriceTier.Apttus_Config2__Dimension2Value__c;
            consoldatedPriceTier.APT_Dimension_3_Value__c = usagePriceTier.Apttus_Config2__Dimension3Value__c;
            consoldatedPriceTier.APT_Dimension_4_Value__c = usagePriceTier.Apttus_Config2__Dimension4Value__c;
            consoldatedPriceTier.APT_Dimension_5_Value__c = usagePriceTier.Apttus_Config2__Dimension5Value__c;
            consoldatedPriceTier.APT_Dimension_6_Value__c = usagePriceTier.Apttus_Config2__Dimension6Value__c;
            consoldatedPriceTier.APT_Flat_Price__c = usagePriceTier.Apttus_Config2__FlatPrice__c;
            consoldatedPriceTier.APT_Charge_Type__c = usagePriceTier.Apttus_Config2__LineItemId__r.Apttus_Config2__ChargeType__c;
            consoldatedPriceTier.APT_Price_Adjustment__c = usagePriceTier.Apttus_Config2__PriceAdjustment__c;
            consoldatedPriceTier.APT_Weight_Price_Type__c = usagePriceTier.APT_Weight_Code_and_Price_Type__c;
            consoldatedPriceTier.APT_Unit_Price__c = usagePriceTier.Apttus_Config2__UsageRate__c;
            
            consoldatedPriceTier.APT_Line_Item__c = pliID;
            
            return consoldatedPriceTier;
       } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }       
    }
}