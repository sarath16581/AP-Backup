/**
 * Created by hasan on 6/06/2022.
 */

public virtual without sharing class ChasBase {

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
        return [SELECT ContactId FROM User WHERE Id = :userId]?.ContactId;
    }

    /**
 * @description Helper class containing methods that need to bypass sharing settings
 */
    public without sharing class SharingBypass {
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
            return Database.insert(pSObjects);
            //return ApplicationDatabase.getInstance().dmlInsert(pSObjects);
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
                Date reopenDate = ChasUtil.calculateNextBusinessDay(pCase.EstimatedDelivery__c, Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c != null ? Integer.valueOf(Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c) : 0);
                pCase.Status = SSSWConstants.CASE_STATUS_INPROGRESS;
                pCase.Case_Reopen_Date__c = reopenDate;
                pCase.HeldToOpenOn__c = reopenDate;
                pCase.ByPassRoutingRulesOnCreation__c = true;
                pCase.AllocateToQueue__c = false;
            }
        }
    }

    /**
* Create Parse Case inserted results and create case comment
* */
    public static CaseWrapper parseInsertedCaseResultsAndCreateComment(Database.SaveResult[] results, CaseWrapper caseWrapperObj, List<CaseComment> comments) {
        Set<Id> vCaseIds = new Set<Id>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                try {
                    Id lObjectId = Id.valueOf(results[i].getId());
                    String objName = lObjectId.getSobjectType().getDescribe().getName();
                    //-- Creating Case Comment for inserted Case
                    if (objName.equalsIgnoreCase('Case')) {
                        createCaseComment(lObjectId, comments);
                        vCaseIds.add(lObjectId);
                    }

                } catch (Exception ex) {
                    System.debug('*** - Error while retrieving Case Number/Creating Case Comment ===' + ex);
                }

            } else {
                caseWrapperObj.caseStatus = 'ERROR';
                System.debug('Error: could not create sobject ' + 'for array element ' + i + '.');
                System.debug('The error reported was: ' + results[i].getErrors()[0].getMessage() + '\n');

            }
        }

        caseWrapperObj.caseNumber = CasesSelector.newInstance().selectById(vCaseIds).get(new List<Id>(vCaseIds)[0]).CaseNumber;

        return caseWrapperObj;
    }

    /**
     * create a case comment with publish option
     * @author: edgarallan.castillo3@auspost.com.au
     * @param caseId: target case Id
     * @param commentBody: list of comments to create
     */
    public static void createCaseComment(Id caseId, List<CaseComment> comments) {
        for (CaseComment cc : comments) {
            cc.CommentBody = '---Enquiry Details---' + '\n' + cc.CommentBody;
            cc.ParentId = caseId;
        }
        try {
            ApplicationDatabase.getInstance().dmlInsert(comments);
        } catch (Exception e) {
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'CHAS', 'ChasApexController', 'createCaseComment', '', LoggingLevel.ERROR);
        }
    }
}