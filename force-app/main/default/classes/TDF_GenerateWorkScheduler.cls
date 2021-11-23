/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-08-01
* @domain Field Service 
* @description Scheduled Class to Generate Work for tomorrow schedule for duties approaching the duty start time
*               The class gets all active Crew (Duty) based Service Resources with a Duty Start Time in the next 30 min window and Auto Generate Work = true, including:
*               - Related list of active Duty Templates (based on active day and status)
*               - Related list of jobs for tomorrow duty day
*               - Related list of primary service territories
*               If the duty meets the following criteria
*               - Only one active Duty Template for tomorrow
*               - No existing jobs for the duty for tomorrow
*               - An active primary territory assigned
*               Then the system will submit a generate work job for the duty
*
* @changelog 
* 2020-08-01 - Andrew Judd - Created 
* 2020-08-25 - Andrew Judd - Added condition to queryString to ignore jobs with status 'Canceled'
* 2020-09-04 - Andrew Judd - Added isTest condition to not constrain on Duty Start Time if in test mode
*/
global class TDF_GenerateWorkScheduler implements Schedulable{
    
    global void execute(SchedulableContext SC){
        
        String queryString;
        String queryDayString;
        Time currentTime = DateTime.Now().Time();
        Time toTime = currentTime.addMinutes(30);
        
        //if adding 30 mins pushes past midnight, then make it midnight
		if(toTime < currentTime) toTime = Time.newInstance(23,59,59,999); 
        
        //Debug to get all
        //currentTime = Time.newInstance(00,00,00,000); 
        //toTime = Time.newInstance(23,59,59,999); 
        
        Date tomorrowDate = Date.Today().addDays(1);
        
        System.debug('currentTime = ' + currentTime);
        System.debug('tomorrowDate = ' + tomorrowDate);
        
        Datetime tomorrowDateTime = (DateTime)tomorrowDate;
		String dayString = tomorrowDateTime.format('E');
        Boolean monBol = false;
        Boolean tueBol = false;
        Boolean wedBol = false;
        Boolean thuBol = false;
        Boolean friBol = false;
        Boolean satBol = false;
        Boolean sunBol = false;

        Boolean primarySTActiveBoolean;
        Integer activeDTInt;
        Integer jobsQueuedInt = 0;
        
        //For duty day work being generated for, include criteria in query to only get DTs active for that day
        switch on dayString {
            when 'Mon' {queryDayString = ' Monday__c = true ';}
            when 'Tue' {queryDayString = ' Tuesday__c = true ';}
            when 'Wed' {queryDayString = ' Wednesday__c = true ';}
            when 'Thu' {queryDayString = ' Thursday__c = true ';}
            when 'Fri' {queryDayString = ' Friday__c = true ';}
            when 'Sat' {queryDayString = ' Saturday__c = true ';}
            when 'Sun' {queryDayString = ' Sunday__c = true ';}
		}
         
        //Get all Active duty SRs with Auto Generate Work as true, by Duty Start time within next 30 min window*
        //Include return of active Duty Templates assigned to this SR for tomorrow
        //Include return of Service Appointments for tomorrow duty day - to determine if work has already been generated for tomorrow
        //Limit the list to 200, but only process the first 50 valid duties below.
        //*Note that timezone is not considered here, but since we are generating the work for tomorrow, exact timing is not important. 
        List<ServiceResource> dutySRList;

        queryString =  'SELECT Id, Name, DutyStartTime__c, '; 
        queryString += '(SELECT Id FROM Service_Appointments_By_Primary__r WHERE Work_Order__r.Duty_Day__c = ' + String.valueOf(tomorrowDate) + ' AND Status != \'Canceled\' LIMIT 1), ';
        queryString += '(SELECT Id, EffectiveStartDate, EffectiveEndDate FROM ServiceTerritories WHERE TerritoryType = \'P\' ), ';
        queryString += '(SELECT Id, Effective_Date__c, Expiry_Date__c, Name FROM Duty_Templates__r WHERE Status__c = \'Active\' ';
        queryString += 'AND ' + queryDayString + ') ';
        queryString += 'FROM ServiceResource ';
        queryString += 'WHERE IsActive = true AND Auto_Generate_Work__c = true AND ResourceType = \'C\' ';
        if(!Test.isRunningTest()){
            queryString += 'AND DutyStartTime__c != null AND (DutyStartTime__c > ' + currentTime + ' AND DutyStartTime__c < ' + toTime + ') LIMIT 200 ';
        }
        //System.debug('queryString = ' + queryString);
        
        dutySRList = Database.query(queryString);
        //System.debug('dutySRList = ' + dutySRList);
       
        //Loop thru DTs
        for(ServiceResource dutySR : dutySRList){
            
            String jobBoardTemplateId;
            
            System.debug('Duty ' + dutySR.Name + '. Job ' + dutySR.Service_Appointments_By_Primary__r.size() + '. DT ' + dutySR.Duty_Templates__r.size() + '. ST ' + dutySR.ServiceTerritories.size());
            
            //If Duty does not have work already for tomorrow
            if(dutySR.Service_Appointments_By_Primary__r.size() == 0){
                
                //If Duty has at least one active duty template for tomorrow day
                if(dutySR.Duty_Templates__r.size() > 0){
                    
                    activeDTInt = 0;
                    
                    //For each duty template - not that we only have Active ones at this point
                    for(Route_Template__c dt : dutySR.Duty_Templates__r){
                        
                        //If still active based on effective and expiry dates
                        if(	(dt.Effective_Date__c <= tomorrowDate || dt.Effective_Date__c == null) &&  
                           (dt.Expiry_Date__c > tomorrowDate || dt.Expiry_Date__c == null)){
                               //Then count
                               activeDTInt = activeDTInt + 1;
                           }
                    }
                    
                    //If only one DT is Active for tomorrow
                    if(activeDTInt == 1){
                    
                        //If duty has a primary territory
                        if(dutySR.ServiceTerritories.size() > 0){
                            
                            primarySTActiveBoolean = false;
                            
                            //For each primary stm
                            for(ServiceTerritoryMember stm : dutySR.ServiceTerritories){
                               
                                //Check to see if any are active for tomorrow
                                if(stm.EffectiveStartDate < tomorrowDateTime && (stm.EffectiveEndDate > tomorrowDateTime || stm.EffectiveEndDate == null)){
                                    primarySTActiveBoolean = true;
                                }
                            }
                            
                            //If primary territory is active and no more than 50 jobs have been queued.
                            //-it is not expected there will be more that 50 jobs in one cycle, however if so these will be processed in the next run
                            if(primarySTActiveBoolean == true && jobsQueuedInt < 50){
                                
                                jobBoardTemplateId = dutySR.Duty_Templates__r[0].Id;
                                System.debug('GENERATE WORK for Duty = ' + dutySR.Name + 'Id = ' + jobBoardTemplateId);

                                try{
                                    //Call generate work via queueable interface
                                    Id jobID = System.enqueueJob(new TDF_GenerateWorkQueueable(tomorrowDate, tomorrowDate, jobBoardTemplateId, null));
                                }
                                catch(Exception exp) {
                                    //Log error to Exception object for analysis
                                    UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'TDF', 'TDF_GenerateWorkScheduler', 'execute', 'System: DTId = ' + jobBoardTemplateId, LoggingLevel.ERROR);
                                    System.debug('ERROR Logged');
                                }

                                //Count number of jobs queued
                                jobsQueuedInt = jobsQueuedInt + 1;
                            }
                        }
                    }
                }
            }
        }  
    }
}