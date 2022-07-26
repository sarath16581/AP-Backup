/**
* @author Dheeraj Mandavilli
* @date 2020-03-25
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Controller class to fetch job records from PUD_Job__c object.
* NOTE: This class is used by PUD_FutureJobsPrintView VF Page upon clicking "Print Route" from Routes Detail Page. 
* 2020-03-25 - Dheeraj Mandavilli - Created
* 2020-05-25 - Dheeraj Mandavilli - Updated SOQL to accommodate new cosmetic changes on Vf page
* 2020-06-10 - Dheeraj Mandavilli - Included Time of Print Logic.
* 2022-07-11 - Kamil Szyc - Rebuilt data retrieval using selectors
*/

public with sharing class PUD_JobsPrintFutureControllerX {
	public PUD_Route__c route { get; set; }
	public Date effectiveDate {get;set;}
	// Constructor    
	public PUD_JobsPrintFutureControllerX(ApexPages.StandardController sc){
		effectiveDate = Date.valueOf(ApexPages.currentPage().getParameters().get('date').escapeHtml4());
		String printType = ApexPages.currentPage().getParameters().get('type').escapeHtml4();

		Set<String> groupNameSet = new Set<String>();

		for(GroupMember objCGM : (List<GroupMember>) GroupMembersSelector.newInstance().getMyGroups(new List<String>(),new Set<Object>{GroupMembersSelector.Options.WITH_GROUP},false)){
			groupNameSet.add(objCGM.Group.Name);
		}

		Set<String> bookingTypes = new Set<String>();
		if(printType == 'Perm'){
			bookingTypes.add(PUDConstants.PUD_BOOKING_RECORD_TYPE_PERMANENT_PICKUP_DELIVERY);
		}else if(printType == 'Adhoc'){ // 'Adhoc' type corresponds to modal choice #2: Print Adhoc and Perm Variations, hence we are adding both booking types
			bookingTypes.add(PUDConstants.PUD_BOOKING_RECORD_TYPE_AD_HOC_PICKUP_DELIVERY);
			bookingTypes.add(PUDConstants.PUD_BOOKING_RECORD_TYPE_PERMANENT_PICKUP_DELIVERY);
		}
		route = PUDRoutesSelector.newInstance(PUD_AdhocJobsPrintfromRouteControllerX.jobPrintFieldOverrides).selectByIdWithJobs(
				new Set<Id>{
						sc.getId()
				},
				bookingTypes,
				new Set<Date>{
						effectiveDate
				},
				new Map<Id,Network__c>(NetworksSelector.newInstance().selectByName(groupNameSet)).keySet(),
				false,
				new Set<Object>{
						PUDRoutesSelector.Options.WITH_DEPOT
				})[0];

	}
}