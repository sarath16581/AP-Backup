/**
* @author Kamil Szyc
* @date 2022-06-24
* @group PUD
* @tag Controller
* @tag PUD_Route__c
* @domain PUD
* @description Controller class to for printing CCP routes with bookings.
 * @changelog
 * 2022-06-24 - created
 */

public with sharing class PUD_PrintRouteController {
	//public List<PUD_Route__c> routes { get; set; }
	//public PUD_Route__c route { get; set; }

	public List<PUD_PrintRouteWrapper> routes {get;set;}

	//Constructor
	public PUD_PrintRouteController(ApexPages.StandardSetController ssc) {

		//initialise wrapper list
		routes = new List<PUD_PrintRouteWrapper>();

		//Identify the selected records from Listview
		Set<Id> selectedRouteIDs = new Map<Id, PUD_Route__c>((PUD_Route__c[]) ssc.getSelected()).keySet();
		
		//iterate through routes and build wrapper list for routes, its bookings and meal break bookings
		for(PUD_Route__c route : getSelectedRoutesWithBookings(selectedRouteIDs, new Set<Object>{PUDRoutesSelector.Options.WITH_DEPOT})){
			routes.add(new PUD_PrintRouteWrapper(route));
		}
		
		// routes = getSelectedRoutesWithBookings(selectedRouteIDs, new Set<Object>{
		// 		PUDRoutesSelector.Options.WITH_DEPOT
		// });
	}
	public PUD_PrintRouteController(ApexPages.StandardController sc) {
		//initialise wrapper list
		routes = new List<PUD_PrintRouteWrapper>();

		//Identify the selected records from Listview
		Set<Id> selectedRouteIDs = new Set<Id>{
				sc.getId()
		};

		
		//iterate through routes and build wrapper list for routes, its bookings and meal break bookings
		for(PUD_Route__c route : getSelectedRoutesWithBookings(selectedRouteIDs, new Set<Object>{PUDRoutesSelector.Options.WITH_DEPOT})){
			routes.add(new PUD_PrintRouteWrapper(route));
		}
		
		// routes = getSelectedRoutesWithBookings(selectedRouteIDs, new Set<Object>{
		// 		PUDRoutesSelector.Options.WITH_DEPOT
		// });
	}
	@TestVisible private static List<PUD_Route__c> getSelectedRoutesWithBookings(Set<Id> routeIds, Set<Object>selectorOptions) {
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				PUD_Route__c.getSObjectType() => new Set <SObjectField>{
						PUD_Route__c.Name, PUD_Route__c.Depot__c,
						PUD_Route__c.Monday__c, PUD_Route__c.Tuesday__c, PUD_Route__c.Wednesday__c, PUD_Route__c.Thursday__c, PUD_Route__c.Friday__c,
						PUD_Route__c.Saturday__c, PUD_Route__c.Sunday__c, PUD_Route__c.Overtime_Allowance__c,
						PUD_Route__c.Start_Time__c, PUD_Route__c.End_Time__c, PUD_Route__c.Start_Date__c, PUD_Route__c.End_Date__c
				},
				PUD_Booking__c.getSObjectType() => new Set <SObjectField>{
						PUD_Booking__c.Id, PUD_Booking__c.Name, PUD_Booking__c.Status__c, PUD_Booking__c.Article_Count__c, PUD_Booking__c.Parent_Booking__c,
						PUD_Booking__c.Route_Lookup__c, PUD_Booking__c.Start_Time__c, PUD_Booking__c.Booking_Comments__c,
						PUD_Booking__c.Display_Start_Time__c, PUD_Booking__c.Dwell_Time_Planned__c, PUD_Booking__c.Booking_Type__c,
						PUD_Booking__c.Location__c, PUD_Booking__c.Booking_Location_Street__c, PUD_Booking__c.Booking_Location_City__c,
						PUD_Booking__c.Booking_Location_Name_LU__c, PUD_Booking__c.Comments__c, PUD_Booking__c.Key_Number__c, PUD_Booking__c.Dock_Number__c, PUD_Booking__c.Latest_End_Time__c,
						PUD_Booking__c.Monday__c, PUD_Booking__c.Tuesday__c, PUD_Booking__c.Wednesday__c, PUD_Booking__c.Thursday__c, PUD_Booking__c.Friday__c,
						PUD_Booking__c.Saturday__c, PUD_Booking__c.Sunday__c, PUD_Booking__c.Booking_Location__c, PUD_Booking__c.Booking_Location__c, PUD_Booking__c.Site_Instructions__c
				}
		};
		return PUDRoutesSelector.newInstance(fieldOverrides).selectByIdWithAllBookings(routeIds, selectorOptions);


		//return null;
	}

	public class Route {
		public PUD_Route__c route {get; private set;}
		public List<PUD_PrintRouteBookingWrapper> bookings {get; private set;}
		public List<PUD_PrintRouteBookingWrapper> mealBreaks {get; private set;}
	 
		public Route(PUD_Route__c route) {
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
	}
	 
	public class Booking {
		public PUD_Booking__c booking {get; private set;}
	 
		public Booking(PUD_Booking__c booking) {
			this.booking = booking;
		}
	 
		public Boolean isMealBreak() {
			return this.booking.Booking_Type__c == PUDConstants.PUD_BOOKING_TYPE_MEAL_BREAK ? true : false;
		}
	 
		// public String getDurationDisplayTimeString() {
		//    '0800 - 0830'
		// }
	 
	}

}