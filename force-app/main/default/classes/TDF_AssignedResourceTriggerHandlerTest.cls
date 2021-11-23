/**
 * @author Andrew Judd
 * @date 2020-09-21
 * @domain Field Service
 * @description  Test class for AssignedResourceTrigger, AssignedResourceTriggerHandler, and TDF_AssignedResourceTriggerHandler
 *
 * @changelog
 * 2021-11-01 - Alvin Zhou  - Add test code for skip the validations for the dispatch validations
 *
 */
@isTest
public class TDF_AssignedResourceTriggerHandlerTest {
	static testMethod void validateAssignedResourceTriggerMethodOne() {
		TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

		//Create base data
		OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
		insert objOperatingHours;

		ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory(
			'Dandenong',
			objOperatingHours.Id
		);
		insert objServiceTerritory;

		Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User objUser1 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@auspost.com');
		insert objUser1;

		//Create Driver Service Resource 1
		ServiceResource objDriverServiceResource1 = objTestDataFactory.getServiceResource(
			'Driver 1',
			objUser1
		);
		insert objDriverServiceResource1;

		//Create Service Territory Member record assigning driver SR 1 to the ST
		insert (objTestDataFactory.getServiceTerritoryMember(
			objDriverServiceResource1.Id,
			objServiceTerritory.Id,
			System.now().addDays(-2),
			System.now().addDays(7)
		));

		//Create Duty Service Resource 1
		DateTime startDateTime = System.now().addDays(-3);
		DateTime endDateTime = System.now().addDays(-2);
		ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource(
			'DT61',
			objDriverServiceResource1.Id,
			startDateTime,
			endDateTime
		);
		insert objDutyServiceResource1;

		//Create Service Territory Member record assigning duty SR 1 to the ST
		insert (objTestDataFactory.getServiceTerritoryMember(
			objDutyServiceResource1.Id,
			objServiceTerritory.Id,
			System.now().addDays(-2),
			System.now().addDays(7)
		));

		//Create Work Order and Service Appointment 1
		String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');
		WorkOrder objWorkOrder1 = objTestDataFactory.getWorkOrder(standardWORecordType);
		insert objWorkOrder1;
		ServiceAppointment objServiceAppointment1 = objTestDataFactory.getServiceAppointment(
			objWorkOrder1.Id,
			objServiceTerritory.Id,
			System.now(),
			30
		);
		insert objServiceAppointment1;

		//#Test 1 - Assign service appointment 1 to duty SR1
		AssignedResource objAssignedResource1 = objTestDataFactory.getAssignedResource(
			objServiceAppointment1.Id,
			objDutyServiceResource1.Id
		);
		insert objAssignedResource1;

		//Confirm that the primary service resource on the service appointment is the duty
		System.assert(
			[SELECT Primary_SR__c FROM ServiceAppointment WHERE Id = :objServiceAppointment1.Id]
			.Primary_SR__c == objDutyServiceResource1.Id,
			'The primary SR is not the duty SR'
		);

		//#Test 2 - Assign service appointment 1 to driver 1
		AssignedResource objAssignedResource2 = objTestDataFactory.getAssignedResource(
			objServiceAppointment1.Id,
			objDriverServiceResource1.Id
		);
		insert objAssignedResource2;

		//Confirm that the primary service resource on the service appointment is still the duty
		System.assert(
			[SELECT Primary_SR__c FROM ServiceAppointment WHERE Id = :objServiceAppointment1.Id]
			.Primary_SR__c == objDutyServiceResource1.Id,
			'The primary SR is not still the duty SR'
		);

		//#Test 3 - Delete the assignments and assign to just to driver 1
		delete objAssignedResource1;
		delete objAssignedResource2;
		objServiceAppointment1.SchedStartTime = System.now();
		objServiceAppointment1.SchedEndTime = System.now().addMinutes(30);
		update objServiceAppointment1;
		AssignedResource objAssignedResource3 = objTestDataFactory.getAssignedResource(
			objServiceAppointment1.Id,
			objDriverServiceResource1.Id
		);
		insert objAssignedResource3;

		//Confirm that the primary service resource on the service appointment is now the driver
		System.assert(
			[SELECT Primary_SR__c FROM ServiceAppointment WHERE Id = :objServiceAppointment1.Id]
			.Primary_SR__c == objDriverServiceResource1.Id,
			'The primary SR is not the driver SR'
		);
	}

