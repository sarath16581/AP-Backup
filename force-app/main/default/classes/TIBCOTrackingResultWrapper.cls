/**
* @author Mohamed Atheek
* @date 30.01.2014
* @group Articles
* @tags Cases, SSSW, Articles, Safe Drop, SAP-EM
* @domain SSSW
* @description
* @changelog
* 2020-03-13  nathan.franklin@auspost.com.au  Added ability to pass in matched contacts from TibcoArticleService
* 2021-09-09	seth.heang@auspost.com.au		Uplift SF API version to 52
*/
public class TIBCOTrackingResultWrapper {
	public String trackingID { get; set; }
	public String returnCode { get; set; }
	public String resultDescription { get; set; }
	public TIBCOArticleWrapper articleDetails { get; set; }
	public TIBCOConsignmentWrapper consignmentDetails { get; set; }

	public Boolean Success {
		get {
			return returnCode == 'ESB-BUS-DATA-100';
		}
	}

	public TIBCOTrackingResultWrapper(Article__c a, Map<String, List<Article__c>> consArticles, Map<Id, List<EventMessage__c>> articleToEventMessages) {
		this(a, consArticles, articleToEventMessages, new Map<Id, Map<String, Contact>>());
	}

	public TIBCOTrackingResultWrapper(Article__c a, Map<String, List<Article__c>> consArticles, Map<Id, List<EventMessage__c>> articleToEventMessages, Map<Id, Map<String, Contact>> contactArticleMappings) {
		returnCode = 'ESB-BUS-DATA-100';
		if (a != null) {
			trackingID = a.trackingID__c;

			List<Article__c> aList = consArticles.get(a.ArticleID__c);
			if (aList == null) {
				articleDetails = new TIBCOArticleWrapper(a, articleToEventMessages, contactArticleMappings.get(a.Id));
			} else {
				consignmentDetails = new TIBCOConsignmentWrapper(a, aList, articleToEventMessages, contactArticleMappings);
			}
		}
	}

	public TIBCOTrackingResultWrapper(AuspostQueryTrackEventsSchema.TrackingResults tr) {
		System.debug('TrackResult:' + tr);
		if (tr != null) {
			trackingID = tr.TrackingID;
			returnCode = tr.ReturnCode;
			resultDescription = tr.ResultDescription;

			if (tr.ArticleDetails != null) {
				articleDetails = new TIBCOArticleWrapper(trackingID, tr.ArticleDetails);
			} else if (tr.ConsignmentDetails != null) {
				consignmentDetails = new TIBCOConsignmentWrapper(trackingID, tr.ConsignmentDetails);
			}
		}
	}


}