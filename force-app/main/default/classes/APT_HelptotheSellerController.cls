/**
Description: This apex class is extension class for APT_HelptotheSeller page
Created By: Adil muzaffar
Created Date: 12th Dec, 2015
Last Modified By:
Last Modified Date:
*/
public with sharing class APT_HelptotheSellerController {
Public string AgreementId;
Public boolean Message {get;set;}
Public string redirectCheck{get;set;}
Public List<APT_R2T_Signers_Authority_Help_Text__c> CSValue;
Public Apttus__APTS_Agreement__c Agrvalue {get;set;}
Public ID rectypeid;
Public RecordType rt;
public boolean donext{get;set;}
public string tempname{get;set;}
public List<APT_R2T_Signers_Authority_Help_Text__c> checklist{get;set;}
public map<APT_R2T_Signers_Authority_Help_Text__c,string> csmap{get;set;}
Public Static final String TITLE = 'Message';
public static String titleValue {get{return TITLE;}set;}
Public Static final String NEXT = 'Next';
public static String nextValue {get{return NEXT;}set;}
Public Static final String CANCEL = 'Cancel';
public static String cancelValue {get{return CANCEL;}set;}
public Static String docusignRecipientErrorMessage{get; set;}
public Static List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> docusignRecipientList; 
public Static Boolean displayNextButton {get; set;}
public Static Boolean displayAddSignerButton {get; set;} 
public Static Boolean displayHelpMessage {get; set;}
 /**
     Constructor
 **/   
 public APT_HelptotheSellerController(ApexPages.StandardController controller) {
    donext=true;
    Message= true;  
    displayNextButton = false;
    displayHelpMessage = false;
    displayAddSignerButton = true;
    init ();
  
} 
    
/**
 init Method
**/
public void init () {
    docusignRecipientList = new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>();
    AgreementId = Apexpages.currentPage().getParameters().get(APT_Constants.URL_ID);
    redirectCheck=Apexpages.currentPage().getParameters().get(APT_Constants.URL_NAME);
    system.debug('@@Redirectcheck'+redirectCheck);

    Agrvalue=[select id, name,recordtype.name,Apttus__Agreement_Category__c,Apttus__Total_Contract_Value__c from Apttus__APTS_Agreement__c where id=:AgreementId ];
    system.debug('@@Agrtotal'+Agrvalue.Apttus__Total_Contract_Value__c);
    system.debug('@@rtname1');
    try {
    docusignRecipientList = [select id from Apttus_DocuApi__DocuSignDefaultRecipient2__c 
                                where Apttus_CMDSign__AgreementId__c =:AgreementId 
                                AND Apttus_DocuApi__RecipientType__c IN (:APT_Constants.Signer ,:APT_Constants.In_Person_Signer)];
    
    //tempname = 'Agrvalue.recordtype.name';
    ID rectypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(Agrvalue.recordtype.name).getRecordTypeId();   
    rt = [SELECT Id,developername FROM RecordType WHERE  Id =: rectypeid LIMIT 1];    
    system.debug('@@rtname1'+rt.developername);
    string url=APT_Constants.SEPERATOR_NO_SPACE;
    tempname= APT_Constants.SEPERATOR_NO_SPACE;    
    List<APT_R2T_Signers_Authority_Help_Text__c> Listrecordtypematc= new List<APT_R2T_Signers_Authority_Help_Text__c>();
    List<APT_R2T_Signers_Authority_Help_Text__c> ListComparechecke=new List<APT_R2T_Signers_Authority_Help_Text__c>();
    
    List<APT_R2T_Signers_Authority_Help_Text__c> ListDocusignRecipientCheck =new List<APT_R2T_Signers_Authority_Help_Text__c>();
    
    CSValue = APT_R2T_Signers_Authority_Help_Text__c.getall().values();
    system.debug('csvalue'+CSValue);
    csmap = new map<APT_R2T_Signers_Authority_Help_Text__c,string>();
    for(APT_R2T_Signers_Authority_Help_Text__c temp : CSValue){
    csmap.put(temp,temp.Message__c);
    }
    for(APT_R2T_Signers_Authority_Help_Text__c temp1 : CSValue){
    system.debug('Entering For');  
    if((rt.developername == temp1.Record_Type_Name__c) && (temp1.Compare_Contract_Category__c == True) && (temp1.Contract_Category__c == Agrvalue.Apttus__Agreement_Category__c) && temp1.Type__c.equalsIgnoreCase(APT_Constants.HelpText))
    {
     system.debug('Entering 1st if');   
        ListComparechecke.add(temp1);
        }
    if((rt.developername == temp1.Record_Type_Name__c) && (temp1.Compare_Contract_Category__c == False) && (temp1.Contract_Category__c == Agrvalue.Apttus__Agreement_Category__c ) && temp1.Type__c.equalsIgnoreCase(APT_Constants.HelpText)) {
        system.debug('Entering 2nd if');  
        Listrecordtypematc.add(temp1);
    }
    
    if((rt.developername == temp1.Record_Type_Name__c) && temp1.Type__c.equalsIgnoreCase(APT_Constants.MinSigners) && docusignRecipientList.size() < temp1.Min_Number_of_Signers__c  ) {
        system.debug('In Docusign check');
        ListDocusignRecipientCheck.add(temp1);
    }
 
   }
    if(Listrecordtypematc.size()>0){
     for(APT_R2T_Signers_Authority_Help_Text__c temp4 : Listrecordtypematc){
         System.debug('***************:'+Agrvalue.Apttus__Total_Contract_Value__c+''+temp4.Value_From__c+''+Agrvalue.Apttus__Total_Contract_Value__c+''+temp4.Value_To__c);
     if((Agrvalue.Apttus__Total_Contract_Value__c >=temp4.Value_From__c) && (Agrvalue.Apttus__Total_Contract_Value__c<temp4.Value_To__c) )
     {
     
    system.debug('Entering not checked');
   
    tempname=csmap.get(temp4);
    displayHelpMessage = true;
    }
     }
     } 
     if(ListComparechecke.size()==1){
   
    tempname = csmap.get(ListComparechecke[0]);
    displayHelpMessage = true;
    system.debug('Entering 3rd if'); 
   
      }
     if(ListDocusignRecipientCheck.size() == 1) {
         docusignRecipientErrorMessage = APT_Constants.MIN_RECIPIENT_ERROR + Integer.valueOf(ListDocusignRecipientCheck[0].Min_Number_of_Signers__c);
          displayNextButton = true;
          displayAddSignerButton = false;
     } 
      if(ListComparechecke.size()==0){
      }
      
      checklist= new List<APT_R2T_Signers_Authority_Help_Text__c>();
     if(ListComparechecke.size()>1){
     system.debug('Entering  checkedIF');
     for(APT_R2T_Signers_Authority_Help_Text__c temp3 : ListComparechecke){
     
     if((Agrvalue.Apttus__Total_Contract_Value__c >=temp3.Value_From__c) && (Agrvalue.Apttus__Total_Contract_Value__c < temp3.Value_To__c) )
     {
     system.debug('Entering  checked');
   checklist.add(temp3);

     }
    }
      
 if(checklist.size()==1){
   tempname=csmap.get(checklist[0]);
   displayHelpMessage = true;
   }
   
   if(checklist.size()>1){
   system.debug('Entering Final');
   tempname=APT_Constants.SEPERATOR_NO_SPACE;
   displayHelpMessage = true;
   }
 
  }
    } catch(system.exception ex) {
                      
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
      
    }
}
 /**
     This method will redirect you to next page.
 **/   
 public pagereference donext(){
    try {
        if((tempname==null ||tempname==APT_Constants.SEPERATOR_NO_SPACE)&&(redirectCheck!=null) && String.isEmpty(docusignRecipientErrorMessage) )  
            {
            
            return new PageReference(APT_Constants.URL_DOCUSIGN_CREATE_ENVELOPE +AgreementId);
            }
            if((tempname==null ||tempname==APT_Constants.SEPERATOR_NO_SPACE)&&(redirectCheck==null) )  
            {
            return new PageReference(APT_Constants.URL_SEND_MAIL_PAGE+AgreementId + APT_Constants.URL_SEND_MAIL_PAGE_PARAMETERS);
    
            }
            return null;
     } catch(system.exception ex) {
                      
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
  }
  /**
     This method will redirect you to Previous page.
 **/  
 public pageReference docancel(){  
        
        try {
          return new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + AgreementId);
        } catch(system.exception ex) {
                      
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }  
    }
 // This method will redirect you to create new docusign recipient page.   
 public pageReference addDocusignRecipient(){  
     try {
        system.debug('*** addDocusignRecipient');

        PageReference pageRef = new PageReference('/lightning/o/Apttus_DocuApi__DocuSignDefaultRecipient2__c/new');
        pageRef.getParameters().put('useRecordTypeCheck', '1');
        pageRef.getParameters().put('defaultFieldValues','Apttus_CMDSign__AgreementId__c='+AgreementId);

        return pageRef;
    } catch(system.exception ex) {
                      
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        return null;
    }
    
}


 /**
     This method will redirect you to next page.
 **/ 
 public pagereference Next(){
        try {
            if(redirectCheck!=null ){
                return new PageReference(APT_Constants.URL_DOCUSIGN_CREATE_ENVELOPE+AgreementId);
            }
            if(redirectCheck==null )  
            {
            return new PageReference(APT_Constants.URL_SEND_MAIL_PAGE+AgreementId +APT_Constants.URL_SEND_MAIL_PAGE_PARAMETERS);
        
            }
            return null;
        } catch(system.exception ex) {
                      
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
        
  }

}