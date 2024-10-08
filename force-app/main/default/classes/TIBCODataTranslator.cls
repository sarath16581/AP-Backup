/**
 * @author Mohamed Atheek
 * @date 30.01.2014
 * @group Articles
 * @tags Cases, SSSW, Articles, Safe Drop, SAP-EM
 * @domain SSSW
 * @Test TIBCOArticleService_Test,TIBCOUtilsTest,TIBCO_Test,BSPConsignmentSearch_Test,TIBCODataVisualizerComponentCont_Test
 * @description
 * @changelog
 * 19.09.2016  Eric.Shen@auspost.com.au  modified to allow Snap It missing item enquiry type cases to have product category & subcategory
 *									   auto populated based on SAP EM returned info.
 * 03.10.2016  Snigdha.Sahu@auspost.com.au  INC0624598
 * 2017-10-02  nathan.franklin@auspost.com.au  Refactored code and removed link to cases functionality.
 * 2017-10-29  nathan.franklin@auspost.com.au  Added error logging for failure article / consignment upserts
 * 2020-04-01  nathan.franklin@auspost.com.au  Remove a few redundant save() calls and tidied up error notifications
 * 2021-09-09	seth.heang@auspost.com.au   Uplift SF API version to 52
 * 2021-10-01 - Nathan Franklin - Removed the clone capability to ensure the ID is set by references so the callers of this class get use it
*/
public without sharing class TIBCODataTranslator {

	public static TIBCODataTranslator newInstance() {
		return (TIBCODataTranslator)Application.Utilities.newInstance(TIBCODataTranslator.class);
	}

	//Consignment Id to Consignment(Article)
	@TestVisible
	private Map<String, Article__c> consignments = new Map<String, Article__c>();
	Map<String, List<Article__c>> consignmentsWithArticles = new Map<String, List<Article__c>>();

	//Article Id to Article
	@TestVisible
	private Map<String, Article__c> articles = new Map<String, Article__c>();

	//Event Id to Event Message
	@TestVisible
	private Map<String, EventMessage__c> eventMessages = new Map<String, EventMessage__c>();

	private List<TIBCOTrackingResultWrapper> trackingResults;

	private static final String DATE_TIME_FORMAT = 'ddMMyyyyHHmmssSSS';

	public TIBCODataTranslator(List<TIBCOTrackingResultWrapper> trackingResults) {
		this.trackingResults = trackingResults;
		translate();
	}

	// Need this for proper mocking
	public TIBCODataTranslator() {}

	public TIBCODataTranslator translate(List<TIBCOTrackingResultWrapper> trackingResults) {
		this.trackingResults = trackingResults;
		translate();
		return this;
	}

	public void save() {
		save(true, false);
	}

	public void save(Boolean showMessages) {
		save(showMessages, false);
	}

	public void save(Boolean deprecated1, boolean deprecated2, boolean showMessages) {
		save(showMessages, false);
	}

	public void save(Boolean deprecated1 /* linkToCases */, boolean deprecated2 /* refreshCaseDetails */, boolean showMessages, boolean deprecated3 /* linkToChildArticleIfSingleArticleConsignment */) {
		save(showMessages, false);
	}

	public void save(Boolean showMessages, Boolean throwException) {

		System.debug('Saving consignment:' + consignments);
		System.debug('Saving articles: ' + articles);

		if (consignments.size() > 0) {
			try {
				upsert consignments.values() ArticleID__c;
			} catch(Exception e) {
				System.debug('---Exception consignments:' + e);

				// this is most likely due to a request running parallel to this one which can happpen from the MiniCaseComponent.
				if(!e.getMessage().contains('DUPLICATE_VALUE')) {
					if (showMessages) {
						ApexPages.addMessages(e);
					}
					if(throwException) {
						throw e;
					}
				}
			}
		}

		if (articles.size() > 0) {
			try {
				upsert articles.values() ArticleID__c;
			} catch(Exception e) {
				System.debug('---Exception articles:' + e);

				// this is most likely due to a request running parallel to this one which can happpen from the MiniCaseComponent.
				if(!e.getMessage().contains('DUPLICATE_VALUE')) {
					if (showMessages) {
						ApexPages.addMessages(e);
					}
					if(throwException) {
						throw e;
					}
				}
			}
		}

		if (eventMessages.size() > 0) {
			try {
				upsert eventMessages.values() EventID__c;
			} catch (Exception e) {

				// this is most likely due to a request running parallel to this one which can happpen from the MiniCaseComponent.
				System.debug('---Exception eventMessages:' + e);
				if (!e.getMessage().contains('DUPLICATE_VALUE')) {
					if (showMessages) {
						ApexPages.addMessages(e);
					}
					if(throwException) {
						throw e;
					}
				}
			}
		}
	}

	private void translate() {
		for (TIBCOTrackingResultWrapper tr : trackingResults) {
			if (tr.articleDetails != null) {
				addArticle(tr.articleDetails, null);
				addEventMessages(tr.articleDetails);
			} else if (tr.consignmentDetails != null) {
				addConsignment(tr.consignmentDetails);
				addEventMessages(tr.consignmentDetails);
			}
		}
	}

	private void addConsignment(TIBCOConsignmentWrapper cw) {
		System.debug('---addConsignment:' + cw);
		Article__c c = createConsignment(cw);

		if (c.RecordTypeId == null) //this is null if Article is from SAP, this has a value if Article is from SFDC
		{
			c.RecordType = new RecordType(Name = Constants.RECORDTYPE_NAME_ARTICLE_CONSIGNMENT);
		}

		if (!String.isBlank(c.ArticleID__c)) {
			consignments.put(c.ArticleID__c.toUpperCase(), c);
			consignmentsWithArticles.put(c.ArticleID__c.toUpperCase(), new List<Article__c>());
		}

		for (TIBCOArticleWrapper aw : cw.articles) {
			consignmentsWithArticles.get(c.ArticleID__c.toUpperCase()).add(addArticle(aw, c));
		}
	}

	private Article__c addArticle(TIBCOArticleWrapper aw, Article__c consignment) {
		System.debug('---addArticle:' + aw);
		Article__c a = createArticle(aw);

		if (a.RecordTypeId == null) //this is null if Article is from SAP, this has a value if Article is from SFDC
		{
			a.RecordType = new RecordType(Name = Constants.RECORDTYPE_NAME_ARTICLE_ARTICLE);
		}

		if (consignment != null && a.Consignment__c == null) {

			if (consignment.ArticleID__c == a.ArticleID__c) //To fix defects 66 & 67. Removing consignment having the same Id as article
			{
				consignments.remove(toUpper(a.ArticleID__c));
			} else {
				a.Consignment__r = new Article__c(ArticleID__c = consignment.ArticleID__c);
			}
		}
		articles.put(toUpper(a.ArticleID__c), a);
		return a;
	}

	private void addEventMessages(TIBCOConsignmentWrapper cw) {
		for (TIBCOArticleWrapper aw : cw.articles) {
			addEventMessages(aw);
		}
	}

	private void addEventMessages(TIBCOArticleWrapper aw) {
		System.debug('---addEventMessages:' + aw.eventMessages);
		for (TIBCOEventMessageWrapper ew : aw.eventMessages) {
			EventMessage__c em = createEventMessage(ew, aw);
			if (em.Article__c == null) //this is null if EM is from SAP, this has a value if EM is from SFDC
			{
				em.Article__r = new Article__c(ArticleID__c = aw.proxyArticle.ArticleID__c);
			}

			if (!eventMessages.containsKey(toUpper(em.EventID__c))) {
				eventMessages.put(toUpper(em.EventID__c), em);
			}
		}
	}

	private String toUpper(String s) {
		return s != null ? s.toUpperCase() : s;
	}

	private Article__c createConsignment(TIBCOConsignmentWrapper cw) {
//		Article__c c = cw.proxyConsignment.clone(false, true);
//		c.Name = cw.proxyConsignment.ArticleID__c;
//		return c;
		cw.proxyConsignment.Name = cw.proxyConsignment.ArticleID__c;
		return cw.proxyConsignment;
	}

	private Article__c createArticle(TIBCOArticleWrapper aw) {
//		Article__c a = aw.proxyArticle.clone(false, true);
//		a.Name = aw.proxyArticle.ArticleID__c;
//		return a;
		aw.proxyArticle.Name = aw.proxyArticle.ArticleID__c;
		return aw.proxyArticle;
	}

	private EventMessage__c createEventMessage(TIBCOEventMessageWrapper ew, TIBCOArticleWrapper aw) {
//		EventMessage__c em = ew.proxyEM.clone(false, true);
//		if (em.EventID__c == null) {
//			em.EventID__c = getEventMessageKey(ew, aw);
//		}
//		return em;
		if (ew.proxyEM.EventID__c == null) {
			ew.proxyEM.EventID__c = getEventMessageKey(ew, aw);
		}
		return ew.proxyEM;
	}

	private String getEventMessageKey(TIBCOEventMessageWrapper ew, TIBCOArticleWrapper aw) {
		return aw.proxyArticle.ArticleID__c
			+ (ew.proxyEM.EventType__c != null ? ew.proxyEM.EventType__c : '')
			// + (ew.proxyEM.ActualDateTime__c != null ? ew.proxyEM.ActualDateTime__c.formatGMT(DATE_TIME_FORMAT) : '')
			+ (ew.proxyEM.ActualDateTime__c != null ? ew.proxyEM.ActualDateTime__c.format(DATE_TIME_FORMAT) : '')
			+ (ew.proxyEM.SenderID__c != null ? ew.proxyEM.SenderID__c : '');
	}
}