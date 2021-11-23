/***
 * @author Mathew Jose
 * @date 2021-02-15
 * @group 
 * @description This batch job will create price list items for Domestic , International & Startrack products
 * @changelog
 * 2021-02-15 - Mathew Jose - Created
 * 2021-09-14 - Mathew Jose - Updated to incorporate chages require for Parcel Contract products.
*/

global class APT_PricingDataBatch implements Database.Batchable<sObject>, Database.Stateful 
{
    //global variables
    global string productType;
    global String priceStructure {get;set;}  
    global set<String> setErrorMessage;
    public static final String CLASSNAME = 'APT_CreatePMBatch';
    public static final String ORGID = UserInfo.getOrganizationId(); 

    global APT_PricingDataBatch(string productType, String priceStructure)
    {
        this.productType = productType;
        this.setErrorMessage = new set<String>();
        this.priceStructure = priceStructure;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) 
    {

        //To Do - Add to constants class
        String parSimProductType = 'Parcel Contract'; 
        list<string> parSimFSRProductTypeList= new list<string>{'Parcel Contract-Feature','Parcel Contract-Surcharge','Parcel Contract-Return'};              
        // Potentially move the query into query string.
        if(productType == 'Domestic_Non_Startrack')
        {
            //exclude startrack & international.
            return Database.getQueryLocator([SELECT Id, Name, ProductCode, APT_Category__c, 
                                            APT_Network_Type__c, APT_Product_type__c 
                                            FROM Product2 
                                            WHERE APT_Domestic_Pricing__c = true
                                            AND APT_Product_type__c !=: APT_Constants.PRODUCTTYPE_STARTRACK
                                            AND APT_Product_type__c !=: parSimProductType
                                            ORDER BY ProductCode]);
        }
        else if(productType == 'Startrack')
        {
            return Database.getQueryLocator([SELECT Id, Name, ProductCode, APT_Category__c, 
                                            APT_Network_Type__c, APT_Product_type__c 
                                            FROM Product2 
                                            WHERE APT_Domestic_Pricing__c = true
                                            AND APT_Product_type__c =: APT_Constants.PRODUCTTYPE_STARTRACK                                            
                                            ORDER BY ProductCode]);


                       
        }
        else if(productType == 'International')
        {
            return Database.getQueryLocator([SELECT Id, Name, ProductCode, APT_Category__c, 
                                            APT_Network_Type__c, APT_Product_type__c 
                                            FROM Product2 
                                            WHERE APT_International_Pricing__c = true
                                            ORDER BY ProductCode]);            
        }
        else if(productType == 'Domestic_Simplified_Parcel_Contract')
        {
            return Database.getQueryLocator([SELECT Id, Name, ProductCode, APT_Category__c, 
                                            APT_Network_Type__c, APT_Product_type__c 
                                            FROM Product2 
                                            WHERE APT_Domestic_Pricing__c = true
                                            AND APT_Product_type__c =: parSimProductType                                           
                                            ORDER BY ProductCode]);
                      
        }else if(productType == 'Domestic_Simplified_Features_Surcharges'){
            return Database.getQueryLocator([SELECT Id, Name, ProductCode, APT_Category__c, 
                                            APT_Network_Type__c, APT_Product_type__c 
                                            FROM Product2 
                                            WHERE  
                                            //APT_Domestic_Pricing__c = true AND 
                                            APT_Product_type__c IN : parSimFSRProductTypeList                                           
                                            ORDER BY ProductCode]);
        }                
        else
        {
            return null;
        }  
    }    

    global void execute(Database.BatchableContext bc, list<Product2> scope)
    {
        try
        { 
            system.debug('execute scope: '+ scope);
            if(scope != null && scope.size() > 0)
            {
                this.executeProducts(scope);
            }
        }
        catch(Exception ex)
        {
            setErrorMessage.add(ex.getMessage() + ex.getStackTraceString());
            system.debug('execute Exception: ' + ex.getMessage());       
            system.debug('execute Exception: ' + ex.getStackTraceString().substringBefore('\n'));
            UTIL_LoggingService.logHandledException(ex, ORGID, 'Apttus Pricing Batch Job', CLASSNAME, 'execute', null, LoggingLevel.ERROR);
  
        }
    }

    /**
        This method will create price list item for different product types (for which the job is run)
        @params -
        products - list of products
    */   
    public void executeProducts(List<Product2> products)
    {
        //Convert the list of products in scope to a map.
        Map<Id, Product2> productMap = new Map<Id, Product2>(products);
        Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
        Map<String, Apttus_Config2__PriceListItem__c> mapExistingPriceListItem;
        Map<String, Apttus_Config2__PriceListItem__c> priceListItemsUpserted = new map<String, Apttus_Config2__PriceListItem__c>();
        Map<String, String> lodgementZoneCodeToDescriptionMap = new Map<String, String>();
        Set<String> setNationalRateNetworkTypes = new Set<String>();
        Set<Id> stSinglePLIProducts = new Set<Id>();

        //Query the generic pricing data table.
        /*
        Map<Id,APT_Pricing_Data__c> pricingDataMap = new Map<Id,APT_Pricing_Data__c>([SELECT Id,Name,
                                                            APT_Product__c, APT_Pricing_Value_1__c,
                                                            APT_Pricing_Value_2__c,APT_Pricing_Value_3__c,
                                                            APT_Pricing_Value_4__c, APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
                                                            APT_Pricing_Value_7__c, APT_Pricing_Value_8__c, APT_Pricing_Value_9__c,
                                                            APT_Pricing_Value_10__c, APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
                                                            APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c,
                                                            APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,  
                                                            APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c,  
                                                            APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,  
                                                            APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c,  
                                                            APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,  
                                                            APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, 
                                                            APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,  
                                                            APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c,
                                                            APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,                  
                                                            APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c,                  
                                                            APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c,
                                                            APT_Product__r.APT_Network_Type__c,
                                                            APT_Product__r.ProductCode
                                                            FROM APT_Pricing_Data__c
                                                            WHERE APT_Product__c IN : productMap.keySet() 
                                                        ]);

        */
        Set<Id> productIdSet = productMap.keyset();
        String queryStr='SELECT APT_Pricing_Value_1__c, APT_Pricing_Value_2__c,APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,' +
                            'APT_Pricing_Value_5__c, APT_Pricing_Value_6__c, APT_Pricing_Value_7__c, APT_Pricing_Value_8__c, ' +
                            'APT_Pricing_Value_9__c, APT_Pricing_Value_10__c, APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,' +
                            'APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,' + 
                            'APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c, ' +
                            'APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c, ' +
                            'APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c, ' +
                            'APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,' +
                            'APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c,' +
                            'Id, Name, APT_Product__c, APT_Product__r.APT_Network_Type__c, APT_Product__r.ProductCode ' +
                            'FROM APT_Pricing_Data__c ' +
                            'WHERE APT_Product__c IN : productIdSet';
        if(!String.isBlank(priceStructure)){
                queryStr += ' AND APT_Pricing_Value_1__c =: priceStructure'; 
        }    
        Map<Id,APT_Pricing_Data__c> pricingDataMap = new Map<Id,APT_Pricing_Data__c>((List<APT_Pricing_Data__c>)Database.query(queryStr));                                        
        //Tech key for domestic = ProductId+ APT_Constants.ADD_TILDE + Price_Structure__c + APT_Constants.ADD_TILDE + Lodgement_Zone_Code__c;
        //Tech key for Startrack = ProductId+ APT_Constants.ADD_TILDE + Lodgement_Zone_Code__c;
        //Tech key for International = ProductId+ APT_Constants.ADD_TILDE + Product code +APT_Constants.ADD_TILDE+Band;
        //get the pricing data config metadata associated with the product type (Domestic)
        if(pricingDataMap != null && !pricingDataMap.isEmpty()){               
            Apttus_Pricing_Data_Config__mdt pricingConfigMdt = Apttus_Pricing_Data_Config__mdt.getInstance(productType);
            String keyConstituentString = pricingConfigMdt?.Pricing_Key_Constituents__c;
            Set<String> keyConstituents = new Set<String>(keyConstituentString.Split(','));
    
            Map<String, Set<APT_Pricing_Data__c>> pricingKeyToDataMap = new Map<String, Set<APT_Pricing_Data__c>>();
            pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(pricingDataMap.values());
    
            //Get National Rates Products, If Any
            String nationalRateNetworkTypes = pricingConfigMdt?.National_Rate_Products__c;
    
            if(nationalRateNetworkTypes != null)
            {
                List<String> listNationalRateNetworkTypes = new List<String>(nationalRateNetworkTypes.Split(','));
                
                for(String nationalRateNetworkType: listNationalRateNetworkTypes)
                {
                    setNationalRateNetworkTypes.add(nationalRateNetworkType.trim());
                }    
                for(Product2 product : products) 
                {
                    string networkType = product.APT_Network_Type__c;

                    if(product.APT_Product_type__c == APT_Constants.PRODUCTTYPE_STARTRACK && (setNationalRateNetworkTypes != null && setNationalRateNetworkTypes.contains(networkType)))
                    {
                        stSinglePLIProducts.add(product.Id);
                    }
                }  
                
            }
    
            //Pricing Key Logic
            Set<String> pricingKeySet = new Set<String>();
            for(String dpId : pricingDataWithMapping.keySet())
            {
                if(!pricingDataWithMapping.get(dpId).isEmpty())
                {
                    //generate the tech key using the key constituents
                    //Note : Product Id / Code should be generic to the pricing keys
                    String pricingKey = '';
                    APT_Pricing_Data__c currentPricingData = pricingDataMap.get(dpId);    
                    //In case of national rates, pricing key would have product id only
                    if(stSinglePLIProducts != null && stSinglePLIProducts.contains(currentPricingData?.APT_Product__c))
                    {
                        pricingKey = currentPricingData?.APT_Product__c;
                    }
                    else
                    {
                        pricingKey = currentPricingData?.APT_Product__c;
                        Map<String,String>pricingMap = new Map<String,String>();
                        pricingMap = pricingDataWithMapping.get(dpId);
        				String keyConstinuentString = '';
                        for(string k : keyConstituents)
                        {                            
                            if(pricingMap.containsKey(k))
                            {
                                keyConstinuentString+= APT_Constants.ADD_TILDE+pricingMap.get(k);
                                
                            }
                        }
                        if(!String.isBlank(keyConstinuentString)){
                           pricingKey += keyConstinuentString;  
                        }
                    }
                     
                    System.debug('Pricing Key: ' + pricingKey);                        
                    pricingKeySet.add(pricingKey);
    
                    Set<APT_Pricing_Data__c> pricingDataSet = new Set<APT_Pricing_Data__c>();
                    if(!pricingKeyToDataMap.containsKey(pricingKey))
                    {
                        pricingDataSet.add(pricingDataMap.get(dpId));                    
                    }
                    else
                    {
                        pricingDataSet = pricingKeyToDataMap.get(pricingKey);
                        pricingDataSet.add(pricingDataMap.get(dpId));
                    }
    
                    pricingKeyToDataMap.put(pricingKey, pricingDataSet);
    
                    //adding lodgement zone code to lodgement zone description.
                    lodgementZoneCodeToDescriptionMap.put(pricingDataWithMapping.get(dpId).get('Pickup Zone Code'), pricingDataWithMapping.get(dpId).get('Lodgement Zone'));
                }                
            }        
            System.debug('Pricing key'+pricingKeyToDataMap.keySet());
            //get existing price list items and associated keys.
            if(!pricingKeyToDataMap.isEmpty())
            {
                mapExistingPriceListItem = new Map<String, Apttus_Config2__PriceListItem__c>([SELECT Id, Apttus_Config2__ProductId__c, 
                                                Apttus_Config2__ProductId__r.ProductCode,
                                                APT_Pricing_Key__c, APT_Zone_Type__c, 
                                                APT_Zone_Combination__c
                                            FROM Apttus_Config2__PriceListItem__c                                        
                                            WHERE APT_Pricing_Key__c 
                                            IN :pricingKeyToDataMap.keySet()]);
            }
    
            if(productType == 'Domestic_Non_Startrack' || productType == 'International' || productType == 'Domestic_Simplified_Parcel_Contract' || productType == 'Domestic_Simplified_Features_Surcharges')
            {
                this.upsertPLIDomesticOrInternational(productType, pricingKeyToDataMap, mapExistingPriceListItem, pricingConfigMdt, pricingDataWithMapping);
            }
            else if(productType == 'Startrack')
            {
                this.upsertPLIStartrack(pricingKeyToDataMap, mapExistingPriceListItem, pricingConfigMdt, pricingDataWithMapping, lodgementZoneCodeToDescriptionMap);
            }          
    	}
        
    }

    /**
        This method will create/update price list item for International or Domestic Products.
        @params -
        productType - Type of product for which the job is run.
        pricingKeyToDataMap - Map of pricing key to it's associated set of Pricing data records.
        existingPliMap - Map of existing pli records with repective pricing keys.
        pricingConfigMdt - The custom metadata associated with the respective product type.
        pricingDataWithMapping - Map of pricing data record Id to Map of name-value pais of pricing data
    */   
    private void upsertPLIDomesticOrInternational(String productType,
                                    Map<String, Set<APT_Pricing_Data__c>> pricingKeyToDataMap, 
                                    map<String, Apttus_Config2__PriceListItem__c> existingPliMap,
                                    Apttus_Pricing_Data_Config__mdt pricingConfigMdt,
                                    Map<String,Map<String,String>> pricingDataWithMapping){
        //get Existing Price list items
        Map<String, Apttus_Config2__PriceListItem__c> mapExistingKeyToPli = new map<String, Apttus_Config2__PriceListItem__c>();
        Map<String, Apttus_Config2__PriceListItem__c> allPlisToUpsert= new Map<String, Apttus_Config2__PriceListItem__c>();

        for(Apttus_Config2__PriceListItem__c pli : existingPliMap.Values())
        {
            mapExistingKeyToPli.put(pli.APT_Pricing_Key__c, pli);
        }
        if(productType == 'Domestic_Non_Startrack' || productType == 'Domestic_Simplified_Parcel_Contract'){
            allPlisToUpsert = APT_PricingBatchUtility.createPliForDomesticExcludingST(mapExistingKeyToPli, pricingKeyToDataMap, pricingConfigMdt, pricingDataWithMapping);
        }else if(productType == 'Domestic_Simplified_Features_Surcharges'){
            allPlisToUpsert = APT_PricingBatchUtility.createPliForDomesticFSR(mapExistingKeyToPli, pricingKeyToDataMap, pricingConfigMdt, pricingDataWithMapping);
        }
        else if(productType == 'International'){
            allPlisToUpsert = APT_PricingBatchUtility.createPliForInternational(mapExistingKeyToPli, pricingKeyToDataMap, pricingConfigMdt, pricingDataWithMapping);
        }
        if(!allPlisToUpsert.isEmpty())
        {
            upsert allPlisToUpsert.Values();
        }

    }

    /**
        This method will create/update price list item for Startrack Products.
        @params -
        pricingKeyToDataMap - Map of pricing key to it's associated set of Pricing data records.
        existingPliMap - Map of existing pli records with repective pricing keys.
        pricingConfigMdt - The custom metadata associated with the respective product type.
        pricingDataWithMapping - Map of pricing data record Id to Map of name-value pais of pricing data
        lodgementZoneCodeToDescriptionMap - Map of lodgement zone code to description which is used in the creation of ST pli's.
    */    
    public void upsertPLIStartrack(Map<String, Set<APT_Pricing_Data__c>> pricingKeyToDataMap,
                                   Map<String, Apttus_Config2__PriceListItem__c> existingPliMap,
                                   Apttus_Pricing_Data_Config__mdt pricingConfigMdt,
                                   Map<String,Map<String,String>> pricingDataWithMapping,
                                   Map<String, String> lodgementZoneCodeToDescriptionMap)
    {
        //Map of network type to zone type.
        map<String, Apttus_Config2__PriceListItem__c> mapExistingKeyToPli = new map<String, Apttus_Config2__PriceListItem__c>();
        Map<String, Apttus_Config2__PriceListItem__c> allPlisToUpsert= new Map<String, Apttus_Config2__PriceListItem__c>();
        Map<String, set<String>> networkTypeToZoneTypesMap = new map<String, set<String>>();
        networkTypeToZoneTypesMap = APT_PricingBatchUtility.createNetworkTypeToZoneTypesMap(pricingConfigMdt);

        for(Apttus_Config2__PriceListItem__c pli : existingPliMap.Values())
        {
            mapExistingKeyToPli.put(pli.APT_Zone_Combination__c, pli);
        }

        allPlisToUpsert = APT_PricingBatchUtility.createPliForStartrack(mapExistingKeyToPli, pricingKeyToDataMap, pricingConfigMdt, pricingDataWithMapping, networkTypeToZoneTypesMap, lodgementZoneCodeToDescriptionMap); 

        //To do - Potentially leverage saveresult.
        if(!allPlisToUpsert.isEmpty())
        {
            upsert allPlisToUpsert.Values();
        }
    }


    /**
    Finish Method
    **/    
    global void finish(Database.BatchableContext bc) 
    {
        //Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob asyncApexJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems, CreatedBy.Email,
                                     ExtendedStatus
                                    FROM AsyncApexJob 
                                    WHERE Id = :bc.getJobId()];

        system.debug('No. of errors: ' + asyncApexJob.NumberOfErrors);
                        
        if(asyncApexJob.NumberOfErrors > 0) 
        {
            setErrorMessage.add(asyncApexJob.ExtendedStatus);
        }
        
        if(setErrorMessage.size() > 0) 
        {
            APT_PricingBatchUtility.sendEmailNotification('CreatePLIBatch', asyncApexJob, setErrorMessage, null);
        } 
        else 
        {
            //Trigger PM Creation Batch
            APT_CreatePMBatch createPMBatch = new APT_CreatePMBatch(productType, priceStructure);
            if(!Test.isRunningTest()){ 
                database.executeBatch(createPMBatch, 1);
            }
        }
    }
}