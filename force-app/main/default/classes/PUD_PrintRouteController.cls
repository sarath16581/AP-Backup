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
 * 2022-08-09 - Dattaraj Deshmukh - Updated class to use wrapper classes for Route and Bookings.
 * 2022-08-31 - Dattaraj Deshmukh - Sorted overnight route bookings to appear on top.
 * 2022-09-14 - Dattaraj Deshmukh - Removed 'Display_Start_Time__c' and added 'Display_ETA_to_Driver__c' in fieldOverrides map 
 */

public with sharing class PUD_PrintRouteController {
	public List<PUDPrintableRouteWrapper> routes {get;set;}
	
	//Constructor
	public PUD_PrintRouteController(ApexPages.StandardSetController ssc) {

		//initialise wrapper list
		routes = new List<PUDPrintableRouteWrapper>();

		//Identify the selected records from Listview
		Set<Id> selectedRouteIDs = new Map<Id, PUD_Route__c>((PUD_Route__c[]) ssc.getSelected()).keySet();
		
		//iterate through routes and build wrapper list for routes, its bookings and meal break bookings
		for(PUD_Route__c route : getSelectedRoutesWithBookings(selectedRouteIDs, new Set<Object>{PUDRoutesSelector.Options.WITH_DEPOT})){
			routes.add(new PUDPrintableRouteWrapper(route));
		}
	}

	public PUD_PrintRouteController(ApexPages.StandardController sc) {
		//initialise wrapper list
		routes = new List<PUDPrintableRouteWrapper>();

		//Identify the selected records from Listview
		Set<Id> selectedRouteIDs = new Set<Id>{
				sc.getId()
		};

		
		//iterate through routes and build wrapper list for routes, its bookings and meal break bookings
		for(PUD_Route__c route : getSelectedRoutesWithBookings(selectedRouteIDs, new Set<Object>{PUDRoutesSelector.Options.WITH_DEPOT})){
			routes.add(new PUDPrintableRouteWrapper(route));
		}
	}
	@TestVisible private static List<PUD_Route__c> getSelectedRoutesWithBookings(Set<Id> routeIds, Set<Object>selectorOptions) {
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				PUD_Route__c.getSObjectType() => new Set <SObjectField>{
						PUD_Route__c.Name, PUD_Route__c.Depot__c,
						PUD_Route__c.Monday__c, PUD_Route__c.Tuesday__c, PUD_Route__c.Wednesday__c, PUD_Route__c.Thursday__c, PUD_Route__c.Friday__c,
						PUD_Route__c.Saturday__c, PUD_Route__c.Sunday__c, PUD_Route__c.Overtime_Allowance__c,
						PUD_Route__c.Start_Time__c, PUD_Route__c.End_Time__c, PUD_Route__c.Start_Date__c, PUD_Route__c.End_Date__c,
						PUD_Route__c.Overnight_Route__c
				},
				PUD_Booking__c.getSObjectType() => new Set <SObjectField>{
						PUD_Booking__c.Id, PUD_Booking__c.Name, PUD_Booking__c.Status__c, PUD_Booking__c.Article_Count__c, PUD_Booking__c.Parent_Booking__c,
						PUD_Booking__c.Route_Lookup__c, PUD_Booking__c.Start_Time__c, PUD_Booking__c.Booking_Comments__c,
						PUD_Booking__c.Display_ETA_to_Driver__c, PUD_Booking__c.Dwell_Time_Planned__c, PUD_Booking__c.Booking_Type__c,
						PUD_Booking__c.Location__c, PUD_Booking__c.Booking_Location_Street__c, PUD_Booking__c.Booking_Location_City__c,
						PUD_Booking__c.Booking_Location_Name_LU__c, PUD_Booking__c.Comments__c, PUD_Booking__c.Key_Number__c, PUD_Booking__c.Dock_Number__c, PUD_Booking__c.Latest_End_Time__c,
						PUD_Booking__c.Monday__c, PUD_Booking__c.Tuesday__c, PUD_Booking__c.Wednesday__c, PUD_Booking__c.Thursday__c, PUD_Booking__c.Friday__c,
						PUD_Booking__c.Saturday__c, PUD_Booking__c.Sunday__c, PUD_Booking__c.Booking_Location__c, PUD_Booking__c.Site_Instructions__c
				}
		};

		return PUDRoutesSelector.newInstance(fieldOverrides).selectByIdWithAllBookings(routeIds, selectorOptions);
	}
}