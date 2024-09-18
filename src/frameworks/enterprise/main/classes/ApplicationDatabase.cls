/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Utility
 * @tag Utility
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-08-02 - Nathan Franklin - Added return results for database methods and the ability to do allOrNothing
 * 2020-08-16 - arjun.singh@auspost.com.au - Added methods for  rollback and savepoint
 * 2020-10-18 - Nathan Franklin - Increased API Version to 49
 * 2022-05-09 - Ranjeewa Silva - Added support for upsert operation.
 * 2022-03-14 - Nathan Franklin - uplifted to version 52
 * 2024-05-17 - Harry Wang - Added support for dml option on dmlInsert
 */
public inherited sharing class ApplicationDatabase {

	public static ApplicationDatabase getInstance() {
		return (ApplicationDatabase)Application.Utilities.getInstance(ApplicationDatabase.class);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public List<Database.SaveResult> dmlInsert(List<SObject> objList) {
		return dmlInsert(objList, true);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public List<Database.SaveResult> dmlInsert(List<SObject> objList, Boolean allOrNothing) {
		return Database.insert(objList, allOrNothing);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	// Need Approval from Boris/Nathan
	public List<Database.SaveResult> dmlInsert(List<SObject> objList, Database.DMLOptions dmlOptions) {
		return Database.insert(objList, dmlOptions);
	}

	/**
	 * Creates new sObject records or updates existing sObject records. Does not allow partial success 
	 * (i.e. allOrNothing = true). Allows to combine insert and update on different SObjectTypes using 1 single
	 * DML statement
	 *
	 * @param objList list of sObject records to upsert
	 *
	 * @return Database.UpsertResults[] if successful. An exception is thrown in the case of any failures.
	 */
	public List<Database.UpsertResult> dmlUpsert(List<SObject> objList) {
		return Database.upsert(objList, true);
	}

	/**
	 * Creates new sObject records or updates existing sObject records, using the specified field to determine the presence
	 * of existing objects. Does not allow partial success (i.e. allOrNothing = true).
	 *
	 * @param objList list of sObject records to upsert
	 * @param idField id / external id field to determine the presence of existing records.
	 *
	 * @return Database.UpsertResults[] if successful. An exception is thrown in the case of any failures.
	 */
	public List<Database.UpsertResult> dmlUpsert(List<SObject> objList, SObjectField idField) {
		return dmlUpsert(objList, idField, true);
	}

	/**
	 * Creates new sObject records or updates existing sObject records, using the specified field to determine the presence
	 * of existing objects. The optional allOrNothing parameter specifies whether partial success is to be allowed.
	 *
	 * @param objList list of sObject records to upsert
	 * @param idField id / external id field to determine the presence of existing records.
	 * @param allOrNothing specifies whether the operation allows partial success
	 *
	 * @return Database.UpsertResults[] if 'allOrNothing' is false. If 'allOrNothing' is not set or is set true, an exception
	 * is thrown if the method is not successful.
	 */
	public List<Database.UpsertResult> dmlUpsert(List<SObject> objList, SObjectField idField, Boolean allOrNothing) {
		return Database.upsert(objList, idField, allOrNothing);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public List<Database.SaveResult> dmlUpdate(List<SObject> objList) {
		return dmlUpdate(objList, true);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public List<Database.SaveResult> dmlUpdate(List<SObject> objList, Boolean allOrNothing) {
		return Database.update(objList, allOrNothing);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public List<Database.DeleteResult> dmlDelete(List<SObject> objList) {
		return dmlDelete(objList, true);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public List<Database.DeleteResult> dmlDelete(List<SObject> objList, Boolean allOrNothing) {
		return Database.delete(objList, allOrNothing);
	}

	/**
	 * Note: return value to enable stubbed mocks, always true, or else an exception is thrown
	 */
	public Boolean eventPublish(List<SObject> objList) {
		EventBus.publish(objList);
		return true;
	}
	/**
	 * Note: return restult as System.savepoint , used for rollback
	 */
	public System.Savepoint dmlSetSavePoint() {
		System.Savepoint sSavePoint = Database.setSavepoint();
		return sSavePoint;
	}
	/**
	 * Note: return result as true after roll back
	 */
	public Boolean dmlRollback(System.Savepoint databaseSavepoint) {
		Database.rollback(databaseSavepoint);
		return true;
	}

	public Id enqueueJob(Object queueable) {
		return System.enqueueJob(queueable);
	}

	public Boolean revokeTokenAccess(Id ssoProviderId, String providerName, Id userId, String remoteIdentifier) {
		return Auth.AuthToken.revokeAccess(ssoProviderId, providerName.toLowerCase(), userId, remoteIdentifier);
	}

	/**
	 * Submit a records for approval with provided comments
	 * @param recordId
	 * @param comments
	 */
	public Approval.ProcessResult submitForApproval(Id recordId, String comments) {
		Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
		req.setComments(comments);
		req.setObjectId(recordId);
		return Approval.process(req);
	}
	
	public List<DatacloudProxy.FindDuplicatesResult> findDuplicates(List<SObject> candidates) {
		// Average duration of serialisation roundtrip is ~2.73 msec (tested with 1 single match record * 1,000 times)
		return (List<DatacloudProxy.FindDuplicatesResult>)JSON.deserialize(
			JSON.serialize(Datacloud.FindDuplicates.findDuplicates(candidates)),
			List<DatacloudProxy.FindDuplicatesResult>.class
		);
	}
}