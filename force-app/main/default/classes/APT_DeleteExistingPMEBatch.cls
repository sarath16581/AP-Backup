/***
 * @author Mahesh Patel
 * @date 2021-05-01
 * @group 
 * @description Apex batch class which deletes all the existing PME's associated with product type for which the job is triggered for.
 * Subsequent batches are chained to this batch job and varies between ST and other product types.
 * @changelog
 * 2021-05-01 - Mahesh Patel - Created
 * 2021-09-14 - Mathew Jose - Updated to incorporate chages require for Parcel Contract products.
*/
global class APT_DeleteExistingPMEBatch implements Database.Batchable<sObject>, Database.Stateful 
{    
    global set<String> setErrorMessage {get;set;} 
    global List<APT_Post_Code_Mapping__c> listPostCodeMapping;
    global String productType {get;set;} 
    global String priceStructure {get;set;}  
    public static final String CLASSNAME = 'APT_DeleteExistingPMEBatch';
    public static final String ORGID = UserInfo.getOrganizationId();     
    /**
        Constructor
    **/    
    global APT_DeleteExistingPMEBatch(String productType, String priceStructure) 
    {
        setErrorMessage = new set<String>();
        this.productType = productType;
        this.priceStructure = priceStructure;
    }

    /**
        Start Method
    **/        
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {        
        String stProductType = APT_Constants.PRODUCTTYPE_STARTRACK;
        String parSimProductType = 'Parcel Contract';
        list<string> parSimFSRProductTypeList= new list<string>{'Parcel Contract-Feature','Parcel Contract-Surcharge','Parcel Contract-Return'};
        String queryStr = 'SELECT Id FROM Apttus_Config2__PriceListItem__c WHERE';
        if(productType == 'Domestic_Non_Startrack')
        {
            queryStr += ' Apttus_Config2__ProductId__r.APT_Domestic_Pricing__c = true AND Apttus_Config2__ProductId__r.APT_Product_type__c !=: stProductType AND Apttus_Config2__ProductId__r.APT_Product_type__c !=: parSimProductType';
            if(!String.isBlank(priceStructure)){
                queryStr += ' AND APT_Price_Structure__c =: priceStructure';
            }
        }
        else if(productType == 'Startrack')
        {
            queryStr += ' Apttus_Config2__ProductId__r.APT_Domestic_Pricing__c = true AND Apttus_Config2__ProductId__r.APT_Product_type__c =: stProductType';
        }
        else if(productType == 'International')
        {
            queryStr += ' Apttus_Config2__ProductId__r.APT_International_Pricing__c = true';
        }        
        else if(productType == 'Domestic_Simplified_Parcel_Contract')
        {
            queryStr += ' Apttus_Config2__ProductId__r.APT_Domestic_Pricing__c = true AND Apttus_Config2__ProductId__r.APT_Product_type__c =: parSimProductType';
            if(!String.isBlank(priceStructure)){
                queryStr += ' AND APT_Price_Structure__c =: priceStructure';
            }    
        }
        else if(productType == 'Domestic_Simplified_Features_Surcharges'){
            queryStr += ' Apttus_Config2__ProductId__r.APT_Product_type__c IN : parSimFSRProductTypeList';
        }    
        return Database.getQueryLocator(queryStr);
    }
    /**
        Execute Method
    **/        
    global void execute(Database.BatchableContext bc, list<Apttus_Config2__PriceListItem__c> listPriceListItem)
    {
        try 
        { 
            //delete price matrix entry
            Set<Id> setPriceListItemId = new Set<Id>();
            for(Apttus_Config2__PriceListItem__c priceListItem : listPriceListItem) 
            {
                setPriceListItemId.add(priceListItem.Id);
            }
            
            Set<Id> setPriceMatrixId = new Set<Id>();
            for(Apttus_Config2__PriceMatrix__c priceMatrix : [SELECT Id FROM Apttus_Config2__PriceMatrix__c WHERE Apttus_Config2__PriceListItemId__c IN :setPriceListItemId]) 
            {
                setPriceMatrixId.add(priceMatrix.Id);
            }
            
            List<Apttus_Config2__PriceMatrixEntry__c> listPriceMatrixEntry = [SELECT Id FROM Apttus_Config2__PriceMatrixEntry__c WHERE Apttus_Config2__PriceMatrixId__c IN :setPriceMatrixId];
            if(listPriceMatrixEntry != null && listPriceMatrixEntry.size() > 0) 
            {
                delete listPriceMatrixEntry;
            }
            
        } 
        catch(System.Exception ex) 
        {
            setErrorMessage.add(ex.getMessage() + ex.getStackTraceString());             
            system.debug('APT_DeleteExistingPMEBatch Exception: ' + ex.getMessage() + ex.getStackTraceString().substringBefore('\n'));
            UTIL_LoggingService.logHandledException(ex, ORGID, 'Apttus Pricing Batch Job', CLASSNAME, 'execute', null, LoggingLevel.ERROR);

        }
    }

    /**
        Finish Method
    **/    
    global void finish(Database.BatchableContext bc) 
    {
        //Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob asyncApexJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems, CreatedBy.Email, ExtendedStatus  
                                    FROM AsyncApexJob 
                                    WHERE Id = :bc.getJobId()];

        system.debug('No. of errors: ' + asyncApexJob.NumberOfErrors);
                        
        if(asyncApexJob.NumberOfErrors > 0) 
        {
            setErrorMessage.add(asyncApexJob.ExtendedStatus);
        }
        
        if(setErrorMessage.size() > 0) 
        {
            APT_PricingBatchUtility.sendEmailNotification('DeleteExistingPMEBatch', asyncApexJob, setErrorMessage, null);
        } 
        else 
        {
            if(productType == 'Startrack')
            {
                //Get Post Code Mapping
                List<APT_Post_Code_Mapping__c> listPostCodeMapping = [SELECT Id, APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c,
                                                                        APT_EXP_Zone_Type__c, APT_PRM_Zone_Type__c, APT_NXF_Zone_Type__c, APT_SE2_Zone_Type__c, 
                                                                        APT_SE3_Zone_Type__c, APT_RET_Zone_Type__c, APT_RE2_Zone_Type__c 
                                                                        FROM APT_Post_Code_Mapping__c];

                //Determine Zone Type for ST Products
                APT_DetermineZoneTypesBatch determineZoneTypesBatch = new APT_DetermineZoneTypesBatch(listPostCodeMapping, productType);
                if(!Test.isRunningTest()){
                    database.executeBatch(determineZoneTypesBatch, 1);
                }
            }
            else
            {
                //call price list item and price matrix batch
                APT_PricingDataBatch createPLIBatch = new APT_PricingDataBatch(productType, priceStructure);
                if(!Test.isRunningTest()){
                    database.executeBatch(createPLIBatch, 1);
                } 
            }
            
        }
    }
}