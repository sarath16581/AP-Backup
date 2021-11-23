/**
    * This Class is controller for PON update page so that we can decide the case type and resolution by network and send automation
      emails to users and close the case.
    * 
    * @Author kalpita.talwadekar@auspost.com.au
    * @Date 25/07/2016
    * 03/04/2017  Eric Shen   add  isClosedbyNetwork flag to indicate if the case is closed by Mynetwork users via network response, fix for REQ1077315
    *   
    */
public class SSSW_PON_UpdateController {

    //class variables
    public  Network_Response__c nresp {get;set;}
    public  String cseId {get;set;}
    public  String templateId {get;set;}
    public  EmailTemplate template {get;set;}
    public  Boolean doNotShowEmail {get;set;}
    public  Case relatedCse {get;set;}
    public  String templateName {get;set;}
    public  Schema.FieldSet fieldSetObj {get;set;}
    private List<PON_Update_EmailTemplates__c> ponCS ;
    public  List<Schema.FieldSetMember> fieldSetMemberObj  {get;set;}
    public  String enqSubTypeFldSet {get;set;}
    public  boolean  noAutoClose {get;set;}
    public  String templateBody {get;set;}
    public  String templateBody2 {get;set;}
    public  String comments {get;set;}
    public  Map<String,String> fieldMap {get;set;}
    public  Boolean refreshPage {get;set;}
    public Double timeDueIn {get;set;}
    public string prevStatus;
    public boolean hasCaseStatusChanged {get;set;}
    private static final string DeliOption_NwComm_Mand1 = 'Redirection failure - unable to recover - DC prepared to compensate for loss';
    private static final string DeliOption_NwComm_Mand2 = 'Admits fault - DC prepared to compensate for loss';    
    private static final string DeliOption_NwComm_Mand3 =  'Other - back to CCC resolution*';    
    private static final Set<String> deliOptnsMandate = new Set<String>{'Redirection failure - unable to recover - DC prepared to compensate for loss', 
                                                            'Admits fault - DC prepared to compensate for loss',
                                                            'Other - back to CCC resolution*'};
    private static final String NW_COMM_ERROR = 'Please enter the network comments.';                                                            
    private static final String DROP_DOWN_ERROR = 'Please fill in the selections to proceed.';
    private static final String SENDER = 'Sender';
        
    
    
    /** 
      * @name: SSSW_PON_UpdateController 
      * @desciption: remote action method to get the recordTypeId
      * @param: ApexPages.StandardController stdCon
      * @return: NA
      *
      */
    public SSSW_PON_UpdateController (ApexPages.StandardController stdCon) {
        //nresp = new Network_Response__c ();
        cseId = stdCon.getRecord().Id;
        system.debug(cseId);
        doNotShowEmail = true;
        templateBody =SSSWConstants.EMPTY_SPACE;
        templateBody2 =SSSWConstants.EMPTY_SPACE;
        refreshPage = false;
        hasCaseStatusChanged  = false;
    }
    
    /** 
      * @name: initialize
      * @desciption: called on page load to setup data (capture case and network response details)
      * @param: NA
      * @return: NA
      *
      */
    public void initialize() {
        
        if(!String.isblank(cseId)) {
            for(Network_Response__c  nresponse : [Select Network_Comments__c,Send_Case_To_Customer_Service__c,CaseAction__c,
                                    Case_Comments__c,Quality_of_the_case__c ,DeliveryOptions__c,R_Root_Cause__c,
                                    Address_type__c,Request_hold_Case__c,More_Delivery_Information__c,
                                    Delivery_officer_knowledge__c,RelatedCase__c,Network_Response__c
                                    from Network_Response__c where  RelatedCase__c = :cseId order by createdDate desc limit 1]) {
                nresp = nresponse;
                //if(!nresp.Request_hold_Case__c) { 
                        nresp.Id = null;
                        nresp.RelatedCase__c  = cseId; 
                        nResp.Send_Case_To_Customer_Service__c = false; 
                // }                       
            }          
                                      
            if(nresp == null) {
                nresp = new Network_Response__c(RelatedCase__c = cseId);
            }
            
            relatedCse = [Select Id,CaseNumber,Description,Primary_Email__c,Network__c,Network__r.Name,SLATargetDate__c,NetworkTierSLA__c, Contact.FirstName, ArticleTest__r.Name,ProductSubCategory__c,
                                CaseOriginator__c,Address2Postcode__c, Status, NetworkComments__c,Contact.email, Type,Contact.Name,LastModifiedById ,
                                CreatedDate,Subject,Primary_Name__c,Address1__c ,Secondary_Contact__c ,Address2__c ,
                                
                                 
                                Quality_of_the_case__c, EnquirySubType__c from Case where Id = :cseId limit 1];  
            //timeDueIn = (relatedCse.SLATargetDate__c.getTime() - DateTime.now().getTime())/1000/60/60 ;
            //if(relatedCse.SLATargetDate__c < DateTime.now()) { timeDueIn = -1 ;}
            refreshPage = relatedCse.Status.contains(SSSWConstants.CLOSE_CONTAINSCHECK); 
            nResp.Enquiry_Sub_Type__c =  relatedCse.EnquirySubType__c;
            prevStatus = relatedCse.Status;
            ponCS = PON_Update_EmailTemplates__c.getAll().values();
            String fieldSetName = SSSWConstants.SSSW_Generic;
            for(PON_Update_EmailTemplates__c pcs: ponCS) {
                if(pcs.enquiry_Sub_Type__c!=null && pcs.enquiry_Sub_Type__c.equalsIgnoreCase(relatedCse.enquirySubType__c)) {
                    fieldSetName = pcs.field_set_Name__c;
                }
            }
            fieldMap = readFieldSet(fieldSetName,SSSWConstants.NETWORK_RESP_OBJ );
        }
        
    }
    
