/**
* Created by: Raviteja Epuri* 
* Date: 12th Jan 2016
* Select Text Area Fields from product
 */
public with sharing class APT_SelectFieldController {
 
    public String choice{get;set;} 
    public String id{get;set;} 
    public String objectType{get;set;}  
    
    /**
    Consturctor to get the values from url
    **/
    public APT_SelectFieldController() {
        Id = ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_ID);
        if (string.isNotBlank(Id)) {Id = String.escapeSingleQuotes(Id);}
 
        objectType = ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_OBJECTTYPE);
        if (string.isNotBlank(objectType)) {objectType = String.escapeSingleQuotes(objectType);}
 
    }
 
   /**
    method to navigate to AttachFile Page
   **/
    public PageReference next() {
     try{
        PageReference newPage;
        newPage = Page.APT_AttachFile;
        newPage.getParameters().put(APT_Constants.PARAM_ID, id);
        newPage.getParameters().put(APT_Constants.URL_SELECTED_VALUE, choice);
        newPage.getParameters().put(APT_Constants.URL_OBJ, objectType);
        return newPage.setRedirect(true);
        } catch (Exception ex) {
            apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  ex.getMessage()));
            return null;
        }
    }
 
   
    /**
    select Html formated  and text area fields  for Product
    **/
    public list<SelectOption> getFieldsForSelectedObject() {
 
        List<SelectOption> fieldsNames = new List<SelectOption>();
       // Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        try {
            Schema.sObjectType objectDef = Schema.getGlobalDescribe().get(objectType).getDescribe().getSObjectType();
            Map<String, Schema.SobjectField> fieldMap = objectDef.getDescribe().fields.getMap();
            schema.describefieldresult dfield;
            schema.Displaytype disfield;
            Schema.DisplayType dt;
            SelectOption op;
            for (Schema.SObjectField sfield : fieldMap.Values()) {
                dfield = sfield.getDescribe();
                disfield = dfield.getType();
                dt = dfield.getType();                
                if (dt == Schema.DisplayType.Textarea && dfield.isHtmlFormatted()) {
                    op = new SelectOption(dfield.getName(), dfield.getLabel());
                    fieldsNames.add(op);
                }
            }
          return sortSelectOptions(fieldsNames);
        } catch (Exception ex) {
            apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  ex.getMessage()));
            return null;
        }        
    }
    /**
        This method will redirect you to previos page.
    **/ 
    public PageReference cancel() {
        try {
            PageReference pageRef = new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + Id);
            return pageRef;
        }  catch(Exception ex) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }    
    }
 
    /**
    sort fields in alphabetical order.
    **/
    @TestVisible
    private List<SelectOption> sortSelectOptions(List<SelectOption> sortingList) {
        for (Integer i = 0; i < sortingList.size(); i++) {
            for (Integer j = i; j > 0; j--) {
                if (sortingList[j - 1].getLabel() > sortingList[j].getLabel()) {
                    SelectOption temp = sortingList[j];
                    sortingList[j] = sortingList[j - 1];
                    sortingList[j - 1] = temp;
                }
            }
        }
        return sortingList;
    }
 
}