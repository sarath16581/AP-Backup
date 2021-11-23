/***

 * @author Mahesh Patel
 * @date 2021-02-15
 * @group 
 * @description Apex batch class which creates price matrix entries for different product types.
 * This batch job is executed post the creation on price list items & price matrix entries by the preceding batch jobs.
 * @changelog
 * 2021-02-15 - Mahesh Patel - Created
 * 2021-09-14 - Mathew Jose - Updated to incorporate chages require for Parcel Contract products.
*/
global class APT_CreatePMEBatch implements Database.Batchable<sObject>, Database.Stateful 
{
    global set<String> setErrorMessage {get;set;} 
    global String productType {get;set;} 
    global String priceStructure {get;set;}     
    public static final String CLASSNAME = 'APT_CreatePMEBatch';
    public static final String ORGID = UserInfo.getOrganizationId();

    public APT_CreatePMEBatch(string productType, string priceStructure) 
    {
        this.setErrorMessage = new set<String>();
        this.productType = productType;
        this.priceStructure = priceStructure;
    }

     /**
    Start Method
    **/    
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {        
        //Generate the query string based on the product type in order to retrieve PM's associated with each type.
        String queryStr =   'SELECT Id, Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c,'+
                            'Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c,'+
                            'Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c,'+
                            'Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c,'+
                            'Apttus_Config2__PriceListItemId__r.APT_Zone_Type__c,'+ 
                            'Apttus_Config2__PriceListItemId__r.APT_Zones__c '+
                            'FROM Apttus_Config2__PriceMatrix__c WHERE';
        string stProductType = APT_Constants.PRODUCTTYPE_STARTRACK;
        String parSimProductType = 'Parcel Contract'; 
        list<string> parSimFSRProductTypeList= new list<string>{'Parcel Contract-Feature','Parcel Contract-Surcharge','Parcel Contract-Return'};          
      
        if(productType == 'Domestic_Non_Startrack')
        {
            queryStr += ' Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Domestic_Pricing__c = true AND Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c !=: stProductType AND Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c !=: parSimProductType';
            if(!String.isBlank(priceStructure)){
                queryStr += ' AND Apttus_Config2__PriceListItemId__r.APT_Price_Structure__c =: priceStructure'; 
            }    
        }
        else if(productType == 'Startrack')
        {
 			queryStr += ' Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Domestic_Pricing__c = true AND Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c =: stProductType' ;
        }
        else if(productType == 'International')
        {
            queryStr += ' Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_International_Pricing__c = true';
        } 
        else if(productType == 'Domestic_Simplified_Parcel_Contract')
        {
            queryStr += ' Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Domestic_Pricing__c = true AND Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c =: parSimProductType';
            if(!String.isBlank(priceStructure)){
                queryStr += ' AND Apttus_Config2__PriceListItemId__r.APT_Price_Structure__c =: priceStructure'; 
            }    
        }
        else if(productType == 'Domestic_Simplified_Features_Surcharges')
        {
            queryStr += ' Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c IN: parSimFSRProductTypeList';
 
        }                                       
        return Database.getQueryLocator(queryStr);       
    }
    
    /**
    Execute Method
    **/    
    global void execute(Database.BatchableContext bc, List<Apttus_Config2__PriceMatrix__c> listPriceMatrix)
    {
        try 
        { 
            system.debug('execute listPriceMatrix: ' + listPriceMatrix);

            Map<String, List<APT_Pricing_Data__c>> mapPricingData = new Map<String, List<APT_Pricing_Data__c>>();
            Set<String> setProducts = new Set<String>();
            Set<String> setNationalRateNetworkTypes = new Set<String>();
            Set<Id> stSinglePLIProducts = new Set<Id>();
            
            for(Apttus_Config2__PriceMatrix__c priceMatrix : listPriceMatrix) 
            {
                setProducts.add(priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c);
            }

            system.debug('execute productType: ' + productType);
            //get the pricing data config metadata associated with the product type (Domestic)
            Apttus_Pricing_Data_Config__mdt pricingConfigMdt = [SELECT Id, Pricing_Key_Constituents__c, Order_By_Fields__c, National_Rate_Products__c 
                                                                FROM Apttus_Pricing_Data_Config__mdt 
                                                                WHERE DeveloperName =: productType LIMIT 1];

            List<Apttus_Price_Types__mdt> priceTypes = [SELECT MasterLabel, Price_Type__c 
                                                        FROM Apttus_Price_Types__mdt 
                                                        WHERE Apttus_Pricing_Data_Config__c =: pricingConfigMdt.Id]; 

            //get price types
            Map<String, String> priceTypeValues = new Map<String, String>();
            for(Apttus_Price_Types__mdt priceType : priceTypes)
            {
                priceTypeValues.put(priceType.MasterLabel, priceType.Price_Type__c);
            }
            system.debug('execute priceTypeValues: ' + priceTypeValues);

            //get order by fields
            String orderByFields = pricingConfigMdt?.Order_By_Fields__c;

            String queryStr = 'SELECT APT_Pricing_Value_1__c, APT_Pricing_Value_2__c,APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,' +
                                'APT_Pricing_Value_5__c, APT_Pricing_Value_6__c, APT_Pricing_Value_7__c, APT_Pricing_Value_8__c, ' +
                                'APT_Pricing_Value_9__c, APT_Pricing_Value_10__c, APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,' +
                                'APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,' + 
                                'APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c, ' +
                                'APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c, ' +
                                'APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c, ' +
                                'APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,' +
                                'APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c,' +
                                'Id, Name,Order_By_Pricing_Value_6__c,APT_Product__c, APT_Product__r.APT_Network_Type__c ' +
                        'FROM APT_Pricing_Data__c ' +
                        'WHERE APT_Product__c IN : setProducts';
            if(!String.isBlank(priceStructure)){
                queryStr += ' AND APT_Pricing_Value_1__c =: priceStructure'; 
            }    

            if(!String.isEmpty(orderByFields))
            {
                queryStr += ' ORDER BY ' + orderByFields;
            }
            System.debug('Query String::'+queryStr);
            //Get pricing data table with pricing data mapping.
            List<APT_Pricing_Data__c> pricingData = Database.query(queryStr);

            if(pricingData != null && !pricingData.isEmpty())
            {
                system.debug('execute pricingData size: ' + pricingData.size());

                //convert list to map for further processing
                Map<Id,APT_Pricing_Data__c> pricingDataMap = new Map<Id,APT_Pricing_Data__c>(pricingData);
    
                //create pricing key
                String keyConstituentString = pricingConfigMdt?.Pricing_Key_Constituents__c;
                Set<string> keyConstituents = new Set<String>(keyConstituentString.Split(','));
                //Map<String, List<Map<String,String>>> pricingKeyToDataMap = new Map<String, List<Map<String,String>>>();
                Map<String, Set<Map<String,String>>> pricingKeyToDataMap = new Map<String, Set<Map<String,String>>>();
                Map<String, Map<String, String>> stZoneGroupMappings = new Map <String, Map<String, String>>();
    
                //Get National Rates Products, If Any
                String nationalRateNetworkTypes = pricingConfigMdt?.National_Rate_Products__c;
    
                if(nationalRateNetworkTypes != null)
                {
                    List<String> listNationalRateNetworkTypes = new List<String>(nationalRateNetworkTypes.Split(','));
                    
                    for(String nationalRateNetworkType: listNationalRateNetworkTypes)
                    {
                        setNationalRateNetworkTypes.add(nationalRateNetworkType.trim());
                    }
                    //get zone - group mapping for the national rate network types
                    stZoneGroupMappings = APT_PricingBatchUtility.getSTZoneGroupMapping(setNationalRateNetworkTypes);

                    for(Apttus_Config2__PriceMatrix__c priceMatrix : listPriceMatrix) 
                    {
                        string networkType = priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c;    
                        if(priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c == APT_Constants.PRODUCTTYPE_STARTRACK && (setNationalRateNetworkTypes != null && setNationalRateNetworkTypes.contains(networkType)))
                        {
                            stSinglePLIProducts.add(priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c);
                        }
                    }
                }
    
                //create pricing data mapping
                Map<string, Map<String,String>> pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(pricingDataMap.values());
    
                //build pricing key
                for(String pricingDataId : pricingDataWithMapping.keySet())
                {
                    if(!pricingDataWithMapping.get(pricingDataId).isEmpty())
                    {
                        String pricingKey;
                        //Getting the product Id.
                        String productId = pricingDataMap.get(pricingDataId)?.APT_Product__c;
                        Map<String,String> pricingMap = pricingDataWithMapping.get(pricingDataId); 
                        System.debug('Pricing Map::'+pricingMap);
                        //Getting the network type of the product product.
                        String nwType = pricingDataMap.get(pricingDataId)?.APT_Product__r?.APT_Network_Type__c;
                        //In case of national rates, pricing key would have product id only
                        if(stSinglePLIProducts != null && stSinglePLIProducts.contains(productId))
                        {
                            Map<String, String> mapZoneGroup = new Map<String, String>();
                        	mapZoneGroup = stZoneGroupMappings.get(nwType);
                            //For single pli products pricing key is the product Id itself.
                            pricingKey = productId;                            	                                                        
                            System.debug('mapZoneGroup::'+mapZoneGroup);
                            if(mapZoneGroup != null)
                            {
                                String pickUpZoneCode = pricingMap.get('Pickup Zone Code');
                                String destZoneCode = pricingMap.get('Destination Zone Code');
                                String pickUpGroupCode=  pickUpZoneCode != null && mapZoneGroup.get(pickUpZoneCode) != null    
                                                     ? mapZoneGroup.get(pickUpZoneCode) : '';
                                String destGroupCode=  destZoneCode != null && mapZoneGroup.get(destZoneCode) != null    
                                                     ? mapZoneGroup.get(destZoneCode) : '';              
                                if(pricingMap.containsKey('Pickup Zone Code') && pickUpGroupCode != ''){
                                    pricingMap.put('Pickup Zone Code',pickUpGroupCode);
                                }
                                if(pricingMap.containsKey('Destination Zone Code') && destGroupCode != ''){
                                    pricingMap.put('Destination Zone Code',destGroupCode);
                                }
                                //remove the not required entries from Pricing Map
                                Set<String> excludedValues = new Set<String>(APT_Constants.ST_SINGLE_VALUES_TO_EXCLUDE.split(','));
								pricingMap.keySet().removeAll(excludedValues);
                                System.debug('Pricing Map post::'+pricingMap);                                
                            }
                        }                                                        
                        
                        else
                        {
                            //generate the tech key using the key constituents
                            pricingKey = productId+ APT_Constants.ADD_TILDE;
                            Map<String,String> pricingKeyMap = new Map<String, String>();
    
                            for(string key : keyConstituents)
                            {
                                if(pricingMap.containsKey(key))
                                {
                                    pricingKeyMap.put(key,pricingMap.get(key));
                                }
                            }
    
                            pricingKey += String.join(pricingKeyMap.Values(),APT_Constants.ADD_TILDE);
                            System.debug('Key::'+pricingKey);
                            
                        }
                        //Using set to ensure that no duplicate pricing data record is associated with each pricing key.
                        Set<Map<String,String>> pricingDataSet = new Set<Map<String,String>>();
                        if(pricingKeyToDataMap.containsKey(pricingKey)){
                            pricingDataSet = pricingKeyToDataMap.get(pricingKey);
                            pricingDataSet.add(pricingMap);
                            pricingKeyToDataMap.put(pricingKey, pricingDataSet);                             
                        }                                        
                        else
                        {                            
                            pricingDataSet.add(pricingMap);
                            pricingKeyToDataMap.put(pricingKey, pricingDataSet);                     
                        }
                        
                        if(productType == 'Startrack' && (stSinglePLIProducts == null || stSinglePLIProducts.isEmpty()))
                        {
                            if(pricingMap.get('Outbound - Inbound') == APT_Constants.INBOUND) 
                            {
                                string inboundKey = pricingDataMap.get(pricingDataId)?.APT_Product__c + APT_Constants.ADD_TILDE + pricingMap.get('Destination Zone Code');
                                Set<Map<String,String>> pricingDataSetInbound = new Set<Map<String,String>>();
                                if(!pricingKeyToDataMap.containsKey(inboundKey))
                                {
                                    pricingDataSetInbound.add(pricingMap);                    
                                }
                                else
                                {
                                    pricingDataSetInbound = pricingKeyToDataMap.get(inboundKey);
                                    pricingDataSetInbound.add(pricingMap);
                                }
    
                                pricingKeyToDataMap.put(inboundKey, pricingDataSetInbound);
                            }
                        }
                    }                
                }
    
                system.debug('execute pricingKeyToDataMap: ' + pricingKeyToDataMap);
                system.debug('execute pricingKeyToDataMap size: ' + pricingKeyToDataMap.size());    
                //create price matrix entry records
                List<Apttus_Config2__PriceMatrixEntry__c> listPriceMatrixEntry = APT_PricingBatchUtility.createPriceMatrixEntryGeneric(listPriceMatrix, pricingKeyToDataMap, priceTypeValues, productType);
                
                if(listPriceMatrixEntry != null && listPriceMatrixEntry.size() > 0) 
                {
                    insert listPriceMatrixEntry;
                }
            }
        } 
        catch(System.Exception ex) 
        {
            setErrorMessage.add(ex.getMessage() + ex.getStackTraceString());
            system.debug('execute Exception: ' + ex.getMessage());       
            system.debug('execute Exception: ' + ex.getStackTraceString().substringBefore('\n')); 
            UTIL_LoggingService.logHandledException(ex, ORGID, 'Apttus Pricing Batch Job', CLASSNAME, 'execute', null, LoggingLevel.ERROR);         
        }
    }
    
    /**
    Finish Method
    **/    
    global void finish(Database.BatchableContext bc) 
    {
        //Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob asyncApexJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems, CreatedBy.Email,ExtendedStatus 
                                    FROM AsyncApexJob 
                                    WHERE Id = :bc.getJobId()];

        system.debug('No. of errors: ' + asyncApexJob.NumberOfErrors);
                        
        if(asyncApexJob.NumberOfErrors > 0) 
        {
            setErrorMessage.add(asyncApexJob.ExtendedStatus);
        }
        
        if(setErrorMessage.size() > 0) 
        {
            APT_PricingBatchUtility.sendEmailNotification('CreatePMEBatch', asyncApexJob, setErrorMessage, null);
        }
        else 
        {
            APT_PricingBatchUtility.sendEmailNotification(null, asyncApexJob, null, productType + ' Batch Job Completed Successfully');
        }
    }
}