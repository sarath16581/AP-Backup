/**
Descirtion: This scheduleable class will schedule job to calculate international pricing. Create Price List Item and Price Matrix records. 
Price Matrix Entry records will be creates using batch apex.
Created By - Mausam Padhiyar
Created Date - 6th Oct, 2015
**/
global class APT_CalculateInternationalPricingSched implements Schedulable {
    //Class to calculate International Pricing Schedule
    /**
    Execute method
    **/
    global void execute (SchedulableContext SC) {
        set<String> setErrorMessage = new set<String>();
        String emailAddresses;
        try {            
            //get default price list item
            APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
            String defaultPriceListID;            
            if(r2tSystemProperties != null) {
                if(!String.isEmpty(r2tSystemProperties.APT_Default_Price_List_ID__c)) {
                    defaultPriceListID = r2tSystemProperties.APT_Default_Price_List_ID__c;
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_MISSING_DEFAULT_PRICE_LIST_ID);
                }
                if(!String.isEmpty(r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c)) {
                    emailAddresses = r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c;
                }
            } 
            
            //validate if international price data exists?
            list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
            listInternationalPriceData = database.query(APT_Constants.SOQL_SELECT + APT_PricingUtility.getAllFields(APT_Constants.SOQL_INTERNATIONAL_PRICE_DATA_OBJECT) + APT_Constants.SOQL_INTERNATIONAL_PRICE_DATA_ORDER_BY);
            /**
            listInternationalPriceData = [SELECT Id, Name, APT_Band__c, APT_Band_Range_Max__c, APT_Band_Range_Min__c,
                                        APT_Calc_Per_Item_Rate__c, APT_Calc_Per_Kg_Rate__c, APT_CSP_Per_Item_Rate__c,
                                        APT_CSP_Per_Kg_Rate__c, APT_eParcel_Per_Item_Rate__c,
                                        APT_eParcel_Per_Kg_Rate__c, APT_Industry__c, APT_Product__c, APT_Zone__c
                                        FROM APT_International_Price_Data__c];
            **/
            System.debug('********************listInternationalPriceData:'+listInternationalPriceData);
            if(listInternationalPriceData.size() == 0) {
                setErrorMessage .add(APT_Constants.NO_INTERNATIONAL_PRICE_FOUND);
            }
            
            //validate if any missing price dimension
            //set<String> setDimension = new set<String>{'Zone', 'International Price Type'};
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = APT_R2T_International_Pricing_Properties__c.getValues(APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES);
            set<String> setDimension = new set<String>();
            map<String, list<String>> mapChargeType = new map<String, list<String>>();
            if(r2tInternationalPricingProperties != null) {
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension1_Name__c)) {
                    setDimension.add(r2tInternationalPricingProperties.APT_Dimension1_Name__c);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension1_Name__c) && (String.isEmpty(r2tInternationalPricingProperties.APT_Dimension1_Type__c) || r2tInternationalPricingProperties.APT_Dimension1_Type__c.equalsIgnoreCase(APT_Constants.SEPERATOR_NO_SPACE))) {
                        setErrorMessage .add(APT_Constants.ERROR_MISSING_DIMENSION_TYPE_FOR + r2tInternationalPricingProperties.APT_Dimension1_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension1_Name__c) && (String.isEmpty(r2tInternationalPricingProperties.APT_Dimension1_Value__c) || r2tInternationalPricingProperties.APT_Dimension1_Value__c.equalsIgnoreCase(APT_Constants.SEPERATOR_NO_SPACE))) {
                    setErrorMessage .add(APT_Constants.ERROR_MISSING_DIMENSION_VALUE_FOR + r2tInternationalPricingProperties.APT_Dimension1_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension2_Name__c)) {
                    setDimension.add(r2tInternationalPricingProperties.APT_Dimension2_Name__c);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension2_Name__c) && (String.isEmpty(r2tInternationalPricingProperties.APT_Dimension2_Type__c) || r2tInternationalPricingProperties.APT_Dimension2_Type__c.equalsIgnoreCase(APT_Constants.SEPERATOR_NO_SPACE))) {
                    setErrorMessage .add(APT_Constants.ERROR_MISSING_DIMENSION_TYPE_FOR + r2tInternationalPricingProperties.APT_Dimension2_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension2_Name__c) && (String.isEmpty(r2tInternationalPricingProperties.APT_Dimension2_Value__c) || r2tInternationalPricingProperties.APT_Dimension2_Value__c.equalsIgnoreCase(APT_Constants.SEPERATOR_NO_SPACE))) {
                    setErrorMessage .add(APT_Constants.ERROR_MISSING_DIMENSION_VALUE_FOR + r2tInternationalPricingProperties.APT_Dimension2_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension3_Name__c)) {
                    setDimension.add(r2tInternationalPricingProperties.APT_Dimension3_Name__c);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension3_Name__c) && (String.isEmpty(r2tInternationalPricingProperties.APT_Dimension3_Type__c) || r2tInternationalPricingProperties.APT_Dimension3_Type__c.equalsIgnoreCase(APT_Constants.SEPERATOR_NO_SPACE))) {
                    setErrorMessage .add(APT_Constants.ERROR_MISSING_DIMENSION_TYPE_FOR + r2tInternationalPricingProperties.APT_Dimension3_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension3_Name__c) && (String.isEmpty(r2tInternationalPricingProperties.APT_Dimension3_Value__c) || r2tInternationalPricingProperties.APT_Dimension3_Value__c.equalsIgnoreCase(APT_Constants.SEPERATOR_NO_SPACE))) {
                    setErrorMessage .add(APT_Constants.ERROR_MISSING_DIMENSION_VALUE_FOR + r2tInternationalPricingProperties.APT_Dimension3_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension4_Name__c)) {
                    setDimension.add(r2tInternationalPricingProperties.APT_Dimension4_Name__c);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension4_Name__c) && (String.isEmpty(r2tInternationalPricingProperties.APT_Dimension4_Type__c) || r2tInternationalPricingProperties.APT_Dimension4_Type__c.equalsIgnoreCase(APT_Constants.SEPERATOR_NO_SPACE))) {
                    setErrorMessage .add(APT_Constants.ERROR_MISSING_DIMENSION_TYPE_FOR + r2tInternationalPricingProperties.APT_Dimension4_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension4_Name__c) && (String.isEmpty(r2tInternationalPricingProperties.APT_Dimension4_Value__c) || r2tInternationalPricingProperties.APT_Dimension4_Value__c.equalsIgnoreCase(APT_Constants.SEPERATOR_NO_SPACE))) {
                    setErrorMessage .add(APT_Constants.ERROR_MISSING_DIMENSION_VALUE_FOR + r2tInternationalPricingProperties.APT_Dimension4_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension5_Name__c)) {
                    setDimension.add(r2tInternationalPricingProperties.APT_Dimension5_Name__c);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension5_Name__c) && (String.isEmpty(r2tInternationalPricingProperties.APT_Dimension5_Type__c) || r2tInternationalPricingProperties.APT_Dimension5_Type__c.equalsIgnoreCase(APT_Constants.SEPERATOR_NO_SPACE))) {
                    setErrorMessage .add(APT_Constants.ERROR_MISSING_DIMENSION_TYPE_FOR + r2tInternationalPricingProperties.APT_Dimension5_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension5_Name__c) && (String.isEmpty(r2tInternationalPricingProperties.APT_Dimension5_Value__c) || r2tInternationalPricingProperties.APT_Dimension5_Value__c.equalsIgnoreCase(APT_Constants.SEPERATOR_NO_SPACE))) {
                    setErrorMessage .add(APT_Constants.ERROR_MISSING_DIMENSION_VALUE_FOR + r2tInternationalPricingProperties.APT_Dimension5_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension6_Name__c)) {
                    setDimension.add(r2tInternationalPricingProperties.APT_Dimension6_Name__c);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension6_Name__c) && (String.isEmpty(r2tInternationalPricingProperties.APT_Dimension6_Type__c) || r2tInternationalPricingProperties.APT_Dimension6_Type__c.equalsIgnoreCase(APT_Constants.SEPERATOR_NO_SPACE))) {
                    setErrorMessage .add(APT_Constants.ERROR_MISSING_DIMENSION_TYPE_FOR + r2tInternationalPricingProperties.APT_Dimension6_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_Dimension6_Name__c) && String.isEmpty(r2tInternationalPricingProperties.APT_Dimension6_Value__c)) {
                    setErrorMessage .add(APT_Constants.ERROR_MISSING_DIMENSION_VALUE_FOR + r2tInternationalPricingProperties.APT_Dimension6_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRLET_Charge_Type__c)) {
                    //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRLET_Charge_Types__c.split(',');
                    mapChargeType.put(APT_Constants.AIRLET_INTERNATIONAL_PRODUCT, new list<String> {r2tInternationalPricingProperties.APT_AIRLET_Charge_Type__c});
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.AIRLET_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_DOT);
                }

                if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRPTI_Charge_Type__c)) {
                    //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRPTI_Charge_Types__c.split(',');
                    mapChargeType.put(APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT, new list<String> {r2tInternationalPricingProperties.APT_AIRPTI_Charge_Type__c});
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_DOT);
                }
              
        //added By HA on 2-6-2017        
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_EXPRESS_MERCH_Charge_Type__c)) {
                    //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRPTI_Charge_Types__c.split(',');
                    mapChargeType.put(APT_Constants.PRODUCT_InternationalExpressMerchandise, new list<String> {r2tInternationalPricingProperties.APT_EXPRESS_MERCH_Charge_Type__c});
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.PRODUCT_InternationalExpressMerchandise + APT_Constants.SEPERATOR_DOT);
                }
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_EXPRESSDOCT_Charge_Type__c)) {
                    //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRPTI_Charge_Types__c.split(',');
                    mapChargeType.put(APT_Constants.PRODUCT_InternationalExpressDocuments, new list<String> {r2tInternationalPricingProperties.APT_EXPRESSDOCT_Charge_Type__c});
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.PRODUCT_InternationalExpressDocuments + APT_Constants.SEPERATOR_DOT);
                }
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRMAIL_LETTERS_Charge_Type__c)) {
                    //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRPTI_Charge_Types__c.split(',');
                    mapChargeType.put(APT_Constants.PRODUCT_AIRMAILLETTER, new list<String> {r2tInternationalPricingProperties.APT_AIRMAIL_LETTERS_Charge_Type__c});
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.PRODUCT_AIRMAILLETTER + APT_Constants.SEPERATOR_DOT);
                }
                
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_RETURNS_STANDARD_Charge_Type__c)) {
                    //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRPTI_Charge_Types__c.split(',');
                    mapChargeType.put(APT_Constants.PRODUCT_INTERNATIONALRETURNSINTERNATIONALSTANDARD, new list<String> {r2tInternationalPricingProperties.APT_RETURNS_STANDARD_Charge_Type__c});
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.PRODUCT_INTERNATIONALRETURNSINTERNATIONALSTANDARD + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_RETURNS_EXPRESS_Charge_Type__c)) {
                    //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRPTI_Charge_Types__c.split(',');
                    mapChargeType.put(APT_Constants.PRODUCT_INTERNATIONALRETURNSINTERTIONALEXPRESS, new list<String> {r2tInternationalPricingProperties.APT_RETURNS_EXPRESS_Charge_Type__c});
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.PRODUCT_INTERNATIONALRETURNSINTERTIONALEXPRESS + APT_Constants.SEPERATOR_DOT);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_ECONOMY_WITH_SIGN_Charge_Type__c)) {
                    //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRPTI_Charge_Types__c.split(',');
                    mapChargeType.put(APT_Constants.PRODUCT_INTERNATIONALECONOMYWITHSIGNATURE, new list<String> {r2tInternationalPricingProperties.APT_ECONOMY_WITH_SIGN_Charge_Type__c});
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.PRODUCT_INTERNATIONALECONOMYWITHSIGNATURE + APT_Constants.SEPERATOR_DOT);
                }
                
                    
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_STANDARD_WITH_SIGN_Charge_Type__c)) {
                    //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRPTI_Charge_Types__c.split(',');
                    mapChargeType.put(APT_Constants.PRODUCT_INTERNATIONALSTANDARDWITHSIGNATURE, new list<String> {r2tInternationalPricingProperties.APT_STANDARD_WITH_SIGN_Charge_Type__c});
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.PRODUCT_INTERNATIONALSTANDARDWITHSIGNATURE + APT_Constants.SEPERATOR_DOT);
                }
                
                
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_ECONOMY_Charge_Type__c)) {
                    //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRPTI_Charge_Types__c.split(',');
                    mapChargeType.put(APT_Constants.PRODUCT_InternationalEconomy, new list<String> {r2tInternationalPricingProperties.APT_ECONOMY_Charge_Type__c});
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.PRODUCT_InternationalEconomy + APT_Constants.SEPERATOR_DOT);
                }
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_STANDARD_Charge_Type__c)) {
                    //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRPTI_Charge_Types__c.split(',');
                    mapChargeType.put(APT_Constants.PRODUCT_InternationalStandard, new list<String> {r2tInternationalPricingProperties.APT_STANDARD_Charge_Type__c});
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.PRODUCT_InternationalStandard + APT_Constants.SEPERATOR_DOT);
                }
                
            //   // This Code was added by HA
              
            //     if(!String.isEmpty(r2tInternationalPricingProperties.APT_InternationPCMS_Charge_Type__c)) {
            //         //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRRPI_Charge_Types__c.split(',');
            //         mapChargeType.put(APT_Constants.PRODUCT_INTERNATIONALDIGITALPCMSBUNDLE, new list<String> {r2tInternationalPricingProperties.APT_InternationPCMS_Charge_Type__c});
            //     } else {
            //         setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.PRODUCT_INTERNATIONALDIGITALPCMSBUNDLE + APT_Constants.SEPERATOR_DOT);
            //     }
                
              // ends here   
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRRPI_Charge_Type__c)) {
                    //list<String> listChargeTypes = r2tInternationalPricingProperties.APT_AIRRPI_Charge_Types__c.split(',');
                    mapChargeType.put(APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT, new list<String> {r2tInternationalPricingProperties.APT_AIRRPI_Charge_Type__c});
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_DOT);
                }
                
                
                list<String> listAIRPCLChargeTypes = new list<String>();
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c)) {
                    listAIRPCLChargeTypes.add(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c);
                } 
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c)){
                    listAIRPCLChargeTypes.add(r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c);                   
                }
                if(listAIRPCLChargeTypes.size() > 0) {
                    mapChargeType.put(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT, listAIRPCLChargeTypes);
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_DOT);
                }
                
                list<String> listECIPCLChargeTypes = new list<String>();
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c)) {
                    listECIPCLChargeTypes.add(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c);
                } 
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c)) {
                    listECIPCLChargeTypes.add(r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c);
                }
                
                if(!String.isEmpty(r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c)) {
                    listECIPCLChargeTypes.add(r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c);
                }
                
                if(listECIPCLChargeTypes.size() > 0) {
                    mapChargeType.put(APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT, listECIPCLChargeTypes);
                } else {
                    setErrorMessage .add(APT_Constants.ERROR_NO_CHARGE_TYPES_FOUND_FOR_PRODUCT + APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT + APT_Constants.SEPERATOR_DOT);
                }
                
            } else {
                setErrorMessage .add(APT_Constants.ERROR_NO_CUSTOM_SETTINGS_WITH_NAME + APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES + APT_Constants.SEPERATOR_SPACE + APT_Constants.FOUND + APT_Constants.SEPERATOR_DOT);
            }
            
            if(setDimension.size() == 0) {
                setErrorMessage .add(APT_Constants.PRICE_DIMENSIONS_ARE_NOT_CONFIGURED);
            }
            
            map<String, String> mapDimension = new map<String, String>();
            for(Apttus_Config2__PriceDimension__c pd : [SELECT Id, Name 
                                                        FROM Apttus_Config2__PriceDimension__c
                                                        WHERE Name IN :setDimension]){
            
                if(setDimension.contains(pd.Name)) {
                    mapDimension.put(pd.Name, pd.Id);
                } else {
                    setErrorMessage .add(APT_Constants.NO_PRICE_DIMENSION_WITH_NAME + pd.Name + APT_Constants.SEPERATOR_SPACE + APT_Constants.STR_FOUND + APT_Constants.SEPERATOR_DOT);
                }
            }
            
            set<String> setProduct = new set<String>();
            //set<String> setIndustry = new set<String>();
            set<String> setBand = new set<String>();
            set<String> seteParcelLodgment = new Set<String>{APT_Constants.STR_TRUE, APT_Constants.STR_FALSE};     
            map<String, list<APT_International_Price_Data__c>> mapInternationalPriceData = new map<String, list<APT_International_Price_Data__c>>();
            for(APT_International_Price_Data__c ipd : listInternationalPriceData) {
                //setIndustry.add(ipd.APT_Industry__c);
                setBand.add(ipd.APT_Band__c);
                //AIRPCL
                System.debug('ipd.APT_Product__c'+ipd.APT_Product__c);
                System.debug('r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c'+r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c);
                if(!String.isEmpty(ipd.APT_Product__c) && !String.isEmpty(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT) && ipd.APT_Product__c.equalsIgnoreCase(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT) && !String.isEmpty(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c)) {
                    list<APT_International_Price_Data__c> listIPD = mapInternationalPriceData.get(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c);
                    if(listIPD != null && listIPD.size() > 0) {
                        listIPD.add(ipd);
                        mapInternationalPriceData.put(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c, listIPD);
                    } else {
                        listIPD = new list<APT_International_Price_Data__c>();
                        listIPD.add(ipd);
                        mapInternationalPriceData.put(r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c, listIPD);
                    }
                } 
                //AIRSMPCL
                else if(!String.isEmpty(ipd.APT_Product__c) && !String.isEmpty(APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT) && ipd.APT_Product__c.equalsIgnoreCase(APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT)  && !String.isEmpty(r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c)) {
                    list<APT_International_Price_Data__c> listIPD = mapInternationalPriceData.get(r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c);
                    if(listIPD != null && listIPD.size() > 0) {
                        listIPD.add(ipd);
                        mapInternationalPriceData.put(r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c, listIPD);
                    } else {
                        listIPD = new list<APT_International_Price_Data__c>();
                        listIPD.add(ipd);
                        mapInternationalPriceData.put(r2tInternationalPricingProperties.APT_AIRSMPCL_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c, listIPD);
                    }
                }
                //EMSDOCT
                else if(!String.isEmpty(ipd.APT_Product__c) && !String.isEmpty(APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT) && ipd.APT_Product__c.equalsIgnoreCase(APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT)  && !String.isEmpty(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c)) {
                    list<APT_International_Price_Data__c> listIPD = mapInternationalPriceData.get(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c);
                    if(listIPD != null && listIPD.size() > 0) {
                        listIPD.add(ipd);
                        mapInternationalPriceData.put(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c, listIPD);
                    } else {
                        listIPD = new list<APT_International_Price_Data__c>();
                        listIPD.add(ipd);
                        mapInternationalPriceData.put(r2tInternationalPricingProperties.APT_EMSDOCT_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c, listIPD);
                    }
                }
                //EMSMERCH
                else if(!String.isEmpty(ipd.APT_Product__c) && !String.isEmpty(APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT) && ipd.APT_Product__c.equalsIgnoreCase(APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT)  && !String.isEmpty(r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c)) {
                   list<APT_International_Price_Data__c> listIPD = mapInternationalPriceData.get(r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c);
                    if(listIPD != null && listIPD.size() > 0) {
                        listIPD.add(ipd);
                        mapInternationalPriceData.put(r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c, listIPD);
                    } else {
                        listIPD = new list<APT_International_Price_Data__c>();
                        listIPD.add(ipd);
                        mapInternationalPriceData.put(r2tInternationalPricingProperties.APT_EMSMERCH_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c, listIPD);
                    }
                }
                //EMSMER20
                else if(!String.isEmpty(ipd.APT_Product__c) && !String.isEmpty(APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT) && ipd.APT_Product__c.equalsIgnoreCase(APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT)  && r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c != null) {
                   list<APT_International_Price_Data__c> listIPD = mapInternationalPriceData.get(r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c);
                    if(listIPD != null && listIPD.size() > 0) {
                        listIPD.add(ipd);
                        mapInternationalPriceData.put(r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c, listIPD);
                    } else {
                        listIPD = new list<APT_International_Price_Data__c>();
                        listIPD.add(ipd);
                        mapInternationalPriceData.put(r2tInternationalPricingProperties.APT_EMSMER20_Charge_Type__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c, listIPD);
                    }
                }
                //AIRLET, AIRPTI and AIRRPI
                else {
                    list<APT_International_Price_Data__c> listIPD = mapInternationalPriceData.get(ipd.APT_Product__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c);
                    if(listIPD != null && listIPD.size() > 0) {
                        listIPD.add(ipd);
                        mapInternationalPriceData.put(ipd.APT_Product__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c, listIPD);
                    } else {
                        listIPD = new list<APT_International_Price_Data__c>();
                        listIPD.add(ipd);
                        mapInternationalPriceData.put(ipd.APT_Product__c + APT_Constants.SEPERATOR_SIMILARITY + ipd.APT_Band__c, listIPD);
                    }
                }                
            }
            
            //validate if any missing international product
            map<String, String> mapProduct = new map<String, String>();
            list<Product2> listProduct = [SELECT Id, Name, ProductCode FROM Product2 WHERE APT_International_Pricing__c = true];
            if(listProduct.size() > 0) {
                for(Product2 prod : listProduct) {
                    mapProduct.put(prod.ProductCode, prod.Id);
                    setProduct.add(prod.ProductCode);
                }
            } else {
                setErrorMessage .add(APT_Constants.NO_INTERNATION_PRODUCT_FOUND);
            }
            
            System.debug('setErrorMessage:'+setErrorMessage);
            if(setErrorMessage .size() == 0) {
                //delete existing price matrix entries
                //APT_PricingUtility.deletePriceMatrixEntries(mapProduct.values());
                
                //delete existing price matrix
                //APT_PricingUtility.deletePriceMatrix(mapProduct.values());
                
                //delete existing price list items
                //APT_PricingUtility.deletePriceListItems(mapProduct.values());
                
                //existing price list items
                map<String, Apttus_Config2__PriceListItem__c> mapExistingPLI = new map<String, Apttus_Config2__PriceListItem__c>();
                //list<Apttus_Config2__PriceListItem__c> listExistingPLI = new list<Apttus_Config2__PriceListItem__c>();
                set<Id> setPriceListItemId = new set<Id>();
                for(Apttus_Config2__PriceListItem__c pli : [SELECT Id, Name, Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode, APT_Band__c, 
                                                            APT_eParcel_Lodgment__c
                                                            FROM Apttus_Config2__PriceListItem__c
                                                            WHERE Apttus_Config2__ProductId__c IN : mapProduct.values()
                                                            AND APT_Band__c IN :setBand]) {
                    
                    String key = pli.Apttus_Config2__ProductId__r.ProductCode + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_Band__c + APT_Constants.SEPERATOR_SIMILARITY + pli.APT_eParcel_Lodgment__c;
                    system.debug('*** key ***'+key.toLowerCase());
                    mapExistingPLI.put(key.toLowerCase(), pli);
                    //listExistingPLI.add(pli);
                    setPriceListItemId.add(pli.Id);
                }
                                    system.debug('Enter here@@@@');
                                    system.debug('mapChargeType----->'+mapChargeType);

                //create price list items
                list<Apttus_Config2__PriceListItem__c> listPriceListItem = APT_PricingUtility.createPriceListItemForInternational(setProduct, setBand, seteParcelLodgment, defaultPriceListID, mapProduct, mapChargeType, mapExistingPLI);
                            
                if(listPriceListItem != null && listPriceListItem.size() > 0) {
                    system.debug('*** listPriceListItem > size ***'+listPriceListItem.size());
                    insert listPriceListItem;
                } 
                
                list<Apttus_Config2__PriceListItem__c> listAllPriceListItem = new list<Apttus_Config2__PriceListItem__c>();
                /*
                for(Apttus_Config2__PriceListItem__c pli : listExistingPLI) {
                    listAllPriceListItem.add(pli);
                    setPriceListItemId.add(pli.Id);
                }
                */
                listAllPriceListItem.addAll(listPriceListItem);
                setPriceListItemId.addAll((new Map<Id,Apttus_Config2__PriceListItem__c>(listPriceListItem)).keySet());
                /*
                for(Apttus_Config2__PriceListItem__c pli : listPriceListItem) {
                    listAllPriceListItem.add(pli);
                    setPriceListItemId.add(pli.Id);
                }
                */
                //existing price matrix 
                map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix = new map<String, Apttus_Config2__PriceMatrix__c>();
                set<Id> setPriceMatrixId = new set<Id>();
                for(Apttus_Config2__PriceMatrix__c pm : [SELECT Id, Apttus_Config2__PriceListItemId__c
                                                        FROM Apttus_Config2__PriceMatrix__c
                                                        WHERE Apttus_Config2__PriceListItemId__c IN :setPriceListItemId]) {
                    
                    setPriceMatrixId.add(pm.Id);
                    mapExistingPriceMatrix.put(pm.Apttus_Config2__PriceListItemId__c, pm);
                }
                
                /*
                //delete existing price matrix entry
                list<Apttus_Config2__PriceMatrixEntry__c> listExistingPME = [SELECT Id FROM Apttus_Config2__PriceMatrixEntry__c
                                                                            WHERE Apttus_Config2__PriceMatrixId__c IN :setPriceMatrixId];
                
                if(listExistingPME != null && listExistingPME.size() > 0) {
                    delete listExistingPME;
                }
                */
                
                
                //create price matrix
                list<Apttus_Config2__PriceMatrix__c> listPriceMatrix = APT_PricingUtility.createPriceMatrixForInternational(listAllPriceListItem, mapDimension, r2tInternationalPricingProperties, mapExistingPriceMatrix);
                if(listPriceMatrix != null && listPriceMatrix.size() > 0) {
                    system.debug('*** listPriceMatrix > size ***'+listPriceMatrix.size());
                    insert listPriceMatrix;
                }
                setPriceMatrixId.addAll((new Map<Id,Apttus_Config2__PriceMatrix__c>(listPriceMatrix)).keySet()); 
                /*
                for(Apttus_Config2__PriceMatrix__c pm : listPriceMatrix) {
                    setPriceMatrixId.add(pm.Id);                    
                }*/
                
                /*
                list<Apttus_Config2__PriceMatrix__c> listPM = [SELECT Id, Name, Apttus_Config2__PriceListItemId__c,
                                                            Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode,
                                                            Apttus_Config2__PriceListItemId__r.APT_Industry__c,
                                                            Apttus_Config2__PriceListItemId__r.APT_eParcel_Lodgment__c,
                                                            Apttus_Config2__PriceListItemId__r.APT_Band__c,
                                                            Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c
                                                            FROM Apttus_Config2__PriceMatrix__c
                                                            WHERE Id IN :setPriceMatrixId];
                
                //create price matrix entry records                 
                list<Apttus_Config2__PriceMatrixEntry__c> listPME = APT_PricingUtility.createPriceMatrixEntryForInternational(listPM, mapInternationalPriceData);
                if(listPME != null && listPME.size() > 0) {
                    insert listPME;
                }
                
                sendEmailAlert(emailAddresses, new set<String>(), true);
                */
                
                
                if(!test.isRunningTest()) {    //ignore while test class
                    APT_InternationalPricingBatch ipBatchController = new APT_InternationalPricingBatch(setPriceMatrixId, mapInternationalPriceData);
                    database.executeBatch(ipBatchController, 1);
                }
                
            } else {
                if(setErrorMessage.size() > 0 && !String.isEmpty(emailAddresses) /*emailAddresses != null && emailAddresses != ''*/) {
                    sendEmailAlert(emailAddresses, setErrorMessage, false);
                }
            }      
        } catch(System.Exception ex) {
            setErrorMessage .add(ex.getMessage());            
            if(!String.isEmpty(emailAddresses)) {//if(emailAddresses != null && emailAddresses != '') {
                sendEmailAlert(emailAddresses, setErrorMessage, false);
            }
        }
    }
    
    /**
        This method will send email alert.
        @params -
        emailAddresses - comma separated email addresses
        setErrorMessage - list of error messages
     */
    @TestVisible 
    private static void sendEmailAlert(String emailAddresses, set<String> setErrorMessage, Boolean bIsSuccess) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        list<String> toAddresses = emailAddresses.split(APT_Constants.SEPERATOR_COMMA);
        mail.setToAddresses(toAddresses);
        mail.setSubject(APT_Constants.INTERNATIONAL_PRICING_BATCH_STATUS);
        
        //Handle Batch Error Message
        if(bIsSuccess) {
            mail.setPlainTextBody(APT_Constants.JOB_COMPLETED_SUCCESSFULLY);                
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } else {
            String errorMessage;
            for(String em : setErrorMessage ) {
                if(!String.isEmpty(errorMessage)) {
                    errorMessage += APT_Constants.SEPERATOR_NEW_LINE + em;
                } else {
                    errorMessage = em;
                }
            }
            
            mail.setPlainTextBody(APT_Constants.JOB_PROCESSED_WITH + setErrorMessage .size() + APT_Constants.FAILURES_ERRORS + errorMessage);                
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
    
    /**
        This method will send email alert.
        @params -
        emailAddresses - comma separated email addresses
        setErrorMessage - list of error messages
     */
     
     /*
    public static void sendEmailAlert(String emailAddresses, set<String> setErrorMessage) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        list<String> toAddresses = emailAddresses.split(',');
        mail.setToAddresses(toAddresses);
        mail.setSubject('*** International Pricing Batch Status ***');
        
        //Handle Batch Error Message        
        String errorMessage;
        for(String em : setErrorMessage ) {
            if(errorMessage != null) {
                errorMessage += '\n' + em;
            } else {
                errorMessage = em;
            }
        }
        
        mail.setPlainTextBody('The job processed with '+ setErrorMessage .size() + ' failures. \n\n Error(s) : \n ' + errorMessage);                
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });       
    }
    */
}