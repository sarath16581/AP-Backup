/**
 * @description 
 * The ApplicationEmailService is part of the proposed email framework, intended to establish a best practice for dealing with email notifications.
 * This service class encapsulates and provides methods to leverage flow based static email alerts. The available methods include support for queuing, de-queuing and 
 * dispatching of email notifications.
 * 
 * This framework helps streamline the currently de-fragmented logic on hot objects. It also addresses a potential gap in email delivery for recursive 
 * scenarios in trigger order of execution.
 * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_order_of_execution.htm
 * 
 * Details about the framework can be found at https://australiapost.jira.com/wiki/spaces/SF/pages/3116468473/Email+Notifications+-+Framework+To+be+reviewed
* 
 * Execution Order:
 * 1. 
 *  
 * @author Parveen Kaushik
 * @date 2024-05-20
 * @changelog
 */
public inherited sharing class ApplicationEmailService {

	/**
	 * Email Registry is a collection that aids in maintaining accuracy for queued email notifications until they are dispatched (via Flows) when the calling code is ready
	 * The key for the registry map is Record Id + Email Alert Name
	 */
	@testVisible
	private Map<String, ApplicationFlowEmailType> emailNotificationRegistry;

	/**
	 * Keeps track of all email notification keys that have been queued on the service in the same transaction. Used to ensure that the service only sends a unique email once,
	 * even in scenarios where an email has already been dispatched earlier in the transaction, then re-queued.
	 */
	@testVisible
	private Set<String> emailNotificationDispatchKeyHistory;


	/**
	 * API name for the Master email automation flow
	 */
	public static final String MASTER_FLOW_API_NAME = 'FlowEmailService_MasterFlow';


	public static ApplicationEmailService getInstance() {
		return (ApplicationEmailService) Application.Utilities.getInstance(ApplicationEmailService.class);
	}


	public ApplicationEmailService() {
		this.emailNotificationRegistry = new Map<String, ApplicationFlowEmailType>();
		this.emailNotificationDispatchKeyHistory = new Set<String>();
	}

	/**
	 * Adds the email to registry. The email notification is sent only upon Dispatch method invocation.
	 * 
	 * @param srcRecordId Source Record ID to use for the static email alert
	 * @param srcObjectType Type of the sObject
	 * @param emailAlertName API name of the pre-configured workflow email alert
	 */
	public void queueEmailNotification(Id srcRecordId, sObjectType srcObjectType, String emailAlertName) {
		this.queueEmailNotification(new ApplicationFlowEmailType(srcRecordId, srcObjectType, emailAlertName));
	}

	/**
	 * Adds the email to registry. The email notification is sent only upon Dispatch method invocation.
	 * @param emailNotification Wrapper object containing details of email notification. This param should ideally be 
	 * 							instantiated using the generateEmailNotification() method
	 */
	public void queueEmailNotification(ApplicationFlowEmailType emailNotification) {
		if (emailNotification != null) {
			String registryKey = emailNotification.generateRegistryKey();

			if (!this.emailNotificationDispatchKeyHistory.contains(registryKey)) {
				emailNotificationRegistry.put(registryKey, emailNotification);
				//emailNotificationRegistryKeyHistory.add(registryKey);
			} else {
				System.debug(LoggingLevel.INFO, 'Cannot queue this email notification. ' + registryKey 
					+ ' has already been dispatched previously on this instance of ApplicationEmailService.');
			}
			
		} else {
			throw new EmailServiceException('Cannot queue up an empty email notification. Object not instantiated.');
		}
	}

	/**
	 * @param registryKey Key for the email notification object to be deleted
	 * @return Removed email notification wrapper object from Registry
	 */
	public ApplicationFlowEmailType removePendingEmailNotification(String registryKey) {
		return emailNotificationRegistry?.remove(registryKey);
	}

	/**
	 * Removes all email notifications from the registry
	 * 
	 * @return List of all email notifications that have been removed from the registry. If registry is null or empty, an empty List is returned.
	 */
	public List<ApplicationFlowEmailType> removeAllPendingEmailNotifications() {
		
		// retrieve all entries in the registry
		List<ApplicationFlowEmailType> pendingEmailNotifications = new List<ApplicationFlowEmailType>();
		pendingEmailNotifications.addAll(getRegistryValues());
		
		// empty the registry
		this.emailNotificationRegistry?.clear();
		
		// return the registry values
		return pendingEmailNotifications;
	}
	

	/**
	 * @return 
	 */
	public void dispatchPendingEmailNotification(String registryKey) {
		// attempt to remove email notification from registry
		ApplicationFlowEmailType pendingEmailNotification = removePendingEmailNotification(registryKey);

		// if email notification with registry key exists, dispatch to flow
		if (pendingEmailNotification != null) {
			dispatchEmailNotifications(new List<ApplicationFlowEmailType> {pendingEmailNotification});
		}
	}	

	/**
	 * Dispatches all pending email notifications and clears the registry.
	 */
	public void dispatchAllPendingEmailNotifications() {

		// remove all pending email notifications from the registry and store in a list
		List<ApplicationFlowEmailType> pendingEmailNotifications = removeAllPendingEmailNotifications();

		// if there are pending notifications, dispatch to flow
		if (!pendingEmailNotifications.isEmpty()) {
			dispatchEmailNotifications(pendingEmailNotifications);
		}
	}

	/**
	 * Accepts a list of email notifications and dispatches them to the master Flow.
	 * 
	 * @param emailNotifications List of email notifications to be dispatched
	 */
	private void dispatchEmailNotifications(List<ApplicationFlowEmailType> emailNotifications) {

		if (!emailNotifications.isEmpty()) {

			// add email notifications to dispatch history so the same email notification 
			// can't be registered again in the same transaction
			for (ApplicationFlowEmailType emailNotification : emailNotifications) {
				this.emailNotificationDispatchKeyHistory.add(emailNotification.generateRegistryKey());
			}

			// Group all email notifications by object to minimise looping in the master Flow
			List<ApplicationFlowEmailTypeObjectCollection> emailNotificationsGroupedByObject = generateFlowEmailTypeObjectCollections(emailNotifications);

			// Add the grouped email notifications to the flow parameters
			Map<String, Object> flowParams = new Map<String, Object> {
				'flowEmailTypeRequestsGroupedByObject' => emailNotificationsGroupedByObject
			};

			// start the Flow
			Flow.Interview flowEmailServiceDispatcher = Flow.Interview.createInterview(MASTER_FLOW_API_NAME, flowParams);
			flowEmailServiceDispatcher.start();
			
		}
	}

	/**
	 * Query the number of pending email notifications that have been registered
	 * 
	 * @return The number of email notifications in the registry
	 */
	public Integer getRegistrySize() {
		return this.emailNotificationRegistry != null ? this.emailNotificationRegistry.size() : 0;
	}

	/**
	 * Retrieve all email notifications stored in the registry
	 * 
	 * @return List of all email notifications registered
	 */
	public List<ApplicationFlowEmailType> getRegistryValues() {
		List<ApplicationFlowEmailType> registryValues = new List<ApplicationFlowEmailType>();

		if (this.emailNotificationRegistry != null) {
			registryValues.addAll(this.emailNotificationRegistry.values());
		}

		return registryValues;

	}

	/** 
	 * Groups all email notifications by object type.
	 * 
	 * @param emailNotifications List of email notifications to be grouped
	 * @return List of email notifications grouped by object type
	 * 
	 * @testVisible
	 *
	 */
	@TestVisible
	private List<ApplicationFlowEmailTypeObjectCollection> generateFlowEmailTypeObjectCollections(List<ApplicationFlowEmailType> emailNotifications) {

		List<ApplicationFlowEmailTypeObjectCollection> emailNotificationsByObject = new List<ApplicationFlowEmailTypeObjectCollection>();

		if (emailNotifications != null && !emailNotifications.isEmpty()) {
			
			Map<String, ApplicationFlowEmailTypeObjectCollection> emailCollectionsByObjectName = new Map<String, ApplicationFlowEmailTypeObjectCollection>();

			// process each email notification
			for (ApplicationFlowEmailType emailNotification : emailNotifications) {

				// retrieve existing collection for the current email notification's object
				ApplicationFlowEmailTypeObjectCollection objectCollection = emailCollectionsByObjectName.get(emailNotification.objectType);

				// if no collection exists yet for the current notification's object, create one
				if (objectCollection == null) {
					objectCollection = new ApplicationFlowEmailTypeObjectCollection(emailNotification.objectType);
					emailCollectionsByObjectName.put(emailNotification.objectType, objectCollection);
				}

				// add the current email notification to the object collection
				objectCollection.addFlowEmailType(emailNotification);

			}

			// add the object collections to the return List
			emailNotificationsByObject.addAll(emailCollectionsByObjectName.values());
		}

		return emailNotificationsByObject;
	}

	public class EmailServiceException extends Exception {}
}