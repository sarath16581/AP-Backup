/**************************************************
Type:      
Purpose:    
History:

--------------------------------------------------

9 Sept 2015    christopher.henschke@auspost.com.au  added subscriberID into ExactTargetEmail class to allow for the use of ExactTarget Preference Centre for unsubscribe
2015-10-15     paul.stamer@auspost.com.au           Created label ShareInformationrootlabel (General to Share)
2016-01-03     nandan.narasappa@auspost.com.au      added createShareInfoActivity method for share info reporting requirement : REQ0626809
2016-05-30     nandan.narasappa@auspost.com.au      limited to display only Share info articles on page load for INC0649377 fix
28-Feb-2017    Angelo.Rivera@auspost.com.au         Updated sendAnEmail and sendMultipleEmail method and added contactID parameter 
                                                        that will be passed to sendSingleMail method as the subscriberID
01 Sep 2017    rufus.solomon@auspost.com.au         INC0996855: Change made to reflect an update of the Default Knowledge Base Language  
08 SEp 2017    dilshan.egodawela@auspost.com		added send notification method to send invitations via the registration API
11 Feb 2021    madhuri.awasthi@auspost.com.au       INC1729620 Changing Record query from Name to developerName for Default Task
23 Apr 2024		Raghav Ravipati						Replaced Classic  articaltype with salesforce lighting article Knowledge__kav as part of knowledge lightning uplift
*/

