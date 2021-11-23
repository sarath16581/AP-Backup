/*------------------------------------------------------------
Author:        Adrian Recio
Company:       Accenture
Description:   Main test class utility for creating test data.
Test Class:    N/A
History
<Date>      <Authors Name>     <Brief Description of Change>
9-Sep-2018  Adrian Recio        Initial version.
------------------------------------------------------------*/
@Istest
public with sharing class APT_TestUtil2 {
    
    //create Apttus__APTS_Admin__c test record
    @TestVisible private static Apttus__APTS_Admin__c createAptAdmin() {
        Apttus__APTS_Admin__c adminObj = new Apttus__APTS_Admin__c();
        adminObj.Name = APT_Constants.ADMIN_LARGE_CART_THRESHOLD;
        adminObj.Apttus__Value__c = '1';
        return adminObj;
    }
    
    //create APT_R2TValidationFields__c test record
    @TestVisible private static APT_R2TValidationFields__c createAptValidationFields() {
        APT_R2TValidationFields__c valFieldVar = new APT_R2TValidationFields__c();
        valFieldVar.APT_Unique_Fields__c = APT_Constants.APT_Unique_fields;
        valFieldVar.APT_Product_Code__c = APT_Constants.eParcelExpress;
        valFieldVar.Name = APT_Constants.eParcelExpress;
        return valFieldVar;
    }
    
    //create Apttus_Config2__ConfigSystemProperties__c test record
    @TestVisible private static Apttus_Config2__ConfigSystemProperties__c createAptConfigSystem() {
        Apttus_Config2__ConfigSystemProperties__c cofingSetting = new Apttus_Config2__ConfigSystemProperties__c();
        cofingSetting.Name = 'System Properties';
        cofingSetting.Apttus_Config2__ViewCartCustomFields__c = 'APT_Approval_Required2__c,APT_Get_Renewal_Rates__c,APT_Approval_Required__c,Apttus_Config2__AttributeValueId__r.Category__c,Apttus_Config2__ProductId__r.ProductCode,View_Rate_Card__c,Apttus_Config2__OptionId__r.APT_Sync_with_Opportunity__c';
        cofingSetting.Apttus_Config2__ViewCartCustomFields2__c = 'Apttus_Config2__AttributeValueId__r.APT_Minimum_Quantity__c,Apttus_Config2__ProductId__r.APT_Sync_with_Opportunity__c,APT_Channel_OTC_Only__c,Apttus_Config2__ProductId__r.Name,Edit_in_Excel__c,APT_Manage_LP__c,Apttus_CQApprov__Approval_Status__c';
        return cofingSetting;
    }
    
    //create Apttus_Config2__ConfigCustomClasses__c test record
    @TestVisible private static Apttus_Config2__ConfigCustomClasses__c createAptConfigClass() {
        Apttus_Config2__ConfigCustomClasses__c configCC = new Apttus_Config2__ConfigCustomClasses__c();
        configCC.Apttus_Config2__ValidationCallbackClass__c = 'APT_CartValidationCallBack';
        configCC.Name = 'System Properties';
        return configCC;
    }
    
    //create Apttus_Config2__ConfigLineItemCustomFields__c test record
    @TestVisible private static Apttus_Config2__ConfigLineItemCustomFields__c createCLICustomFields() {
        Apttus_Config2__ConfigLineItemCustomFields__c cliCustomFieldVar = new Apttus_Config2__ConfigLineItemCustomFields__c();
        cliCustomFieldVar.Name = '1';
        cliCustomFieldVar.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__ConfigurationId__r.APT_Created_On__c,APT_Is_Band_Changed__c,Apttus_Config2__ConfigurationId__r.APT_Is_Cloned__c,APT_New_Renew__c,Apttus_Config2__AttributeValueId__r.APT_eParcel_Lodgment__c,Apttus_Config2__AttributeValueId__c';
        cliCustomFieldVar.Apttus_Config2__CustomFieldNames2__c = 'APT_Cascade_Adjustments__c,APT_Rate_Card_Key__c,APT_Pricing_Reason__c,APT_Competitors__c,Apttus_Config2__OptionId__c,Apttus_Config2__ParentBundleNumber__c,APT_New__c, Apttus_CQApprov__Approval_Status__c,Apttus_Config2__AttributeValueId__r.APT_Band__c';
        cliCustomFieldVar.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_International_CO__c,Apttus_Config2__ProductId__r.Name,Apttus_Config2__AdjustmentType__c,Apttus_Config2__AttributeValueId__r.APT_International_Letters__c,APT_Ar4__c';
        cliCustomFieldVar.Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__AttributeValueId__r.APT_Band_Original_Value__c,APT_Band__c,Apttus_Config2__IsPrimaryLine__c,Apttus_Config2__LineType__c,APT_Product_Name__c,Apttus_Config2__PricingStatus__c,Apttus_Config2__PriceListItemId__c,APT_Is_Higher_Band_Offered__c';
        cliCustomFieldVar.Apttus_Config2__CustomFieldNames5__c = 'Apttus_Config2__OptionId__r.Name,APT_Amendment__c,APT_Added_LP__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Contract_Id__c,Apttus_Config2__AttributeValueId__r.Revenue_Committment__c,APT_Is_OPC_deleted__c';
        return cliCustomFieldVar;
    }
    
    //create Apttus_Config2__ClassificationName__c test record
    @TestVisible private static Apttus_Config2__ClassificationName__c createAptCName() {
        Apttus_Config2__ClassificationName__c classification = new Apttus_Config2__ClassificationName__c();
        classification.Apttus_Config2__Active__c = true;
        classification.Apttus_Config2__HierarchyLabel__c = APT_Constants.Australia_Post_All_Categories;
        classification.Apttus_Config2__Type__c = APT_Constants.CAT_OFFERING;
        classification.Apttus_Config2__GuidePage__c = APT_Constants.URL_GUIDED_SELLING_FLOW;
        return classification;
    }
    
    //create Apttus_Config2__PriceList__c test record
    @TestVisible private static Apttus_Config2__PriceList__c createPriceList() {
        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        priceList.Name = APT_Constants.STRING_AUSTRALIA_POST_PRICE_LIST;
        priceList.Apttus_Config2__Active__c = true;
        return priceList;
    }
    
    //create APT_R2T_System_Properties__c test record
    @TestVisible private static APT_R2T_System_Properties__c createR2TSystemProperties(Apttus_Config2__PriceList__c priceList, Apttus_Config2__ClassificationName__c classVar) {
        APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
        r2tSystemProperties.Name = 'System Properties';
        r2tSystemProperties.APT_Default_Price_List_ID__c = priceList.Id;
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = APT_Constants.TEST_EMAIL;
        r2tSystemProperties.APT_Classification_ID__c = classVar.Id;
        r2tSystemProperties.APT_Interview_Name__c = APT_Constants.STRING_AUSTRALIAPOST;
        return r2tSystemProperties;
    }
    
    //create Accoutn test record
    @TestVisible private static Account createOrganisation() {
        Account organisation = new Account();
        organisation.Name = APT_Constants.STRING_TEST_ORGANIZATION;
        organisation.Type = APT_Constants.STRING_ENTERPRISE;
        organisation.ShippingCity = 'TestCity';
        organisation.ShippingState = 'TestState';
        organisation.ShippingPostalCode = '123456';
        return organisation;
    }
    
    //create Contact
    @TestVisible private static Contact createContact(){
        Contact conVar = new Contact();
        conVar.FirstName = APT_Constants.STRING_TEST1;
        conVar.LastName = APT_Constants.STRING_SAMPLE;
        conVar.Email = APT_Constants.SAMPLE_EMAIL;
        return conVar;
    }
    
    //create Opportunity test record
    @TestVisible private static Opportunity createOpportunity(Account accVar) {
        Opportunity oppty = new Opportunity();
        oppty.AccountId = accVar.Id;
        oppty.Name = APT_Constants.STRING_TEST_OPPORTUNITY;
        oppty.Type = APT_Constants.OPPORTUNITY_TYPE_NEW_CUSTOMER;
        oppty.Offering_Type__c = APT_Constants.OPPORTUNITY_OFFERING_TYPE_PRODUCT;
        oppty.StageName = APT_Constants.OPPORTUNITY_STAGE_IDENTIFY;
        oppty.CloseDate = date.Today().addDays(365);
        return oppty;
    }
    
    //create OpportunityLineItem test record
    @TestVisible private static OpportunityLineItem createOpportunityLI(Opportunity oppVar, Id PricebookEntryId, String classVar) {
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = oppVar.Id;
        oliVar.PricebookEntryId = PricebookEntryId;
        oliVar.Classification__c = classVar;
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.Contract_Start_Date__c = Date.today();
        oliVar.Contract_End_Date__c = Date.today() + 365; // RSolomon Updated end date to be greater than Start Date, based on an updated VR
        return oliVar;
    }
    
    //create APT_Opportunity_Product_Line_Item__c test record
    @TestVisible private static APT_Opportunity_Product_Line_Item__c createAPTOpportunityLI(Apttus_Proposal__Proposal__c propVar, Product2 prodVar) {
        APT_Opportunity_Product_Line_Item__c APTopliVar = new APT_Opportunity_Product_Line_Item__c();
        APTopliVar.APT_Quote_Proposal__c = propVar.id;
        APTopliVar.APT_Product__c = prodVar.Id;
        APTopliVar.APT_Quantity__c = 3;
        APTopliVar.APT_TotalPrice__c = 6;
        APTopliVar.APT_Revenue_Start_Date__c = System.Today();
        APTopliVar.APT_Revenue_End_Date__c= System.Today() + 10;
        APTopliVar.APT_Classification__c = 'New Business';
        APTopliVar.APT_Unit_Sales_Price__c = 2;
        return APTopliVar;
    }
    
    //create PricebookEntry test record
    @TestVisible private static PricebookEntry getPricebookEntry(String pricebookId,Product2 prodVar){
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = prodVar.Id;
        standardPrice.UnitPrice = 10000;
        standardPrice.IsActive = true;
        return standardPrice;
        
    }
    
    //create Apttus_Config2__PriceListItem__c test data
    @TestVisible private static Apttus_Config2__PriceListItem__c createPriceListItem(Id priceListId, Id productId, String industry, String band) {
        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
        pli.Apttus_Config2__PriceListId__c = priceListId;
        pli.Apttus_Config2__ProductId__c = productId;
        pli.Apttus_Config2__ListPrice__c = 0;
        pli.Apttus_Config2__ChargeType__c = APT_Constants.CHARGE_TYPE_STANDARD_PRICE;
        pli.Apttus_Config2__PriceType__c = APT_Constants.PRICE_TYPE_USAGE;
        pli.Apttus_Config2__PriceMethod__c = APT_Constants.PRICE_METHOD_PER_UNIT;
        pli.Apttus_Config2__PriceUom__c = APT_Constants.PRICE_UOM_EACH;
        pli.Apttus_Config2__Active__c = true;
        pli.APT_Industry__c = industry;
        pli.APT_Band__c = band;
        pli.APT_Lodgement_Zone_Code__c=APT_Constants.SRRING_AAT;
        pli.APT_Price_Structure__c=APT_Constants.STRING_BANDED;
        return pli;
    }
    
    //create Apttus__APTS_Agreement__c test record
    @TestVisible private static Apttus__APTS_Agreement__c createAgreement(Account accVar, Contact conVar, Opportunity oppVar, Apttus_Proposal__Proposal__c pProposalVar,
                                                                          string status, string category, String recordTypeName){
                                                                              Apttus__APTS_Agreement__c aptContract = new Apttus__APTS_Agreement__c();
                                                                              aptContract.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
                                                                              aptContract.Name = APT_Constants.STRING_AGREEMENT;
                                                                              aptContract.Apttus__Agreement_Category__c = APT_Constants.NETWORK_TYPE_STANDARD;
                                                                              aptContract.Apttus__Primary_Contact__c = conVar.Id;
                                                                              aptContract.Apttus__Account__c = accVar.Id;
                                                                              aptContract.Apttus__Related_Opportunity__c = oppVar.Id;
                                                                              aptContract.Apttus__Status__c = status;
                                                                              aptContract.Apttus__Status_Category__c = category;
                                                                              aptContract.Apttus_QPComply__RelatedProposalId__c = pProposalVar.Id;
                                                                              return aptContract;
                                                                          }
    
    //Create Apttus_Proposal__Proposal__c test record
    @TestVisible private static Apttus_Proposal__Proposal__c createQuoteProposal(Account accVar, Opportunity oppVar, Apttus__APTS_Agreement__c pAggVar,
                                                                                 string recordTypeName, Apttus_Config2__PriceList__c priceList){
                                                                                     Apttus_Proposal__Proposal__c quoteVar = new Apttus_Proposal__Proposal__c();
                                                                                     quoteVar.Apttus_Proposal__Proposal_Name__c = 'Test Quote';
                                                                                     quoteVar.Apttus_Proposal__Opportunity__c = oppVar.Id;
                                                                                     quoteVar.Apttus_Proposal__Account__c = accVar.Id;
                                                                                     quoteVar.RecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
                                                                                     quoteVar.Apttus_QPConfig__PriceListId__c = priceList.Id;
                                                                                     quoteVar.APT_Contract_Id__c = pAggVar.Id; // This is the parent agreement of the proposal if proposal is created from amendment or renewal
                                                                                     return quoteVar;
                                                                                 }

    //create international product
    @TestVisible private static Product2 createInternationalProduct(String productName, String productCode, String productFamily, String prodClass) {
        Product2 product = new Product2();
        product.Name = productName;
        product.ProductCode = productCode;
        product.Family = productFamily;
        product.APT_Apttus_Product_Classification__c = prodClass;
        product.IsActive = true;
        product.APT_International_Pricing__c = true;
        return product;
    }
    
    //create domestic product
    @TestVisible private static Product2 createDomesticProduct(String productName, String productCode, String productFamily, String prodClass,
                                                               String strCategory, String networkType) {
                                                                   Product2 product = new Product2();
                                                                   product.Name = productName;
                                                                   product.ProductCode = productCode;
                                                                   product.Family = productFamily;
                                                                   product.APT_Apttus_Product_Classification__c = prodClass;
                                                                   product.IsActive = true;
                                                                   product.APT_Domestic_Pricing__c = true;
                                                                   
                                                                   product.APT_Category__c = strCategory;
                                                                   product.APT_Network_Type__c = networkType;
                                                                   return product;
                                                               }
    
    //create Apttus_Config2__ProductConfiguration__c test data
    @TestVisible private static Apttus_Config2__ProductConfiguration__c getProductConfiguration(String configName,
                                                                                                Integer versionNbr,
                                                                                                ID bObjectId,
                                                                                                String bObjectType,
                                                                                                String groupType,
                                                                                                ID priceListId,
                                                                                                ID ancestorId,
                                                                                                String status,
                                                                                                Datetime finalizedDate,
                                                                                                Datetime effectiveDate,
                                                                                                Boolean isTransient){
                                                                                                    
                                                                                                    Apttus_Config2__ProductConfiguration__c configSO = new Apttus_Config2__ProductConfiguration__c(Name = configName, OwnerId = UserInfo.getUserId());
                                                                                                    configSO.Apttus_Config2__VersionNumber__c = versionNbr;
                                                                                                    configSO.Apttus_Config2__SummaryGroupType__c = groupType;
                                                                                                    configSO.Apttus_Config2__BusinessObjectId__c = bObjectId;
                                                                                                    configSO.Apttus_Config2__BusinessObjectType__c = bObjectType;
                                                                                                    configSO.Apttus_QPConfig__Proposald__c = bObjectId;
                                                                                                    configSO.Apttus_Config2__PriceListId__c = priceListId;
                                                                                                    configSO.Apttus_Config2__AncestorId__c = ancestorId;
                                                                                                    configSO.Apttus_Config2__Status__c = status;
                                                                                                    configSO.Apttus_Config2__IsTransient__c = isTransient;
                                                                                                    configSO.Apttus_Config2__FinalizedDate__c = finalizedDate;
                                                                                                    configSO.Apttus_Config2__EffectiveDate__c = effectiveDate;
                                                                                                    return configSO;
                                                                                                }
    
    //create product attribute group
    @TestVisible private static Apttus_Config2__ProductAttributeGroup__c createProductAttributeGroup(String businessObject) {
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = new Apttus_Config2__ProductAttributeGroup__c();
        productAttributeGroup.Name = APT_Constants.STRING_TEST_PRODUCT_ATTRIBUTE_GROUP;
        productAttributeGroup.Apttus_Config2__BusinessObject__c = businessObject;
        productAttributeGroup.Apttus_Config2__Description__c = APT_Constants.STRING_TEST_PRODUCT_ATTRIBUTE_GROUP;
        productAttributeGroup.Apttus_Config2__TwoColumnAttributeDisplay__c = true;
        
        return productAttributeGroup;
    }
    
    //create product attribute
    @TestVisible private static Apttus_Config2__ProductAttribute__c createProductAttribute(String field, Id attributeGroupId) {
        Apttus_Config2__ProductAttribute__c productAttribute = new Apttus_Config2__ProductAttribute__c();
        productAttribute.Apttus_Config2__Sequence__c = 1;
        productAttribute.Apttus_Config2__Field__c = field;
        productAttribute.Apttus_Config2__AttributeGroupId__c = attributeGroupId;
        
        return productAttribute;
    }
    
    //create price dimension
    @TestVisible private static Apttus_Config2__PriceDimension__c createPriceDimension(String dimensionName, String contextType, String businessObject,
                                                                                       String field, Id productAttributeId) {
                                                                                           Apttus_Config2__PriceDimension__c priceDimension = new Apttus_Config2__PriceDimension__c();
                                                                                           priceDimension.Name = dimensionName;
                                                                                           priceDimension.Apttus_Config2__ContextType__c = contextType;
                                                                                           priceDimension.Apttus_Config2__BusinessObject__c = businessObject;
                                                                                           priceDimension.Apttus_Config2__Datasource__c = field;
                                                                                           priceDimension.Apttus_Config2__AttributeId__c = productAttributeId;
                                                                                           
                                                                                           return priceDimension;
                                                                                       }
    
    
    //create product configuration
    @TestVisible private static Apttus_Config2__ProductConfiguration__c getProductConfiguration2(String configName,
                                                                                                 Integer versionNbr,
                                                                                                 ID bObjectId,
                                                                                                 String bObjectType,
                                                                                                 String groupType,
                                                                                                 ID priceListId,
                                                                                                 String status,
                                                                                                 Datetime finalizedDate,
                                                                                                 Datetime effectiveDate,
                                                                                                 Boolean isTransient){
                                                                                                     
                                                                                                     Apttus_Config2__ProductConfiguration__c configSO = new Apttus_Config2__ProductConfiguration__c(Name = configName, OwnerId = UserInfo.getUserId());
                                                                                                     configSO.Apttus_Config2__VersionNumber__c = versionNbr;
                                                                                                     configSO.Apttus_Config2__SummaryGroupType__c = groupType;
                                                                                                     configSO.Apttus_Config2__BusinessObjectId__c = bObjectId;
                                                                                                     configSO.Apttus_Config2__BusinessObjectType__c = bObjectType;
                                                                                                     configSO.Apttus_QPConfig__Proposald__c = bObjectId;
                                                                                                     configSO.Apttus_Config2__PriceListId__c = priceListId;
                                                                                                     configSO.Apttus_Config2__Status__c = status;
                                                                                                     configSO.Apttus_Config2__IsTransient__c = isTransient;
                                                                                                     configSO.Apttus_Config2__FinalizedDate__c = finalizedDate;
                                                                                                     configSO.Apttus_Config2__EffectiveDate__c = effectiveDate;
                                                                                                     return configSO;
                                                                                                 }
    
    //create Line Item
    @TestVisible private static Apttus_Config2__LineItem__c getConfigLineItem(ID configId,
                                                                              ID groupId,
                                                                              Integer lineNumber,
                                                                              Boolean isPrimaryLine,
                                                                              Integer itemSeq,
                                                                              String lineType,
                                                                              ID productId,
                                                                              Boolean customizable,
                                                                              ID productOptionId,
                                                                              ID optionId,
                                                                              ID classId,
                                                                              String classHierarchy,
                                                                              Decimal quantity,
                                                                              Boolean isQtyModifiable,
                                                                              String uom,
                                                                              Integer term,
                                                                              ID priceListId,
                                                                              ID plItemId,
                                                                              String priceType,
                                                                              String priceMethod,
                                                                              String chargeType,
                                                                              String frequency,
                                                                              Boolean allowManualAdj,
                                                                              Boolean allocateGroupAdj,
                                                                              Decimal listPrice,
                                                                              Decimal basePrice,
                                                                              String basePriceMethod,
                                                                              Decimal baseExtPrice,
                                                                              Decimal optionPrice,
                                                                              Decimal extPrice,
                                                                              String lineDesc){
                                                                                  
          Apttus_Config2__LineItem__c lineItem = new Apttus_Config2__LineItem__c(Apttus_Config2__ConfigurationId__c = configId);
          lineItem.Apttus_Config2__LineNumber__c = lineNumber;
          lineItem.Apttus_Config2__IsPrimaryLine__c = isPrimaryLine;
          lineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
          lineItem.Apttus_Config2__ItemSequence__c = itemSeq;
          lineItem.Apttus_Config2__SummaryGroupId__c = groupId;
          lineItem.Apttus_Config2__LineType__c = lineType;
          lineItem.Apttus_Config2__ProductId__c = productId;
          lineItem.Apttus_Config2__Customizable__c = customizable;
          lineItem.Apttus_Config2__ProductOptionId__c = productOptionId;
          lineItem.Apttus_Config2__OptionId__c = optionId;
          lineItem.Apttus_Config2__ClassificationId__c = classId;
          lineItem.Apttus_Config2__ClassificationHierarchy__c = classHierarchy;
          lineItem.Apttus_Config2__Quantity__c = quantity;
          lineItem.Apttus_Config2__IsQuantityModifiable__c = isQtyModifiable;
          lineItem.Apttus_Config2__Uom__c = uom;
          lineItem.Apttus_Config2__Term__c = term;
          lineItem.Apttus_Config2__PriceListId__c = priceListId;
          lineItem.Apttus_Config2__PriceListItemId__c = plItemId;
          lineItem.Apttus_Config2__PriceType__c = priceType;
          lineItem.Apttus_Config2__PriceMethod__c = priceMethod;
          lineItem.Apttus_Config2__ChargeType__c = chargeType;
          lineItem.Apttus_Config2__Frequency__c = frequency;
          lineItem.Apttus_Config2__AllowManualAdjustment__c = allowManualAdj;
          lineItem.Apttus_Config2__AllocateGroupAdjustment__c = allocateGroupAdj;
          lineItem.Apttus_Config2__ListPrice__c = listPrice;
          lineItem.Apttus_Config2__BasePrice__c = basePrice;
          lineItem.Apttus_Config2__BasePriceMethod__c = basePriceMethod;
          lineItem.Apttus_Config2__BaseExtendedPrice__c = baseExtPrice;
          lineItem.Apttus_Config2__OptionPrice__c = optionPrice;
          lineItem.Apttus_Config2__ExtendedPrice__c = extPrice;
          lineItem.Apttus_Config2__Description__c = lineDesc;
          lineItem.Apttus_Config2__AdjustedPrice__c = 0;

          return lineItem;
    }
    
    //create Apttus_Config2__ProductAttributeValue__c
    @TestVisible private static Apttus_Config2__ProductAttributeValue__c createAttributeValue(Id lineItemId,string maintenanceLevel,
                                                                                              boolean isNeoship,boolean isOnlinePostalExpenseManager,boolean isPostalRate,
                                                                                              String volumeData,String industry, Boolean eParcelLodg, Boolean internationalLetters)
    {
        Apttus_Config2__ProductAttributeValue__c pav= new Apttus_Config2__ProductAttributeValue__c();
        pav.Apttus_Config2__LineItemId__c = lineItemId;
        pav.APT_Volume_Data__c = volumeData;
        pav.APT_Industry__c = industry;
        pav.APT_eParcel_Lodgment__c = eParcelLodg;
        pav.APT_International_Letters__c = internationalLetters;
        return pav;
    }
    
    //update line item with Attribute Value
    @TestVisible private static void UpdateLineItem(Id prodAttValID){
        Apttus_Config2__LineItem__c lineItem = [select ID,Apttus_Config2__AttributeValueId__c from Apttus_Config2__LineItem__c limit 1];
        lineItem.Apttus_Config2__AttributeValueId__c= prodAttValID;
    }

    // create APT_SAP_Contracts__c
    @TestVisible private static APT_SAP_Contracts__c createSAPContract(Apttus__APTS_Agreement__c aptContract){
        APT_SAP_Contracts__c sapContract = new APT_SAP_Contracts__c();
        sapContract.APT_Apttus_Contract__c = aptContract.Id;
        sapContract.APT_SAP_Contract_Number__c = '1234567';
        sapContract.APT_Contract_Extension_Date__c = Date.today() + 50;
        sapContract.APT_Contract_Start_Date__c = Date.today() - 50;
        sapContract.APT_Contract_End_Date__c = Date.today();
        sapContract.SAP_Contract_Status__c = 'Active';
        return sapContract;
    }

    //create Logdement Zone
    @TestVisible private static APT_Lodgement_Zone__c createLodgementZone(String name,String code){
        APT_Lodgement_Zone__c lodZone= new APT_Lodgement_Zone__c();
        lodZone.Name=name;
        lodZone.APT_Lodgement_Zone_Code__c =code;
        return lodZone;
    }
    
    //create Feature Pricing
    @TestVisible private static APT_Feature_Pricing__c getFeaturePricing(String name,String category,String lodgementZone,String networkType,
                                                                         String productType,Double flagFallRate,Double perKgRate) {
        APT_Feature_Pricing__c fp=new APT_Feature_Pricing__c();
        fp.name=name;
        fp.APT_Category__c=category;
        fp.APT_Lodgement_Zone__c=lodgementZone;
        fp.APT_Network_Type__c=networkType;
        fp.APT_Product_Type__c=productType;
        fp.APT_Flag_Fall_Rate__c=flagFallRate;
        fp.APT_Per_Kg_Rate__c =perKgRate;
        
        return fp;
    }
    
    //create Proposal line Item
    @TestVisible private static Apttus_Proposal__Proposal_Line_Item__c getProposalLineItem(String quoteId, String lineId, String pliId, String prodId,String optionId){
        
        Apttus_Proposal__Proposal_Line_Item__c propLineItem = new Apttus_Proposal__Proposal_Line_Item__c(
            Apttus_Proposal__Proposal__c = quoteId,
            Apttus_QPConfig__DerivedFromId__c = lineId,
            Apttus_QPConfig__PriceListItemId__c = pliId,Apttus_QPConfig__OptionId__c = optionId,Apttus_Proposal__Product__c = prodId);
        return propLineItem;
    }
    //create product attribute value
    @TestVisible private static Apttus_QPConfig__ProposalProductAttributeValue__c getProposalProductAttributeValue(String propLineItemID){
        
        Apttus_QPConfig__ProposalProductAttributeValue__c ProposalProductAttributeValue = new Apttus_QPConfig__ProposalProductAttributeValue__c (
            Apttus_QPConfig__LineItemId__c= propLineItemID,APT_Minimum_Quantity__c=10,APT_Classification__c=APT_Constants.CLASSIFICATION_GROWTH,APT_Sub_Classification__c=APT_Constants.STRING_UP_SELL,APT_Sales_Unit_Price__c=10);
        
        return ProposalProductAttributeValue;
    }

    //create Case
    @TestVisible private static Case  createCase(Id conId,Id aptContractId ){
        Case cse = new Case(Product_Type__c = APT_Constants.STRING_LETTERS , APT_Contract__c = aptContractId ,
                            Billing_Number__c = APT_Constants.STRING_BI1234 , ContactId = conId , Priority =APT_Constants.STRING_MEDIUM ,
                            Work_Type__c =APT_Constants.STRING_PRODUCTS , Subject = APT_Constants.STRING_THIS_IS_A_CASE ,Description = APT_Constants.STRING_DESCRIBE);
        return cse;
    }
    
    //create network
    @TestVisible private static Network__c createNetwork() {
        Network__c nw = new Network__c();
        nw.Name = APT_Constants.STRING_LODGEMENT_POINT;
        nw.Post_Code__c = APT_Constants.STRING_RANDOM_STRING;
        nw.State__c = APT_Constants.STRING_ACT;
        
        // Adrian Recio, 22/5/2017, Test class population for APT Business Unit field
        nw.APT_Business_Unit__c = APT_Constants.STRING_BUSINESS;
        nw.Business_Unit__c = APT_Constants.STRING_BUSINESS;
        nw.APT_eParcel_Enabled__c = APT_Constants.OPTION_YES;
        nw.Org_ID__c = APT_Constants.STRING_ID_A1POM;
        nw.APT_DWS_ID__c = APT_Constants.STRING_ID_A1POM;
        nw.APT_Transport_Capability__c = APT_Constants.STRING_VAN_ONLY;
        nw.APT_MCAT__c = true;
        nw.APT_Threshold_Categories__c = APT_Constants.STRING_CATEGORY;
        nw.APT_Comments__c = APT_Constants.STRING_NO_COMMENTS;
        
        return nw;
    }
    
    //create Billing Account
    @TestVisible private static Billing_Account__c createBillingAccount(Id AccId) {
        Billing_Account__c bAcc = new Billing_Account__c();
        bAcc.Legacy_Id__c =  APT_Constants.STRING_60000000;
        bAcc.Organisation__c = AccId;
        return bAcc;
    }
    //create Custom Setting
    @TestVisible private static SystemSettings__c createSystemSettings(){
        
        SystemSettings__c systemSettings = new SystemSettings__c (Loglevel_Debug__c = true,
                                                                  Loglevel_Error__c = true,
                                                                  Loglevel_Warning__c = true,
                                                                  Loglevel_Info__c = true,
                                                                  Disable_Billing_Account_Trigger__c=true);
        
        return systemSettings;
    }
    /*
    This method will return Agreement Lodgement Point.
    @params -
    acc - id of account
    agr - Id of agreement
    nwk - id of lodgement point.
    zone - id of lodgement zone
    bcc - id of billing account
    */
    @TestVisible private static APT_Agreement_Lodgement_Point__c createLodgementPoint(ID acc, ID agr, ID nwk,
                                                                                      ID zone, String product,ID bcc){
        APT_Agreement_Lodgement_Point__c  objLp = new APT_Agreement_Lodgement_Point__c();
        objLp.APT_Status__c = APT_Constants.ACTIVE;
        objLp.APT_Agreement__c = agr;
        objLp.APT_Address__c = APT_Constants.STRING_AUSTRALIA;
        objLp.APT_eParcel_Enabled__c = APT_Constants.OPTION_YES;
        objLp.APT_Transport_Capability__c = APT_Constants.STRING_VAN_ONLY;
        objLp.APT_Organisation_ID__c = APT_Constants.STIRNG_ORG123;
        objLp.APT_Lodgement_Point_Lookup__c= nwk;
        objLp.APT_Organisation__c = acc;
        objLp.APT_Lodgement_Zone_Lookup__c= zone;
        objLp.APT_DWS_ID__c = APT_Constants.STRING_DWS12;
        objLp.APT_Selected_Lodgement_Point__c = objLp.Name;
        objLp.APT_LP_Post_Code__c = APT_Constants.STRING_PCODE;
        objLp.APT_Lodgement_Zone__c = APT_Constants.STRING_LZOONE;
        objLp.APT_Product__c = product;
        objLp.APT_Billing_Account__c = bcc;
        objLp.APT_Outlet_Type__c = APT_Constants.STRING_OTYPE;
        return objLp;
    }
    
    //create charge code
    @TestVisible private static APT_Charge_Code__c createChargeCode(String strPriceStructure) {
        APT_Charge_Code__c objChargeCode = new APT_Charge_Code__c();
        objChargeCode.APT_Price_Structure__c = strPriceStructure;
        objChargeCode.APT_Network_Type__c = APT_Constants.NETWORK_TYPE_EXPRESS;
        objChargeCode.APT_Weight_Measure__c = APT_Constants.WEIGHT_MEASURE_CUBIC;
        return objChargeCode;
    }
    //crete opportunity product line item
    @TestVisible private static APT_Opportunity_Product_Line_Item__c createOpProdLI(String clsf,String contPro,ID pro,ID proconf,Integer qty,ID prop,Integer unitSP,Date revStrt,Date revEnd) {
        APT_Opportunity_Product_Line_Item__c OppProLineItem = new APT_Opportunity_Product_Line_Item__c();
        OppProLineItem.APT_Classification__c = clsf;
        OppProLineItem.APT_Contract_Product__c = contPro;
        OppProLineItem.APT_Product__c = pro;
        OppProLineItem.APT_Product_Configuration__c = proconf;
        OppProLineItem.APT_Quantity__c = qty;
        OppProLineItem.APT_Quote_Proposal__c = prop;
        OppProLineItem.APT_Unit_Sales_Price__c = unitSP;
        OppProLineItem.APT_Revenue_Start_Date__c = revStrt;
        OppProLineItem.APT_Revenue_End_Date__c= revEnd;
        return OppProLineItem;
    }
    
    //create attachment
    @TestVisible private static Attachment createAttachment(ID pid){
        Attachment atc = new Attachment();
        atc.Name = APT_Constants.STRING_SAMPLE_ATTACHMENT;
        atc.ParentID = pid;
        return atc;
    }

    //create Proposal - Added by conrad.c.v.borbon on September 21, 2018
    @TestVisible private static Apttus_Proposal__Proposal__c createQuoteProposalNoAgrmnt(Account accVar, Opportunity oppVar, string recordTypeName, Apttus_Config2__PriceList__c priceList){
        Apttus_Proposal__Proposal__c quoteVar = new Apttus_Proposal__Proposal__c();
        quoteVar.Apttus_Proposal__Proposal_Name__c = 'Test Quote';
        quoteVar.Apttus_Proposal__Opportunity__c = oppVar.Id;
        quoteVar.Apttus_Proposal__Account__c = accVar.Id;
        quoteVar.RecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        quoteVar.Apttus_QPConfig__PriceListId__c = priceList.Id;
        return quoteVar;
    }

    //create ContentVersion - Added by conrad.c.v.borbon on September 21, 2018
    @testvisible private static ContentVersion createContentVersion (){
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Content Version';
        cv.PathOnClient = 'sample.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        return cv;
    }

    //create ContentDocumentLink - Added by adrian.a.recio on September 21, 2018
    @testvisible private static ContentDocumentLink createContentDocumentLink (Id entityId, Id documentId){
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = entityId;
        cdl.ContentDocumentId = documentId;
        cdl.shareType = 'V';
        return cdl;
    }

    //Create User
    public static User createUser(Id profileId){
        User user = new User();
        user.Alias = APT_Constants.ALIAS_TEST_USER;
        user.Email = APT_Constants.EMAIL_TEST_USER;
        user.EmailEncodingKey = APT_Constants.EMAILENCODINGKEY_TEST_USER;
        user.LastName = APT_Constants.LASTNAME_TEST_USER;
        user.LanguageLocaleKey = APT_Constants.LANGUAGELOCALEKEY_TEST_USER;
        user.LocaleSidKey = APT_Constants.LOCALESIDKEY_TEST_USER;
        user.ProfileId = profileId;
        user.TimeZoneSidKey = APT_Constants.TIMEZONESIDKEY_TEST_USER;
        user.UserName = APT_Constants.EMAIL_TEST_USER;
        return user;
    }
    
    //Create DocuSign Recipient
    public static Apttus_DocuApi__DocuSignDefaultRecipient2__c createDocuSignRecipient(Id agreementId, string recordType, string contactId, string userId, string firstName, string lastName, string email)
    {
        Apttus_DocuApi__DocuSignDefaultRecipient2__c docuSignRecipient = new Apttus_DocuApi__DocuSignDefaultRecipient2__c();
        docuSignRecipient.Apttus_CMDSign__AgreementId__c = agreementId;
        docuSignRecipient.Apttus_DocuApi__RecipientType__c = APT_Constants.Signer;
        docuSignRecipient.RecordTypeId = Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId();
        docuSignRecipient.Apttus_DocuApi__ContactId__c = contactId;
        docuSignRecipient.Apttus_DocuApi__UserId__c = userId;
        docuSignRecipient.Apttus_DocuApi__FirstName__c = firstName;
        docuSignRecipient.Apttus_DocuApi__LastName__c = lastName;
        docuSignRecipient.Apttus_DocuApi__Email__c = email;
        return docuSignRecipient;
    }
}