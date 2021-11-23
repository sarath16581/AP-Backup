Public Class APTS_TestDataFactory{
    //testing the checkin 
    public static id GlocartID;
    public static Account objAcc;
    public static Opportunity objOpty;
    public static list<Product2> ListOfProd;
    public static Apttus_Config2__PriceList__c objPrList;
    public static List<Apttus_Config2__PriceListItem__c> ListOfPLI;
    public static Apttus_Proposal__Proposal__c objProp;
    public static Apttus_Config2__ProductConfiguration__c objProdConfig;
    public static Apttus_Config2__AssetLineItem__c objAsstLI;
    public static List<Apttus_Config2__LineItem__c> listOfLI;
    public static List<Apttus_Config2__ProductAttributeValue__c> listOfPAV;
    public static Apttus_Config2__BillingPreference__c gloobjBP;
    public static Apttus_Approval__Approval_Request__c gloObjAR;

    public static void CreateAllBasicData(){
        CreateAllBasicData(false);
    }
    public static void CreateAllBasicData(boolean blnCreateAttribute){
        CreateBillingPref();
        objAcc = insertAccount();
        objAcc.Apttus_Config2__BillingPreferenceId__c = gloobjBP.id;
        objAcc.BillingStreet='12345';
        //objAcc.BillingState='California';
        objAcc.BillingState='CA';
        objAcc.BillingPostalCode='12345';
        objAcc.BillingCountry='United States';
        objAcc.BillingCity='SFO';
        insert objAcc;

        Contact objCont = new Contact();
        objCont.Accountid = objAcc.id;
//        objCont.firstname= 'testing contact';
        //objCont.APTS_Billing_Contact__c = true;
        //objCont.APTS_Primary_Shipping_Contact__c=true;
        objCont.LastName = 'test l';
        objCont.FirstName = 'test f';
        objCont.email='Test@test.com';
        insert objCont;
        //objCont.id=null;
        //insert objCont;



        objOpty = insertOppty(objAcc);
        insert objOpty;
        //id idProdRecType = [SELECT id from RecordType where DeveloperName ='Standard_Product'].Id;
        ListOfProd = new list<Product2>();
        ListOfProd.add(new product2(Name=APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,ProductCode=APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE,Apttus_Config2__ConfigurationType__c='Standalone',Family='Hybrid Products',APT_Cascade_Adjustments__c = true));
        ListOfProd.add(new product2( Name=APT_Constants.PRODUCT_CODE_POST_BILLPAY,ProductCode='CPSPT101',Apttus_Config2__ConfigurationType__c='Standalone',Family='Hybrid Products',APT_Cascade_Adjustments__c = true));
        ListOfProd.add(new product2(Name='Product3',ProductCode='3',Apttus_Config2__ConfigurationType__c='Option',Family='Data Solutions',APT_Cascade_Adjustments__c = true));
        //ListOfProd[0].RecordTypeId = idProdRecType;
        //ListOfProd[1].RecordTypeId = idProdRecType;
        //ListOfProd[2].RecordTypeId = idProdRecType;
        insert ListOfProd;
        
        objPrList = insertPriceList();
        insert objPrList;

        ListOfPLI = new List<Apttus_Config2__PriceListItem__c>();
        ListOfPLI.add(insertPriceListItem(objPrList,ListOfProd[0], 10, 'Maintenance Fee', 'Recurring', 'Per Unit', null,null,null,null,null ));
        ListOfPLI.add(insertPriceListItem(objPrList,ListOfProd[1], 20, 'License Fee', 'Recurring', 'Per Unit', null,null,null,null,null ));
        ListOfPLI.add(insertPriceListItem(objPrList,ListOfProd[2], 30, 'License Fee', 'Recurring', 'Per Unit', null,null,null,null,null ));
        insert ListOfPLI;

        objProp = insertQuoteProposal(objAcc, objOpty, objPrList, null);
        objProp.Apttus_Proposal__Primary__c = True;
        objProp.Apttus_QPConfig__BillingPreferenceId__c = gloobjBP.id;
        objProp.Apttus_Proposal__ExpectedStartDate__c = (Date.Today()+30).toStartOfMonth();
        insert objProp;  
        
        objProdConfig=insertProductConfiguration(objProp,'New',objPrList,objAcc);
        insert objProdConfig;
        GlocartID=objProdConfig.Id;
        Apttus_Config2__TempObject__c objTempObj=insertTempObj(objProdConfig);
        insert objTempObj;

        objAsstLI=insertAssetLineItem(ListOfProd[1],null,ListOfPLI[0] ,objAcc,'Product/Service',1,1,1,null,null,0,0,0,1,System.today().addDays(-100),System.today().addDays(265)); //@TODO put start/end dates
        insert objAsstLI;                                                                

        listOfLI = new List<Apttus_Config2__LineItem__c>();
        Apttus_Config2__LineItem__c line1 = insertLineItem(ListOfProd[0], null, GlocartID, 1, 1, 1, 'Product/Service', objPrList, ListOfPLI[0], true, null,1,'New',null,System.today(),System.today().addDays(365));
        line1.APT_Rate_Card_Key__c = null;
        line1.Apttus_Config2__AdjustmentType__c = APT_Constants.OFFER_HIGHER_BAND;
        listOfLI.add(line1);
        listOfLI.add(insertLineItem(ListOfProd[1], null, GlocartID, 1, 1, 1, 'Product/Service', objPrList, ListOfPLI[1], true, null,1,'New',null,System.today(),System.today().addDays(365)));
        listOfLI.add(insertLineItem(ListOfProd[0], ListOfProd[2], GlocartID, 1, 1, 1, 'Option', objPrList, ListOfPLI[2], true, null,1,'New',null,System.today(),System.today().addDays(365)));
        listOfLI.add(listOfLI[0].clone());
        insert listOfLI;
        
        if (blnCreateAttribute){
            listOfPAV = new list<Apttus_Config2__ProductAttributeValue__c>();
            listOfPAV.add(new Apttus_Config2__ProductAttributeValue__c(APT_Band__c = 'BAND 1',APT_Band_Original_Value__c = 'BAND 1'));
            listOfPAV.add(new Apttus_Config2__ProductAttributeValue__c(APT_Band__c = 'BAND 4',APT_Band_Original_Value__c = APT_Constants.BAND_2));
            listOfPAV.add(new Apttus_Config2__ProductAttributeValue__c(APT_Band__c = 'BAND 3',APT_Band_Original_Value__c = APT_Constants.BAND_3));
            listOfPAV.add(new Apttus_Config2__ProductAttributeValue__c(APT_Band__c = 'BAND 2',APT_Band_Original_Value__c = APT_Constants.BAND_4));
            listOfPAV[0].Apttus_Config2__LineItemID__c = listOfLI[0].id;
            listOfPAV[1].Apttus_Config2__LineItemID__c = listOfLI[1].id;
            listOfPAV[2].Apttus_Config2__LineItemID__c = listOfLI[2].id;
            listOfPAV[3].Apttus_Config2__LineItemID__c = listOfLI[3].id;
            insert listOfPAV;
    
            listOfLI[0].Apttus_Config2__AttributevalueID__c = listOfPAV[0].id;
            listOfLI[1].Apttus_Config2__AttributevalueID__c = listOfPAV[1].id;
            listOfLI[2].Apttus_Config2__AttributevalueID__c = listOfPAV[2].id;
            update listOfLI;
        }
    }

     public static Account insertAccount() {
        Account tobjAcc = new Account();
        tobjAcc.NAME = 'Test Account';
        tobjAcc.Industry='Airlines';
        tobjAcc.Type='Active Customer Account';
        //tobjAcc.APTS_Payment_Method__c='Giro Slip' ;
        return tobjAcc;
    }

    public static Opportunity insertOppty(Account tobjAcc) {
        Opportunity tobjOpty = new Opportunity();
        tobjOpty.Name = 'Test Oppty';
        tobjOpty.AccountId = tobjAcc.ID;
        tobjOpty.CloseDate = (Date.Today()+30).toStartOfMonth();
        //tobjOpty.Enddate__c = Date.today(); 
        //tobjOpty.StageName = 'Idea';
        tobjOpty.StageName = 'Identify';
        tobjOpty.ForecastCategoryName = 'Commit';
        tobjOpty.Type = 'New Logo';
        tobjOpty.LeadSource= 'Aspect AE Prospecting';
        tobjOpty.NextStep='Call';
        //tobjOpty.Service_Location__c= APTS_Constants.COUNTRY_USA;
        //tobjOpty.RecordTypeId = [SELECT id from RecordType where DeveloperName ='MembershipPartnership'].Id;

        //objOpty.Approval_Status__c = 'Pending Approval';
        return tobjOpty;
    }
    public static Apttus_Config2__PriceList__c insertPriceList() {
        Apttus_Config2__PriceList__c tobjPrList = new Apttus_Config2__PriceList__c();
        tobjPrList.NAME = 'NL Pricelist 2015';
        //tobjPrList.CurrencyIsoCode = 'USD'; //APTS_Constants.OPPORTUNITY_CURRENCY_US;
        return tobjPrList;
    }   

    public static Apttus_Config2__PriceList__c insertPriceListNonUS() {
        Apttus_Config2__PriceList__c tobjPrList = new Apttus_Config2__PriceList__c();
        tobjPrList.NAME = 'NL Pricelist 2015';
        //tobjPrList.CurrencyIsoCode = 'CHF';  //APTS_Constants.OPPORTUNITY_CURRENCY_NONUS;
        return tobjPrList;
    }   

    public static Apttus_Config2__PriceListItem__c insertPriceListItem(Apttus_Config2__PriceList__c tobjPrList, Product2 prodSO, Decimal listPrice, string cType,String priceType, String priceMethod,
                                                                            String relatedAdjType, Decimal relatedAdjAmt, String relatedAdjAmtAppliesTo, String priceListGrouping, Decimal defaultQuant) {
        Apttus_Config2__PriceListItem__c pliSO = new Apttus_Config2__PriceListItem__c();
        pliSO.Apttus_Config2__Active__c = true;
        pliSO.Apttus_Config2__PriceType__c = 'One Time';
        if(priceType=='Recurring'){
          pliSO.Apttus_Config2__Frequency__c = 'Monthly';
        }
        pliSO.Apttus_Config2__ListPrice__c = listPrice;
        pliSO.Apttus_Config2__PriceListId__c = tobjPrList.ID;
        pliSO.Apttus_Config2__PriceMethod__c = priceMethod;
        pliSO.Apttus_Config2__PriceUom__c = 'Each';
        pliSO.Apttus_Config2__ProductId__c = prodSO.ID;
        pliso.Apttus_Config2__BillingFrequency__c = 'Yearly';
        pliso.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        pliSO.Apttus_Config2__ChargeType__c = cType;
        pliSO.Apttus_Config2__RelatedAdjustmentType__c=relatedAdjType;
        pliSO.Apttus_Config2__RelatedAdjustmentAmount__c=relatedAdjAmt;
        pliSO.Apttus_Config2__RelatedAdjustmentAppliesTo__c=relatedAdjAmtAppliesTo;
        pliSO.Apttus_Config2__DefaultQuantity__c= defaultQuant;
        return pliSO;
    }    

    public static Apttus_Proposal__Proposal__c insertQuoteProposal(Account tobjAcc, Opportunity tobjOpty, Apttus_Config2__PriceList__c tobjPrList, Contact contSO) {
        Apttus_Proposal__Proposal__c tobjProp = new Apttus_Proposal__Proposal__c();
        tobjProp.Apttus_Proposal__Proposal_Name__c = 'Test Proposal';
        tobjProp.Apttus_Proposal__Account__c = tobjAcc.ID;
        tobjProp.Apttus_Proposal__Opportunity__c =tobjOpty.ID;
        tobjProp.Apttus_QPConfig__PriceListId__c = tobjPrList.ID;
        tobjProp.Apttus_Proposal__Valid_Until_Date__c=Date.today();
        tobjProp.Apttus_QPConfig__AutoActivateOrder__c = true;
        tobjProp.Apttus_QPConfig__ReadyForActivationDate__c=Date.today();
        tobjProp.Apttus_QPConfig__ReadyForBillingDate__c=Date.today();
        tobjProp.Apttus_QPConfig__ReadyForFulfillmentDate__c=Date.today();
        tobjProp.Apttus_Proposal__ExpectedStartDate__c = date.today()-10;
        //tobjProp.APTPS_Selling_Term__c = 15;
        //tobjProp.APTPS_Selling_Frequency__c = 'Daily';
        tobjProp.Apttus_QPConfig__ReadyForRevRecDate__c=Date.today();
        //objProp.License_Term__c='Perpetual';
        tobjProp.Apttus_Proposal__Approval_Stage__c='Draft';
        return tobjProp;
    }    
    public static Apttus_Config2__ProductConfiguration__c insertProductConfiguration(Apttus_Proposal__Proposal__c tobjProp,String status,Apttus_Config2__PriceList__c tobjPrList, Account acctSO){
        Apttus_Config2__ProductConfiguration__c tobjProdConfig=new Apttus_Config2__ProductConfiguration__c();
        tobjProdConfig.Apttus_Config2__BusinessObjectId__c=tobjProp.Id;
        tobjProdConfig.Apttus_QPConfig__Proposald__c=tobjProp.Id;
        tobjProdConfig.Apttus_Config2__BusinessObjectType__c='Proposal';
        tobjProdConfig.Apttus_Config2__PriceListId__c=tobjPrList.Id;
        tobjProdConfig.Apttus_Config2__EffectivePriceListId__c=tobjPrList.Id;
        tobjProdConfig.Apttus_Config2__Status__c=status;
        tobjProdConfig.Apttus_Config2__AccountId__c=acctSO.Id;
        tobjProdConfig.Apttus_Config2__VersionNumber__c=1;
        tobjProdConfig.Name='Test';
        return tobjProdConfig;
    }

    public static Apttus_Config2__TempObject__c insertTempObj(Apttus_Config2__ProductConfiguration__c tobjProdConfig){
        Apttus_Config2__TempObject__c toSO=new Apttus_Config2__TempObject__c();
        toSO.Apttus_Config2__ConfigurationId__c=tobjProdConfig.Id;
        return toSO;
    }
    public static Apttus_Config2__LineItem__c insertLineItem(Product2 prodSO, Product2 optProdSO, ID cartID, Decimal itemSeq, Decimal lineNum, Decimal primaryLineNum, 
                                                                        string lineType, Apttus_Config2__PriceList__c tobjPrList, Apttus_Config2__PriceListItem__c pliSO, 
                                                                        Boolean isPrimaryLine, Decimal parentBundleLineNumber, Decimal quant, String lineStatus, Apttus_Config2__AssetLineItem__c aliSO,
                                                                        Date startDate, Date endDate) {
        Apttus_Config2__LineItem__c liSO = new Apttus_Config2__LineItem__c();
        liSO.Apttus_Config2__ConfigurationId__c = cartID;
        liSO.Apttus_Config2__ProductId__c = prodSO.ID;
        if(optProdSO != null) {
            liSO.Apttus_Config2__OptionId__c = optProdSO.ID;
        }
        //liSO.Apttus_Config2__Quantity__c = 1;
        liSO.Apttus_Config2__ChargeType__c = pliSO.Apttus_Config2__ChargeType__c;
        liSO.Apttus_Config2__IsPrimaryLine__c = isPrimaryLine;
        liSO.Apttus_Config2__IsPrimaryRampLine__c = true;
        liSO.Apttus_Config2__ItemSequence__c = itemSeq;
        liSO.Apttus_Config2__LineNumber__c  = lineNum;
        liSO.Apttus_Config2__PrimaryLineNumber__c = primaryLineNum;
        liSO.Apttus_Config2__LineStatus__c = lineStatus;
        liSO.Apttus_Config2__LineType__c = lineType;
        liSO.Apttus_Config2__StartDate__c = startDate;
        liSO.Apttus_Config2__EndDate__c = endDate;
        liSO.Apttus_Config2__SellingTerm__c = 1;
        liSO.Apttus_Config2__PriceListId__c = tobjPrList.ID;
        liSO.Apttus_Config2__PriceListItemId__c = pliSO.ID;
        liSO.Apttus_Config2__PriceType__c = pliSO.Apttus_Config2__PriceType__c;
        liSO.Apttus_Config2__PriceMethod__c = pliSO.Apttus_Config2__PriceMethod__c;
        liSO.Apttus_Config2__SellingFrequency__c = 'Monthly';
        liSO.Apttus_Config2__PricingStatus__c = 'Pending';
        liSO.Apttus_Config2__ListPrice__c = pliSO.Apttus_Config2__ListPrice__c;
        liSO.Apttus_Config2__BasePrice__c = pliSO.Apttus_Config2__ListPrice__c;
        liSO.Apttus_Config2__ExtendedPrice__c = pliSO.Apttus_Config2__ListPrice__c;
        liSO.Apttus_Config2__NetPrice__c = pliSO.Apttus_Config2__ListPrice__c;
        liSO.APT_New__c = false;
        liSO.APT_Rate_Card_Key__c = 'Test Data';
        liSO.APT_Amendment__c = true;
        
        
        if(parentBundleLineNumber != null) {
            liSO.Apttus_Config2__ParentBundleNumber__c = parentBundleLineNumber;
        }
        liSO.Apttus_Config2__Quantity__c=quant;
        if(aliSO!=null){
            liSO.Apttus_Config2__AssetLineItemId__c=aliSO.Id;
            liSO.Apttus_Config2__AssetQuantity__c=aliSO.Apttus_Config2__Quantity__c;
        }
        return liSO;
    }    

    public static Apttus_Config2__AssetLineItem__c insertAssetLineItem(Product2 prodSO, Product2 optProdSO, Apttus_Config2__PriceListItem__c pliSO, Account acctSO,String lineType, 
                                                                            Decimal itemSeq, Decimal lineNum, Decimal quant, Integer parentBundleNum, Apttus_Config2__AssetLineItem__c bundleAsset,
                                                                            Decimal basePrice, Decimal extendedPrice, Decimal netPrice, Decimal sellingTerm,Date startDate, Date endDate){
        Apttus_Config2__AssetLineItem__c aliSO=new Apttus_Config2__AssetLineItem__c();
        aliSO.Apttus_Config2__ProductId__c=prodSO.Id;
        if(optProdSO!=null){
            aliSO.Apttus_Config2__OptionId__c=optProdSO.Id;
        }
        aliSO.Apttus_Config2__AccountId__c=acctSO.Id;
        aliSO.Apttus_Config2__BillToAccountId__c=acctSO.Id;
        aliSO.Apttus_Config2__ShipToAccountId__c=acctSO.Id;
        aliSO.Apttus_Config2__AssetStatus__c='Activated';
        aliSO.Apttus_Config2__ShipToAccountId__c = acctSO.id;
        aliSO.Apttus_Config2__LineType__c=lineType;
        aliSO.Apttus_Config2__ChargeType__c=pliSO.Apttus_Config2__ChargeType__c;
        aliSO.Apttus_QPConfig__ProposalId__c=objProp.id;
        aliSO.Apttus_Config2__ItemSequence__c=itemSeq;
        aliSO.Apttus_Config2__LineNumber__c=lineNum;
        aliSO.Apttus_Config2__Quantity__c=quant;
        aliSO.Apttus_Config2__AssetStatus__c='New';
        aliSO.Apttus_Config2__ParentBundleNumber__c=parentBundleNum;
        //aliSO.Apttus_Config2__AttributeValueId__c =prodAttrVal.Id;
        if(parentBundleNum==null){
            //aliSO.Apttus_Config2__HasAttributes__c=true;
            aliSO.Apttus_Config2__HasOptions__c=true;
        }
        if(bundleAsset!=null){
            aliSO.Apttus_Config2__BundleAssetId__c=bundleAsset.Id;
        }
        aliSO.Apttus_Config2__PriceType__c = pliSO.Apttus_Config2__PriceType__c;
        aliSO.Apttus_Config2__PriceMethod__c = pliSO.Apttus_Config2__PriceMethod__c;
        aliSO.Apttus_Config2__SellingFrequency__c = pliSO.Apttus_Config2__Frequency__c;
        aliSO.Apttus_Config2__ListPrice__c = pliSO.Apttus_Config2__ListPrice__c;
        aliSO.Apttus_Config2__BasePriceMethod__c = 'Per Unit';
        aliSO.Apttus_Config2__BasePrice__c = basePrice;
        aliSO.Apttus_Config2__ExtendedPrice__c = extendedPrice;
        aliSO.Apttus_Config2__NetPrice__c = netPrice;
        aliSO.Apttus_Config2__SellingTerm__c=sellingTerm;
        aliSO.Apttus_Config2__StartDate__c=startDate;
        aliSO.Apttus_Config2__EndDate__c=endDate;
        aliSo.Apttus_Config2__IsPrimaryLine__c=true;
        aliso.Apttus_Config2__AdjustedPrice__c = netPrice;
        aliso.Apttus_Config2__BaseExtendedPrice__c = netPrice;
        aliso.Apttus_Config2__NetUnitPrice__c = netprice;
        
        //remember get base price and all from pli  
        return aliSO;
    }
    public static void CreateAllConfigSettings(){
        //CreateCustomeSetting1();
        CreateCustomeSetting2();
        CreateCustomeSetting3();
        CreateCustomeSetting4();
        CreateCustomeSetting5();
        CreateCustomeSetting6();
        CreateCustomeSetting7();
        CreateCustomeSetting8();
        CreateCustomeSetting9();
        CreateCustomeSetting0();
        CreateCustomSettingNew1();
        InsertInstalledProductsSettings();
    }
    private static void CreateCustomeSetting2(){
        Apttus_Proposal__ProposalSystemProperties__c objCustSett = Apttus_Proposal__ProposalSystemProperties__c.getValues('System Properties');
        if(objCustSett == null) {
            objCustSett = new Apttus_Proposal__ProposalSystemProperties__c(Name= 'System Properties'
            ,Apttus_Proposal__DefaultOpportunityQuoteOwner__c='Opportunity Owner'
            ,Apttus_Proposal__DefaultQuoteAgreementOwner__c='Quote Owner'
            ,Apttus_Proposal__EmailTemplateForPresentingProposals__c='APTS_Email_Template_for_presenting_Proposal'
            ,Apttus_Proposal__InstanceUrl__c='https://cs81.salesforce.com'
            ,Apttus_Proposal__MergeCallTimeoutMillis__c=60000
            ,Apttus_QPConfig__AutoCreateOrder__c=TRUE
            //,Apttus_QPDSign__AutoSelectAttachment__c=TRUE
            ,Apttus_Proposal__MergeWebserviceEndpoint__c='https://mergews.apttus.net/cgi-bin/3.6.2/MergeServer/Bin/MMCGI.exe'
            );
            insert objCustSett;
        }
    }
    private static void CreateCustomeSetting3(){
        Apttus_Config2__ConfigSystemProperties__c objCustSett = Apttus_Config2__ConfigSystemProperties__c.getValues('System Properties');
        if(objCustSett == null) {
            objCustSett = new Apttus_Config2__ConfigSystemProperties__c(Name= 'System Properties'
            ,Apttus_Config2__ActionsColumnPosition__c=null
            ,Apttus_Config2__AdminUser__c=null
            ,Apttus_Config2__AutoFinalizeOnCartApproval__c=TRUE
            ,Apttus_Config2__AutoSyncOnCartApproval__c=TRUE
            ,Apttus_Config2__BaseProductRelationField__c=null
            ,Apttus_Config2__BypassSharing__c=TRUE
            ,Apttus_Config2__BypassShoppingCart__c=FALSE
            ,Apttus_Config2__CascadeSharedAttributeUpdates__c=FALSE
            ,Apttus_Config2__CleanupInvalidRulePrompt__c=FALSE
            ,Apttus_Config2__ComputeTotalsInSeparateStep__c=FALSE
            ,Apttus_Config2__CSSOverride__c=null
            ,Apttus_Config2__CurrencyFieldPrecision__c=2
            ,Apttus_Config2__CustomAssetActionLabelName__c=null
            ,Apttus_Config2__CustomAssetActionPage__c=null
            ,Apttus_Config2__CustomOptionAttributePage__c=null
            ,Apttus_Config2__CustomPricingFields__c=null
            ,Apttus_Config2__DefaultProductsPage__c='Apttus_Config2__Cart'
            ,Apttus_Config2__AlertSelectedExclude__c=TRUE
            ,Apttus_Config2__DeferPricingUntilCart__c=FALSE
            ,Apttus_Config2__DeferValidationCheckInBundles__c=TRUE
            ,Apttus_Config2__DirectConfigureAssetActions__c=null
            ,Apttus_Config2__DisableChargeTypeTotaling__c=FALSE
            ,Apttus_Config2__DisableConstraintRules__c=FALSE
            ,Apttus_Config2__DisableExistingAssetPricing__c=FALSE
            ,Apttus_Config2__DisplayCartActionsAsDropdown__c=FALSE
            ,Apttus_Config2__EnableAggregatePricing__c=TRUE
            ,Apttus_Config2__EnableAutoReprice__c=FALSE
            ,Apttus_Config2__EnableAutoSequencingForOptions__c=FALSE
            ,Apttus_Config2__EnableDefaultingForOptions__c=FALSE
            ,Apttus_Config2__EnableDefaultingForProducts__c=TRUE
            ,Apttus_Config2__EnableExternalPricing__c=FALSE
            ,Apttus_Config2__EnableFieldExpression__c=TRUE
            ,Apttus_Config2__SkipPricingOnSelectPages__c=FALSE
            ,Apttus_Config2__EnableLocation__c=TRUE
            ,Apttus_Config2__EnableMatrixPricingForOptions__c=TRUE
            ,Apttus_Config2__EnhancedSearchURL__c=null
            ,Apttus_Config2__FixedButtonBar__c=FALSE
            ,Apttus_Config2__ShowErrorInHeader__c=FALSE
            ,Apttus_Config2__GuidePageDefault__c=null
            ,Apttus_Config2__HideAssetActions__c=null
            ,Apttus_Config2__HideCopyAction__c=FALSE
            ,Apttus_Config2__HideGrandTotal__c=FALSE
            ,Apttus_Config2__HideResolveConfigLink__c=FALSE
            ,Apttus_Config2__HideSubtotalsInCart__c=FALSE
            ,Apttus_Config2__IndicateErrorTypeExclude__c=FALSE
            ,Apttus_Config2__IndicateWarningTypeExclude__c=FALSE
            ,Apttus_Config2__InstanceUrl__c='https://cs81.salesforce.com'
            ,Apttus_Config2__KeepAbandonedCarts__c=FALSE
            ,Apttus_Config2__MaxAdjustmentLines__c=1
            ,Apttus_Config2__MaxConstraintRulesRoundTrip__c=3
            ,Apttus_Config2__MiscChargeTypes__c=null
            ,Apttus_Config2__OptionLineItemColumns__c=null
            ,Apttus_Config2__OptionPricingChunkSize__c=100
            ,Apttus_Config2__OptionProductColumns__c=null
            ,Apttus_Config2__OptionsPageDefault__c='Apttus_Config2__Cart'
            ,Apttus_Config2__PercentageFieldPrecision__c=2
            ,Apttus_Config2__PreventErrorExcludeSelection__c=FALSE
            ,Apttus_Config2__PreventErrorTypeExcludeSelection__c=FALSE
            ,Apttus_Config2__PricingBatchSize__c=null
            ,Apttus_Config2__PricingProfile__c='Advance'
            ,Apttus_Config2__ProductAttributeDetailPage__c='Apttus_Config2__Cart'
            ,Apttus_Config2__ProductAttributeExtensionLookupFields__c=null
            ,Apttus_Config2__ProductTotalingHierarchy__c=null
            ,Apttus_Config2__QuantityFieldPrecision__c=2
            ,Apttus_Config2__SearchAttributeValuePage__c='Cart'
            ,Apttus_Config2__ResolveConfigurationPageDefault__c='Apttus_Config2__ResolveConfig'
            ,Apttus_Config2__RunFinalizationTaskInAsyncMode__c=FALSE
            ,Apttus_Config2__SaveOnAllActions__c=TRUE
            ,Apttus_Config2__SearchCategoryDefault__c='AllCategories'
            ,Apttus_Config2__ShowAdminSidebar__c=FALSE
            ,Apttus_Config2__ShowHeader__c=FALSE
            ,Apttus_Config2__ShowInfoInHeader__c=TRUE
            ,Apttus_Config2__ShowMessageInline__c=FALSE
            ,Apttus_Config2__AlertInclude__c=FALSE
            ,Apttus_Config2__TabViewInConfigureBundle__c=FALSE
            ,Apttus_Config2__ShowWarningInHeader__c=FALSE
            ,Apttus_Config2__SearchAttributeDefaultPage__c=null
            ,Apttus_Config2__SkipReview__c=TRUE
            ,Apttus_Config2__StaticCriteriaFields__c=null
            ,Apttus_Config2__TotalingGroupType__c='Category'
            ,Apttus_Config2__UseButtonToSaveSelection__c=FALSE
            ,Apttus_Config2__UseEnhancedCSS__c=FALSE
            ,Apttus_Config2__ViewCartPage__c='Apttus_Config2__Cart'
            ,Apttus_Config2__ViewCartTotalCustomFields__c=null
            ,Apttus_Config2__ViewCartCustomFields__c = 'View_Rate_Card__c,Test_View_Rate_Card__c,APT_Charge_Code_Formula__c,APT_Get_Renewal_Rates__c,APT_Classification__c,Apttus_Config2__AttributeValueId__r.Category__c,Apttus_Config2__ProductId__r.ProductCode'
            ,Apttus_Config2__ViewCartCustomFields2__c = 'Apttus_Config2__AttributeValueId__r.APT_Minimum_Quantity__c,Apttus_Config2__ProductId__r.APT_Sync_with_Opportunity__c,Apttus_Config2__OptionId__r.APT_Sync_with_Opportunity__c,Apttus_CQApprov__Approval_Status__c'
            
            );
            insert objCustSett;
            Apttus_Config2__ConfigLineItemCustomFields__c cusObj = new Apttus_Config2__ConfigLineItemCustomFields__c();
            cusObj.Name = '1';
            cusObj.Apttus_Config2__CustomFieldNames__c = 'APT_Cascade_Adjustments__c,APT_Rate_Card_Key__c,APT_Pricing_Reason__c,APT_Competitors__c,Apttus_Config2__OptionId__c,Apttus_Config2__ParentBundleNumber__c,APT_New__c, Apttus_CQApprov__Approval_Status__c';
            cusObj.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_International_CO__c,Apttus_Config2__ProductId__r.Name,Apttus_Config2__AdjustmentType__c,Apttus_Config2__AttributeValueId__c,Apttus_Config2__AttributeValueId__r.APT_Band__c';
            cusObj.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__AttributeValueId__r.APT_Band_Original_Value__c,APT_Band__c,Apttus_Config2__IsPrimaryLine__c,Apttus_Config2__LineType__c,APT_Product_Name__c, Apttus_Config2__PricingStatus__c,Apttus_Config2__PriceListItemId__c,APT_Is_Higher_Band_Offered__c';
            cusObj.Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__OptionId__r.Name,APT_Amendment__c';
            insert cusObj;
        }
    }
    private static void CreateCustomeSetting4(){
        Apttus_Config2__ConfigCustomClasses__c objCustSett = Apttus_Config2__ConfigCustomClasses__c.getValues('System Properties');
        if(objCustSett == null) {
            objCustSett = new Apttus_Config2__ConfigCustomClasses__c(Name= 'System Properties'
            ,Apttus_Config2__PricingCallbackClass__c='APT_PricingCallBack'
            );
            insert objCustSett;
        }
    }
    private static void CreateCustomeSetting5(){
        Apttus__ComplySystemProperties__c objCustSett = Apttus__ComplySystemProperties__c.getValues('System Properties');
        if(objCustSett == null) {
            objCustSett = new Apttus__ComplySystemProperties__c(Name= 'System Properties'
            ,Apttus__AdminUser__c=null
            ,Apttus__AgreementNumberFieldForImportedDocs__c=null
            ,Apttus__AllowPDFSelectionOverride__c=TRUE
            ,Apttus__AllowPrivateSelectionOverride__c=TRUE
            ,Apttus__AllowReconcileSelectionOverride__c=TRUE
            ,Apttus__ApiUserKey__c=null
            ,Apttus__AutoEnablePDFForFinalDocs__c=TRUE
            ,Apttus__AutoEnablePrivateIndicator__c=FALSE
            ,Apttus__AutoEnableReconciliation__c=TRUE
            ,Apttus__AutoInsertHeaderFooterData__c=FALSE
            //,Apttus_CMDSign__AutoSelectAttachment__c=TRUE
            //,Apttus_CMDSign__FieldNameAutoSelectRecipient__c=null
            //,Apttus_CMConfig__AutoSyncWithOpportunity__c=TRUE
            //,Apttus_CMDSign__AutoSelectMultipleRecipients__c=FALSE
            ,Apttus__BypassSharing__c=FALSE
            ,Apttus__ContractSummaryTemplate__c=null
            ,Apttus__DefaultOpportunityAgreementOwner__c='Opportunity Owner'
            ,Apttus__DocumentNamingConvention__c=null
            ,Apttus__DocumentStructureFX2ForImportedDocs__c=TRUE
            ,Apttus__DocumentVersioningNamingConvention__c=null
            ,Apttus__EmailTemplateForCheckinNotification__c=null
            ,Apttus__EnableClauseApprovals__c=TRUE
            //,Apttus_CMDSign__EnableDocumentPreviewInDocuSign__c=TRUE
            ,Apttus__EnableDocumentVersioning__c=TRUE
            ,Apttus__EnableMergeCallDebug__c=TRUE
            ,Apttus__EnableMultipleCheckout__c=false
            ,Apttus__EnablePDFSecurity__c=FALSE
            ,Apttus__EnableSubmitMergeCall__c=TRUE
            ,Apttus__EnableVersionControl__c=TRUE
            //,Apttus_CMDSign__ESignatureStrictMode__c=FALSE
            ,Apttus__FooterDatetimeFormatForImportedDocs__c=null
            ,Apttus__InstanceUrl__c='https://cs81.salesforce.com'
            ,Apttus__MaxChildLevel__c=null
            ,Apttus__MergeCallTimeoutMillis__c=60000
            ,Apttus__MergeWebserviceEndpoint__c='https://mergews.apttus.net/cgi-bin/MergeServer/Bin/MMCGI.exe'
            //,Apttus_CMDSign__OneClickSend__c=FALSE
            ,Apttus__PDFOwnerPwd__c=null
            ,Apttus__PublishAuthorEvents__c=TRUE
            ,Apttus__PublishMergeEvents__c=TRUE
            //,Apttus_CMDSign__SelectAttachmentsFromRSPCAgreements__c=FALSE
            ,Apttus_CMConfig__SyncBundleUsingLineItems__c=FALSE
            ,Apttus_CMConfig__SyncOptionProducts__c=FALSE
            ,Apttus__UseAgreementLocksForVersioning__c=FALSE
            );
            insert objCustSett;
        }
    }
    private static void CreateCustomeSetting6(){
        Apttus_Approval__ApprovalsSystemProperties__c objCustSett = Apttus_Approval__ApprovalsSystemProperties__c.getValues('System Properties');
        if(objCustSett == null) {
            objCustSett = new Apttus_Approval__ApprovalsSystemProperties__c(Name= 'System Properties'
            ,Apttus_Approval__AdminUser__c=null
            ,Apttus_Approval__ApprovalTaskPrefix__c=null
            ,Apttus_Approval__BackupAdminProfile__c='System Administrator'
            ,Apttus_Approval__BackupAdminUser__c='Clara Tiphaine'
            ,Apttus_Approval__BackupFilterPage__c=null
            ,Apttus_Approval__BypassSharing__c=TRUE
            ,Apttus_Approval__EmailApprovalServiceAddress__c=null
            ,Apttus_Approval__EmailSenderDisplayName__c=null
            ,Apttus_Approval__EnableApprovalRequestAutoEscalation__c=TRUE
            ,Apttus_Approval__EnableEmailApprovalResponse__c=TRUE
            ,Apttus_Approval__InstanceUrl__c='https://cs81.salesforce.com'
            ,Apttus_Approval__ReassignFilterPage__c=null
            ,Apttus_Approval__ReassignMyApprovalsFilterPage__c=null
            ,Apttus_Approval__UIAssigneeSearchPageSize__c=null
            ,Apttus_Approval__UICustomAssigneeObjectTypes__c=null
            ,Apttus_CQApprov__CartApprovalContextType__c='cart'
            ,Apttus_CQApprov__CartApprovalPreviewPage__c=null
            ,Apttus_CQApprov__EnableApprovalCheckOnQuoteUpdate__c=TRUE
            );
            insert objCustSett;
        }
    }
    private static void CreateCustomeSetting7(){
        Apttus_Approval__ApprovalsCustomConfig__c objCustSett = Apttus_Approval__ApprovalsCustomConfig__c.getValues('Apttus_Config2__LineItem__c');
        if(objCustSett == null) {
            objCustSett = new Apttus_Approval__ApprovalsCustomConfig__c(Name= 'Apttus_Config2__LineItem__c'
            ,Apttus_Approval__ApprovalContextType__c='Multiple'
            ,Apttus_Approval__ApprovalGroupStatusField__c=null
            ,Apttus_Approval__ApprovalStatusField__c='Approval_Status__c'
            ,Apttus_Approval__ApprovalSummaryPage__c='null'
            ,Apttus_Approval__AssignmentEmailTemplate__c='Apttus Cart Approval Notification (Assignment)'
            ,Apttus_Approval__BackupAdminUser__c=null
            ,Apttus_Approval__CancellationEmailTemplate__c='Apttus Cart Approval Notification (Assignment)'
            ,Apttus_Approval__ChildObjectTypes__c='Apttus_Config2__LineItem__c'
            ,Apttus_Approval__ChildObjectTypes2__c='Apttus_Config2__LineItem__c'
            ,Apttus_Approval__EnableAdhocApproval__c=TRUE
            ,Apttus_Approval__EscalationEmailTemplate__c='Apttus Cart Approval Notification (Assignment)'
            ,Apttus_Approval__MyApprovalsPage__c='APTPS_MyApprovalsCustom'
            ,Apttus_Approval__NotifyOnlyEmailTemplate__c='Apttus Cart Approval Notification (Assignment)'
            ,Apttus_Approval__ParentReferenceField__c=null
            ,Apttus_Approval__PreviewPage__c=null
            ,Apttus_Approval__ReassignmentEmailTemplate__c='Apttus Cart Approval Notification (Assignment)'
            );
            insert objCustSett;
        }
    }
    private static void CreateCustomeSetting8(){
        Apttus_Approval__ApprovalsCustomConfig__c objCustSett = Apttus_Approval__ApprovalsCustomConfig__c.getValues('ProductConfiguration__c');
        if(objCustSett == null) {
            objCustSett = new Apttus_Approval__ApprovalsCustomConfig__c(Name= 'ProductConfiguration__c'
            ,Apttus_Approval__ApprovalContextType__c='Multiple'
            ,Apttus_Approval__ApprovalGroupStatusField__c=null
            ,Apttus_Approval__ApprovalStatusField__c='Approval_Status__c'
            ,Apttus_Approval__ApprovalSummaryPage__c='null'
            ,Apttus_Approval__AssignmentEmailTemplate__c='Apttus Cart Approval Notification (Assignment)'
            ,Apttus_Approval__BackupAdminUser__c=null
            ,Apttus_Approval__CancellationEmailTemplate__c='Apttus Cart Approval Notification (Assignment)'
            ,Apttus_Approval__ChildObjectTypes__c='Apttus_Config2__LineItem__c'
            ,Apttus_Approval__ChildObjectTypes2__c='Apttus_Config2__LineItem__c'
            ,Apttus_Approval__EnableAdhocApproval__c=TRUE
            ,Apttus_Approval__EscalationEmailTemplate__c='Apttus Cart Approval Notification (Assignment)'
            ,Apttus_Approval__MyApprovalsPage__c='APTPS_MyApprovalsCustom'
            ,Apttus_Approval__NotifyOnlyEmailTemplate__c='Apttus Cart Approval Notification (Assignment)'
            ,Apttus_Approval__ParentReferenceField__c=null
            ,Apttus_Approval__PreviewPage__c=null
            ,Apttus_Approval__ReassignmentEmailTemplate__c='Apttus Cart Approval Notification (Assignment)'
            );
            insert objCustSett;
        }
    }
    private static void CreateCustomeSetting9(){
        Apttus_Approval__ApprovalsCustomConfig__c objCustSett = Apttus_Approval__ApprovalsCustomConfig__c.getValues('Apttus_Proposal__Proposal__c');
        if(objCustSett == null) {
            objCustSett = new Apttus_Approval__ApprovalsCustomConfig__c(Name= 'Apttus_Proposal__Proposal__c'
            ,Apttus_Approval__ApprovalContextType__c='Multiple'
            ,Apttus_Approval__ApprovalGroupStatusField__c=null
            ,Apttus_Approval__ApprovalStatusField__c='Approval_Status__c'
            ,Apttus_Approval__ApprovalSummaryPage__c='null'
            ,Apttus_Approval__AssignmentEmailTemplate__c='Apttus Quote Approval Notification (Assignment)'
            ,Apttus_Approval__BackupAdminUser__c=null
            ,Apttus_Approval__CancellationEmailTemplate__c='Apttus Quote Approval Notification (Cancellation)'
            ,Apttus_Approval__ChildObjectTypes__c='Apttus_Proposal__Proposal_Line_Item__c'
            ,Apttus_Approval__ChildObjectTypes2__c='Apttus_Proposal__Proposal_Line_Item__c'
            ,Apttus_Approval__EnableAdhocApproval__c=TRUE
            ,Apttus_Approval__EscalationEmailTemplate__c='Apttus Quote Approval Notification (Reassignment)'
            ,Apttus_Approval__MyApprovalsPage__c='APTPS_MyApprovalsCustom'
            ,Apttus_Approval__NotifyOnlyEmailTemplate__c='Apttus Quote Approval Notification (Notify Only)'
            ,Apttus_Approval__ParentReferenceField__c=null
            ,Apttus_Approval__PreviewPage__c=null
            ,Apttus_Approval__ReassignmentEmailTemplate__c='Apttus Quote Approval Notification (Reassignment)'
            );
            insert objCustSett;
        }
    }
    private static void CreateCustomeSetting0(){
        Apttus_Approval__ApprovalsCustomConfig__c objCustSett = Apttus_Approval__ApprovalsCustomConfig__c.getValues('Apttus__APTS_Agreement__c');
        if(objCustSett == null) {
            objCustSett = new Apttus_Approval__ApprovalsCustomConfig__c(Name= 'Apttus__APTS_Agreement__c'
            ,Apttus_Approval__ApprovalContextType__c='Multiple'
            ,Apttus_Approval__ApprovalGroupStatusField__c=null
            ,Apttus_Approval__ApprovalStatusField__c=null
            ,Apttus_Approval__ApprovalSummaryPage__c='APTPS_AgreementApprovalSummaryCustom'
            ,Apttus_Approval__AssignmentEmailTemplate__c='Apttus Agreement Approval Notification (Assignment)'
            ,Apttus_Approval__BackupAdminUser__c=null
            ,Apttus_Approval__CancellationEmailTemplate__c='Apttus Agreement Approval Notification (Cancellation)'
            ,Apttus_Approval__ChildObjectTypes__c='Apttus__AgreementLineItem__c'
            ,Apttus_Approval__ChildObjectTypes2__c='Apttus__AgreementLineItem__c'
            ,Apttus_Approval__EnableAdhocApproval__c=TRUE
            ,Apttus_Approval__EscalationEmailTemplate__c='Apttus Agreement Approval Notification (Escalation)'
            ,Apttus_Approval__MyApprovalsPage__c='APTPS_MyApprovalsCustom'
            ,Apttus_Approval__NotifyOnlyEmailTemplate__c='Apttus Agreement Approval Notification (Notify Only)'
            ,Apttus_Approval__ParentReferenceField__c=null
            ,Apttus_Approval__PreviewPage__c=null
            ,Apttus_Approval__ReassignmentEmailTemplate__c='Apttus Agreement Approval Notification (Reassignment)'
            );
            insert objCustSett;
        }
            /*APTS_Asset_Renewal__c objCustSett1;
            objCustSett1 = new APTS_Asset_Renewal__c(Name='Asset Renewal (User)'
            ,APTS_Auto_Renewal_Contact_Email__c='cahjolia@apttus.com'
            ,Auto_Renewal_Days__c=5
            ,SetupOwnerId=UserInfo.getUserId()
            ,Type_of_Renewal__c='Auto');
            insert objCustSett1;
            
            APTS_Asset_ManualRenewal__c objCustSett2;
            objCustSett2 = new APTS_Asset_ManualRenewal__c(Name='Asset Manual Renewal (Profile)'
            ,Instance_URL_Managed_Renewal__c = 'https://apttus-config2.cs81.visual.force.com'
            ,Manual_Renewal_Contact_Email__c = 'cahjolia@apttus.com'
            ,SetupOwnerId=UserInfo.getUserId()
            ,Manual_Renewal_Days__c = 5
            ,Type_of_Renewal__c = 'Manual');
            insert objCustSett2;
        */
    }
    private static void CreateBillingPref(){
        Apttus_Config2__BillingPreference__c objBP = new Apttus_Config2__BillingPreference__c();
        objBP.Name = 'Org Level Preference';
        objBP.Apttus_Config2__Active__c=TRUE;
        objBP.Apttus_Config2__AllowPaymentTermOverride__c=TRUE;
        objBP.Apttus_Config2__AllowPrefOverride__c=FALSE;
        objBP.Apttus_Config2__BillingCycleStart__c='Period Start Date';
        objBP.Apttus_Config2__BillingInterval__c='Anytime';
        objBP.Apttus_Config2__Default__c=TRUE;
        objBP.Apttus_Config2__DoNotCreateInformational__c=FALSE;
        objBP.Apttus_Config2__HideInformational__c=FALSE;
        objBP.Apttus_Config2__InvoiceDeliveryMethod__c='Email';
        objBP.Apttus_Config2__InvoiceOutputFormat__c='PDF';
        objBP.Apttus_Config2__PrefLevel__c='Organization';
        objBP.Apttus_Config2__ProrationPeriodTreatment__c='Separate Period';
        objBP.Apttus_Config2__TaxLevel__c='Account';
        insert objBP;
        gloobjBP = objBP;
    }
    

    public static void CreateApprReq(id OptyID){
    Apttus_Approval__Approval_Request__c objAR = new Apttus_Approval__Approval_Request__c();
        objAR.Apttus_Approval__ProcessInstanceId__c= null;
        objAR.Apttus_Approval__Active__c= TRUE;
        objAR.Apttus_Approval__ApprovalFromEmail__c= false;
        objAR.Apttus_Approval__Auto_Complete__c= false;
        objAR.Apttus_Approval__AutoEscalate__c= false;
        objAR.Apttus_Approval__AutoReapprove__c= false;
        objAR.Apttus_Approval__CanEscalate__c= false;
        objAR.Apttus_Approval__ContinuePolicyApprovalOnAReject__c= false;
        objAR.Apttus_Approval__EscalatedToHighestLevel__c= false;
        objAR.Apttus_Approval__HasAttachments__c= false;
        objAR.Apttus_Approval__HasDelegateApprover__c= false;
        objAR.Apttus_Approval__InEscalation__c= false;
        objAR.Apttus_Approval__IsAdhoc__c= false;
        objAR.Apttus_Approval__IsAutoReapprovalEnabled__c= false;
        objAR.Apttus_Approval__IsSubprocess__c= false;
        objAR.Apttus_Approval__Notify_Only__c= false;
        objAR.Apttus_Approval__Send_Email__c= TRUE;
        objAR.Apttus_Approval__Workflow_Trigger_Added_Comments__c= false;
        objAR.Apttus_Approval__Date__c= Date.Today();
        objAR.Apttus_Approval__DateAssigned__c= Date.Today();
        objAR.Apttus_Approval__StepSequence__c= 1.007;
        objAR.Apttus_Approval__Step_Group_Seq_Number__c= 1;
        objAR.Apttus_Approval__Related_Opportunity__c= OptyID;
        objAR.Apttus_Approval__Approval_Status__c= 'Assigned';
        objAR.Apttus_Approval__Assigned_To_Type__c= 'User';
        objAR.Apttus_Approval__RequestType__c= 'Standard';
        //objAR.CurrencyIsoCode= 'CHF';
        
        objAR.Apttus_Approval__Action_Approve_Id__c= '00b70000000xoxK';
        objAR.Apttus_Approval__Action_Reassign_Id__c= '00b70000000xoxJ';
        objAR.Apttus_Approval__Assigned_To_Id__c= '00511000002HOfpAAG';
        objAR.Apttus_Approval__Object_Id__c= OptyID;
        objAR.Apttus_Approval__Approval_Process__c= 'a71110000004EEXAA2';
        objAR.Apttus_Approval__Group__c= 'a71110000004EEYAA2';
        objAR.Apttus_Approval__Step__c= 'a71110000004EIiAAM';
        objAR.Apttus_Approval__Group_Unique_Id__c= '3qeJggoKdina910pFbZ1yfS0d';
        objAR.Apttus_Approval__Assigned_To_Name__c= 'Neev Shah';
        objAR.Apttus_Approval__Object_Name__c= '- Membership / Partnership - 2016';
        objAR.Apttus_Approval__Object_Type__c= 'Opportunity';
        objAR.Apttus_Approval__Step_Name__c= 'CGA';
        objAR.Apttus_Approval__StepLabel__c= 'CGA';
        objAR.Apttus_Approval__Approver_Comments__c= 'Assigned - System Info - Item previously on-hold is now available for approval 2016-02-19 21:54:10+0100 On-Hold for consolidation - System Info - Waiting for approval step: CBO/ELT Chair 2016-02-19 21:54:09+0100';
        objAR.Apttus_Approval__Initial_Submitter__c= UserInfo.getUserId();
        objAR.Apttus_Approval__Related_Opportunity_Owner__c= UserInfo.getUserId();
        //objAR.APTS_Exclusion_Track__c = 'Region';
        insert objAR;
        gloObjAR = objAR;
    }
    
    private static void CreateCustomSettingNew1(){
            /*APTS_ELT_Approval_Propoerties__c objCustSett1;
            objCustSett1 = new APTS_ELT_Approval_Propoerties__c(Name='Approval Criteria for Non US Region'
            ,APTS_Approved_Count__c=0
            ,APTS_ELT_Chair_Approval_Count__c=0
            ,APTS_ELT_Chair_Rejection_Count__c=0
            ,APTS_Rejection_Count__c=0
            ,APTS_US_Member_Rejection_Count__c=0
            ,APTS_US_Members_Approval_Count__c=0
            ,APTS_Is_US_Region__c=false);
            insert objCustSett1;

            APTS_ELT_Approval_Propoerties__c objCustSett2;
            objCustSett2 = new APTS_ELT_Approval_Propoerties__c(Name='Rejection Criteria for US Region'
            ,APTS_Approved_Count__c=0
            ,APTS_ELT_Chair_Approval_Count__c=0
            ,APTS_ELT_Chair_Rejection_Count__c=0
            ,APTS_Rejection_Count__c=0
            ,APTS_US_Member_Rejection_Count__c=0
            ,APTS_US_Members_Approval_Count__c=0
            ,APTS_Is_US_Region__c=true);
            insert objCustSett2;

            APTS_ELT_Approval_Propoerties__c objCustSett3;
            objCustSett3 = new APTS_ELT_Approval_Propoerties__c(Name='Rejection Criteria for Non US Region'
            ,APTS_Approved_Count__c=0
            ,APTS_ELT_Chair_Approval_Count__c=0
            ,APTS_ELT_Chair_Rejection_Count__c=0
            ,APTS_Rejection_Count__c=0
            ,APTS_US_Member_Rejection_Count__c=0
            ,APTS_US_Members_Approval_Count__c=0
            ,APTS_Is_US_Region__c=false);
            insert objCustSett3;

            APTS_ELT_Approval_Propoerties__c objCustSett4;
            objCustSett4 = new APTS_ELT_Approval_Propoerties__c(Name='Approval Criteria for US Region'
            ,APTS_Approved_Count__c=0
            ,APTS_ELT_Chair_Approval_Count__c=0
            ,APTS_ELT_Chair_Rejection_Count__c=0
            ,APTS_Rejection_Count__c=0
            ,APTS_US_Member_Rejection_Count__c=0
            ,APTS_US_Members_Approval_Count__c=0
            ,APTS_Is_US_Region__c=true);
            insert objCustSett4;
*/


    }
    
    public static Contact CreateContact( id accID){
        
        Contact con= new contact();
        con.LastName='TestConm';
        con.AccountId=accId;
        con.Email='Test@test.com';
        return con;
        
    }
    public static void InsertInstalledProductsSettings(){
        Apttus_Config2__InstalledProductsSettings__c  InstalledProducts= new Apttus_Config2__InstalledProductsSettings__c();
        InstalledProducts.name='Primary Setting';
        InstalledProducts.Apttus_Config2__DefaultRenewalTerm__c=12;
        insert InstalledProducts;
    }

    public static void ExecuteBasicCPQFlow(){
            //Dont put any more code in this method; call this method and append any extra line after that call
            APTS_TestDataFactory.CreateAllConfigSettings();
            APTS_TestDataFactory.CreateAllBasicData(true);
            update APTS_TestDataFactory.objOpty;
            
            Apttus_Config2.PricingWebService.updatePriceForCart(APTS_TestDataFactory.GloCartID);
            Apttus_Config2.CPQWebService.finalizeConfiguration(APTS_TestDataFactory.GloCartID);
            APTS_TestDataFactory.objProp.Apttus_QPConfig__ConfigurationFinalizedDate__c = DateTime.now();
            update APTS_TestDataFactory.objProp;
            Apttus_QPConfig.QPConfigWebService.afterFinalizeConfiguration(APTS_TestDataFactory.GloCartID);
            Apttus_QPConfig.QPConfigWebService.syncConfiguration(APTS_TestDataFactory.GloCartID);
            Apttus_QPConfig.QPConfigWebService.afterSyncConfiguration(APTS_TestDataFactory.GloCartID);
            list<Apttus_Proposal__Proposal_Line_Item__c> lstPPL = [Select id from Apttus_Proposal__Proposal_Line_Item__c where Apttus_Proposal__Proposal__c=:APTS_TestDataFactory.objProp.id];
            for (Apttus_Proposal__Proposal_Line_Item__c ObjPPL: lstPPL){
                objPPL.Apttus_QPConfig__BillingPreferenceId__c = APTS_TestDataFactory.gloobjbp.id;
            }
            update lstPPL;
    }
}