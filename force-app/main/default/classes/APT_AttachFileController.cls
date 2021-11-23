/**
 * Created by Raviteja Epuri * 
 * Date: 12th Jan 2016
 * Upload Jpg,png,gif files and insert links to product Image of Product
 * Files with size more than 1Mb are not allowed.
 
 **/ 
 
public with sharing class APT_AttachFileController {

    public String choice{get;set;}
    public String objectId {get;set;}
    public String folderId {get;set;}
    public String comboLabel{get;set;}
    public String objectType {get;set;}
    public String infoMessage {get;set;}
    public String errorMessage {get;set;}    
    public Integer fileSize {get;set;}    

    private SObject objectDoc;
    public Document mydoc;

    public String fieldName {get;set;}
    public SObject recordObject {get;set;}
    public Boolean isUploaded {get;set;}
    public Boolean isUploadPressed {get;set;}
   
   
   /**
    Constructor to get the values from Url
    **/
    public APT_AttachFileController() {
        isUploaded = false;
        objectId = escapeSingleQuates(ApexPages.currentPage().getParameters().get(APT_Constants.URL_ID));
        fieldName = escapeSingleQuates(ApexPages.currentPage().getParameters().get(APT_Constants.URL_SELECTED_VALUE));
        objectType =escapeSingleQuates(ApexPages.currentPage().getParameters().get(APT_Constants.URL_OBJ));
        comboLabel = escapeSingleQuates(ApexPages.currentPage().getParameters().get(APT_Constants.URL_COMBO_LABEL));       
     }
    
    /**
    Method for remove single quotes from string
    **/
    private String escapeSingleQuates(String param) {
        if (string.isNotBlank(param)) {
            param = String.escapeSingleQuotes(param);
        }
        return param;
    }

    /**
        Fetch product
    **/
    public sObject getObject(String fieldName, String objectId) {
       try{  
        Schema.sObjectType objectDoc = Schema.getGlobalDescribe().get(objectType).getDescribe().getSObjectType();
        System.debug('fieldNamegetObject' + fieldName + 'objectType'+objectType);
        String sql = APT_Constants.SOQL_SELECT_ID + fieldName + APT_Constants.SOQL_FROM + objectType + APT_Constants.SOQL_WHERE_ID + APT_Constants.Qoute + objectId + APT_Constants.Qoute;
        List<SObject> listSo = Database.query(sql);
        return (!listSo.isEmpty() ? listSo[0] : null);
        } catch (Exception ex) {
            System.debug('getObject exception:' + ex.getMessage());
            apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  ex.getMessage()));
            return null;
        }
    }
    /**
    Fetch the folderID 
    **/
    public String getFolderId() {
    try{
         List<Folder> listid =[select id from Folder where name =:APT_Constants.FOLDERNAME];
        if (listid.isEmpty()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, APT_Constants.FOLDER_DOES_EXIST_MESSAGE));
            return APT_Constants.EMPTY_STRING;
        }
        return listid[0].Id;
        } catch (Exception ex) {
            apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  ex.getMessage()));
            return null;
        } 
    }

    /**
        Method to retrieve document
    **/
    public Document getImage() {      
        try {
            mydoc = new Document();       
            return mydoc;
        } catch (Exception ex) {
            System.debug('getObject exception:' + ex.getMessage());
            apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  ex.getMessage()));
            return null;
        }
     }

    /**
     upload only png, jpeg,
    **/
    public Pagereference uploadFile() {
      try{
        if (mydoc.Body == NULL) return NULL;
        if ((!String.isNotBlank(getFolderId()))) return NULL;
        mydoc.folderid = getFolderId();
        infoMessage = APT_Constants.EMPTY_STRING;
        errorMessage = APT_Constants.EMPTY_STRING;
       
        //fileSize=(mydoc.BodyLength / 1024); // no more than 1Mb
        fileSize=mydoc.Body.size()/1024;
        if (mydoc.ContentType.contains(APT_Constants.FILE_TYPE_JPEG) || mydoc.ContentType.contains(APT_Constants.FILE_TYPE_PNG) || mydoc.ContentType.contains(APT_Constants.FILE_TYPE_GIF)) {
           if (fileSize > 1024)
           {
               errorMessage =APT_Constants.FILE_SIZE_RESTRICTION;
               ApexPages.addMessage(new ApexPages.message(ApexPages.severity.error,errorMessage));
               isUploadPressed = false;
               mydoc.Body=null;
             return null;
          }
            System.debug('mydoc:'+mydoc);
            insert mydoc;
            isUploaded = true;
            
            insertIntoReachTextBox();
      
            infoMessage = mydoc.Name + APT_Constants.SEPERATOR_SPACE + APT_Constants.SUCCESS_UPLOAD_MESSAGE;
            isUploadPressed = true;
            
            mydoc.Body=null;             
        }else{
            errorMessage = APT_Constants.IMAGESONLY;
            apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  errorMessage));
            isUploadPressed = false;
            mydoc.Body=null;   
            return null;
        
        }
        return null;
        } catch (Exception ex) {
            System.debug('mydocgetmessage:'+ex.getMessage());
            errorMessage = APT_Constants.RESTRICTION_FILE_UPLOAD_MESSAGE;
            apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  ex.getMessage()));
            isUploadPressed = false;
            mydoc.Body=null;   
            return null;
        } 
    }

    /**
    method to insert record of attachment
    **/
    public void insertIntoReachTextBox() {
      try{
        recordObject = getObject(fieldName, objectId);
        System.debug('fieldName' + fieldName + 'getImagePath' + getImagePath());
        recordObject.put(fieldName, getImagePath());
        update recordObject;
        mydoc.Body = NULL;
        
      } catch (Exception ex) {
         apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  ex.getMessage()));            
        }
    }

    /**
     id is 15 symbols 
    **/
    public String getImageId(String str) {
        try {
            if (string.isNotBlank(str)) {
                return str.substring(0, 15);
            }
            return APT_Constants.EMPTY_STRING;
        } catch (Exception ex) {
            System.debug('getObject exception:' + ex.getMessage());
            apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  ex.getMessage()));
            return null;
        }
    }
   
    /**
    construct Image Path
    **/
    public String getImagePath() {
        try {
            System.debug('getImageId(mydoc.id)' + getImageId(mydoc.id) + 'getHost()' + getHost());
            return APT_Constants.IMAGE_TAG + getHost() + APT_Constants.SERVLET_TAG + getImageId(mydoc.id) + APT_Constants.CLOSE_TAG ;
        } catch (Exception ex) {
                System.debug('getObject exception:' + ex.getMessage());
                apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  ex.getMessage()));
                return null;
        }
        
    }

    /** 
     fetch the base Url
    **/ 
    public String getHost() {
         try {
            return ApexPages.currentPage().getHeaders().get(APT_Constants.URL_HOST);
         } catch (Exception ex) {
            System.debug('getObject exception:' + ex.getMessage());
            apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  ex.getMessage()));
            return null;
        }
  }

   /**
    return to Product
    **/
    public PageReference goHome() {
        try {
            PageReference pageRef = new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + objectId);
            return pageRef;
        } catch (Exception ex) {
            System.debug('getObject exception:' + ex.getMessage());
            apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  ex.getMessage()));
            return null;
        } 
    }
    /*
    // delete __c prefix  from Name of Field.
    public String getExtractName() {
        String ss = fieldName.substring(0, fieldName.length() - 3);
        if (string.isNotBlank(ss))
            return ss;
        return APT_Constants.EMPTY_STRING;
    }
    */
}