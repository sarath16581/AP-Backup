/***

 * @author Mahesh Patel
 * @date 2021-02-15
 * @group 
 * @description Apex batch class which creates price matrix record for different product types. 
 * This batch class have a chained batch job which creates Price matrix entries.
 * @changelog
 * 2021-02-15 - Mahesh Patel - Created
 * 2021-09-14 - Mathew Jose - Updated to incorporate chages require for Parcel Contract products.
*/
global class APT_CreatePMBatch implements Database.Batchable<sObject>, Database.Stateful 
{
    global set<String> setErrorMessage {get;set;} 
    global String productType {get;set;}
    global String priceStructure {get;set;}
    public static final String CLASSNAME = 'APT_CreatePMBatch';
    public static final String ORGID = UserInfo.getOrganizationId(); 

    public APT_CreatePMBatch(string productType, string priceStructure) 
    {
        this.setErrorMessage = new set<String>();
        this.productType = productType;
        this.priceStructure = priceStructure;
    }

    /**
    Start Method
    **/    
    global List<Product2> start(Database.BatchableContext bc) 
    {        
        String queryStr = 'SELECT Id, Name FROM Product2 WHERE';
        String stProductType = APT_Constants.PRODUCTTYPE_STARTRACK;
        String parSimProductType = 'Parcel Contract';
        list<string> parSimFSRProductTypeList= new list<string>{'Parcel Contract-Feature','Parcel Contract-Surcharge','Parcel Contract-Return'};          
        
        if(productType == 'Domestic_Non_Startrack')
        {
            queryStr += ' APT_Domestic_Pricing__c = true AND APT_Product_type__c !=: stProductType AND APT_Product_type__c !=: parSimProductType';
        }
        else if(productType == 'Startrack')
        {
            queryStr += ' APT_Domestic_Pricing__c = true AND APT_Product_type__c =: stProductType';
        }
        else if(productType == 'International')
        {
            queryStr += ' APT_International_Pricing__c = true';
        }        
        else if(productType == 'Domestic_Simplified_Parcel_Contract')
        {
            queryStr += ' APT_Domestic_Pricing__c = true AND APT_Product_type__c =: parSimProductType';
        }
        else if(productType == 'Domestic_Simplified_Features_Surcharges')
        {
            queryStr += ' APT_Product_type__c IN : parSimFSRProductTypeList';
        }        
        return Database.query(queryStr);
    }
    
    /**
    Execute Method
    **/    
    global void execute(Database.BatchableContext bc, List<Product2> products)
    {
        try 
        { 
            system.debug('execute start');

            Map<Id, Product2> productMap = new Map<Id, Product2>(products);
            Map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix = new Map<String, Apttus_Config2__PriceMatrix__c>();

            List<Apttus_Config2__PriceListItem__c> listPriceListItem = [SELECT Id, Apttus_Config2__ProductId__c,
                                                                        (SELECT Id, Apttus_Config2__PriceListItemId__c FROM Apttus_Config2__PriceMatrices__r)
                                                                        FROM Apttus_Config2__PriceListItem__c
                                                                        WHERE Apttus_Config2__ProductId__c IN :productMap.keySet()];

            system.debug('execute listPriceListItem: ' + listPriceListItem);
            for(Apttus_Config2__PriceListItem__c pli: listPriceListItem)
            {
               for(Apttus_Config2__PriceMatrix__c pm : pli.Apttus_Config2__PriceMatrices__r){
                    mapExistingPriceMatrix.put(pm.Apttus_Config2__PriceListItemId__c, pm);
               }
            }
            system.debug('execute mapExistingPriceMatrix: ' + mapExistingPriceMatrix);

            //create price matrix records
            List<Apttus_Config2__PriceMatrix__c> listPriceMatrix = APT_PricingBatchUtility.createPriceMatrixGeneric(listPriceListItem, mapExistingPriceMatrix, productMap);

            system.debug('execute listPriceMatrix: ' + listPriceMatrix);
            
            //upsert price matrix records
            if(listPriceMatrix != null && listPriceMatrix.size() > 0) 
            {
                upsert listPriceMatrix;
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
            APT_PricingBatchUtility.sendEmailNotification('CreatePMBatch', asyncApexJob, setErrorMessage, null);
        } 
        else 
        {
            //Trigger PME Creation Batch
            APT_CreatePMEBatch createPMEBatch = new APT_CreatePMEBatch(productType, priceStructure);
            if(!Test.isRunningTest()){
                database.executeBatch(createPMEBatch, 1);
            }
        }
    }
}