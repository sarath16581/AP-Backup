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
	
	public PUD_PrintRouteBookingWrapper(PUD_Booking__c booking) {
		this.booking = booking;
	}
	
	// check if booking is of Meal Type
	public Boolean isMealBreak() {
		return this.booking.Booking_Type__c == PUDConstants.PUD_BOOKING_TYPE_MEAL_BREAK ? true : false;
	}
	
	//getter for startTimeString
	public String getStartTimeString(){
		return PUDPrintUtility.getDurationDisplayX(this.booking.Start_Time__c);
	}

	//getter for endTimeString
	public String getEndTimeString(){
		
		Time endTime;
		String endTimeString='';

		//return blank if startime is null.
		if(this.booking.Start_Time__c == null){
			return endTimeString;
		}
		
		//create a new instance of END TIME from start time and dwell time planned
		if( this.booking.Dwell_Time_Planned__c !=null ){
			endTime = this.booking.Start_Time__c.addMinutes(Time.newInstance(0,(Integer)this.booking.Dwell_Time_Planned__c,0,0).minute());	
		}

		//format endtime in HHMM format
		if(endTime !=null){
			return PUDPrintUtility.getDurationDisplayX(endTime);
		}

		//return blank string if endTime is NULL;
		return endTimeString;
	}
}
