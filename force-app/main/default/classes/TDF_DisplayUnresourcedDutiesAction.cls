/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-08-11
* @domain Field Service 
* @description Service to call function to display unresourced duties for first day in display, from custom FSL Gantt action 'Display All Unresourced'
*	            Displays list of duties that don't have a driver assigned
*               -gets the start day in view in the gantt and the primary territory of the selected SR
*               -gets a list of all duties (service crews) for the territory
*               -then gets all service crew assignments commencing from start to end of day
*               -return message displays all duties that do not have an assignment.
*
* @changelog 
* 2020-08-11 - Andrew Judd - Created 
*/
global class TDF_DisplayUnresourcedDutiesAction implements FSL.CustomGanttServiceResourceAction {

    global String action(Id resourceId, Id stmId, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {

		//Initialize
		String resultString;
        Id territoryId;
        String stTimezoneString; 
        Set<Id> dutySCIdSet = new Set<Id>();

        //Get Territory from stm
        territoryId = [SELECT ServiceTerritory.TopLevelTerritoryId FROM ServiceTerritoryMember WHERE Id = :stmId].ServiceTerritory.TopLevelTerritoryId;

        //Get the territory timezone string
        stTimezoneString = [SELECT OperatingHours.TimeZone FROM ServiceTerritory WHERE Id = :territoryId].OperatingHours.TimeZone;

        //Get all Service Crew Ids of active Duties for the Service Territory
        for(ServiceTerritoryMember stm : [SELECT Id, ServiceResource.Name, ServiceResource.ServiceCrewId  
                                            FROM ServiceTerritoryMember
                                            WHERE ServiceResource.IsActive = true 
                                            AND ServiceResource.ResourceType = 'C' 
                                            AND TerritoryType = 'P' 
                                            AND EffectiveStartDate < :ganttStartDate 
                                            AND (EffectiveEndDate = null OR EffectiveEndDate > :ganttStartDate) 
                                            AND ServiceTerritoryId = :territoryId]){
            dutySCIdSet.add(stm.ServiceResource.ServiceCrewId);                
        }       

        //Get the start and end of day times for the service territory in GMT i.e. 0000hrs to 2400hrs for territory
        //Note that the gantt Start Date gives time in GMT based on user's locale.  The following will ensure it is accurate regardless of location
        Datetime startDayDateTimeST = Datetime.newInstanceGMT(ganttStartDate.year(), ganttStartDate.month(), ganttStartDate.day(), 0, 0, 0);
         
        //Get timezone offset
		string currentDateTimeStrGMT  = startDayDateTimeST.formatGMT('yyyy-MM-dd HH:mm:ss');
		string currentDateTimeStrST = startDayDateTimeST.format('yyyy-MM-dd HH:mm:ss',  stTimezoneString);
		Long milliSecDiff =  DateTime.valueOf(currentDateTimeStrGMT).getTime() - DateTime.valueOf(currentDateTimeStrST).getTime();
        Long minDiff = milliSecDiff / 1000 / 60;

		//Calculate start and end of day for the service territory
        startDayDateTimeST = startDayDateTimeST.addMinutes(minDiff.intValue());
		Datetime endDayDateTimeST = startDayDateTimeST.addMinutes(60 * 24);

        //Get Duties (crews) 
        //-and their related SCMs where Start of the assignment occurs within the ST day
        List<ServiceCrew> dutySCList = [SELECT Id, Name, 
                                    (SELECT Id from ServiceCrewMembers 
                                    WHERE StartDate > :startDayDateTimeST AND StartDate < :endDayDateTimeST) 
                                FROM ServiceCrew
                                WHERE Id IN :dutySCIdSet 
                                ORDER BY Name];

        String dutiesWithNoAssignmentString;
        //Loop thru list and build string of all duties without an SCM for the day.
        for(ServiceCrew sc : dutySCList){
            //if no member
            if(sc.ServiceCrewMembers.size() == 0){
                //Add to return string
                if(dutiesWithNoAssignmentString == null){
                    dutiesWithNoAssignmentString = sc.Name;
                }
                else{
                    dutiesWithNoAssignmentString = dutiesWithNoAssignmentString + '<br/> ' + sc.Name;
                }
            }
        }

        String returnMessageString;
        //Set return string
        if(dutiesWithNoAssignmentString == null){
            returnMessageString = 'All duties have an assignment for ' + ganttStartDate.format('dd MMM');
        }
        else{
            returnMessageString = 'The following duties do not have a driver assigned for ' + ganttStartDate.format('dd MMM') + ':<br/>' + dutiesWithNoAssignmentString;
        }

        //Return message
        return returnMessageString;
    }
}