/** 
* @author Andrew Judd
* @date 2020-09-02
* @domain Field Service 
* @description  Test class for the Apply Roster form, controller, and TDF_CreateServiceCrewMember
*
* @changelog 
* 
*/
@isTest
public class TDF_ApplyRosterControllerTest {

    static testmethod void validateApplyRosterMethodOne(){

        String rrId;
        Roster__c objRoster;
        List<Apexpages.Message> msgs = new List<Apexpages.Message>();
        Boolean passBol;
        Datetime startDateTime;
        Datetime endDateTime;
        Date startDate;
        Date endDate;

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
        
        //Create base data
        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        //Create primary ST
        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        //Create secondary ST
        ServiceTerritory objServiceTerritorySec = objTestDataFactory.getServiceTerritory('Dandenong Secondary', objOperatingHours.Id);
        objServiceTerritorySec.ParentTerritoryId = objServiceTerritory.Id;
        insert objServiceTerritorySec;

        //Create users
        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objUser1 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf1@auspost.com');
        insert objUser1;
        User objUser2 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf2@auspost.com');
        insert objUser2;

        //Create Driver Service Resource 1
        ServiceResource objDriverServiceResource1 = objTestDataFactory.getServiceResource('Driver 1', objUser1);
        insert objDriverServiceResource1;

        //Create Driver Service Resource 2
        ServiceResource objDriverServiceResource2 = objTestDataFactory.getServiceResource('Driver 2', objUser2);
        insert objDriverServiceResource2;        

        //Create Duty Service Resource 1. 
        //Note Driver Service Resource and start and end dates are for the inital SCM required to activate the Service Crew
        startDateTime = System.now().addDays(-3);
        endDateTime = System.now().addDays(-2);
        ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource('DT61', objDriverServiceResource1.Id, startDateTime, endDateTime);
        insert objDutyServiceResource1;

        //Create Duty Service Resource 2
        ServiceResource objDutyServiceResource2 = objTestDataFactory.getDutyServiceResource('DT62', objDriverServiceResource2.Id, startDateTime, endDateTime);
        insert objDutyServiceResource2;

        //Create Service Territory Member records assigning duties and drivers to the ST
        List<ServiceTerritoryMember> stmList = new List<ServiceTerritoryMember>();
        stmList.add(objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));
        stmList.add(objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource2.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));
        stmList.add(objTestDataFactory.getServiceTerritoryMember(objDriverServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));
        stmList.add(objTestDataFactory.getServiceTerritoryMember(objDriverServiceResource2.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));
        
        //Create Service Territory Member record to assign the secondary territory to Duty 2 (this will result in creation of assignment of secondary territory assignment to the driver via applyRoster)  
        ServiceTerritoryMember objServiceTerritoryMemberSec = objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource2.Id, objServiceTerritorySec.Id, System.now().addDays(-2), System.now().addDays(7));
        objServiceTerritoryMemberSec.TerritoryType = 'S';
        stmList.add(objServiceTerritoryMemberSec);
        insert stmList;

        //Create Roster Records
        startDate = System.today().addDays(2);
        endDate = System.today().addDays(3);
        List<Roster__c> rosterList = new List<Roster__c>();
        //Test 1 - Duty SR with no start time
        rosterList.add(objTestDataFactory.getRoster(objDriverServiceResource1.Id, objDutyServiceResource1.Id, objServiceTerritory.Id, startDate, endDate, 'Test 1 - duty no start', false));
        //Test 2 = Driver 1 assigned to two duties for the same day
        rosterList.add(objTestDataFactory.getRoster(objDriverServiceResource1.Id, objDutyServiceResource1.Id, objServiceTerritory.Id, startDate, endDate, 'Test 2 - driver same day', false));
        rosterList.add(objTestDataFactory.getRoster(objDriverServiceResource1.Id, objDutyServiceResource2.Id, objServiceTerritory.Id, startDate, endDate, 'Test 2 - driver same day', false));
        //Test 3 - Call function with one assignment in the past
        rosterList.add(objTestDataFactory.getRoster(objDriverServiceResource1.Id, objDutyServiceResource1.Id, objServiceTerritory.Id, System.today().addDays(-5), System.today().addDays(-4), 'Test 3 - call service', false));
        rosterList.add(objTestDataFactory.getRoster(objDriverServiceResource1.Id, objDutyServiceResource1.Id, objServiceTerritory.Id, startDate, endDate, 'Test 3 - call service', false));
        rosterList.add(objTestDataFactory.getRoster(objDriverServiceResource2.Id, objDutyServiceResource2.Id, objServiceTerritory.Id, startDate, endDate, 'Test 3 - call service', false));
        //Test 4 - Call function to change a driver assignment. This will required delete of their SCM and STM (as moving off a duty with sec ter)
        rosterList.add(objTestDataFactory.getRoster(objDriverServiceResource2.Id, objDutyServiceResource1.Id, objServiceTerritory.Id, startDate, endDate, 'Test 4 - change assignment', false));
        insert rosterList;

        //Set page
        PageReference pageRef = Page.TDF_ApplyRoster;
        Test.setCurrentPage(pageRef);
        TDF_ApplyRosterController objController;

        //#Test 1 - Null Duty Start Time test
        //Set Duty start time to null
        objDutyServiceResource1.DutyStartTime__c = null;
        update objDutyServiceResource1;

        //Get the a roster record for Test 1
        objRoster = [SELECT Id FROM Roster__c WHERE Roster_Reference__c = 'Test 1 - duty no start' LIMIT 1];

        //Assign record to page
        pageRef.getParameters().put('id', objRoster.Id);
        objController = new TDF_ApplyRosterController(new ApexPages.StandardController(objRoster));

        //Apply roster based on this roster record
        objController.applyRoster();

        //Check messages returned
        msgs = ApexPages.getMessages();
        passBol = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('The following duties do not have a start date set')) passBol = true;
        }
        //Assert
        System.assert(passBol, 'The following duties do not have a start date set'); 
        
        //Restore Duty start time 900
        Time startTime = Time.newInstance(9, 0, 0, 0);
        objDutyServiceResource1.DutyStartTime__c = startTime;
        update objDutyServiceResource1;
        
        //#Test 2 - Driver assigned to more that one day check
        //Get a roster record for Test 2
        objRoster = [SELECT Id FROM Roster__c WHERE Roster_Reference__c = 'Test 2 - driver same day' LIMIT 1];

        //Assign record to page
        pageRef.getParameters().put('id', objRoster.Id);
        objController = new TDF_ApplyRosterController(new ApexPages.StandardController(objRoster));

        //Apply roster based on this roster record
        objController.applyRoster();

        //Check messages returned
        msgs = ApexPages.getMessages();
        passBol = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('Drivers with assignments that will overlap')) passBol = true;
        }
        //Assert
        System.assert(passBol, 'Drivers with assignments that will overlap');

        //#Test 3 - Valid roster day, but with one in the past
        //Get a roster record for Test 3
        objRoster = [SELECT Id FROM Roster__c WHERE Roster_Reference__c = 'Test 3 - call service' LIMIT 1];

        //Assign record to page
        pageRef.getParameters().put('id', objRoster.Id);
        objController = new TDF_ApplyRosterController(new ApexPages.StandardController(objRoster));

        //Apply roster based on this roster record
        objController.applyRoster();

        //Assert four SCMs created (2 for each driver) for this roster reference
        List<ServiceCrewMember> scmTestList;
        scmTestList = [SELECT Id FROM ServiceCrewMember WHERE Roster_Record__r.Roster_Reference__c = 'Test 3 - call service'];
        System.assert(scmTestList.size() == 4, 'Four SCMs were not created');

        //#Test 4 - change assignment
        //Get a roster record for Test 4
        objRoster = [SELECT Id FROM Roster__c WHERE Roster_Reference__c = 'Test 4 - change assignment' LIMIT 1];

        //Assign record to page
        pageRef.getParameters().put('id', objRoster.Id);
        objController = new TDF_ApplyRosterController(new ApexPages.StandardController(objRoster));

        //Apply roster based on this roster record
        objController.applyRoster();
        
        //#Test 5 - Delete assignments by roster reference (i.e. the current Test 3 one)
        objController.rosterReferenceString = 'Test 3 - call service';
        objController.deleteAssignmentsByRosterRef();
        //Assert
        scmTestList = [SELECT Id FROM ServiceCrewMember WHERE Roster_Record__r.Roster_Reference__c = 'Test 3 - call service'];
        System.assert(scmTestList.size() == 0, 'All SCMs were not deleted by roster reference');

        //#Test 6 - Delete assignments by service territory (i.e. all inserted)
        //Apply roster to recreate assignments
        objController.applyRoster();
        //Delete assignments
        objController.deleteAssignmentsByST();

        //#Test 7 - Delete roster records
        objController.deleteRosterRecordsByRosterRef();
        rosterList = [SELECT Id FROM Roster__c WHERE Roster_Reference__c = 'Test 3 - call service'];
        //Assert 
        System.assert(rosterList.size() == 0, 'All roster records were not deleted by service territory');

    }

}