public with sharing class CSQApprovalsController {
	@AuraEnabled
	/**
     * Submit record for approval with provided comments
     * @param recordId - The record's identifier
     * @param comments - Optional comments on the approval 
     * @exception AuraHandledException - Any errors upon submission
     */ 
	public static void submitForApproval(Id recordId, String comments) {
		try {
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
	/**
     * Submit record for approval with provided comments
     * @param recordId - The record's identifier
     * @param status - newly assigned approval status 
     * @param comments - Optional comments on the update 
     * @exception AuraHandledException - Any errors upon submission
     */ 
	public static void updatePickupLocationStatus(Id recordId, String status, String comments) {
		Map<ProcessStatus,String> approvalStatusMap = new Map<ProcessStatus,String>{
			ProcessStatus.Pending => 'Pending Information',
			ProcessStatus.Received => 'Received Information'
		};

		try {
			// Will throw NoSuchElementException if null or incorrect
			ProcessStatus procStatus = ProcessStatus.valueOf(status);

			UserRecordAccess ura = UserRecordAccessSelector.newInstance().selectById(recordId);
			
			if (!ura.HasEditAccess) {
				throw new NoAccessException();
			}

			unitOfWork.registerDirty(new Pick_Up_Location__c(
				Id = recordId,
				Pick_up_Location_Status__c = approvalStatusMap.get(procStatus),
				Notes__c = comments
			));

			WithoutSharingDataAccessHelper noSharingInstance = new WithoutSharingDataAccessHelper(unitOfWork);
			// Commit status update
			noSharingInstance.commitWork();
		} catch(Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	private Enum ProcessStatus {
		Pending,
		Received
	}

	private static ApplicationUnitOfWork unitOfWork {
		get {
			if (unitOfWork == null) {
				unitOfWork = ApplicationUnitOfWork.newInstance(new List<SObjectType>{
					Pick_Up_Location__c.SObjectType
				});
			}

			return unitOfWork;
		}
		set;
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
		private ApplicationUnitOfWork unitOfWork;

		private WithoutSharingDataAccessHelper(ApplicationUnitOfWork uow) {
			unitOfWork = uow;
		}

		private void commitWork() {
			unitOfWork.commitWork();
		}
	}
}