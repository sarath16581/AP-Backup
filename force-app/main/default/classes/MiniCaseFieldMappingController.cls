/**
  * @changelog
  * 01.01.1970 Created date unknown.
  * 13.06.2024 Parveen Kaushik Added a filter in SOQL for mapping model. See CSLU-470 (JIRA) for details.
  */  
global without sharing class MiniCaseFieldMappingController {
    public ApexPages.StandardController controller {get;set;}
    public Case proxyCase {get;set;}
    public List<MiniCaseFieldMapping__c> existingSAPMappings {get;set;}
    public List<MiniCaseFieldMapping__c> existingCTIMappings {get;set;}
    public integer counter {get{if(counter == null)counter = 0; return counter++;}set;}
   
    public MiniCaseFieldMappingController(ApexPages.StandardController controller){
        this.controller = controller;
        proxyCase = new Case();
        proxyCase.RecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].Id;
        
        existingSAPMappings = new List<MiniCaseFieldMapping__c>();
        existingCTIMappings = new List<MiniCaseFieldMapping__c>();
        
        if(controller.getRecord().id != null){
            MiniCaseFieldMapping__c r = [select ProductCategory__c,ProductSubcategory__c,Type__c, caseRecordTypeId__c 
                                         from MiniCaseFieldMapping__c 
                                         where id =:controller.getRecord().id limit 1];
                                         
            proxyCase.ProductCategory__c = r.ProductCategory__c;
            proxyCase.ProductSubCategory__c = r.ProductSubCategory__c;
            proxyCase.Type = r.Type__c;
            proxyCase.Type_and_Product__c = proxyCase.Type + '|' + proxyCase.ProductCategory__c + '|' + proxyCase.ProductSubCategory__c;
        }
    }
    
    @RemoteAction
    global static string getRecordTypeId(string caseType, string productCategory, String productSubCategory){ //updated kalpita
        string result = '';
        Savepoint sp = Database.setSavepoint(); 
        Case c = [select id from Case where referenceId__c = 'SSSWCase' limit 1];
        c.ReferenceID__c = '';
        c.type = caseType;
        c.ProductCategory__c = productCategory;
        c.ProductSubCategory__c = productSubCategory; //added Kalpita
        c.Bypass_Data_enforcement__c = true;
        update c;
        result = [select recordTypeid from Case where id=:c.id].RecordTypeId;
        Database.rollback(sp);
        return result;
    }
        
    public void save(){
        try{
            MiniCaseFieldMapping__c r = (MiniCaseFieldMapping__c)controller.getRecord();
            r.ProductCategory__c = proxyCase.ProductCategory__c;
            r.ProductSubcategory__c = proxyCase.ProductSubCategory__c;
            r.Type__c = proxyCase.Type;
            r.caseRecordTypeId__c = proxyCase.recordTypeId;
                        
            string key = string.isEmpty(r.CTICustomerSegment__c) ? '' : r.CTICustomerSegment__c.trim();
            key += string.isEmpty(r.CTIServiceType__c) ? '' : r.CTIServiceType__c;          
            
            existingCTIMappings = new List<MiniCaseFieldMapping__c>(); 
            if(key != ''){  
                existingCTIMappings = [select CTICustomerSegment__c,CTIServiceType__c,ProductCategory__c,ProductSubcategory__c,Type__c 
                                       from MiniCaseFieldMapping__c 
                                       where CTIKey__c=:key and id!=:r.id AND MappingModel__c =: r.MappingModel__c];
            }
            
            if(existingCTIMappings.size() > 0){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Duplicate CTI Settings'));            
            }
            
            key = string.isEmpty(r.SAPProductCategory__c) ? '' : r.SAPProductCategory__c;
            key += string.isEmpty(r.SAPProductSubcategory__c) ? '' : r.SAPProductSubcategory__c; 
            
            existingSAPMappings = new List<MiniCaseFieldMapping__c>(); 
            if(key != ''){  
                existingSAPMappings = [select SAPProductCategory__c,SAPProductSubcategory__c,ProductCategory__c,ProductSubcategory__c,Type__c 
                                       from MiniCaseFieldMapping__c 
                                       where SAPKey__c=:key and id!=:r.id AND MappingModel__c =: r.MappingModel__c];
            }
                                               
            if(existingSAPMappings.size() > 0){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Duplicate SAP Settings'));            
            }
            
            if(existingSAPMappings.size() == 0 && existingCTIMappings.size() == 0) {
                upsert r;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Saved successfully!'));
            }
        }catch(Exception ex){
            ApexPages.addMessages(ex);
        }
    }
    
}