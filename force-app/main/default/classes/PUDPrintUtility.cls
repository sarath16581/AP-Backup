/**
* @author Dattaraj Deshmukh
* @date 2022-08-17
* @group PUD
* @tag Utility class
* @tag PUD_Route__c
* @domain PUD
* @description Utility functions for PUD Print implementations
* @changelog 
 * 2022-08-17- Dattaraj Deshmukh - Created
 */
public inherited sharing class PUDPrintUtility {

    /**
     * @param Time value
     * @return String representation of Time in HHMM format.
     * @desc time is prefixed with '0'.  
	 * e.g. If Time is 9 then function returns 09 as a string. If its 12 then returns 12 as a string.
     */
    public static String getDisplayTime(Time displayTime){
        String displayTimeString='';

		//return blank string if time is null
		if(displayTime == null) { return displayTimeString; }

		//if hour() component of Time is less than 10, prefix with 0
		if( displayTime.hour() < 10 ){
			displayTimeString += ('0'+String.valueOf(displayTime.hour()));
		}
		else{
			displayTimeString += String.valueOf(displayTime.hour());
		}

		//if minute() component of Time is less than 10, prefix with 0
		if( displayTime.minute() < 10){
			displayTimeString += ('0'+String.valueOf(displayTime.minute()));
		}
		else{
			displayTimeString += (''+String.valueOf(displayTime.minute()));
		}
		
		return displayTimeString;
    }



	/**
     * @param StarTime, EndTime value
     * @return concatinate StartTime and EndTime with '-'
     * @desc
	 * 		1. StartTime & EndTime == NULL, display whitespace.
	 *		2. StartTime(1000) != NULL, EndTime = NULL, display '1000 -' 
	 *		3. StartTime == NULL, EndTime(1100) != NULL, display ' - 1100' 
     */
	public static String getDuration(String startTime, String endTime){
		String duration = '';

		// return blank if both startTime and endTime is blank
		if(String.isBlank(startTime) && String.isBlank(endTime)){
			return duration;
		}

		// add start time and append with ' - '
		if(String.isNotBlank(startTime)){
			duration += startTime + ' - ';
		}
		else{
			duration += ' - ';
		}
		
		if(String.isNotBlank(endTime)){
			duration += endTime;
		}
		
		return duration;
	}
}