	private testMethod static void skipValidations() {
		TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

		//Create base data
		OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
		insert objOperatingHours;

		ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory(
			'Dandenong',
			objOperatingHours.Id
		);
		insert objServiceTerritory;

		Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User objUser1 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@auspost.com');
		insert objUser1;
		User objUser2 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf123@auspost.com');
		insert objUser2;
		//Create Driver Service Resource 1
		ServiceResource objDriverServiceResource1 = objTestDataFactory.getServiceResource(
			'Driver 1',
			objUser1
		);
		insert objDriverServiceResource1;
		ServiceResource objDriverServiceResource2 = objTestDataFactory.getServiceResource(
			'Driver 2',
			objUser2
		);
		insert objDriverServiceResource2;
		//Create Service Territory Member record assigning driver SR 1 to the ST
		insert (objTestDataFactory.getServiceTerritoryMember(
			objDriverServiceResource1.Id,
			objServiceTerritory.Id,
			System.now().addDays(-2),
			System.now().addDays(7)
		));
		insert (objTestDataFactory.getServiceTerritoryMember(
			objDriverServiceResource2.Id,
			objServiceTerritory.Id,
			System.now().addDays(-2),
			System.now().addDays(7)
		));
		//Create Duty Service Resource 1
		DateTime startDateTime = System.now().addDays(-3);
		DateTime endDateTime = System.now().addDays(-2);
		ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource(
			'DT61',
			objDriverServiceResource1.Id,
			startDateTime,
			endDateTime
		);
		insert objDutyServiceResource1;

		//Create Service Territory Member record assigning duty SR 1 to the ST
		insert (objTestDataFactory.getServiceTerritoryMember(
			objDutyServiceResource1.Id,
			objServiceTerritory.Id,
			System.now().addDays(-2),
			System.now().addDays(7)
		));

		//Create Work Order and Service Appointment 1
		String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');
		WorkOrder objWorkOrder1 = objTestDataFactory.getWorkOrder(standardWORecordType);
		WorkOrder objWorkOrder2 = objTestDataFactory.getWorkOrder(standardWORecordType);
		insert new List<WorkOrder>{ objWorkOrder1, objWorkOrder2 };

		Product2 objProduct = objTestDataFactory.getProduct2('Test Product 002');
		insert objProduct;

		WorkOrderLineItem objWOLI = objTestDataFactory.getWOLI(
			objWorkOrder1.Id,
			objProduct.Id,
			'Collect Product'
		);
		objWOLI.Collect_From_Work_Order__c = objWorkOrder2.Id;
		insert objWOLI;

		ServiceAppointment objServiceAppointment1 = objTestDataFactory.getServiceAppointment(
			objWorkOrder1.Id,
			objServiceTerritory.Id,
			System.now(),
			30
		);
		ServiceAppointment objServiceAppointment2 = objTestDataFactory.getServiceAppointment(
			objWorkOrder2.Id,
			objServiceTerritory.Id,
			System.now(),
			30
		);
		insert new List<ServiceAppointment>{ objServiceAppointment1, objServiceAppointment2 };

		//#Test 1 - Assign service appointment 1 to duty SR1
		AssignedResource objAssignedResource1 = objTestDataFactory.getAssignedResource(
			objServiceAppointment1.Id,
			objDutyServiceResource1.Id
		);

		//#Test 1 - Assign service appointment 1 to duty SR1
		AssignedResource objAssignedResource2 = objTestDataFactory.getAssignedResource(
			objServiceAppointment2.Id,
			objDutyServiceResource1.Id
		);
		insert new List<AssignedResource>{ objAssignedResource1, objAssignedResource2 };

		Test.startTest();
		objAssignedResource1.ServiceResourceId = objDriverServiceResource2.Id;
		update objAssignedResource1;
		System.assert(
			[SELECT Primary_SR__c FROM ServiceAppointment WHERE Id = :objServiceAppointment1.Id]
			.Primary_SR__c == objDriverServiceResource2.Id,
			'The primary SR is not the driver SR'
		);
		Test.stopTest();
	}
}