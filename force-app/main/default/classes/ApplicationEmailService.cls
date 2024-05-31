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
	 * API name for the Master email automation flow
	 */
	public static final String MASTER_FLOW_API_NAME = ''; // Use custom metadata 

	/**
	 * Prepares a wrapper object for Email notification based on provided details.
	 * 
	 * @param srcRecordId Source Record ID to use for the static email alert
	 * @param srcObjectType Type of the sObject
	 * @param emailAlertName API name of the pre-configured workflow email alert
	 * 
	 * @return EmailWrapper object of apex data type to be passed into Flow as input variable
	 */
	public ApplicationFlowEmailType generateEmailNotification(Id srcRecordId, sObjectType srcObjectType, String emailAlertName) {
		return new ApplicationFlowEmailType(srcRecordId, srcObjectType, emailAlertName);
	}

	/**
	 * Adds the email to registry. The email notification is sent only upon Dispatch method invocation.
	 * @param emailNotification Wrapper object containing details of email notification. This param should ideally be 
	 * 							instantiated using the generateEmailNotification() method
	 */
	public void queueEmailNotification(ApplicationFlowEmailType emailNotification) {
		if(emailNotification != null) {
			emailNotificationRegistry.put(emailNotification.generateRegistryKey(), emailNotification);
		} else {
			throw new EmailServiceException('Cannot queue up an empty email notification. Object not instantiated.');
		}
	}

	/**
	 * @param registryKey Key for the email notification object to be deleted
	 * @return Removed email notification wrapper object from Registry
	 */
	public ApplicationFlowEmailType deletePendingEmailNotification(String registryKey) {
		return emailNotificationRegistry?.remove(registryKey);
	}

	/**
	 * @return 
	 */
	public void dispatchPendingEmailNotification(String registryKey) {
		
	}	

	public void dispatchAllPendingEmailNotification() {
		
	}	

	public class EmailServiceException extends Exception {}
}