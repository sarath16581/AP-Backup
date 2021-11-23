/** 
* @author Andrew Judd
* @date 2020-09-06
* @domain Field Service 
* @description  Test class for the TDF_ScheduleToDutyController class
*
* @changelog 
* 
*/
@isTest
public class TDF_ScheduleToDutyControllerTest {

    //Test assign driver to duty
    static testmethod void validateScheduleToDutyMethodOne(){

        List<AssignedResource> assResList;
        List<Apexpages.Message> msgs = new List<Apexpages.Message>();
        Boolean passBol;

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
        
        //Create base data
        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objUser1 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@auspost.com');
        insert objUser1;
        User objUser2 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf2@auspost.com');
        insert objUser2;

        //Create Driver Service Resource 1
        ServiceResource objDriverServiceResource1 = objTestDataFactory.getServiceResource('Driver 1', objUser1);
        insert objDriverServiceResource1;

        //Create Driver Service Resource 2
        ServiceResource objDriverServiceResource2 = objTestDataFactory.getServiceResource('Driver 2', objUser2);
        insert objDriverServiceResource2;

        //Create Service Territory Member record assigning driver SR 1 to the ST
        insert(objTestDataFactory.getServiceTerritoryMember(objDriverServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));

        //Create Service Territory Member record assigning driver SR 2 to the ST
        insert(objTestDataFactory.getServiceTerritoryMember(objDriverServiceResource2.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));

        //Create Duty Service Resource 1
        DateTime startDateTime = System.now().addDays(-3);
        DateTime endDateTime = System.now().addDays(-2);
        ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource('DT61',objDriverServiceResource1.Id, startDateTime, endDateTime );
        insert objDutyServiceResource1;

        //Create Duty Service Resource 2
        ServiceResource objDutyServiceResource2 = objTestDataFactory.getDutyServiceResource('DT62',objDriverServiceResource2.Id, startDateTime, endDateTime );
        insert objDutyServiceResource2;

        //Create Service Territory Member record assigning duty SR 1 to the ST
        insert(objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));

