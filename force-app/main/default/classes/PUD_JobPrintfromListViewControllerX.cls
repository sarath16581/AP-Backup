/**
* @author Dheeraj Mandavilli
* @date 2019-11-28
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Controller class to fetch job records from PUD_Job__c object.
* NOTE: This class is used by PUD_JobPrint VF Page upon clicking "Print All Jobs" from Routes List View Page. 
* 2019-11-28 - Dheeraj Mandavilli - Created
* 2020-05-25 - Dheeraj Mandavilli - Refactored the Logic to Fetch Depot Id from Logged in User
* 2020-06-10 - Dheeraj Mandavilli - Included Time of Print Logic.
 * 2022-07-12 - Kamil Szyc - rebuilt the controller to use selectors and meet CUS-72 requirements
*/
public with sharing class PUD_JobPrintfromListViewControllerX {

	public List<PUD_Route__c> routes {get;set;}
	// Constructor    
	public PUD_JobPrintfromListViewControllerX(ApexPages.StandardSetController ssc){

		Set<String> groupNameSet = new Set<String>();
		
		for(GroupMember objCGM : (List<GroupMember>) GroupMembersSelector.newInstance().getMyGroups(new List<String>(),new Set<Object>(),false)){
			groupNameSet.add(objCGM.Group.Name);
		}

		routes = PUDRoutesSelector.newInstance(PUD_PrintRouteController.routeFields).selectByIdWithJobs(
				new Map<Id, PUD_Route__c>( (PUD_Route__c[])ssc.getSelected()).keySet(),
				new Set<String>(),
				new Set<Date>{
						Date.today()
				},
				new Map<Id,Network__c>(NetworksSelector.newInstance().selectByName(groupNameSet)).keySet(),
				new Set<Object>{
						PUDRoutesSelector.Options.WITH_DEPOT
				}, PUD_AdhocJobsPrintfromRouteControllerX.jobFields);
		
	}

}