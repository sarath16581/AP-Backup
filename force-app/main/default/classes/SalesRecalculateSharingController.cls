/**
* @author Rajneewa Silva
* @date 2023-01-23
* @group Controller
* @tag Controller
* @domain Sales
* @test SalesRecalculateSharingController_Test
* @description Controller class for Recalculating Sales Team Sharing.
* @changelog
* 2023-01-23 - Ranjeewa Silva - Created.
*/
public with sharing class SalesRecalculateSharingController {

	/**
	 * Recalculate sales team sharing for child records of the account id passed in. Delegates to SalesRecordSharingService
	 * to recalculate sharing asynchronously.
	 *
	 * @param accountId Id of the account for sharing recalculation
	 */
	@AuraEnabled
	public static void recalculateSalesTeamSharing(Id accountId) {
		try {
			if (accountId != null){
				SalesRecordSharingService.getInstance().enqueueChildRecordsSharingHandlerQueueable(new Set<Id>{accountId});
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}