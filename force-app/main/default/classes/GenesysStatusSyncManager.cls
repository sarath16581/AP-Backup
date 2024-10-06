/**
 * @description	Omni Presence status synchronisation to Genesys CTI status and vice versa between
 *	Genesys Cloud Platform and Salesforce.
 *	NOTE:
 *	- Genesys Cloud statuses are obtained from mapping config in Custom Metadata Object
 *		GenesysAgentStatusMapping__mdt
 *
 *	Incoming Genesys Status Change
 *	- Find the GenesysAgentStatusMapping__mdt for the Genesys Status Id
 *	- Set the Salesforce Target PresenceStatusId accordingly
 *
 *	Incoming Omni Status Change
 *	- Find the GenesysAgentStatusMapping__mdt for the PresenceStatus Developer Name
 *	- Set the Genesys Target StatusId + StatusName accordingly
 *	- Known Genesys limitation: Division specific secundairy statuses cannot be used
 *			WorkAround: Introduced field SyncDirection__c to have direction specific mappings
 *
 *	The global declaration is required to provide access to purecloud Managed Package namespace
 * @author		Paul Perry
 * @date		15/08/2024
 * @changelog
 */
global with sharing class GenesysStatusSyncManager implements genesyscloud.GenesysSCVExtension.Status {
	/**
	 * datadump from genesys:
	 *
		[
			{ "id": "227b37e2-f1d0-4dd0-8f50-badd7cf6d158"," type": "System", "status": "Break" },
			{ "id": "26085809-a4aa-4b4f-beda-903583763330"," type": "User", "status": "Lunch Break" },
			{ "id": "2ce3fee1-da35-49e7-bb3e-3f2292d54073"," type": "User", "status": "Training" },
			{ "id": "2edc5ec5-4095-42bc-8e1f-612467b7b12f"," type": "User", "status": "Technical Issues" },
			{ "id": "31fe3bac-dea6-44b7-bed7-47f91660a1a0"," type": "System", "status": "Busy" },
			{ "id": "3cfd6036-db2c-4a2d-aa07-b8e30f9b7c8f"," type": "User", "status": "Break" },
			{ "id": "3fd96123-badb-4f69-bc03-1b1ccc6d8014"," type": "System", "status": "Meal" },
			{ "id": "4d3b99c9-67ce-4604-a3bd-834fd9820166"," type": "User", "status": "Personal" },
			{ "id": "5e5c5c66-ea97-4e7f-ac41-6424784829f2"," type": "System", "status": "Away" },
			{ "id": "6a3af858-942f-489d-9700-5f9bcdcdae9b"," type": "System", "status": "Available" },
			{ "id": "7ffa01cd-7866-4ad7-8faa-31e11b42f51f"," type": "System", "status": "Idle" },
			{ "id": "bbdff279-7ae1-48ea-bade-7831d7234c64"," type": "System", "status": "Meeting" },
			{ "id": "ccf3c10a-aa2c-4845-8e8d-f59fa48c58e5"," type": "System", "status": "Offline" },
			{ "id": "d2390a99-8546-bad9-8f0a-219548e8aeb0"," type": "System", "status": "Training" },
			{ "id": "e08eaf1b-ee47-4fa9-a231-1200e284798f"," type": "System", "status": "On Queue" },
			{ "id": "e665a132-a45a-46cc-8f98-44082e2f8b62"," type": "User", "status": "Meeting" }
		]
	 */

	/**
	 * This method will get invoked once a Omni Presence status gets updated.
	 *  Method will find its mapped counterpart status in Genesys for status synchronisation
	 *
	 * @param data Provided event payload.
	 * @return Response payload
	 */
	public String onSalesforceStatusChange(String data) {
		Map<String,Object> payloadMap = (Map<String,Object>)JSON.deserializeUntyped(data);
		String salesforceTargetStatusName = (String)getObjectAttribute('salesforceStatus.targetStatus.statusApiName', payloadMap);

		try {
			putObjectAttribute(
				'genesysCloudStatus.targetStatus',
				payloadMap,
				getNewGenesysStatus(salesforceTargetStatusName)
			);
		} catch(Exception ex) {
			ApplicationLogger.getInstance().logException(
				new ApplicationLogger.ExceptionWrapper(ex),
				'Genesys Status Sync Manager',
				'GenesysStatusSyncManager',
				'onSalesforceStatusChange',
				'N.A.',
				ApplicationLogger.LoggingLevel.ERROR
			);

			// Results in Status Misalignment warning in the UI
			return null;
		}

		return JSON.serialize(payloadMap);
	}

	/**
	 * This method will get invoked once Genesys CTI status gets updated.
	 *  Method will find its mapped counterpart status in Salesforce Omni Presence for status synchronisation
	 *
	 * @param data Provided event payload.
	 * @return Response payload
	 */
	public String onGenesysCloudStatusChange(String data) {
		Map<String,Object> payloadMap = (Map<String,Object>)JSON.deserializeUntyped(data);
		String genesysTargetStatusId = (String)getObjectAttribute('genesysCloudStatus.targetStatus.id', payloadMap);
		String primaryStatusName = String.valueOf(getObjectAttribute('genesysCloudStatus.targetStatus.systemPresence', payloadMap) ?? '');

		try {
			putObjectAttribute(
				'salesforceStatus.targetStatus',
				payloadMap,
				getNewSalesforceStatus(genesysTargetStatusId, primaryStatusName)
			);
		} catch(Exception ex) {
			ApplicationLogger.getInstance().logException(
				new ApplicationLogger.ExceptionWrapper(ex),
				'Genesys Status Sync Manager',
				'GenesysStatusSyncManager',
				'onGenesysCloudStatusChange',
				'N.A.',
				ApplicationLogger.LoggingLevel.ERROR
			);

			// Results in Status Misalignment warning in the UI
			return null;
		}

		return JSON.serialize(payloadMap);
	}

	/**
	 * Obtain the Genesys status from provided Salesforce PresenceStatus
	 */
	public static Map<String,Object> getNewGenesysStatus(String salesforceTargetStatusName) {
		GenesysAgentStatusMapping__mdt mapping = GenesysAgentStatusMappingsSelector.newInstance()
			.selectBySalesforcePresenceStatus(salesforceTargetStatusName, null);

		if (mapping == null) {
			throw new GenesysStatusSyncException('Mapping not found for Salesforce Presence Status: ' + salesforceTargetStatusName);
		}

		return new Map<String,Object>{
			'id' => mapping.GenesysStatusId__c,
			'systemPresence' => mapping.GenesysStatusLabel__c?.toUpperCase()
		};
	}

	public static Map<String,Object> getNewSalesforceStatus(String genesysTargetStatusId, String primaryStatusName) {
		// Find GenesysAgentStatusMapping__mdt by genesys status Id
		GenesysAgentStatusMapping__mdt mapping = GenesysAgentStatusMappingsSelector.newInstance()
			.selectByGenesysStatusId(genesysTargetStatusId, null);

		if (mapping == null) {
			throw new GenesysStatusSyncException('Mapping not found for Salesforce Presence Status: "' + primaryStatusName + '" ID: ' + genesysTargetStatusId);
		}

		// Find related ServicePresenceStatus by DeveloperName
		ServicePresenceStatus presenceStatus = ServicePresenceStatusSelector.newInstance()
			.selectByDeveloperName(mapping.SalesforcePresenceStatus__c, null);

		if (presenceStatus == null) {
			throw new GenesysStatusSyncException('Salesforce Presence Status: ' + primaryStatusName + ' does not exists');
		}

		return new Map<String,Object>{
			'statusId' => presenceStatus.Id,
			'statusName' => mapping.SalesforcePresenceStatus__c
		};
	}

	/**
	 * Returns provided attributeName as object value from Map<String,Object>
	 * @param attributeName pathname of attribute - eg 'main.subVal'
	 * @param sourceObjMap Map<String,Object> - eg {"main": { "subVal": true }}
	 * @return Object value or null if not found - true with the given examples above
	 */
	public static Object getObjectAttribute(String attributeName, Object sourceObjMap) {
		String[] attributeNames = attributeName.split('\\.', 2);
		String currentAttribute = attributeNames.remove(0);

		try {
			Map<String,Object> objectMap = (Map<String,Object>)sourceObjMap;
			Object result = objectMap.get(currentAttribute);

			if (!attributeNames.isEmpty() && result != null) {
				result = getObjectAttribute(attributeNames[0], result);
			}

			return result;
		} catch(Exception ex) {
			return null;
		}
	}

	/**
	 * Updates a value in a Map<String,Object> using provided path attributeName and value
	 * @param attributeName pathname of attribute - eg 'main.subVal'
	 * @param sourceObjMap Map<String,Object> - eg {"main": { "subVal": true }}
	 * @param value (any) - eg false, would result into {"main": { "subVal": false }}
	 */
	public static void putObjectAttribute(String attributeName, Object sourceObjMap, Object value) {
		String[] attributeNames = attributeName.split('\\.');
		String targetAttribute = attributeNames.remove(attributeNames.size() - 1);
		Map<String,Object> parentObjMap = (Map<String,Object>)sourceObjMap;

		if (!attributeNames.isEmpty()) {
			parentObjMap = (Map<String,Object>)getObjectAttribute(String.join(attributeNames, '.'), parentObjMap);
		}

		parentObjMap.put(targetAttribute, value);
	}

	public class GenesysStatusSyncException extends Exception { }
}