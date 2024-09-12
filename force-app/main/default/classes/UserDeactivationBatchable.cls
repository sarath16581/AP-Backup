/**
 * @author Naveen Rajanna
 * @date 2023-01-27
 * @tag Batch
 * @tag User
 * @description Batch job to deactivate users who have been inactive and based on few more filters
 * and lastly remove all the assigned user package licenses
 * @changelog
 * 2023-01-27 - Initial creation
 * 2024-03-01 - REQ3451627 - Minor Change to expose Excluded Profile in Custom Settings
 * 2024-08-01 - Mona Raghav -  REQ3575796 - Feature added to notify the users via Email few days prior to the deactivation -
 * Execute method modification and new method sendNotificationEmail added.
 * 2024-08-19 - Mona Raghav -  REQ3575796 - Notification email to be sent via no-reply instead of salesforce support user.
 */

 public class UserDeactivationBatchable implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
	// contains today's datetime
	private static final String NOW_STRING = Datetime.now().format('yyyy-MM-dd_hhmmss');
	// number of characters to retrieve from error message
	private static final Integer MAX_FIELD_LENGTH = 255;
	// define all the User Types in scope for fetching users to deactivate
	private static final Set<String> DEFAULT_USERTYPE = new Set<String>{'Standard'};

	// contains map of user id and user sobject information for failed users
	private Map<Id, User> failedUserMap;
	// contains map of user id and error message for each user deactivation failure
	private Map<Id, String> userErrorMessageMap;
	// contains unique error status code
	private Set<String> errorTypeSet;
	// contains userIds which were successfully deactivated/updated
	private Set<Id> successIdSet;
	// contains user details to send the email notification
    private List<User> userEmailNotification;
	// contains user details to deactivate
	private List<User> updateable;

	// default batch size
	private static final Integer DEFAULT_BATCH_SIZE = 20;
	// default number of days to wait for deactivation after a user has been invited but has not yet logged in
	private static final Integer DEFAULT_LASTINVITE_DAYS = 30;
	// default number of days of inactivity after which a user should be deactivated
	private static final Integer DEFAULT_LASTLOGIN_DAYS = 90;
	// default number of days of inactivity after which a notification should be sent to the user
	private static final Integer DEFAULT_NOTIFICATION_LASTLOGIN_DAYS = 75;
	// default notification email
	private static final String DEFAULT_NOTIFICATIONEMAIL = 'DLITRCPCMSalesforceSupport@auspost.com.au';
	// define all the profiles to be excluded for fetching users to deactivate
	private static final List<String> DEFAULT_EXCLUDEDPROFILES = new List<String>{'Sales Insights Integration User','SalesforceIQ Integration User','B2BMA Integration User'};
	// define all the profiles to be included for sending email notification prior to deactivation
	private static final List<String> DEFAULT_NOTIFICATIONPROFILES = new List<String>{'MyNetwork Portal'};
	// define from notification email
	private static final String DEFAULT_FROM_NOTIFICATIONEMAIL = 'no-reply@auspost.com.au';

	private static UserDeactivationSettings__c CONFIG {
		get {
			if(CONFIG == null) {
				CONFIG = UserDeactivationSettings__c.getOrgDefaults();
			}
			return CONFIG;
		}
		private set;
	}

	private static final Integer CONFIG_BATCHSIZE = Integer.valueOf(CONFIG.BatchSize__c) > 0 ? Integer.valueOf(CONFIG.BatchSize__c) : DEFAULT_BATCH_SIZE;
	private static final Integer CONFIG_LASTINVITE_DAYS = Integer.valueOf(CONFIG.LastInviteDays__c) > 0 ? Integer.valueOf(CONFIG.LastInviteDays__c) : DEFAULT_LASTINVITE_DAYS;
	private static final Integer CONFIG_LASTLOGIN_DAYS = Integer.valueOf(CONFIG.LastLoginDays__c) > 0 ? Integer.valueOf(CONFIG.LastLoginDays__c) : DEFAULT_LASTLOGIN_DAYS;
	private static final Integer CONFIG_NOTIFICATION_LASTLOGIN_DAYS = Integer.valueOf(CONFIG.LastLoginDaysNotification__c) > 0 ? Integer.valueOf(CONFIG.LastLoginDaysNotification__c) : DEFAULT_NOTIFICATION_LASTLOGIN_DAYS;
	private static final String CONFIG_NOTIFICATIONEMAIL = String.valueOf(CONFIG?.NotificationEmail__c) ?? DEFAULT_NOTIFICATIONEMAIL;
	private static final List<String> CONFIG_EXCLUDEDPROFILES = CONFIG?.ExcludedProfileNames__c?.split(',') ?? DEFAULT_EXCLUDEDPROFILES;
	private static final List<String> CONFIG_NOTIFICATIONPROFILES = CONFIG?.NotificationProfileNames__c?.split(',') ?? DEFAULT_NOTIFICATIONPROFILES;
	private static final String CONFIG_FROMNOTIFICATIONEMAIL = String.valueOf(CONFIG?.NotificationFromEmail__c) ?? DEFAULT_FROM_NOTIFICATIONEMAIL;
	
	//Fields to query
	private static final Set<SObjectField> USER_FIELDS = new Set<SObjectField>{ User.Id, User.Name, User.Username, User.Email, User.CreatedDate, User.MyNetwork_Retail_User__c, User.LastAutoDeactivatedDate__c, User.LastLoginDate };
    private static final Set<SObjectField> PROFILE_FIELDS = new Set<SObjectField>{ Profile.Name };

	public UserDeactivationBatchable() {
		failedUserMap = new Map<Id, User>();
		userErrorMessageMap = new Map<Id, String>();
		errorTypeSet = new Set<String>();
		successIdSet = new Set<Id>();
		userEmailNotification = new List<User>();
		updateable = new List<User>();
	}

	// Getter for userEmailNotification - This function is added to cover email notification feature in test class
    public List<User> getUserEmailNotification() {
        return userEmailNotification;
    }

     // Setter for userEmailNotification - This function is added to cover email notification feature in test class
     public void setUserEmailNotification(List<User> listOfUsers) {
         userEmailNotification = listOfUsers;
     }

	 // Getter for updateable - This function is added to cover email notification feature in test class
	 public List<User> getUpdateable() {
        return updateable;
    }

     // Setter for updateable - This function is added to cover email notification feature in test class
     public void setUpdateable(List<User> listOfUsers) {
		updateable = listOfUsers;
     }

	public Database.QueryLocator start(Database.BatchableContext bc) {
		// Query for users who have been inactive and based on few more filters
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
			User.SObjectType => USER_FIELDS, Profile.SObjectType =>  PROFILE_FIELDS
		};
		return UsersSelector.newInstance(
				0,
				fieldOverrides
			)
			.selectUsersEligibleForDeactivationQueryLocator(DEFAULT_USERTYPE, CONFIG_NOTIFICATION_LASTLOGIN_DAYS, CONFIG_LASTINVITE_DAYS, new Set<String>(CONFIG_EXCLUDEDPROFILES), new Set<Object>{UsersSelector.Options.WITH_PROFILE});
	}

	public void execute(Database.BatchableContext bc, List<User> scope) {
		try {
			for (User usr : scope) {				
				if(usr.LastLoginDate < Datetime.now().addDays(-CONFIG_LASTLOGIN_DAYS) || usr.LastLoginDate == null) {
					// deactivate the user and set date to know when it was deactivated
					usr.IsActive = false;
					usr.LastAutoDeactivatedDate__c = Date.today();
					updateable.add(usr);
				} else if(CONFIG_NOTIFICATIONPROFILES.contains(usr.Profile.Name) && !usr.MyNetwork_Retail_User__c && usr.LastLoginDate < Datetime.now().addDays(-CONFIG_NOTIFICATION_LASTLOGIN_DAYS) && usr.LastLoginDate > Datetime.now().addDays(-CONFIG_LASTLOGIN_DAYS)) {
					//Send email notification
					userEmailNotification.add(usr);
				}
			}

			if(updateable.size() > 0) {
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
			if(updateable.size() > 0) {
				AsyncApexJob jobDetail = [
					SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedDate, CompletedDate
					FROM AsyncApexJob
					WHERE Id = :bc.getJobId()
				];
				System.debug('User Deactivation - ' + successIdSet.size() + ' success, ' + failedUserMap.size() + ' failures');
				sendEmail(jobDetail); // Send a summary email if any failures
				removeUserLicenses(); // Remove licenses for the deactivated users (if any)
			}
			if(userEmailNotification.size() > 0) {
				sendNotificationEmail(); // Send Email to Notify user to prevent the deactivation
			}
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
			Database.executeBatch(this, CONFIG_BATCHSIZE);
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
	 * Prepare EmailMessage, send to user's email address to notify them to prevent the deactivation of their account
	 */
	private void sendNotificationEmail() {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: CONFIG_FROMNOTIFICATIONEMAIL];
		  if ( owea.size() > 0 ) {
			  mail.setOrgWideEmailAddressId(owea.get(0).Id);
		  }

		// define the body
		String htmlBody = 
        '<html>' +
        '<body>' +
        '<p>Hi,</p>' +
        '<p>This is a notification that your MyNetwork account is scheduled for deactivation due to inactivity.</p>' +
        '<p>To maintain access, please <a href="https://mynetwork.auspost.com.au">log in to MyNetwork</a> asap.</p>' +
        '<p>For any questions or support, please email <a href="mailto:MyNetworkSupport@auspost.com.au">MyNetworkSupport@auspost.com.au</a>.</p>' +
        '<p>Best Regards,<br>' +
        'Salesforce Support Team</p>' +
        '</body>' +
        '</html>';

		//Set parameters
        List<String> bccAddress = new List<String>();
		for (User usr : userEmailNotification) {	
			if(usr.Email != null) {
				bccAddress.add(usr.Email);
			}			
		}
		mail.setBccAddresses(bccAddress);
		mail.setSubject('Action required: Prevent User Deactivation');
		mail.setHtmlBody(htmlBody);

		// Sends the email
		if(bccAddress.size() > 0) {
			Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
		}		
	}

	/**
	 * Prepare EmailMessage, send to CONFIG_NOTIFICATIONEMAIL, running user if any failures to deactivate users
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
			'\nbatch size: ' + CONFIG_BATCHSIZE +
			'\nlast login (days): ' + CONFIG_LASTLOGIN_DAYS +
			'\nlast invite (days): ' + CONFIG_LASTINVITE_DAYS +
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
		if (CONFIG_NOTIFICATIONEMAIL != null) {
			toAddress.add(CONFIG_NOTIFICATIONEMAIL);
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