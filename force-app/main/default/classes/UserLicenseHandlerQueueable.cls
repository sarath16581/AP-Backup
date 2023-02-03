/**
 * @author Naveen Rajanna
 * @date 2023-01-27
 * @tag Queueable
 * @tag User
 * @description Queueable job to delete/insert UserPackageLicenses and PermissionSetLicenses for the supplied UserIds
 * usage: if you want to delete only user package licenses for a given userIds, remaining parameters can be null see below
 * UserLicenseHandlerQueueable(true, userIdSet, packageIdSet, null, null, null);
 * @changelog
 * 2023-01-27 - Initial creation
 */
public class UserLicenseHandlerQueueable implements Queueable {
	// number of characters to retrieve from error message
	private static final Integer MAX_FIELD_LENGTH = 255;
	// contains today's datetime
	private static final String NOW_STRING = Datetime.now().format('yyyy-MM-dd_hhmmss');
	// used to test job chain in test class
	@TestVisible
	private static Boolean doChain = false;
	// number of dml rows to be processed in a DML statement
	private static Integer dmlRecordLimit = 2000;
	// specify false to insert license assignments or true to delete existing license assignments
	private Boolean isDelete;
	// UserIds for which licenses needs to be added or removed
	private Set<Id> userIdSet;
	// Package License Ids to be added or removed for given UserIdSet
	private Set<Id> packageIdSet;
	// Permission Set Ids to be added or removed for given UserIdSet
	private Set<Id> permissionSetIdSet;
	// Permission Set Group Ids to be added or removed for given UserIdSet
	private Set<Id> permissionSetGroupIdSet;
	// Permission Set License Ids to be added or removed for given UserIdSet
	private Set<Id> permissionSetLicenseIdSet;

	// List of UserPackageLicense records to be added or removed (based on isDelete)
	private List<UserPackageLicense> userPackageLicenseList;
	// List of PermissionSetAssignment records to be added or removed (based on isDelete)
	private List<PermissionSetAssignment> permissionSetAssignmentList;
	// List of PermissionSetLicenseAssign records to be added or removed (based on isDelete)
	private List<PermissionSetLicenseAssign> permissionSetLicenseList;

	// Set of errors encountered during DML
	private Map<Id, String> errorMap;

	public UserLicenseHandlerQueueable(
		Boolean isDelete,
		Set<Id> userIdSet,
		Set<Id> packageIdSet,
		Set<Id> permissionSetIdSet,
		Set<Id> permissionSetGroupIdSet,
		Set<Id> permissionSetLicenseIdSet
	) {
		this.isDelete = isDelete;
		this.userIdSet = userIdSet;
		this.packageIdSet = packageIdSet;
		this.permissionSetIdSet = permissionSetIdSet;
		this.permissionSetGroupIdSet = permissionSetGroupIdSet;
		this.permissionSetLicenseIdSet = permissionSetLicenseIdSet;
		userPackageLicenseList = new List<UserPackageLicense>();
		permissionSetAssignmentList = new List<PermissionSetAssignment>();
		permissionSetLicenseList = new List<PermissionSetLicenseAssign>();
	}

	public UserLicenseHandlerQueueable(
		Boolean isDelete,
		List<UserPackageLicense> userPackageLicenseList,
		List<PermissionSetAssignment> permissionSetAssignmentList,
		List<PermissionSetLicenseAssign> permissionSetLicenseList
	) {
		this.isDelete = isDelete;
		this.userPackageLicenseList = userPackageLicenseList != null ? userPackageLicenseList : new List<UserPackageLicense>();
		this.permissionSetAssignmentList = permissionSetAssignmentList != null ? permissionSetAssignmentList : new List<PermissionSetAssignment>();
		this.permissionSetLicenseList = permissionSetLicenseList != null ? permissionSetLicenseList : new List<PermissionSetLicenseAssign>();
	}

	private void init() {
		// fetch DML Record Limit from Custom Settings
		UserDeactivationSettings__c dmlSetting = UserDeactivationSettings__c.getOrgDefaults();
		if (dmlSetting.DMLRecordLimit__c != null) {
			dmlRecordLimit = Integer.valueOf(dmlSetting.DMLRecordLimit__c);
		}
		errorMap = new Map<Id, String>();
	}

