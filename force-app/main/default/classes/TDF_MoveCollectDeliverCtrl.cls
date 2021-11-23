/**
 * @author       : Alvin Zhou
 * @date         : 2021-10-21
 * @description  : Used as the controller for the tdf_serviceAppointment
 * @changelog
 *
 */
public with sharing class TDF_MoveCollectDeliverCtrl {
	@AuraEnabled
	public static string getServiceAppointment(String recordId) {
		if (recordId != null) {
			ServiceAppointment record = [
				SELECT
					Id,
					Subject,
					ActualStartTime,
					ActualEndTime,
					Duty_Board__c,
					Duty_Board__r.Name,
					Work_Order__r.Duty_Day__c,
					Street,
					State,
					City,
					Postalcode,
					Primary_SR__c,
					Service_Resource__c,
					ArrivalWindowStartTime,
					ArrivalWindowEndTime,
					Primary_SR__r.Name,
					Service_Resource__r.Name,
					SchedStartTime,
					SchedEndTime,
					EarliestStartTime
				FROM ServiceAppointment
				WHERE Id = :recordId
			];
			return JSON.serialize(record);
		}
		return '{}';
	}
	// to check if the resource has got the dispatched job for today.
	public static Boolean checkServiceResource(String srId) {
		Datetime currentDateTime = System.Now();
		Datetime fromSADateTime = currentDateTime.addHours(-12);
		Datetime toSADateTime = currentDateTime.addHours(20);
		List<ServiceAppointment> saList = new List<ServiceAppointment>();
		if (srId != null) {
			saList = [
				SELECT
					Id,
					SchedStartTime,
					SchedEndTime,
					Status,
					Work_Order__c,
					Work_Order__r.Duty_Day__c,
					ServiceTerritoryId,
					Work_Order__r.RecordType.DeveloperName
				FROM ServiceAppointment
				WHERE
					Id IN (
						SELECT ServiceAppointmentId
						FROM AssignedResource
						WHERE
							ServiceResourceId = :srId
							AND ServiceAppointment.SchedStartTime > :fromSADateTime
							AND ServiceAppointment.SchedStartTime < :toSADateTime
					)
					AND Status = 'Dispatched'
				ORDER BY SchedStartTime ASC
			];
		}
		return !saList.isEmpty();
	}

	@AuraEnabled
	public static void reassignRecords(
		String recordId,
		List<String> idList,
		String assignedResourceId,
		String updatedDateTime
	) {
		if (recordId != null && !idList.isEmpty()) {
			Map<Id, ServiceAppointment> updatedAppointments = (Map<Id, ServiceAppointment>) JSON.deserialize(
				updatedDateTime,
				Map<Id, ServiceAppointment>.class
			);
			// Get the assigned resources
			List<AssignedResource> assignedResources = [
				SELECT
					Id,
					ServiceAppointmentId,
					Service_Resource_Type__c,
					ServiceResourceId,
					ServiceCrewId
				FROM AssignedResource
				WHERE ServiceAppointmentId = :recordId OR ServiceAppointmentId IN :idList
			];

			Map<String, AssignedResource> updateResources = new Map<String, AssignedResource>();
			List<AssignedResource> recordsForDeletion = new List<AssignedResource>();

			// To exclude the service appointment and assigned resource
			// if the assignedResourceId is the same as the assgiend resource.
			Set<String> serviceAppointmentIdForSkip = new Set<String>();
			for (AssignedResource resource : assignedResources) {
				if (resource.ServiceResourceId == assignedResourceId) {
					serviceAppointmentIdForSkip.add(resource.ServiceAppointmentId);
				}
			}
			Set<String> serviceAppointmentIdsForUpdate = new Set<String>();
			// detetc the assignments for update and find the ones need to be deleted
			for (AssignedResource resource : assignedResources) {
				// Make sure the service appointments are all selected for update
				serviceAppointmentIdsForUpdate.add(resource.ServiceAppointmentId);
				// the service appointment is not required for update.
				if (serviceAppointmentIdForSkip.contains(resource.ServiceAppointmentId))
					continue;
				// Update the service appointment
				// resource.ServiceCrewId = newlyAssignedCrewId;
				resource.ServiceResourceId = assignedResourceId;

				if (!updateResources.containsKey(resource.ServiceAppointmentId)) {
					updateResources.put(resource.ServiceAppointmentId, resource);
				} else if (resource.Service_Resource_Type__c == 'C') {
					updateResources.put(resource.ServiceAppointmentId, resource);
				}
			}

			for (AssignedResource record : assignedResources) {
				// if(record.ServiceAppointmentId == recordId) continue;
				if (updateResources.containsKey(record.ServiceAppointmentId)) {
					if (updateResources.get(record.ServiceAppointmentId).Id != record.Id) {
						recordsForDeletion.add(record);
					}
				}
			}
			if (!serviceAppointmentIdsForUpdate.isEmpty()) {
				List<ServiceAppointment> appointments = [
					SELECT Id, Primary_SR__c, Service_Resource__c
					FROM ServiceAppointment
					WHERE Id IN :serviceAppointmentIdsForUpdate
				];

				List<ServiceAppointment> saForUpdate = new List<ServiceAppointment>();
				for (ServiceAppointment record : appointments) {
					Boolean needUpdate = false;
					if (updatedAppointments.containsKey(record.Id)) {
						if (updatedAppointments.get(record.Id).SchedStartTime != null) {
							record.SchedStartTime = updatedAppointments.get(record.Id)
								.SchedStartTime;
							needUpdate = true;
						}
						if (updatedAppointments.get(record.Id).SchedEndTime != null) {
							record.SchedEndTime = updatedAppointments.get(record.Id).SchedEndTime;
							needUpdate = true;
						}
					}
					if (serviceAppointmentIdForSkip.contains(record.Id)) {
						if (needUpdate) {
							saForUpdate.add(record);
						}
						continue;
					}
					record.Primary_SR__c = null;
					record.Service_Resource__c = null;
					saForUpdate.add(record);
				}
				if (!saForUpdate.isEmpty())
					update saForUpdate;
			}

			// To delete the records that are not required.
			if (!recordsForDeletion.isEmpty())
				delete recordsForDeletion;

			if (!updateResources.isEmpty())
				update updateResources.values();

			List<AssignedResource> resources = [
				SELECT Id, ServiceResourceId
				FROM AssignedResource
				WHERE
					ServiceAppointmentId IN :updateResources.keyset()
					AND Service_Resource_Type__c = 'C'
			];
			if (!resources.isEmpty()) {
				Id serviceResourceId = resources.get(0).ServiceResourceId;
				if (checkServiceResource(serviceResourceId)) {
					TDF_DispatchWork.dispatch(serviceResourceId);
				}
			}
		}
	}

	@AuraEnabled
	public static string getRelatedAppointments(String recordId) {
		if (recordId == null) {
			return '[]';
		}
		ServiceAppointment record = [
			SELECT
				Id,
				Work_Order__r.Duty_Day__c,
				Subject,
				ActualStartTime,
				ActualEndTime,
				Duty_Board__c,
				Duty_Board__r.Name,
				Primary_SR__c,
				Service_Resource__r.Name,
				ArrivalWindowStartTime,
				ArrivalWindowEndTime,
				Service_Resource__c,
				SchedStartTime,
				SchedEndTime,
				EarliestStartTime
			FROM ServiceAppointment
			WHERE Id = :recordId
		];

		Date dutyDay = record.Work_Order__r.Duty_Day__c;
		String dutyBoardId = record.Duty_Board__c;
		List<WorkOrder> workOrders = [
			SELECT
				Id,
				(SELECT Id, Deliver_To_Work_Order__c FROM Collect_From_Work_Order_Line_Items__r),
				(SELECT Id, Collect_From_Work_Order__c FROM Deliver_To_Work_Order_Line_Items__r)
			FROM WorkOrder
			WHERE Id = :record.Work_Order__c
		];
		List<String> parentIds = new List<String>();
		for (WorkOrder wo : workOrders) {
			for (WorkOrderLineItem collectWo : wo.Collect_From_Work_Order_Line_Items__r) {
				parentIds.add(collectWo.Deliver_To_Work_Order__c);
			}
			for (WorkOrderLineItem deliverWo : wo.Deliver_To_Work_Order_Line_Items__r) {
				parentIds.add(deliverWo.Collect_From_Work_Order__c);
			}
		}
		List<ServiceAppointment> otherAppointments = [
			SELECT
				Id,
				Street,
				State,
				City,
				Postalcode,
				ArrivalWindowStartTime,
				Service_Resource__c,
				Primary_SR__r.Name,
				Service_Resource__r.Name,
				Subject,
				Work_Order__c,
				Primary_SR__c,
				ArrivalWindowEndTime,
				SchedStartTime,
				SchedEndTime,
				EarliestStartTime
			FROM ServiceAppointment
			WHERE
				Work_Order__r.Duty_Day__c = :dutyDay
				AND Duty_Board__c = :dutyBoardId
				AND Work_Order__c IN :parentIds
				AND Id != :recordId
			ORDER BY SchedStartTime
		];

		List<ServiceAppointment> records = new List<ServiceAppointment>();
		for (ServiceAppointment sa : otherAppointments) {
			if (
				sa.Subject == null ||
				(!sa.Subject.contains('Prepare Vehicle') &&
				!sa.Subject.contains('Fit For Duty') &&
				!sa.Subject.contains('Return & Refuel Vehicle'))
			) {
				records.add(sa);
			}
		}

		List<DataFeed> feeds = new List<DataFeed>();
		for (ServiceAppointment appointment : records) {
			DataFeed feed = new DataFeed();
			feed.record = appointment;
			feeds.add(feed);
		}

		return JSON.serialize(feeds);
	}

	public class DataFeed {
		public ServiceAppointment record { get; set; }
		public List<ServiceAppointment> collectFrom { get; set; }
		public List<ServiceAppointment> deliverTo { get; set; }
	}
}