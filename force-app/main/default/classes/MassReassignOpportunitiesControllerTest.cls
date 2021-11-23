/**
 * Test Class for MassReassignOpportunitiesController
 * @changelog
 * 30-09-2021 seth.heang@auspost.com.au	Migrate the testmode from the main class(MassReassignOpportunitiesController) to a new test class
 * */
@isTest
public class MassReassignOpportunitiesControllerTest {

    public static testmethod void testReassign(){
        
        RecordType orgrectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        //create account
        Account bacct = new Account(name='test org', recordtypeid=orgrectype.Id, phone='11111111', email__c='test@test.com');
        insert bacct;
        
        //Account testAccount = new Account();
        //testAccount.Name = 'test';
        //insert testAccount;
        
        Opportunity testOpty = new Opportunity();
        testOpty.StageName = 'Identify';
        //testOpty.Organisation_Sector__c = 'Enterprise';
        //testOpty.Owner_Approval_Status__c = true;
        testOpty.CloseDate = System.today()+1;
        testOpty.AccountId=bacct.Id;
        testOpty.Name='testOpty';
        testOpty.Type = 'testType';
        insert testOpty;
        
        MassReassignOpportunitiesController controller = new MassReassignOpportunitiesController();
        controller.refreshOptyList();
        controller.filterId = controller.listviewoptions[1].getValue();
        controller.refreshOptyList();
        controller.searchRecord.stageName = 'Identify';
        controller.helperRecord.ClosedDate_From__c=System.today();
        controller.helperRecord.ClosedDate_To__c=System.today()+2;
        //controller.helperRecord.From__c=System.today();
        //controller.helperRecord.To__c=System.today()+1;
        controller.searchRecord.Type = 'testType';
        controller.refreshOptyListBySearch();
        
        System.assert(controller.optyList.size()>0);
        
        controller.optyList[0].selected = true;
        controller.helperRecord.Assign_to__c = UserInfo.getUserId();
        controller.Assign();        
    }
}