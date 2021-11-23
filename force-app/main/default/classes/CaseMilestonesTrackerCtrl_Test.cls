/*
  * @author       : haraprasad.sahoo@auspost.com.au
  * @date         : 24/04/2020
  * @description  : Test class controller for CaseMilesronesTrackerCtrl Apex class
--------------------------------------- History --------------------------------------------------
24.04.2020    Hara Sahoo    Created
*/
@isTest
private class CaseMilestonesTrackerCtrl_Test
{
    private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
    @isTest
    static void testCaseMilestonesTrackerLogic()
    {
        
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        System.runAs(TestUtility.createUser('Wayne',prof.id,role.id)){
            TestUtility.createTestEntitlementProcessData();
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);
            
            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            Database.insert(csRec);
            CaseTriggerHelper.isCompleteMilestonRecursive  = false; // resetting Recursive flag to invoke update triggers
            
            csRec.Status = 'Awaiting Network Response';
            csRec.Facility_Milestones_Violated__c = 1;
            
            test.startTest();
            Id defaultBusinessHour = Utility.getDefaultBussinessHour();
            csRec.BusinessHoursId=defaultBusinessHour;
            Database.update(csRec);
            List<CaseMilestone> mileStones = CaseMilestonesTrackerCtrl.getSpecificMilestonesForCase(csRec.Id, '');
            
            List<CaseMilestone> mileStonesFiltered = CaseMilestonesTrackerCtrl.getSpecificMilestonesForCase(csRec.Id, 'Network Tier 1');
            
            String bussHoursAsString = csRec.BusinessHoursId;
            if(bussHoursAsString!=null)
            {
                Boolean withinBusinessHours = CaseMilestonesTrackerCtrl.areWeWithinSpecifiedBusinessHours(bussHoursAsString);
            }
            
            ApexPages.StandardController sc = new ApexPages.StandardController(csRec);
            CaseMilestonesTrackerCtrl testCaseMilestonesTrackerCtrl = new CaseMilestonesTrackerCtrl(sc);
            
            PageReference pageRef = Page.myNetworkCaseMilestoneTracker;
            pageRef.getParameters().put('id', String.valueOf(csRec.Id));
            Test.setCurrentPage(pageRef);
            
            test.stopTest();
            
        }
    }
}