/*
 * @author Mahesh Patel
 * @date 2021-02-15
 * @group 
 * @description This batch job will update zone types in post code mapping
 * @changelog
 * 2021-02-15 - Mahesh Patel - Created
*/

global class APT_UpdatePostCodeMappingBatch implements Database.Batchable<sObject>, Database.Stateful 
{    
    global set<String> setErrorMessage {get;set;} 
    global List<APT_Post_Code_Mapping__c> listPostCodeMapping; 
    global Map<String, String> lodgementZonesWithType;
    global Set<String> setProducts;
    global String productType {get;set;} 
    public static final String CLASSNAME = 'APT_UpdatePostCodeMappingBatch';
    public static final String ORGID = UserInfo.getOrganizationId();    

    public APT_UpdatePostCodeMappingBatch(List<APT_Post_Code_Mapping__c> listPostCodeMapping, Map<String, String> lodgementZonesWithType, Set<String> setProducts, String productType) 
    {
        setErrorMessage = new set<String>();
        this.listPostCodeMapping = listPostCodeMapping;
        this.lodgementZonesWithType = lodgementZonesWithType;
        this.setProducts = setProducts;
        this.productType = productType;
    }

    /**
        Start
    **/ 
    global Iterable<sObject> start(Database.BatchableContext bc)
    {      
        return (Iterable<sObject>)this.listPostCodeMapping;
    }  

    /**
        Execute
    **/    
    global void execute(Database.BatchableContext bc, List<APT_Post_Code_Mapping__c> listPostCodeMapping)
    {
        try 
        { 
            update listPostCodeMapping;
        } 
        catch(System.Exception ex) 
        {
            setErrorMessage.add(ex.getMessage() + ex.getStackTraceString());          
            system.debug('APT_UpdatePostCodeMappingBatch Exception: ' + ex.getMessage() + ex.getStackTraceString());
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
            APT_PricingBatchUtility.sendEmailNotification('UpdatePostCodeMappingBatch', asyncApexJob, setErrorMessage, null);
        } 
        else 
        {
            //Update Pricing Data Zone Type
            if(!Test.isRunningTest()){
            	APT_UpdatePricingDataBatch updatePricingDataBatch = new APT_UpdatePricingDataBatch(lodgementZonesWithType, setProducts, productType);
            	database.executeBatch(updatePricingDataBatch, 10000);
            }
        }
    }
}