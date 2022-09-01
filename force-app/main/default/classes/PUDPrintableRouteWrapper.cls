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
* 2022-08-31 - Updated - Sorted bookings overnight routes. Bookings on overnight routes appear on top in list on pdf.
*/

public inherited sharing class PUDPrintableRouteWrapper {
	public PUD_Route__c route {get; private set;}
	public List<PUDPrintableBookingWrapper> bookings {get; private set;}
	public List<PUDPrintableBookingWrapper> mealBreaks {get; private set;}

	// List<PUDPrintableBookingWrapper> overnightBookings {get; private set;}
	// List<PUDPrintableBookingWrapper> normalBookings {get; private set;}
	
	
	public PUDPrintableRouteWrapper(PUD_Route__c route) {
		this.route = route;
		this.bookings = new List<PUDPrintableBookingWrapper>();
		this.mealBreaks = new List<PUDPrintableBookingWrapper>();
		// this.overnightBookings = new List<PUDPrintableBookingWrapper>();
		// this.normalBookings = new List<PUDPrintableBookingWrapper>();
		
		for(PUD_Booking__c booking: route.Bookings__r) {
			PUDPrintableBookingWrapper b = new PUDPrintableBookingWrapper(booking);
			
			// //if route is overnight and booking is overnight, add booking to overnight collection
			// if(this.route.Overnight_Route__c && b.isOvernightBooking(this.route.Start_Time__c)){
			// 	this.overnightBookings.add(b);
			// }
			// else{
			// 	this.normalBookings.add(b);
			// }
				
			//if ROUTE is overnight route, check and set overnight flag on booking if booking.Start_Time__c >= Route.Start_Time  
			if(this.route.Overnight_Route__c) {
				b.isOvernightBooking(this.route.Start_Time__c);
			}

			this.bookings.add(b);

			//add meal break bookings			
			if (b.isMealBreak()) {
				this.mealBreaks.add(b);
			}

			//sort bookings
			this.bookings.sort();
		}

		// //adding overnight bookings first as these should appear on top of page whenever Route is overnight
		// if(!this.overnightBookings.isEmpty()){
		// 	this.bookings.addAll(this.overnightBookings);
		// }

		// //adding normal bookings (non-overnight) as these should appear after overnight bookings on a page.
		// if(!this.normalBookings.isEmpty()){
		// 	this.bookings.addAll(this.normalBookings);
		// }
		
	}

	//return Route Start and End time in HHMM format
	// e.g. Startime/endtime will be displayed as 1200 - 1215
	// Scenarios: 1. StartTime & EndTime == NULL, display whitespace.
	//				2. StartTime(1000) != NULL, EndTime = NULL, display '1000 -' 
	//				3. StartTime == NULL, EndTime(1100) != NULL, display ' - 1100' 
	public String getRouteDuration(){
		String startTime = PUDPrintUtility.getDisplayTime(this.route.Start_Time__c);
		String endTime = PUDPrintUtility.getDisplayTime(this.route.End_Time__c);
		
		return PUDPrintUtility.getDuration(startTime, endTime);
	}
	
}