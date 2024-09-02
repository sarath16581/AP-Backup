/**
 * @author Hasantha Liyanage
 * @date 2022-06-06
 * @group Chas
 * @tag productAndServices
 * @tag DDS-10974
 * @domain Help & Support
 * @description DDS-10974 This class contains common methods used across all the controllers in the chas context,
 * This has been created as a part of refactoring of chas apex controller. This will help grouping all the
 * common methods together and breaking down all the other main methods in the chasApexController in to individual classes by extending.
 * @changelog
 * 2022-06-06 - Hasantha Liyanage - Created
 * 2022-07-15 - Hasantha Liyanage - DDS-11324 added support for unit test mocking
 * 2024-08-16 - Talib Raza - PRB0051724, REQ3488651: Setting Root Cause to Awaiting Network Response for Direct to network cases. 
 */
public virtual inherited sharing class ChasBase {

	/**
	 * Grabs an instance of this class
	 * Using Application.Utilities allows us to override this interface with a mock class for unit testing
	 */
	public static ChasBase getInstance() {
		return (ChasBase)Application.Utilities.getInstance(ChasBase.class);
	}

	public enum RoutingBypass {
		NETWORK, HOLD
	}

	//-- Case Wrapper Class
	public class CaseWrapper {
		@AuraEnabled public String caseNumber { get; set; }
		@AuraEnabled public String caseStatus { get; set; }
	}

	/**
* @description     get the Contact Id of the provided User Id
* @param           Id i.e. User Id
* @return          Id i.e. Contact Id for the user
*/
	public static Id getContactId(Id userId) {
		return UsersSelector.newInstance().selectById(new Set<Id>{userId}).values()[0].ContactId;
	}

	/**
 * @description Helper class containing methods that need to bypass sharing settings
 */
	public without sharing class SharingBypass {
		public SharingBypass getInstance() {
			return (SharingBypass)Application.Utilities.getInstance(SharingBypass.class);
		}
		/**
		 * @description Method querying network Id by Org Id and Contact Facility
		 * @param orgId Organisation Id
		 * @return Id Network Id
		 */
		public Id getNetworkIdByOrgId(String orgId) {
			List<Network__c> networks = [
					SELECT Id
					FROM Network__c
					WHERE Org_ID__c = :orgId
					AND Contact_Facility__c = 'MyNetwork'
					LIMIT 1
			];
			return networks.isEmpty() ? null : networks[0].Id;
		}

		/**
		* @description Method inserting SObjects
		* @param pSObjects SObject List of SObject records to insert
		* @return List<Database.SaveResult> DML results
		*/
		public List<Database.SaveResult> insertSObjects(List<SObject> pSObjects) {
			//return Database.insert(pSObjects);
			return ApplicationDatabase.getInstance().dmlInsert(pSObjects);
		}

		/**
		* @description Method generating a case comment with required visibility
		* @param pBody comment body
		* @param pPublicFlag public visibility flag
		* @return CaseComment resulting case comment
		*/
		public CaseComment generateCaseComment(String pBody, Boolean pPublicFlag) {
			return new CaseComment(CommentBody = pBody, IsPublished = pPublicFlag);
		}

		/**
	* Create Parse Case inserted results and create case comment
	* */
		public CaseWrapper parseInsertedCaseResultsAndCreateComment(Database.SaveResult[] results, CaseWrapper caseWrapperObj, List<CaseComment> comments) {
			Set<Id> vCaseIds = new Set<Id>();
			for (Integer i = 0; i < results.size(); i++) {
				if (results[i].isSuccess()) {
					try {
						Id lObjectId = Id.valueOf(results[i].getId());
						String objName = lObjectId.getSobjectType().getDescribe().getName();
						//-- Creating Case Comment for inserted Case
						if (objName.equalsIgnoreCase('Case')) {
							// create comment body
							for (CaseComment cc : comments) {
								cc.CommentBody = '---Enquiry Details---' + '\n' + cc.CommentBody;
								cc.ParentId = lObjectId;
							}
							// create case comment record

							ApplicationDatabase.getInstance().dmlInsert(comments);
							vCaseIds.add(lObjectId);
						}

					} catch (Exception ex) {
						System.debug('*** - Error while retrieving Case Number/Creating Case Comment ===' + ex);
						UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'CHAS', 'ChasBase', 'parseInsertedCaseResultsAndCreateComment', '', LoggingLevel.ERROR);
					}

				} else {
					caseWrapperObj.caseStatus = 'ERROR';
					System.debug('Error: could not create sobject ' + 'for array element ' + i + '.');
					System.debug('The error reported was: ' + results[i].getErrors()[0].getMessage() + '\n');
				}
			}

			if(!Test.isRunningTest()) {
				caseWrapperObj.caseNumber = CasesSelector.newInstance().selectById(vCaseIds).get(new List<Id>(vCaseIds)[0]).CaseNumber;
			}

			return caseWrapperObj;
		}
	}

	public static Boolean noNetworkIdFound = false;                // flag for no network ID found in setDirectRoutingValues
	public static String unavailableOrgId;                         // org ID that is unavailable
	public static Boolean noNetworkGroupFound = false;             // flag for no network group found in setDirectRoutingValues
	/**
	 * @description Sets case owner, status and flags when routing rules need to be bypassed
	 * @param pCase Case to route directly bypassing the routing engine
	 * @param pBypass Type of bypass
	 * @param pOrgId Organisation Id for network cases
	 */
	public static void setDirectRoutingValues(Case pCase, final RoutingBypass pBypass, final String pOrgId) {
		if (pBypass == RoutingBypass.NETWORK) {
			pCase.Automated_Network_Assignment__c = true;
			SharingBypass vSharingBypass = new SharingBypass();
			Id vNetworkId = vSharingBypass.getNetworkIdByOrgId(pOrgId);
			if (vNetworkId != null) {

				pCase.Status = SSSWConstants.STAT_AWAITING_NTWRK_RESPONSE;
				pCase.Network__c = vNetworkId;
				Map<Id, Group> vGroups = GroupsSelector.newInstance().selectByDeveloperName(new Set<String>{
						SSSWConstants.QUEUE_DEV_NAME_SSSWNETWORKQUEUE
				});
				if (!vGroups.isEmpty()) {
					pCase.OwnerId = vGroups.values()[0].Id;
					pCase.Root_cause__c = SSSWConstants.CASE_ROOT_CAUSE_SSSW_NETWORK_QUEUE;
					pCase.Sent_To_Network_Date__c = System.now();
					pCase.ByPassRoutingRulesOnCreation__c = true;
					pCase.AllocateToQueue__c = false;
				} else {
					// set the flag for case comment after case inserted
					noNetworkGroupFound = true;
				}
				//Need to explicitly add description from rules due to routing bypass
				SSSW_Routing.populateCaseDescriptionFromDescriptionRules(new List<Case>{
						pCase
				}, null);
			} else {
				// set the flag for case comment after case inserted
				noNetworkIdFound = true;
				unavailableOrgId = pOrgId;
			}
		} else if (pBypass == RoutingBypass.HOLD) {
			Map<Id, Group> vGroups = GroupsSelector.newInstance().selectByDeveloperName(new Set<String>{
					SSSWConstants.QUEUE_NAME_REOPEN_Q
			});
			if (!vGroups.isEmpty()) {
				pCase.OwnerId = vGroups.values()[0].Id;
				Date reopenDate = BusinessHoursService.newInstance().calculateNextBusinessDay(pCase.EstimatedDelivery__c, Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c != null ? Integer.valueOf(Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c) : 0);
				pCase.Status = SSSWConstants.CASE_STATUS_INPROGRESS;
				pCase.Case_Reopen_Date__c = reopenDate;
				pCase.HeldToOpenOn__c = reopenDate;
				pCase.ByPassRoutingRulesOnCreation__c = true;
				pCase.AllocateToQueue__c = false;
			}
		}
	}
}