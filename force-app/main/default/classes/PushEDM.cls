/*

9 Sept 2015 - 	christopher.henschke@auspost.com.au: added subscriberID into ExactTargetEmail class to allow for the use of ExactTarget Preference Centre for unsubscribe
28-Feb-2017	- 	Angelo.Rivera@auspost.com.au : 		Updated sendAnEmail and sendMultipleEmail method and added contactID parameter 
													that will be passed to sendSingleMail method as the subscriberID 
11 Feb 2021		madhuri.awasthi@auspost.com.au		INC1729620 Changing Record query from Name to developerName for Default Task
23 Apr 2024		Raghav Ravipati						Replaced Classic articaltype with salesforce lighting article Knowledge__kav as part of knowledge lightning uplift
*/


global with sharing class PushEDM {
	//public transient string template {get; private set;}
	public string template {get; set;}
	
	public transient list<Category> TopCategories {get; private set;}
	public transient list<articleSet> ArticleSet {get; private set;}
	public Contact aContact {get;private set;}
	public boolean displayResult {get;set;}
	
	// added by shengpeng.xiao@bluewolf.com at 2014.7.15
	public String searchKeyword	{get;set;}
	
	public class Category {
		public String Name {get; set;}
		public String Label {get; set;}
		
		public Category(String name, String label) {
			this.Name = name;
			this.Label = label;
		}
	}
	
	public PushEDM() {
		// added by shengpeng.xiao@bluewolf.com at 2014.7.15
		this.searchKeyword = '';
		String urlParam = ApexPages.currentPage().getParameters().get('id');
		if (urlParam.startsWith('001')) {
			Account anAccount = [SELECT PersonContactId FROM Account WHERE id = :urlParam LIMIT 1];
			aContact = [SELECT firstname, lastname, id, email, name FROM Contact WHERE id = :anAccount.PersonContactId LIMIT 1];
		}

		if (urlParam.startsWith('003')) {
			aContact = [SELECT firstname, lastname, id, email, name FROM Contact WHERE id = :urlParam LIMIT 1];
		}

		TopCategories = getTopCategories();

		if (ApexPages.currentPage().getParameters().get('k') <> null) {
			// added by shengpeng.xiao@bluewolf.com at 2014.7.15
			this.searchKeyword = ApexPages.currentPage().getParameters().get('k');

			ArticleSet = getArticleSetByKeywords();
		} else {
			ArticleSet = getArticleSet();
		}

		displayResult = false;
	}
	
	// added by shengpeng.xiao@bluewolf.com at 2014.7.15
	// used for searching
	public Pagereference searchArticles() {
		TopCategories = getTopCategories();
		
		if (!String.isEmpty(this.searchKeyword)) {
			ArticleSet = getArticleSetByKeywords();
		} else {
			ArticleSet = getArticleSet();
		}
		return null;
	}
   
	public void populateEmailTempalte() {	
		if (aContact.email <> null) {
			String[] toAddresses = new List<String>{ aContact.email };
			EmailTemplate et = [SELECT HtmlValue FROM EmailTemplate e WHERE DeveloperName = 'PushEDM'];			
			Savepoint sp = Database.setSavepoint();
			Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
			sem.setToAddresses(toAddresses);
			sem.setTargetObjectId(aContact.id);
			sem.setTemplateId(et.Id);
			Messaging.sendEmail(new List<Messaging.Email>{ sem });
			template = sem.getHtmlBody();
			Database.rollback(sp);
		}
	}   
		
	public String articleID{get; set;}
	  
	private list<Category> getTopCategories() {
		list<Category> topCategories = new list<Category>();
		list<Schema.DescribeDataCategoryGroupStructureResult> describeResult = DescribeDataCategoryGroupStructures.getDescribeDataCategoryGroupStructureResults();
		
		for (Schema.DescribeDataCategoryGroupStructureResult result : describeResult) {
			
			DataCategory [] topLevelCategories = result.getTopCategories();
		
			//checking if the correct children are returned
			DataCategory [] children = topLevelCategories[0].getChildCategories();
		
			for(Integer i=0; i < children.size(); i++){
				topCategories.add(new Category(children[i].getName(), children[i].getLabel()));
			}
		}
		return topCategories;
	}
	  
	public class articleSet {
		public string title {get;set;}
		public string body {get;set;}
		public string url {get;set;}
		public string type {get;set;}
		public Id id {get;set;}
		public string categoryList {get;set;}
		//public Map<String, Boolean> categoryMap {get;set;}
		public string categoryListUnique {get;set;}
		
		//new constructor added by shengpeng.xiao@bluewolf.com at 2014.6.25
		//if the article is under the category 'All' , set all top catogories to the categoryListUnique, tile id PushEDM 312
		public articleSet(string title, string body, string url, String type, Id id, string categoryList, List<Category> TopCategories) {
			this.title = title;
			this.url = url;
			this.type = type;
			this.id = id;
			this.categoryList = categoryList;
			this.body = body;
			this.categoryListUnique = '';
			if(categoryList != null) {
		  		// if the artical is under all
		  		if(categoryList == 'All') {
		  			if(TopCategories != null && TopCategories.size() > 0) {
		  				for(Category ctg : TopCategories) {
		  					if(ctg.name != null && ctg.name.trim() != '' && this.categoryListUnique.indexOf('$' + ctg.name.trim() + '$') == -1) {
		  						this.categoryListUnique += '$' + ctg.name.trim() + '$';
		  					}
		  				}
		  			}
		  		}else {
		  			for(String s : categoryList.split(',')) {
						if(s.trim() != '' && this.categoryListUnique.indexOf('$' + s.trim() + '$') == -1) {
							this.categoryListUnique += '$' + s.trim() + '$';
						}
					}
		  		}
			}
		}
		
		public articleSet(string title, string body, string url, String type, Id id, string categoryList){
			this.title = title;
			this.url = url;
			this.type = type;
			this.id = id;
			this.categoryList = categoryList;
			this.body = body;
			//modified by shengpeng.xiao@bluewolf.com 2014.06.16 begin
			//make category unique in categoryList and more recognizable
			this.categoryListUnique = '';
			if(categoryList != null) {
	  			for(String s : categoryList.split(',')) {
					if(s.trim() != '' && this.categoryListUnique.indexOf('$' + s.trim() + '$') == -1) {
						this.categoryListUnique += '$' + s.trim() + '$';
					}
				}
			}
			//modified by shengpeng.xiao@bluewolf.com 2014.06.16 end
		}
	}
	
	private list<articleSet> getArticleSetByKeywords() {
		list<articleSet> articles = new list<articleSet>(); 
		map<string,string> appliedCategories=new map<string,string>();
		map<string,string> articleIDCategoryName=new map<string,string>();
		PushEDMWrapper edmWrapper = new PushEDMWrapper();
		Set<Id> parentIds = new Set<Id>();

		for(Knowledge__kav knowledgeArticle : edmWrapper.getKnowledgeArticles()){
			parentIds.add(knowledgeArticle.Id);
		}
		//Fields to Query
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
			Knowledge__DataCategorySelection.DataCategoryGroupName,
			Knowledge__DataCategorySelection.DataCategoryName,
			Knowledge__DataCategorySelection.ParentId
		};		
		Map<String, Object> params = new Map<String, Object>{'parentIds' => parentIds};
		KnowledgeDataCategorySelectionsSelector dataCategorySelector = KnowledgeDataCategorySelectionsSelector.newInstance(fieldOverrides);

		for(Sobject faq:dataCategorySelector.search(params)){
			articleIDCategoryName.put(string.valueof(faq.get('ParentId')),string.valueof(faq.get('DataCategoryName')));
		}
		
		//modified by shengpeng.xiao@bluewolf.com at 2014.6.17 end
		string keyword = this.searchKeyword;
		List<String> allowedArticles = new List<String>{'PUSH_EDM','FAQ'};

		Map<Id, articleSet> articleSetMap = new Map<Id, articleSet>();
		Map<Id, Knowledge__kav> kavMap = new Map<Id, Knowledge__kav>();
		for(Knowledge__kav article: (List<Knowledge__kav>)edmWrapper.searchArticles(keyword, allowedArticles)){
			kavMap.put(article.id, article);
			String articleType = 'PusheDM';
			if('FAQ'.equalsIgnoreCase(article.RecordType.DeveloperName)){
				articleType = 'FAQ';
			}
			articleSet anArticleSet = new articleSet(article.Title, article.Answer__c, article.UrlName, articleType, article.Id, '', TopCategories);
			articleSetMap.put(article.id, anArticleSet);
		}

		Map<String, Object> searchParams = new Map<String, Object>{'parentIds' => kavMap.keySet()};
		KnowledgeDataCategorySelectionsSelector kavDatCatSelector = KnowledgeDataCategorySelectionsSelector.newInstance(fieldOverrides);

		for (Knowledge__DataCategorySelection kavDataCat : kavDatCatSelector.search(searchParams)) {

			if (articleIDCategoryName.containskey(kavDataCat.ParentId) && articleIDCategoryName.get(kavDataCat.ParentId) <> kavDataCat.DataCategoryName) {
				string newCategoryNames = articleIDCategoryName.get(kavDataCat.ParentId) + ',' + kavDataCat.DataCategoryName;
				articleIDCategoryName.put(string.valueof(kavDataCat.get('ParentId')), newCategoryNames);
				appliedCategories.put(kavDataCat.DataCategoryName, kavDataCat.DataCategoryName);
			} else if (!articleIDCategoryName.containskey(kavDataCat.ParentId)) {
				articleIDCategoryName.put(string.valueof(kavDataCat.get('ParentId')), kavDataCat.DataCategoryName);
				appliedCategories.put(kavDataCat.DataCategoryName, kavDataCat.DataCategoryName);
			}

			articleSet anArticleSet = articleSetMap.get(kavDataCat.ParentId);
			anArticleSet.categoryList = articleIDCategoryName.get(kavDataCat.ParentId);
		}
		articles.addAll(articleSetMap.values());

		return articles;
	}   
								 
	private list<articleSet> getArticleSet(){						 
		String language ='en_US';
		String PublishStatus='Online';
		list<articleSet> articles = new list<articleSet>();
		map<string,string> appliedCategories=new map<string,string>();

		//Fields to Query
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
			Knowledge__DataCategorySelection.DataCategoryGroupName,
			Knowledge__DataCategorySelection.DataCategoryName,
			Knowledge__DataCategorySelection.ParentId
		};

		map<string,string> articleIDCategoryName=new map<string,string>();
		Set<String> allowedArticles = new Set<String>{'PUSH_EDM','FAQ'};
		List<Knowledge__DataCategorySelection> eligibleDataCats = new List<Knowledge__DataCategorySelection>();
		Set<Id> parentIds = new Set<Id>();
		Map<Id, Knowledge__kav> knowledgeArticlesMap = new Map<Id, Knowledge__kav>();
		PushEDMWrapper edmWrapper = new PushEDMWrapper();

		for(Knowledge__kav knowledgeArticle : edmWrapper.getKnowledgeArticles()){
			parentIds.add(knowledgeArticle.Id);
			knowledgeArticlesMap.put(knowledgeArticle.Id, knowledgeArticle);
		}
		
		Map<String, Object> params = new Map<String, Object>{'parentIds' => parentIds};
		KnowledgeDataCategorySelectionsSelector dataCategorySelector = KnowledgeDataCategorySelectionsSelector.newInstance(fieldOverrides);

		for(Knowledge__DataCategorySelection dataCat :dataCategorySelector.search(params)){
			articleIDCategoryName.put(dataCat.ParentId,dataCat.DataCategoryName);

			if(knowledgeArticlesMap.get(dataCat.ParentId).language == 'en_US' && knowledgeArticlesMap.get(dataCat.ParentId).PublishStatus == 'Online' && knowledgeArticlesMap.get(dataCat.ParentId).IsLatestVersion){
				eligibleDataCats.add(dataCat);
			}		
		}

		Map<Id, articleSet> articleSetMap = new Map<Id, articleSet>();

		for (Knowledge__DataCategorySelection faqPushEDM : eligibleDataCats) {
			if (articleIDCategoryName.containskey(faqPushEDM.ParentId) == true && articleIDCategoryName.get(faqPushEDM.ParentId) <> faqPushEDM.get('DataCategoryName')) {
				string newCategoryNames = articleIDCategoryName.get(faqPushEDM.ParentId) + ',' + faqPushEDM.get('DataCategoryName');
				articleIDCategoryName.put(string.valueof(faqPushEDM.get('ParentId')), newCategoryNames);
				appliedCategories.put(string.valueof(faqPushEDM.get('DataCategoryName')), string.valueof(faqPushEDM.get('DataCategoryName')));
			}

			if (articleIDCategoryName.containskey(faqPushEDM.ParentId) == false) {
				articleIDCategoryName.put(string.valueof(faqPushEDM.get('ParentId')), string.valueof(faqPushEDM.get('DataCategoryName')));
				appliedCategories.put(string.valueof(faqPushEDM.get('DataCategoryName')), string.valueof(faqPushEDM.get('DataCategoryName')));
			}

			if (articleSetMap.containsKey(faqPushEDM.ParentId)) {
				articleSet anArticleSet = articleSetMap.get(faqPushEDM.ParentId);
				anArticleSet.categoryList = articleIDCategoryName.get(faqPushEDM.ParentId);
			} else {
				String articleType = 'PusheDM';
				Knowledge__kav parentKnowledge = knowledgeArticlesMap.get(faqPushEDM.parentId);

				if ('FAQ'.equalsIgnoreCase(parentKnowledge.RecordType.DeveloperName)) {
					articleType = 'FAQ';
				}
				articleSet article = new articleSet(parentKnowledge.title, parentKnowledge.Answer__c, parentKnowledge.UrlName, articleType, faqPushEDM.ParentId, articleIDCategoryName.get(faqPushEDM.ParentId), TopCategories);
				articleSetMap.put(faqPushEDM.ParentId, article);
			}
		}

		articles.addAll(articleSetMap.values());

		return articles;
	} 
	
	public List<String> articleBodys = new List<String>();  
	public String articleBody {get; set;} 
	public Integer articlePosition {get; set;}
	//add article body into the list
	public void addToArticleBody() {   
		articleBodys.add(articleBody);
	}
	
	//remove article body from the list
	public void removeFromArticleBody() { 
		articleBodys.remove(articlePosition);
	}
	
	// set the article body from a given position
	public void moveToArticleBody() {
		String origArticleBody = articleBodys[articlePosition]; 
		// get original position of the article body
		Integer origPosition = 0;
		for (Integer i = 0; i < articleBodys.size(); i++) {
			if (articleBodys[i] == articleBody) {
				origPosition = i;
				break;
			}
		}
		articleBodys[articlePosition] = articleBody;
		articleBodys[origPosition] = origArticleBody;
	}
	
	public void sendEmail(){
		string replacement='';

		for(string s:articleBodys){
			replacement=replacement+'<br/>'+s;
		}
		
		string emailContent;
		string subject;
		String textContent;
		
		Savepoint sp = Database.setSavepoint();
		Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] {aContact.email};
		sem.setToAddresses(toAddresses);
		sem.setTargetObjectId(aContact.id);
		EmailTemplate et=[Select id, subject, HtmlValue From EmailTemplate e where DeveloperName='PushEDM'];
		sem.setTemplateId(et.Id);
		Messaging.sendEmail(new Messaging.Email[] { sem });
		emailContent = sem.getHtmlBody();
		textContent = sem.getPlainTextBody();
		subject = sem.getSubject();
		Database.rollback(sp);

		emailContent=emailContent.replace('%%BodyContent%%', replacement);
		textContent=textContent.replace('%%BodyContent%%', replacement);
		
		emailContent = emailContent.replace(PushEDM_Domain__c.getInstance().Force_Com_URL__c, PushEDM_Domain__c.getInstance().Site_URL__c);
		textContent = textContent.replace(PushEDM_Domain__c.getInstance().Force_Com_URL__c, PushEDM_Domain__c.getInstance().Site_URL__c);
		emailContent=emailContent.normalizeSpace();
		
		QM__c qm=[Select CusEmail__c From QM__c limit 1];
		
		sendExactTargetEmail(qm.CusEmail__c,'Australia Post-No Reply', aContact.email, aContact.Name, emailContent,subject, aContact.Id);
		// 04.28.17 - Angelo P. Rivera - Added aContact.Id parameter that will be passed to sendExactTargetEmail method as the subscriberID
	   	
		// create activity history
		Task activityHistory = new Task();
		activityHistory.Subject = 'Email: ' + subject;
		activityHistory.ActivityDate = system.today();
		activityHistory.RecordTypeId = [Select Id From RecordType Where developerName = 'Default_Taks'][0].Id;
		activityHistory.whoid = aContact.Id;
		activityHistory.Description = textContent;
		activityHistory.Status = 'Completed';
		insert activityHistory;		
				
		displayResult=true;
		
	}
	
	@future(callout=true)
	private static void sendExactTargetEmail(string fromEmail, string fromName, string toAddress, string toName,string emailBody, string subject, string subscriberID){
		// 04.28.17 - Angelo P. Rivera - Added aContact.Id parameter that will be passed to sendExactTargetEmail method as the subscriberID	
		// 9 Sept 2015 - added so users can unsubscribe from ET Preference centre
		//string subscriberID = toAddress;

		ExactTargetEmail.ExactTargetSentResult sendResult = new ExacttargetEmail().sendSingleMail(fromEmail,fromName,toAddress,toName,emailBody, subject, subscriberID);
		if(!sendResult.isSuccessful){
			ExactTargetBacklog__c c = new ExactTargetBacklog__c();
			c.EmailContentJSON__c = sendResult.requestBody;
			c.ErrorMessage__c = sendResult.message;
			c.IsBatchEmail__c = sendResult.IsBatchEmail;
			insert c;
		}
	}
	/**created a wrapper class and defined without sharing to provide access to the articles */
	without sharing class PushEDMWrapper{
		@testVisible
		private List<SObject> searchArticles(String searchKeyWord, List<String> allowedArticles){
			
			KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance();
			return kavSelector.searchArticles(searchKeyWord, allowedArticles);
		}
		/**
		 * @description Gets all the Kavs based on published status, recordtype and language
		 * @return list of Knowledge__kav
		 */
		@testVisible
		private List<Knowledge__kav> getKnowledgeArticles() {
			Set<SObjectField> fields = new Set<SObjectField>{
				Knowledge__kav.Id,
				Knowledge__kav.Answer__c,
				Knowledge__kav.ArticleNumber,
				Knowledge__kav.KnowledgeArticleId,
				Knowledge__kav.Title
			};

			Map<String, Object> params = new Map<String, Object>{'recordTypeNames' => new Set<String>{ 'PUSH_EDM', 'FAQ' }};
			KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance(fields);
			Set<Object> selectorOptions = new Set<Object>();
			selectorOptions.add(KnowledgeArticleVersionsSelector.Options.WITH_RECORDTYPE);
			return  kavSelector.search(params, selectorOptions, true);
		}
	}
}