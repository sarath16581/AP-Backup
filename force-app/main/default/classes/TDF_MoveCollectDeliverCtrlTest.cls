/**
 * @author Alvin Zhou
 * @date 2021-10-27
 * @domain Field Service
 * @description  Test class for TDF_MoveCollectDeliverCtrl
 *
 * @changelog
 *
 */
@isTest
private class TDF_MoveCollectDeliverCtrlTest {
	@TestSetup
	static void makeData() {
		TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
		Product2 objProduct = new Product2();
		objProduct = objTestDataFactory.getProduct2('Test Product 001');
		insert objProduct;

		Product2 objProduct1 = objTestDataFactory.getProduct2('Test Product 002');
		objProduct1.Parent_Product__c = objProduct.Id;
		insert objProduct1;
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
		WorkOrder objWorkOrder2 = objTestDataFactory.getWorkOrder(standardWORecordType);
		WorkOrder objWorkOrder3 = objTestDataFactory.getWorkOrder(standardWORecordType);
		insert new List<WorkOrder>{ objWorkOrder1, objWorkOrder2, objWorkOrder3 };

		WorkOrderLineItem objWOLI = objTestDataFactory.getWOLI(
			objWorkOrder1.Id,
			objProduct1.Id,
			'Collect Product'
		);
		objWOLI.Collect_From_Work_Order__c = objWorkOrder2.Id;
		WorkOrderLineItem objWOLI1 = objTestDataFactory.getWOLI(
			objWorkOrder1.Id,
			objProduct1.Id,
			'Deliver Product'
		);
		objWOLI.Actual_Quantity__c = 5;
		objWoLi1.Deliver_To_Work_Order__c = objworkOrder3.Id;
		insert new List<WorkOrderLineItem>{ objWOLI1, objWOLI };

		ServiceAppointment objServiceAppointment1 = objTestDataFactory.getServiceAppointment(
			objWorkOrder1.Id,
			objServiceTerritory.Id,
			System.now(),
			30
		);
		objServiceAppointment1.Work_Order__c = objWorkOrder1.Id;
		ServiceAppointment objServiceAppointment2 = objTestDataFactory.getServiceAppointment(
			objWorkOrder2.Id,
			objServiceTerritory.Id,
			System.now(),
			30
		);
		objServiceAppointment2.Work_Order__c = objWorkOrder2.Id;
		ServiceAppointment objServiceAppointment3 = objTestDataFactory.getServiceAppointment(
			objWorkOrder3.Id,
			objServiceTerritory.Id,
			System.now(),
			30
		);
		objServiceAppointment3.Work_Order__c = objWorkOrder3.Id;
		insert new List<ServiceAppointment>{
			objServiceAppointment1,
			objServiceAppointment2,
			objServiceAppointment3
		};

		AssignedResource objAssignedResource1 = objTestDataFactory.getAssignedResource(
			objServiceAppointment1.Id,
			objDutyServiceResource1.Id
		);
		insert objAssignedResource1;
	}
	@isTest
	private static void testGetServiceAppointment() {
		Test.starttest();
		List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment];
		for (ServiceAppointment record : appointments) {
			System.assert(TDF_MoveCollectDeliverCtrl.getServiceAppointment(record.Id) != null);
		}
		Test.stoptest();
	}
	@isTest
	private static void testGetRelatedAppointments() {
		Test.starttest();
		List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment];
		for (ServiceAppointment record : appointments) {
			System.assert(TDF_MoveCollectDeliverCtrl.getRelatedAppointments(record.Id) != null);
		}
		Test.stoptest();
	}
	@isTest
	private static void testReassign() {
		Test.starttest();
		
		List<WorkOrderLineItem> lineItems = [Select Id, WorkOrderId from WorkOrderLineItem where  Collect_From_Work_Order__c != null];
		List<ServiceAppointment> selectedAppointments = [SELECT Id FROM ServiceAppointment where Work_Order__c =: lineItems.get(0).WorkOrderId];
		String recordId;
		recordId = selectedAppointments.get(0).Id;
		List<String> idList = new List<String>();
		List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment];
		for (ServiceAppointment record : appointments) {
			if (recordId != null) {
				idList.add(record.Id);
			} else {
				recordId = record.Id;
			}
		}
		List<AssignedResource> assignedResources = [Select Id, ServiceResourceId from AssignedResource where ServiceAppointmentId =: recordId];
		Map<Id, ServiceAppointment> records = new Map<Id, ServiceAppointment>([Select id, SchedEndTime, SchedStartTime from ServiceAppointment]);
		TDF_MoveCollectDeliverCtrl.reassignRecords(recordId, idList, assignedResources.get(0).ServiceResourceId, JSON.serialize(records));
		TDF_MoveCollectDeliverCtrl.DataFeed feed = new TDF_MoveCollectDeliverCtrl.DataFeed();
		feed.record = selectedAppointments.get(0);
		feed.collectFrom = appointments;
		feed.deliverTo = appointments;
		System.assert(feed.collectFrom.size() > 0);
		System.assert(!TDF_MoveCollectDeliverCtrl.checkServiceResource(assignedResources.get(0).ServiceResourceId));
		Test.stoptest();
	}
}