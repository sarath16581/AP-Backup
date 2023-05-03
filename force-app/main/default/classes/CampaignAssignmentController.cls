/**
 * @author Mathew Jose
 * @date 2021-12-21
 * @group Campaign Feedback
 * @description Controller for Campaign contact assignments to facilitate campaign feedback survey.
 * @changelog
 * 2021-08-02 - Mathew Jose - Created
 * 2022-05-16 - Prerna Rahangdale - Modified to show the Campaign Contact Assginment records to the CCA owner user field
 *              value from the CCA record.
 * 2023-05-04 - Talib Raza - INC2125102: introduced for loop to fix the "Aggregate query has too many rows for direct assignment" error.
*/
public with sharing class CampaignAssignmentController {
	
	/**
	 * To retrieve all accounts owned by the current user (Accout Manager)
	 * 
	 * @param campaign record Id.
	 * @return List of AccountCampaignContactWrappers relevant to the campaign
	 */
	@AuraEnabled(cacheable=true)
	public static List<AccountCampaignContactWrapper> getCampaignContactAssignments(String campaignId) {

		//get campaign, campaign contact assignments making sure we only get campaign member records with a Contact Id
		Campaign campaignWithContactAssignmentsAndMembers = CampaignsSelector.newInstance(1).selectById(
				new Set<Id>{campaignId},
				new Set<Object>{
						CampaignsSelector.Options.WITH_CAMPAIGNMEMBERS,
						CampaignsSelector.Options.WITH_CONTACTASSIGMENTS,
						CampaignMembersSelector.Options.FILTER_CONTACTS_ONLY,
						CampaignMembersSelector.Options.WITH_CONTACT
				}
		)[0];
		// INC2125102: Introduced for loop to fix the "Aggregate query has too many rows for direct assignment" error.
		List<CampaignContactAssignment__c> campaignConAssignments = new List<CampaignContactAssignment__c>();
		for (Campaign_Contact_Assignment__c assignment : campaignWithContactAssignmentsAndMembers.Campaign_Contact_Assignments__r) {
			campaignConAssignments.add(assignment);
		}
		
		List<CampaignMember> campaignMembers = new List<CampaignMember>();
		for (CampaignMember member : campaignWithContactAssignmentsAndMembers.CampaignMembers) {
			campaignMembers.add(member);
		}

		Map<Id, CampaignMember> contactCampaignMemberMap = new Map<Id, CampaignMember>();
		if(campaignMembers != null){
			for(CampaignMember cm : campaignMembers){
				contactCampaignMemberMap.put(cm.ContactId,cm);
			}	
		}

		//Set the CampaignContactAssignment wrapper to be displayed on the datatable.
		if(campaignConAssignments != null){
			Map<String, AccountCampaignContactWrapper> accountIdToCampaignContactWrapperMap = new Map<String, AccountCampaignContactWrapper>();
			for(CampaignContactAssignment__c cca : campaignConAssignments){
				// Show the records if the logged in user is a campaign Owner or a user in the CCA record. Else Follow back to AccountManager Owner
				if((cca.Campaign_Contact_Owner__c != null && cca.Campaign_Contact_Owner__c == UserInfo.getUserId())
						|| cca.Organisation__r.OwnerId == UserInfo.getUserId() || cca.Campaign__r.OwnerId == UserInfo.getUserId()) {
					AccountCampaignContactWrapper acw = new AccountCampaignContactWrapper();
					acw.assignmentId = cca.Id;
					acw.assignmentDefaultStatus = campaignWithContactAssignmentsAndMembers?.ContactAssignmentDefaultStatus__c;
					acw.accountName = cca.Organisation__r.Name;
					acw.accountId = cca.Organisation__c;
					acw.campaignContactId = cca.Contact__c;
					acw.campaignContactDescription = cca.Description__c;
					acw.campaignMemberStatus = contactCampaignMemberMap.get(cca.Contact__c)?.Status;
					acw.campaignMemberId = contactCampaignMemberMap.get(cca.Contact__c)?.Id;
					acw.campaignContactOwner = cca.Campaign_Contact_Owner__r.Name;
					accountIdToCampaignContactWrapperMap.put(cca.Organisation__c,acw);
				}
			}
			return accountIdToCampaignContactWrapperMap.values();

		} else {
			return null;
		}

	}

	/**
	 * To update the campaign contact assignments provided the contacts are populated / removed.
	 * 
	 * @param assignments List of AccountCampaignContactWrapper updated with contact lookup values.
	 * @return String value which specifies successful execution of updates to the assignments.
	 */  
	@AuraEnabled
	public static void updateCampaignContactAssignments(List<AccountCampaignContactWrapper> assignments){ 
		List<CampaignContactAssignment__c> campaignContactAssignmentsToUpdate = new List<CampaignContactAssignment__c>();
		try {
			//Loop through the list of wrapper to identify the records to be updated.
			if(!assignments.isEmpty()){
				for(AccountCampaignContactWrapper aWrap : assignments){
					if(!String.isBlank(aWrap.assignmentId)){
						System.debug('Campaign Contact Id'+aWrap.campaignContactId);
						CampaignContactAssignment__c assignmentToUpdate = new CampaignContactAssignment__c();
						assignmentToUpdate.Id = aWrap.assignmentId;
						Id contactId = !(String.isBlank(aWrap.campaignContactId)) ? aWrap.campaignContactId : null;
						assignmentToUpdate.Contact__c = contactId;
						campaignContactAssignmentsToUpdate.add(assignmentToUpdate);
					}
				}
			}
			if(!campaignContactAssignmentsToUpdate.isEmpty()){
				ApplicationDatabase.getInstance().dmlUpdate(campaignContactAssignmentsToUpdate);
			}
		} catch(Exception e) {
			System.debug(LoggingLevel.ERROR, e.getMessage());
			throw new AuraHandledException(e.getMessage());
		}
		
	}
	/**
	 * Wrapper class to facilitate the presentation of contact assignments in the datatable.
	 */  
	public class AccountCampaignContactWrapper {
		@AuraEnabled public String assignmentId {get;set;}
		@AuraEnabled public String assignmentDefaultStatus {get;set;}
		@AuraEnabled public String accountName {get;set;}
		@AuraEnabled public String accountId {get;set;}
		@AuraEnabled public String campaignContactId {get;set;}
		@AuraEnabled public String campaignMemberId {get;set;}
		@AuraEnabled public String campaignMemberStatus {get;set;}
		@AuraEnabled public String campaignContactDescription {get;set;}
		@AuraEnabled public String campaignContactOwner{get;set;}
	}

}