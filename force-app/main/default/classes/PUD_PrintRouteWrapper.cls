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
	
	public PUD_PrintRouteWrapper(PUD_Route__c route) {
		this.route = route;
		this.bookings = new List<PUD_PrintRouteBookingWrapper>();
		this.mealBreaks = new List<PUD_PrintRouteBookingWrapper>();
		
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

	//getter for startTimeString
	//return time in HHMM format
	public String getStartTimeString(){
		return PUDPrintUtility.getDurationDisplayX(this.route.Start_Time__c);
	}

	//getter for endTimeString
	//return time in HHMM format
	public String getEndTimeString(){
		return PUDPrintUtility.getDurationDisplayX(this.route.End_Time__c);
	}
	
}
