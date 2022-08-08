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
	public List<PUD_Route__c> routes { get; set; }
	public PUD_Route__c route { get; set; }
	//Constructor
	public PUD_PrintRouteController(ApexPages.StandardSetController ssc) {
		//Identify the selected records from Listview
		Set<Id> selectedRouteIDs = new Map<Id, PUD_Route__c>((PUD_Route__c[]) ssc.getSelected()).keySet();
		routes = getSelectedRoutesWithBookings(selectedRouteIDs, new Set<Object>{
				PUDRoutesSelector.Options.WITH_DEPOT
		});
	}
	public PUD_PrintRouteController(ApexPages.StandardController sc) {
		//Identify the selected records from Listview
		Set<Id> selectedRouteIDs = new Set<Id>{
				sc.getId()
		};
		route = getSelectedRoutesWithBookings(selectedRouteIDs, new Set<Object>{
				PUDRoutesSelector.Options.WITH_DEPOT
		})[0];
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
	}

}