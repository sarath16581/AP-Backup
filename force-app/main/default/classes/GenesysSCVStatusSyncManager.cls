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

	private static Map<String,String> salesforceStatuses {
		get {
			if (salesforceStatuses == null) {
				salesforceStatuses = new Map<String,String>();

				ServicePresenceStatus[] spsList = ServicePresenceStatusSelector.newInstance().selectActiveStatuses();

				for (ServicePresenceStatus servicePresenceStatus :spsList) {
					salesforceStatuses.put(
						servicePresenceStatus.DeveloperName?.toUpperCase(),
						servicePresenceStatus.Id
					);
				}
			}

			return salesforceStatuses;
		}
		set;
	}

	private static Map<String,String> genesysStatuses {
		get {
			if (genesysStatuses == null) {
				genesysStatuses = new Map<String,String>();

				GenesysAgentStatusIdMapping__c[] mappings = GenesysAgentStatusIdMappingsSelector.newInstance().selectBySource('Genesys');

				for (GenesysAgentStatusIdMapping__c mapping :mappings) {
					genesysStatuses.put(mapping.Name?.toUpperCase(), mapping.StatusId__c);
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
		if (origin == StatusOrigin.SALESFORCE) {
			return genesysStatuses;
		} else if (origin == StatusOrigin.GENESYS) {
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
		System.debug(configMap);
		GenesysAgentStatusMapping__mdt gasm = configMap.get(statusChangeOrigin);

		return (Map<String,String>)JSON.deserialize(gasm.MappingData__c, Map<String,String>.class);
	}

	@TestVisible
	/**
	 * Get the statusId of mapped status Name
	 * @param origin StatusOrigin SALESFORCE / GENESYS
	 * @param originStatusName Status in the originating system
	 * @return StatusId for mapped status in the target system
	 */
	private static String getTargetStatus(StatusOrigin origin, String originStatusName) {
		if (String.isNotBlank(originStatusName)) {
			originStatusName = originStatusName.toUpperCase();
		}

		Map<String,String> targetStatusIdMappings = getStatusIdMappings(origin);
		Map<String,String> targetStatusNameMappings = getStatusNameMapping(origin);

		String targetStatusName = targetStatusNameMappings.get(originStatusName);
		String targetStatusId = targetStatusIdMappings.get(targetStatusName);

		System.debug(JSON.serializePretty(new Map<String,Object>{
			'origin' => origin,
			'originStatusName' => originStatusName,
			'targetStatusNameMappings' => targetStatusNameMappings,
			'targetStatusName' => targetStatusName,
			'targetStatusIdMappings' => targetStatusIdMappings,
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
			genesysTargetStatus = new genesysTargetStatus(getTargetStatus(origin, statusName));
		} else if (origin == StatusOrigin.GENESYS) {
			salesforceTargetStatus = new SalesforceTargetStatus(getTargetStatus(origin, presence));
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
		if (UserInfo.getUserId() == paulId) {
			GenesysSCVStatusSyncManager2 instance = new GenesysSCVStatusSyncManager2();
			return instance.onSalesforceStatusChange(data);
		}
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
		if (UserInfo.getUserId() == paulId) {
			GenesysSCVStatusSyncManager2 instance = new GenesysSCVStatusSyncManager2();
			return instance.onGenesysCloudStatusChange(data);
		}
		return JSON.serialize(handleStatusChange(StatusOrigin.GENESYS, data));
	}

	private static Id paulId = '0052v00000kLvGP';
}