global with sharing class ShareInformationController {
	
	//Constant
	private static final String PUSH_EDM = 'Push_EDM';  // varialbe for knowledge article type for INC0649377
	public string template {get; set;}
	public Contact aContact {get;private set;}
	public boolean displayResult {get;set;}
	public String searchKeyword {get;set;}
	public String articleID{get; set;}  
	public List<String> articleBodys = new List<String>();      
	public String articleBody {get; set;} 
	public Integer articlePosition {get; set;}
	//Start Change by Snigdha: 07/08/2015: REQ0614391 : Ensure Legal Marketing Opt-In flag is checked before sending email 
	public Contact currentContact {get; set;}
	public boolean legalCheck;
	public string product {get; set;}
	public string productType{get; set;}
	//public List<SelectOption> Prods {get; set;}
	//public List<SelectOption> ProdTypes {get; set;}
	//End Change by Snigdha: 07/08/2015: REQ0614391
	
	public Set<Id> articleIds = new Set<Id>();
	
	public ShareInformationController(){   
		if(ApexPages.currentPage().getParameters().get('id').startsWith('001')){
			Account anAccount = [select PersonContactId from Account where id=:ApexPages.currentPage().getParameters().get('id') limit 1];
			aContact = [select firstname, lastname,id,email,APCN__c,name,CRMCSSOID__c,Account.RecordType.DeveloperName from Contact where id=:anAccount.PersonContactId limit 1];
			//Start Change by Snigdha: 07/08/2015: REQ0614391 : Ensure Legal Marketing Opt-In flag is checked before sending email
			currentContact = [select Legal_Marketing_Opt_In__c from Contact where id=:anAccount.PersonContactId limit 1];
			//End Change by Snigdha: 07/08/2015: REQ0614391 
		}
		
		if(ApexPages.currentPage().getParameters().get('id').startsWith('003')){
			aContact = [select firstname, lastname,id,email,APCN__c,name,CRMCSSOID__c,Account.RecordType.DeveloperName from Contact where id=:ApexPages.currentPage().getParameters().get('id') limit 1];
			//Start Change by Snigdha: 07/08/2015: REQ0614391 : Ensure Legal Marketing Opt-In flag is checked before sending email
			currentContact = [select Legal_Marketing_Opt_In__c from Contact where id=:ApexPages.currentPage().getParameters().get('id') limit 1];
			//End Change by Snigdha: 07/08/2015: REQ0614391 
		}
		
		
		displayResult = false;
		product = 'Consumer';
		//getProds();
		//getProdTypes();
	}
	
	//used send customers invitations to join/register with mypost.
	@RemoteAction
	public static string sendNotification(String productType,Id custID){
		//productType.substring(productType.lastIndexOf('/'), productType.length()+1);
		
		Contact aContact = [select firstname, lastname,id,email,APCN__c,name,CRMCSSOID__c from Contact where id=:custID limit 1];
		HttpRequest req = new HttpRequest(); 
		
		req.setMethod('POST');
		String endPoint; 
		
		//get environment settings from the custom setting
		AusPostSettings__c setting = AusPostSettings__c.getValues('Customer Invitations');
		if (setting != null)
		{
			endPoint = setting.URL__c;
		}
		String custAPCN = String.isNotEmpty(aContact.APCN__c) ? '"apcn": "'+aContact.APCN__c+'",' : '';
		req.setEndpoint(endPoint);
		req.setHeader('Content-Type', 'application/json');
		
		String content = '{  "email": "'+aContact.email+'",'+ custAPCN +'"tokenTtl":"'+setting.TokenDuration__c+'",'+
			+'"invitationErrorMsg":"Some error occurred","registrationNextUrl":"'+ productType +'",'+
			+'"registrationUrl": "'+setting.URL2__c+'",'+
			+'"registrationErrorMsg": "Some error occurred", "loginUrl":"'+setting.URL3__c+'",'+
			+'"sapcrm": false, "salesforce": true, "caller": "Salesforce_'+productType.substring(productType.lastIndexOf('/')+1, productType.length())+'",'+
			+'"invitationNotification": {"templateId": "'+setting.TemplateId__c+'","templateMap": {'+
			+'"firstName": "'+aContact.firstname+'","lastName": "'+aContact.lastname+'" } }}';
		
		req.setBody(content);    
		Http http = new Http();
		
		HTTPResponse res = http.send(req);
		
		if(res.getStatusCode() == 200){ 
			
			Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
			
			if(results.get('emailSent')== true){
				// create activity history on successful invite sent
				Task activityHistory = new Task();
				activityHistory.Subject = Label.MyPostSendInvitesTitle;
				activityHistory.ActivityDate = system.today();
				activityHistory.RecordTypeId = [Select Id From RecordType Where developerName = 'Default_Taks'][0].Id;
				activityHistory.whoid = aContact.Id;
				activityHistory.Description = 'product Value : '+productType;
				activityHistory.Status = 'Completed';
				insert activityHistory;     
				return Label.InviteSent;}
			else if(results.get('registered')== true){
				return Label.CustomerAlreadyRegisterd;}
			else if(results.get('known')== true){
				return Label.CustomerKnown;}
			else if(results.get('loggedin')== true){
				return Label.CustomerLoggedin;}
			else{
				return Label.ShareInformationError1;
			}
		}
		else{
			return 'There was an error ('+res.getBody()+')';
		}
		
	}
	
	//get all product types
	public List<SelectOption> getProds(){
		List<SelectOption> prods = new List<SelectOption>();
		Map<String,String> temp = new Map<String,String>();
		List<CIproducts__c> cips = CIproducts__c.getall().values();
		for(CIproducts__c a : cips){
			if(!temp.containsKey(a.productType__c)){
				temp.put(a.productType__c, a.productType__c);
			}
		}
		for(String so : temp.keySet()){
			prods.add(new SelectOption(so,so));
		}
		product = temp.values()[0];
		return prods;
	}
	//get product related to the selected product type:defaulted to Consumer
	public List<SelectOption> getProdTypes(){
		List<SelectOption> prodTypes = new List<SelectOption>();
		Map<String,String> temp = new Map<String,String>();
		List<CIproducts__c> cips = CIproducts__c.getall().values();
		cips.sort();
		for(CIproducts__c a : cips){
			if(!temp.containsKey(a.product__c) && a.productType__c == product){
				temp.put(a.product__c, a.RegistrationNextURL__c);
			}
		}
		for(String so : temp.keySet()){
			prodTypes.add(new SelectOption(temp.get(so),so));
		}
		return prodTypes;
	}
	
	//Start Change by Snigdha: 07/08/2015: REQ0614391 : Ensure Legal Marketing Opt-In flag is checked before sending email 
	public void saveMarketingOptions()
	{          
		
		try
		{
			
			update currentContact;
			
		}
		catch (DmlException ex)
		{
			for (Integer i = 0; i < ex.getNumDml(); i++) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(i))); 
			}
		}
		
	}
	//End Change by Snigdha: 07/08/2015: REQ0614391 :
	
	public void clearSearch() {
		searchKeyword = '';
		rootData = null;
		categorisedArticles = null;
		displayResult = false;
	}
	
	public void searchArticles() {
		rootData = null;
		categorisedArticles = null;
		displayResult = true;
	}
   
	public void populateEmailTempalte(){
		
		if(aContact.email<>null){
			Savepoint sp = Database.setSavepoint();
			try {
				Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
				String[] toAddresses = new String[] {aContact.email};
				sem.setToAddresses(toAddresses);
				sem.setTargetObjectId(aContact.id);
				EmailTemplate et=[Select HtmlValue From EmailTemplate e where DeveloperName='PushEDM'];
				sem.setTemplateId(et.Id);
				Messaging.sendEmail(new Messaging.Email[] { sem });
				template = sem.getHtmlBody();
			} catch(Exception ex){
				template = 'Error: Unable to generate the template because ' + ex.getMessage();
			} finally {
				Database.rollback(sp);
			}
		}
	}   
	
	public void addToArticleBody() {
		articleBodys.add(articleBody);
		articleIds.add(articleID);
	}
	
	public void removeFromArticleBody() {
		articleBodys.remove(articlePosition);
		articleIds.remove(articleID);
	}
	
	public void moveToArticleBody() {
		String origArticleBody = articleBodys[articlePosition]; 
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
		// 04.28.17 - Angelo P. Rivera - Added aContact.Id parameter that will be passed to sendExactTargetEmail method as the subscriberID
		sendExactTargetEmail(qm.CusEmail__c,'Australia Post-No Reply', aContact.email, aContact.Name, emailContent,subject, aContact.Id);
		
		// create activity history
		Task activityHistory = new Task();
		activityHistory.Subject = 'Email: ' + subject;
		activityHistory.ActivityDate = system.today();
		activityHistory.RecordTypeId = [Select Id From RecordType Where developerName = 'Default_Taks'][0].Id;
		activityHistory.whoid = aContact.Id;
		activityHistory.Description = textContent;
		activityHistory.Status = 'Completed';
		insert activityHistory;     
		
		createShareInfoActivity(aContact.Id,articleIds);    // create share info records for reporting
		
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
	
	public class DataCategoryArticleNode {
		public string id {get;set;}
		public string label {get;set;}
		public string body {get;set;}
		public string type {get;set;}
		public List<DataCategoryArticleNode> childCategories {
			get{
				if(childCategories == null){
					childCategories = new List<DataCategoryArticleNode>();
				} 
				return childCategories;
			} private set;
		}
		public List<DataCategoryArticleNode> articles {
			get {
				if(articles == null) {
					articles = new List<DataCategoryArticleNode>();
				}
				return articles;
			} private set;
		}
		
		public DataCategoryArticleNode(DataCategory dc){
			this.id = dc.name;
			this.label = dc.label;
		}
		
		public DataCategoryArticleNode(SObject article){
			Knowledge__kav kav = (Knowledge__kav)article;
			this.id = kav.id;
			this.label = kav.Title;// (String)article.get('Title');
			this.body = kav.Answer__c; //(String)article.get('Answer__c');
			this.type = kav.recordType.DeveloperName;
		}
	}
	 
	public List<DataCategoryArticleNode> rootData {
		get {
			if(rootData == null) {
				rootData = new List<DataCategoryArticleNode>();
				Datacategorygroupsobjecttypepair pair = new Datacategorygroupsobjecttypepair();
				pair.setSobject('KnowledgeArticleVersion');
				pair.setDataCategoryGroupName('product');
				Describedatacategorygroupstructureresult structureResult = Schema.describeDataCategoryGroupStructures(new Datacategorygroupsobjecttypepair[]{ pair }, false)[0]; 
				DataCategory root = structureResult.getTopCategories()[0];
				
				DataCategoryArticleNode rootNode = new DataCategoryArticleNode(root);
				Map<id, SObject> articles = categorisedArticles.get(root.Name);
				if(articles != null){
					for(SObject o: articles.values()){
						rootNode.articles.add(new DataCategoryArticleNode(o));
					}
				}
				rootNode.label = label.ShareInformationRootLabel;  // REQ0678533 paul stamer
				rootData.add(rootNode);
				
				for(DataCategory dc: root.getChildCategories()){
					DataCategoryArticleNode node = generateNode(dc);
					if(node != null) { 
						rootData.add(node);
					}
				}
			}
			return rootData;
		} private set;
	}
	
	DataCategoryArticleNode generateNode(DataCategory dc) {
		DataCategoryArticleNode result = new DataCategoryArticleNode(dc);
		
		Map<id, SObject> articles = categorisedArticles.get(dc.Name);
		List<DataCategory> childCategories = dc.getChildCategories();
		
		if(articles != null){
			for(SObject o: articles.values()){
				result.articles.add(new DataCategoryArticleNode(o));
			}
		}
		
		for(DataCategory child: childCategories){
			DataCategoryArticleNode node = generateNode(child);
			if(node != null) {
				result.childCategories.add(node);
			}
		}
		
		if(result.articles.isEmpty() && result.childCategories.isEmpty()) {
			result = null;
		}
		
		return result;
	}
	 
	Map<String, Map<id, SObject>> categorisedArticles {
		get {
			if(categorisedArticles == null) {
				categorisedArticles = new Map<String, Map<id, SObject>>();
				//Map<id, KnowledgeArticleVersion> publishedArticles = new Map<id, KnowledgeArticleVersion>([SELECT ArticleNumber,ArticleType,Id,KnowledgeArticleId,Title FROM KnowledgeArticleVersion WHERE Language = 'en_US' AND PublishStatus = 'Online']);
				
				PushEDM_Domain__c pDom =  PushEDM_Domain__c.getOrgDefaults();
				
				List<String> allowedArticles = pDom.Supported_Article_Types__c.split(';');
				/*for(integer i=0; i<allowedArticles.size(); i++)
				{
					allowedArticles[i] = allowedArticles[i] + '__kav';
				}*/
				/*
				for(Knowledge__kav kav : [SELECT ArticleType 
								FROM Knowledge__kav 
							  	WHERE Language = 'en_US' AND 
								PublishStatus = 'Online'AND
								RecordType.DeveloperName IN: allowedArticles
								group by ArticleType]){
					Map<id, SObject> articles = new Map<id, SObject>();
					
					if(!String.isBlank(searchKeyword) && searchKeyword.length() > 2) {
							for(SObject o: Search.query('FIND :searchKeyword IN ALL FIELDS RETURNING ' + (String)a.get('ArticleType') + '(Answer__c,ArticleNumber,ArticleType,KnowledgeArticleId,id, Title WHERE PublishStatus = \'Online\' AND Language = \'en_US\')')[0]) {
						  articles.put(o.id, o); 
						}
					} else {
						// Nandan : limiting the query for Share info article for view state error (INC0649377)
						for(SObject o: Database.query('SELECT Answer__c,ArticleNumber,ArticleType,KnowledgeArticleId,id, Title FROM ' + PUSH_EDM + ' WHERE PublishStatus = \'Online\' AND Language = \'en_US\'')) {
						//for(SObject o: Database.query('SELECT Answer__c,ArticleNumber,ArticleType,KnowledgeArticleId,id, Title FROM ' + //(String)a.get('ArticleType') + ' WHERE PublishStatus = \'Online\' AND Language = \'en_US\'')) {
							articles.put(o.id, o); 
						}
					}
					
					for(SObject o: Database.query('SELECT DataCategoryName,ParentId FROM ' + ((String)a.get('ArticleType')).replace('__kav', '') + '__DataCategorySelection')) {
						if(categorisedArticles.get((String)o.get('DataCategoryName')) == null) {
							categorisedArticles.put((String)o.get('DataCategoryName'), new Map<id, SObject>());
						} 
						SObject article = articles.get((id)o.get('parentid')); 
						if(article != null) {
							categorisedArticles.get((String)o.get('DataCategoryName')).put(article.id, article);
						}
					}
				}*/
				//Performs SOSL to search the given keyword across the KAVs and 
				//if the search key is blank does query on the eligible Kavs
				Map<id, SObject> articles = new Map<id, SObject>();
				ShareInformationControllerWrapper siWrapper = new ShareInformationControllerWrapper();

				if(String.isNotBlank(searchKeyword) && searchKeyword.length() > 2) {

					for(SObject o: siWrapper.searchArticles(searchKeyword, allowedArticles)){
				  		articles.put(o.id, o); 
					}
				}
				else {
					// Nandan : limiting the query for Share info article for view state error (INC0649377)

					for(SObject o: siWrapper.getKnowledgeArticles()) {
					//for(SObject o: Database.query('SELECT Answer__c,ArticleNumber,ArticleType,KnowledgeArticleId,id, Title FROM ' + //(String)a.get('ArticleType') + ' WHERE PublishStatus = \'Online\' AND Language = \'en_US\'')) {
						articles.put(o.id, o); 
					}
				}

				//Collect the data categories
				Set<SObjectField> fieldOverrides = new Set<SObjectField>{
					Knowledge__DataCategorySelection.DataCategoryName,
					Knowledge__DataCategorySelection.ParentId
				};

				map<string,string> articleIDCategoryName=new map<string,string>();
				Set<String> rtTypes = new Set<String>();
				rtTypes.addAll(allowedArticles);
				Map<String, Object> params = new Map<String, Object>{'recordTypeNames' => rtTypes};
				KnowledgeDataCategorySelectionSelector datCatSelector = KnowledgeDataCategorySelectionSelector.newInstance(fieldOverrides);
				
				for(SObject o: datCatSelector.search(params, true)) {
					if(categorisedArticles.get((String)o.get('DataCategoryName')) == null) {
						categorisedArticles.put((String)o.get('DataCategoryName'), new Map<id, SObject>());
					} 
					SObject article = articles.get((id)o.get('parentid')); 
					if(article != null) {
						categorisedArticles.get((String)o.get('DataCategoryName')).put(article.id, article);
					}
				}
			}
   
			return categorisedArticles; 
		} private set;  
	}   
	
	/**
	  * @description       This method creates ShareInformation activity for reporting
	  * @param             contactId - Id, articleIds - Set<Id> 
	  * @return            void
	  * @throws            Method might throw exception which is handled by Try-Catch block
	  */
	private static void createShareInfoActivity(Id contactId,Set<Id> articleIds){
		Savepoint beforeShareInfo = Database.setSavepoint();
		try{
			// form share info activity record
			ShareInfoActivity__c shareInfoActivity = new ShareInfoActivity__c ();
			shareInfoActivity.Agent__c = UserInfo.getUserId();  // service agent sharing articles with customer
			shareInfoActivity.Contact__c = contactId;
			shareInfoActivity.ActivityTime__c = DateTime.now();  
			Database.insert(shareInfoActivity);
			List<ShareInfoArticle__c> shareInfoArticleList = new List<ShareInfoArticle__c>();
			
			ShareInformationControllerWrapper siWrapper = new ShareInformationControllerWrapper();
			
			// fetch details for the articles selected
			for(Knowledge__kav article : (List<Knowledge__kav>) siWrapper.getKnowledgeArticles(articleIds)){
				ShareInfoArticle__c shareInfoArticle = new ShareInfoArticle__c();
				shareInfoArticle.ShareInfoActivity__c = shareInfoActivity.Id;
				shareInfoArticle.ArticleID__c = article.KnowledgeArticleId;
				shareInfoArticle.ArticleNumber__c = article.ArticleNumber;
				shareInfoArticle.ArticleTitle__c = article.Title;
				shareInfoArticle.ArticleType__c = article.RecordType.DeveloperName;
				shareInfoArticleList.add(shareInfoArticle);
			}
			
			if(!shareInfoArticleList.isEmpty()){    // check if shareInfoArticleList got values
				Database.insert(shareInfoArticleList);
			}         
		}
		catch(Exception exp){
			Database.rollback(beforeShareInfo); // roll back on exception
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
													ShareInformationController.class.getName(), SSSWConstants.METH_CREATE_SHAREINFO, 
													null, LoggingLevel.ERROR);
		}
	}
	/**created a wrapper class and defined without sharing to provide access to the articles */
	@testVisible
	without sharing class ShareInformationControllerWrapper{
		/**
		 * @description Gets all the Kavs based on published status, recordtype and language
		 * @return list of Knowledge__kav
		 */
		@testVisible
		private List<Knowledge__kav> getKnowledgeArticles(){
			Set<SObjectField> fields = new Set<SObjectField>{
				Knowledge__kav.Id,
				Knowledge__kav.Answer__c,
				Knowledge__kav.ArticleNumber,
				Knowledge__kav.KnowledgeArticleId,
				Knowledge__kav.Title
			};

			Map<String, Object> params = new Map<String, Object>{'statuses' => new Set<String>{'Online'}, 'languages' => new Set<String>{'en_US'}, 'recordTypeNames' => new Set<String>{'PUSH_EDM'}};
			KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance(fields);
			Set<Object> selectorOptions = new Set<Object>();
			selectorOptions.add(KnowledgeArticleVersionsSelector.Options.WITH_RECORDTYPE);
			return  kavSelector.search(params, selectorOptions, true);
		}
		/**
		 * @description Gets all the Kavs based on recordIds
		 * @param articleIDs KAVs Ids
		 * @return list of Knowledge__kav
		 */
		@testVisible
		private List<Knowledge__kav> getKnowledgeArticles(Set<Id> articleIDs){
			Set<SObjectField> fields = new Set<SObjectField>{
				Knowledge__kav.Id,
				Knowledge__kav.KnowledgeArticleId,
				Knowledge__kav.Title
			};
			Map<String, Object> params = new Map<String, Object>{'knowledgeIds' => articleIds};
			Set<Object> selectorOptions = new Set<Object>{KnowledgeArticleVersionsSelector.Options.WITH_RECORDTYPE};

			KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance(fields);
			return kavSelector.search(params, selectorOptions);
		}
		/**
		 * @description Gets the KAVs based on the given search keyword
		 * @param searchKeyWord Keyword from UI
		 * @param allowedArticles allowed recordTypes
		 * @retun list of Sobject 
		 */
		@testVisible
		private List<SObject> searchArticles(String searchKeyWord, List<String> allowedArticles){

			KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance();
			return kavSelector.searchArticles(searchKeyWord, allowedArticles);
		}
	}
	
}