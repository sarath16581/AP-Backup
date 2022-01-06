/*

9 Sept 2015 - christopher.henschke@auspost.com.au: added subscriberID into ExactTargetEmail class to allow for the use of ExactTarget Preference Centre for unsubscribe
28-Feb-2017	- Angelo.Rivera@auspost.com.au : Updated sendAnEmail and sendMultipleEmail method and added contactID parameter 
												that will be passed to sendSingleMail method as the subscriberID 
11 Feb 2021    madhuri.awasthi@auspost.com.au       INC1729620 Changing Record query from Name to developerName for Default Task
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
    
    public PushEDM(){   
    	// added by shengpeng.xiao@bluewolf.com at 2014.7.15      
        this.searchKeyword = '';
        
        if(ApexPages.currentPage().getParameters().get('id').startsWith('001')){
            Account anAccount = [select PersonContactId from Account where id=:ApexPages.currentPage().getParameters().get('id') limit 1];
            aContact = [select firstname, lastname,id,email,name from Contact where id=:anAccount.PersonContactId limit 1];
        }
        
        if(ApexPages.currentPage().getParameters().get('id').startsWith('003')){
            aContact = [select firstname, lastname,id,email,name from Contact where id=:ApexPages.currentPage().getParameters().get('id') limit 1];
        }
        
        TopCategories = getTopCategories();
        
         if(ApexPages.currentPage().getParameters().get('k')<>null){
         	// added by shengpeng.xiao@bluewolf.com at 2014.7.15      
        	this.searchKeyword = ApexPages.currentPage().getParameters().get('k');
        	
            ArticleSet = getArticleSetByKeywords();
        }
        else{
            ArticleSet = getArticleSet();
        }

        displayResult=false;
    }
    
    // added by shengpeng.xiao@bluewolf.com at 2014.7.15
    // used for searching
    public Pagereference searchArticles() {
    	TopCategories = getTopCategories();
    	if(!String.isEmpty(this.searchKeyword)) {
            ArticleSet = getArticleSetByKeywords();
        }else {
            ArticleSet = getArticleSet();
        }
    	return null;
    }
   
   
    public void populateEmailTempalte(){
    
        if(aContact.email<>null){
                
            Savepoint sp = Database.setSavepoint();
            Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
            

            String[] toAddresses = new String[] {aContact.email};
            
            sem.setToAddresses(toAddresses);
            sem.setTargetObjectId(aContact.id);
            EmailTemplate et=[Select HtmlValue From EmailTemplate e where DeveloperName='PushEDM'];
            sem.setTemplateId(et.Id);
            Messaging.sendEmail(new Messaging.Email[] { sem });
            
            template = sem.getHtmlBody();
            Database.rollback(sp);
        }

    }   
        
    public String articleID{get; set;}    
      
    private list<Category> getTopCategories(){
        list<Category> topCategories = new list<Category>();
        list<Schema.DescribeDataCategoryGroupStructureResult> describeResult = DescribeDataCategoryGroupStructures.getDescribeDataCategoryGroupStructureResults();
        
        for (Schema.DescribeDataCategoryGroupStructureResult result : describeResult) {
            
            DataCategory [] topLevelCategories = result.getTopCategories();
        
            //checking if the correct children are returned
            DataCategory [] children = topLevelCategories[0].getChildCategories();
        
            for(Integer i=0; i < children.size(); i++){
                System.debug(children[i].getName());
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
    
    private list<articleSet> getArticleSetByKeywords(){
        list<articleSet> articles = new list<articleSet>();                 

            string articleTypeName ='FAQ__DataCategorySelection';
        
            map<string,string> appliedCategories=new map<string,string>();
    
            string q='Select ParentId, DataCategoryName From '+articleTypeName;
            list<Sobject> slist = Database.query(q);
            map<string,string> articleIDCategoryName=new map<string,string>();
            
            for(Sobject faq:slist){
                articleIDCategoryName.put(string.valueof(faq.get('ParentId')),string.valueof(faq.get('DataCategoryName')));
            }
            
            //get PushEDM articles
            //modified by shengpeng.xiao@bluewolf.com at 2014.6.17 begin
            //as article attached to different category, previous value will be replaced by following steps
            /*articleTypeName ='Push_EDM__DataCategorySelection';
        
           
    
            q='Select ParentId, DataCategoryName From '+articleTypeName;
            slist = Database.query(q);

            
            for(Sobject pushEDM:slist){
                articleIDCategoryName.put(string.valueof(pushEDM.get('ParentId')),string.valueof(pushEDM.get('DataCategoryName')));
            }*/
            //modified by shengpeng.xiao@bluewolf.com at 2014.6.17 end
            
            //
            String articleQuery = 'FAQ__kav (ID, Title, UrlName,Summary,Answer__c WHERE  language =\'en_US\'  and PublishStatus = \'Online\') ,Push_EDM__kav (ID, Title, UrlName,Summary,Answer__c WHERE  language =\'en_US\'  and PublishStatus = \'Online\')';
            
            //string keyword=ApexPages.currentPage().getParameters().get('k');
            
            //modified by shengpeng.xiao@bluewolf.com at 2014.6.17 end
            string keyword = this.searchKeyword;
            
            List<List<SObject>> doclist = search.query('FIND \''+keyword+'\' IN ALL FIELDs '+'Returning '+ articleQuery); 
              
               List<SObject>  resultArticles = ((List<SObject>)doclist[0]);
               system.debug('>>>>>>>>:'+resultArticles.size());
               for(SObject article: resultArticles){
                 for(Sobject faq:slist){
                    if(string.valueof(faq.get('ParentId')) == string.valueof(article.get('id'))){
                        // modified by shengpeng.xiao@bluewolf.com at 2014.06.16 begin
                        // fixed the bug that Push EDM article not show in different categories
                        if(articleIDCategoryName.containskey(string.valueof(article.get('id')))
                                && articleIDCategoryName.get(string.valueof(article.get('id'))) <> faq.get('DataCategoryName')){
                            string newCategoryNames= articleIDCategoryName.get(string.valueof(article.get('id')))+','+faq.get('DataCategoryName');
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),newCategoryNames);
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }
                        else if (!articleIDCategoryName.containskey(string.valueof(article.get('id')))) {
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),string.valueof(faq.get('DataCategoryName')));
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }
                        // modified by shengpeng.xiao@bluewolf.com at 2014.06.16 end

                        /*if(articleIDCategoryName.containskey(string.valueof(article.get('id')))){
                            string newCategoryNames= articleIDCategoryName.get(string.valueof(article.get('id')))+','+faq.get('DataCategoryName');
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),newCategoryNames);
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }
                        else{
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),string.valueof(faq.get('DataCategoryName')));
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }*/
                    }
                        
                }
                // use new constructor added by shengpeng.xiao@bluewolf.com at 2014.6.25
                //articleSet AnArticleSet = new articleSet(string.valueof(article.get('title')),string.valueof(article.get('answer__c')),string.valueof(article.get('UrlName')),'FAQ',string.valueof(article.get('id')), articleIDCategoryName.get(string.valueof(article.get('id'))));
                articleSet AnArticleSet = new articleSet(string.valueof(article.get('title')),string.valueof(article.get('answer__c')),string.valueof(article.get('UrlName')),'FAQ',string.valueof(article.get('id')), articleIDCategoryName.get(string.valueof(article.get('id'))), TopCategories);
                articles.add(AnArticleSet);
                }
               
                //get push edms
               
                //added by shengpeng.xiao@bluewolf.com at 2014.6.17 begin
                slist.clear();
                articleIDCategoryName.clear();

                articleTypeName ='Push_EDM__DataCategorySelection';
        
                q='Select ParentId, DataCategoryName From '+articleTypeName;
                slist = Database.query(q);

                
                for(Sobject pushEDM:slist){
                    articleIDCategoryName.put(string.valueof(pushEDM.get('ParentId')),string.valueof(pushEDM.get('DataCategoryName')));
                }
               //added by shengpeng.xiao@bluewolf.com at 2014.6.17 end
               resultArticles.clear();
               resultArticles = ((List<SObject>)doclist[1]);
               system.debug('>>>>>>>>:'+resultArticles.size());
               for(SObject article: resultArticles){
                 for(Sobject faq:slist){
                    if(string.valueof(faq.get('ParentId')) == string.valueof(article.get('id'))){
                        // modified by shengpeng.xiao@bluewolf.com at 2014.06.16 begin
                        // fixed the bug that Push EDM article not show in different categories
                        if(articleIDCategoryName.containskey(string.valueof(article.get('id'))) 
                                && articleIDCategoryName.get(string.valueof(article.get('id')))<>faq.get('DataCategoryName')){
                            string newCategoryNames= articleIDCategoryName.get(string.valueof(article.get('id')))+','+faq.get('DataCategoryName');
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),newCategoryNames);
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }
                        else if(!articleIDCategoryName.containskey(string.valueof(article.get('id')))) {
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),string.valueof(faq.get('DataCategoryName')));
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }
                        // modified by shengpeng.xiao@bluewolf.com at 2014.06.16 end
                        
                        /*if(articleIDCategoryName.containskey(string.valueof(article.get('id')))){
                            string newCategoryNames= articleIDCategoryName.get(string.valueof(article.get('id')))+','+faq.get('DataCategoryName');
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),newCategoryNames);
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }
                        else{
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),string.valueof(faq.get('DataCategoryName')));
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }*/
                    }
                        
                }
                // use new constructor added by shengpeng.xiao@bluewolf.com at 2014.6.25
                //articleSet AnArticleSet = new articleSet(string.valueof(article.get('title')),string.valueof(article.get('answer__c')),string.valueof(article.get('UrlName')),'PusheDM',string.valueof(article.get('id')), articleIDCategoryName.get(string.valueof(article.get('id'))));
                articleSet AnArticleSet = new articleSet(string.valueof(article.get('title')),string.valueof(article.get('answer__c')),string.valueof(article.get('UrlName')),'PusheDM',string.valueof(article.get('id')), articleIDCategoryName.get(string.valueof(article.get('id'))), TopCategories);
                articles.add(AnArticleSet);
               }
            system.debug('>>>>>>>>:'+articles.size());
        return articles;
    }   
                                 
    private list<articleSet> getArticleSet(){
        list<articleSet> articles = new list<articleSet>();                 

            string articleTypeName ='FAQ__DataCategorySelection';

        
            map<string,string> appliedCategories=new map<string,string>();
    
            string q='Select ParentId, DataCategoryName From '+articleTypeName;
            list<Sobject> slist = Database.query(q);
            map<string,string> articleIDCategoryName=new map<string,string>();
            
            for(Sobject faq:slist){
                articleIDCategoryName.put(string.valueof(faq.get('ParentId')),string.valueof(faq.get('DataCategoryName')));
            }
            
            for(FAQ__kav a:[Select UrlName, Title, PublishStatus, KnowledgeArticleId, IsLatestVersion, Id, ArticleType, ArticleNumber, Answer__c From FAQ__kav WHERE  language ='en_US' and PublishStatus='Online' and IsLatestVersion=true]){
                for(Sobject faq:slist){
                    if(string.valueof(faq.get('ParentId')) == a.id){
                        if(articleIDCategoryName.containskey(a.id)==true && articleIDCategoryName.get(a.id)<>faq.get('DataCategoryName')){
                            string newCategoryNames= articleIDCategoryName.get(a.id)+','+faq.get('DataCategoryName');
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),newCategoryNames);
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }
                        if(articleIDCategoryName.containskey(a.id)==false){
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),string.valueof(faq.get('DataCategoryName')));
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }
                    }
                        
                }
                // use new constructor added by shengpeng.xiao@bluewolf.com at 2014.6.25
                //articleSet article = new articleSet(a.title,a.Answer__c,a.UrlName,'FAQ',a.id, articleIDCategoryName.get(a.id));
                articleSet article = new articleSet(a.title,a.Answer__c,a.UrlName,'FAQ',a.id, articleIDCategoryName.get(a.id), TopCategories);
                articles.add(article);
            } 
            
                        
             //get PushEDM articles
             articleIDCategoryName.clear();
            articleTypeName ='Push_EDM__DataCategorySelection';
    
            q='Select ParentId, DataCategoryName From '+articleTypeName;
            slist.clear();
            slist = Database.query(q);
            
            for(Sobject pushEDM:slist){
                articleIDCategoryName.put(string.valueof(pushEDM.get('ParentId')),string.valueof(pushEDM.get('DataCategoryName')));
            }
            //
            
            for(Push_EDM__kav a:[Select UrlName, Title, PublishStatus, KnowledgeArticleId, IsLatestVersion, Id, ArticleType, ArticleNumber, Answer__c From Push_EDM__kav WHERE  language ='en_US' and PublishStatus='Online' and IsLatestVersion=true]){
                for(Sobject faq:slist){
                    if(string.valueof(faq.get('ParentId')) == a.id){
                        
                        // modified by shengpeng.xiao@bluewolf.com at 2014.06.16 begin
                        // fixed the bug that Push EDM article not show in different categories
                        if(articleIDCategoryName.containskey(a.id) == true && articleIDCategoryName.get(a.id)<>faq.get('DataCategoryName')){
                            string newCategoryNames= articleIDCategoryName.get(a.id)+','+faq.get('DataCategoryName');
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),newCategoryNames);
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }
                        if(articleIDCategoryName.containskey(a.id) == false){
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),string.valueof(faq.get('DataCategoryName')));
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }
                        // modified by shengpeng.xiao@bluewolf.com at 2014.06.16 end
                        
                        /*if(articleIDCategoryName.containskey(a.id)){
                            string newCategoryNames= articleIDCategoryName.get(a.id)+','+faq.get('DataCategoryName');
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),newCategoryNames);
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }
                        else{
                            articleIDCategoryName.put(string.valueof(faq.get('ParentId')),string.valueof(faq.get('DataCategoryName')));
                            appliedCategories.put(string.valueof(faq.get('DataCategoryName')),string.valueof(faq.get('DataCategoryName')));
                        }*/
                    }
                        
                }
				
				// use new constructor added by shengpeng.xiao@bluewolf.com at 2014.6.25
                //articleSet article = new articleSet(a.title,a.Answer__c,a.UrlName,'PusheDM',a.id, articleIDCategoryName.get(a.id));
                articleSet article = new articleSet(a.title,a.Answer__c,a.UrlName,'PusheDM',a.id, articleIDCategoryName.get(a.id), TopCategories);
                articles.add(article);
            }   
        return articles;
    }     
    
    public List<String> articleBodys = new List<String>();      
    public String articleBody {get; set;} 
    public Integer articlePosition {get; set;}
    //add article body into the list
    public void addToArticleBody() {
        System.debug('articleBody : ' + articleBody);   
        articleBodys.add(articleBody);      
        System.debug('articleBodys : ' + articleBodys);
    }
    
    //remove article body from the list
    public void removeFromArticleBody() {
        System.debug('articleBody : ' + articleBody);                   
        articleBodys.remove(articlePosition);
        System.debug('articleBodys : ' + articleBodys);
    }
    
    // set the article body from a given position
    public void moveToArticleBody() {
        System.debug('articleBody : ' + articleBody);
        System.debug('articleBody Position: ' + articlePosition);
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
        System.debug('articleBodys : ' + articleBodys);
    }
    
    public void sendEmail(){
        system.debug('#################### Sending Push eDM...');
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
        system.debug('fixed email content>>>>>>>>>>>>>>>>>>>>: ' + emailContent );
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
}