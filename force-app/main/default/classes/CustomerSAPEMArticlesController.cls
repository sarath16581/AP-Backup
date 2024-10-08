/**
  * @author       :Dilshan Egodawela 
  * @date         :
  * @description  : Class created as the controller for Customer SAPEM Articel list page.
  * @changelog
  * 01.01.1970 Created date unknown.
  * 13.06.2024 Parveen Kaushik Added a filter in SOQL for mapping model. See CSLU-470 (JIRA) for details.
**/

public with sharing class CustomerSAPEMArticlesController {
    
    public List<SAPEMArticles> articleList {get;set;}
    public integer pagenumber{get;set;}
    public integer totalpages{get;set;}
    public integer pagesize{get;set;}
    public integer skip{get;set;}
    public integer totalrecords {get;set;}
    public Account acc {get;set;}
    public Boolean showError {get; set;}
    public Map<String,String> colorcodes {get;set;}
    public Map<String,String> productMapping {get;set;}
    public Map<String,String> subProdMap {get;set;}

    
    public CustomerSAPEMArticlesController(ApexPages.StandardController controller){
        
        this.acc = [select Id, APCN__pc,FirstName,LastName,PersonMobilePhone,VerifiedMobile__pc,PersonEmail from Account where Id = :controller.getId()];
        //set page size from the custom setting if available if not default to 10
        pagesize = AusPostSettings__c.getValues('SAPEMCustomerArticles').PageSize__c != null ? (integer)AusPostSettings__c.getValues('SAPEMCustomerArticles').PageSize__c : 10;
        skip = 0;
        pagenumber = 1;
        colorcodes = new Map<String,String>();
        for(TrackingStatusColor__mdt statuscolor : [select MasterLabel,Color_Code__c from TrackingStatusColor__mdt]){
            colorcodes.put(statuscolor.MasterLabel, statuscolor.Color_Code__c);
        }
        productMapping = new Map<String,String>();
        subProdMap = new Map<String,String>();
        for(MiniCaseFieldMapping__c mfm : [SELECT SAPProductSubcategory__c,ProductCategory__c,ProductSubcategory__c FROM MiniCaseFieldMapping__c WHERE MappingModel__c =: SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL]){
            if(!productMapping.containsKey(mfm.SAPProductSubcategory__c)){
                productMapping.put(mfm.SAPProductSubcategory__c,mfm.ProductCategory__c);}
            if(!subProdMap.containsKey(mfm.SAPProductSubcategory__c)){
                subProdMap.put(mfm.SAPProductSubcategory__c,mfm.ProductSubcategory__c);}
        }
    }
    
    public class SAPEMArticles {
        public String articleID{get;set;}
        public String customerType{get;set;}
        public String edd{get;set;}
        public String lastEventDate{get;set;}
        public String status{get;set;}
        public Boolean pastEDD {get;set;}
        public String color{get;set;}
        public String prodCategory{get;set;}
        public String subProdCategory{get;set;}
        public SAPEMArticles(String articleID, String customerType, String status, String lastEventDate, String edd, Boolean pastEDD, String color,String prodCategory, String subProdCategory)
        {
            this.articleID = articleID;
            this.customerType = customerType;
            this.edd = edd;
            this.lastEventDate = lastEventDate;
            this.status = status;
            this.pastEDD = pastEDD;
            this.color = color;
            this.prodCategory = prodCategory;
            this.subProdCategory = subProdCategory;
        }
    }
    //check whether more pages are available
    public boolean gethasNext(){
        return (pagenumber < totalpages);
    }
    //check previous available
    public boolean gethasPrev(){
        return (pagenumber > 1);
    }
    //go to next page
    public void next(){
        skip = pagenumber*pagesize;
        pagenumber++;
        System.debug('pagenumber : '+pagenumber);
                System.debug('pagesize : '+pagesize);
                System.debug('skip : '+skip);
        getCustomerArticleList();
    }
    //go to last page
    public void last(){
        skip = (totalpages-1)*pagesize;
        pagenumber = totalpages;
        System.debug('pagenumber : '+pagenumber);
                System.debug('pagesize : '+pagesize);
                System.debug('skip : '+skip);
        getCustomerArticleList();
    }
    //go to first page
    public void first(){
        skip = 0;
        pagenumber = 1;
        System.debug('pagenumber : '+pagenumber);
                System.debug('pagesize : '+pagesize);
                System.debug('skip : '+skip);
        getCustomerArticleList();
    }
    //go to previous page
    public void previous(){
        pagenumber--;
        skip = (pagenumber-1)*pagesize;
                System.debug('pagenumber1 : '+pagenumber);
                System.debug('pagesize2 : '+pagesize);
                System.debug('skip3 : '+skip);
        getCustomerArticleList();
    }
    //Quary articles
    public void getCustomerArticleList(){
        HttpRequest req = new HttpRequest(); 
            articleList = new List<SAPEMArticles>();
        totalrecords = 0;
    String endPoint;
    String username;
    String password;
    String mobile = String.isNotEmpty(acc.VerifiedMobile__pc) ? acc.VerifiedMobile__pc : acc.PersonMobilePhone;
    String mob = String.isNotEmpty(mobile) ? 'Mobile eq \''+mobile+'\' or AccountMobile eq \''+mobile+'\'' : '';
    String apcn = String.isNotEmpty(acc.APCN__pc) ? 'APCN eq \''+acc.APCN__pc+'\'' : '';
    String email = String.isNotEmpty(acc.PersonEmail) ? 'Email eq \''+acc.PersonEmail+'\'' : '';
    String condition1 = String.isNotEmpty(apcn) && (String.isNotEmpty(email) || String.isNotEmpty(mob)) ? ' or ' : '';
    String condition2 = String.isNotEmpty(email) && String.isNotEmpty(mob) ? ' or ' : '';
    //get environment details from the Auspost custom setting
        AusPostSettings__c setting = AusPostSettings__c.getValues('SAPEMCustomerArticles');
            if (setting != null)
            {
                endPoint = setting.URL__c;
                username = setting.Username__c;
                password = setting.Password__c;
            }    
    req.setMethod('GET');
        
    String endp = endPoint+'?$filter='+ apcn +''+ condition1 +''+ email +''+ condition2 +''+ mob +'&$orderby=LastEventDate desc&$skip='+skip+'&$top='+pagesize+'&$expand=Article,Article/TrackingStatus,Article/DateInfo&$format=json';   
    req.setEndpoint(endp.replaceAll(' ','+'));
    Blob headerValue = Blob.valueOf(username + ':' + password);
    String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', authorizationHeader);
    
    Http http = new Http();
    
    HTTPResponse res = http.send(req);
    //if successful
    if(res.getStatusCode() == 200){
    String resBody = res.getBody();
    //String R = '{"d":{"results":[{"__metadata":{"id":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'99601070083001004564690\')","uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'99601070083001004564690\')","type":"ZGW_ARTICLE_QUERY_SRV.CustomerArticle"},"ArticleID":"99601070083001004564690","CustomerType":"SENDER","APCN":"","Email":"","Mobile":"0427002870","DPID":"","Name":"","CreatedDate":"/Date(1473832611000)/","LastEventDate":"/Date(1501203804000)/","APCNAddDate":null,"RecordNumber":1,"RecordsTotal":27,"Article":{"__deferred":{"uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'99601070083001004564690\')/Article"}}},{"__metadata":{"id":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000081201000910909\')","uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000081201000910909\')","type":"ZGW_ARTICLE_QUERY_SRV.CustomerArticle"},"ArticleID":"HMM000081201000910909","CustomerType":"RECEIVER","APCN":"1010844839","Email":"naz.ali1@mailinator.com","Mobile":"0427002870","DPID":"54516251","Name":"NAZ ALI","CreatedDate":"/Date(1497932164000)/","LastEventDate":"/Date(1500944442000)/","APCNAddDate":"/Date(1497932165000)/","RecordNumber":2,"RecordsTotal":27,"Article":{"__deferred":{"uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000081201000910909\')/Article"}}},{"__metadata":{"id":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000081901000605002\')","uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000081901000605002\')","type":"ZGW_ARTICLE_QUERY_SRV.CustomerArticle"},"ArticleID":"HMM000081901000605002","CustomerType":"RECEIVER","APCN":"1010844839","Email":"naz.ali1@mailinator.com","Mobile":"0427002870","DPID":"54516251","Name":"NAZ ALI","CreatedDate":"/Date(1498029064000)/","LastEventDate":"/Date(1500879576000)/","APCNAddDate":"/Date(1498029064000)/","RecordNumber":3,"RecordsTotal":27,"Article":{"__deferred":{"uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000081901000605002\')/Article"}}},{"__metadata":{"id":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000027401000600202\')","uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000027401000600202\')","type":"ZGW_ARTICLE_QUERY_SRV.CustomerArticle"},"ArticleID":"HMM000027401000600202","CustomerType":"RECEIVER","APCN":"1009656570","Email":"ptest.3@mailinator.com","Mobile":"0427002870","DPID":"54516251","Name":"BEN R","CreatedDate":"/Date(1476083080000)/","LastEventDate":"/Date(1500600630000)/","APCNAddDate":"/Date(1493358263000)/","RecordNumber":4,"RecordsTotal":27,"Article":{"__deferred":{"uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000027401000600202\')/Article"}}},{"__metadata":{"id":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044120000605006\')","uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044120000605006\')","type":"ZGW_ARTICLE_QUERY_SRV.CustomerArticle"},"ArticleID":"HMM000044120000605006","CustomerType":"RECEIVER","APCN":"","Email":"ctest@mailinator.com","Mobile":"0427002870","DPID":"","Name":"NAZ ALI","CreatedDate":"/Date(1490055716000)/","LastEventDate":"/Date(1500437047000)/","APCNAddDate":null,"RecordNumber":5,"RecordsTotal":27,"Article":{"__deferred":{"uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044120000605006\')/Article"}}},{"__metadata":{"id":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044119000605000\')","uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044119000605000\')","type":"ZGW_ARTICLE_QUERY_SRV.CustomerArticle"},"ArticleID":"HMM000044119000605000","CustomerType":"RECEIVER","APCN":"","Email":"ctest@mailinator.com","Mobile":"0427002870","DPID":"","Name":"NAZ ALI","CreatedDate":"/Date(1490055716000)/","LastEventDate":"/Date(1500437047000)/","APCNAddDate":null,"RecordNumber":6,"RecordsTotal":27,"Article":{"__deferred":{"uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044119000605000\')/Article"}}},{"__metadata":{"id":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044118000605003\')","uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044118000605003\')","type":"ZGW_ARTICLE_QUERY_SRV.CustomerArticle"},"ArticleID":"HMM000044118000605003","CustomerType":"RECEIVER","APCN":"","Email":"ctest@mailinator.com","Mobile":"0427002870","DPID":"","Name":"NAZ ALI","CreatedDate":"/Date(1490055716000)/","LastEventDate":"/Date(1500437047000)/","APCNAddDate":null,"RecordNumber":7,"RecordsTotal":27,"Article":{"__deferred":{"uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044118000605003\')/Article"}}},{"__metadata":{"id":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044117000605006\')","uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044117000605006\')","type":"ZGW_ARTICLE_QUERY_SRV.CustomerArticle"},"ArticleID":"HMM000044117000605006","CustomerType":"RECEIVER","APCN":"","Email":"ctest@mailinator.com","Mobile":"0427002870","DPID":"","Name":"NAZ ALI","CreatedDate":"/Date(1490055716000)/","LastEventDate":"/Date(1500437047000)/","APCNAddDate":null,"RecordNumber":8,"RecordsTotal":27,"Article":{"__deferred":{"uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044117000605006\')/Article"}}},{"__metadata":{"id":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044116000605009\')","uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044116000605009\')","type":"ZGW_ARTICLE_QUERY_SRV.CustomerArticle"},"ArticleID":"HMM000044116000605009","CustomerType":"RECEIVER","APCN":"","Email":"ctest@mailinator.com","Mobile":"0427002870","DPID":"","Name":"NAZ ALI","CreatedDate":"/Date(1490055716000)/","LastEventDate":"/Date(1500437047000)/","APCNAddDate":null,"RecordNumber":9,"RecordsTotal":27,"Article":{"__deferred":{"uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044116000605009\')/Article"}}},{"__metadata":{"id":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044115000605002\')","uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044115000605002\')","type":"ZGW_ARTICLE_QUERY_SRV.CustomerArticle"},"ArticleID":"HMM000044115000605002","CustomerType":"RECEIVER","APCN":"","Email":"ctest@mailinator.com","Mobile":"0427002870","DPID":"","Name":"NAZ ALI","CreatedDate":"/Date(1490055716000)/","LastEventDate":"/Date(1500437047000)/","APCNAddDate":null,"RecordNumber":10,"RecordsTotal":27,"Article":{"__deferred":{"uri":"http://sit-sap-em.corptest.aptest.local:8000/sap/opu/odata/SAP/ZGW_ARTICLE_QUERY_SRV/CustomerArticles(\'HMM000044115000605002\')/Article"}}}]}}';
    Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(resBody);
            
    Map<String, Object> a = (Map<String, Object>)results.get('d');
    List<Object> a2 = (List<Object>)a.get('results');
    if(a2.size() != 0){
        for(Object x : a2){
        Map<String, Object> a3 = (Map<String, Object>)x;
        String dateString = (String)a3.get('LastEventDate');
        //get last event date    
        Long longtime = long.valueOf(dateString.substringAfter('(').substringBefore(')'));
        DateTime dt = DateTime.newInstance(longtime);    
        //get records total    
        totalrecords = (integer)a3.get('RecordsTotal');
        totalpages = Integer.valueof(math.ceil((double)totalrecords/(double)pagesize ));
            
        Map<String, Object> articleExp = (Map<String, Object>)a3.get('Article');
        //get tracking status from the article expand
        Map<String, Object> trackingStatus = (Map<String, Object>)articleExp.get('TrackingStatus');
        Map<String, Object> dateInfo = (Map<String, Object>)articleExp.get('DateInfo');   
        String eddateString = (String)dateInfo.get('EstimatedDeliveryDate');
            
        Long eddlongtime = String.isNotEmpty(eddateString) ? long.valueOf(eddateString.substringAfter('(').substringBefore(')')) : 0;
        DateTime eddt = DateTime.newInstance(eddlongtime);
        DateTime currentdate = DateTime.now().date();
        Boolean eddcheck =  currentdate > eddt && String.isNotEmpty(eddateString) ? true : false;
        String eddate = String.isNotEmpty(eddateString) ? eddt.date().format() : '-';
            
        String pCategory = String.isNotBlank(productMapping.get((String)articleExp.get('SubProductName'))) ? productMapping.get((String)articleExp.get('SubProductName')) : 'Domestic Parcels';
        String subPCategory = String.isNotBlank(subProdMap.get((String)articleExp.get('SubProductName'))) ? subProdMap.get((String)articleExp.get('SubProductName')) : 'eParcel- Regular';
        
        articleList.add(new SAPEMArticles((String)a3.get('ArticleID'),(String)articleExp.get('SubProductName'),(String)trackingStatus.get('StatusValue'),dt.format(),eddate,eddcheck,colorcodes.get((String)trackingStatus.get('StatusValue')),pCategory,subPCategory));
        }
    }}
        else{
            showError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Some error occured. Please contact your administrator!'));
        }
    }

}