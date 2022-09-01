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
* 2022-08-09 - created - Dattaraj Deshmukh
* 2022-08-31 - Updated - Added compareTo() logic to sort Bookings for overnight routes. Bookings on overnight routes appear on top in list on pdf.
*/

public inherited sharing class PUDPrintableBookingWrapper implements Comparable{
  
	public PUD_Booking__c booking {get; private set;}
	Boolean overnightBooking {get; private set;}
	
	public PUDPrintableBookingWrapper(PUD_Booking__c booking) {
		this.booking = booking;
		this.overnightBooking = false;
	}
	
	//check if booking is for overnight route.
	//overnight bookings are appeared on top of Print Board pdf page.
	public Boolean isOvernightBooking(Time routeStartTime){
		this.overnightBooking = this.booking.Start_Time__c >= routeStartTime ? true : false;
		return overnightBooking;
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
		
		Time endTime;
		String endTimeString='';

		//return blank if startime is null.
		if(this.booking.Start_Time__c == null){
			return endTimeString;
		}
		
        endTime = this.calculateEndTime();

		//format endtime in HHMM format
		if(endTime !=null){
			return PUDPrintUtility.getDisplayTime(endTime);
		}

		//return blank string if endTime is NULL;
		return endTimeString;
	}

    private Time calculateEndTime(){
        Time endTime;

        //create a new instance of END TIME from start time and dwell time planned
		if( this.booking.Dwell_Time_Planned__c !=null ){
			endTime = this.booking.Start_Time__c.addMinutes(Time.newInstance(0,(Integer)this.booking.Dwell_Time_Planned__c,0,0).minute());	
		}
        return endTime;
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

	/**
	 * @desc: * By default bookings are sorted as per Start Time.
	 * compareTo() method is used to sort overnight bookings within bookings list.
	 * For overnight route, Overnight bookings should appear before normal day bookings.
	 * 		
	 */
	public Integer compareTo(Object compareTo) {
		PUDPrintableBookingWrapper compareToBooking = (PUDPrintableBookingWrapper)compareTo;

		//if booking being compared is overnight booking and its start time is greater than current booking
		if(compareToBooking.overnightBooking && compareToBooking.booking.Start_Time__c > this.booking.Start_Time__c){

			//if current booking is also overnight and its start time is < overnight booking being compared then, return -1
			//ie. Bookings at 2200 and 1130 are both overnights but 2200 should appear first hence returning -1 will make
			// booking at 2200 return before 1130 as its 2200 < 1130.  
			if(this.overnightBooking && this.booking.Start_Time__c< compareToBooking.booking.Start_Time__c){
				return -1;
			}
			return 1;
		}
		else{
			return 0;
		}	
	}
}
