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
	public Date effectiveDate {get;set;}
	
	
	// Constructor    
	public PUD_AdhocJobsPrintfromRouteControllerX(ApexPages.standardController sc) {
		effectiveDate = Date.today();
		route = new PUD_Route__c();
		Set<String> groupNameSet = new Set<String>();

		for(GroupMember objCGM : (List<GroupMember>) GroupMembersSelector.newInstance().getMyGroups(new List<String>(),new Set<Object>{GroupMembersSelector.Options.WITH_GROUP},false)){
			groupNameSet.add(objCGM.Group.Name);
		}
		//Get list of jobs with anything other than permanent record type
		List<PUD_Route__c> routes = PUDRoutesSelector.newInstance(PUDConstants.PUD_JOB_PRINT_FIELDS).selectByIdAndDepotWithJobs(
				new Set <Id>{
						sc.getId()
				},
				new Map<Id, Network__c>(NetworksSelector.newInstance().selectByName(groupNameSet)).keySet(),
				new Set<String>{
						PUDConstants.PUD_BOOKING_RECORD_TYPE_AD_HOC_PICKUP_DELIVERY,
						PUDConstants.PUD_BOOKING_RECORD_TYPE_PERMANENT_PICKUP_DELIVERY

				},
				new Set<Date>{
						effectiveDate
				},
				new Set<Object>{
						PUDRoutesSelector.Options.WITH_DEPOT
				}
		);
		
		if(routes != null && !routes.isEmpty()){
			route = routes[0];
		}

	}
}