public without sharing class ChasCaseAssignment implements Queueable{

    public static List<String> VALID_STATUSES = new List<String> {ChasConstants.TRACK_STAT_AWAITING_COLLECTION
            , ChasConstants.TRACK_STAT_DELIVERED
            , ChasConstants.TRACK_STAT_LEFT_IN_A_SAFE_PLACE
    };

    public static String SSSW_NETWORK_QUEUE = 'SSSWNetworkQueue';
    public static String STATUS_AWAITING_NETWORK_RESPONSE = 'Awaiting Network Response';
    public static String CONTACT_VIA_MY_NETWORK = 'MyNetwork';

    private Id caseId;
    private Id networkId;

    private static Id getNetworkIdByOrgId(String orgId)
    {
        List<Network__c> networks = [SELECT Id, Org_ID__c
        FROM Network__c
        WHERE Org_ID__c =: orgId
        AND Contact_Facility__c =: CONTACT_VIA_MY_NETWORK
        LIMIT 1
        ];

        if(networks.size() == 1)
            return networks[0].Id;
        return NULL;
    }

    public ChasCaseAssignment(Case newCase, String wcid)
    {
        caseId = newCase.Id;
        networkId = getNetworkIdByOrgId(wcid);
        System.debug('ChasCaseAssignment::queued for ' + caseId + ', ' + networkId);
    }

    public void execute(QueueableContext context)
    {
        System.debug('ChasCaseAssignment::assignCaseToNetwork BEGIN:' + caseId);
        if(caseId != null && networkId != null)
        {
            List<Case> updateCases = [SELECT Id, Network__c, Subject
            FROM Case
            WHERE Id =: caseId];
            if(updateCases.size() == 1)
            {
                Case updateCase = updateCases[0];

                updateCase.Status = STATUS_AWAITING_NETWORK_RESPONSE;
                updateCase.Network__c = networkId;
                updateCase.AllocateToQueue__c = false;

                // get the owner
                List<Group> groups = [select id from Group where developerName =: SSSW_NETWORK_QUEUE];
                System.debug('ChasCaseAssignment Group :' + groups);
                if (groups.size() > 0) {
                    updateCase.OwnerId = groups[0].id;
                }

                // need to re-assign the case owner BEFORE trying to add team members
                update updateCases;

            }
        }
    }

}