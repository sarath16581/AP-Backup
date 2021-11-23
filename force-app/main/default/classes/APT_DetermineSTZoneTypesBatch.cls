/**
Description: This batch job will create zone types in domestic data for star track products
Created By - Mahesh Patel
Created Date - 20th Oct, 2020
Last Modified By -
Last Modified Date - 
**/
global class APT_DetermineSTZoneTypesBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global set<String> setErrorMessage {get;set;} 
    global List<APT_Post_Code_Mapping__c> listPostCodeMapping;

    public APT_DetermineSTZoneTypesBatch(List<APT_Post_Code_Mapping__c> listPostCodeMapping) {
        setErrorMessage = new set<String>();
        this.listPostCodeMapping = listPostCodeMapping;
    }

    /**
        Start
    **/ 
    //start() Method to pass eligible post code mappings
    global Database.QueryLocator start(Database.BatchableContext bc) {      
        Set<string> setSinglePLIProducts = APT_Utils.getSinglePLINetworkTypes();
        
        If(Test.isRunningTest()){  
            return Database.getQueryLocator([SELECT Id, Name, ProductCode, APT_Category__c, APT_Network_Type__c, APT_Product_type__c FROM Product2 
                                            WHERE APT_Domestic_Pricing__c = true AND APT_Product_type__c = :APT_Constants.PRODUCTTYPE_STARTRACK LIMIT 1]);
        }
        else{
            return Database.getQueryLocator([SELECT Id, Name, ProductCode, APT_Category__c, APT_Network_Type__c, APT_Product_type__c FROM Product2 
                                            WHERE APT_Domestic_Pricing__c = true AND APT_Product_type__c = :APT_Constants.PRODUCTTYPE_STARTRACK
                                            AND APT_Network_Type__c NOT IN :setSinglePLIProducts]);
        }
    } 

    /**
        execute
    **/    
    global void execute(Database.BatchableContext bc, List<Product2> stProducts){
        try 
        { 
            determineZoneTypesForStarTrack(stProducts);
        } 
        catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage());
            system.debug('APT_DetermineSTZoneTypesBatch Exception: ' + ex.getMessage());
        }
    }

    /**
        determine Zone Types For StarTrack products to be used in pricing
    **/    
    @TestVisible 
    private void determineZoneTypesForStarTrack(List<Product2> stProducts){
        try 
        { 
            //STP-2955 Modify Existing Batch to Create PLI, PM and PME for Express Road - STE Product
            system.debug('execute scope: '+ stProducts);

            if(stProducts != null && stProducts.size() > 0) 
            {
                set<String> setCategory = new set<String>();
                set<String> setNetworkType = new set<String>();

                //Get DISTINCT Direct, Onforwarding, OnforwardingAlternate Zones from Post Code Mapping
                List<AggregateResult> agrPostCodeMapping = [SELECT APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c 
                                                            FROM APT_Post_Code_Mapping__c    
                                                            GROUP BY APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c
                                                            ORDER BY APT_Direct_Zone__c NULLS LAST];

                //Get category and network types
                for(Product2 product : stProducts) 
                {
                    system.debug('product.APT_Network_Type__ce: '+ product.APT_Network_Type__c);
                    system.debug('product.APT_Category__c: '+ product.APT_Category__c);
                    setCategory.add(product.APT_Category__c);
                    setNetworkType.add(product.APT_Network_Type__c);

                    //for LOC, LO2 and LOT network type
                    if(product.APT_Network_Type__c == 'EXP')
                    {
                        setNetworkType.add('LOC');
                    }
                    else if(product.APT_Network_Type__c == 'RE2')
                    {
                        setNetworkType.add('LO2');
                    }
                    else if(product.APT_Network_Type__c == 'RET')
                    {
                        setNetworkType.add('LOT');
                    }
                }

                //Get DISTINCT Lodgement Zones from Domestic Price Data
                List<AggregateResult> agrDomesticPriceData = [SELECT APT_Lodgement_Zone_Code__c       
                                                                FROM APT_Domestic_Price_Data__c
                                                                WHERE RecordType.Name = :APT_Constants.RECORDTYPE_STARTRACK 
                                                                AND APT_Category__c IN :setCategory
                                                                AND APT_Network_Type__c IN :setNetworkType
                                                                GROUP BY APT_Lodgement_Zone_Code__c];

                if(agrDomesticPriceData != null && !agrDomesticPriceData.IsEmpty())
                {
                    //Find whether given lodgement zone is Direct or Onforwarding or OnforwardingAlternate
                    map<String, String> mapPostCodeMappings = new map<String, String>();
                    string directZone;
                    string onforwardingZone;
                    string onforwardingAltZone;
                    string lodgementZone;
                    
                    for(AggregateResult domesticPriceData : agrDomesticPriceData)
                    {
                        lodgementZone = String.valueOf(domesticPriceData.get(APT_Constants.ST_LODGEMENT_ZONE_API));

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
                        }
                    }
                    for(AggregateResult domesticPriceData : agrDomesticPriceData)
                    {
                        lodgementZone = String.valueOf(domesticPriceData.get(APT_Constants.ST_LODGEMENT_ZONE_API));

                        for(AggregateResult postCodeMapping : agrPostCodeMapping)
                        {
                            directZone = String.valueOf(postCodeMapping.get(APT_Constants.ST_DIRECT_ZONE_API));
                            onforwardingZone = String.valueOf(postCodeMapping.get(APT_Constants.ST_ONFORWARDING_ZONE_API));
                            onforwardingAltZone = String.valueOf(postCodeMapping.get(APT_Constants.ST_ONFORWARDING_ALTERNATE_ZONE_API));

                            //If lodgement zone is found in onforwarding zone and onforwarding alternate zone is same or blank, then its onforwarding zone
                            if(onforwardingZone == lodgementZone && (onforwardingAltZone == null || onforwardingZone == onforwardingAltZone))
                            {
                                if(mapPostCodeMappings.get(directZone + APT_Constants.ADD_HYPHEN + onforwardingZone + APT_Constants.ADD_HYPHEN + onforwardingAltZone) == null)
                                {
                                    mapPostCodeMappings.put(directZone + APT_Constants.ADD_HYPHEN + onforwardingZone + APT_Constants.ADD_HYPHEN + onforwardingAltZone, APT_Constants.ZONE_TYPE_ONFORWARDING  + APT_Constants.ADD_HYPHEN + onforwardingZone);
                                }
                            }
                        }
                    }
                    for(AggregateResult domesticPriceData : agrDomesticPriceData)
                    {
                        lodgementZone = String.valueOf(domesticPriceData.get(APT_Constants.ST_LODGEMENT_ZONE_API));

                        for(AggregateResult postCodeMapping : agrPostCodeMapping)
                        {
                            directZone = String.valueOf(postCodeMapping.get(APT_Constants.ST_DIRECT_ZONE_API));
                            onforwardingZone = String.valueOf(postCodeMapping.get(APT_Constants.ST_ONFORWARDING_ZONE_API));
                            onforwardingAltZone = String.valueOf(postCodeMapping.get(APT_Constants.ST_ONFORWARDING_ALTERNATE_ZONE_API));

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

                    for(string mapKey: mapPostCodeMappings.keySet())
                    {
                        system.debug('mapPostCodeMapping Key: ' + mapKey);
                        system.debug('mapPostCodeMapping: ' + mapPostCodeMappings.get(mapKey));
                    }
                }
            }
        } 
        catch(System.Exception ex) {
            system.debug('APT_DetermineSTZoneTypesBatch determineZoneTypesForStarTrack Exception: ' + ex.getMessage());
            throw ex;
        }
    }

    /**
        send notification email
    **/    
    public void sendEmailNotification(AsyncApexJob asyncApexJob, set<String> setErrorMessage) {
        
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
        toAddresses.add(asyncApexJob.CreatedBy.Email);
        
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
            mail.setPlainTextBody(APT_Constants.DETERMINE_ST_ZONE_TYPES_PROCESSED + asyncApexJob.TotalJobItems + APT_Constants.BATCHES_WITH + iErrorCount + APT_Constants.FAILURES_ERRORS + errorMessage);
        } 
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    /**
        finish
    **/    
    global void finish(Database.BatchableContext bc) {
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob asyncApexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus 
                        FROM AsyncApexJob 
                        WHERE Id = :bc.getJobId()];

        system.debug('No. of errors: ' + asyncApexJob.NumberOfErrors);
                        
        if(asyncApexJob.NumberOfErrors > 0) {
            setErrorMessage.add(asyncApexJob.ExtendedStatus);
        }
        
        if(setErrorMessage.size() > 0) {
        
            this.sendEmailNotification(asyncApexJob, setErrorMessage);
            
        } else {
            system.debug('Call Update Batches');

            //Update Post Code Mappings
            APT_PostCodeZoneTypesBatch postCodeZoneTypesBatch = new APT_PostCodeZoneTypesBatch(listPostCodeMapping);
            database.executeBatch(postCodeZoneTypesBatch, 10000);
        }
    }
}