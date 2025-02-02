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
* 2022-08-09 - Dattaraj Deshmukh - created 
*/

public inherited sharing class PUDPrintableBookingWrapper {
  
	public PUD_Booking__c booking {get; private set;}
	
	public PUDPrintableBookingWrapper(PUD_Booking__c booking) {
		this.booking = booking;
	}

	// check if booking is of Meal Type
	public Boolean isMealBreak() {
		return this.booking.Booking_Type__c == PUDConstants.PUD_BOOKING_TYPE_MEAL_BREAK ? true : false;
	}
	
	//getter for startTimeString
	public String getStartTimeString(){
		return PUDPrintUtility.getDisplayTime(this.booking.Start_Time__c);
	}

	//getter for endTimeString
	public String getEndTimeString(){
		
		if (this.booking.Start_Time__c != null && this.booking.Dwell_Time_Planned__c !=null) {
			Time endTime = this.booking.Start_Time__c.addMinutes((Integer) this.booking.Dwell_Time_Planned__c);
			//format endtime in the required format
			return PUDPrintUtility.getDisplayTime(endTime);
		}

		//return blank if endTime cannot be calculated
		return '';
	}

	//return Booking Start and End time in HHMM format
	// e.g. Startime/endtime will be displayed as 1200 - 1215
	// Scenarios: 1. StartTime & EndTime == NULL, display whitespace.
	//				2. StartTime(1000) != NULL, EndTime = NULL, display '1000 -' 
	//				3. StartTime == NULL, EndTime(1100) != NULL, display ' - 1100' 
	public String getBookingDuration(){
		String startTime = getStartTimeString();
		String endTime = getEndTimeString();
		
		return PUDPrintUtility.getDuration(startTime, endTime);
	}

}