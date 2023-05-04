/***
 * @author Mahesh Patel
 * @date 2021-03-01
 * @group
 * @description Utility class for pricing batch with methods to create PLI, PM and PMEs and manipulate the Pricing Data records.
 * @changelog
 * 2021-03-01 - Mahesh Patel - Created
 * 2021-03-04 - Mathew Jose - Added methods getPricingDataAttributesWithValues, createPliForDomesticExcludingST, createPliForInternational.
 * 2021-07-29 - Sautul Mehta - Added Assignment for APT_Band_Range_Max__c (PLI)
 * 2021-09-14 - Mathew Jose - Created new method which updates the PLI for Features, Surcharges & Returns and changes required for Parcel Contract products
 * 2023-05-04 - Sarath Burra - CI-859 Added code changes to create Charge Criteria for only Transit Cover (Adhoc and Always On) and not other FSR products based on Pricing Key Constituents and data in custom tables (APT_Pricing_Data__c,APT_Pricing_Data_Mapping__c)
**/
public with sharing class APT_PricingBatchUtility
{
    /**
        This method will arrange the generic pricing data into Map
        @params -
        pricingDataRecords - list of pricing data records
    */
    public static Map<string, Map<String,String>> getPricingDataAttributesWithValues(List<APT_Pricing_Data__c> pricingDataRecords)
    {
        Map <string, Map<String,String>> pricingDataWithMapping = new Map<string, Map<String,String>>();

        for(APT_Pricing_Data__c pd : pricingDataRecords)
        {
            Map<string,string>pricingParameterNameToValueMap = new Map<string,string>();

            //build the map.
            pricingParameterNameToValueMap.put(pd.APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c, pd.APT_Pricing_Value_1__c);
            pricingParameterNameToValueMap.put(pd.APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c, pd.APT_Pricing_Value_2__c);
            pricingParameterNameToValueMap.put(pd.APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, pd.APT_Pricing_Value_3__c);
            pricingParameterNameToValueMap.put(pd.APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c, pd.APT_Pricing_Value_4__c);
            pricingParameterNameToValueMap.put(pd.APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, pd.APT_Pricing_Value_5__c);
            pricingParameterNameToValueMap.put(pd.APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c, pd.APT_Pricing_Value_6__c);
            pricingParameterNameToValueMap.put(pd.APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, pd.APT_Pricing_Value_7__c);
            pricingParameterNameToValueMap.put(pd.APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c, pd.APT_Pricing_Value_8__c);
            pricingParameterNameToValueMap.put(pd.APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, pd.APT_Pricing_Value_9__c);
            pricingParameterNameToValueMap.put(pd.APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c, pd.APT_Pricing_Value_10__c);
            pricingParameterNameToValueMap.put(pd.APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, pd.APT_Pricing_Value_11__c);
            pricingParameterNameToValueMap.put(pd.APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c, pd.APT_Pricing_Value_12__c);

            if(!pricingDataWithMapping.containsKey(pd.Id))
            {
                pricingDataWithMapping.put(pd.Id, pricingParameterNameToValueMap);
            }
        }
        return pricingDataWithMapping;
    }

    /**
        This method will arrange the generic pricing data into Map for the specific field
        @params -
        pricingDataMappings - list of pricing data mapping records
        fieldName - field label
    */
    public static String getPricingDataFieldAPI(List<APT_Pricing_Data_Mapping__c> pricingDataMappings, String fieldName)
    {
        string lodgementZoneCodeField;

        if(pricingDataMappings != null && pricingDataMappings.size() > 0)
        {
            Map<string,string> mapPricingDataMappings = new Map<string,string>();

            for(APT_Pricing_Data_Mapping__c pricingDataMapping : pricingDataMappings)
            {
                mapPricingDataMappings.put(pricingDataMapping.APT_Pricing_Value_Name_1__c, 'APT_Pricing_Value_1__c');
                mapPricingDataMappings.put(pricingDataMapping.APT_Pricing_Value_Name_2__c, 'APT_Pricing_Value_2__c');
                mapPricingDataMappings.put(pricingDataMapping.APT_Pricing_Value_Name_3__c, 'APT_Pricing_Value_3__c');
                mapPricingDataMappings.put(pricingDataMapping.APT_Pricing_Value_Name_4__c, 'APT_Pricing_Value_4__c');
                mapPricingDataMappings.put(pricingDataMapping.APT_Pricing_Value_Name_5__c, 'APT_Pricing_Value_5__c');
                mapPricingDataMappings.put(pricingDataMapping.APT_Pricing_Value_Name_6__c, 'APT_Pricing_Value_6__c');
                mapPricingDataMappings.put(pricingDataMapping.APT_Pricing_Value_Name_7__c, 'APT_Pricing_Value_7__c');
                mapPricingDataMappings.put(pricingDataMapping.APT_Pricing_Value_Name_8__c, 'APT_Pricing_Value_8__c');
                mapPricingDataMappings.put(pricingDataMapping.APT_Pricing_Value_Name_9__c, 'APT_Pricing_Value_9__c');
                mapPricingDataMappings.put(pricingDataMapping.APT_Pricing_Value_Name_10__c, 'APT_Pricing_Value_10__c');
                mapPricingDataMappings.put(pricingDataMapping.APT_Pricing_Value_Name_11__c, 'APT_Pricing_Value_11__c');
                mapPricingDataMappings.put(pricingDataMapping.APT_Pricing_Value_Name_12__c, 'APT_Pricing_Value_12__c');
            }

            lodgementZoneCodeField = mapPricingDataMappings.get(fieldName);
        }

        return lodgementZoneCodeField;
    }

    /**
        This method is used to identify and return the pli's to be created or updated for Domestic products.
        The creation or updation of PLI's are based on the pricing key associated.
        @params -
        existingPlis - Existing PLI's for the relevant pricing keys.
        pricingKeyToDataMap -  Map of Pricing key to unique set of Pricing Data associated with each key.
        pricingDataWithMapping -  Map of Pricing data record Id to Map of Pricing Data attribute name to Value.
     */
    public static Map<string,Apttus_Config2__PriceListItem__c> createPliForDomesticExcludingST(map<String,Apttus_Config2__PriceListItem__c> existingPlis,
                                                                                                Map<String,Set<APT_Pricing_Data__c>> pricingKeyToDataMap,
                                                                                                Apttus_Pricing_Data_Config__mdt pricingDataConfig,
                                                                                                Map<String,Map<String,String>> pricingDataWithMapping)
    {
        Map<String, Apttus_Config2__PriceListItem__c> mapPriceListItem = new Map<String, Apttus_Config2__PriceListItem__c>();
        Apttus_PLI_Config__mdt defaultPliConfig = new Apttus_PLI_Config__mdt();
        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        //Check if the product type uses default config. If yes, Get the default PLI Config.

        if(pricingDataConfig.Use_Default_PLI_Config__c)
        {
            //get the default pricing config - Apttus_PLI_Config__mdt
            defaultPliConfig = [SELECT Charge_Type__c, Price_Type__c, Price_Method__c, Price_UOM__c, Price_List__c,
                                Allocate_Group_Adjustment__c,Allow_Manual_Adjustment__c,Price_Included_In_Bundle__c,
                                Is_Quantity_Readonly__c
                                FROM Apttus_PLI_Config__mdt
                                WHERE Apttus_Pricing_Data_Config__c =: pricingDataConfig.Id LIMIT 1];

            //Default PriceList
            priceList = [Select Id FROM Apttus_Config2__PriceList__c WHERE Name = :defaultPliConfig.Price_List__c LIMIT 1];

            system.debug('defaultPliConfig: ' + defaultPliConfig);
        }

        //get charge type config criteria metadata type.
        List<Apttus_Charge_Type_Criteria__mdt> chargeTypeCriterias = new List<Apttus_Charge_Type_Criteria__mdt>(
                                                                        [Select Field_Expression__c, Field_Label__c,
                                                                        Field_Name__c, Field_Type__c, Apttus_Pricing_Data_Config__c
                                                                        FROM Apttus_Charge_Type_Criteria__mdt
                                                                        WHERE Apttus_Pricing_Data_Config__c = : pricingDataConfig.Id
                                                                        ]);

        system.debug('chargeTypeCriterias: ' + chargeTypeCriterias);

        for(String pk: pricingKeyToDataMap.keySet())
        {
            system.debug('*** new pli ***');
            APT_Pricing_Data__c pd = new List<APT_Pricing_Data__c>(pricingKeyToDataMap.get(pk))[0];
            Map<String, String> pricingDataFieldToValueMap = pricingDataWithMapping.get(pd.Id);

            //get the set of Pricing Data Associated with the key
            Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
            pli.Apttus_Config2__ProductId__c = pd.APT_Product__c;
            pli.Apttus_Config2__PriceListId__c = priceList.Id;
            pli.APT_Pricing_Key__c = pk;
            pli.Apttus_Config2__ListPrice__c = APT_Constants.INTEGER_ZERO;
            pli.Apttus_Config2__ChargeType__c =  defaultPliConfig.Charge_Type__c;
            pli.Apttus_Config2__PriceType__c = defaultPliConfig.Price_Type__c;
            pli.Apttus_Config2__PriceMethod__c = defaultPliConfig.Price_Method__c;
            pli.Apttus_Config2__PriceUom__c = defaultPliConfig.Price_UOM__c;
            pli.Apttus_Config2__Active__c = APT_Constants.BOOL_TRUE;
            //Adding more fields from the PLI config metadata (Parcel Simplification)
            pli.Apttus_Config2__PriceIncludedInBundle__c = defaultPliConfig.Price_Included_In_Bundle__c;
            pli.Apttus_Config2__AllowManualAdjustment__c = defaultPliConfig.Allow_Manual_Adjustment__c;
            pli.Apttus_Config2__AllocateGroupAdjustment__c = defaultPliConfig.Allocate_Group_Adjustment__c;
            pli.Apttus_Config2__IsQuantityReadOnly__c = defaultPliConfig.Is_Quantity_Readonly__c;
            //get charge type criteria fields
            if(chargeTypeCriterias != null && chargeTypeCriterias.size() > 0){
                List<Map<String,String>> criteriaFields = getConfigCriteriaFieldsMap(chargeTypeCriterias, null, pricingDataFieldToValueMap);
                //refactor the following method which generates the JSON in a generic way.
                pli.Apttus_Config2__Criteria__c = generateJSONStringGeneric(criteriaFields);
            }else{
                pli.Apttus_Config2__HasCriteria__c = false;
            }
            //To do - Decide on the best way to set key fields
            pli.Apttus_Config2__IsUsageTierModifiable__c = APT_Constants.BOOL_FALSE;
            pli.APT_Price_Structure__c = (String)pricingDataFieldToValueMap.get('Price Structure');
            pli.APT_Lodgement_Zone_Code__c = (String)pricingDataFieldToValueMap.get('Lodgement Zone Code');

            if(existingPlis.containsKey(pk))
            {
                //Existing pli - update record
                pli.Id = existingPlis.get(pk).Id;
            }
            mapPriceListItem.put(pk, pli);
        }
        return mapPriceListItem;
    }

    /**
        This method is used to identify and return the pli's to be created or updated for Features, Surcharges & Returns
        The creation or updation of PLI's are based on the pricing key associated.
        @params -
        existingPlis - Existing PLI's for the relevant pricing keys.
        pricingKeyToDataMap -  Map of Pricing key to unique set of Pricing Data associated with each key.
        pricingDataWithMapping -  Map of Pricing data record Id to Map of Pricing Data attribute name to Value.
     */
    public static Map<string,Apttus_Config2__PriceListItem__c> createPliForDomesticFSR(map<String,Apttus_Config2__PriceListItem__c> existingPlis,
                                                                                                Map<String,Set<APT_Pricing_Data__c>> pricingKeyToDataMap,
                                                                                                Apttus_Pricing_Data_Config__mdt pricingDataConfig,
                                                                                                Map<String,Map<String,String>> pricingDataWithMapping)
    {
        Map<String, Apttus_Config2__PriceListItem__c> mapPriceListItem = new Map<String, Apttus_Config2__PriceListItem__c>();
        Apttus_PLI_Config__mdt defaultPliConfig = new Apttus_PLI_Config__mdt();
        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        //Check if the product type uses default config. If yes, Get the default PLI Config.

        if(pricingDataConfig.Use_Default_PLI_Config__c)
        {
            //get the default pricing config - Apttus_PLI_Config__mdt
            defaultPliConfig = [SELECT Charge_Type__c, Price_Type__c, Price_Method__c, Price_UOM__c, Price_List__c,
                                Allocate_Group_Adjustment__c,Allow_Manual_Adjustment__c,Price_Included_In_Bundle__c,
                                Is_Quantity_Readonly__c
                                FROM Apttus_PLI_Config__mdt
                                WHERE Apttus_Pricing_Data_Config__c =: pricingDataConfig.Id LIMIT 1];

            //Default PriceList
            priceList = [Select Id FROM Apttus_Config2__PriceList__c WHERE Name = :defaultPliConfig.Price_List__c LIMIT 1];

            system.debug('defaultPliConfig: ' + defaultPliConfig);
        }

        //get charge type config criteria metadata type.
        List<Apttus_Charge_Type_Criteria__mdt> chargeTypeCriterias = new List<Apttus_Charge_Type_Criteria__mdt>(
                                                                        [Select Field_Expression__c, Field_Label__c,
                                                                        Field_Name__c, Field_Type__c, Apttus_Pricing_Data_Config__c
                                                                        FROM Apttus_Charge_Type_Criteria__mdt
                                                                        WHERE Apttus_Pricing_Data_Config__c = : pricingDataConfig.Id
                                                                        ]);

        system.debug('chargeTypeCriterias: ' + chargeTypeCriterias);

        for(String pk: pricingKeyToDataMap.keySet())
        {
            system.debug('*** new pli ***');
            APT_Pricing_Data__c pd = new List<APT_Pricing_Data__c>(pricingKeyToDataMap.get(pk))[0];
            Map<String, String> pricingDataFieldToValueMap = pricingDataWithMapping.get(pd.Id);

            //get the set of Pricing Data Associated with the key
            Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
            pli.Apttus_Config2__ProductId__c = pd.APT_Product__c;
            pli.Apttus_Config2__PriceListId__c = priceList.Id;
            pli.APT_Pricing_Key__c = pk;
            pli.Apttus_Config2__ListPrice__c = APT_Constants.INTEGER_ZERO;
            pli.Apttus_Config2__ChargeType__c =  defaultPliConfig.Charge_Type__c;
            pli.Apttus_Config2__PriceType__c = defaultPliConfig.Price_Type__c;
            pli.Apttus_Config2__PriceMethod__c = defaultPliConfig.Price_Method__c;
            pli.Apttus_Config2__PriceUom__c = defaultPliConfig.Price_UOM__c;
            pli.Apttus_Config2__Active__c = APT_Constants.BOOL_TRUE;
            //Adding more fields from the PLI config metadata (Parcel Simplification)
            pli.Apttus_Config2__PriceIncludedInBundle__c = defaultPliConfig.Price_Included_In_Bundle__c;
            pli.Apttus_Config2__AllowManualAdjustment__c = defaultPliConfig.Allow_Manual_Adjustment__c;
            pli.Apttus_Config2__AllocateGroupAdjustment__c = defaultPliConfig.Allocate_Group_Adjustment__c;
            pli.Apttus_Config2__IsQuantityReadOnly__c = defaultPliConfig.Is_Quantity_Readonly__c;
            //get charge type criteria fields
            if(chargeTypeCriterias != null && chargeTypeCriterias.size() > 0){
                List<Map<String,String>> criteriaFields = getConfigCriteriaFieldsMap(chargeTypeCriterias, null, pricingDataFieldToValueMap);
				//CI-859 Added code changes to create Charge Criteria  for only Transit Cover (Adhoc and Always On) and not other FSR products based on Pricing Key Constituents and data in custom tables (APT_Pricing_Data__c,APT_Pricing_Data_Mapping__c)
				// We will only generate the JSONString (Criteria) if there is value on APT_Pricing_Data__c table for APT_Pricing_Value_5__c
				//This can be applied to other FSR products which may need additional criteria going forward by creating a Custom metadata record in Apttus_Charge_Type_Criteria__mdt
				for(Map<String, String> criteriaField: criteriaFields)
				{
					for(String ctrv :criteriaField.values()){
						If(!String.isEmpty(ctrv) && pricingDataFieldToValueMap.containsKey(ctrv)){
							//refactor the following method which generates the JSON in a generic way.
							pli.Apttus_Config2__Criteria__c = generateJSONStringGeneric(criteriaFields);
						}
					}
				}

            }else{
                pli.Apttus_Config2__HasCriteria__c = false;
            }
            //To do - Decide on the best way to set key fields
            pli.Apttus_Config2__IsUsageTierModifiable__c = APT_Constants.BOOL_FALSE;
            pli.APT_Price_Point__c = (String)pricingDataFieldToValueMap.get('Price Point');

            if(existingPlis.containsKey(pk))
            {
                //Existing pli - update record
                pli.Id = existingPlis.get(pk).Id;
            }
            mapPriceListItem.put(pk, pli);
        }
        return mapPriceListItem;
    }


    /**
        This method is used to identify and return the pli's to be created or updated for ST products.
        The creation or updation of PLI's are based on the pricing key associated.
        @params -
        existingPlis - Existing PLI's for the relevant pricing keys.
        pricingKeyToDataMap -  Map of Pricing key to unique set of Pricing Data associated with each key.
        pricingDataWithMapping -  Map of Pricing data record Id to Map of Pricing Data attribute name to Value.
        networkTypeToZoneTypesMap -
        lodgementZoneCodeToDescriptionMap -
     */
    public static Map<string,Apttus_Config2__PriceListItem__c> createPliForStartrack(Map<String,Apttus_Config2__PriceListItem__c> existingPlis,
                                                                                    Map<String,Set<APT_Pricing_Data__c>> pricingKeyToDataMap,
                                                                                    Apttus_Pricing_Data_Config__mdt pricingDataConfig,
                                                                                    Map<String,Map<String,String>> pricingDataWithMapping,
                                                                                    Map<String, set<String>> networkTypeToZoneTypesMap,
                                                                                    Map<String, String> lodgementZoneCodeToDescriptionMap)
    {
        system.debug('pricingKeyToDataMap: ' + pricingKeyToDataMap.size());

        Map<String, Apttus_Config2__PriceListItem__c> mapPriceListItem = new Map<String, Apttus_Config2__PriceListItem__c>();
        Apttus_PLI_Config__mdt defaultPliConfig;
        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        //Check if the product type uses default config. If yes, Get the default PLI Config.

        if(pricingDataConfig.Use_Default_PLI_Config__c)
        {
            //get the default pricing config - Apttus_PLI_Config__mdt
            defaultPliConfig = [SELECT Charge_Type__c, Price_Type__c, Price_Method__c, Price_UOM__c, Price_List__c
                                FROM Apttus_PLI_Config__mdt
                                WHERE Apttus_Pricing_Data_Config__c =: pricingDataConfig.Id LIMIT 1];

            //Default PriceList
            priceList = [Select Id FROM Apttus_Config2__PriceList__c WHERE Name = :defaultPliConfig.Price_List__c LIMIT 1];

            system.debug('defaultPliConfig: ' + defaultPliConfig);
        }

        //get charge type config criteria metadata type.
        List<Apttus_Charge_Type_Criteria__mdt> chargeTypeCriterias = new List<Apttus_Charge_Type_Criteria__mdt>(
                                                                        [Select Field_Expression__c, Field_Label__c,
                                                                        Field_Name__c, Field_Type__c, Apttus_Pricing_Data_Config__c
                                                                        FROM Apttus_Charge_Type_Criteria__mdt
                                                                        WHERE Apttus_Pricing_Data_Config__c = : pricingDataConfig.Id
                                                                        ]);
        for(String pk: pricingKeyToDataMap.keySet())
        {
            system.debug('pricingKeyToDataMap pk: ' + pk);

            //get the set of Pricing Data Associated with the key
            APT_Pricing_Data__c pd = new List<APT_Pricing_Data__c>(pricingKeyToDataMap.get(pk))[0];
            Map<String, String> pricingDataFieldToValueMap = pricingDataWithMapping.get(pd.Id);
            Integer sequence = 1;

            //get the relevant zone type
            set<String> postCodeMappingZoneTypes = networkTypeToZoneTypesMap.get(pd.APT_Product__r.APT_Network_Type__c);

            string zoneType;
            string mainZone;
            string altZone;
            string pliZones;
            string zoneDescription;
            string zoneCombination;
            string chargeTypeCriteria;

            //for all post code mapping combination, create pli for given lodgement zone
            if(postCodeMappingZoneTypes != null && postCodeMappingZoneTypes.size() > 0)
            {
                for(String postCodeMappingZoneType : postCodeMappingZoneTypes)
                {
                    system.debug('postCodeMappingZoneType: '+ postCodeMappingZoneType);
                    if(postCodeMappingZoneType != null)
                    {
                        //split post code mapping zone type
                        string[] postCodeMappingZoneTypeSplit = postCodeMappingZoneType.split(APT_Constants.ADD_HYPHEN);

                        if(postCodeMappingZoneTypeSplit != null && postCodeMappingZoneTypeSplit.size() == 2)
                        {
                            mainZone = null;
                            altZone = null;
                            pliZones = null;
                            zoneDescription = null;
                            zoneType = null;
                            zoneCombination = null;

                            //zone type is the first value
                            zoneType = postCodeMappingZoneTypeSplit[0];

                            //zones are second value
                            string[] zones = postCodeMappingZoneTypeSplit[1].split(APT_Constants.ADD_TILDE);

                            if(zones != null && zones.size() > 0)
                            {
                                mainZone = zones[0];
                                pliZones = mainZone;
                                zoneDescription = lodgementZoneCodeToDescriptionMap.get(mainZone);

                                if(zones.size() > 1 && zones[1] != 'null' && zones[1] != mainZone)
                                {
                                    altZone = zones[1];
                                    pliZones = pliZones + APT_Constants.ADD_TILDE + altZone;
                                    zoneDescription = zoneDescription + APT_Constants.ADD_COMMA + lodgementZoneCodeToDescriptionMap.get(altZone);
                                }
                            }

                            if(pk.contains('~' + mainZone))
                            {
                                //for each lodgement zone, create unique zone combination key as below combination
                                zoneCombination = pk + APT_Constants.ADD_TILDE  + postCodeMappingZoneType;
                                chargeTypeCriteria = postCodeMappingZoneType;

                                system.debug('zoneType: '+ zoneType);
                                system.debug('pliZones: '+ pliZones);
                                system.debug('zoneCombination: '+ zoneCombination);

                                //check if there is any existing PLI with same unique zone combination
                                if(zoneCombination == null) zoneCombination = pk;

                                Apttus_Config2__PriceListItem__c existingPLI = existingPlis.get(zoneCombination);

                                //create pli record
                                Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
                                pli.Apttus_Config2__ProductId__c = pd.APT_Product__c;
                                pli.APT_Pricing_Key__c = pk;
                                pli.Apttus_Config2__PriceListId__c = priceList.Id;
                                pli.Apttus_Config2__ListPrice__c = APT_Constants.INTEGER_ZERO;
                                pli.Apttus_Config2__ChargeType__c =  defaultPliConfig.Charge_Type__c;
                                pli.Apttus_Config2__PriceType__c = defaultPliConfig.Price_Type__c;
                                pli.Apttus_Config2__PriceMethod__c = defaultPliConfig.Price_Method__c;
                                pli.Apttus_Config2__PriceUom__c = defaultPliConfig.Price_UOM__c;
                                pli.Apttus_Config2__Active__c = APT_Constants.BOOL_TRUE;
                                pli.Apttus_Config2__IsUsageTierModifiable__c = APT_Constants.BOOL_FALSE;
                                pli.Apttus_Config2__AllowManualAdjustment__c = APT_Constants.BOOL_FALSE;
                                pli.Apttus_Config2__AllocateGroupAdjustment__c = APT_Constants.BOOL_FALSE;
                                pli.APT_Rate_Card_Version__c = (String)pricingDataFieldToValueMap.get('Rate Card Version');
                                pli.APT_Rate_Card_Updated_On__c = (String)pricingDataFieldToValueMap.get('Rate Card Updated On');
                                pli.APT_Zone_Type__c = zoneType;
                                pli.APT_Zones__c = pliZones;
                                pli.APT_Zone_Combination__c = zoneCombination;
                                pli.APT_Zone_Description__c = zoneDescription;

                                //get charge type criteria fields
                                List<Map<String,String>> criteriaFields = chargeTypeCriteria != null ? getConfigCriteriaFieldsMap(chargeTypeCriterias, chargeTypeCriteria, null) : null;
                                pli.Apttus_Config2__Criteria__c = criteriaFields != null ? generateJSONStringGeneric(criteriaFields) : null;

                                system.debug('PLI: ' + pli);

                                if(existingPLI != null)
                                {
                                    pli.Id = existingPLI.Id;
                                }

                                mapPriceListItem.put(zoneCombination, pli);

                                sequence++;
                            }
                        }
                    }
                }
            }

            //check if there is any existing PLI with same unique zone combination
            else if(postCodeMappingZoneTypes == null)
            {
                Apttus_Config2__PriceListItem__c existingSinglePLI = existingPlis.get(pk);

                //create pli record
                Apttus_Config2__PriceListItem__c singlePli = new Apttus_Config2__PriceListItem__c();
                singlePli.Apttus_Config2__ProductId__c = pd.APT_Product__c;
                singlePli.APT_Pricing_Key__c = pk;
                singlePli.Apttus_Config2__PriceListId__c = priceList.Id;
                singlePli.Apttus_Config2__ListPrice__c = APT_Constants.INTEGER_ZERO;
                singlePli.Apttus_Config2__ChargeType__c =  defaultPliConfig.Charge_Type__c;
                singlePli.Apttus_Config2__PriceType__c = defaultPliConfig.Price_Type__c;
                singlePli.Apttus_Config2__PriceMethod__c = defaultPliConfig.Price_Method__c;
                singlePli.Apttus_Config2__PriceUom__c = defaultPliConfig.Price_UOM__c;
                singlePli.Apttus_Config2__Active__c = APT_Constants.BOOL_TRUE;
                singlePli.Apttus_Config2__IsUsageTierModifiable__c = APT_Constants.BOOL_FALSE;
                singlePli.Apttus_Config2__AllowManualAdjustment__c = APT_Constants.BOOL_FALSE;
                singlePli.Apttus_Config2__AllocateGroupAdjustment__c = APT_Constants.BOOL_FALSE;
                singlePli.APT_Rate_Card_Version__c = (String)pricingDataFieldToValueMap.get('Rate Card Version');
                singlePli.APT_Rate_Card_Updated_On__c = (String)pricingDataFieldToValueMap.get('Rate Card Updated On');

                //get charge type criteria fields
                List<Map<String,String>> criteriaFieldsSingle = chargeTypeCriteria != null ? getConfigCriteriaFieldsMap(chargeTypeCriterias, chargeTypeCriteria, null) : null;
                singlePli.Apttus_Config2__Criteria__c = criteriaFieldsSingle != null ? generateJSONStringGeneric(criteriaFieldsSingle) : null;

                system.debug('PLI: ' + singlePli);

                if(existingSinglePLI != null)
                {
                    singlePli.Id = existingSinglePLI.Id;
                }

                mapPriceListItem.put(pk, singlePli);

                sequence++;
            }
        }
        return mapPriceListItem;
    }

    /**
        This method is used to identify and return the pli's to be created or updated for international products.
        The creation or updation of PLI's are based on the pricing key associated.
        @params -
        existingPlis - Existing PLI's for the relevant pricing keys.
        pricingKeyToDataMap -  Map of Pricing key to unique set of Pricing Data associated with each key.
        pricingDataWithMapping -  Map of Pricing data record Id to Map of Pricing Data attribute name to Value.
     */
    public static Map<string,Apttus_Config2__PriceListItem__c> createPliForInternational(Map<String,Apttus_Config2__PriceListItem__c> existingPlis,
                                                                                         Map<String,Set<APT_Pricing_Data__c>> pricingKeyToDataMap,
                                                                                         Apttus_Pricing_Data_Config__mdt pricingDataConfig,
                                                                                         Map<String,Map<String,String>> pricingDataWithMapping){
        //get the PLI configs associated with different products along with charge types
        List<Apttus_PLI_Config__mdt> pliConfigs;
        Apttus_PLI_Config__mdt defaultPliConfig;
        Map<String, Apttus_Config2__PriceListItem__c> mapPriceListItem = new Map<String, Apttus_Config2__PriceListItem__c>();
        Map<String, Set<String>> productToChargeTypesMap = new Map <String, Set<String>>();
        Map<String, Set<Apttus_PLI_Config__mdt>> productToPliConfigMap = new Map <String, Set<Apttus_PLI_Config__mdt>>();
        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        //get pli configs associated with International products
        pliConfigs = [SELECT DeveloperName,Charge_Type__c, Price_Type__c, Price_Method__c, Price_UOM__c,
                        Product_name__c, Price_List__c, Charge_Type_Code__c
                        FROM Apttus_PLI_Config__mdt
                        WHERE Apttus_Pricing_Data_Config__c =: pricingDataConfig.Id];
        if(pliConfigs != null){
            //Default PriceList for all international pli's. Assumption is that the price list will be same for all International products.
            priceList = [Select Id FROM Apttus_Config2__PriceList__c WHERE Name = :pliConfigs[0].Price_List__c LIMIT 1];
            //create map of product to charge type
            for(Apttus_PLI_Config__mdt pliCon : pliConfigs){
                if(pliCon.DeveloperName == 'Default_International'){
                    defaultPliConfig = pliCon;
                }
                Set<Apttus_PLI_Config__mdt> pliConfigSet = new Set<Apttus_PLI_Config__mdt>();
                if(productToPliConfigMap.containsKey(pliCon.Product_name__c)){
                    productToPliConfigMap.get(pliCon.Product_name__c).add(pliCon);
                }else{
                    pliConfigSet.add(pliCon);
                    productToPliConfigMap.put(pliCon.Product_name__c,pliConfigSet);
                }
            }
        }
        //get charge type config criteria metadata type.
        List<Apttus_Charge_Type_Criteria__mdt> chargeTypeCriterias = new List<Apttus_Charge_Type_Criteria__mdt>(
                                                                        [Select Field_Expression__c, Field_Label__c,
                                                                        Field_Name__c, Field_Type__c, Apttus_Pricing_Data_Config__c
                                                                        FROM Apttus_Charge_Type_Criteria__mdt
                                                                        WHERE Apttus_Pricing_Data_Config__c = : pricingDataConfig.Id
                                                                        ]);

        system.debug('chargeTypeCriterias: ' + chargeTypeCriterias);
        for(String pk: pricingKeyToDataMap.keySet()){
            system.debug('*** new pli ***');
            APT_Pricing_Data__c pd = new List<APT_Pricing_Data__c>(pricingKeyToDataMap.get(pk))[0];
            Map<String, String> pricingDataFieldToValueMap = pricingDataWithMapping.get(pd.Id);
            system.debug('*** new pli ***');
            if(productToPliConfigMap.containsKey(pd.APT_Product__r.ProductCode)){
                for(Apttus_PLI_Config__mdt p : productToPliConfigMap.get(pd.APT_Product__r.ProductCode)){
                    if(pk.Contains(p.Charge_Type_Code__c)){
                        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
                        pli.Apttus_Config2__ProductId__c = pd.APT_Product__c;
                        pli.Apttus_Config2__PriceListId__c = priceList.Id;
                        pli.Apttus_Config2__ListPrice__c = APT_Constants.INTEGER_ZERO;
                        pli.APT_Pricing_Key__c = pk;
                        pli.Apttus_Config2__ChargeType__c = p.Charge_Type__c ;
                        pli.Apttus_Config2__PriceType__c = p.Price_Type__c;
                        pli.Apttus_Config2__PriceMethod__c = p.Price_Method__c;
                        pli.Apttus_Config2__PriceUom__c = p.Price_UOM__c;
                        pli.Apttus_Config2__Active__c = APT_Constants.BOOL_TRUE;
                        pli.APT_Band__c = (String)pricingDataFieldToValueMap.get('Band');
                        pli.APT_Band_Range_Max__c = Decimal.valueOf(pricingDataFieldToValueMap.get('Band Range Max'));
                        //Usage Tier Modifier field set to false - Fix for the international issue.
						pli.Apttus_Config2__IsUsageTierModifiable__c = APT_Constants.BOOL_FALSE;
                        //pli.Apttus_Config2__IsUsageTierModifiable__c = APT_Constants.BOOL_TRUE;
                        pli.Apttus_Config2__AllowManualAdjustment__c = false;
                        List<Map<String,String>> criteriaFields = getConfigCriteriaFieldsMap(chargeTypeCriterias, null, pricingDataFieldToValueMap);
                        pli.Apttus_Config2__Criteria__c = generateJSONStringGeneric(criteriaFields);
                        system.debug('PLI: ' + pli);
                        if(existingPlis.containsKey(pk))
                        {
                            //Existing pli - update record
                            pli.Id = existingPlis.get(pk).Id;
                        }
                        mapPriceListItem.put(pk, pli);
                   }
                }
            }else{
                Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
                pli.Apttus_Config2__ProductId__c = pd.APT_Product__c;
                pli.Apttus_Config2__PriceListId__c = priceList.Id;
                pli.Apttus_Config2__ListPrice__c = APT_Constants.INTEGER_ZERO;
                pli.APT_Pricing_Key__c = pk;
                pli.Apttus_Config2__ChargeType__c = defaultPliConfig.Charge_Type__c ;
                pli.Apttus_Config2__PriceType__c = defaultPliConfig.Price_Type__c;
                pli.Apttus_Config2__PriceMethod__c = defaultPliConfig.Price_Method__c;
                pli.Apttus_Config2__PriceUom__c = defaultPliConfig.Price_UOM__c;
                pli.Apttus_Config2__Active__c = APT_Constants.BOOL_TRUE;
                pli.APT_Band__c = (String)pricingDataFieldToValueMap.get('Band');
                pli.APT_Band_Range_Max__c = Decimal.valueOf(pricingDataFieldToValueMap.get('Band Range Max'));
                //pli.Apttus_Config2__IsUsageTierModifiable__c = APT_Constants.BOOL_TRUE;
                pli.Apttus_Config2__IsUsageTierModifiable__c = APT_Constants.BOOL_FALSE;
                pli.Apttus_Config2__AllowManualAdjustment__c = false;
                List<Map<String,String>> criteriaFields = getConfigCriteriaFieldsMap(chargeTypeCriterias, null, pricingDataFieldToValueMap);
                //To do - Clarify this logic before committing the code.
                // Validate the relevance of the
                pli.Apttus_Config2__Criteria__c = generateJSONStringGeneric(criteriaFields);
                system.debug('PLI: ' + pli);
                if(existingPlis.containsKey(pk))
                {
                    //Existing pli - update record
                    pli.Id = existingPlis.get(pk).Id;
                }
                mapPriceListItem.put(pk, pli);
            }
        }
        return mapPriceListItem;


    }


    /**
        This method is used to retrieve the criteria fields from the custom metadata.
        These criteria fields will be used to set the config criteria on the price list items getting created.
        @params -
        chargeTypeCriterias - The config criterias associated with respective product type stored in metadata.
        fieldValue -  Value to be set on the specific condition on the criteria (This is derived dynamically in the calling method)
        pricingDataFieldToValueMap - This is used to retrieve the field value if no field value is passed directly.
     */
     public static List<Map<String,String>> getConfigCriteriaFieldsMap(List<Apttus_Charge_Type_Criteria__mdt> chargeTypeCriterias, string fieldValue, Map<String, String> pricingDataFieldToValueMap)
     {
        system.debug('chargeTypeCriterias : ' + chargeTypeCriterias);
        system.debug('fieldValue : ' + fieldValue);
        system.debug('pricingDataFieldToValueMap : ' + pricingDataFieldToValueMap);

        List<Map<String, String>> criteriaFields = new List<Map<String, String>>();

        for(Apttus_Charge_Type_Criteria__mdt criteria : chargeTypeCriterias)
        {
            Map<String, String>  criteriaField = new Map<String, String>();
            criteriaField.put(APT_Constants.FIELD_VALUE, fieldValue != null ? fieldValue : (String)pricingDataFieldToValueMap.get(criteria.Field_Label__c));
            criteriaField.put(APT_Constants.FIELD_TYPE, criteria.Field_Type__c);
            criteriaField.put(APT_Constants.FIELD_NAME, criteria.Field_Name__c);
            criteriaField.put(APT_Constants.FIELD_EXPR, criteria.Field_Expression__c);
            criteriaField.put(APT_Constants.FIELD_LABEL, criteria.Field_Label__c);
            criteriaFields.add(criteriaField);
        }

        system.debug('criteriaFields: ' + criteriaFields);
        return criteriaFields;
     }

    /**
        This method will retrieve a map of network type to zone types for relevant products.
        @params -
        pricingConfigMdt - Pricing data config metadata associated with the respective product type.
    */
    public static Map<String, set<String>> createNetworkTypeToZoneTypesMap(Apttus_Pricing_Data_Config__mdt pricingConfigMdt)
    {
        //Get associated network type to field API name mapping
        Map<String, String>zoneTypeToPostcodeFieldMap = new Map<String, String>();
        Map<String, set<String>> networkTypeToZoneTypesMap = new Map <String, set<String>>();

        List<APT_Post_Code_Mapping__c>postCodeMappingList = new List<APT_Post_Code_Mapping__c>([SELECT Id, APT_Direct_Zone__c, APT_Onforwarding_Zone__c,
                                                    APT_Onforwarding_Alternate_Zone__c,
                                                    APT_EXP_Zone_Type__c, APT_PRM_Zone_Type__c, APT_NXF_Zone_Type__c,
                                                    APT_SE2_Zone_Type__c,
                                                    APT_SE3_Zone_Type__c, APT_RET_Zone_Type__c, APT_RE2_Zone_Type__c
                                                    FROM APT_Post_Code_Mapping__c]);

        for(Apttus_Zone_Type_Field_Mapping__mdt zoneTypeMap : [Select Network_Type__c,PostCodeMapping_Field_Name__c ,Apttus_Pricing_Data_Config__c
                                                               From Apttus_Zone_Type_Field_Mapping__mdt
                                                               WHERE Apttus_Pricing_Data_Config__c = : pricingConfigMdt.Id])
        {
            zoneTypeToPostcodeFieldMap.put(zoneTypeMap.Network_Type__c, zoneTypeMap.PostCodeMapping_Field_Name__c);
        }

        system.debug('zoneTypeToPostcodeFieldMap: ' + zoneTypeToPostcodeFieldMap);

        for(APT_Post_Code_Mapping__c postCodeMapping: postCodeMappingList)
        {
            for(string zoneType: zoneTypeToPostcodeFieldMap.keySet())
            {
                if(postCodeMapping.get(zoneTypeToPostcodeFieldMap.get(zoneType)) != null)
                {
                    if(networkTypeToZoneTypesMap.containsKey(zoneType))
                    {
                        networkTypeToZoneTypesMap.get(zoneType).add(postCodeMapping.get(zoneTypeToPostcodeFieldMap.get(zoneType)).toString());
                    }
                    else
                    {
                        Set<String> zoneTypeSet = new Set<String>();
                        zoneTypeSet.add(postCodeMapping.get(zoneTypeToPostcodeFieldMap.get(zoneType)).toString());
                        networkTypeToZoneTypesMap.put(zoneType, zoneTypeSet);
                    }
                }

            }
        }

        system.debug('networkTypeToZoneTypesMap: ' + networkTypeToZoneTypesMap);
        return networkTypeToZoneTypesMap;
    }

    /**
        This method is specific to ST products which uses National Rates (NXF, SE3)
        The purpose of this method is to reduce the number of PME's created for the above product types by
        assigning zone to groups.
        @params -
        productType - network type to identify the products which requires zone to group mapping.
     */
    public static Map<String, Map<String, String>> getSTZoneGroupMapping(Set<String> productType)
    {
        Map<String, Map<String, String>> mapSTZoneGroupMapping = new Map<String, Map<String, String>>();

        List<APT_ST_Zone_Group_Mapping__mdt> stZoneGroupMappings = [SELECT MasterLabel, APT_Zone__c, APT_Group__c FROM APT_ST_Zone_Group_Mapping__mdt WHERE MasterLabel IN :productType];

        for(APT_ST_Zone_Group_Mapping__mdt stZoneGroupMapping: stZoneGroupMappings)
        {
            Map<String, String> mapZoneGroup = mapSTZoneGroupMapping.get(stZoneGroupMapping.MasterLabel);

            //prepare collection of domestic data for pricing key
            if(mapZoneGroup != null && mapZoneGroup.size() > 0)
            {
                mapZoneGroup.put(stZoneGroupMapping.APT_Zone__c, stZoneGroupMapping.APT_Group__c);
                mapSTZoneGroupMapping.put(stZoneGroupMapping.MasterLabel, mapZoneGroup);
            }
            else
            {
                mapZoneGroup = new Map<String, String>();
                mapZoneGroup.put(stZoneGroupMapping.APT_Zone__c, stZoneGroupMapping.APT_Group__c);
                mapSTZoneGroupMapping.put(stZoneGroupMapping.MasterLabel, mapZoneGroup);
            }
        }

        return mapSTZoneGroupMapping;
    }



    /**
        This method will generate charge type criteria JSON string for products.
        @params -
        criteriaFields - fields to be added in criteria (This is retrieved from the custom metadata)
     */
    private static String generateJSONStringGeneric(List<Map<String, String>> criteriaFields)
    {
        //generate json structure for the criteria of pli
        Integer rowNum = 1;
        APT_PLICriteriaModel pliCriteria = new APT_PLICriteriaModel();
        pliCriteria.sObjectName = APT_Constants.LINE_ITEM_SOBJECT_API_NAME;
        pliCriteria.sObjectLabel = APT_Constants.LINE_ITEM;
        pliCriteria.filter = new APT_PLICriteriaModel.Filter();
        pliCriteria.fields = new List<String>();
        pliCriteria.exprStr = '';
        pliCriteria.filter.predicates = new List<String>();
        pliCriteria.filter.childFilter = new APT_PLICriteriaModel.ChildFilter();
        pliCriteria.filter.childFilter.relationFieldName = APT_Constants.LINE_ITEM_ID_API_NAME;
        pliCriteria.filter.childFilter.predicates = new List<APT_PLICriteriaModel.Predicates>();
        pliCriteria.filter.childFilter.condExpr = '';

        //add all the criterias in json
        for(Map<String, String> criteriaField: criteriaFields)
        {
            //add predicates
            APT_PLICriteriaModel.Predicates predicate = new APT_PLICriteriaModel.Predicates();
            predicate.RowNum = rowNum;
            predicate.FieldValue = criteriaField.get(APT_Constants.FIELD_VALUE);
            predicate.FieldType = criteriaField.get(APT_Constants.FIELD_TYPE);
            predicate.FieldName = criteriaField.get(APT_Constants.FIELD_NAME);
            predicate.FieldLabel = criteriaField.get(APT_Constants.FIELD_LABEL);
            predicate.CompOper = APT_Constants.OPERATOR_EQUAL_TO;

            //add row number
            if(rowNum != criteriaFields.size())
            {
                predicate.BoolOper = APT_Constants.OPERATOR_AND;
            }

            pliCriteria.filter.childFilter.predicates.add(predicate);

            //add condition expression
            if(pliCriteria.filter.childFilter.condExpr != '')
            {
                pliCriteria.filter.childFilter.condExpr = pliCriteria.filter.childFilter.condExpr + APT_Constants.SEPERATOR_SPACE + APT_Constants.OPERATOR_AND + APT_Constants.SEPERATOR_SPACE;
            }
            pliCriteria.filter.childFilter.condExpr = pliCriteria.filter.childFilter.condExpr + rowNum;

            //add expression
            if(pliCriteria.exprStr != '')
            {
                pliCriteria.exprStr = pliCriteria.exprStr + APT_Constants.SEPERATOR_SPACE + APT_Constants.OPERATOR_AND + APT_Constants.SEPERATOR_SPACE;
            }

            //add fields
            pliCriteria.fields.add(criteriaField.get(APT_Constants.FIELD_EXPR));

            pliCriteria.exprStr = pliCriteria.exprStr + APT_Constants.ROUND_PARANTHESIS_START + criteriaField.get(APT_Constants.FIELD_LABEL) + APT_Constants.SEPERATOR_EQUAL + criteriaField.get(APT_Constants.FIELD_VALUE) + APT_Constants.ROUND_PARANTHESIS_END;

            rowNum++;
        }

        pliCriteria.filter.childFilter.childSObjectName = APT_Constants.OBJECT_API_NAME_PRODUCT_ATTRIBUTE_VALUE;
        pliCriteria.filter.childFilter.childSObjectLabel = APT_Constants.OBJECT_LABEL_PRODUCT_ATTRIBUTE_VALUE;

        return JSON.serialize(pliCriteria);
    }


    /**
        This method will create price matrix records.
        @params -
        listPriceListItem - list of price list item
        mapExistingPriceMatrix - exising PM
        products - Unique collection of products for which the job is being run.
     */
    public static List<Apttus_Config2__PriceMatrix__c> createPriceMatrixGeneric(List<Apttus_Config2__PriceListItem__c> listPriceListItem,
                                                                                map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix,
                                                                                Map<Id,Product2> products)
    {
        List<Apttus_Config2__PriceMatrix__c> listPriceMatrix = new List<Apttus_Config2__PriceMatrix__c>();
        Apttus_Config2__PriceMatrix__c existingPriceMatrix;
        Apttus_Config2__PriceMatrix__c priceMatrix;

        //get price dimensions
        List<Apttus_Config2__PriceDimension__c> priceDimensions = [SELECT Id, Name, Apttus_Config2__Datasource__c
                                                                   FROM Apttus_Config2__PriceDimension__c];

        //create map of price dimensions
        Map<String, String> mapPriceDimensions = new Map<String, String>();
        for(Apttus_Config2__PriceDimension__c priceDimension : priceDimensions)
        {
            mapPriceDimensions.put(priceDimension.Apttus_Config2__Datasource__c, priceDimension.Id);
        }

        system.debug('createPriceMatrixGeneric mapPriceDimensions: ' + mapPriceDimensions);

        //get price matrix mapping to get dimensions
        List<APT_Price_Matrix_Mapping__c> priceMatrixMappings = [SELECT APT_Dimension1__c, APT_Dimension2__c, APT_Dimension3__c,
                                                                        APT_Dimension4__c, APT_Dimension5__c, APT_Dimension6__c,
                                                                        APT_Dimension1_API__c, APT_Dimension2_API__c, APT_Dimension3_API__c,
                                                                        APT_Dimension4_API__c, APT_Dimension5_API__c, APT_Dimension6_API__c,
                                                                        APT_Dimension1_Type__c, APT_Dimension2_Type__c, APT_Dimension3_Type__c,
                                                                        APT_Dimension4_Type__c, APT_Dimension5_Type__c, APT_Dimension6_Type__c,
                                                                        APT_Product__c
                                                                FROM APT_Price_Matrix_Mapping__c
                                                                WHERE APT_Product__c IN :products.keySet()];

        //create map of dimension id and type
        Map<String, Map<String, String>> mapDimension = new Map<String, Map<String, String>>();

        for(APT_Price_Matrix_Mapping__c priceMatrixMapping : priceMatrixMappings)
        {
            Map<String, String> dimensionDetail = new Map<String, String>();

            for(String dataSource : mapPriceDimensions.keySet())
            {
                if(priceMatrixMapping.APT_Dimension1_API__c != null && priceMatrixMapping.APT_Dimension1_API__c.equalsIgnoreCase(dataSource))
                {
                    dimensionDetail.put('Dimension 1', mapPriceDimensions.get(dataSource));
                    dimensionDetail.put('Dimension 1 Type', priceMatrixMapping.APT_Dimension1_Type__c);
                }
                else if(priceMatrixMapping.APT_Dimension2_API__c != null && priceMatrixMapping.APT_Dimension2_API__c.equalsIgnoreCase(dataSource))
                {
                    dimensionDetail.put('Dimension 2', mapPriceDimensions.get(dataSource));
                    dimensionDetail.put('Dimension 2 Type', priceMatrixMapping.APT_Dimension2_Type__c);
                }
                else if(priceMatrixMapping.APT_Dimension3_API__c != null && priceMatrixMapping.APT_Dimension3_API__c.equalsIgnoreCase(dataSource))
                {
                    dimensionDetail.put('Dimension 3', mapPriceDimensions.get(dataSource));
                    dimensionDetail.put('Dimension 3 Type', priceMatrixMapping.APT_Dimension3_Type__c);
                }
                else if(priceMatrixMapping.APT_Dimension4_API__c != null && priceMatrixMapping.APT_Dimension4_API__c.equalsIgnoreCase(dataSource))
                {
                    dimensionDetail.put('Dimension 4', mapPriceDimensions.get(dataSource));
                    dimensionDetail.put('Dimension 4 Type', priceMatrixMapping.APT_Dimension4_Type__c);
                }
                else if(priceMatrixMapping.APT_Dimension5_API__c != null && priceMatrixMapping.APT_Dimension5_API__c.equalsIgnoreCase(dataSource))
                {
                    dimensionDetail.put('Dimension 5', mapPriceDimensions.get(dataSource));
                    dimensionDetail.put('Dimension 5 Type', priceMatrixMapping.APT_Dimension5_Type__c);
                }
                else if(priceMatrixMapping.APT_Dimension6_API__c != null && priceMatrixMapping.APT_Dimension6_API__c.equalsIgnoreCase(dataSource))
                {
                    dimensionDetail.put('Dimension 6', mapPriceDimensions.get(dataSource));
                    dimensionDetail.put('Dimension 6 Type', priceMatrixMapping.APT_Dimension6_Type__c);
                }
            }

            mapDimension.put(priceMatrixMapping.APT_Product__c, dimensionDetail);
        }

        system.debug('createPriceMatrixGeneric mapDimension: ' + mapDimension);

        //for each price list item, create price matrix
        for(Apttus_Config2__PriceListItem__c priceListItem : listPriceListItem)
        {
            //check if price matrix exists for given pli, if not create new
            existingPriceMatrix = mapExistingPriceMatrix.get(priceListItem.Id);
            priceMatrix = new Apttus_Config2__PriceMatrix__c();

            //assign dimension ids and type to price matrix records
            priceMatrix.Apttus_Config2__Dimension1Id__c = mapDimension.get(priceListItem.Apttus_Config2__ProductId__c)?.get('Dimension 1');
            priceMatrix.Apttus_Config2__Dimension1ValueType__c = mapDimension.get(priceListItem.Apttus_Config2__ProductId__c)?.get('Dimension 1 Type');

            priceMatrix.Apttus_Config2__Dimension2Id__c = mapDimension.get(priceListItem.Apttus_Config2__ProductId__c)?.get('Dimension 2');
            priceMatrix.Apttus_Config2__Dimension2ValueType__c = mapDimension.get(priceListItem.Apttus_Config2__ProductId__c)?.get('Dimension 2 Type');

            priceMatrix.Apttus_Config2__Dimension3Id__c = mapDimension.get(priceListItem.Apttus_Config2__ProductId__c)?.get('Dimension 3');
            priceMatrix.Apttus_Config2__Dimension3ValueType__c = mapDimension.get(priceListItem.Apttus_Config2__ProductId__c)?.get('Dimension 3 Type');

            priceMatrix.Apttus_Config2__Dimension4Id__c = mapDimension.get(priceListItem.Apttus_Config2__ProductId__c)?.get('Dimension 4');
            priceMatrix.Apttus_Config2__Dimension4ValueType__c = mapDimension.get(priceListItem.Apttus_Config2__ProductId__c)?.get('Dimension 4 Type');

            priceMatrix.Apttus_Config2__Dimension5Id__c = mapDimension.get(priceListItem.Apttus_Config2__ProductId__c)?.get('Dimension 5');
            priceMatrix.Apttus_Config2__Dimension5ValueType__c = mapDimension.get(priceListItem.Apttus_Config2__ProductId__c)?.get('Dimension 5 Type');

            priceMatrix.Apttus_Config2__Dimension6Id__c = mapDimension.get(priceListItem.Apttus_Config2__ProductId__c)?.get('Dimension 6');
            priceMatrix.Apttus_Config2__Dimension6ValueType__c = mapDimension.get(priceListItem.Apttus_Config2__ProductId__c)?.get('Dimension 6 Type');

            priceMatrix.Apttus_Config2__PriceListItemId__c = priceListItem.Id;
            priceMatrix.Apttus_Config2__Sequence__c = 1;

            if(existingPriceMatrix != null)
            {
                priceMatrix.Id = existingPriceMatrix.Id;
            }

            system.debug('createPriceMatrixGeneric priceMatrix: ' + priceMatrix);

            listPriceMatrix.add(priceMatrix);
        }

        return listPriceMatrix;
    }

    /**
        This method will create price matrix entry records.
        @params -
        listPriceMatrix - list of price matrix records
        pricingKeyToDataMap- price data with pricing key
        priceTypeValues - Price Types associated with respective product type (Per Kg, Subsequent, Per Item etc)
        productType - Product type for which job is run.
    */
    public static List<Apttus_Config2__PriceMatrixEntry__c> createPriceMatrixEntryGeneric(List<Apttus_Config2__PriceMatrix__c> listPriceMatrix,
                                                                                          Map<String, Set<Map<String,String>>> pricingKeyToDataMap,
                                                                                          Map<String, String> priceTypeValues,
                                                                                          String productType)
    {
        List<Apttus_Config2__PriceMatrixEntry__c> listPriceMatrixEntry = new List<Apttus_Config2__PriceMatrixEntry__c>();
        Apttus_Config2__PriceMatrixEntry__c priceMatrixEntry = new Apttus_Config2__PriceMatrixEntry__c();

        //if no price matrix or pricing properties
        if(listPriceMatrix.size() == 0)
        {
            return listPriceMatrixEntry;
        }

        //get price matrix mapping to get dimensions
        List<APT_Price_Matrix_Mapping__c> priceMatrixMappings = [SELECT APT_Dimension1__c, APT_Dimension2__c, APT_Dimension3__c,
                                                                        APT_Dimension4__c, APT_Dimension5__c, APT_Dimension6__c,
                                                                        APT_Dimension1_API__c, APT_Dimension2_API__c, APT_Dimension3_API__c,
                                                                        APT_Dimension4_API__c, APT_Dimension5_API__c, APT_Dimension6_API__c,
                                                                        APT_Dimension1_Type__c, APT_Dimension2_Type__c, APT_Dimension3_Type__c,
                                                                        APT_Dimension4_Type__c, APT_Dimension5_Type__c, APT_Dimension6_Type__c,
                                                                        APT_Product__c
                                                                FROM APT_Price_Matrix_Mapping__c];

        //create map of pricing matrix
        Map<String, APT_Price_Matrix_Mapping__c> mapPriceMatrixMapping = new Map<String, APT_Price_Matrix_Mapping__c>();
        for(APT_Price_Matrix_Mapping__c priceMatrixMapping : priceMatrixMappings)
        {
            mapPriceMatrixMapping.put(priceMatrixMapping.APT_Product__c, priceMatrixMapping);
        }

        //for each price matrix, create price matrix entries
        for(Apttus_Config2__PriceMatrix__c priceMatrix : listPriceMatrix)
        {
            Integer iSequence = 1;

            //get dimesion field Names
            Map<string, string> dimensions = new Map<string, string>();
            dimensions.put('dimension1', (string)mapPriceMatrixMapping.get(priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c)?.get('APT_Dimension1__c'));
            dimensions.put('dimension2', (string)mapPriceMatrixMapping.get(priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c)?.get('APT_Dimension2__c'));
            dimensions.put('dimension3', (string)mapPriceMatrixMapping.get(priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c)?.get('APT_Dimension3__c'));
            dimensions.put('dimension4', (string)mapPriceMatrixMapping.get(priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c)?.get('APT_Dimension4__c'));
            dimensions.put('dimension5', (string)mapPriceMatrixMapping.get(priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c)?.get('APT_Dimension5__c'));
            dimensions.put('dimension6', (string)mapPriceMatrixMapping.get(priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c)?.get('APT_Dimension6__c'));

            system.debug('createPriceMatrixEntryGeneric dimensions: ' + dimensions);

            Integer totalDimensions = 0;

            //assign dimension values
            for(string dimension: dimensions.keySet())
            {
                string dimensionName = dimensions.get(dimension);
                if(!String.isEmpty(dimensionName))
                {
                    totalDimensions++;
                }
            }

            //get domestice price data for the pricing key
            Set<Map<String,String>> listPricingData = new Set<Map<String,String>>();
            if(productType == 'Startrack')
            {
                listPricingData = createPMEDataForSTE(pricingKeyToDataMap, priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c, priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Zone_Type__c, priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Zones__c);
            }
            else
            {
                listPricingData = pricingKeyToDataMap.get(priceMatrix.Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c);
            }

            system.debug('createPriceMatrixEntryGeneric listPricingData: ' + listPricingData);
            if(listPricingData != null && !listPricingData.isEmpty()){
            for(Map<String,String> pricingData : listPricingData)
            {
                string[] dimensionValue = new string[6];
                Integer dimensionIndex = 0;
                Integer dimensionCount = 0;

                //assign dimension values
                for(string dimension: dimensions.keySet())
                {
                    string dimensionName = dimensions.get(dimension);

                    //assign actual dimesion value
                    if(!String.isEmpty(dimensionName) && !dimensionName.contains(APT_Constants.PRICE_TYPE))
                    {
                        dimensionValue[dimensionIndex] = String.valueOf(pricingData.get(dimensionName));
                        dimensionCount++;
                    }

                    dimensionIndex++;
                }

                if(dimensionCount == totalDimensions)
                {
                    //create pme
                    //Updated below logic to include FSR. FSR does not have price type dimensions (Eg : Base Rate, Per Kg Rate). However, it requires amount to be populated on PME.
                    Decimal totalAmount  = pricingData.get('Amount') != null ? Decimal.valueOf(pricingData.get('Amount')) : null;
                    priceMatrixEntry = createPME(dimensionValue, priceMatrix.Id, iSequence, totalAmount);
                    listPriceMatrixEntry.add(priceMatrixEntry);
                    iSequence++;
                }
                else
                {
                    //assign price type specific dimensions
                    if(String.valueOf(pricingData.get('Base Rate')) != null)
                    {
                        dimensionIndex = 0;

                        //assign price type dimension values
                        for(string dimension: dimensions.keySet())
                        {
                            string dimensionName = dimensions.get(dimension);

                            if(!String.isEmpty(dimensionName) && dimensionName.contains(APT_Constants.PRICE_TYPE))
                            {
                                dimensionValue[dimensionIndex] = priceTypeValues.get('Base Rate');

                                //create pme
                                priceMatrixEntry = createPME(dimensionValue, priceMatrix.Id, iSequence, Decimal.valueOf(pricingData.get('Base Rate')));
                                listPriceMatrixEntry.add(priceMatrixEntry);
                                iSequence++;
                            }

                            dimensionIndex++;
                        }
                    }

                    //assign price type specific dimensions
                    if(String.valueOf(pricingData.get('Subsequent Rate')) != null)
                    {
                        dimensionIndex = 0;

                        //assign price type dimension values
                        for(string dimension: dimensions.keySet())
                        {
                            string dimensionName = dimensions.get(dimension);

                            if(!String.isEmpty(dimensionName) && dimensionName.contains(APT_Constants.PRICE_TYPE))
                            {
                                dimensionValue[dimensionIndex] = priceTypeValues.get('Subsequent Rate');

                                //create pme
                                priceMatrixEntry = createPME(dimensionValue, priceMatrix.Id, iSequence, Decimal.valueOf(pricingData.get('Subsequent Rate')));
                                listPriceMatrixEntry.add(priceMatrixEntry);
                                iSequence++;
                            }

                            dimensionIndex++;
                        }
                    }

                    //assign price type specific dimensions
                    if(String.valueOf(pricingData.get('Per Kg Rate')) != null)
                    {
                        dimensionIndex = 0;

                        //assign price type dimension values
                        for(string dimension: dimensions.keySet())
                        {
                            string dimensionName = dimensions.get(dimension);

                            if(!String.isEmpty(dimensionName) && dimensionName.contains(APT_Constants.PRICE_TYPE))
                            {
                                dimensionValue[dimensionIndex] = priceTypeValues.get('Per Kg Rate');

                                //create pme
                                priceMatrixEntry = createPME(dimensionValue, priceMatrix.Id, iSequence, Decimal.valueOf(pricingData.get('Per Kg Rate')));
                                listPriceMatrixEntry.add(priceMatrixEntry);
                                iSequence++;
                            }

                            dimensionIndex++;
                        }
                    }
                    //assign price type specific dimensions - International
                    if(String.valueOf(pricingData.get('CSP Per Item Rate')) != null)
                    {
                        dimensionIndex = 0;

                        //assign price type dimension values
                        for(string dimension: dimensions.keySet())
                        {
                            string dimensionName = dimensions.get(dimension);

                            if(!String.isEmpty(dimensionName) && dimensionName.contains(APT_Constants.PRICE_TYPE))
                            {
                                dimensionValue[dimensionIndex] = priceTypeValues.get('Per Item Rate');

                                //create pme
                                priceMatrixEntry = createPME(dimensionValue, priceMatrix.Id, iSequence, Decimal.valueOf(pricingData.get('CSP Per Item Rate')));
                                listPriceMatrixEntry.add(priceMatrixEntry);
                                iSequence++;
                            }

                            dimensionIndex++;
                        }
                    }
                    //assign price type specific dimensions
                    if(String.valueOf(pricingData.get('CSP Per Kg Rate')) != null)
                    {
                        dimensionIndex = 0;

                        //assign price type dimension values
                        for(string dimension: dimensions.keySet())
                        {
                            string dimensionName = dimensions.get(dimension);

                            if(!String.isEmpty(dimensionName) && dimensionName.contains(APT_Constants.PRICE_TYPE))
                            {
                                dimensionValue[dimensionIndex] = priceTypeValues.get('Per Kg Rate');

                                //create pme
                                priceMatrixEntry = createPME(dimensionValue, priceMatrix.Id, iSequence, Decimal.valueOf(pricingData.get('CSP Per Kg Rate')));
                                listPriceMatrixEntry.add(priceMatrixEntry);
                                iSequence++;
                            }

                            dimensionIndex++;
                        }
                    }



                }
            }
            }

        }

        return listPriceMatrixEntry;
    }

    /**
        This method will create price matrix entry records for startrack products.
        @params -
        listPriceMatrix - list of price matrix records
        mapDomesticPriceData- get domestic price data using key. Key is product code, category, network type, pickup zone and dest zone
    */
    public static Set<Map<String,String>> createPMEDataForSTE(Map<String, Set<Map<String,String>>> pricingKeyToDataMap, String pricingKey, String pliZoneType, String pliZones)
    {
        Set<Map<String,String>> listPricingData = new Set<Map<String,String>>();

        //get domestice price data for the pricing key
        Set<Map<String,String>> listDomesticPriceData = new Set<Map<String,String>>();
        listDomesticPriceData = pricingKeyToDataMap.get(pricingKey);

        system.debug('listDomesticPriceData: ' + listDomesticPriceData);

        if(listDomesticPriceData != null && listDomesticPriceData.size() > 0)
        {
            system.debug('listDomesticPriceData Size: ' + listDomesticPriceData.size());
            Integer iSequence = 1;
            String domesticZoneType;

            //get zone type for the main outbound domestic entry based on which price matrix entries will be created
            for(Map<String,String> domesticPriceData : listDomesticPriceData)
            {
                if(domesticPriceData.get('Outbound - Inbound') == APT_Constants.OUTBOUND)
                {
                    domesticZoneType = domesticPriceData.get('Zone Type');
                    break;
                }
            }

            if(domesticZoneType != null)
            {
                //deserialize zones
                APT_ZoneTypeModel zoneTypeModel = (APT_ZoneTypeModel)JSON.deserialize(domesticZoneType, APT_ZoneTypeModel.class);
                system.debug('zoneTypeModel: ' + zoneTypeModel);

                //in case of onforwarding alternate zone, get domestic data for all alternate zones too
                if(zoneTypeModel.onforwardingAlternateZone != null && pliZoneType == APT_Constants.ZONE_TYPE_ONFORWARDING_ALTERNATE)
                {
                    //get pricing Key
                    String[] pricingKeyValues = pricingKey.Split(APT_Constants.ADD_TILDE);

                    //get all alternate zones
                    string[] onforwardAlternateZones = zoneTypeModel.onforwardingAlternateZone.split(APT_Constants.ADD_COMMA);
                    for(String onforwardAlternateZone: onforwardAlternateZones)
                    {
                        if(pliZones == onforwardAlternateZone)
                        {
                            string[] onforwardAlternate = onforwardAlternateZone.split(APT_Constants.ADD_TILDE);

                            //generate new pricing key to get alternate zones data and add it to exising list
                            String alternatePricingKey = pricingKeyValues[0] + APT_Constants.ADD_TILDE + onforwardAlternate[1];

                            Set<Map<String,String>> alternateZoneDomesticData = pricingKeyToDataMap.get(alternatePricingKey);

                            if(alternateZoneDomesticData != null)
                            {
                                listDomesticPriceData.addall(alternateZoneDomesticData);
                            }
                        }
                    }
                }

                for(Map<String,String> domesticPriceData : listDomesticPriceData)
                {
                    Set<string> zoneTypes = new Set<string>();

                    //for direct zone
                    if(zoneTypeModel.directZone != null && pliZoneType == APT_Constants.ZONE_TYPE_DIRECT)
                    {
                        //if inbound, search in from zone. if outbound, search in to zone
                        if((domesticPriceData.get('Outbound - Inbound') == APT_Constants.OUTBOUND && domesticPriceData.get('Pickup Zone Code') == zoneTypeModel.directZone) ||
                        (domesticPriceData.get('Outbound - Inbound') == APT_Constants.INBOUND && domesticPriceData.get('Destination Zone Code') == zoneTypeModel.directZone))
                        {
                            zoneTypes.add(APT_Constants.ZONE_TYPE_DIRECT);
                        }
                    }
                    else
                    {
                        //for onforwarding zone
                        if(zoneTypeModel.onforwardingZone != null && pliZoneType == APT_Constants.ZONE_TYPE_ONFORWARDING)
                        {
                            //if inbound, search in from zone. if outbound, search in to zone
                            if((domesticPriceData.get('Outbound - Inbound') == APT_Constants.OUTBOUND && domesticPriceData.get('Pickup Zone Code') == zoneTypeModel.onforwardingZone) ||
                                (domesticPriceData.get('Outbound - Inbound') == APT_Constants.INBOUND && domesticPriceData.get('Destination Zone Code') == zoneTypeModel.onforwardingZone))
                            {
                                zoneTypes.add(APT_Constants.ZONE_TYPE_ONFORWARDING);
                            }
                        }
                        //for onforwarding alternate zone
                        if(zoneTypeModel.onforwardingAlternateZone != null && pliZoneType == APT_Constants.ZONE_TYPE_ONFORWARDING_ALTERNATE)
                        {
                            string[] onforwardingAlternateZones = zoneTypeModel.onforwardingAlternateZone.split(APT_Constants.ADD_COMMA);
                            for(String onforwardingAlternateZone: onforwardingAlternateZones)
                            {
                                if(pliZones == onforwardingAlternateZone)
                                {
                                    string[] onforwardingAlternate = onforwardingAlternateZone.split(APT_Constants.ADD_TILDE);

                                    //if inbound, search in from zone. if outbound, search in to zone
                                    if((domesticPriceData.get('Outbound - Inbound') == APT_Constants.OUTBOUND && domesticPriceData.get('Pickup Zone Code') == onforwardingAlternate[0]) ||
                                        (domesticPriceData.get('Outbound - Inbound') == APT_Constants.INBOUND && domesticPriceData.get('Destination Zone Code') == onforwardingAlternate[0]))
                                    {
                                        zoneTypes.add(APT_Constants.ZONE_TYPE_ONFORWARDING);
                                    }

                                    //if inbound, search in from zone. if outbound, search in to zone
                                    if((domesticPriceData.get('Outbound - Inbound') == APT_Constants.OUTBOUND && domesticPriceData.get('Pickup Zone Code') == onforwardingAlternate[1]) ||
                                        (domesticPriceData.get('Outbound - Inbound') == APT_Constants.INBOUND && domesticPriceData.get('Destination Zone Code') == onforwardingAlternate[1]))
                                    {
                                        zoneTypes.add(APT_Constants.ZONE_TYPE_ALTERNATE);
                                    }
                                }
                            }
                        }
                    }

                    system.debug('zoneTypes: ' + zoneTypes);

                    //for each zone, create price matrix entry
                    for(string zoneType: zoneTypes)
                    {
                        Map<String,String> pricingData = new Map<String,String>();
                        pricingData = domesticPriceData;
                        pricingData.put('Zone Type', zoneType);
                        listPricingData.add(pricingData);
                    }
                }
            }
        }

        if(listPricingData == null || listPricingData.isEmpty())
        {
            listPricingData = listDomesticPriceData;
        }
        return listPricingData;
    }

    /**
        This method will create price matrix entry records.
        @params -
        dimensionValue - dimension values
        priceMatrixId - price matrix id
        iSequence - sequence number
        amount - amount
    */
    private static Apttus_Config2__PriceMatrixEntry__c createPME(string[] dimensionValue, string priceMatrixId, Integer iSequence, Decimal amount)
    {
        //creates pme records from the input params for prime matrix
        Apttus_Config2__PriceMatrixEntry__c priceMatrixEntry = new Apttus_Config2__PriceMatrixEntry__c();
        priceMatrixEntry.Apttus_Config2__Dimension1Value__c = dimensionValue[0];
        priceMatrixEntry.Apttus_Config2__Dimension2Value__c = dimensionValue[1];
        priceMatrixEntry.Apttus_Config2__Dimension3Value__c = dimensionValue[2];
        priceMatrixEntry.Apttus_Config2__Dimension4Value__c = dimensionValue[3];
        priceMatrixEntry.Apttus_Config2__Dimension5Value__c = dimensionValue[4];
        priceMatrixEntry.Apttus_Config2__Dimension6Value__c = dimensionValue[5];
        priceMatrixEntry.Apttus_Config2__AdjustmentType__c = APT_Constants.ADJUSTMENT_TYPE_LIST_PRICE_OVERRIDE;
        priceMatrixEntry.Apttus_Config2__PriceMatrixId__c = priceMatrixId;
        priceMatrixEntry.Apttus_Config2__Sequence__c = iSequence;
        priceMatrixEntry.Apttus_Config2__AdjustmentAmount__c = amount;
        priceMatrixEntry.Apttus_Config2__PriceOverride__c = amount;

        return priceMatrixEntry;
    }

    /**
        send notification email
    **/
    public static void sendEmailNotification(String batchName, AsyncApexJob asyncApexJob, set<String> setErrorMessage, String successMessage)
    {
        //send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        //get email addresses
        APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
        List<String> toAddresses = new list<String>();
        String emailAddresses;
        String errorMessage;

        if(r2tSystemProperties != null && r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c != null)
        {
            emailAddresses = r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c;
        }

        if(!string.IsEmpty(emailAddresses))
        {
            toAddresses = emailAddresses.split(APT_Constants.ADD_COMMA);
        }

        toAddresses.add(asyncApexJob.CreatedBy.Email);
        mail.setToAddresses(toAddresses);
        mail.setSubject(APT_Constants.PRICING_JOB_STATUS);

        //error count
        Integer iErrorCount = setErrorMessage != null ? setErrorMessage.size() : 0;

        if(setErrorMessage != null)
        {
            for(String errMessage : setErrorMessage)
            {
                if(errorMessage != null)
                {
                    errorMessage += APT_Constants.SEPARATOR_NEXT_LINE + errMessage;
                }
                else
                {
                    errorMessage = errMessage;
                }
            }
        }

        //add batch error message in email
        if(errorMessage != null)
        {
            mail.setPlainTextBody(batchName + asyncApexJob.TotalJobItems + APT_Constants.BATCHES_WITH + iErrorCount + APT_Constants.FAILURES_ERRORS + errorMessage);
        }
        else if(successMessage != null)
        {
            mail.setPlainTextBody(successMessage);
        }

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}