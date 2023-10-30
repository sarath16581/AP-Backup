public with sharing class CSQApprovalsController {
	private static final String TASK_SUBJECT_PENDING_INFORMATION = '{0} - Pending Information';

	/**
	 * Submit record for approval with provided comments
	 * @param recordId - The record's identifier
	 * @param comments - Optional comments on the approval 
	 * @exception AuraHandledException - Any errors upon submission
	 */ 
	@AuraEnabled
	public static void submitForApproval(Id recordId, String comments) {
		try {
			UserRecordAccess ura = UserRecordAccessSelector.newInstance().selectById(recordId);
			
			if (!ura.HasEditAccess) {
				throw new NoAccessException();
			}
			
			WithoutSharingDataAccessHelper noSharingInstance = new WithoutSharingDataAccessHelper();			
			// Commit status update
			noSharingInstance.dmlUpsert(new SObject[] {
				new Customer_Scoping_Questionnaire__c(
					Id = recordId,
					CSQ_Compliance_Check__c = true
				)
			});

			Exception prResult = convertProcessResult(
				adInstance.submitForApproval(recordId, comments)
			);
			
			if (prResult != null) {
				throw prResult;
			}
		} catch (DmlException dmlEx) {
			throw new AuraHandledException(dmlEx.getMessage());
		}
	}

	@TestVisible
	private static Exception convertProcessResult(Approval.ProcessResult pr) {
		DMLException result;

		if (!pr.isSuccess()) {
			List<String> errors = new List<String>();

			for (Database.Error err :pr.getErrors()) {
				errors.add(err.getMessage());

				if (err.fields != null && !err.fields.isEmpty()) {
					errors.add('Incorrect fields: ' + String.join(err.fields, ', '));
				}
			}

			result = new DmlException(String.join(errors, '; '));
		}

		return result;
	}

	@AuraEnabled
	public static CSQCloneService.CloneResult cloneCSQTree(Id recordId, List<String> cloneOptions) {
		try {
			if (!FeatureManagement.checkPermission('CSQ_Record_Duplication') && !Test.isRunningTest()) {
				throw new NoAccessException();
			}

			CSQCloneService csqClone = new CSQCloneService(new Set<String>(cloneOptions));
			return csqClone.execute(new Set<Id>{ recordId });
		} catch(Exception ex) {
			System.debug(ex.getMessage());
			System.debug(ex.getStackTraceString());
		//	System.debug(LoggingLevel.Error, ex.getMessage() + '\r\n' + ex.getStackTraceString());
		//	throw new AuraHandledException(ex.getMessage());
			throw ex;
		}
	}

	@AuraEnabled
	/**
	 * Submit record for approval with provided comments
	 * @param recordId - The record's identifier
	 * @param status - newly assigned approval status 
	 * @param comments - Optional comments on the update 
	 * @exception AuraHandledException - Any errors upon submission
	 */ 
	public static void updatePickupLocationStatus(Id recordId, String status, String comments) {
		Map<ProcessStatus,String> approvalStatusMap = new Map<ProcessStatus,String>{
			ProcessStatus.PENDING => 'Pending Information',
			ProcessStatus.RECEIVED => 'Received Information'
		};

		try {
			// Will throw NoSuchElementException if null or incorrect
			ProcessStatus procStatus = ProcessStatus.valueOf(status);

			Boolean canAccess = FeatureManagement.checkPermission('CSQ_Pending_Information') || Test.isRunningTest();

			if (canAccess) {
				// No need to get user record access when custom permission not assigned
				canAccess = UserRecordAccessSelector.newInstance().selectById(recordId).HasEditAccess;
			}

			if (!canAccess) {
				throw new NoAccessException();
			}

			List<SObject> upsertRecords = new List<SObject>();

			if (procStatus == ProcessStatus.PENDING) {
				PickUpLocationSelector pulSelector = PickUpLocationSelector.newInstance();
				Pick_Up_Location__c pul = pulSelector.selectById(new Set<Id>{ recordId }).get(recordId);				

				// Warning: This will throw an error once the CSQ record creator becomes inactive
				Id taskOwnerId = pul.OwnerId__c;

				upsertRecords.add(new Task(
					WhatId = recordId,
					OwnerId = taskOwnerId,
					Subject = String.format(
						TASK_SUBJECT_PENDING_INFORMATION,
						new Object[] { pul.CSQ__r.Name }
					),
					Type = 'Other',
					Category__c = 'Sales',
					Description = comments,
					ActivityDate = Date.today()
				));
			}

			upsertRecords.add(new Pick_Up_Location__c(
				Id = recordId,
				Pick_up_Location_Status__c = approvalStatusMap.get(procStatus)
			));

			//WithoutSharingDataAccessHelper noSharingInstance = new WithoutSharingDataAccessHelper(unitOfWork);
			WithoutSharingDataAccessHelper noSharingInstance = new WithoutSharingDataAccessHelper();			
			// Commit status update
			noSharingInstance.dmlUpsert(upsertRecords);
		} catch(Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	private Enum ProcessStatus {
		PENDING,
		RECEIVED
	}

	private static ApplicationDatabase adInstance {
		get {
			if (adInstance == null) {
				adInstance = ApplicationDatabase.getInstance();
			}

			return adInstance;
		}
		set;
	}

	private without sharing class WithoutSharingDataAccessHelper {
		private Database.UpsertResult[] dmlUpsert(List<SObject> upsertRecords) {
			return adInstance.dmlUpsert(upsertRecords);
		}
	}
}