/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-08-12
* @domain Field Service 
* @description Service to call function to call generate work for selected duty in FSL Gantt     
*
* @changelog 
* 2020-08-12 - Andrew Judd - Created 
* 2020-08-25 - Andrew Judd - Added condition to queryString to ignore jobs with status 'Canceled'
*/
global class TDF_GenerateWorkAction implements FSL.CustomGanttServiceResourceAction {

    global String action(Id resourceId, Id stmId, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {

		//Initialize
		String resultString;
        Date startDate;
        Date endDate;
        String jobBoardTemplateId;
        String jobTemplateId;
        String queryDayString;
        String queryString;

        //Get start date from date in view in gantt
        startDate = Date.newInstance(ganttStartDate.year(), ganttStartDate.month(), ganttStartDate.day());

        Datetime startDateTime = (DateTime)startDate;
		String dayString = startDateTime.format('E');
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
        Set<String> activeTemplatesSet = new Set<String>();
        
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

        List<ServiceResource> dutySRList;
        //Get Service Resource record with related lists of SAs for today, and all Active Duty Templates
        queryString =  'SELECT Id, Name, DutyStartTime__c, '; 
        queryString += '(SELECT Id FROM Service_Appointments_By_Primary__r WHERE Work_Order__r.Duty_Day__c = ' + String.valueOf(startDate) + ' AND Status != \'Canceled\' LIMIT 1), ';
        queryString += '(SELECT Id, Effective_Date__c, Expiry_Date__c, Name FROM Duty_Templates__r WHERE Status__c = \'Active\' ';
        queryString += 'AND ' + queryDayString + ') ';
        queryString += 'FROM ServiceResource ';
        queryString += 'WHERE Id = \'' + resourceId + '\' ';
        //System.debug('queryString = ' + queryString);

        //Execute query
        dutySRList = Database.query(queryString);
        //System.debug('dutySRList = ' + dutySRList);

        //If SR found
        for(ServiceResource dutySR : dutySRList){
            
            //If Duty does not have work already for tomorrow
            if(dutySR.Service_Appointments_By_Primary__r.size() == 0){
                
                //If Duty has at least one active duty template for tomorrow day
                if(dutySR.Duty_Templates__r.size() > 0){
                    
                    activeDTInt = 0;
                    
                    //For each duty template
                    for(Route_Template__c dt : dutySR.Duty_Templates__r){
                        
                        //If still active based on effective and expiry dates
                        if(	(dt.Effective_Date__c <= startDate || dt.Effective_Date__c == null) &&  
                           (dt.Expiry_Date__c > startDate || dt.Expiry_Date__c == null)){
                               //Then count and add to set 
                               activeDTInt = activeDTInt + 1;
                               activeTemplatesSet.add(dt.Name);
                               jobBoardTemplateId = dt.Id;
                           }
                    }
                    
                    //If only one Duty Template is active for tomorrow
                    if(activeDTInt == 1){

                        //Call generate work 
                        TDF_GenerateWork tdfGW = new TDF_GenerateWork();
                        resultString = tdfGW.createJobs(startDate, startDate, jobBoardTemplateId, null);
                        return resultString + ' for duty ' + dutySR.Name;

                    }
                    //Else duty has more than one active Duty Template, so return this message
                    else{
                        return 'Duty ' + dutySR.Name + ' has more than one active duty template for this day as follows:' + activeTemplatesSet;
                    }
                }
                //Else no active Duty Template found, so return this message
                else{
                    return 'Duty ' + dutySR.Name + ' has no active duty template for this day.';
                }
            }
            //Else operational duty already has work for this day, so return message
            else{
                return 'Duty ' + dutySR.Name + ' already has work for this day.';
            }
        }

        //Nothing found, return message
        return 'No duty service resource found.';

    }
}