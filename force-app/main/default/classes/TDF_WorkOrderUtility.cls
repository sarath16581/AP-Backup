/* Utility to support TDF Generate Work function
 *
 * Change History:
 * 24.07.2020 ajudd@salesforce.com 	Commented out debug statements
 * 
 * 10-08-2021 keerthi.akul@auspost.com.au  updated createStartDateTime to fix timezone issue 
 */
global class TDF_WorkOrderUtility{

    //Method used to return offset hours between User timezone and location timezone
    public static Decimal getOffsetHours(String timeZoneString){

        //Calculate User timezone offset from GMT time.
        /*A.Judd 29.10.18 Replaced with revised approach below.
        DateTime now = DateTime.now();
        Long userOffset = DateTime.newInstance(now.date(), now.time()).getTime() - DateTime.newInstance(now.dateGmt(), now.timeGmt()).getTime();
        System.debug('userOffsetFromGMT (milliseconds): ' + userOffset);
        Decimal userOffsetHours = 0.0;
        userOffsetHours = (userOffset / (60 * 60));
        userOffsetHours = userOffsetHours/1000;
        System.debug('userOffsetHoursFromGMT (hours): ' + userOffsetHours);*/

        //A.Judd 29.10.18 New solution to get user offset hour.  Original approach did not switch accurately on daylight savings transition.
        String userTimeZoneString = UserInfo.getTimeZone().getID();
        //System.debug('userTimeZoneString ->'+userTimeZoneString );
        TimeZone userTimeZone = TimeZone.getTimeZone(userTimeZoneString);
        Long userOffset = userTimeZone.getOffset(System.now());
        //System.debug('UserOffset ->' + userOffset);
        Decimal userOffSetHours = 0.0;
        userOffSetHours = (userOffset / (60 * 60));
        userOffSetHours = userOffSetHours/1000;
        //System.debug('userOffSetHours ->' + userOffSetHours);
        //A.Judd 29.10.18 End new solution to get user offset hour.

        //Calculate offset from location timezone
        String locationTimeZoneString = timeZoneString;
        //System.debug('locationTimeZoneString ->'+locationTimeZoneString);
        TimeZone locationTimeZone = TimeZone.getTimeZone(locationTimeZoneString);
        Long locationOffset = locationTimeZone.getOffset(System.now());
        //System.debug('LocationOffset ->'+locationOffset);
        Decimal locationOffSetHours = 0.0;
        locationOffSetHours = (locationOffset / (60 * 60));
        locationOffSetHours = locationOffSetHours/1000;
        //System.debug('locationOffSetHours ->'+locationOffSetHours);

        //Check if both are eqaul then no need to add hours
        if(userOffsetHours == locationOffSetHours){
            return 0.0;
        }

        //Return the difference between user and location offset
        else{
            return userOffsetHours - locationOffSetHours;
        }
    }

    // To create Start Time for Work Order from Duty Template start time(String) and specific date
    public static DateTime createStartDateTime(Date startDate, String timeZone, String startTime){
        // If start time is 3 digit then follow with that numbers of zero
        if(startTime.length()<4){
            startTime = startTime.leftPad((4-startTime.length())+startTime.length(),'0');
        }
        //System.debug('StartTime'+Integer.valueOf(startTime.substring(0,2)));
        //System.debug('StartTime'+Integer.valueof(startTime.substring(2)));

        Decimal toAddHoursDecimal = TDF_WorkOrderUtility.getOffsetHours(timeZone);

        //System.debug('toAddHoursDecimal ->'+toAddHoursDecimal);
        Integer toAddHours = Integer.valueOf(toAddHoursDecimal);
       // System.debug('toAddHoursDecimal ->'+toAddHours);
        Integer startDateHour = Integer.valueOf(startTime.substring(0,2));
        Integer startDateMinutes = Integer.valueof(startTime.substring(2));
        startDateHour += toAddHours;

        //Calculation to add extra minutes in startDateMinutes
        Decimal additionalMinutes = (toAddHoursDecimal - Math.floor(toAddHoursDecimal)) * 100;
        additionalMinutes = additionalMinutes.setScale(4,RoundingMode.HALF_DOWN);
        if(additionalMinutes > 0){
            if(additionalMinutes == 50){
                startDateMinutes += 30;
            }else if(additionalMinutes == 25){
                startDateMinutes += 15;
            }else if(additionalMinutes == 75){
                startDateMinutes += 45;
            }
        }

        //If minutes are more than 60 then add and hour and round of the minutes by 60
        if(startDateMinutes >= 60){
            startDateHour += 1;
            startDateMinutes = Math.mod(startDateMinutes, 60);
        }

        //System.debug('startDateHour k ->'+startDateHour);
       // System.debug('startDateMinutes k->'+startDateMinutes);

        //Timezone issue fix starts here
        // When startDateHour >=24 it essentially is next day, so add another day to the date. When startDateHour <0, it
        // means its run by a user that is in an earlier timezone, so subtract a day.
         // Also, when startDateHour <0, the time needs  to be adjusted to reflect correct offset. -0230 means 2230 technically.
        if(startDateHour >= 24){
            startDate = startDate.addDays(1);
        }
        else if (startDateHour < 0){
            startDate = startDate.addDays(-1);
            startDateHour += 24;
        }
        //timezone  issue fix ends here
       
        //System.debug('startDateMinutes k ->'+startDateMinutes);

        Time sTime = Time.newInstance(startDateHour, startDateMinutes, 0, 0);
        DateTime startDateTime = DateTime.newInstance(startDate, sTime);
        //System.debug('startDateTime ->'+startDateTime);
        return startDateTime;
    }



    //To get Duty Board Assignment for the Assigned Resource for specific date
    public static String getJobBoardAssignment(Date startDate,List<Route_Assignment__c> jbAssignmentList){
        for(Route_Assignment__c objJBAssignment : jbAssignmentList){
            if(objJBAssignment.Start_Date__c <= startDate && objJBAssignment.End_Date__c >= startDate){
                //System.debug('Id service resource '+objJBAssignment.Service_Resource__c);
                return objJBAssignment.Service_Resource__c;
            }
        }
        return null;
    }

    //To get day of date
    public static String getDayOfDate(Date objDate){
        Datetime dt = (DateTime)objDate;
        return dt.format('EEEE');
    }

    //Query work order to get timezone of their location
    public static List<WorkOrder> getWOListWithTimeZone(List<WorkOrder> woList){

        //Set of Work Order Ids
        Set<String> woIds = new Set<String>();
        for(WorkOrder objWO : woList){
            woIds.add(objWO.Id);
        }

        //To prepare dynamic query
        DescribeSObjectResult describeResult = WorkOrder.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        String query = ' SELECT ' + String.join( fieldNames, ',' );
        query += ', Duty_Board__r.Name, Location.TimeZone, Job_Template__r.Location__r.Name, Job_Template__r.Location__r.TimeZone, Job_Template__r.Activity_Type__c, Job_Template__r.Description__c, Job_Template__r.Earliest_Start_Time__c, Job_Template__r.Latest_Start_Time__c, Job_Template__r.Duration__c';
        query += ' FROM ' + describeResult.getName();
        query += ' WHERE Id IN:woIds';
        //System.debug('Query '+query);
        return Database.query(query);
    }

    //get WorkOrder RecordType map with Developer Name and Id
    public static Map<String, String> workOrderRecordTypeMap(){
        Map<String, String> workOrderRTMap = new Map<String, String>();
        for(RecordType objRecordType : [SELECT Id, DeveloperName FROM RecordType WHERE sObjectType = 'WorkOrder']){
            workOrderRTMap.put(objRecordType.DeveloperName, objRecordType.Id);
        }
        return workOrderRTMap;
    }

    //get WorkOrder RecordType map with Id and DeveloperName
    public static Map<String, String> workOrderRecordTypeMapForTrigger(){
        Map<String, String> workOrderRTMap = new Map<String, String>();
        for(RecordType objRecordType : [SELECT Id, DeveloperName FROM RecordType WHERE sObjectType = 'WorkOrder']){
            workOrderRTMap.put(objRecordType.Id, objRecordType.DeveloperName);
        }
        return workOrderRTMap;
    }
}