/**
* @author Dheeraj Mandavilli
* @date 2019-11-28
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Controller class to fectch adhoc job records from PUD_Job__c object.
* NOTE: This class is used by PUD_AdhocJobsPrint VF Page upon clicking "Print Adhoc Jobs" from Routes List View Page. 
* 2019-11-28 - Dheeraj Mandavilli - Created
* 2020-05-25 - Dheeraj Mandavilli - Refactored the Logic to Fetch Depot Id from Logged in User
* 2020-06-10 - Dheeraj Mandavilli - Included Time of Print Logic.
 * 2022-07-12 - Kamil Szyc - refactor the controller to use selectors and meet requirements of CUS-72
*/
public with sharing class PUD_AdhocJobsfromListViewControllerX {
	public List<PUD_Route__c> routes {get;set;}
	// Constructor    
	public PUD_AdhocJobsfromListViewControllerX(ApexPages.StandardSetController ssc){
		routes = new List<PUD_Route__c>();
		Set<String> groupNameSet = new Set<String>();

		for(GroupMember objCGM : (List<GroupMember>) GroupMembersSelector.newInstance().getMyGroups(new List<String>(),new Set<Object>{GroupMembersSelector.Options.WITH_GROUP},false)){
			groupNameSet.add(objCGM.Group.Name);
		}

		for(PUD_Route__c route :  PUDRoutesSelector.newInstance(PUD_AdhocJobsPrintfromRouteControllerX.jobPrintFieldOverrides).selectByIdWithJobs(
				new Map<Id, PUD_Route__c>( (PUD_Route__c[])ssc.getSelected()).keySet(),
				new Set<String>{PUDConstants.PUD_BOOKING_RECORD_TYPE_AD_HOC_PICKUP_DELIVERY},
				new Set<Date>{Date.today()
				},
				new Map<Id,Network__c>(NetworksSelector.newInstance().selectByName(groupNameSet)).keySet(),
				new Set<Object>{
						PUDRoutesSelector.Options.WITH_DEPOT, PUDRoutesSelector.Options.LIMIT_TO_MY_GROUPS_ONLY
				})){
			if(!route.Jobs__r.isEmpty()){
				routes.add(route);
			}
		}

	}
}