	public void execute(QueueableContext context) {
		try {
			init(); // initialise
			//System.debug('dmlRecordLimit: ' + dmlRecordLimit);
			//System.debug('isDelete: ' + isDelete);
			if (userIdSet != null && !userIdSet.isEmpty()) {
				//System.debug('userIdSet size: ' + userIdSet.size());
				generateUserPackageLicense(); // generate userPackageLicenseList for mentioned packageIdSet
				generatePermissionSetAssignment(); // generate permissionSetAssignmentList for mentioned permissionSetIdSet, permissionSetGroupIdSet
				generatePermissionSetLicense(); // generate permissionSetLicenseList for mentioned permissionSetLicenseIdSet
			}
			processUserPackageLicense(); // process DML for userPackageLicenseList - List<UserPackageLicense>
			processPermissionSetAssignment(); // process DML for permissionSetAssignmentList - List<PermissionSetAssignment>
			processPermissionSetLicense(); // process DML for permissionSetLicenseList - List<PermissionSetListAssign>
			// email errors (if any) to the job creator
			sendMail();
			// if not all dml rows were processed (based on the DML Row limit), chain to another queueable job
			if (!userPackageLicenseList.isEmpty() || !permissionSetAssignmentList.isEmpty() || !permissionSetLicenseList.isEmpty()) {
				if (Test.isRunningTest()) {
					doChain = true;
				} else {
					System.enqueueJob(
						new UserLicenseHandlerQueueable(isDelete, userPackageLicenseList, permissionSetAssignmentList, permissionSetLicenseList)
					);
				}
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance()
				.logException(
					ApplicationLogger.wrapException(ex),
					'User License Deactivation',
					UserLicenseHandlerQueueable.class.getName(),
					'execute',
					'Queueable',
					ApplicationLogger.LoggingLevel.ERROR
				);
		}
	}

	/**
	 * Generate List of UserPackageLicense to be processed (insert/delete based on isDelete flag)
	 * for mentioned packageIdSet (packageIdSet)
	 */
	private void generateUserPackageLicense() {
		// if supplied package Ids are empty, nothing to action
		if (packageIdSet == null || packageIdSet.isEmpty()) {
			return;
		}

		if (isDelete) {
			// delete operation - fetch the exisiting assignments
			userPackageLicenseList = [
				SELECT Id, UserId, PackageLicenseId
				FROM UserPackageLicense
				WHERE UserId IN :userIdSet AND PackageLicenseId IN :packageIdSet
				ORDER BY UserId ASC
			];
		} else {
			// insert operation - add assignments to collection
			for (Id packageId : packageIdSet) {
				for (Id userId : userIdSet) {
					userPackageLicenseList.add(new UserPackageLicense(PackageLicenseId = packageId, UserId = userId));
				}
			}
		}
	}

	/**
	 * Generate List of PermissionSetAssignment to be processed (insert/delete based on isDelete flag)
	 * for mentioned permissionSetIdSet (permissionSets), permissionSetGroupIdSet (permissionSetGroups)
	 */
	private void generatePermissionSetAssignment() {
		Boolean hasPermissionSet = !(permissionSetIdSet == null || permissionSetIdSet.isEmpty());
		Boolean hasPermissionSetGroup = !(permissionSetGroupIdSet == null || permissionSetGroupIdSet.isEmpty());
		// if both supplied permissionSet Ids and permissionSetGroup Ids are empty, nothing to action
		if (!hasPermissionSet && !hasPermissionSetGroup) {
			return;
		}

		if (isDelete) {
			// delete operation - fetch the exisiting assignments
			String query = 'SELECT Id, AssigneeId, PermissionSetId, PermissionSetGroupId FROM PermissionSetAssignment WHERE AssigneeId IN :userIdSet AND';
			if (hasPermissionSet && hasPermissionSetGroup) {
				query += ' (PermissionSetId IN :permissionSetIdSet OR PermissionSetGroupId IN :permissionSetGroupIdSet)';
			} else {
				query += hasPermissionSet ? ' PermissionSetId IN :permissionSetIdSet' : ' PermissionSetGroupId IN :permissionSetGroupIdSet';
			}
			permissionSetAssignmentList = Database.query(query);
		} else {
			// insert operation - add assignments to collection
			if (hasPermissionSet) {
				for (Id permissionSetId : permissionSetIdSet) {
					for (Id userId : userIdSet) {
						permissionSetAssignmentList.add(new PermissionSetAssignment(PermissionSetId = permissionSetId, AssigneeId = userId));
					}
				}
			}
			if (hasPermissionSetGroup) {
				for (Id permissionSetGroupId : permissionSetGroupIdSet) {
					for (Id userId : userIdSet) {
						permissionSetAssignmentList.add(
							new PermissionSetAssignment(PermissionSetGroupId = permissionSetGroupId, AssigneeId = userId)
						);
					}
				}
			}
		}
	}

	/**
	 * Generate List of PermissionSetLicenseAssign to be processed (insert/delete based on isDelete flag)
	 * for mentioned permissionSetLicense (permissionSetLicenseIdSet)
	 */
	private void generatePermissionSetLicense() {
		// if supplied permissionSetLicense Ids are empty, nothing to action
		if (permissionSetLicenseIdSet == null || permissionSetLicenseIdSet.isEmpty()) {
			return;
		}

		if (isDelete) {
			// delete operation - fetch the exisiting assignments
			permissionSetLicenseList = [
				SELECT Id, AssigneeId, PermissionSetLicenseId
				FROM PermissionSetLicenseAssign
				WHERE AssigneeId IN :userIdSet AND PermissionSetLicenseId IN :permissionSetLicenseIdSet
				ORDER BY AssigneeId ASC
			];
		} else {
			// insert operation - add assignments to collection
			for (Id permissionSetLicenseId : permissionSetLicenseIdSet) {
				for (Id userId : userIdSet) {
					permissionSetLicenseList.add(
						new PermissionSetLicenseAssign(PermissionSetLicenseId = permissionSetLicenseId, AssigneeId = userId)
					);
				}
			}
		}
	}

	/**
	 * Process (insert/delete based on isDelete flag) specified dmlRecordLimit rows from userPackageLicenseList (List<UserPackageLicense>)
	 */
	private void processUserPackageLicense() {
		if (userPackageLicenseList == null || userPackageLicenseList.isEmpty()) {
			return;
		}
		//System.debug('upl incoming: ' + userPackageLicenseList.size());
		List<UserPackageLicense> processeable = new List<UserPackageLicense>();
		for (Integer i = 0; i < dmlRecordLimit; i++) {
			if (userPackageLicenseList.isEmpty()) {
				break;
			}
			processeable.add(userPackageLicenseList.remove(0));
		}

		if (!processeable.isEmpty()) {
			//System.debug('upl processed: ' + processeable.size());
			if (isDelete) {
				processDMLDeleteResults(ApplicationDatabase.getInstance().dmlDelete(processeable, false));
			} else {
				processDMLSaveResults(ApplicationDatabase.getInstance().dmlInsert(processeable, false));
			}
		}
		//System.debug('upl remaining: ' + userPackageLicenseList.size());
	}

	/**
	 * Process (insert/delete based on isDelete flag) specified dmlRecordLimit rows from permissionSetAssignmentList (List<PermissionSetAssignment>)
	 */
	private void processPermissionSetAssignment() {
		if (permissionSetAssignmentList == null || permissionSetAssignmentList.isEmpty()) {
			return;
		}
		//System.debug('psa incoming: ' + permissionSetAssignmentList.size());
		List<PermissionSetAssignment> processeable = new List<PermissionSetAssignment>();
		for (Integer i = 0; i < dmlRecordLimit; i++) {
			if (permissionSetAssignmentList.isEmpty()) {
				break;
			}
			processeable.add(permissionSetAssignmentList.remove(0));
		}

		if (!processeable.isEmpty()) {
			//System.debug('psa processed: ' + processeable.size());
			if (isDelete) {
				processDMLDeleteResults(ApplicationDatabase.getInstance().dmlDelete(processeable, false));
			} else {
				processDMLSaveResults(ApplicationDatabase.getInstance().dmlInsert(processeable, false));
			}
		}
		//System.debug('psa remaining: ' + permissionSetAssignmentList.size());
	}

	/**
	 * Process (insert/delete based on isDelete flag) specified dmlRecordLimit rows from permissionSetLicenseList (List<PermissionSetLicenseAssign>)
	 */
	private void processPermissionSetLicense() {
		if (permissionSetLicenseList == null || permissionSetLicenseList.isEmpty()) {
			return;
		}
		//System.debug('psl incoming: ' + permissionSetLicenseList.size());
		List<PermissionSetLicenseAssign> processeable = new List<PermissionSetLicenseAssign>();
		for (Integer i = 0; i < dmlRecordLimit; i++) {
			if (permissionSetLicenseList.isEmpty()) {
				break;
			}
			processeable.add(permissionSetLicenseList.remove(0));
		}

		if (!processeable.isEmpty()) {
			//System.debug('psl processed: ' + processeable.size());
			if (isDelete) {
				processDMLDeleteResults(ApplicationDatabase.getInstance().dmlDelete(processeable, false));
			} else {
				processDMLSaveResults(ApplicationDatabase.getInstance().dmlInsert(processeable, false));
			}
		}
		//System.debug('psl remaining: ' + permissionSetLicenseList.size());
	}

	/**
	 * Process the DML Delete results and save errors to collection
	 */
	private void processDMLDeleteResults(List<Database.DeleteResult> deleteResults) {
		if (deleteResults.isEmpty()) {
			return;
		}
		// analyze the results and save to collection for stats
		for (Database.DeleteResult deleteResult : deleteResults) {
			if (!deleteResult.isSuccess() && !deleteResult.getErrors().isEmpty()) {
				String errorMsg = String.valueOf(deleteResult.getErrors()[0].getMessage()).left(MAX_FIELD_LENGTH);
				//System.debug('UserLicenseHandlerQueueable Error: ' + deleteResult.getId() + ' - ' + errorMsg);
				errorMap.put(deleteResult.getId(), errorMsg);
			}
		}
	}

	/**
	 * Process the DML Save results and save errors to collection
	 */
	private void processDMLSaveResults(List<Database.SaveResult> saveResults) {
		if (saveResults.isEmpty()) {
			return;
		}
		// analyze the results and save to collection for stats
		for (Database.SaveResult saveResult : saveResults) {
			if (!saveResult.isSuccess() && !saveResult.getErrors().isEmpty()) {
				String errorMsg = String.valueOf(saveResult.getErrors()[0].getMessage()).left(MAX_FIELD_LENGTH);
				//System.debug('UserLicenseHandlerQueueable Error: ' + saveResult.getId() + ' - ' + errorMsg);
				errorMap.put(saveResult.getId(), errorMsg);
			}
		}
	}

	/**
	 * Prepare EmailMessage, send to running user if any failures
	 */
	private void sendMail() {
		if (errorMap.isEmpty()) {
			return;
		}

		//System.debug('UserLicenseHandlerQueueable failed: ' + errorMap.size());
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

		// add data to csv file
		String csvData = 'Id, Error\n';
		for (Id id : errorMap.keySet()) {
			csvData += '"' + id + '","' + errorMap.get(id) + '"\n';
		}

		// Set parameters
		mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
		mail.setSubject('Action required: UserLicenseHandlerQueueable job - ' + NOW_STRING);
		mail.setPlainTextBody('The UserLicenseHandlerQueueable job resulted with attached ' + errorMap.size() + ' errors.');

		// include csv file attachment
		Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
		attachment.setFileName('UserLicenseDeactivation_errors-' + NOW_STRING + '.csv');
		attachment.setBody(Blob.valueOf(csvData));
		mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });

		// Sends the email
		Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
	}
}
