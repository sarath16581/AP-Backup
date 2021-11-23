global class TDF_RefreshTerritoriesScheduler implements Schedulable{
    global void execute(SchedulableContext SC){
        
        //If AssRes query in RT exceeds limit of 50k, then set Refresh All to false to call for one territory at a time 
        //Not done initially due to potential for conflicts with multi call and 50k not expected
        
        //Default Service Territory Id to null
        String strServTerId = null;
        
        //Get custom setting controlling refresh all, or by territory
        TDF_Settings__c objTDFSetting = TDF_Settings__c.getOrgDefaults();
        Boolean refreshAllTerritories = Boolean.valueof(objTDFSetting.Refresh_All_Territories__c);
        
        //If refresh all true, and not a test run, then call RT with null service territory value.
        if(refreshAllTerritories && !test.isRunningTest()){
            TDF_RefreshTerritories.RefreshByServiceTerritoryId(strServTerId);
        }
        //else call seperately for each territory
        else
        {                
            //Get all parent territories
            List<ServiceTerritory> parentSvcTerList = new List<ServiceTerritory>();
            parentSvcTerList = [SELECT Id, Name FROM ServiceTerritory WHERE ParentTerritory.Id = null AND IsActive = true];
            
            //Call refresh for each parent
            for (ServiceTerritory servTer : parentSvcTerList){
            
                strServTerId = servTer.Id;
                
                //If test is running set Service Territory Id to dummy value as calling test class is 'SeeAllData'             
                if(test.isRunningTest())
                    strServTerId = '0xx0x0000000xxx';
                
                //Call Refresh Territories   
                TDF_RefreshTerritories.RefreshByServiceTerritoryId(strServTerId);
            }
        }
    }
}