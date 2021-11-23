/* @author Mav3rik
 * @date 2020-10-27
 * @group Lead
 * @tag Lead
 * @domain Core
 * @description Apex class for populating the Lead LPO_WCC__c field. 
 *  NOTE - uses without sharing to grant visibility to Network records. 
 * @changelog
 * 2020-10-27 - Mav3rik - Created
 */
public without sharing class LPOLeadWccController {
    
    /**
     * @description Update the Lead LPO_WCC__c field if the Network ID is available for the User
     *
     * ## leads (List<Lead>): leads
     * @@ Return List<Lead>: Returns the update list of Leads
     */
    public static List<Lead> updateWCC(List<Lead> leads) {
        /* Only populate the LPO WCC field if the user is a Partner user - 
            check the user type and return if not a Partner.
            This can be modified to look at Network ID after Community is live
        */
        if(UserInfo.getUserType() == 'PowerPartner') {
            String networkOrgId = getUserNetwork();
            
            if(networkOrgId != null) {
                ID networkRecordID = getNetworkRecordID(networkOrgId);
                for (Lead l : leads) {
                    if (l.LPO_WCC__c == null || String.isEmpty(l.LPO_WCC__c)) {
                        l.LPO_WCC__c = networkRecordID;
                    }
                }
            }
        }

        return leads;
    }

    /**
     * @description Get the Network Org ID from the User
     *
     * @@ Return String: Returns the Network Org ID
     */
    private static String getUserNetwork() {
        User u = [SELECT Id, Network__c FROM User WHERE Id =: UserInfo.getUserId()];
        if ( u == null) {
            return null;
        }
        return u.Network__c;
    }

    /**
     * @description Get the Network ID from Network Object
     *
     * ## orgId (String): orgId - Netowrk Org Id
     * @@ Return String: Returns the Network ID
     */
    private static String getNetworkRecordID(String orgId) {
        List<Network__c> n = [SELECT Id, Org_ID__c FROM Network__c WHERE Org_ID__c =: orgId];
        if ( n == null || n.size() == 0 || n.size() > 1) {
            return null;
        }
        return n[0].Id;
    }
}