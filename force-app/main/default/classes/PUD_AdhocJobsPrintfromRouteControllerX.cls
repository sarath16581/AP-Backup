/**
* @author Dheeraj Mandavilli
* @date 2019-11-19
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain PUD 
* @description Controller class to fectch job records from PUD_Job__c object.
* NOTE: This class is used by PUD_AdhocJobsPrint VF Page upon clicking "Print Adhoc and Perm with variations" from Routes Detail Page. 
* 2019-11-19 - Dheeraj Mandavilli - Created
* 2020-05-25 - Dheeraj Mandavilli - Updated SOQL to accommodate new cosmetic changes on Vf page
* 2020-06-10 - Dheeraj Mandavilli - Included Time of Print Logic.
 * 2022-07-08 - Kamil Szyc - refactor to use the selector
*/
public with sharing class PUD_AdhocJobsPrintfromRouteControllerX {
	public PUD_Route__c route { get; set; }
	public static Map<SObjectType,Set<SObjectField>> jobFields = new Map<SObjectType,Set<SObjectField>>{
			PUD_Job__c.getSObjectType() => new Set<SObjectField> {PUD_Job__c.Start_Time__c, PUD_Job__c.Location_Information__c, PUD_Job__c.Booking_Type_Fx__c, PUD_Job__c.Booking_Comments__c,
			PUD_Job__c.Deliver_Product__c, PUD_Job__c.Key_Number__c}
	};
	// Constructor    
	public PUD_AdhocJobsPrintfromRouteControllerX(ApexPages.standardController sc) {
		
		//Get list of jobs with anything other than permanent record type
		route = PUDRoutesSelector.newInstance(PUD_PrintRouteController.routeFields).selectByIdWithJobs(
				new Set <Id>{
						sc.getId()
				},
				new Set<String>{
						PUDConstants.PUD_BOOKING_RECORD_TYPE_AD_HOC_PICKUP_DELIVERY,
						PUDConstants.PUD_BOOKING_RECORD_TYPE_PERMANENT_PICKUP_DELIVERY

				}, new Set<Date>{
						Date.today()
				},
				new Set<Id>(),
				new Set<Object>{
						PUDRoutesSelector.Options.WITH_DEPOT
				}, jobFields)[0];

	}
}