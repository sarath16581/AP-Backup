/**
* @author Dattaraj Deshmukh
* @date 2022-08-09
* @group PUD
* @tag Wrapper class for PUD_PrintRouteController
* @tag PUD_Route__c
* @domain PUD
* @description - Wrapper class to wrap bookings to be used in PUD_PrintRouteController. 
*				 This class is created to be able to use on Apex:Component as a Type attribute. Due to current limitation of Visualforce 
* 				 Component, we cannot use apex:attribute with inner class as a "Type". It requires TOP LEVEL class only.
* @changelog
* 2022-08-09 - created
*/

public inherited sharing class PUD_PrintRouteBookingWrapper {
  
	public PUD_Booking__c booking {get; private set;}
	public String startTimeString {get; private set;}
	public String endTimeString {get; private set;}
	
	public PUD_PrintRouteBookingWrapper(PUD_Booking__c booking) {
		this.booking = booking;
		this.startTimeString = getDurationDisplayStartTimeString(booking.Start_Time__c);
		this.endTimeString = getDurationDisplayEndTimeString(booking.Start_Time__c, booking.Dwell_Time_Planned__c);
	}
	
	// check if booking is of Meal Type
	public Boolean isMealBreak() {
		return this.booking.Booking_Type__c == PUDConstants.PUD_BOOKING_TYPE_MEAL_BREAK ? true : false;
	}

	
	/**
	 * @param Time value.
	 * @return Time displayed in String.
	 * @desc time is prefixed with '0'.  
	 * e.g. If Time is 9 then function returns 09 as a string. If its 12 then returns 12 as a string.
	 */
	public String getDurationDisplayStartTimeString(Time displayTime){
		
		String displayTimeString='';

		//return blank string if time is null
		if(displayTime == null) { return displayTimeString; }

		//if length of hour() component of Time is less than 2, prefix with 0
		if((String.valueOf(displayTime.hour())).length() < 2){
			displayTimeString += ('0'+String.valueOf(displayTime.hour()));
		}
		else{
			displayTimeString += String.valueOf(displayTime.hour());
		}

		//if length of minute() component of Time is less than 2, prefix with 0
		if((String.valueOf(displayTime.minute())).length() < 2){
			displayTimeString += ('0'+String.valueOf(displayTime.minute()));
		}
		else{
			displayTimeString += (''+String.valueOf(displayTime.minute()));
		}
		
		//if length of hour() & minute() component of Time is equal to, return string representation of time.
		if((String.valueOf(displayTime.hour())).length() == 2 && (String.valueOf(displayTime.minute())).length() == 2){
			displayTimeString = String.valueOf(displayTime.hour()) + ''+String.valueOf(displayTime.minute());
		}
		
		return displayTimeString;
	}

	
	/**
	 * @param Start Time value, Dwelled Time.
	 * @return Time displayed in String.
	 * @desc Start Time and Dwell Time is passed to calculate end time. 
	 * End time is prefixed with '0'.  
	 * e.g. If Time is 9 then function returns 09 as a string. If its 12 then returns 12 as a string.
	 */
	public String getDurationDisplayEndTimeString(Time startTime, Decimal dwellTimePlanned ){
		Time endTime;
		String endTimeString='';

		//return blank if startime is null.
		if(startTime == null){
			return endTimeString;
		}
		
		//create a new instance of END TIME from start time and dwell time planned
		if( dwellTimePlanned !=null ){
			endTime = startTime.addMinutes(Time.newInstance(0,(Integer)dwellTimePlanned,0,0).minute());	
		}

		//format endtime in HHMM format
		if(endTime !=null){
			return getDurationDisplayStartTimeString(endTime);
		}

		//return blank string if endTime is NULL;
		return endTimeString;
	}
	
}