        //Create Service Territory Member record assigning duty SR 2 to the ST
        insert(objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource2.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));

        //Create site location 
        Schema.Location objSiteLocation1 = new Schema.Location();
        objSiteLocation1 = objTestDataFactory.getLocation('Depot', 'Site');
        insert objSiteLocation1;

        String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');
        
        //Create Work Order and Service Appointment 1
        WorkOrder objWorkOrder1 = objTestDataFactory.getWorkOrder(standardWORecordType);
        insert objWorkOrder1;
        ServiceAppointment objServiceAppointment1 = objTestDataFactory.getServiceAppointment(objWorkOrder1.Id, objServiceTerritory.Id, System.now(), 30);                 
        insert objServiceAppointment1;

        //Create Work Order and Service Appointment 2
        WorkOrder objWorkOrder2 = objTestDataFactory.getWorkOrder(standardWORecordType);
        insert objWorkOrder2;
        ServiceAppointment objServiceAppointment2 = objTestDataFactory.getServiceAppointment(objWorkOrder2.Id, objServiceTerritory.Id, System.now().addHours(1), 30);                 
        insert objServiceAppointment2;

        //Create Work Order and Service Appointment 3
        WorkOrder objWorkOrder3 = objTestDataFactory.getWorkOrder(standardWORecordType);
        insert objWorkOrder3;
        ServiceAppointment objServiceAppointment3 = objTestDataFactory.getServiceAppointment(objWorkOrder3.Id, objServiceTerritory.Id, System.now().addHours(2), 30);                 
        insert objServiceAppointment3;

        //Create Work Order and Service Appointment 4 - to be unassigned
        WorkOrder objWorkOrder4 = objTestDataFactory.getWorkOrder(standardWORecordType);
        insert objWorkOrder4;
        ServiceAppointment objServiceAppointment4 = objTestDataFactory.getServiceAppointment(objWorkOrder4.Id, objServiceTerritory.Id, System.now().addHours(3), 30);                 
        insert objServiceAppointment4;

        //Assign the service appointments 1 and 2 to duty SR1
        insert(objTestDataFactory.getAssignedResource(objServiceAppointment1.Id, objDutyServiceResource1.Id));
        insert(objTestDataFactory.getAssignedResource(objServiceAppointment2.Id, objDutyServiceResource1.Id));
        //Assign the service appointment 3 to just driver 1
        insert(objTestDataFactory.getAssignedResource(objServiceAppointment3.Id, objDriverServiceResource1.Id));

        //Assign page
        PageReference pageRef = Page.TDF_ScheduleToDuty;
        Test.setCurrentPage(pageRef);
        TDF_ScheduleToDutyController objController;

        //##Commence tests
        //#Test 1 - none selected
        //Set page attributes to reflect
        pageRef.getParameters().put('id', null);
        pageRef.getParameters().put('services', '');
        objController = new TDF_ScheduleToDutyController();

        //Page message should be returned - no SAs selected
        msgs = ApexPages.getMessages();
        passBol = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('No Service Appointments selected for assignment.')) passBol = true;
        }
        //Assert
        System.assert(passBol, 'No Service Appointments selected for assignment.'); 

        //#Test 2 - multiple SAs selected. Assign both to duty 2
        //Set page attributes to reflect
        pageRef.getParameters().put('id', null);
        pageRef.getParameters().put('services', objServiceAppointment1.Id + ','+ objServiceAppointment2.Id);
        objController = new TDF_ScheduleToDutyController();
        
        //Set selected duty as duty 2
        objController.selectedDutyForAssignment = objDutyServiceResource2.Id;

        //Call schedule to duty
        objController.scheduleToDuty();

        //Assert that SA 1 and 2 are now assigned to duty 2
        assResList = [SELECT Id FROM AssignedResource 
                        WHERE (ServiceAppointmentId = :objServiceAppointment1.Id OR ServiceAppointmentId = :objServiceAppointment2.Id)  
                        AND ServiceResourceId = :objDutyServiceResource2.Id];

        System.assert(assResList.size()==2, 'Test 2 error - Service Appointment 1 and 2 were not assigned to Duty 2');

        //#Test 3 - a single SA selected. Assign SA1 back to duty 1 
        //Set page attributes to reflect
        pageRef.getParameters().put('id', objServiceAppointment1.Id);
        pageRef.getParameters().put('services', ''); 
        objController = new TDF_ScheduleToDutyController();
        
        //Set selected duty as duty 1
        objController.selectedDutyForAssignment = objDutyServiceResource1.Id;

        //Call schedule to duty
        objController.scheduleToDuty();

        //Assert that SA 1 is now assigned back to to duty 1
        assResList = [SELECT Id FROM AssignedResource 
                        WHERE ServiceAppointmentId = :objServiceAppointment1.Id   
                        AND ServiceResourceId = :objDutyServiceResource1.Id];

        System.assert(assResList.size()==1, 'Test 3 error - Service Appointment 1 was not assigned back to Duty 1');        

        //#Test 4 - Attempt to reassign a dispatch SA. Change SA2 status to dispatched and attempt to assign back to duty 1
        objServiceAppointment2.Status = 'Dispatched';
        update objServiceAppointment2;

        //Set page attributes to reflect
        pageRef.getParameters().put('id', objServiceAppointment2.Id);
        pageRef.getParameters().put('services', ''); 
        objController = new TDF_ScheduleToDutyController();
        
        //Set selected duty as duty 1
        objController.selectedDutyForAssignment = objDutyServiceResource1.Id;     
        
        //Call schedule to duty
        objController.scheduleToDuty();

        //Page message should be returned - Dispatched can not be reassigned
        msgs = ApexPages.getMessages();
        passBol = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('Dispatched, In Progress and Completed jobs can not be reassigned')) passBol = true;
        }
        //Assert
        System.assert(passBol, 'Dispatched, In Progress and Completed jobs can not be reassigned'); 

        //#Test 5 - assign driver assigned sa 3 to duty 1
        //Set page attributes to reflect
        pageRef.getParameters().put('id', objServiceAppointment3.Id);
        pageRef.getParameters().put('services', ''); 
        objController = new TDF_ScheduleToDutyController();
        
        //Set selected duty as duty 1
        objController.selectedDutyForAssignment = objDutyServiceResource1.Id;     
        
        //Call schedule to duty to assign the SA from a Driver SR to the select Duty SR
        objController.scheduleToDuty();

        //Assert that SA 3 now assigned to Duty 1
        assResList = [SELECT Id FROM AssignedResource 
                        WHERE ServiceAppointmentId = :objServiceAppointment3.Id   
                        AND ServiceResourceId = :objDutyServiceResource1.Id];

        System.assert(assResList.size()==1, 'Test 5 error - Service Appointment 3 was not assigned to Duty 1');  

        //#Test 6 - assign unassigned SA4 to duty 1
        //Set page attributes to reflect
        pageRef.getParameters().put('id', objServiceAppointment4.Id);
        pageRef.getParameters().put('services', ''); 
        objController = new TDF_ScheduleToDutyController();
        
        //Set selected duty as duty 1
        objController.selectedDutyForAssignment = objDutyServiceResource1.Id;     
        
        //Call schedule to duty to assign the SA from a Driver SR to the select Duty SR
        objController.scheduleToDuty();

        //Assert that SA 4 now assigned to Duty 1 
        assResList = [SELECT Id FROM AssignedResource 
                        WHERE ServiceAppointmentId = :objServiceAppointment4.Id   
                        AND ServiceResourceId = :objDutyServiceResource1.Id];

        System.assert(assResList.size()==1, 'Test 6 error - Service Appointment 4 was not assigned to Duty 1');    

    }    

}