    /** 
      * @name: readFieldSet
      * @desciption: method to get the field set specific to an enquiry type
      * @param: String fieldSetName, String ObjectName
      * @return: Map<String,String>
      *
      */
    public static Map<String,String> readFieldSet(String fieldSetName, String ObjectName) {
        Map<String,String> fieldList = new Map<String,String>();
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
    
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetObj.getFields()) {
            fieldList.put(fieldSetMemberObj.getFieldPath(),fieldSetMemberObj.getLabel());
            
        }
        return fieldList ; 
    }  
        
     /** 
      * @name: setDeliveryOptions
      * @desciption: method just adds up to create the delivery option to refresh the delivery information
      * @param: NA
      * @return: NA
      *
      */
    public void setDeliveryOptions() {
        if(!String.isBlank(nresp.Address_Type__c) && !String.isBlank(nresp.Delivery_officer_knowledge__c))
        nresp.DeliveryOptions__c = nresp.Address_Type__c+nresp.Delivery_officer_knowledge__c;
        else
        nresp.DeliveryOptions__c = '';
    }
    
    /** 
      * @name: showEmailTemplate
      * @desciption: method to decide type of sub enquiry type and grouping to either auto close or shoot email
      * @param: NA
      * @return: NA
      *
      */
    public void showEmailTemplate(){
        try {
            if(String.isblank(nResp.Network_Comments__c) && !SSSWConstants.DISPUTED_DELIVERY.equalsIgnoreCase(relatedCse.EnquirySubType__c) || 
              (String.isblank(nResp.Network_Comments__c) && SSSWConstants.DISPUTED_DELIVERY.equalsIgnoreCase(relatedCse.EnquirySubType__c) &&
              String.isblank(nResp.Address_type__c) && String.isblank(nResp.Delivery_officer_knowledge__c) && 
              String.isblank(nResp.More_Delivery_Information__c) 
              ) ||
              (deliOptnsMandate.contains(nResp.More_Delivery_Information__c) && String.isblank(nResp.Network_Comments__c)) ) {
                nResp.Network_Comments__c.addError(NW_COMM_ERROR);
            }
            else if(SSSWConstants.DISPUTED_DELIVERY.equalsIgnoreCase(relatedCse.EnquirySubType__c) && 
                String.isblank(nResp.Address_type__c)  && !nresp.Request_Hold_Case__c) {
                nResp.Address_type__c.addError(DROP_DOWN_ERROR);
            }
            else if(SSSWConstants.DISPUTED_DELIVERY.equalsIgnoreCase(relatedCse.EnquirySubType__c) && 
                 String.isblank(nResp.Delivery_officer_knowledge__c)  && !nresp.Request_Hold_Case__c) {
                nResp.Delivery_officer_knowledge__c.addError(DROP_DOWN_ERROR);
            }
            else if(SSSWConstants.DISPUTED_DELIVERY.equalsIgnoreCase(relatedCse.EnquirySubType__c) && 
              String.isblank(nResp.More_Delivery_Information__c) && !nresp.Request_Hold_Case__c) {
                nResp.More_Delivery_Information__c.addError(DROP_DOWN_ERROR );
            }
            else {
                if((!SSSWConstants.DISPUTED_DELIVERY.equalsIgnoreCase(relatedCse.EnquirySubType__c) && 
                                        !relatedCse.Status.contains(SSSWConstants.CLOSE_CONTAINSCHECK)) ||
                                        ( !String.isBlank(relatedCse.Primary_Email__c) &&
                                        relatedCse.Primary_Email__c.equalsIgnoreCase(relatedCse.Contact.Email) || 
                                        SENDER.equalsIgnoreCase(relatedCse.CaseOriginator__c))
                                        ) {
                    nResp.Send_Case_To_Customer_Service__c = true;
                }
                
                if(!nResp.Send_Case_To_Customer_Service__c && !nresp.Request_Hold_Case__c  && 
                            !relatedCse.Status.contains(SSSWConstants.CLOSE_CONTAINSCHECK)) {
                    String caseCond = nresp.Address_type__c + nresp.Delivery_officer_knowledge__c+nresp.More_Delivery_Information__c;
                    system.debug(caseCond);
                    for(PON_Update_EmailTemplates__c mp: ponCS) {
                        if(caseCond.equalsIgnoreCase(mp.CaseCondition__c)) {
                            templateName = mp.Template_API_Name__c;
                            system.debug(templateName);
                            doNotShowEmail = false;
                        }
                    }
                    if(!String.isBlank(templateName)) {
                        template  = [Select Id, Body,HTMLValue, Subject from EmailTemplate where DeveloperName = :templateName limit 1];
                        templateId = template.id;
                        String temp = String.valueOf(template.HTMLValue);
                        templateBody = temp.replace('{!Case.CaseNumber}',relatedCse.CaseNumber); 
                        templateBody = !String.isblank(relatedCse.Contact.FirstName) ? 
                                        templateBody.replace('{!Contact.FirstName}',relatedCse.Contact.FirstName) : templateBody.replace('{!Contact.FirstName}','') ;
                        templateBody = relatedCse.ArticleTest__c!=null && !String.isBlank(relatedCse.ArticleTest__r.Name) ?
                                        templateBody.replace('{!Case.ReferenceID__c}',relatedCse.ArticleTest__r.Name) : templateBody.replace('{!Case.ReferenceID__c}','') ;
                        templateBody = nResp.More_Delivery_Information__c!=null && !String.isBlank(nResp.More_Delivery_Information__c) ?
                                        templateBody.replace('{!Network_Response__c.More_Delivery_Information__c}',
                                        nResp.More_Delivery_Information__c) : templateBody.replace('{!Network_Response__c.More_Delivery_Information__c}','') ;
                        templateBody = !String.isblank(relatedCse.ProductSubCategory__c) ? 
                                        templateBody.replace('{!Case.ProductSubCategory__c}',relatedCse.ProductSubCategory__c): 
                                        templateBody.replace('{!Case.ProductSubCategory__c}','') ;
                        templateBody = templateBody.replace('{!User.FirstName}',UserInfo.getFirstName());
                        templateBody =!String.isblank(relatedCse.Type) ? 
                                        templateBody.replace('{!Case.Type}',relatedCse.Type): templateBody.replace('{!Case.Type}','') ;
                        templateBody =!String.isblank(relatedCse.Address2Postcode__c) ? 
                                        templateBody.replace('{!Case.Address2Postcode__c}',relatedCse.Address2Postcode__c): templateBody.replace('{!Case.Address2Postcode__c}','') ;                                    
                        templateBody =!String.isblank(relatedCse.Network__c) ? 
                                        templateBody.replace('{!Case.Network__c}',relatedCse.Network__r.Name): templateBody.replace('{!Case.Network__c}','') ;                                                                            
                        String thread = '[ ref:_' 
                                             + UserInfo.getOrganizationId().left(4) 
                                             + '0' 
                                             + UserInfo.getOrganizationId().mid(11,4) + '._' 
                                             + String.valueOf(relatedCse.Id).left(4) + '0' 
                                             + String.valueOf(relatedCse.Id).mid(10,5) + ':ref ]'; 
                         system.debug('---'+thread);
                         templateBody = templateBody.replace('{!Case.Thread_Id}',thread) ;                 
                        //for UI email to be shown - 
                        temp = String.valueOf(template.Body);
                        templateBody2 = temp.replace('{!Case.CaseNumber}',relatedCse.CaseNumber); 
                        templateBody2 = !String.isblank(relatedCse.Contact.FirstName) ? 
                                        templateBody2.replace('{!Contact.FirstName}',relatedCse.Contact.FirstName) : templateBody2.replace('{!Contact.FirstName}','') ;
                        templateBody2 = relatedCse.ArticleTest__c!=null && !String.isBlank(relatedCse.ArticleTest__r.Name) ?
                                        templateBody2.replace('{!Case.ReferenceID__c}',relatedCse.ArticleTest__r.Name) : templateBody2.replace('{!Case.ReferenceID__c}','') ;
                        templateBody2 = nResp.More_Delivery_Information__c!=null && !String.isBlank(nResp.More_Delivery_Information__c) ?
                                        templateBody2.replace('{!Network_Response__c.More_Delivery_Information__c}',
                                        nResp.More_Delivery_Information__c) : templateBody2.replace('{!Network_Response__c.More_Delivery_Information__c}','') ;
                        templateBody2 = !String.isblank(relatedCse.ProductSubCategory__c) ? 
                                        templateBody2.replace('{!Case.ProductSubCategory__c}',relatedCse.ProductSubCategory__c): 
                                        templateBody2.replace('{!Case.ProductSubCategory__c}','') ;
                        templateBody2 = templateBody2.replace('{!User.FirstName}',UserInfo.getFirstName());
                        templateBody2 =!String.isblank(relatedCse.Type) ? 
                                        templateBody2.replace('{!Case.Type}',relatedCse.Type): templateBody2.replace('{!Case.Type}','') ;
                        templateBody2 =!String.isblank(relatedCse.Address2Postcode__c) ? 
                                        templateBody2.replace('{!Case.Address2Postcode__c}',relatedCse.Address2Postcode__c): templateBody2.replace('{!Case.Address2Postcode__c}','') ;                                                    
                        templateBody2 =!String.isblank(relatedCse.Network__c) ? 
                                        templateBody2.replace('{!Case.Network__c}',relatedCse.Network__r.Name): templateBody2.replace('{!Case.Network__c}','') ;                                         
                        templateBody2 = templateBody2.replace('{!Case.Thread_Id}',thread) ;                                                            
                    }
                    else {
                        nResp.Send_Case_To_Customer_Service__c = true;
                    }
                }
                if(nResp.Send_Case_To_Customer_Service__c || nresp.Request_Hold_Case__c ||  
                                        relatedCse.Status.contains(SSSWConstants.CLOSE_CONTAINSCHECK)) {
                    updateRespoTemp();
                }
            }
        }
        catch(Exception exp) {
            //log exceptions
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                            SSSW_PON_UpdateController.class.getName(), 'showEmailTemplate', '', LoggingLevel.ERROR);
        }  
    }
    
    /** 
      * @name: updateRespoTemp
      * @desciption: method to update/insert response and update the case accordingly.
      * @param: NA
      * @return: NA
      *
      */
    public void updateRespoTemp() {
        try {
            String newStatus = [Select id, Status from Case where id = :cseId limit 1].Status;
            system.debug(newStatus);
            system.debug(prevStatus);
            if(prevStatus.equalsIgnoreCase(newStatus)) {
                //nresp.Case_Comments__c = !String.isBlank(nresp.Case_Comments__c) ? nresp.Case_Comments__c : '';
                //nresp.Case_Comments__c = nresp.Case_Comments__c + '\r\n' + comments;
                if(nresp.Request_Hold_Case__c) {
                    nResp.CaseAction__c = 'On Hold';
                    database.insert(nresp);
                }
                else if(relatedCse.Status.contains(SSSWConstants.CLOSE_CONTAINSCHECK)) {
                    nResp.CaseAction__c = relatedCse.Status;
                    database.insert(nresp);
                }
                else {
                    //check if contact has email always and send email, else route to CCC
                    if(relatedCse.Contact!=null && relatedCse.Contact.Email!=null && !nResp.Send_Case_To_Customer_Service__c ) {
                        OrgWideEmailAddress oweaId = [select Id from OrgWideEmailAddress where 
                                                        Address = :SSSWCOnstants.OWADDR_CUST_SERVICE limit 1];
                        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                        msg.setSubject(template.Subject.replace('{!Case.CaseNumber}',relatedCse.CaseNumber));
                        msg.setTemplateId(templateId);
                        msg.setHTMLBody(templateBody);
                        msg.setTargetObjectId(relatedCse.ContactId);
                        msg.setOrgWideEmailAddressId(oweaId.Id);
                        msg.setWhatId(CseId);
                        msg.setSaveAsActivity(true);
                        if(!Test.isRunningTest()) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { msg });
                    } else {
                        nResp.Send_Case_To_Customer_Service__c = true;
                    }
                    if(!nResp.Send_Case_To_Customer_Service__c) {
                        nResp.CaseAction__c = SSSWConstants.CLOSE_CONTAINSCHECK;
                        //03-Apr-17 Eric Shen   add this new flag to indicate if the case is closed by Mynetwork users via network response
                         nResp.isClosedByNetwork__c = true; 
                    }
                    else {
                         nResp.CaseAction__c = SSSWConstants.NETWORK_RESP_STATUSSET;
                    }
                    nresp.Id = null;
                    nresp.RelatedCase__c = cseId;
                    database.insert(nresp);
                
                } 
            }     
            else {
                hasCaseStatusChanged  = true;
            }     
        }
        catch(Exception exp) {
            //log exceptions
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                            SSSW_PON_UpdateController.class.getName(), 'updateRespoTemp', '', LoggingLevel.ERROR);
        }
    }
    
    /** 
      * @name: goBack
      * @desciption: method to allow users to change the response
      * @param: NA
      * @return: NA
      *
      */
    public   void goBack() {
        templateId = SSSWConstants.EMPTY_SPACE;
        template = new EmailTemplate();
        doNotShowEmail = true;
    }
    
}