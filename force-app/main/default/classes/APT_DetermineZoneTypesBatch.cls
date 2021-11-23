/***
 * @author Mahesh Patel
 * @date 2021-05-01
 * @group 
 * @description Apex batch job will determine and create zone types in pricing data for star track products
 * Subsequent batches are chained to this batch job and varies between ST and other product types.
 * @changelog
 * 2021-05-01 - Mahesh Patel - Created
*/
global class APT_DetermineZoneTypesBatch implements Database.Batchable<sObject>, Database.Stateful 
{    
    global Set<String> setErrorMessage {get;set;} 
    global List<APT_Post_Code_Mapping__c> listPostCodeMapping;
    @TestVisible static Map<String, String> lodgementZonesWithTypeMap;
    global Map<String, String> lodgementZonesWithType;
    global String productType {get;set;} 
    global Set<String> setProducts {get;set;}
    public static final String CLASSNAME = 'APT_DetermineZoneTypesBatch';
    public static final String ORGID = UserInfo.getOrganizationId();     

    //Constructor
    public APT_DetermineZoneTypesBatch(List<APT_Post_Code_Mapping__c> listPostCodeMapping, String productType) 
    {
        setErrorMessage = new set<String>();
        this.listPostCodeMapping = listPostCodeMapping;
        this.productType = productType;
        lodgementZonesWithType = new Map<String, String>();
        setProducts = new Set<String>();
    }

    /**
        Start Method
    **/ 
    global List<Product2> start(Database.BatchableContext bc) 
    {      
        Set<string> setSinglePLIProducts = APT_Utils.getSinglePLINetworkTypes();

        String queryStr = 'SELECT Id, Name, ProductCode, APT_Category__c, APT_Network_Type__c, APT_Product_type__c FROM Product2 ' + 
                          'WHERE APT_Network_Type__c NOT IN :setSinglePLIProducts';
        
        if(productType == 'Startrack')
        {
            string stProductType = APT_Constants.PRODUCTTYPE_STARTRACK;
            queryStr += ' AND APT_Domestic_Pricing__c = true AND APT_Product_type__c =: stProductType';
        }
        else
        {
            return null;
        }
        
        return Database.query(queryStr);
    } 

    /**
        Execute Method
    **/    
    global void execute(Database.BatchableContext bc, List<Product2> stProducts)
    {
        try 
        { 
            determineZoneTypesForStarTrack(stProducts);
        } 
        catch(System.Exception ex) 
        {
            setErrorMessage.add(ex.getMessage() + ex.getStackTraceString());   
            system.debug('APT_DetermineZoneTypesBatch Exception: ' + ex.getMessage() + ex.getStackTraceString());
            UTIL_LoggingService.logHandledException(ex, ORGID, 'Apttus Pricing Batch Job', CLASSNAME, 'execute', null, LoggingLevel.ERROR);
        }
    }

    /**
        Determine Zone Types For StarTrack products to be used in pricing
    **/    
    private void determineZoneTypesForStarTrack(List<Product2> stProducts)
    {
        try 
        { 
            //STP-2955 Modify Existing Batch to Create PLI, PM and PME for Express Road - STE Product
            system.debug('execute scope: '+ stProducts);

            if(stProducts != null && stProducts.size() > 0) 
            {
                //Create set of product ids
                setProducts = new Set<String>();
                Set<String> setNetworkType = new Set<String>();
                List<AggregateResult> agrDomesticPriceData;
            
                for(Product2 product : stProducts) 
                {
                    setProducts.add(product.Id);
                    setNetworkType.add(product.APT_Network_Type__c);
                }

                List<APT_Pricing_Data_Mapping__c> pricingDataMappings = [SELECT APT_Pricing_Value_Name_1__c, APT_Pricing_Value_Name_2__c, APT_Pricing_Value_Name_3__c,          
                                                                        APT_Pricing_Value_Name_4__c, APT_Pricing_Value_Name_5__c, APT_Pricing_Value_Name_6__c, APT_Pricing_Value_Name_7__c, 
                                                                        APT_Pricing_Value_Name_8__c, APT_Pricing_Value_Name_9__c, APT_Pricing_Value_Name_10__c, APT_Pricing_Value_Name_11__c, 
                                                                        APT_Pricing_Value_Name_12__c 
                                                                        FROM APT_Pricing_Data_Mapping__c 
                                                                        WHERE APT_Product__c IN :setProducts LIMIT 1];

                String lodgementZoneCodeField = APT_PricingBatchUtility.getPricingDataFieldAPI(pricingDataMappings, 'Pickup Zone Code');

                if(lodgementZoneCodeField != null)
                {
                    //Get DISTINCT Lodgement Zones APT_Lodgement_Zone_Code__c from Pricing Data
                    String aggrQuery = 'SELECT ' + lodgementZoneCodeField + ' FROM APT_Pricing_Data__c WHERE APT_Product__c IN :setProducts GROUP BY ' + lodgementZoneCodeField;
                    agrDomesticPriceData = Database.Query(aggrQuery);
                }

                if(agrDomesticPriceData != null && !agrDomesticPriceData.IsEmpty())
                {
                    //Find whether given lodgement zone is Direct or Onforwarding or OnforwardingAlternate
                    map<String, String> mapPostCodeMappings = new map<String, String>();
                    string directZone;
                    string onforwardingZone;
                    string onforwardingAltZone;
                    string lodgementZone;

                    //Get DISTINCT Direct, Onforwarding, OnforwardingAlternate Zones from Post Code Mapping
                    List<AggregateResult> agrPostCodeMapping = [SELECT APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c 
                                                                FROM APT_Post_Code_Mapping__c    
                                                                GROUP BY APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c
                                                                ORDER BY APT_Direct_Zone__c NULLS LAST];                    
                        
                    for(AggregateResult domesticPriceData : agrDomesticPriceData)
                    {
                        lodgementZone = String.valueOf(domesticPriceData.get(lodgementZoneCodeField));

                        for(AggregateResult postCodeMapping : agrPostCodeMapping)
                        {
                            directZone = String.valueOf(postCodeMapping.get(APT_Constants.ST_DIRECT_ZONE_API));
                            onforwardingZone = String.valueOf(postCodeMapping.get(APT_Constants.ST_ONFORWARDING_ZONE_API));
                            onforwardingAltZone = String.valueOf(postCodeMapping.get(APT_Constants.ST_ONFORWARDING_ALTERNATE_ZONE_API));

                            //If lodgement zone is found in direct zone, then its direct zone
                            if(directZone == lodgementZone)
                            {
                                mapPostCodeMappings.put(directZone + APT_Constants.ADD_HYPHEN + onforwardingZone + APT_Constants.ADD_HYPHEN + onforwardingAltZone, APT_Constants.ZONE_TYPE_DIRECT  + APT_Constants.ADD_HYPHEN + directZone);
                            }
                            //If lodgement zone is found in onforwarding zone and onforwarding alternate zone is same or blank, then its onforwarding zone
                            if(onforwardingZone == lodgementZone && (onforwardingAltZone == null || onforwardingZone == onforwardingAltZone))
                            {
                                if(mapPostCodeMappings.get(directZone + APT_Constants.ADD_HYPHEN + onforwardingZone + APT_Constants.ADD_HYPHEN + onforwardingAltZone) == null)
                                {
                                    mapPostCodeMappings.put(directZone + APT_Constants.ADD_HYPHEN + onforwardingZone + APT_Constants.ADD_HYPHEN + onforwardingAltZone, APT_Constants.ZONE_TYPE_ONFORWARDING  + APT_Constants.ADD_HYPHEN + onforwardingZone);
                                }
                            }
                            //If lodgement zone is found in onforwarding zone and onforwarding alternate zone is not same, then its onforwarding alternate zone
                            if(onforwardingZone == lodgementZone && (onforwardingAltZone != null && onforwardingZone != onforwardingAltZone))
                            {
                                string onforwardingAlternateZone = onforwardingZone + APT_Constants.ADD_TILDE + onforwardingAltZone;

                                if(mapPostCodeMappings.get(directZone + APT_Constants.ADD_HYPHEN + onforwardingZone + APT_Constants.ADD_HYPHEN + onforwardingAltZone) == null)
                                {
                                    mapPostCodeMappings.put(directZone + APT_Constants.ADD_HYPHEN + onforwardingZone + APT_Constants.ADD_HYPHEN + onforwardingAltZone, APT_Constants.ZONE_TYPE_ONFORWARDING_ALTERNATE  + APT_Constants.ADD_HYPHEN + onforwardingAlternateZone);
                                }
                            }                                                        
                        }
                    }
                    if(mapPostCodeMappings != null && !mapPostCodeMappings.IsEmpty())
                    {
                        for(APT_Post_Code_Mapping__c postCodeMapping: listPostCodeMapping)
                        {
                            System.debug('Key::'+postCodeMapping.APT_Direct_Zone__c + APT_Constants.ADD_HYPHEN + postCodeMapping.APT_Onforwarding_Zone__c + APT_Constants.ADD_HYPHEN + postCodeMapping.APT_Onforwarding_Alternate_Zone__c);
                            string postCodeZoneType = mapPostCodeMappings.get(postCodeMapping.APT_Direct_Zone__c + APT_Constants.ADD_HYPHEN + postCodeMapping.APT_Onforwarding_Zone__c + APT_Constants.ADD_HYPHEN + postCodeMapping.APT_Onforwarding_Alternate_Zone__c);
    
                            //assign zone type to all network types
                            if(postCodeZoneType != null)
                            {
                                if(setNetworkType.contains('EXP'))
                                {
                                    postCodeMapping.APT_EXP_Zone_Type__c = postCodeZoneType;
                                }
                                else if(setNetworkType.contains('PRM'))
                                {
                                    postCodeMapping.APT_PRM_Zone_Type__c = postCodeZoneType;
                                }
                                else if(setNetworkType.contains('NXF'))
                                {
                                    postCodeMapping.APT_NXF_Zone_Type__c = postCodeZoneType;
                                }
                                else if(setNetworkType.contains('SE2'))
                                {
                                    postCodeMapping.APT_SE2_Zone_Type__c = postCodeZoneType;
                                }
                                else if(setNetworkType.contains('SE3'))
                                {
                                    postCodeMapping.APT_SE3_Zone_Type__c = postCodeZoneType;
                                }
                                else if(setNetworkType.contains('RET'))
                                {
                                    postCodeMapping.APT_RET_Zone_Type__c = postCodeZoneType;
                                }
                                else if(setNetworkType.contains('RE2'))
                                {
                                    postCodeMapping.APT_RE2_Zone_Type__c = postCodeZoneType;
                                }
                            }
                        }
                    }

                    //Find whether given lodgement zone is Direct or Onforwarding or OnforwardingAlternate
                    //Update Pricing Data
                    for(AggregateResult domesticPriceData : agrDomesticPriceData)
                    {
                        APT_ZoneTypeModel zoneType = new APT_ZoneTypeModel();
                        lodgementZone = String.valueOf(domesticPriceData.get(lodgementZoneCodeField));
						System.debug('zoneType::'+zoneType);
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
                            lodgementZonesWithType.put(lodgementZone, JSON.serialize(zoneType));
                        }
                    }

                }
            }
        } 
        catch(System.Exception ex) 
        {
            system.debug('APT_DetermineZoneTypesBatch determineZoneTypesForStarTrack Exception: ' + ex.getMessage());
            throw ex;
        }
    }

    /**
        Finish Method
    **/    
    global void finish(Database.BatchableContext bc) 
    {

        //Using the Static variable to assert the results in the test class.
        lodgementZonesWithTypeMap = lodgementZonesWithType;
        //Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob asyncApexJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems, CreatedBy.Email 
                                    FROM AsyncApexJob 
                                    WHERE Id = :bc.getJobId()];

        system.debug('No. of errors: ' + asyncApexJob.NumberOfErrors);
                        
        if(asyncApexJob.NumberOfErrors > 0) 
        {
            setErrorMessage.add(asyncApexJob.ExtendedStatus);
        }
        
        if(setErrorMessage.size() > 0) 
        {
            APT_PricingBatchUtility.sendEmailNotification(APT_Constants.DETERMINE_ST_ZONE_TYPES_PROCESSED, asyncApexJob, setErrorMessage, null);
        } 
        else 
        {
            //Update Post Code Mappings
            if(!Test.isRunningTest()){
            	APT_UpdatePostCodeMappingBatch updatePostCodeMappingBatch = new APT_UpdatePostCodeMappingBatch(listPostCodeMapping, lodgementZonesWithType, setProducts, productType);
            	database.executeBatch(updatePostCodeMappingBatch, 10000);
            }
        }
    }
}