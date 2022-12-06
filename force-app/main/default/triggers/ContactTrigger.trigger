/*------------------------------------------------------------------------------
Author:         Initial author unknown
Company:        Australia Post
Description:    Existing Contact trigger evolved and enhanced over multiple
                implementations / projects.

History
<Date>      <Authors Name>      <Brief Description of Change>
2-JUN-2016  Kenny Liew          Updated Contact trigger for MyPost Business, to
                                call MyPostBusinessLeadConvert.convertLead for
                                converting Leads to existing Accounts + Contacts
                                provisioned prior via TIBCO integration.
16-JUL-2019 Andrew Judd			Added before Delete to call function deleteConApps
05-MAR-2020 Alex Volkov			Added setMailingAddress call before insert
01-AUG-2022 Kamil Szyc          Added reparentToNewAccount call after update
2022-08-29 - Nathan Franklin - Moved reparentToNewAccount into domain framework

@Test ContactTrigger_Test 
------------------------------------------------------------------------------*/

trigger ContactTrigger on Contact (before insert, before update, after insert, after update, before Delete) {

    if(!TriggerHelper.isTriggerDisabled(String.valueOf(Contact.SObjectType))) {
		ContactDomainTriggerHandler.newInstance().dispatch();
	}

	// ************************************************* WARNING *************************************************************
	// WARNING: Please do not use the approach below. All new functionalities should be done using the Handler method above.
	// ************************************************* WARNING *************************************************************


	system.debug('####################################### Contact trigger: ' + SystemSettings__c.getInstance().Disable_Triggers__c + '#######################################');
	if (!SystemSettings__c.getInstance().Disable_Triggers__c)
	{
		if(trigger.isInsert){
			if(trigger.isBefore){
				system.debug('####################################### isInsert & isBefore #####################################');
				ContactUtility.setMailingAddress(Trigger.new);
				ContactUtility.generateReversePhoneFields(trigger.new);
				ContactUtility.onDeleteLockedSet(trigger.new, trigger.oldMap);
			}

			if(trigger.isAfter){
				system.debug('####################################### isInsert & isAfter #####################################');
				/* START MPB Lead Enhancement 27-07-2016 */
				if(!System.isFuture()) {

					// Loop through the map, and only run this function if the CampaignMemberId field is not null on any of the records.
					Set<Id> targetedContactIds = new Set<Id>();

					for (Contact contactRec : Trigger.New) {
						if (contactRec.MPB_Campaign_Member_Id__c != null && contactRec.MPB_Campaign_Member_Id__c != '') {
							targetedContactIds.add(contactRec.Id);
						}
					}
					// Added if to prevent future method call without value in targetedContactIds - Disha on 16 April 2018
					if(targetedContactIds.size()>0){
						MyPostBusinessLeadConvert.convertLead(targetedContactIds);}
				}
				/* END MPB Lead Enhancement 27-07-2016 */
			}
		}
		if(trigger.isUpdate){
			if(trigger.isBefore){
				system.debug('####################################### isUpdate & isBefore #####################################');

				ContactUtility.generateReversePhoneFields(trigger.newMap, trigger.oldMap);
				ContactUtility.checkContactEmail(trigger.new, trigger.oldMap);
				ContactUtility.onDeleteLockedSet(trigger.new, trigger.oldMap);
			}

			if(trigger.isAfter){
				system.debug('####################################### isUpdate & isAfter #####################################');

				ContactUtility.updateUserDetails(trigger.newMap, trigger.oldMap);
			}
		}
		if(trigger.isDelete){
			if(trigger.isBefore ){
				system.debug('####################################### isDelete & isBefore #####################################');
				ContactUtility.raiseErrorIfRestrictedDelete(trigger.old);
				//BAM A.Judd 17-07-2019 Call utility to delete Contact Apps on delete of Contact
				ContactUtility.deleteConApps(trigger.old, trigger.oldMap);
			}
		}
	}
}