/*
 * @author Mahesh Patel
 * @date 2021-02-15
 * @group 
 * @description This batch job will update zone type column in pricing data records for star track products
 * @changelog
 * 2021-02-15 - Mahesh Patel - Created
*/
global class APT_UpdatePricingDataBatch implements Database.Batchable<sObject>, Database.Stateful 
{
    
    global set<String> setErrorMessage {get;set;} 
    global Map<String, String> lodgementZonesWithType;
    global Set<String> setProducts;
    global String productType {get;set;} 
    public static final String CLASSNAME = 'APT_UpdatePricingDataBatch';
    public static final String ORGID = UserInfo.getOrganizationId();        

    public APT_UpdatePricingDataBatch(Map<String, String> lodgementZonesWithType, Set<String> setProducts, String productType) 
    {
        setErrorMessage = new set<String>();
        this.lodgementZonesWithType = lodgementZonesWithType;
        this.setProducts = setProducts;
        this.productType = productType;
    }

    /**
        Start
    **/ 
    global Iterable<SObject> start(Database.BatchableContext bc)
    {      
        system.debug('lodgementZonesWithType: ' + lodgementZonesWithType);
        system.debug('setProducts: ' + setProducts);
        //Get all domestic price data for given product
        return Database.getQueryLocator([SELECT Id, APT_Pricing_Value_2__c             
                                        FROM APT_Pricing_Data__c
                                        WHERE APT_Pricing_Value_2__c IN :lodgementZonesWithType.keySet()]);
    }  

    /**
        Execute
    **/    
    global void execute(Database.BatchableContext bc, List<APT_Pricing_Data__c> listDomesticPriceData)
    {
        try 
        { 
            system.debug('listDomesticPriceData: ' + listDomesticPriceData);
            //APT_Pricing_Value_12__c is designated to store zone type calculated in precious batches.
            string lodgementZoneCode = 'APT_Pricing_Value_2__c';

            for(APT_Pricing_Data__c domesticPriceData : listDomesticPriceData) 
            {
                domesticPriceData.APT_Pricing_Value_12__c = lodgementZonesWithType.get(String.ValueOf(domesticPriceData.get(lodgementZoneCode)));
            }
            update listDomesticPriceData;
        } 
        catch(System.Exception ex) 
        {
            setErrorMessage.add(ex.getMessage() + ex.getStackTraceString());          
            system.debug('APT_UpdatePricingDataBatch Exception: ' + ex.getMessage() + ex.getStackTraceString());
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
            APT_PricingBatchUtility.sendEmailNotification('UpdatePricingDataBatch', asyncApexJob, setErrorMessage, null);
        } 
        else 
        {
            //call price list item and price matrix batch
            //Price structure parameter is not valid for Startrack products.
            APT_PricingDataBatch createPLIBatch = new APT_PricingDataBatch(productType,'');
            database.executeBatch(createPLIBatch, 1);
        }
    }
}