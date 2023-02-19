/**************************************************
Type:       Test class for ChasCaseAssignment
History:
--------------------------------------------------
2023-02-16	Noel Lim	Class comment added, Update method setupTestData to remove queues being decommissioned

**************************************************/

@isTest
public class ChasCaseAssignment_Test {

    public static String TEST_NETWORK_ORG_ID = '1248777';

    @testSetup
    public static void setupTestData()
    {
        List<String> groupNames = new List<String>{
                'SSSW High Level Complaints',
                'SSSW Customer Recovery',
                'SSSW Snap It Inbound',
                'SSSW Snap It Back Office',
                'SSSW MyPost Business Inbound',
                'SSSW MyPost Business Back Office',
                'SSSW Damages Back Office',
                'SSSW Load & Go',
                'SSSW MyPost',
                'SSSW Consumer Back Office Disputed Del',
                'SSSW PBD Inbound Orders queue',
                'SSSW MyPost Digital Mailbox',
                'SSSW Shopmate',
                'SSSW Enterprise Inbound',
                'SSSW Business Inbound',
                'SSSW International Inbound Std Track',
                'SSSW International Inbound',
                'SSSW International ECI Back Office',
                'SSSW International Back Office',
                'SSSW Unaddressed Mail Inbound',
                'SSSW Unaddressed Mail Back Office',
                'SSSW Enterprise Back Office',
                'SSSW Business Back Office',
                'SSSW Consumer Inbound',
                'SSSW Consumer Back Office Spec Del',
                'SSSW Consumer Back Office Delivery Compl',
                'SSSW Consumer Back Office Premium',
                'SSSW Consumer Back Office Standard',
                'SSSW Consumer Back Office Fin & Trav',
                'SSSW Consumer Back Office Other',
                ChasCaseAssignment.SSSW_NETWORK_QUEUE
        };

        Profile adminProf = [select Id from Profile where Name = 'System Administrator'];

        // use runAs to bypass the DML with Group limitations
        System.runAs(TestUtility.createUser('Admin',adminProf.id,null)) {

            //Create the related Groups
            List<Group> groupsToAdd = new List<Group>();
            for (String gn : groupNames) {
                groupsToAdd.add(new Group(Name = gn, Type = 'Queue'));
            }
            insert groupsToAdd;

            //Create the related queues
            List<QueueSobject> queuesToAdd = new List<QueueSobject>();
            for (Group g : groupsToAdd) {
                queuesToAdd.add(new QueueSobject(QueueID = g.id, SobjectType = 'Case'));
            }
            insert queuesToAdd;

            // create a network
            Network__c network = new Network__c();
            network.Name = 'Melbourne Dead Mail';
            network.Org_ID__c = TEST_NETWORK_ORG_ID;
            network.Contact_Facility__c = ChasCaseAssignment.CONTACT_VIA_MY_NETWORK;
            insert network;

        }
    }

    @isTest
    public static void test_AssignCase()
    {
        List<Group> groupNetwork = [SELECT Id, Name FROM Group WHERE developerName =: ChasCaseAssignment.SSSW_NETWORK_QUEUE];
        Id queueId = groupNetwork[0].Id;

        // create a new Case for testing getRecordTypeId static method
        Case testCase = TestDataProvider.createTestCase();
        //testCase.ReferenceID__c = 'SSSWCase';
        insert testCase;
        Id caseId = testCase.Id;

        Test.startTest();

        ChasCaseAssignment assignJob = new ChasCaseAssignment(testCase, TEST_NETWORK_ORG_ID);
        System.enqueueJob(assignJob);
        Test.stopTest();

        List<Case> results = [
                SELECT Id, OwnerId
                FROM Case
                WHERE Id =: caseId
        ];
        System.assertEquals(results[0].OwnerId, queueId, 'Expected Case to be assigned to Network Queue, ' + results[0]);
    }
}