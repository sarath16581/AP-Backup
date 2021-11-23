/**
Description: This batch job will delete existing price matrix entry.
Created By - Mausam Padhiyar
Created Date - 7th Oct, 2015
Last Modified By - Mahesh Patel
Last Modified Date - 20th Oct, 2020
Change Description - Added startrack product's determine zone type related logic. 
**/
global class APT_DeleteExistingDomesticPricingBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global set<String> setErrorMessage {get;set;} 
    global List<APT_Post_Code_Mapping__c> listPostCodeMapping;
    
    /**
        constructor
    **/    
    global APT_DeleteExistingDomesticPricingBatch() {
        setErrorMessage = new set<String>();
    }
    /**
        Start Method
    **/        
    global Database.QueryLocator start(Database.BatchableContext bc) {        
        set<Id> setProductId = new set<Id>();

        for(Product2 product : [SELECT Id, Name, APT_Category__c, APT_Network_Type__c FROM Product2 
                                WHERE APT_Domestic_Pricing__c = true]) {
             
            setProductId.add(product.Id);                               
        }
        
        //start
        return Database.getQueryLocator([SELECT Id FROM Apttus_Config2__PriceListItem__c
                                        WHERE Apttus_Config2__ProductId__c IN :setProductId]);
    }
    /**
        execute
    **/        
    global void execute(Database.BatchableContext bc, list<Apttus_Config2__PriceListItem__c> listPriceListItem){
        try { 
            APT_R2T_Domestic_Pricing_Properties__c r2tDomesticPricingProperties = APT_R2T_Domestic_Pricing_Properties__c.getValues(APT_Constants.R2T_DOMESTIC_PRICING_PROPERTIES);
            set<String> setDimension = new set<String>();
            if(r2tDomesticPricingProperties != null) {
                if(r2tDomesticPricingProperties.APT_Dimension1_Name__c != null) {
                    setDimension.add(r2tDomesticPricingProperties.APT_Dimension1_Name__c);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension1_Name__c != null && r2tDomesticPricingProperties.APT_Dimension1_Type__c == null) {
                    setErrorMessage.add(APT_Constants.ERROR_MISSING_DIM_TYPE + r2tDomesticPricingProperties.APT_Dimension1_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension1_Name__c != null && r2tDomesticPricingProperties.APT_Dimension1_Value__c == null) {
                    setErrorMessage.add(APT_Constants.ERROR_MISSING_DIM_VALUE + r2tDomesticPricingProperties.APT_Dimension1_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension2_Name__c != null) {
                    setDimension.add(r2tDomesticPricingProperties.APT_Dimension2_Name__c);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension2_Name__c != null && r2tDomesticPricingProperties.APT_Dimension2_Type__c == null) {
                    setErrorMessage.add(APT_Constants.ERROR_MISSING_DIM_TYPE + r2tDomesticPricingProperties.APT_Dimension2_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension2_Name__c != null && r2tDomesticPricingProperties.APT_Dimension2_Value__c == null) {
                    setErrorMessage.add(APT_Constants.ERROR_MISSING_DIM_VALUE + r2tDomesticPricingProperties.APT_Dimension2_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension3_Name__c != null) {
                    setDimension.add(r2tDomesticPricingProperties.APT_Dimension3_Name__c);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension3_Name__c != null && r2tDomesticPricingProperties.APT_Dimension3_Type__c == null) {
                    setErrorMessage.add(APT_Constants.ERROR_MISSING_DIM_TYPE + r2tDomesticPricingProperties.APT_Dimension3_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension3_Name__c != null && r2tDomesticPricingProperties.APT_Dimension3_Value__c == null) {
                    setErrorMessage.add(APT_Constants.ERROR_MISSING_DIM_VALUE + r2tDomesticPricingProperties.APT_Dimension3_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension4_Name__c != null) {
                    setDimension.add(r2tDomesticPricingProperties.APT_Dimension4_Name__c);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension4_Name__c != null && r2tDomesticPricingProperties.APT_Dimension4_Type__c == null) {
                    setErrorMessage.add(APT_Constants.ERROR_MISSING_DIM_TYPE + r2tDomesticPricingProperties.APT_Dimension4_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension4_Name__c != null && r2tDomesticPricingProperties.APT_Dimension4_Value__c == null) {
                    setErrorMessage.add(APT_Constants.ERROR_MISSING_DIM_VALUE + r2tDomesticPricingProperties.APT_Dimension4_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension5_Name__c != null) {
                    setDimension.add(r2tDomesticPricingProperties.APT_Dimension5_Name__c);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension5_Name__c != null && r2tDomesticPricingProperties.APT_Dimension5_Type__c == null) {
                    setErrorMessage.add(APT_Constants.ERROR_MISSING_DIM_TYPE + r2tDomesticPricingProperties.APT_Dimension5_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension5_Name__c != null && r2tDomesticPricingProperties.APT_Dimension5_Value__c == null) {
                    setErrorMessage.add(APT_Constants.ERROR_MISSING_DIM_VALUE + r2tDomesticPricingProperties.APT_Dimension5_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension6_Name__c != null) {
                    setDimension.add(r2tDomesticPricingProperties.APT_Dimension6_Name__c);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension6_Name__c != null && r2tDomesticPricingProperties.APT_Dimension6_Type__c == null) {
                    setErrorMessage.add(APT_Constants.ERROR_MISSING_DIM_TYPE + r2tDomesticPricingProperties.APT_Dimension6_Name__c + APT_Constants.SEPERATOR_DOT);
                }
                
                if(r2tDomesticPricingProperties.APT_Dimension6_Name__c != null && r2tDomesticPricingProperties.APT_Dimension6_Value__c == null) {
                    setErrorMessage.add(APT_Constants.ERROR_MISSING_DIM_VALUE + r2tDomesticPricingProperties.APT_Dimension6_Name__c + APT_Constants.SEPERATOR_DOT);
                }
            } else {
                setErrorMessage.add(APT_Constants.ERROR_NO_CSTM_SETTINGS + APT_Constants.R2T_DOMESTIC_PRICING_PROPERTIES + APT_Constants.SEPERATOR_SPACE + APT_Constants.STR_FOUND + APT_Constants.SEPERATOR_DOT);
            }
            
            if(setDimension.size() == 0) {
                setErrorMessage.add(APT_Constants.ERROR_DIMENSIONS_NOT_IN_CUSTOM_SETTINGS + APT_Constants.R2T_DOMESTIC_PRICING_PROPERTIES + APT_Constants.SEPERATOR_DOT);
            }
            
            /*
            if(setErrorMessage.size() == 0 && listPriceListItem != null && listPriceListItem.size() > 0) {
                delete listPriceListItem;
            }
            */
            
            //delete price matrix entry only
            if(setErrorMessage.size() == 0) {
                set<Id> setPriceListItemId = new set<Id>();
                for(Apttus_Config2__PriceListItem__c pli : listPriceListItem) {
                    setPriceListItemId.add(pli.Id);
                }
                
                set<Id> setPriceMatrixId = new set<Id>();
                for(Apttus_Config2__PriceMatrix__c pm : [SELECT Id FROM Apttus_Config2__PriceMatrix__c WHERE Apttus_Config2__PriceListItemId__c IN :setPriceListItemId]) {
                    setPriceMatrixId.add(pm.Id);
                }
                
                list<Apttus_Config2__PriceMatrixEntry__c> listPriceMatrixEntry = [SELECT Id FROM Apttus_Config2__PriceMatrixEntry__c WHERE Apttus_Config2__PriceMatrixId__c IN :setPriceMatrixId];
                if(listPriceMatrixEntry != null && listPriceMatrixEntry.size() > 0) {
                    delete listPriceMatrixEntry;
                }
            }
            
        } catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage());          
            system.debug('APT_DeleteExistingDomesticPricingBatch Exception: ' + ex.getMessage() + ex.getStackTraceString().substringBefore('\n'));
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
            if(String.isNotEmpty(emailAddresses)) {
                toAddresses = emailAddresses.split(APT_Constants.SEPERATOR_COMMA);
            }
            toAddresses.add(a.CreatedBy.Email);
            
            //String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject(APT_Constants.EMAIL_SUB_DOMESTIC_PRICING_BATCH_STATUS);
            
            //Handle Batch Error Message
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
            } /**else {
                mail.setPlainTextBody('The Domestic Pricing Batch job has processed ' + a.TotalJobItems + ' batches with '+ iErrorCount + ' failures.');
            }**/
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } else {
            //STP-2955 Modify Existing Batch to Create PLI, PM and PME for Express Road - STE Product
            //Get Post Code Mapping
            List<APT_Post_Code_Mapping__c> listPostCodeMapping = [SELECT Id, APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c,
                                                                APT_EXP_Zone_Type__c, APT_PRM_Zone_Type__c, APT_NXF_Zone_Type__c, APT_SE2_Zone_Type__c, 
                                                                APT_SE3_Zone_Type__c, APT_RET_Zone_Type__c, APT_RE2_Zone_Type__c 
                                                                FROM APT_Post_Code_Mapping__c];

            //Determine Zone Type for ST Products
            APT_DetermineSTZoneTypesBatch determineSTZoneTypesBatch = new APT_DetermineSTZoneTypesBatch(listPostCodeMapping);
            database.executeBatch(determineSTZoneTypesBatch, 1);
        }        
    }
}