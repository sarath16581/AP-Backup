/**
Description: This batch job will create domestic pricing - Price Matrix Entry records
Created By - Mausam Padhiyar
Created Date - 7th Oct, 2015
Last Modified By - Mahesh Patel
Last Modified Date - 20th Oct, 2020
Change Description - Added startrack product's PME creation logic 
**/
global class APT_DomesticPricingPMEBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global set<String> setErrorMessage {get;set;} 

    /**
        constructor
    **/    
    global APT_DomesticPricingPMEBatch() {
        setErrorMessage = new set<String>();
    }
    
    /**
        Start
    **/    
    global Database.QueryLocator start(Database.BatchableContext bc) {        
        set<Id> setProductId = new set<Id>();

        for(Product2 product : [SELECT Id, Name, APT_Category__c, APT_Network_Type__c FROM Product2 
                                WHERE APT_Domestic_Pricing__c = true]) {
             
            setProductId.add(product.Id);                               
        }
        
        //start
        If(Test.isRunningTest()){ 
            return Database.getQueryLocator([SELECT Id,
                                                Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Category__c,
                                                Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c,
                                                Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c,
                                                Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c,
                                                Apttus_Config2__PriceListItemId__r.APT_Lodgement_Zone_Code__c,
                                                Apttus_Config2__PriceListItemId__r.APT_Price_Structure__c,
                                                Apttus_Config2__PriceListItemId__r.APT_Zone_Type__c,
                                                Apttus_Config2__PriceListItemId__r.APT_Zones__c
                                                FROM Apttus_Config2__PriceMatrix__c
                                                WHERE Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c IN :setProductId LIMIT 1]);
        }
        else{
            return Database.getQueryLocator([SELECT Id,
                                        Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Category__c,
                                        Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c,
                                        Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c,
                                        Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c,
                                        Apttus_Config2__PriceListItemId__r.APT_Lodgement_Zone_Code__c,
                                        Apttus_Config2__PriceListItemId__r.APT_Price_Structure__c,
                                        Apttus_Config2__PriceListItemId__r.APT_Zone_Type__c,
                                        Apttus_Config2__PriceListItemId__r.APT_Zones__c
                                        FROM Apttus_Config2__PriceMatrix__c
                                        WHERE Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c IN :setProductId]);
        }
    }
    
    /**
        execute
    **/    
    global void execute(Database.BatchableContext bc, List<Apttus_Config2__PriceMatrix__c> scope){
        try 
        { 
            //STP-2955 Modify Existing Batch to Create PLI, PM and PME for Express Road - STE Product
            List<Apttus_Config2__PriceMatrix__c> listDomesticPM = new List<Apttus_Config2__PriceMatrix__c>();
            List<Apttus_Config2__PriceMatrix__c> listSTPriceMatrix = new List<Apttus_Config2__PriceMatrix__c>();
            List<Apttus_Config2__PriceMatrix__c> listSTSinglePriceMatrix = new List<Apttus_Config2__PriceMatrix__c>();
            Set<string> setSinglePLIProducts = APT_Utils.getSinglePLINetworkTypes();

            //create separate collections for domestic and startrack price matrix
            if(scope != null && scope.size() > 0) 
            {
                for(Apttus_Config2__PriceMatrix__c priceMatrix : scope) 
                {
                    string networkType = priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c;

                    if(priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c == APT_Constants.PRODUCTTYPE_STARTRACK && (setSinglePLIProducts != null && !setSinglePLIProducts.contains(networkType)))
                    {
                        listSTPriceMatrix.add(priceMatrix);
                    }
                    else if(priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c == APT_Constants.PRODUCTTYPE_STARTRACK && (setSinglePLIProducts != null && setSinglePLIProducts.contains(networkType)))
                    {
                        listSTSinglePriceMatrix.add(priceMatrix);
                    }
                    else if(priceMatrix.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c != APT_Constants.PRODUCTTYPE_STARTRACK)
                    {
                        listDomesticPM.add(priceMatrix);
                    }
                }  
            }

            this.createDomesticPME(listDomesticPM);

            //STP-2955 Modify Existing Batch to Create PLI, PM and PME for Express Road - STE Product
            if(listSTPriceMatrix != null && !listSTPriceMatrix.isEmpty())
            {
                this.createStarTrackPME(listSTPriceMatrix);
            }

            if(listSTSinglePriceMatrix != null && !listSTSinglePriceMatrix.isEmpty())
            {
                this.createStarTrackSinglePLIPME(listSTSinglePriceMatrix);                
            }
        } 
        catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage());          
            system.debug('PME Exception: ' + ex.getMessage());
        }
    }

    /**
        create Domestic PME
        @params -
        listDomesticPM - list of domestic price matrix
    **/    
    private void createDomesticPME(List<Apttus_Config2__PriceMatrix__c> listDomesticPM){
        try 
        { 
            map<String, list<APT_Domestic_Price_Data__c>> mapDomesticPriceData = new map<String, list<APT_Domestic_Price_Data__c>>();
            set<String> setNetworkType = new set<String>();
            set<String> setCategory = new set<String>();
            set<String> setLodgementZone = new set<String>();
            set<String> setPricingStructure = new set<String>();
            
            for(Apttus_Config2__PriceMatrix__c pm : listDomesticPM) {
                setCategory.add(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Category__c);
                setNetworkType.add(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c);
                setLodgementZone.add(pm.Apttus_Config2__PriceListItemId__r.APT_Lodgement_Zone_Code__c);
                setPricingStructure.add(pm.Apttus_Config2__PriceListItemId__r.APT_Price_Structure__c);
            }
            
            for(APT_Domestic_Price_Data__c dpd : [SELECT Id, Name, APT_Category__c, APT_Price_Structure__c,
                                                    APT_Network_Type__c, APT_Destination_Zone__c, APT_Destination_Zone_Code__c,
                                                    APT_Lodgement_Zone_Code__c, APT_Base_Rate__c, APT_Per_Kg_Rate__c, 
                                                    APT_Subsequent_Rate__c, APT_Weight_Range_Code__c, 
                                                    APT_Weight_Range_Code_Description__c              
                                                    FROM APT_Domestic_Price_Data__c
                                                    WHERE RecordType.Name = :APT_Constants.RECORDTYPE_AUSPOST
                                                    AND APT_Category__c IN : setCategory
                                                    AND APT_Network_Type__c IN : setNetworkType
                                                    AND APT_Lodgement_Zone_Code__c IN : setLodgementZone
                                                    AND APT_Price_Structure__c IN :setPricingStructure
                                                    ORDER BY APT_Destination_Zone_List_Order__c, APT_Weight_Range_Code__c asc]) {   //APOST-996
                
                list<APT_Domestic_Price_Data__c> listDPD = mapDomesticPriceData.get(dpd.APT_Category__c + APT_Constants.SEPERATOR_SIMILARITY 
                                                                                    + dpd.APT_Network_Type__c + APT_Constants.SEPERATOR_SIMILARITY
                                                                                    + dpd.APT_Lodgement_Zone_Code__c + APT_Constants.SEPERATOR_SIMILARITY
                                                                                    + dpd.APT_Price_Structure__c);
                if(listDPD != null && listDPD.size() > 0) {
                    listDPD.add(dpd);
                    mapDomesticPriceData.put(dpd.APT_Category__c + APT_Constants.SEPERATOR_SIMILARITY + dpd.APT_Network_Type__c + APT_Constants.SEPERATOR_SIMILARITY + dpd.APT_Lodgement_Zone_Code__c + APT_Constants.SEPERATOR_SIMILARITY + dpd.APT_Price_Structure__c, listDPD);
                } else {
                    listDPD = new list<APT_Domestic_Price_Data__c>();
                    listDPD.add(dpd);
                    mapDomesticPriceData.put(dpd.APT_Category__c + APT_Constants.SEPERATOR_SIMILARITY + dpd.APT_Network_Type__c + APT_Constants.SEPERATOR_SIMILARITY + dpd.APT_Lodgement_Zone_Code__c + APT_Constants.SEPERATOR_SIMILARITY + dpd.APT_Price_Structure__c, listDPD);
                }
            }
            
            //create price matrix entry records
            list<Apttus_Config2__PriceMatrixEntry__c> listPME = APT_PricingUtility.createPriceMatrixEntryForDomestic(listDomesticPM, mapDomesticPriceData);
            if(listPME != null && listPME.size() > 0) {
                insert listPME;
            }           
        } catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage());          
        }
    }

    /**
     * STP-2955 Modify Existing Batch to Create PLI, PM and PME for Express Road - STE Product
     * create price matrix entry for startrack products
     * @params -
        listSTPriceMatrix - list of startrack products
    **/    
    private void createStarTrackPME(List<Apttus_Config2__PriceMatrix__c> listSTPriceMatrix)
    {
        try 
        { 
            map<String, List<APT_Domestic_Price_Data__c>> mapDomesticPriceData = new map<String, List<APT_Domestic_Price_Data__c>>();

            set<String> setCategory = new set<String>();
            set<String> setNetworkType = new set<String>();

            //get category and network types
            for(Apttus_Config2__PriceMatrix__c pm : listSTPriceMatrix) 
            {
                setCategory.add(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Category__c);
                setNetworkType.add(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c);

                //for LOC, LO2 and LOT network type
                if(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c == 'EXP')
                {
                    setNetworkType.add('LOC');
                }
                else if(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c == 'RE2')
                {
                    setNetworkType.add('LO2');
                }
                else if(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c == 'RET')
                {
                    setNetworkType.add('LOT');
                }
            }

            //Get all domestic price data for startrack record type and given category, network types
            List<APT_Domestic_Price_Data__c> stDomesticePriceData = [SELECT Id, Name, APT_Category__c, APT_Network_Type__c, APT_Destination_Zone_Code__c,
                                                                APT_Lodgement_Zone_Code__c, APT_Per_Kg_Rate__c, APT_Subsequent_Rate__c, 
                                                                APT_Base_Rate__c, APT_Outbound_Inbound__c, APT_Zone_Type__c              
                                                                FROM APT_Domestic_Price_Data__c
                                                                WHERE RecordType.Name = :APT_Constants.RECORDTYPE_STARTRACK 
                                                                AND APT_Category__c IN :setCategory
                                                                AND APT_Network_Type__c IN :setNetworkType
                                                                AND APT_Zone_Type__c != null
                                                                ORDER BY APT_Outbound_Inbound__c DESC];

            for(APT_Domestic_Price_Data__c domesticPriceData : stDomesticePriceData) 
            {   
                //for LOC, LO2 and LOT network type
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

                string outboundKey = domesticPriceData.APT_Category__c + APT_Constants.SEPERATOR_SIMILARITY + 
                                     domesticPriceData.APT_Network_Type__c + APT_Constants.SEPERATOR_SIMILARITY + 
                                     domesticPriceData.APT_Lodgement_Zone_Code__c;

                List<APT_Domestic_Price_Data__c> listDomPriceData = mapDomesticPriceData.get(outboundKey);

                //prepare collection of domestic data for pricing key
                if(listDomPriceData != null && listDomPriceData.size() > 0) 
                {
                    listDomPriceData.add(domesticPriceData);
                    mapDomesticPriceData.put(outboundKey, listDomPriceData);
                } 
                else 
                {
                    listDomPriceData = new List<APT_Domestic_Price_Data__c>();
                    listDomPriceData.add(domesticPriceData);
                    mapDomesticPriceData.put(outboundKey, listDomPriceData);
                }

                if(domesticPriceData.APT_Outbound_Inbound__c == APT_Constants.INBOUND) 
                {
                    string inboundKey = domesticPriceData.APT_Category__c + APT_Constants.SEPERATOR_SIMILARITY 
                                        + domesticPriceData.APT_Network_Type__c + APT_Constants.SEPERATOR_SIMILARITY
                                        + domesticPriceData.APT_Destination_Zone_Code__c;

                    //add inbound domestic data to the same collection with destination zone
                    List<APT_Domestic_Price_Data__c> listDomPriceInboundData = mapDomesticPriceData.get(inboundKey);

                    if(listDomPriceInboundData != null && listDomPriceInboundData.size() > 0) 
                    {
                        listDomPriceInboundData.add(domesticPriceData);
                        mapDomesticPriceData.put(inboundKey, listDomPriceInboundData);
                    } 
                    else 
                    {
                        listDomPriceInboundData = new List<APT_Domestic_Price_Data__c>();
                        listDomPriceInboundData.add(domesticPriceData);
                        mapDomesticPriceData.put(inboundKey, listDomPriceInboundData);
                    }
                }
            }
            
            //create price matrix entry records
            List<Apttus_Config2__PriceMatrixEntry__c> listPriceMatrixEntry = APT_PricingUtility.createPriceMatrixEntryForSTE(listSTPriceMatrix, mapDomesticPriceData);
            system.debug('createStarTrackPME listPriceMatrixEntry: ' + listPriceMatrixEntry);

            //create price matrix entries
            if(listPriceMatrixEntry != null && listPriceMatrixEntry.size() > 0) 
            {
                insert listPriceMatrixEntry;
            }           
        } 
        catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage() + ex.getStackTraceString());          
            system.debug('createStarTrackPME Exception: ' + ex.getMessage() + ex.getStackTraceString().substringBefore('\n'));
        }
    }

    /**
     * STP-2955 Modify Existing Batch to Create PLI, PM and PME for Express Road - STE Product
     * create price matrix entry for startrack products
     * @params -
        listSTPriceMatrix - list of startrack products
    **/    
    private void createStarTrackSinglePLIPME(List<Apttus_Config2__PriceMatrix__c> listSTPriceMatrix)
    {
        try 
        { 
            map<String, List<APT_Domestic_Price_Data__c>> mapDomesticPriceData = new map<String, List<APT_Domestic_Price_Data__c>>();

            set<String> setCategory = new set<String>();
            set<String> setNetworkType = new set<String>();

            //get category and network types
            for(Apttus_Config2__PriceMatrix__c pm : listSTPriceMatrix) 
            {
                setCategory.add(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Category__c);
                setNetworkType.add(pm.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c);
            }

            Map<String, Map<String, String>> stZoneGroupMappings = APT_Utils.getSTZoneGroupMapping(setNetworkType);

            //Get all domestic price data for startrack record type and given category, network types
            List<APT_Domestic_Price_Data__c> stDomesticePriceData = [SELECT APT_Category__c, APT_Network_Type__c, APT_Destination_Zone_Code__c,
                                                                    APT_Lodgement_Zone_Code__c, APT_Per_Kg_Rate__c, APT_Subsequent_Rate__c, 
                                                                    APT_Base_Rate__c              
                                                                    FROM APT_Domestic_Price_Data__c
                                                                    WHERE RecordType.Name = :APT_Constants.RECORDTYPE_STARTRACK 
                                                                    AND APT_Category__c IN :setCategory
                                                                    AND APT_Network_Type__c IN :setNetworkType
                                                                    ORDER BY APT_Outbound_Inbound__c DESC];

            for(APT_Domestic_Price_Data__c domesticPriceData : stDomesticePriceData) 
            {   
                domesticPriceData.Id = null;
                
                //replace zones with groups
                Map<String, String> mapZoneGroup = stZoneGroupMappings.get(domesticPriceData.APT_Network_Type__c);
                if(mapZoneGroup != null && mapZoneGroup.size() > 0)
                {
                    domesticPriceData.APT_Lodgement_Zone_Code__c = mapZoneGroup.get(domesticPriceData.APT_Lodgement_Zone_Code__c);
                    domesticPriceData.APT_Destination_Zone_Code__c = mapZoneGroup.get(domesticPriceData.APT_Destination_Zone_Code__c);
                }

                string outboundKey = domesticPriceData.APT_Category__c + APT_Constants.SEPERATOR_SIMILARITY + domesticPriceData.APT_Network_Type__c;

                List<APT_Domestic_Price_Data__c> listDomPriceData = mapDomesticPriceData.get(outboundKey);

                //prepare collection of domestic data for pricing key
                if(listDomPriceData != null && listDomPriceData.size() > 0 && !listDomPriceData.contains(domesticPriceData)) 
                {
                    listDomPriceData.add(domesticPriceData);
                    mapDomesticPriceData.put(outboundKey, listDomPriceData);
                } 
                else if(listDomPriceData == null)
                {
                    listDomPriceData = new List<APT_Domestic_Price_Data__c>();
                    listDomPriceData.add(domesticPriceData);
                    mapDomesticPriceData.put(outboundKey, listDomPriceData);
                }
            }
            
            //create price matrix entry records
            List<Apttus_Config2__PriceMatrixEntry__c> listPriceMatrixEntry = APT_PricingUtility.createPMEForSinglePLISTE(listSTPriceMatrix, mapDomesticPriceData);
            system.debug('createStarTrackSinglePLIPME listPriceMatrixEntry: ' + listPriceMatrixEntry);

            //create price matrix entries
            if(listPriceMatrixEntry != null && listPriceMatrixEntry.size() > 0) 
            {
                insert listPriceMatrixEntry;
            }           
        } 
        catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage() + ex.getStackTraceString());          
            system.debug('createStarTrackSinglePLIPME Exception: ' + ex.getMessage() + ex.getStackTraceString().substringBefore('\n'));
        }
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
                    WHERE Id = :bc.getJobId()];
    
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
        if(String.isNotEmpty(emailAddresses)) {
            toAddresses = emailAddresses.split(APT_Constants.SEPERATOR_COMMA);
        }
        toAddresses.add(a.CreatedBy.Email);
        
        //String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject(APT_Constants.EMAIL_SUB_DOMESTIC_PRICING_BATCH_STATUS);
        
        //Handle Batch Error Message    
        if(a.NumberOfErrors > 0) {
            setErrorMessage.add(a.ExtendedStatus);
        }
        Integer iErrorCount = setErrorMessage.size();
            
        String errorMessage;
        for(String errorMessage1 : setErrorMessage) {
            if(errorMessage != null) {
                errorMessage += APT_Constants.SEPERATOR_NEW_LINE + errorMessage1;
            } else {
                errorMessage = errorMessage1;
            }
        }
        
        //add Batch Error Message in Email
        if(errorMessage != null) {
            mail.setPlainTextBody(APT_Constants.EMAIL_PLAIN_TEXT_PART_1 + a.TotalJobItems + APT_Constants.EMAIL_PLAIN_TEXT_PART_2 + iErrorCount + APT_Constants.EMAIL_PLAIN_TEXT_PART_3 + errorMessage);
        } else {
            mail.setPlainTextBody(APT_Constants.EMAIL_PLAIN_SUCCESS_PART_1 + iErrorCount + APT_Constants.EMAIL_PLAIN_SUCCESS_PART_2);
        }
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}