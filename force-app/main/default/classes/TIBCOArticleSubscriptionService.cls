/**
 * @description TIBCO Article Subscription Service sends the subscription notification to SAP via SOAP API service
 * @author Seth Heang
 * @changelog:
 * 2024-09-11 - Seth Heang - created
 */
public with sharing class TIBCOArticleSubscriptionService {
	@TestVisible
	private static final String ARTICLE_SUBSCRIPTION_FAILURE = 'Article Subscription failed with false acknowledgement.';
	private static final String ARTICLE_SUBSCRIPTION = 'Services/CustomerContractManagement_v1/CreateAdminEventPortEndpoint';

	public static TIBCOArticleSubscriptionService newInstance() {
		return (TIBCOArticleSubscriptionService) Application.Utilities.newInstance(TIBCOArticleSubscriptionService.class);
	}

	/**
	 * @description send article subscription notification to TIBCO then handle the response and update the ImpactedArticle and Article
	 * @param impactedArticles
	 */
	public void sendArticleSubscriptionNotifications(List<ImpactedArticle__c> impactedArticles){
		List<SObject> updatableSObjects = new List<SObject>();
		List<ApplicationLogger.ExceptionWrapper> exceptionWrappers = new List<ApplicationLogger.ExceptionWrapper>();

		TIBCOArticleSubscriptionSOAPService.Notification service = new TIBCOArticleSubscriptionSOAPService.Notification();
		service.endpoint_x = 'callout:TIBCO_BW' + ARTICLE_SUBSCRIPTION;

		for (ImpactedArticle__c impactedArticle : impactedArticles){
			try {
				TIBCOArticleSubscriptionSOAPService.CaseNotification notification = buildCaseNotificationRequestPayload(
						impactedArticle.ArticleId__c,
						impactedArticle.Case__r
				);

				Id organizationId = UserInfo.getOrganizationId();
				String sfdcBaseURL = Url.getOrgDomainUrl().toExternalForm();
				String enterpriseUrl = sfdcBaseURL + '/services/Soap/c/29.0/' + organizationId;
				String partnerUrl = sfdcBaseURL + '/services/Soap/u/29.0/' + organizationId;
				String sessionId = UserInfo.getSessionId();

				Boolean result = service.notifications(
						organizationId,
						null,
						sessionId,
						enterpriseUrl,
						partnerUrl,
						notification
				);

				updatableSObjects.addAll(
						handleArticleSubscriptionResponse(
							result,
							impactedArticle)
				);
			} catch (ArticleSubscriptionException ex) {
				updatableSObjects.add(
						new ImpactedArticle__c(
								Id = impactedArticle.Id,
								SubscriptionErrorCode__c = ex.getMessage()
						)
				);
				exceptionWrappers.add(ApplicationLogger.wrapException(ex));
			} catch (Exception ex) {
				updatableSObjects.add(
						new ImpactedArticle__c(
								Id = impactedArticle.Id,
								SubscriptionErrorCode__c = ex.getTypeName() + ':' + ex.getMessage()
						)
				);
				exceptionWrappers.add(ApplicationLogger.wrapException(ex));
			}

			// log exceptions in bulk
			if (!exceptionWrappers.isEmpty()){
				ApplicationLogger.getInstance()
						.logException(exceptionWrappers, 'ArticleSubscription', TIBCOArticleSubscriptionService.class.getName(), 'sendArticleSubscriptionNotifications', 'ImpactedArticleTrigger', ApplicationLogger.LoggingLevel.ERROR);
			}

			if (!updatableSObjects.isEmpty()) {
				ApplicationDatabase.getInstance().dmlUpdate(updatableSObjects);
			}
		}
	}

	/**
	 * @description build case notification request payload attribute mapping
	 * @param articleNumber
	 * @param caseRecord
	 *
	 * @return TIBCOArticleSubscriptionSOAPService.CaseNotification
	 */
	private TIBCOArticleSubscriptionSOAPService.CaseNotification buildCaseNotificationRequestPayload(String articleNumber, Case caseRecord){
		TIBCOArticleSubscriptionSOAPService.CaseNotification notification = new TIBCOArticleSubscriptionSOAPService.CaseNotification();
		notification.Id = caseRecord.Id; // Case Id
		notification.sObject_x = new TIBCOArticleSubscriptionSchema.Case_x();
		notification.sObject_x.Id = caseRecord.Id; // case.Id
		notification.sObject_x.ArticleCount_xc = '1'; // hardcoded
		notification.sObject_x.CaseNumber = caseRecord.CaseNumber; // case number
		notification.sObject_x.EventCode_xc = 'Subscribe';  // Case.EventCode__c defaults "Subscribe" in formula field
		notification.sObject_x.FacilityOrOutletWCC_xc = caseRecord.FacilityOrOutletWCC__c; // formula field 111894 for consumer or 111931 for business
		notification.sObject_x.LastModifiedDate = caseRecord.LastModifiedDate; // Case.LastModifiedDate
		notification.sObject_x.OwnerUserName_xc = caseRecord.OwnerUserName__c; // username formula field from Case.Owner.User.Username
		notification.sObject_x.ReferenceID_xc = articleNumber; // article to create event for
		notification.sObject_x.Subject = caseRecord.Subject;
		notification.sObject_x.Type_x = caseRecord.Type;
		return notification;
	}

	/**
	 * @description handle the article subscription response from TIBCO and throw ArticleSubscriptionException if applicable
	 * @param result
	 * @param impactedArticle
	 * @throws ArticleSubscriptionException
	 * @return Article__c
	 */
	private List<SObject> handleArticleSubscriptionResponse(Boolean result, ImpactedArticle__c impactedArticle){
		List<SObject> updatableObjects = new List<SObject>();
		if(result == true){
			Article__c updatableArticle = new Article__c(
					Id = impactedArticle.Article__c,
					Subscribed__c = true
			);
			ImpactedArticle__c updatabledImpactedArticle = new ImpactedArticle__c(
					Id = impactedArticle.Id,
					Subscribed__c = true
			);

			updatableObjects.add(updatableArticle);
			updatableObjects.add(updatabledImpactedArticle);
			return updatableObjects;
		} else {
			ArticleSubscriptionException ex = new ArticleSubscriptionException(ARTICLE_SUBSCRIPTION_FAILURE);
			throw ex;
		}
	}

	public class ArticleSubscriptionException extends Exception { }
}