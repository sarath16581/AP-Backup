/**
* @author Dattaraj Deshmukh
* @date 2022-08-09
* @group PUD
* @tag Wrapper class for PUD_PrintRouteController
* @tag PUD_Route__c
* @domain PUD
* @description - Wrapper class to wrap Routes and its bookings to be used in PUD_PrintRouteController. 
*				 This class is created to be able to use on Apex:Component as a Type attribute. Due to current limitation of Visualforce 
* 				 Component, we cannot use apex:attribute with inner class as a "Type". It requires TOP LEVEL class only.
* @changelog
* 2022-08-09 - created
*/

public inherited sharing class PUD_PrintRouteWrapper {
	public PUD_Route__c route {get; private set;}
	public List<PUD_PrintRouteBookingWrapper> bookings {get; private set;}
	public List<PUD_PrintRouteBookingWrapper> mealBreaks {get; private set;}
	
	public String startTimeString {get; private set;}
	public String endTimeString {get; private set;}

	public PUD_PrintRouteWrapper(PUD_Route__c route) {
		this.route = route;
		this.bookings = new List<PUD_PrintRouteBookingWrapper>();
		this.mealBreaks = new List<PUD_PrintRouteBookingWrapper>();
		this.startTimeString = getDurationDisplayTimeString(route.Start_Time__c);
		this.endTimeString = getDurationDisplayTimeString(route.End_Time__c);


		for(PUD_Booking__c booking: route.Bookings__r) {
			PUD_PrintRouteBookingWrapper b = new PUD_PrintRouteBookingWrapper(booking);
			//add bookings
			this.bookings.add(b);
			
			//add meal break bookings			
			if (b.isMealBreak()) {
				this.mealBreaks.add(b);
			}
		}
	}

	
	/**
	 * @param Time value.
	 * @return Time displayed in String.
	 * @desc Display time in HHMM format.   
	 * e.g. If Time is 9:5 then function returns 0905 as a string. If its 1215 then returns 1215 as a string.
	 */
	public String getDurationDisplayTimeString(Time displayTime){
		String displayTimeString='';

		//if length of hour() component of Time is less than 2, prefix with 0
		if(displayTime !=null && (String.valueOf(displayTime.hour())).length() < 2){
			displayTimeString += ('0'+String.valueOf(displayTime.hour()));
		}
		else{
			displayTimeString += String.valueOf(displayTime.hour());
		}

		//if length of minute() component of Time is less than 2, prefix with 0
		if(displayTime !=null && (String.valueOf(displayTime.minute())).length() < 2){
			displayTimeString += ('0'+String.valueOf(displayTime.minute()));
		}
		else{
			displayTimeString += (''+String.valueOf(displayTime.minute()));
		}
		
		//if length of hour() & minute() component of Time is equal to, return string representation of time.
		if(displayTime !=null && (String.valueOf(displayTime.hour())).length() == 2 && (String.valueOf(displayTime.minute())).length() == 2){
			displayTimeString = String.valueOf(displayTime.hour()) + ''+String.valueOf(displayTime.minute());
		}
		
		return displayTimeString;
	}


}
