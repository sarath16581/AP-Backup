/**
* @author Dheeraj Mandavilli
* @date 2020-08-10
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Controller class to fectch adhoc job records from PUD_Job__c object.
* NOTE: This class is used by PUD_AdhocJobsNextDay VF Page upon clicking "Adhoc Jobs-Next Day" from Routes List View Page. 
* 2020-08-10 - Dheeraj Mandavilli - Created
 * 2022-07-12 - Kamil Szyc - refactor the controller to use selectors and meet requirements of CUS-72
*/
public with sharing class PUD_AdhocJobsNextDayController {
	public List<PUD_Route__c> routes {get;set;}

	// Constructor    
	public PUD_AdhocJobsNextDayController(ApexPages.StandardSetController ssc){

		Set<String> groupNameSet = new Set<String>();

		for(GroupMember objCGM : (List<GroupMember>) GroupMembersSelector.newInstance().getMyGroups(new List<String>(),new Set<Object>(),false)){
			groupNameSet.add(objCGM.Group.Name);
		}

		routes = PUDRoutesSelector.newInstance(PUD_PrintRouteController.routeFields).selectByIdWithJobs(
				new Map<Id, PUD_Route__c>( (PUD_Route__c[])ssc.getSelected()).keySet(),
				new Set<String>{PUDConstants.PUD_BOOKING_RECORD_TYPE_AD_HOC_PICKUP_DELIVERY},
				new Set<Date>{
						Date.today().addDays(1)
				},
				new Map<Id,Network__c>(NetworksSelector.newInstance().selectByName(groupNameSet)).keySet(),
				new Set<Object>{
						PUDRoutesSelector.Options.WITH_DEPOT, PUDJobsSelector.Options.LIMIT_TO_MY_GROUPS_ONLY
				}, PUD_AdhocJobsPrintfromRouteControllerX.jobFields);

	}
}