/**
 * @author Noel Lim
 * @group Tests
 * @tag Routing
 * @domain MyCustomer
 * @description Test class for SSSWSortingController
 * 
 * @changelog
 * 2023-02-16	Noel Lim		Created, moved the method testSortingController from SSSW_Routing_Sorting_Test class
 */

 @IsTest
public with sharing class SSSWSortingController_Test{

	private static void CreateRoutingRulesForRaw()
    {	
        //Grab all the groups
        List<Group> groups = new List<Group>([Select Id, Name from Group where Type = 'Queue']);
        Map<Id,String> groupIdToName = new Map<Id,String>();
        for(Group g : groups) {
            groupIdToName.put(g.Id,g.Name);
        }

        //Grab all the queues and map them from QueueID to Name
        List<QueueSobject> queues = new List<QueueSobject>([select QueueId from QueueSobject where QueueId in: groups]);
        Map<String,Id> nameToQId = new Map<String,Id>();
        for(QueueSobject q : queues) {
            if (!nameToQId.containsKey(groupIdToName.get(q.QueueId))) {
                nameToQId.put(groupIdToName.get(q.QueueId), q.QueueId);
            }
        }

        //Routing rule for HLC
        List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();
        SSSWRouting__c routingRule = TestUtility.createSSSWRouting(null,null,null,null,null,'High Level Complaint','All',SSSWConstants.RECTYPEROUTING);
        routingRule.High_Level_Complaint_Flag__c = true;
        routingRule.IsActive__c = True;
        routingRule.Queue_ID__c = nameToQId.get('SSSW High Level Complaints');
        routingRule.Sequence__c = 1;
        routesToInsert.add(routingRule);

        //Routing rule for CR
        routingRule = TestUtility.createSSSWRouting(null,null,null,'Unauthorised Hold/Redirection application',null,null,'Any',SSSWConstants.RECTYPEROUTING);
        routingRule.Customer_Recovery_Flag__c = true;
        routingRule.IsActive__c = True;
        routingRule.Queue_ID__c = nameToQId.get('SSSW Customer Recovery');
        routingRule.Sequence__c = 2;
        routesToInsert.add(routingRule);

        //Routing rule for Prod Cat, Sub Cat, Enq type, sub Type
        routingRule = TestUtility.createSSSWRouting('International Letters','eParcel- Express','General Enquiry','Item transfer',null,null,'ALL',SSSWConstants.RECTYPEROUTING);
        routingRule.IsActive__c = True;
        routingRule.Queue_ID__c = nameToQId.get('SSSW International Inbound');
        routingRule.Sequence__c = 3;
        routesToInsert.add(routingRule);

        //Routing rule for cust type Consumer
        routingRule = TestUtility.createSSSWRouting(null,'eParcel- Express','General Enquiry',null,'Consumer',null,'ALL',SSSWConstants.RECTYPEROUTING);
        routingRule.IsActive__c = True;
        routingRule.Queue_ID__c = nameToQId.get('SSSW FOH Group 4');
        routingRule.Sequence__c = 4;
        routesToInsert.add(routingRule);

        //Routing rule for Any NPS
        routingRule = TestUtility.createSSSWRouting(null,null,null,'Staff Complaint',null,null,'Any',SSSWConstants.RECTYPENPS);
        routingRule.IsActive__c = True;
        routingRule.NPS_criteria__c = 'Include';
        routingRule.Sequence__c = 1;
        routesToInsert.add(routingRule);

        //Routing rule for All NPS
        routingRule = TestUtility.createSSSWRouting(null,null,null,'Damage to property',null,'Direct Email','All',SSSWConstants.RECTYPENPS);
        routingRule.IsActive__c = True;
        routingRule.NPS_criteria__c = 'Exclude';
        routingRule.Sequence__c = 2;
        routesToInsert.add(routingRule);

        //Routing rule for Any Escalation
        routingRule = TestUtility.createSSSWRouting(null,null,null,'Staff Complaint',null,null,'Any',SSSWConstants.RECTYPEESCALATION);
        routingRule.IsActive__c = True;
        routingRule.AutoEscalate__c = true;
        routingRule.Sequence__c = 1;
        routesToInsert.add(routingRule);

        //Routing rule for All Escalation
        routingRule = TestUtility.createSSSWRouting(null,null,null,'Damage to property',null,'Direct Email','All',SSSWConstants.RECTYPEESCALATION);
        routingRule.IsActive__c = True;
        routingRule.AutoEscalate__c = true;
        routingRule.Sequence__c = 2;
        routesToInsert.add(routingRule);

        //Routing Rule for All Description
        routingRule = TestUtility.createSSSWRouting(null,null,null,null,null,'High Level Complaint','All',SSSWConstants.RECTYPEDESCRIPTION);
        routingRule.High_Level_Complaint_Flag__c = true;
        routingRule.IsActive__c = True;
        routingRule.DefaultCaseDetails__c = 'Testing All Description';
        routingRule.Sequence__c = 1;
        routesToInsert.add(routingRule);

        //Routing Rule for All Description
        routingRule = TestUtility.createSSSWRouting(null,null,null,'Unauthorised Hold/Redirection application',null,null,'Any',SSSWConstants.RECTYPEDESCRIPTION);
        routingRule.Customer_Recovery_Flag__c = true;
        routingRule.IsActive__c = True;
        routingRule.DefaultCaseDetails__c = 'Testing Any Description';
        routingRule.Sequence__c = 2;
        routesToInsert.add(routingRule);

        Database.insert(routesToInsert,false);
    }

    @isTest
    private static void testSortingController() {
        Test.startTest(); 
        CreateRoutingRulesForRaw();
        SSSWSortingController ext = new SSSWSortingController();
        ext.sortRoutings();
        ext.cancelSort();
        ext.refreshRoutings();
        ext.refreshNPS();
        ext.refreshEscalate();
        ext.refreshDescription();
        ext.saveRoutings();
        ext.saveNPS();
        ext.saveEscalate();
        ext.saveDescription();
        ext.deleteRouting();
        ext.deleteNPS();
        ext.deleteEscalate();
        ext.deleteDescription();
        ext.getrecordTypes();
        SSSWSortingController.getRoutingRules();
        Test.stoptest();
    }
}