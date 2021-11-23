/**
Description: This batch job will create domestic pricing - Price List Item and Price Matrix records
Created By - Mausam Padhiyar
Created Date - 7th Oct, 20154
Last Modified By - Mahesh Patel
Last Modified Date - 20th Oct, 2020
Change Description - Added startrack product's PLI and PM creation logic  
**/
global class APT_DomesticPricingPLIAndPMBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global set<String> setErrorMessage {get;set;}    
    global String defaultPriceListID {get;set;}  
    
    /**
        constructor
    **/
    global APT_DomesticPricingPLIAndPMBatch() {
        setErrorMessage = new set<String>();
        defaultPriceListID = '';
    }
    
    /**
        start
    **/
    global Database.QueryLocator start(Database.BatchableContext bc) {      
        If(Test.isRunningTest()){  
            return Database.getQueryLocator([SELECT Id, Name, ProductCode, APT_Category__c, APT_Network_Type__c, APT_Product_type__c FROM Product2 
                                            WHERE APT_Domestic_Pricing__c = true ORDER BY ProductCode LIMIT 1]);
        }
        else{
            return Database.getQueryLocator([SELECT Id, Name, ProductCode, APT_Category__c, APT_Network_Type__c, APT_Product_type__c FROM Product2 
                                            WHERE APT_Domestic_Pricing__c = true
                                            ORDER BY ProductCode]);
        }
    }
    
    /**
        execute
    **/    
    global void execute(Database.BatchableContext bc, list<Product2> scope){
        try 
        { 
            system.debug('execute scope: '+ scope);
            //STP-2955 Modify Existing Batch to Create PLI, PM and PME for Express Road - STE Product
            List<Product2> domesticProducts = new List<Product2>();
            List<Product2> stProducts = new List<Product2>();
            List<Product2> stSinglePLIProducts = new List<Product2>();
            Set<string> setSinglePLIProducts = APT_Utils.getSinglePLINetworkTypes();

            //create different collections for domestic and startrack products based on product type
            if(scope != null && scope.size() > 0) 
            {
                for(Product2 product : scope) 
                {
                    string networkType = product.APT_Network_Type__c;

                    if(product.APT_Product_type__c == APT_Constants.PRODUCTTYPE_STARTRACK && (setSinglePLIProducts != null && !setSinglePLIProducts.contains(networkType)))
                    {
                        stProducts.add(product);
                    }
                    else if(product.APT_Product_type__c == APT_Constants.PRODUCTTYPE_STARTRACK && (setSinglePLIProducts != null && setSinglePLIProducts.contains(networkType)))
                    {
                        stSinglePLIProducts.add(product);
                    }
                    else if(product.APT_Product_type__c != APT_Constants.PRODUCTTYPE_STARTRACK)
                    {
                        domesticProducts.add(product);
                    }
                }  
            }
            //STP-2955 Modify Existing Batch to Create PLI, PM and PME for Express Road - STE Product

            //domestic products
            if(domesticProducts != null && domesticProducts.size() > 0) 
            {
                this.executeDomesticProducts(domesticProducts);
            }

            //STP-2955 Modify Existing Batch to Create PLI, PM and PME for Express Road - STE Product
            if(stProducts != null && stProducts.size() > 0) 
            {
                this.executeSTProducts(stProducts);
            }
            if(stSinglePLIProducts != null && stSinglePLIProducts.size() > 0) 
            {
                this.executeSTSinglePLIProducts(stSinglePLIProducts);
            }
        } 
        catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage());          
        }
    }

    /**
        This method will create price list item and price matrix for domestic products.
        @params -
        domesticProducts - list of domestic products
    */   
    public void executeDomesticProducts(List<Product2> domesticProducts)
    {
        try 
        { 
            if(domesticProducts != null && domesticProducts.size() > 0) 
            {
                set<String> setDimension = new set<String>();
                map<String, String> mapDimension = new map<String, String>();
                map<String, set<String>> mapLodgmentZone = new map<String, set<String>>();
                map<String, set<String>> mapPricingStructure = new map<String, set<String>>();
                
                //Get Pricing Properties for ST Products
                APT_R2T_Domestic_Pricing_Properties__c r2tDomesticPricingProperties = this.getPricingProperties(APT_Constants.R2T_DOMESTIC_PRICING_PROPERTIES, setDimension, mapDimension);

                if(setErrorMessage.size() == 0) {
                    set<String> setCategory = new set<String>();
                    set<String> setNetworkType = new set<String>();
                    set<Id> setProductId = new set<Id>();
                    for(Product2 product : domesticProducts) {
                        setProductId.add(product.Id);
                        setCategory.add(product.APT_Category__c);
                        setNetworkType.add(product.APT_Network_Type__c);
                    }  
                    
                    set<String> setAllLodgementZone = new set<String>();
                    set<String> setAllPriceStructure = new set<String>();
                    for(APT_Domestic_Price_Data__c dpd : [SELECT Id, Name, APT_Category__c, APT_Price_Structure__c,
                                                        APT_Network_Type__c, APT_Destination_Zone__c, APT_Destination_Zone_Code__c,
                                                        APT_Lodgement_Zone_Code__c, APT_Per_Kg_Rate__c, APT_Subsequent_Rate__c,
                                                        APT_Weight_Range_Code__c, APT_Weight_Range_Code_Description__c              
                                                        FROM APT_Domestic_Price_Data__c
                                                        WHERE RecordType.Name = :APT_Constants.RECORDTYPE_AUSPOST
                                                        AND APT_Category__c IN :setCategory
                                                        AND APT_Network_Type__c IN :setNetworkType]) {
                        
                        //pricing structure
                        set<String> setPricingStructure = mapPricingStructure.get(dpd.APT_Category__c + APT_Constants.ADD_TILDE  + dpd.APT_Network_Type__c);
                        if(setPricingStructure != null && setPricingStructure.size() > 0) {
                            setAllPriceStructure.add(dpd.APT_Price_Structure__c);
                            
                            setPricingStructure.add(dpd.APT_Price_Structure__c);
                            mapPricingStructure.put(dpd.APT_Category__c + APT_Constants.ADD_TILDE  + dpd.APT_Network_Type__c, setPricingStructure);
                        } else {
                            setAllPriceStructure.add(dpd.APT_Price_Structure__c);
                            
                            setPricingStructure = new set<String>();
                            setPricingStructure.add(dpd.APT_Price_Structure__c);
                            mapPricingStructure.put(dpd.APT_Category__c + APT_Constants.ADD_TILDE  + dpd.APT_Network_Type__c, setPricingStructure);
                        }
                        
                        //lodgment zone
                        set<String> setLodgmentZone = mapLodgmentZone.get(dpd.APT_Category__c + APT_Constants.ADD_TILDE  + dpd.APT_Network_Type__c);
                        if(setLodgmentZone != null && setLodgmentZone.size() > 0) {
                            setAllLodgementZone.add(dpd.APT_Lodgement_Zone_Code__c);
                            
                            setLodgmentZone.add(dpd.APT_Lodgement_Zone_Code__c);
                            mapLodgmentZone.put(dpd.APT_Category__c + APT_Constants.ADD_TILDE  + dpd.APT_Network_Type__c, setLodgmentZone);
                        } else {
                            setAllLodgementZone.add(dpd.APT_Lodgement_Zone_Code__c);
                            
                            setLodgmentZone = new set<String>();
                            setLodgmentZone.add(dpd.APT_Lodgement_Zone_Code__c);
                            mapLodgmentZone.put(dpd.APT_Category__c + APT_Constants.ADD_TILDE + dpd.APT_Network_Type__c, setLodgmentZone);
                        }
                    }
                    
                    //APT_PricingUtility.deletePriceListItems(listProductId);
                    
                    //existing price list items
                    map<String, Apttus_Config2__PriceListItem__c> mapExistingPriceListItem = new map<String, Apttus_Config2__PriceListItem__c>();
                    list<Apttus_Config2__PriceListItem__c> listAllPriceListItem = new list<Apttus_Config2__PriceListItem__c>();
                    set<Id> setPriceListItemId = new set<Id>();
                    for(Apttus_Config2__PriceListItem__c pli : [SELECT Id, Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode,
                                                                APT_Price_Structure__c, APT_Lodgement_Zone_Code__c
                                                                FROM Apttus_Config2__PriceListItem__c
                                                                WHERE Apttus_Config2__ProductId__c IN :setProductId
                                                                AND APT_Price_Structure__c IN :setAllPriceStructure
                                                                AND APT_Lodgement_Zone_Code__c IN  :setAllLodgementZone]) {
                        
                        String key = pli.Apttus_Config2__ProductId__r.ProductCode + APT_Constants.ADD_TILDE + pli.APT_Price_Structure__c + APT_Constants.ADD_TILDE + pli.APT_Lodgement_Zone_Code__c;
                        system.debug('*** key ***'+key.toLowerCase());
                        setPriceListItemId.add(pli.Id);
                        listAllPriceListItem.add(pli);
                        mapExistingPriceListItem.put(key.toLowerCase(), pli);
                    }
                    
                    //new pli
                    list<Apttus_Config2__PriceListItem__c> listPriceListItem = APT_PricingUtility.createPriceListItemForDomestic(domesticProducts,
                                                                                                                                defaultPriceListID,
                                                                                                                                mapLodgmentZone,
                                                                                                                                mapPricingStructure,
                                                                                                                                mapExistingPriceListItem);
                    if(listPriceListItem != null && listPriceListItem.size() > 0) {
                        insert listPriceListItem;
                    }
                    
                    //add new pli
                    for(Apttus_Config2__PriceListItem__c pli : listPriceListItem) {
                        setPriceListItemId.add(pli.Id);
                        listAllPriceListItem.add(pli);
                    }
                    
                    //existing price matrix
                    map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix = new map<String, Apttus_Config2__PriceMatrix__c>();
                    for(Apttus_Config2__PriceMatrix__c pm : [SELECT Id, Apttus_Config2__PriceListItemId__c FROM Apttus_Config2__PriceMatrix__c WHERE Apttus_Config2__PriceListItemId__c IN :setPriceListItemId]) {
                        mapExistingPriceMatrix.put(pm.Apttus_Config2__PriceListItemId__c, pm);
                    }
                    
                    list<Apttus_Config2__PriceMatrix__c> listPriceMatrix = APT_PricingUtility.createPriceMatrixForDomestic(listAllPriceListItem, mapDimension, r2tDomesticPricingProperties, mapExistingPriceMatrix);
                    if(listPriceMatrix != null && listPriceMatrix.size() > 0) {
                        insert listPriceMatrix;
                    }
                }                
            } else {
                setErrorMessage.add(APT_Constants.NO_PRODUCT_DOMESTIC_PRICING);
            }
        } catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage());          
        }
    }

    /**
        This method will create price list item and price matrix for startrack products.
        @params -
        stProducts - list of startrack products
    */
    public void executeSTProducts(List<Product2> stProducts)
    {
        try 
        { 
            system.debug('executeSTProducts stProducts: '+ stProducts);
            set<String> setDimension = new set<String>();
            map<String, String> mapDimension = new map<String, String>();
            map<String, set<String>> mapLodgmentZone = new map<String, set<String>>();
            map<String, String> mapLodgmentZoneDescription = new map<String, String>();
            map<String, set<String>> mapPostCodeMapping = new map<String, set<String>>();
            map<String, String> mapRateCardVersion = new map<String, String>();
            map<String, String> mapRateCardUpdatedOn = new map<String, String>();
            
            if(stProducts != null && stProducts.size() > 0) 
            {
                //Get Pricing Properties for ST Products
                APT_R2T_Domestic_Pricing_Properties__c stPricingProperties = this.getPricingProperties(APT_Constants.ST_PRICING_PROPERTIES, setDimension, mapDimension);
                system.debug('executeSTProducts stPricingProperties: '+ stPricingProperties);

                if(setErrorMessage.size() == 0) 
                {
                    set<String> setCategory = new set<String>();
                    set<String> setNetworkType = new set<String>();
                    set<Id> setProductId = new set<Id>();
                    set<String> setPricingKey = new set<String>();

                    //Get category and network types
                    for(Product2 product : stProducts) 
                    {
                        setProductId.add(product.Id);
                        setCategory.add(product.APT_Category__c);
                        setNetworkType.add(product.APT_Network_Type__c);

                        //for LOC, LO2 and LOT
                        this.assignSameZoneNetworkType(setNetworkType, product.APT_Network_Type__c);
                    }  
                    system.debug('executeSTProducts setCategory: '+ setCategory);
                    system.debug('executeSTProducts setNetworkType: '+ setNetworkType);

                    //Determine Zone Type for Domestic Data
                    List<APT_Domestic_Price_Data__c> lodgementZonesWithType = new List<APT_Domestic_Price_Data__c>();
                    this.determineDomesticZoneTypes(setCategory, setNetworkType, lodgementZonesWithType);

                    //create map of post code mapping zone type
                    this.createPostCodeMappingZoneTypeMap(mapPostCodeMapping, setNetworkType);

                    //Get all domestic price data for startrack record type and given category, network types
                    List<APT_Domestic_Price_Data__c> listDomesticPriceData = [SELECT Id, Name, APT_Category__c, APT_Network_Type__c, APT_Destination_Zone_Code__c,
                                                                                APT_Lodgement_Zone_Code__c, APT_Per_Kg_Rate__c, APT_Subsequent_Rate__c, 
                                                                                APT_Base_Rate__c, APT_Outbound_Inbound__c, APT_Zone_Type__c, APT_Lodgment_Zone__c,
                                                                                APT_Rate_Card_Version__c, APT_Rate_Card_Updated_On__c              
                                                                                FROM APT_Domestic_Price_Data__c
                                                                                WHERE RecordType.Name = :APT_Constants.RECORDTYPE_STARTRACK 
                                                                                AND APT_Category__c IN :setCategory
                                                                                AND APT_Network_Type__c IN :setNetworkType 
                                                                                LIMIT 50000];

                    for(APT_Domestic_Price_Data__c domesticPriceData : listDomesticPriceData) 
                    {
                        //Assign Determined Zone Types
                        for(APT_Domestic_Price_Data__c lodgementZoneType: lodgementZonesWithType)
                        {
                            if(domesticPriceData.APT_Lodgement_Zone_Code__c == lodgementZoneType.APT_Lodgement_Zone_Code__c)
                            {
                                domesticPriceData.APT_Zone_Type__c = lodgementZoneType.APT_Zone_Type__c;
                            }
                        }

                        //Assign category for LOC, LO2 and LOT
                        if(domesticPriceData.APT_Network_Type__c == 'LOC')
                        {
                            domesticPriceData.APT_Network_Type__c = 'EXP';
                        }
                        else if(domesticPriceData.APT_Network_Type__c == 'LO2')
                        {
                            domesticPriceData.APT_Network_Type__c = 'RE2';
                        }
                        else if(domesticPriceData.APT_Network_Type__c == 'LOT')
                        {
                            domesticPriceData.APT_Network_Type__c = 'RET';
                        }

                        //Prepare Lodgement Zone Map
                        for(Product2 product : stProducts) 
                        {
                            if(domesticPriceData.APT_Category__c == product.APT_Category__c && domesticPriceData.APT_Network_Type__c == product.APT_Network_Type__c)
                            {
                                //set pricing key
                                setPricingKey.add(domesticPriceData.APT_Category__c + APT_Constants.ADD_TILDE  + domesticPriceData.APT_Network_Type__c + APT_Constants.ADD_TILDE  + domesticPriceData.APT_Lodgement_Zone_Code__c);

                                //set lodgment zone
                                set<String> setLodgmentZone = mapLodgmentZone.get(domesticPriceData.APT_Category__c + APT_Constants.ADD_TILDE  + domesticPriceData.APT_Network_Type__c);

                                if(setLodgmentZone != null && setLodgmentZone.size() > 0) 
                                {
                                    setLodgmentZone.add(domesticPriceData.APT_Lodgement_Zone_Code__c);
                                    mapLodgmentZone.put(domesticPriceData.APT_Category__c + APT_Constants.ADD_TILDE  + domesticPriceData.APT_Network_Type__c, setLodgmentZone);
                                } 
                                else 
                                {
                                    setLodgmentZone = new set<String>();
                                    setLodgmentZone.add(domesticPriceData.APT_Lodgement_Zone_Code__c);
                                    mapLodgmentZone.put(domesticPriceData.APT_Category__c + APT_Constants.ADD_TILDE + domesticPriceData.APT_Network_Type__c, setLodgmentZone);
                                }
                            }
                        }

                        //Populate zone version map to store in PLI
                        mapLodgmentZoneDescription.put(domesticPriceData.APT_Lodgement_Zone_Code__c, domesticPriceData.APT_Lodgment_Zone__c);

                        //Populate rate card version map to store in PLI
                        mapRateCardVersion.put(domesticPriceData.APT_Category__c + APT_Constants.ADD_TILDE  + domesticPriceData.APT_Network_Type__c, domesticPriceData.APT_Rate_Card_Version__c);

                        //Populate rate card updated on map to store in PLI
                        mapRateCardUpdatedOn.put(domesticPriceData.APT_Category__c + APT_Constants.ADD_TILDE  + domesticPriceData.APT_Network_Type__c, domesticPriceData.APT_Rate_Card_Updated_On__c);
                    }

                    system.debug('executeSTProducts setPricingKey: '+ setPricingKey);
                    system.debug('executeSTProducts mapLodgmentZone: '+ mapLodgmentZone);
                    
                    //Update Zone Types to Domestic Data
                    List<APT_Domestic_Price_Data__c> listDomesticPriceDataToBeUpdated = new List<APT_Domestic_Price_Data__c>();
                    for(APT_Domestic_Price_Data__c domesticPriceData : listDomesticPriceData) 
                    {
                        listDomesticPriceDataToBeUpdated.add(new APT_Domestic_Price_Data__c(Id = domesticPriceData.Id, APT_Zone_Type__c = domesticPriceData.APT_Zone_Type__c));
                    }

                    if(listDomesticPriceDataToBeUpdated != null && !listDomesticPriceDataToBeUpdated.IsEmpty())
                    {
                        update listDomesticPriceDataToBeUpdated;
                    }

                    //Upsert PLI and PM
                    this.upsertPLIandPM(setProductId, setPricingKey, stProducts, mapLodgmentZone, mapLodgmentZoneDescription, mapPostCodeMapping, mapRateCardVersion, mapRateCardUpdatedOn, mapDimension, stPricingProperties);
                }                
            } 
            else 
            {
                setErrorMessage.add(APT_Constants.NO_PRODUCT_ST_PRICING);
            }
        } 
        catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage());          
            system.debug('PLI/PM Exception: ' + ex.getMessage() + ex.getStackTraceString().substringBefore('\n'));
        }
    }

    /**
        This method will assign LOC, LO2 and LOT network types
        @params -
        mapPostCodeMapping - map to set values
    */
    private void assignSameZoneNetworkType(set<String> setNetworkType, string networkType)
    {
        //for LOC, LO2 and LOT network type
        if(networkType == 'EXP')
        {
            setNetworkType.add('LOC');
        }
        else if(networkType == 'RE2')
        {
            setNetworkType.add('LO2');
        }
        else if(networkType == 'RET')
        {
            setNetworkType.add('LOT');
        }
    }

    /**
        This method will determine zone types for domestic price data
        @params -
        setCategory - product categories
        setNetworkType - product network types
        lodgementZonesWithType - logdement zones map with zone types
    */
    private void determineDomesticZoneTypes(set<String> setCategory, set<String> setNetworkType, List<APT_Domestic_Price_Data__c> lodgementZonesWithType)
    {
        //Get DISTINCT Lodgement Zones from Domestic Price Data
        List<AggregateResult> agrDomesticPriceData = [SELECT APT_Lodgement_Zone_Code__c       
                                                        FROM APT_Domestic_Price_Data__c
                                                        WHERE RecordType.Name = :APT_Constants.RECORDTYPE_STARTRACK 
                                                        AND APT_Category__c IN :setCategory
                                                        AND APT_Network_Type__c IN :setNetworkType
                                                        GROUP BY APT_Lodgement_Zone_Code__c];

        //Get DISTINCT Direct, Onforwarding, OnforwardingAlternate Zones from Post Code Mapping
        List<AggregateResult> agrPostCodeMapping = [SELECT APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c 
                                                    FROM APT_Post_Code_Mapping__c    
                                                    GROUP BY APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c
                                                    ORDER BY APT_Direct_Zone__c NULLS LAST];

        //Find whether given lodgement zone is Direct or Onforwarding or OnforwardingAlternate
        for(AggregateResult domesticPriceData : agrDomesticPriceData)
        {
            APT_ZoneTypeModel zoneType = new APT_ZoneTypeModel();
            APT_Domestic_Price_Data__c lodgementZoneWithType = new APT_Domestic_Price_Data__c();
            string lodgementZone = String.valueOf(domesticPriceData.get(APT_Constants.ST_LODGEMENT_ZONE_API));
            string directZone;
            string onforwardingZone;
            string onforwardingAltZone;

            for(AggregateResult postCodeMapping : agrPostCodeMapping)
            {
                directZone = String.valueOf(postCodeMapping.get(APT_Constants.ST_DIRECT_ZONE_API));
                onforwardingZone = String.valueOf(postCodeMapping.get(APT_Constants.ST_ONFORWARDING_ZONE_API));
                onforwardingAltZone = String.valueOf(postCodeMapping.get(APT_Constants.ST_ONFORWARDING_ALTERNATE_ZONE_API));

                //If lodgement zone is found in direct zone, then its direct zone
                if(directZone == lodgementZone)
                {
                    zoneType.directZone = directZone;
                    break;
                }
                //If lodgement zone is found in onforwarding zone and onforwarding alternate zone is same or blank, then its onforwarding zone
                else if(onforwardingZone == lodgementZone && (onforwardingAltZone == null || onforwardingZone == onforwardingAltZone))
                {
                    zoneType.onforwardingZone = onforwardingZone;
                }
                //If lodgement zone is found in onforwarding zone and onforwarding alternate zone is not same, then its onforwarding alternate zone
                else if(onforwardingZone == lodgementZone && (onforwardingAltZone != null && onforwardingZone != onforwardingAltZone))
                {
                    string onforwardingAlternateZone = onforwardingZone + APT_Constants.ADD_TILDE + onforwardingAltZone;

                    if(zoneType.onforwardingAlternateZone == null)
                    {
                        zoneType.onforwardingAlternateZone = onforwardingAlternateZone;
                    }
                    else if(!zoneType.onforwardingAlternateZone.Contains(onforwardingAlternateZone))
                    {
                        zoneType.onforwardingAlternateZone = zoneType.onforwardingAlternateZone + APT_Constants.ADD_COMMA + onforwardingAlternateZone;
                    }
                }
            }

            if(zoneType.directZone != null || zoneType.onforwardingZone != null || zoneType.onforwardingAlternateZone != null)
            {
                lodgementZoneWithType.APT_Lodgement_Zone_Code__c = lodgementZone;
                lodgementZoneWithType.APT_Zone_Type__c = JSON.serialize(zoneType);
                lodgementZonesWithType.add(lodgementZoneWithType);
            }
        }
    }

    /**
        This method will crate map of post code zone types
        @params -
        mapPostCodeMapping - map to set values
    */
    private void createPostCodeMappingZoneTypeMap(map<String, set<String>> mapPostCodeMapping, set<String> setNetworkType)
    {
        //Get Post Code Mapping
        List<APT_Post_Code_Mapping__c> listPostCodeMapping = [SELECT Id, APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c,
                                                                APT_EXP_Zone_Type__c, APT_PRM_Zone_Type__c, APT_NXF_Zone_Type__c, APT_SE2_Zone_Type__c, APT_SE3_Zone_Type__c, APT_RET_Zone_Type__c, APT_RE2_Zone_Type__c 
                                                                FROM APT_Post_Code_Mapping__c];

        set<String> setPostCodeEXPZoneType = new set<String>();
        set<String> setPostCodePRMZoneType = new set<String>();
        set<String> setPostCodeNXFZoneType = new set<String>();
        set<String> setPostCodeSE2ZoneType = new set<String>();
        set<String> setPostCodeSE3ZoneType = new set<String>();
        set<String> setPostCodeRETZoneType = new set<String>();
        set<String> setPostCodeRE2ZoneType = new set<String>();

        for(APT_Post_Code_Mapping__c postCodeMapping: listPostCodeMapping)
        {
            //assign zone type to all network types
            if(setNetworkType.contains('EXP'))
            {
                //Create map of post code mapping for each network type
                setPostCodeEXPZoneType.add(postCodeMapping.APT_EXP_Zone_Type__c);
                mapPostCodeMapping.put('EXP', setPostCodeEXPZoneType);
            }
            else if(setNetworkType.contains('PRM'))
            {
                //Create map of post code mapping for each network type
                setPostCodePRMZoneType.add(postCodeMapping.APT_PRM_Zone_Type__c);
                mapPostCodeMapping.put('PRM', setPostCodePRMZoneType);
            }
            else if(setNetworkType.contains('NXF'))
            {
                //Create map of post code mapping for each network type
                setPostCodeNXFZoneType.add(postCodeMapping.APT_NXF_Zone_Type__c);
                mapPostCodeMapping.put('NXF', setPostCodeNXFZoneType);
            }
            else if(setNetworkType.contains('SE2'))
            {
                //Create map of post code mapping for each network type
                setPostCodeSE2ZoneType.add(postCodeMapping.APT_SE2_Zone_Type__c);
                mapPostCodeMapping.put('SE2', setPostCodeSE2ZoneType);
            }
            else if(setNetworkType.contains('SE3'))
            {
                //Create map of post code mapping for each network type
                setPostCodeSE3ZoneType.add(postCodeMapping.APT_SE3_Zone_Type__c);
                mapPostCodeMapping.put('SE3', setPostCodeSE3ZoneType);
            }
            else if(setNetworkType.contains('RET'))
            {
                //Create map of post code mapping for each network type
                setPostCodeRETZoneType.add(postCodeMapping.APT_RET_Zone_Type__c);
                mapPostCodeMapping.put('RET', setPostCodeRETZoneType);
            }
            else if(setNetworkType.contains('RE2'))
            {
                //Create map of post code mapping for each network type
                setPostCodeRE2ZoneType.add(postCodeMapping.APT_RE2_Zone_Type__c);
                mapPostCodeMapping.put('RE2', setPostCodeRE2ZoneType);
            }
        }
    }

    /**
        This method will create or update price list item and price matrix
        @params -
        stProducts - list of startrack products for which single PLI will be created
    */
    private void upsertPLIandPM(set<Id> setProductId, set<String> setPricingKey, List<Product2> stProducts, map<String, set<String>> mapLodgmentZone,
                                map<String, String> mapLodgmentZoneDescription, map<String, set<String>> mapPostCodeMapping,
                                map<String, String> mapRateCardVersion, map<String, String> mapRateCardUpdatedOn, 
                                map<String, String>  mapDimension, APT_R2T_Domestic_Pricing_Properties__c stPricingProperties)
    {
        //existing price list items
        map<String, Apttus_Config2__PriceListItem__c> mapExistingPriceListItem = new map<String, Apttus_Config2__PriceListItem__c>();
        list<Apttus_Config2__PriceListItem__c> listAllPriceListItem = new list<Apttus_Config2__PriceListItem__c>();
        set<Id> setPriceListItemId = new set<Id>();

        for(Apttus_Config2__PriceListItem__c priceListItem : [SELECT Id, Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode,
                                                            APT_Pricing_Key__c, APT_Zone_Type__c, APT_Zone_Combination__c
                                                            FROM Apttus_Config2__PriceListItem__c
                                                            WHERE Apttus_Config2__ProductId__c IN :setProductId
                                                            AND APT_Pricing_Key__c IN :setPricingKey]) 
        {
            setPriceListItemId.add(priceListItem.Id);
            listAllPriceListItem.add(priceListItem);
            mapExistingPriceListItem.put(priceListItem.APT_Zone_Combination__c, priceListItem);
        }
        system.debug('executeSTProducts mapExistingPriceListItem: '+ mapExistingPriceListItem);
        
        //new priceListItem
        List<Apttus_Config2__PriceListItem__c> listPriceListItem = APT_PricingUtility.createPriceListItemForSTE(stProducts,
                                                                                                                defaultPriceListID,
                                                                                                                mapLodgmentZone,
                                                                                                                mapExistingPriceListItem,
                                                                                                                mapLodgmentZoneDescription,
                                                                                                                mapPostCodeMapping,
                                                                                                                mapRateCardVersion,
                                                                                                                mapRateCardUpdatedOn);

        //create price list items
        if(listPriceListItem != null && listPriceListItem.size() > 0) 
        {
            upsert listPriceListItem;
        }
        
        //add new priceListItem
        for(Apttus_Config2__PriceListItem__c priceListItem : listPriceListItem) 
        {
            setPriceListItemId.add(priceListItem.Id);
        }
        
        //existing price matrix
        Map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix = new Map<String, Apttus_Config2__PriceMatrix__c>();
        for(Apttus_Config2__PriceMatrix__c priceMatrix : [SELECT Id, Apttus_Config2__PriceListItemId__c 
                                                          FROM Apttus_Config2__PriceMatrix__c 
                                                          WHERE Apttus_Config2__PriceListItemId__c IN :setPriceListItemId]) 
        {
            mapExistingPriceMatrix.put(priceMatrix.Apttus_Config2__PriceListItemId__c, priceMatrix);
        }
        
        //get price matrix records to be created
        list<Apttus_Config2__PriceMatrix__c> listPriceMatrix = APT_PricingUtility.createPriceMatrixForSTE(setPriceListItemId, mapDimension, stPricingProperties, mapExistingPriceMatrix);
        
        //create price matrix
        if(listPriceMatrix != null && listPriceMatrix.size() > 0) 
        {
            upsert listPriceMatrix;
        }
    }

    /**
        This method will create price list item and price matrix for startrack products - NXF, SE2, SE3.
        @params -
        stProducts - list of startrack products for which single PLI will be created
    */
    public void executeSTSinglePLIProducts(List<Product2> stProducts)
    {
        try 
        { 
            system.debug('executeSTSinglePLIProducts stProducts: '+ stProducts);
            set<String> setDimension = new set<String>();
            map<String, String> mapDimension = new map<String, String>();
            map<String, String> mapRateCardVersion = new map<String, String>();
            map<String, String> mapRateCardUpdatedOn = new map<String, String>();
            
            if(stProducts != null && stProducts.size() > 0) 
            {
                //Get Pricing Properties for ST Products
                APT_R2T_Domestic_Pricing_Properties__c stPricingProperties = this.getPricingProperties(APT_Constants.ST_SINGLE_PRICING_PROPERTIES, setDimension, mapDimension);
                system.debug('executeSTSinglePLIProducts stPricingProperties: '+ stPricingProperties);

                if(setErrorMessage.size() == 0) 
                {
                    set<String> setCategory = new set<String>();
                    set<String> setNetworkType = new set<String>();
                    set<Id> setProductId = new set<Id>();

                    //Get category and network types
                    for(Product2 product : stProducts) 
                    {
                        setProductId.add(product.Id);
                        setCategory.add(product.APT_Category__c);
                        setNetworkType.add(product.APT_Network_Type__c);
                    }  
                    system.debug('executeSTSinglePLIProducts setCategory: '+ setCategory);
                    system.debug('executeSTSinglePLIProducts setNetworkType: '+ setNetworkType);

                    //Get all domestic price data for startrack record type and given category, network types
                    List<APT_Domestic_Price_Data__c> listDomesticPriceData = [SELECT Id, Name, APT_Category__c, APT_Network_Type__c, APT_Destination_Zone_Code__c,
                                                                                APT_Lodgement_Zone_Code__c, APT_Per_Kg_Rate__c, APT_Subsequent_Rate__c, 
                                                                                APT_Base_Rate__c, APT_Lodgment_Zone__c, APT_Rate_Card_Version__c, APT_Rate_Card_Updated_On__c              
                                                                                FROM APT_Domestic_Price_Data__c
                                                                                WHERE RecordType.Name = :APT_Constants.RECORDTYPE_STARTRACK 
                                                                                AND APT_Category__c IN :setCategory
                                                                                AND APT_Network_Type__c IN :setNetworkType 
                                                                                LIMIT 50000];

                    for(APT_Domestic_Price_Data__c domesticPriceData : listDomesticPriceData) 
                    {
                        //Populate rate card version map to store in PLI
                        mapRateCardVersion.put(domesticPriceData.APT_Category__c + APT_Constants.ADD_TILDE  + domesticPriceData.APT_Network_Type__c, domesticPriceData.APT_Rate_Card_Version__c);

                        //Populate rate card updated on map to store in PLI
                        mapRateCardUpdatedOn.put(domesticPriceData.APT_Category__c + APT_Constants.ADD_TILDE  + domesticPriceData.APT_Network_Type__c, domesticPriceData.APT_Rate_Card_Updated_On__c);
                    }

                    //existing price list items
                    map<String, Apttus_Config2__PriceListItem__c> mapExistingPriceListItem = new map<String, Apttus_Config2__PriceListItem__c>();
                    list<Apttus_Config2__PriceListItem__c> listAllPriceListItem = new list<Apttus_Config2__PriceListItem__c>();
                    set<Id> setPriceListItemId = new set<Id>();

                    for(Apttus_Config2__PriceListItem__c priceListItem : [SELECT Id, Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode,
                                                                        APT_Pricing_Key__c, APT_Zone_Type__c, APT_Zone_Combination__c
                                                                        FROM Apttus_Config2__PriceListItem__c
                                                                        WHERE Apttus_Config2__ProductId__c IN :setProductId]) 
                    {
                        setPriceListItemId.add(priceListItem.Id);
                        listAllPriceListItem.add(priceListItem);
                        mapExistingPriceListItem.put(priceListItem.Apttus_Config2__ProductId__c, priceListItem);
                    }
                    system.debug('executeSTSinglePLIProducts mapExistingPriceListItem: '+ mapExistingPriceListItem);

                    //new priceListItem
                    List<Apttus_Config2__PriceListItem__c> listPriceListItem = APT_PricingUtility.createSinglePriceListItem(stProducts,
                                                                                                                            defaultPriceListID,
                                                                                                                            mapExistingPriceListItem,
                                                                                                                            mapRateCardVersion,
                                                                                                                            mapRateCardUpdatedOn);

                    //create price list items
                    if(listPriceListItem != null && listPriceListItem.size() > 0) 
                    {
                        upsert listPriceListItem;
                    }
                    
                    //add new priceListItem
                    for(Apttus_Config2__PriceListItem__c priceListItem : listPriceListItem) 
                    {
                        setPriceListItemId.add(priceListItem.Id);
                    }
                    
                    //existing price matrix
                    Map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix = new Map<String, Apttus_Config2__PriceMatrix__c>();
                    for(Apttus_Config2__PriceMatrix__c priceMatrix : [SELECT Id, Apttus_Config2__PriceListItemId__c 
                                                                      FROM Apttus_Config2__PriceMatrix__c 
                                                                      WHERE Apttus_Config2__PriceListItemId__c IN :setPriceListItemId]) 
                    {
                        mapExistingPriceMatrix.put(priceMatrix.Apttus_Config2__PriceListItemId__c, priceMatrix);
                    }
                    
                    //get price matrix records to be created
                    list<Apttus_Config2__PriceMatrix__c> listPriceMatrix = APT_PricingUtility.createPriceMatrixForSTE(setPriceListItemId, mapDimension, stPricingProperties, mapExistingPriceMatrix);
                    
                    //create price matrix
                    if(listPriceMatrix != null && listPriceMatrix.size() > 0) 
                    {   
                        upsert listPriceMatrix;
                    }
                }                
            } 
            else 
            {
                setErrorMessage.add(APT_Constants.NO_PRODUCT_ST_PRICING);
            }
        } 
        catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage());          
            system.debug('PLI/PM Exception: ' + ex.getMessage() + ex.getStackTraceString().substringBefore('\n'));
        }
    }

    /**
        This method will get dimensions from custom setting
        @params -
        pricingName - custom setting name
    */
    private APT_R2T_Domestic_Pricing_Properties__c getPricingProperties(string pricingName, set<String> setDimension, map<String, String> mapDimension)
    {
        //get default price list item
        APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
        if(r2tSystemProperties != null) 
        {
            if(r2tSystemProperties.APT_Default_Price_List_ID__c != null) {
                defaultPriceListID = r2tSystemProperties.APT_Default_Price_List_ID__c;
            } else {
                setErrorMessage.add(APT_Constants.MISSING_DEFAULT_PRICELIST_ID);
            }
        }
        
        //validate if any missing price dimension
        APT_R2T_Domestic_Pricing_Properties__c pricingProperties = APT_R2T_Domestic_Pricing_Properties__c.getValues(pricingName);

        if(pricingProperties != null) 
        {
            if(pricingProperties.APT_Dimension1_Name__c != null) {
                setDimension.add(pricingProperties.APT_Dimension1_Name__c);
            }
            
            if(pricingProperties.APT_Dimension1_Name__c != null && pricingProperties.APT_Dimension1_Type__c == null) {
                setErrorMessage.add(APT_Constants.MISSING_DIMENSION_TYPE_FOR + pricingProperties.APT_Dimension1_Name__c + APT_Constants.A_PERIOD);
            }
            
            if(pricingProperties.APT_Dimension1_Name__c != null && pricingProperties.APT_Dimension1_Value__c == null) {
                setErrorMessage.add(APT_Constants.MISSING_DIMENSION_VALUE_FOR + pricingProperties.APT_Dimension1_Name__c + APT_Constants.A_PERIOD);
            }
            
            if(pricingProperties.APT_Dimension2_Name__c != null) {
                setDimension.add(pricingProperties.APT_Dimension2_Name__c);
            }
            
            if(pricingProperties.APT_Dimension2_Name__c != null && pricingProperties.APT_Dimension2_Type__c == null) {
                setErrorMessage.add(APT_Constants.MISSING_DIMENSION_TYPE_FOR + pricingProperties.APT_Dimension2_Name__c + APT_Constants.A_PERIOD);
            }
            
            if(pricingProperties.APT_Dimension2_Name__c != null && pricingProperties.APT_Dimension2_Value__c == null) {
                setErrorMessage.add(APT_Constants.MISSING_DIMENSION_VALUE_FOR + pricingProperties.APT_Dimension2_Name__c + APT_Constants.A_PERIOD);
            }
            
            if(pricingProperties.APT_Dimension3_Name__c != null) {
                setDimension.add(pricingProperties.APT_Dimension3_Name__c);
            }
            
            if(pricingProperties.APT_Dimension3_Name__c != null && pricingProperties.APT_Dimension3_Type__c == null) {
                setErrorMessage.add(APT_Constants.MISSING_DIMENSION_TYPE_FOR + pricingProperties.APT_Dimension3_Name__c + APT_Constants.A_PERIOD);
            }
            
            if(pricingProperties.APT_Dimension3_Name__c != null && pricingProperties.APT_Dimension3_Value__c == null) {
                setErrorMessage.add(APT_Constants.MISSING_DIMENSION_VALUE_FOR + pricingProperties.APT_Dimension3_Name__c + APT_Constants.A_PERIOD);
            }
            
            if(pricingProperties.APT_Dimension4_Name__c != null) {
                setDimension.add(pricingProperties.APT_Dimension4_Name__c);
            }
            
            if(pricingProperties.APT_Dimension4_Name__c != null && pricingProperties.APT_Dimension4_Type__c == null) {
                setErrorMessage.add(APT_Constants.MISSING_DIMENSION_TYPE_FOR + pricingProperties.APT_Dimension4_Name__c + APT_Constants.A_PERIOD);
            }
            
            if(pricingProperties.APT_Dimension4_Name__c != null && pricingProperties.APT_Dimension4_Value__c == null) {
                setErrorMessage.add(APT_Constants.MISSING_DIMENSION_VALUE_FOR + pricingProperties.APT_Dimension4_Name__c + APT_Constants.A_PERIOD);
            }
            
            if(pricingProperties.APT_Dimension5_Name__c != null) {
                setDimension.add(pricingProperties.APT_Dimension5_Name__c);
            }
            
            if(pricingProperties.APT_Dimension5_Name__c != null && pricingProperties.APT_Dimension5_Type__c == null) {
                setErrorMessage.add(APT_Constants.MISSING_DIMENSION_TYPE_FOR + pricingProperties.APT_Dimension5_Name__c + APT_Constants.A_PERIOD);
            }
            
            if(pricingProperties.APT_Dimension5_Name__c != null && pricingProperties.APT_Dimension5_Value__c == null) {
                setErrorMessage.add(APT_Constants.MISSING_DIMENSION_VALUE_FOR + pricingProperties.APT_Dimension5_Name__c + APT_Constants.A_PERIOD);
            }
            
            if(pricingProperties.APT_Dimension6_Name__c != null) {
                setDimension.add(pricingProperties.APT_Dimension6_Name__c);
            }
            
            if(pricingProperties.APT_Dimension6_Name__c != null && pricingProperties.APT_Dimension6_Type__c == null) {
                setErrorMessage.add(APT_Constants.MISSING_DIMENSION_TYPE_FOR + pricingProperties.APT_Dimension6_Name__c + APT_Constants.A_PERIOD);
            }
            
            if(pricingProperties.APT_Dimension6_Name__c != null && pricingProperties.APT_Dimension6_Value__c == null) {
                setErrorMessage.add(APT_Constants.MISSING_DIMENSION_VALUE_FOR + pricingProperties.APT_Dimension6_Name__c + APT_Constants.A_PERIOD);
            }
        } 
        else 
        {
            setErrorMessage.add(APT_Constants.NO_CUSTOM_SETTINGS_WITH_NAME + pricingName + APT_Constants.FOUND);
        }
        
        for(Apttus_Config2__PriceDimension__c priceDimension : [SELECT Id, Name FROM Apttus_Config2__PriceDimension__c WHERE Name IN :setDimension])
        {
            if(setDimension.contains(priceDimension.Name) == true) {
                mapDimension.put(priceDimension.Name, priceDimension.Id);
            } else {
                setErrorMessage.add(APT_Constants.NO_PRICE_DIMENSION_WITH_NAME + priceDimension.Name + APT_Constants.FOUND);
            }
        }

        return pricingProperties;
    }
    
    /**
        finish
    **/    
    global void finish(Database.BatchableContext bc) {
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus 
                        FROM AsyncApexJob 
                        WHERE Id = :BC.getJobId()];

        system.debug('No. of errors: ' + a.NumberOfErrors);
                        
        if(a.NumberOfErrors > 0) {
            setErrorMessage.add(a.ExtendedStatus);
        }
        
        if(setErrorMessage.size() > 0) {
            
        
            // Send an email to the Apex job's submitter notifying of job completion.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            //get email addresses
            APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
            String emailAddresses;            
            if(r2tSystemProperties != null) {            
                if(r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c != null) {
                    emailAddresses = r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c;
                }
            } 
            
            list<String> toAddresses = new list<String>();
            if(!string.IsEmpty(emailAddresses) && emailAddresses != APT_Constants.EMPTY_STRING) {
                toAddresses = emailAddresses.split(APT_Constants.ADD_COMMA);
            }
            toAddresses.add(a.CreatedBy.Email);
            
            //String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject(APT_Constants.DOMESTIC_PRICING_STATUS);
            
            //Handle Batch Error Message 
            Integer iErrorCount = setErrorMessage.size();
                
            String errorMessage;
            for(String errorMessage1 : setErrorMessage) {
                if(errorMessage != null) {
                    errorMessage += APT_Constants.SEPARATOR_NEXT_LINE + errorMessage1;
                } else {
                    errorMessage = errorMessage1;
                }
            }
            
            //add Batch Error Message in Email
            if(errorMessage != null) {
                mail.setPlainTextBody(APT_Constants.DOMESTIC_PRICING_PROCESSED + a.TotalJobItems + APT_Constants.BATCHES_WITH + iErrorCount + APT_Constants.FAILURES_ERRORS + errorMessage);
            } /**else {
                mail.setPlainTextBody('The Domestic Pricing Batch job has processed ' + a.TotalJobItems + ' batches with '+ iErrorCount + ' failures.');
            }**/
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } else {
            system.debug('Call PME Batch');

            //call batch to create price matrix entry records
            APT_DomesticPricingPMEBatch pmeBatchController = new APT_DomesticPricingPMEBatch();
            database.executeBatch(pmeBatchController, 1);    //batch size = 1, do not increase due to salesforce governor limits
        }        
    }
}