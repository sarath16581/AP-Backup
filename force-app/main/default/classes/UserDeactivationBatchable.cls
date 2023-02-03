/**
 * @author Naveen Rajanna
 * @date 2023-01-27
 * @tag Batch
 * @tag User
 * @description Batch job to deactivate users who have been inactive and based on few more filters
 * and lastly remove all the assigned user package licenses
 * @changelog
 * 2023-01-27 - Initial creation
 */

public class UserDeactivationBatchable implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
	// default batch size
	private static final Integer DEFAULT_BATCH_SIZE = 200;
	// default number of days of inactivity after which a user should be deactivated
	private static final Integer DEFAULT_INACTIVITY_THRESHOLD_DAYS = 180;
	// default number of days to wait for deactivation after a user has been invited but has not yet logged in
	private static final Integer DEFAULT_LAST_CREATED_DAYS = 30;
	// contains today's datetime
	private static final String NOW_STRING = Datetime.now().format('yyyy-MM-dd_hhmmss');
	// number of characters to retrieve from error message
	private static final Integer MAX_FIELD_LENGTH = 255;
	// define all the User Types in scope for fetching users to deactivate
	private static final Set<String> USER_TYPE = new Set<String>{ 'Standard' };
	// define all the profiles to be excluded for fetching users to deactivate
	private static final Set<String> EXCLUDE_PROFILE = new Set<String>{ 'Sales Insights Integration User' };
	// batch size
	private Integer batchSize;
	// number of days of inactivity after which a user should be deactivated
	private Integer lastLoginDays;
	// number of days to wait for deactivation after a user has been invited but has not yet logged in
	private Integer lastInviteDays;
	// email where the summary needs to be sent
	private String notificationEmail;
	// contains map of user id and user sobject information for failed users
	private Map<Id, User> failedUserMap;
	// contains map of user id and error message for each user deactivation failure
	private Map<Id, String> userErrorMessageMap;
	// contains unique error status code
	private Set<String> errorTypeSet;
	// contains userIds which were successfully deactivated/updated
	private Set<Id> successIdSet;

	public UserDeactivationBatchable() {
		failedUserMap = new Map<Id, User>();
		userErrorMessageMap = new Map<Id, String>();
		errorTypeSet = new Set<String>();
		successIdSet = new Set<Id>();

		// fetch org defaults from Custom Settings and assign to class properties
		UserDeactivationSettings__c settings = UserDeactivationSettings__c.getOrgDefaults();
		lastLoginDays = settings.LastLoginDays__c != null ? Integer.valueOf(settings.LastLoginDays__c) : DEFAULT_INACTIVITY_THRESHOLD_DAYS;
		lastInviteDays = settings.LastInviteDays__c != null ? Integer.valueOf(settings.LastInviteDays__c) : DEFAULT_LAST_CREATED_DAYS;
		notificationEmail = settings.NotificationEmail__c != null ? String.valueOf(settings.NotificationEmail__c) : null;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		// Query for users who have been inactive and based on few more filters
		return UsersSelector.newInstance(
				0,
				new Set<SObjectField>{ User.Id, User.Name, User.Username, User.CreatedDate, User.LastAutoDeactivatedDate__c, User.LastLoginDate }
			)
			.selectUsersEligibleForDeactivationQueryLocator(USER_TYPE, lastLoginDays, lastInviteDays, EXCLUDE_PROFILE, new Set<Object>());
	}

	public void execute(Database.BatchableContext bc, List<User> scope) {
		try {
			List<User> updateable = new List<User>();
			for (User usr : scope) {
				// deactivate the user and set date to know when it was deactivated
				usr.IsActive = false;
				usr.LastAutoDeactivatedDate__c = Date.today();

				updateable.add(usr);
			}

			// perform the dml and allow partials
			List<Database.SaveResult> saveResults = ApplicationDatabase.getInstance().dmlUpdate(updateable, false);

			// analyze the results and save to collection for stats
			Integer i = 0;
			for (Database.SaveResult saveResult : saveResults) {
				if (saveResult.isSuccess()) {
					// success scenario
					successIdSet.add(updateable[i].Id);
				} else {
					// failure scenario
					failedUserMap.put(updateable[i].Id, updateable[i]);
					if (!saveResult.getErrors().isEmpty()) {
						Database.Error error = saveResult.getErrors()[0];
						String errCode = String.valueOf(error.getStatusCode());
						String errMsg = String.valueOf(error.getMessage()).left(MAX_FIELD_LENGTH);
						userErrorMessageMap.put(updateable[i].Id, errCode + ' : ' + errMsg);
						errorTypeSet.add(errCode);
					}
				}
				i++;
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance()
				.logException(
					ApplicationLogger.wrapException(ex),
					'User Deactivation',
					UserDeactivationBatchable.class.getName(),
					'execute bc',
					'Batch Job',
					ApplicationLogger.LoggingLevel.ERROR
				);
		}
	}

	public void finish(Database.BatchableContext bc) {
		try {
			AsyncApexJob jobDetail = [
				SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedDate, CompletedDate
				FROM AsyncApexJob
				WHERE Id = :BC.getJobId()
			];
			//System.debug('User Deactivation - ' + successIdSet.size() + ' success, ' + failedUserMap.size() + ' failures');
			sendEmail(jobDetail); // Send a summary email if any failures
			removeUserLicenses(); // Remove licenses for the deactivated users (if any)
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance()
				.logException(
					ApplicationLogger.wrapException(ex),
					'User Deactivation',
					UserDeactivationBatchable.class.getName(),
					'finish',
					'Batch Job',
					ApplicationLogger.LoggingLevel.ERROR
				);
		}
	}

	public void execute(SchedulableContext sc) {
		try {
			UserDeactivationSettings__c settings = UserDeactivationSettings__c.getOrgDefaults();
			batchSize = settings.BatchSize__c != null ? Integer.valueOf(settings.BatchSize__c) : DEFAULT_BATCH_SIZE;

			// invoke the batch
			Database.executeBatch(this, batchSize);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance()
				.logException(
					ApplicationLogger.wrapException(ex),
					'User Deactivation',
					UserDeactivationBatchable.class.getName(),
					'execute sc',
					'Batch Job',
					ApplicationLogger.LoggingLevel.ERROR
				);
		}
	}

	/**
	 * Prepare EmailMessage, send to notificationEmail, running user if any failures to deactivate users
	 * @param jobDetail AsyncJob Record
	 */
	private void sendEmail(AsyncApexJob jobDetail) {
		// if no errors then do nothing
		if (failedUserMap.isEmpty()) {
			return;
		}

		// Send an email to notification email notifying of job completion
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		Integer timeTakenMins = (Integer) ((jobDetail.CompletedDate.getTime() - jobDetail.CreatedDate.getTime()) / 60000);
		String errorTypes = '';
		for (String error : errorTypeSet) {
			errorTypes += error + '\n';
		}

		// define the body and append error types to the message body
		String plainBody = 'The UserDeactivationBatchable job with the following filters is completed.\n' +
			'\njob id: ' + jobDetail.Id +  
			'\nstatus: ' + jobDetail.Status +
			'\njobs processed: (' + jobDetail.JobItemsProcessed + ' out of ' + jobDetail.TotalJobItems + ') ' +
			'\noutcome: ' + successIdSet.size() + ' success, ' + failedUserMap.size() + ' failures' +
			'\ntimetaken: ' + timeTakenMins + ' mins' +
			'\n\nConfig: (ref: UserDeactivationSettings__c custom settings)\n' +
			'\nbatch size: ' + batchSize +
			'\nlast login (days): ' + lastLoginDays +
			'\nlast invite (days): ' + lastInviteDays +
			'\nIf any user needs to be excluded, then the relevant User.IsExcludedForAutoDeactivation must be checked.' +
			'\n\nerrors observed: (Refer attached for more details)\n\n' + errorTypes + '\n' + 'Thank you.';

		// add data to csv file
		String csvData = 'Id, Name, Username, Status, Error\n';
		for (Id id : failedUserMap.keySet()) {
			User usr = (User) failedUserMap.get(id);
			String errorMsg = userErrorMessageMap.containsKey(id) ? userErrorMessageMap.get(id) : '';
			String status = (usr.LastLoginDate == null)
				? 'Not logged in since creation on ' + usr.CreatedDate
				: 'Inactive since ' + usr.LastLoginDate;
			csvData += '"' + id + '","' + usr.Name + '","' + usr.UserName + '","' + status + '","' + errorMsg + '"\n';
			//System.debug('UserDeactivationBatchable Error: ' + csvData);
		}

		// Set parameters
		List<String> toAddress = new List<String>{ UserInfo.getUserEmail() };
		if (notificationEmail != null) {
			toAddress.add(notificationEmail);
		}
		mail.setToAddresses(toAddress);
		mail.setSubject('Action required: UserDeactivationBatchable job - ' + NOW_STRING);
		mail.setPlainTextBody(plainBody);

		// include csv file attachment
		Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
		attachment.setFileName('UserDeactivation_errors-' + NOW_STRING + '.csv');
		attachment.setBody(Blob.valueOf(csvData));
		mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });

		// Sends the email
		Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
	}

	/**
	 * Remove specific UserPackageLicenses for the deactivated UserIds
	 */
	private void removeUserLicenses() {
		// if no users were deactivated then do nothing
		if (successIdSet.isEmpty()) {
			return;
		}

		//System.debug('Remove Licenses for deactivated users: ' + successIdSet.size());
		// retrieve the ids of all allowed package licenses to pass to queueable
		List<PackageLicense> packageLicenseList = [SELECT Id FROM PackageLicense WHERE AllowedLicenses > 0];
		// make an async call to remove UserPackageLicenses for the deactivated UserIds
		System.enqueueJob(
			new UserLicenseHandlerQueueable(true, successIdSet, new Map<Id, PackageLicense>(packageLicenseList).keySet(), null, null, null)
		);
	}
}
