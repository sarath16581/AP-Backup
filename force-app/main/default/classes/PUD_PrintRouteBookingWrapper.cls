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
	
	public Boolean isMealBreak() {
		return this.booking.Booking_Type__c == PUDConstants.PUD_BOOKING_TYPE_MEAL_BREAK ? true : false;
	}

	public String getDurationDisplayStartTimeString(Time displayTime){
		if( displayTime !=null && (String.valueOf(displayTime.hour())).length() < 2){
			return ('0'+String.valueOf(displayTime.hour()));
		}
		return displayTime !=null ? String.valueOf(displayTime.hour()) : '';
	}

	public String getDurationDisplayEndTimeString(Time startTime, Decimal dwellTimePlanned ){
		Time endTime;
		if( startTime !=null ){
			endTime = startTime.addMinutes(Time.newInstance(0,(Integer)dwellTimePlanned,0,0).minute());	
		}


		if( endTime !=null && (String.valueOf(endTime.hour())).length() < 2){
			String endTimeString;
			endTimeString = '0'+(String.valueOf(endTime.hour()));
			if(String.valueOf(endTime.minute()).length() < 2 ){
				endTimeString+= '0'+String.valueOf(endTime.minute());
			}
			else {
				endTimeString+= String.valueOf(endTime.minute());
			}
			return endTimeString;
		}
		if(endTime !=null && (String.valueOf(endTime.minute())).length() < 2){
			return (String.valueOf(endTime.hour()) + '0'+String.valueOf(endTime.minute()));
		}
		return endTime !=null ? (String.valueOf(endTime.hour()) + ''+String.valueOf(endTime.minute())) : '';
	}
	
}
