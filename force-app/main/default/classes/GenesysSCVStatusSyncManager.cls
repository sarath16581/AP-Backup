/**
 * @author		Genesys, Paul Perry
 * @date		15/08/2024
 * @description
 * 	Omni Presence status synchronisation to Genesys CTI status and vice versa between
 *	Genesys Cloud Platform and Salesforce.
 *
 * 		Map(Genesys Status => StatusId)
 *		- Genesys Cloud Platform statuses are obtained from Custom Settings Object:
 *		GenesysAgentStatusIdMapping__c[] and can be populated/updated from Genesys using
 *		GenesysStatusSyncUtil
 *
 * 		Map(Omni Presence Status -> StatusId)
 *		- Omni Agent Presence settings are obtained from ServicePresenceStatus object that
 *		reflects the actual Omni Presence configuration of the org
 *
 * 		Map(StatusName => StatusName)
 * 		- Synchronisation mappings (Genesys => Salesforce) and (Salesforce => Genesys) are defined in
 *		GenesysAgentStatusMapping__mdt
 */
global with sharing class GenesysSCVStatusSyncManager implements genesyscloud.GenesysSCVExtension.Status {

	public class GenesysCloudStatus {
		public GenesysTargetStatus targetStatus;
		public GenesysCloudStatus(GenesysTargetStatus targetStatus) {
			this.targetStatus = targetStatus;
		}
	}

	public class GenesysTargetStatus {
		public String id;
		public GenesysTargetStatus(String id) {
			this.id = id;
		}
	}

	public class SalesforceStatus {
		public SalesforceTargetStatus targetStatus;
		public SalesforceStatus(SalesforceTargetStatus targetStatus) {
			this.targetStatus = targetStatus;
		}
	}

	public class SalesforceTargetStatus {
		public String statusId;
		public SalesforceTargetStatus(String statusId) {
			this.statusId = statusId;
		}
	}

	public class Response {
		public GenesysCloudStatus genesysCloudStatus;
		public SalesforceStatus salesforceStatus;
		public Response(GenesysCloudStatus genesysCloudStatus, SalesforceStatus salesforceStatus) {
			this.genesysCloudStatus = genesysCloudStatus;
			this.salesforceStatus = salesforceStatus;
		}
	}

	public enum StatusOrigin {
		SALESFORCE,
		GENESYS
	}

	private static Map<StatusOrigin,StatusOrigin> counterpartStatus = new Map<StatusOrigin,StatusOrigin>{
		StatusOrigin.SALESFORCE => StatusOrigin.GENESYS,
		StatusOrigin.GENESYS => StatusOrigin.SALESFORCE
	};

	// Map of Salesforce Status Name by StatusId
	private static Map<String,String> salesforceStatusesById {
		get {
			if (salesforceStatusesById == null) {
				salesforceStatusesById = new Map<String,String>();

				ServicePresenceStatus[] spsList = ServicePresenceStatusSelector.newInstance().selectActiveStatuses();

				for (ServicePresenceStatus servicePresenceStatus :spsList) {
					salesforceStatusesById.put(
						servicePresenceStatus.Id,
						servicePresenceStatus.DeveloperName?.toUpperCase()
					);
				}
			}

			return salesforceStatusesById;
		}
		set;
	}

	// Reverses Map containing Stalesforce StatusId by Status Name
	private static Map<String,String> salesforceStatuses {
		get {
			if (salesforceStatuses == null) {
				salesforceStatuses = new Map<String,String>();

				for (String statusId :salesforceStatusesById.keySet()) {
					salesforceStatuses.put(
						salesforceStatusesById.get(statusId).toUpperCase(),
						statusId
					);
				}
			}

			return salesforceStatuses;
		}
		set;
	}

	// Map of Genesys Status Name by StatusId
	private static Map<String,String> genesysStatusesById {
		get {
			if (genesysStatusesById == null) {
				genesysStatusesById = new Map<String,String>();

				GenesysAgentStatusIdMapping__c[] mappings = GenesysAgentStatusIdMappingsSelector.newInstance().selectBySource('Genesys');

				for (GenesysAgentStatusIdMapping__c mapping :mappings) {
					genesysStatusesById.put(mapping.StatusId__c, mapping.Name?.toUpperCase());
				}
			}

			return genesysStatusesById;
		}
		set;
	}

	// Reverses Map containing Genesys StatusId by Status Name
	private static Map<String,String> genesysStatuses {
		get {
			if (genesysStatuses == null) {
				genesysStatuses = new Map<String,String>();

				for (String statusId :genesysStatusesById.keySet()) {
					genesysStatuses.put(genesysStatusesById.get(statusId), statusId);
				}
			}

			return genesysStatuses;
		}
		set;
	}

	/**
	 * Obtain Status to StatusId mappings (for Genesys/Salesforce config)
	 * @param origin StatusOrigin SALESFORCE / GENESYS
	 * @return Map<String,String> Status => StatusId
	 */
	private static Map<String,String> getStatusIdMappings(StatusOrigin origin) {
		// Target is the oposite as the origin
		if (origin == StatusOrigin.GENESYS) {
			return genesysStatuses;
		} else if (origin == StatusOrigin.SALESFORCE) {
			return salesforceStatuses;
		}

		throw new HandledException('No origin provided');
	}

	/**
	 * Obtain configuration for Genesys Status => Salesforce Status (or vice versa)
	 * @param origin StatusOrigin SALESFORCE / GENESYS
	 * @return Map<String,String> Origin status name => Target Status Name
	 */
	private static Map<String,String> getStatusNameMapping(StatusOrigin origin) {
		Map<StatusOrigin,String> mappingOrigin = new Map<StatusOrigin,String>{
			StatusOrigin.SALESFORCE => 'salesforceStatusChange',
			StatusOrigin.GENESYS => 'genesysStatusChange'
		};

		String statusChangeOrigin = mappingOrigin.get(origin);
		Map<String,GenesysAgentStatusMapping__mdt> configMap = GenesysAgentStatusMappingsSelector.newInstance().selectByDeveloperName(new Set<String>{ statusChangeOrigin });
		GenesysAgentStatusMapping__mdt gasm = configMap.get(statusChangeOrigin);

		return (Map<String,String>)JSON.deserialize(gasm.MappingData__c.toUpperCase(), Map<String,String>.class);
	}

	@TestVisible
	/**
	 * Get the statusId of mapped status Name
	 * @param origin StatusOrigin SALESFORCE / GENESYS
	 * @param originStatusName Status in the originating system
	 * @return StatusId for mapped status in the target system
	 */
	private static String getTargetStatus(StatusOrigin origin, String originStatusName, String sourceStatusId) {
		// Genesys provides us with the status label which could change over time, fetch DeveloperName first
		String sourceStatusApiName = originStatusName;
		
		if (origin == StatusOrigin.SALESFORCE) {			
			originStatusName = salesforceStatusesById.get(sourceStatusId);
		} 

		if (String.isNotBlank(sourceStatusApiName)) {
			sourceStatusApiName = sourceStatusApiName.toUpperCase();
		}

		StatusOrigin target = counterpartStatus.get(origin);

		Map<String,String> targetStatusIdMappings = getStatusIdMappings(target);
		Map<String,String> targetStatusNameMappings = getStatusNameMapping(origin);

		String targetStatusName = targetStatusNameMappings.get(sourceStatusApiName);
		String targetStatusId = targetStatusIdMappings.get(targetStatusName);

		System.debug(JSON.serializePretty(new Map<String,Object>{
			'origin' => origin,
			'sourceStatusId' => sourceStatusId,
			'originStatusName' => originStatusName,
			'sourceStatusApiName' => sourceStatusApiName,
			'mappings' => new Map<String,Object>{
				'salesforceStatuses' => salesforceStatuses,
				'salesforceStatusesById' => salesforceStatusesById,
				'targetStatusNameMappings' => targetStatusNameMappings,
				'targetStatusIdMappings' => targetStatusIdMappings
			},
			'targetStatusName' => targetStatusName,
			'targetStatusId' => targetStatusId
		}));

		return targetStatusId;
	}

	/**
	 * Consolidated logic for status synchronisation invoked by the external
	 * events onSalesforceStatusChange and onGenesysStatusChange
	 *
	 * @param origin StatusOrigin SALESFORCE / GENESYS
	 * @param eventData event data (JSON) of the external event
	 * @return Response data to be serialized as JSON
	 */
	public static Response handleStatusChange(StatusOrigin origin, String eventData) {
		Map<String,Object> statusData = (Map<String,Object>)JSON.deserializeUntyped(eventData);
		Map<String,Object> salesforceStatusMap = (Map<String,Object>)statusData.get('salesforceStatus');
		Map<String,Object> salesforceInputStatus = (Map<String,Object>)salesforceStatusMap.get('targetStatus');
		Map<String,Object> genesysStatusMap = (Map<String,Object>)statusData.get('genesysCloudStatus');
		Map<String,Object> genesysInputStatus = (Map<String,Object>)genesysStatusMap.get('targetStatus');

		String statusName = '';
		String statusId = '';
		String id = '';
		String presence = '';

		String fromStatusId;

		if (salesforceInputStatus != null) {
			statusName = (String)salesforceInputStatus.get('statusName');
			statusId = (String)salesforceInputStatus.get('statusId');
			fromStatusId = (String)salesforceInputStatus.get('statusId');
		}

		if (genesysInputStatus != null) {
			presence = (String)genesysInputStatus.get('systemPresence');
			id = (String)genesysInputStatus.get('id');
			fromStatusId = (String)genesysInputStatus.get('id');
		}

		GenesysTargetStatus genesysTargetStatus = new GenesysTargetStatus(id);
		SalesforceTargetStatus salesforceTargetStatus = new SalesforceTargetStatus(statusId);
		GenesysCloudStatus genesysCloudStatus = new GenesysCloudStatus(genesysTargetStatus);
		SalesforceStatus salesforceStatus = new SalesforceStatus(salesforceTargetStatus);

		if (origin == StatusOrigin.SALESFORCE) {
			genesysTargetStatus = new genesysTargetStatus(getTargetStatus(origin, statusName, fromStatusId));
		} else if (origin == StatusOrigin.GENESYS) {
			salesforceTargetStatus = new SalesforceTargetStatus(getTargetStatus(origin, presence, fromStatusId));
		}

		genesysCloudStatus = new GenesysCloudStatus(genesysTargetStatus);
		salesforceStatus = new SalesforceStatus(salesforceTargetStatus);

		return new Response(genesysCloudStatus, salesforceStatus);
	}

	/**
	 * This method will get invoked once a Omni Presence status gets updated.
	 *  Method will find its mapped counterpart status in Genesys for status synchronisation
	 *
	 * @param data Provided event payload.
	 * @return Response payload
	 */
	public String onSalesforceStatusChange(String data) {
		return JSON.serialize(handleStatusChange(StatusOrigin.SALESFORCE, data));
	}

	/**
	 * This method will get invoked once Genesys CTI status gets updated.
	 *  Method will find its mapped counterpart status in Salesforce Omni Presence for status synchronisation
	 *
	 * @param data Provided event payload.
	 * @return Response payload
	 */
	public String onGenesysCloudStatusChange(String data) {
		return JSON.serialize(handleStatusChange(StatusOrigin.GENESYS, data));
	}
}