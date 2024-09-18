/**************************************************
Description:       This Class is controller for Network Response Screen for network users - from myNetwork Portal
History:
--------------------------------------------------
25/07/2016 - kalpita.talwadekar@auspost.com.au - created
03.04.17 - Eric Shen - add  isClosedbyNetwork flag to indicate if the case is closed by Mynetwork users via network response, fix for REQ1077315
23.02.18 - kalpita.talwadekar@auspost.com.au - updated code for MW0002003(case notifications) and MW0002001(Sending case back to CCC)
24.03.18 - kalpita.talwadekar@auspost.com.au - updated code for MW0002004 - case re-assignment
25.04.18 - kalpita.talwadekar@auspost.com.au - updated code for MW0002006 - added templates/options for DDS automation
06.06.18 - kalpita.talwadekar@auspost.com.au - updated code for coding standard follow - TDO-202
17.07.18 - kalpita.talwadekar@auspost.com.au - fix for REQ1451356 to update the acknowledgeAndSave method.
2018-07-12 - nathan.franklin@auspost.com.au - changed setContactRequiresEscalation method to use new SSSW_Routing class
2019-01-07 - saiswetha.pingali@auspost.com.au - Fix for INC1214840 - Added exception handling to display the validation errors raised when updating the case  
2019-02-21 - swati.mogadala@auspost.com.au  - Removed Network Reponse picklist from the mynetwork VF page REQ1700918
2019-04-26 - Swati.mogadala@auspost.com.au  - Update 'Message to network' from the case description field on the network response record as per REQ1760281
18.11.19 - Gunith.Devasurendra@auspost.com.au - Corrected the Thread ID for Network Response Emails (INC1437080)
03.02.20 - Gunith.Devasurendra@auspost.com.au - Selection on Case.DescriptionofContents__c (REQ2085413)
2020-05-20 - haraprasad.sahoo@auspost.com.au - Added requestoHold variable and its handling
2023-06-05 - jacob.isaac@auspost.com.au - Resetting Flag Case for Review Field on UI for all SSSW Scenarios - REQ3111278
2024-08-28 - Mona Raghav - REQ3388493 - Method TrimContent added to trim the escalation email content to the field length before updating
**************************************************/
public class SSSW_MyNetworkResponsePageContr {

    //class variables
    public  Network_Response__c nresp {get;set;} //for actual network response
    //for the current case details
    public  String cseId {get;set;} 
    public  Case relatedCse {get;set;} 

    // for the email template details for automation of DDS
    public  String templateId {get;set;} 
    public  EmailTemplate template {get;set;} 
    public  String templateName {get;set;}
    public  String templateBody {get;set;}
    public  String templateBody2 {get;set;}
    @TestVisible private List<PON_Update_EmailTemplates__c> ponCS ;
    
    //boolean for page navigations of DDS and Non-DDS
    public  Boolean doNotShowEmail {get;set;} 
    //boolean to display the confirmation dialog when Request_hold_Case__c is false
    public Boolean requesttoHold {get;set;}
    //for fields to be displayed based on enquiry sub type of case DDS and Non-DDS
    public  String enqSubTypeFldSet {get;set;}
    public  Schema.FieldSet fieldSetObj {get;set;}
    public  List<Schema.FieldSetMember> fieldSetMemberObj  {get;set;}
    public  Map<String,String> fieldMap {get;set;}
    public  Map<String,String> fieldMap2 {get;set;}

    public  Boolean refreshPage {get;set;} // for vfpage refresh to navigate back to home screen
    private string prevStatus; // for status change capture in between process of response
    public boolean hasCaseStatusChanged {get;set;} // boolean for above status change to show message on the respose screen
    public Boolean showCaseDetails {get;set;} //for case response screen and email screen navigations
                                                   
    //setting up constants for repetative usage in code
    private static final String NW_COMM_ERROR = 'Please enter the network comments.';                                                            
    private static final String DROP_DOWN_ERROR = 'Please fill in the selections to proceed.';
    private static final String SENDER = 'Sender';

    //variables for Case re-assignment
    @TestVisible private static  string UNKNOWN_EMAIL = 'unknown@email.com';
    public static  Boolean isTest = false;
    public Case caseToUpdate {get;set;} //  for case update on re-assignment
    public boolean reassignRefresh {get;set;} // for case refresh on visualforce on case re-assignment

    public boolean hasError {get;set;} // for error message display on UI
    public boolean contactRequiresEscalation { get; private set; } //boolean for identification of case escalation for re-assignment
    public String updMsgString {get;set;} // update case scenario - to display message on response screen
    /** 
      * @name: SSSW_MyNetworkResponsePageContr 
      * @desciption: constructor for variable initialization
      * @param: ApexPages.StandardController stdCon
      * @return: NA
      *
      */
    public SSSW_MyNetworkResponsePageContr (ApexPages.StandardController stdCon) {
        cseId = stdCon.getRecord().Id;
        //setting/initializing of variables
        doNotShowEmail = true;
        templateBody = SSSWConstants.EMPTY_SPACE;
        templateBody2 = SSSWConstants.EMPTY_SPACE;
        refreshPage = false;
        hasCaseStatusChanged  = false;
        hasError = false;
        reassignRefresh = false;
    }

    /** 
      * @name: initialize
      * @desciption: called on page load to setup data - capture current case and network response(existing or not) details
      * @param: NA
      * @return: NA
      *
      */
    public void initialize() {
        
        if(!String.isblank(cseId)) {
            
            //query to pull network response if existing from the current case details 
            for(Network_Response__c nresponse : [Select Network_Comments__c,Send_Case_To_Customer_Service__c,CaseAction__c,
                                                Case_Comments__c,Quality_of_the_case__c ,DeliveryOptions__c,R_Root_Cause__c,to_CCC_action__c,
                                                Address_type__c,Request_hold_Case__c,More_Delivery_Information__c,Acting_Network__c,
                                                to_Reassign_Network__c, to_Reassign_Network__r.Contact_Facility__c,
                                                Delivery_officer_knowledge__c,RelatedCase__c,Network_Response__c,RelatedCase__r.Status, RelatedCase__r.Network__c
                                                from 
                                                    Network_Response__c 
                                                where  
                                                    RelatedCase__c = :cseId 
                                                order by 
                                                    createdDate desc 
                                                limit 1]) {
                                                        
                                        nresp = nresponse;
                                        // reset response id, because we need to capture every response as a seperate record
                                        nresp.Id = null; 
                                        nresp.RelatedCase__c  = cseId; 
                                        nResp.Send_Case_To_Customer_Service__c = false; 
                                        //REQ3111278 - For every case the Flag Case For Review field should be blank on UI
                                        nResp.Quality_of_the_case__c = null;
                                        // avoid transferring the case to CCC by defaulting new NET RES record's value to false           
                                        nResp.to_CCC_action__c = false; 
                                        requesttoHold = nresp.Request_hold_Case__c; 
                                        
                                        
                                        // if the case is reassigned by antother network to the opening network, following fields should be reset, 
                                        // and user should see this as a new case for the reassigned network 
                                        if(nresp.to_Reassign_Network__c != null) {
                                            nResp.Network_Response__c = null;
                                            nResp.R_Root_cause__c = null;
                                            nResp.Quality_of_the_case__c = null;
                                            nResp.Request_Hold_Case__c = null;
                                            nresp.to_Reassign_Network__c = null;
                                            nresp.Network_Comments__c = null;
                                            nresp.Address_type__c = '';
                                            nresp.Delivery_officer_knowledge__c= '';
                                            nresp.DeliveryOptions__c= '';
                                            nresp.More_Delivery_Information__c= '';
                                        }  
                                        
            }    
            
            //query for retreival of relevant case fields from current case id                       
            relatedCse = [Select Id,CaseNumber,Description,ResolutionCode__c,Primary_Email__c,Network__c,Network__r.Name,SLATargetDate__c,NetworkTierSLA__c, Contact.FirstName, ArticleTest__r.Name,ProductSubCategory__c,
                CaseOriginator__c,Address2Postcode__c, Status, NetworkComments__c,Contact.email, Type,Contact.Name,LastModifiedById ,ReferenceId__c,ClosedDate,
                CreatedDate,Subject,Primary_Name__c,Address1__c ,Secondary_Contact__c ,Address2__c ,Root_cause__c , Owner.Name,
                OwnerId,ProductCategory__c ,Origin ,LastModifiedDate , IsHLC__c, IsCR__c, 
                Customer_Type__c , isNewForRouting__c, EscalationEmail__c, IsNew__c,
                Quality_of_the_case__c, EnquirySubType__c, DescriptionofContents__c from Case where Id = :cseId limit 1];
            // if no existing response then set the case relation
            if(nresp == null) {
                nresp = new Network_Response__c(RelatedCase__c = cseId);
                caseToUpdate = relatedCse; 
            }                                
            // for closed cases to be able to just capture the response without any action on the case
            refreshPage = relatedCse.Status.contains(SSSWConstants.CLOSE_CONTAINSCHECK); 
            nResp.Enquiry_Sub_Type__c =  relatedCse.EnquirySubType__c;
            
            //for message on updated case scenario - where case is updated from backend due to any reason like - tracking update, customer response etc.
            /*if(relatedCse.Owner.Name != 'SSSW Network Queue' && relatedCse.Root_cause__c == 'Awaiting Network Response')
            updMsgString = relatedCse.Owner.Name != 'SSSW Network Queue' && relatedCse.Root_cause__c == 'Awaiting Network Response' && relatedCse.Status == 'Closed' ?
                            'This case is now closed. No further action is required.' : 'This case has received further information and is now under review by the Customer Contact Centre';
            */
             if(relatedCse.Root_cause__c == 'Awaiting Network Response' && (relatedCse.Owner.Name != 'SSSW Network Queue' || 
                           (relatedCse.Owner.Name == 'SSSW Network Queue' && relatedCse.Status!= 'Awaiting Network Response' )) )
            updMsgString = relatedCse.Status == 'Closed' ?
                           'This case is now closed. No further action is required.' : 'This case has received further information and is now under review by the Customer Contact Centre';
            // variable set Acting_Network__c - for identifying who has responded on the case before re-assignment and from which network
            nResp.Acting_Network__c= relatedCse.Network__c;
            
            prevStatus = relatedCse.Status;
            
            //create email template map based on custom setting
            ponCS = PON_Update_EmailTemplates__c.getAll().values();
            String fieldSetName = SSSWConstants.SSSW_Generic;
            for(PON_Update_EmailTemplates__c pcs: ponCS) {
                //for DDS enquiry sub type - select Field set 
                if(pcs.enquiry_Sub_Type__c!=null && pcs.enquiry_Sub_Type__c.equalsIgnoreCase(relatedCse.enquirySubType__c)) {
                    fieldSetName = pcs.field_set_Name__c;
                    fieldMap = readFieldSet(fieldSetName,SSSWConstants.NETWORK_RESP_OBJ,relatedCse.enquirySubType__c );
                }
            }
            //for all generic fields irrespective of DDS and Non-DDS
            fieldMap2 = readFieldSet(SSSWConstants.SSSW_Generic,SSSWConstants.NETWORK_RESP_OBJ,relatedCse.enquirySubType__c );
        }
        
    }

    /** 
      * @name: readFieldSet
      * @desciption: method to get the field set specific to an enquiry type
      * @param: String fieldSetName, String ObjectName
      * @return: Map<String,String>
      *
      */
    public static Map<String,String> readFieldSet(String fieldSetName, String ObjectName, String enq) {
        //use global descibe for getting the fieldsets out of case object
        Map<String,String> fieldList = new Map<String,String>();
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        
        //loop through the field sets and get the fields out in a map
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetObj.getFields()) {
            if(!'Disputed Delivery Scan'.equalsIgnoreCase(enq))// Removed as per REQ1700918- && 'Network Response'.equalsIgnoreCase(fieldSetMemberObj.getLabel()))
                fieldList.put(fieldSetMemberObj.getFieldPath(),fieldSetMemberObj.getLabel());
            if(!'Network Response'.equalsIgnoreCase(fieldSetMemberObj.getLabel()))
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
        if(!String.isBlank(nresp.Address_Type__c) && !String.isBlank(nresp.Delivery_officer_knowledge__c)) {
            nresp.DeliveryOptions__c = nresp.Address_Type__c+nresp.Delivery_officer_knowledge__c;
        }
        else {
            nresp.DeliveryOptions__c = '';
        }
    }

    /** 
      * @name: showEmailTemplate
      * @desciption: method to decide type of sub enquiry type and grouping to either auto close and shoot email or specific response action  
      * @param: NA
      * @return: NA
      *
      */
    public void showEmailTemplate(){
        try {
            hasError = false; 
            
            //INC1214840 - Verifying any vaidation error available on case record.
            Case checkCase = [Select id, casenumber from Case where id = :cseID limit 1];
            update checkCase; 
            
            //if else loop for error handling on response 
            if('Feedback'.equalsIgnoreCase(relatedCse.Type) && nresp.to_CCC_action__c 
                    && nresp.Request_Hold_Case__c) { // we cannot hold case and send to CCC at the same time for feedback cases
                nResp.to_CCC_action__c.addError('Either hold the case for investigation or send to CCC for investigation');
                hasError = true;
            } else if( String.isblank(nResp.Network_Comments__c) ) {//network comments are always required to save the response
                nResp.Network_Comments__c.addError(NW_COMM_ERROR);
                hasError = true;
            } else if(nresp.to_CCC_action__c && !String.isBlank(nresp.to_Reassign_Network__c)) { //cannot send back to CCC and re-assign at same time
                nResp.to_CCC_action__c.addError('Cannot send back to CCC and reassign at the same time.');
                hasError = true;
            } else if(!String.isBlank(nresp.to_Reassign_Network__c) && nResp.to_Reassign_Network__c == relatedCse.Network__c ) { //  we cannot re-assign to self network
                nResp.to_Reassign_Network__c.addError('Cannot assign to your own network');
                hasError = true;
            } else if('Feedback'.equalsIgnoreCase(relatedCse.Type) && nresp.to_CCC_action__c ) { //  feedback cases if sent back to ccc, update the response and finish the process
                nResp.CaseAction__c = 'CCC to review';
                //Updating 'Message to network' from the case description field as per REQ1760281        
                nResp.Message_to_Networks__c = relatedCse.Description;
                database.insert(nResp);
            } else if(!String.isBlank(nresp.to_Reassign_Network__c)) { //  if case is re-assigned, then call below method for further processing
                contactAnotherNetwork();
            } else if(SSSWConstants.DISPUTED_DELIVERY.equalsIgnoreCase(relatedCse.EnquirySubType__c) && 
                String.isblank(nResp.Address_type__c)  && !nresp.Request_Hold_Case__c) { // to mandate drop down selectiions on DDS
                nResp.Address_type__c.addError(DROP_DOWN_ERROR);
                hasError = true;
            } else if(SSSWConstants.DISPUTED_DELIVERY.equalsIgnoreCase(relatedCse.EnquirySubType__c) && 
                 String.isblank(nResp.Delivery_officer_knowledge__c)  && !nresp.Request_Hold_Case__c) {  // to mandate drop down selectiions on DDS
                nResp.Delivery_officer_knowledge__c.addError(DROP_DOWN_ERROR);
                hasError = true;
            } else if(SSSWConstants.DISPUTED_DELIVERY.equalsIgnoreCase(relatedCse.EnquirySubType__c) && 
                        String.isblank(nResp.More_Delivery_Information__c) && !nresp.Request_Hold_Case__c) { // to mandate drop down selectiions on DDS
                nResp.More_Delivery_Information__c.addError(DROP_DOWN_ERROR );
                hasError = true;
            } else {
                if((!SSSWConstants.DISPUTED_DELIVERY.equalsIgnoreCase(relatedCse.EnquirySubType__c) && 
                                        !relatedCse.Status.contains(SSSWConstants.CLOSE_CONTAINSCHECK)) ||
                                        ( !String.isBlank(relatedCse.Primary_Email__c) &&
                                        relatedCse.Primary_Email__c.equalsIgnoreCase(relatedCse.Contact.Email) || 
                                        SENDER.equalsIgnoreCase(relatedCse.CaseOriginator__c)) ||  
                                        (!String.isblank(nResp.More_Delivery_Information__c) && nResp.More_Delivery_Information__c.contains('*'))
                                        ) {  // for all * marked Delivery informations to be sent back to CCC for DDS or if non-DDS or sender is the originator of case
                    nResp.Send_Case_To_Customer_Service__c = true;
                }
                
                if(!nResp.Send_Case_To_Customer_Service__c && !nresp.Request_Hold_Case__c  && 
                            !relatedCse.Status.contains(SSSWConstants.CLOSE_CONTAINSCHECK)) { //if not closed or not to be sent to CCC then check for valid automation selections
                    String caseCond = nresp.Address_type__c + nresp.Delivery_officer_knowledge__c+nresp.More_Delivery_Information__c;  
                    String CaseProductCategory = relatedCse.productCategory__c;
                                    system.debug('Caseproductcategory' +CaseProductCategory);

                    system.debug(caseCond);
                     
                //loop through the custom setting for getting template against each selections only for product category 
                            
                 for(PON_Update_EmailTemplates__c mp: ponCS){
                       //check if case condition matches the custom setting value
                    if(relatedCse.ResolutionCode__c!='MyNetwork Resolution'){
                        if(caseCond.equalsIgnoreCase(mp.CaseCondition__c)) {
                            templateName = mp.Template_API_Name__c;
                            system.debug(templateName);
                            doNotShowEmail = false;
                        }
                     }   
                 }
                            
                    if(!String.isBlank(templateName)) { // if valid template exists, continue for automation email
                        // retreival of the valid template
                        template  = [Select Id, Body,HTMLValue, Subject from EmailTemplate where DeveloperName = :templateName limit 1];
                        templateId = template.id;
                        
                        // creating the template body for body of the email using HTML version
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
                        templateBody = templateBody.replace('[Location]',nresp.More_Delivery_Information__c);                            
                        String thread = makeThreadId();
                         system.debug('---'+thread);
                         templateBody = templateBody.replace('{!Case.Thread_Id}',thread) ;
                         
                        // creating the template body for display on response screen for network users to review using string version
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
                        templateBody2 = templateBody2.replace('[Location]',nresp.More_Delivery_Information__c);                                         
                        templateBody2 = templateBody2.replace('{!Case.Thread_Id}',thread) ;                                        
                                        
                    }
                    else {  // if no valid template found then send back to CCC
                        nResp.Send_Case_To_Customer_Service__c = true; 
                    }
                }
                
                // send back to CCC if case on hold or further CCC action required on the case
                if((nResp.Send_Case_To_Customer_Service__c || nresp.Request_Hold_Case__c ||  
                                        relatedCse.Status.contains(SSSWConstants.CLOSE_CONTAINSCHECK)) && !nresp.to_CCC_action__c) { 
                    updateRespoTemp();
                }
            }
        }

        //DML Exception handling - INC1214840
        catch(DmlException e) {
                //log exceptions
                hasError = true;
                nResp.More_Delivery_Information__c.addError('An unexpected error has occurred: ' + e.getMessage());
                System.debug('An unexpected error has occurred: ' + e.getMessage());
                UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                            SSSW_PON_UpdateController.class.getName(), 'showEmailTemplate', '', LoggingLevel.ERROR);

            }
        
        catch(Exception exp) {
            //log exceptions
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                            SSSW_PON_UpdateController.class.getName(), 'showEmailTemplate', '', LoggingLevel.ERROR);
        }  
    }

    /**
     * Creates the Thread ID which is created when sending an email
     *
     * @return the Thread ID
     */
   @TestVisible  private String makeThreadId() {
        String orgId = UserInfo.getOrganizationId().left(15);
        String caseId = String.valueOf(relatedCse.Id).left(15);

        return ' ref:_'
                + orgId.left(5)
                + orgId.right(10).replaceAll('0', '')
                + '._'
                + caseId.left(5)
                + caseId.right(10).left(5).replaceAll('0', '')
                + caseId.right(5)
                + ':ref ';
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
            String newStatus = [Select id, Status, IsHLC__c,IsCR__c from Case where id = :cseId limit 1].Status;
            system.debug(newStatus);
            system.debug(prevStatus);
            
            // below action if status has not changed on case 
            if(prevStatus.equalsIgnoreCase(newStatus)) {
                //nresp.id = null; // HANS : make the id allways null as we create a new record whnever the Network user make an update to the response
                if(nresp.Request_Hold_Case__c) {
                    nResp.CaseAction__c = 'On Hold'; //case action decides in trigger whom the case is sent to 
                    //Updating 'Message to network' from the case description field as per REQ1760281        
                    nResp.Message_to_Networks__c = relatedCse.Description;
                    database.insert(nresp);
                } else if(relatedCse.Status.contains(SSSWConstants.CLOSE_CONTAINSCHECK)) { // for closed cases
                    nresp.id = null;
                    nResp.CaseAction__c = relatedCse.Status;
                    //root cause(value = network responded) helps identify if the network user has responded to the case - later used for update case scenario 
                    nResp.R_Root_cause__c = String.isBlank(nResp.R_Root_cause__c) ? SSSWConstants.NETWORK_RESP_STATUSSET : nResp.R_Root_cause__c;
                    nResp.Message_to_Networks__c = relatedCse.Description;
                    //Updating 'Message to network' from the case description field as per REQ1760281        
                    nResp.Message_to_Networks__c = relatedCse.Description;
                    database.insert(nresp);
                } else {
                    //check if contact has email always and send email for automation, else route to CCC
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
                    } else {//else route to CCC
                        nResp.Send_Case_To_Customer_Service__c = true;
                    }
                    if(!nResp.Send_Case_To_Customer_Service__c) { //for routing to CCC
                        nResp.CaseAction__c = SSSWConstants.CLOSE_CONTAINSCHECK;
                        //03-Apr-17 Eric Shen   add this new flag to indicate if the case is closed by Mynetwork users via network response
                         nResp.isClosedByNetwork__c = true; 
                    } else { // for Non-DDS cases to be Network Responded
                         nResp.CaseAction__c = SSSWConstants.NETWORK_RESP_STATUSSET;
                    }
                    nresp.Id = null;
                    nresp.RelatedCase__c = cseId;
                    //root cause(value = network responded) helps identify if the network user has responded to the case - later used for update case scenario
                    nResp.R_Root_cause__c =  String.isBlank(nResp.R_Root_cause__c) ? SSSWConstants.NETWORK_RESP_STATUSSET : nResp.R_Root_cause__c;
                    //Updating 'Message to network' from the case description field as per REQ1760281        
                    nResp.Message_to_Networks__c = relatedCse.Description;
                    database.insert(nresp);
                } 
            }  else { 
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
      * @name: contactAnotherNetwork
      * @desciption: new method to make necessary backend workflows run when case is sent to another network.
      * @param: NA
      * @return: NA
      *
      */
     public void contactAnotherNetwork() {
         Savepoint sp;
         try {
            sp = Database.setSavepoint();
            //set network response details for re-assignment
            nresp.Request_Hold_Case__c = false;
            nresp.CaseAction__c= 'None'; 
            nresp.Id = null;
            nresp.RelatedCase__c = cseId;
            nResp.R_Root_cause__c =  String.isBlank(nResp.R_Root_cause__c) ? SSSWConstants.NETWORK_RESP_STATUSSET : nResp.R_Root_cause__c;
            //Updating 'Message to network' from the case description field as per REQ1760281        
            nResp.Message_to_Networks__c = relatedCse.Description;
             database.insert(nresp);
                 
             reassignRefresh = true;  
            //to identify the contact method for the new re-assigned network
             String contMtd = [Select Id, Contact_Facility__c from Network__c where Id=:nResp.to_Reassign_Network__c  limit 1].Contact_Facility__c ;
             system.debug(contMtd);
             // check if contact should be auto escalated
              setContactRequiresEscalation();
             if('Email'.equalsIgnoreCase(contMtd)) { // for email contact method
             system.debug('here');
                 contactViaEmail(nresp.network_comments__c,nResp.to_Reassign_Network__c,relatedCse.Id,false,contactRequiresEscalation,relatedCse.EscalationEmail__c);
             } else if('Fax'.equalsIgnoreCase(contMtd)) { // for fax contact method
                 contactViaFax(nResp.to_Reassign_Network__c, relatedCse.Id, nresp.network_comments__c, false);    
             } else if('MyNetwork'.equalsIgnoreCase(contMtd)) { // for MyNetwork contact method
                 relatedCse.Network__c = nResp.to_Reassign_Network__c;
                 relatedCse.Status = relatedCse.Type !='Feedback'  ? 'Awaiting Network Response' : relatedCse.Status ;
                 relatedCse.Checkbox__c = false;
                 database.update(relatedCse);
                 //for myNetwork contact - if escalation needed, we need to send email to teir 1
                 if(contactRequiresEscalation) contactViaEmail(nresp.network_comments__c,nResp.to_Reassign_Network__c,relatedCse.Id,false,contactRequiresEscalation,relatedCse.EscalationEmail__c);
             }
         }
         catch (Exception exp) {
             Database.rollback(sp);
             // Error Logged to Exception object for analysis
              UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                                  'SSSW_MyNetworkResponsePageContr', 'contactanothernetwork',
                                  null, LoggingLevel.ERROR);
         }    
     }
     
     /** 
      * @name: setContactRequiresEscalation
      * @desciption: for identifying if the case requires escalation
      * @param: NA
      * @return: NA
      *
      */
    private void setContactRequiresEscalation() {
        contactRequiresEscalation = SSSW_Routing.checkAutoEscalate(relatedCse);
        System.Debug('--' + contactRequiresEscalation);
    }


     /** 
      * @name: acknowledge
      * @desciption: new method to allow users to acknowledge case updates by non- mynetwork users with no action 
      * @param: NA
      * @return: NA
      *
      */
     public void acknowledge(){  
         hasError = false;
         //if network comments is entered promt user to do acknowledge And Save and capture response
         if(!String.isBlank(nResp.Network_Comments__c)) {
                nResp.Network_Comments__c.addError('Click “Acknowledge and Respond” button if you need to enter network comments.');
                hasError = true;
        }  else { 
             relatedCse.Root_cause__c =  String.isBlank(nResp.R_Root_cause__c) ? SSSWConstants.NETWORK_RESP_STATUSSET : nResp.R_Root_cause__c;
             database.update(relatedCse);
        }
     }
     
     /** 
      * @name: acknowledgeAndSave
      * @desciption: new method to allow users to acknowledge case updates with option to respond back 
      * @param: NA
      * @return: NA
      *
      */
      public void acknowledgeAndSave(){ 
          hasError = false;
        if(String.isBlank(nResp.Network_Comments__c)) { //mandate network respose
            nResp.Network_Comments__c.addError(NW_COMM_ERROR);  
            hasError = true;
        } else { //capture response and update case to network responded using case action        
             nResp.R_Root_cause__c = SSSWConstants.NETWORK_RESP_STATUSSET;
             nResp.Request_Hold_Case__c = false;
             //Updating 'Message to network' from the case description field as per REQ1760281        
             nResp.Message_to_Networks__c = relatedCse.Description;
            database.insert(nResp);
             relatedCse.Root_cause__c =  SSSWConstants.NETWORK_RESP_STATUSSET;
             database.update(relatedCse);
        }
     }

    /** 
      * @name: goBack
      * @desciption: method to allow users to change the response selections and navigate between response and email template screen
      * @param: NA
      * @return: NA
      *
      */
    public   void goBack() {
        //reset the template visibilibity variables and render the response screen
        templateId = SSSWConstants.EMPTY_SPACE;
        template = new EmailTemplate();
        doNotShowEmail = true;
        showCaseDetails = false;
    }

    /** 
      * @name: casePrint
      * @desciption: method to allow users to print case
      * @param: NA
      * @return: pageReference 
      *
      */
    public pageReference casePrint() {
        // redirect to case print page
        return new PageReference('/PON_Case_Detail_View?Id='+relatedCse.Id);
     } 
     
     /** 
      * @name: contactViaEmail
      * @desciption: new method to change the network to an email contact method based network and re-set all milestone clocks 
      * @param: string comment, string facilityID, string caseID, boolean preventStatusChange, boolean contactRequiresEscalation, string escalationEmail
      * @return: String
      *
      */
    @TestVisible private string contactViaEmail(string comment, string facilityID, string caseID, boolean preventStatusChange, boolean contactRequiresEscalation, string escalationEmail) {
        // check the network's email address
        Network__c aNetwork;
        for (Network__c ntw : [select Email__c,Email_1__c, name from network__c where id = :facilityID limit 1]) {
            aNetwork = ntw;
            escalationEmail = ntw.Email_1__c;
        }
        // if null return error
        if (aNetwork == null) {  return 'Error : no network find.'; }
        
        //based on escalation requirement - set the email address 
        string toEmailAdd = contactRequiresEscalation ? escalationEmail : aNetwork.Email__c;
        if (String.isEmpty(toEmailAdd)) { return 'Error : The Network has no Email address.'; }

        system.debug('--'+toEmailAdd);
        Case aCase = [select IsHLC__c,IsCR__c,Updated_Case_Comments__c,Account.ServiceSLA__c,Resolution_Result__c,EnquirySubType__c,ContactId,Network__r.Email__c,Type,Status,OwnerId, EscalationEmail__c from Case where id = :caseID];
        system.debug('FacilitySearch > contactViaEmail aCase.OwnerId:' + aCase.OwnerId);
        system.debug('>>>>>>>>>>>>>>>> preventStatusChange:' + preventStatusChange);
        if (aCase.Type == 'Feedback' && String.isBlank(aCase.Resolution_Result__c) && 'Enterprise' == String.valueOf(aCase.Account.ServiceSLA__c)) {
            //  result = 'Error: Please enter Resolution Code to proceed';
            return 'Error: Please enter Resolution Result to proceed';
        }
        //if we want to have a case status change on contacting another network as the type of contact method is different
        if (!preventStatusChange) {
            aCase.Network__c = facilityID;
            id ownerId = null;
            List<Group> groups = [select id from Group where developerName = 'SSSWNetworkQueue'];
            if (groups.size() > 0) {
                ownerId = groups[0].id;
            }

            if (ownerId != null && (!aCase.IsHLC__c && !aCase.IsCR__c)) {   // condition to bypass owner change for HLC & CR cases : Nandan N : 24/06/2015
                aCase.Ownerid = ownerId;
            }

            if (aCase.Type == 'Feedback') {
                if (string.isBlank(aCase.ResolutionCode__c)) {
                    aCase.ResolutionCode__c = 'Feedback (Issue captured and logged)';
                }
                aCase.Status = 'Closed';
            } else {
                aCase.Status = 'Awaiting Network Response';
            }
        }

        //to get the email template as contact method is email
        String GENERAL_TEMPLATE = 'SSSW_Case_GeneralTemplate';
        EmailTemplate emailTemplate;

        String templateName = 'SSSW Case ' + aCase.EnquirySubType__c;
        List<EmailTemplate> tempList = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE Name = :templateName OR DeveloperName = :GENERAL_TEMPLATE];
        if (tempList.size() > 1) {
            for (EmailTemplate et : tempList) {
                if (et.DeveloperName != GENERAL_TEMPLATE) {
                    emailTemplate = et;
                }
            }
        } else if (tempList.size() == 1) {
            emailTemplate = tempList[0];
        }

        Contact ct;
        // If Case contact is blank - we need to ensure the Email Template can be rendered. SSSW Contact used.
        List<Contact> contList = [select id, email,IsPersonAccount, FirstName, LastName, accountid, account.personEmail from contact where id = :aCase.contactId OR (FirstName = 'SSSW' AND LastName = 'Entitlements')];
        if (contList.size() > 1) {
            for (Contact c : contList) {
                if (!(c.FirstName == 'SSSW' && c.LastName == 'Entitlements')) {
                    ct = c;
                }
            }
        } else if (contList.size() == 1) { ct = contList[0]; }
        
        aCase.Root_cause__c = 'Awaiting Network Response';
        aCase.Checkbox__c = false;
        update aCase;

        //generating and sending email
        string emailContent = '';
        string subject = '';
        Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
        string message = generateEmail(sem, new String[]{
            toEmailAdd
        }, ct, emailTemplate.Id, aCase.id);
        if (message.startsWith('Error:')) { return message;
        } else {
            emailContent = sem.getHtmlBody().normalizeSpace().replace(UNKNOWN_EMAIL, '');
            subject = sem.getSubject();
            sendAnEmail(aCase.id, facilityID, emailContent, toEmailAdd, aNetwork.Name, subject, ct.Id);
            // 04.28.17 - Angelo P. Rivera - Added contactID parameter that will be passed to sendSingleMail method as the subscriberID
        }

        system.debug('>>>>>>>>>>>>>>>>> emailContent:' + emailContent.length());
        aCase.EscalationEmail__c = trimContent(emailContent, Schema.SObjectType.Case.fields.EscalationEmail__c.getLength());
        update aCase;
        if (ct != null) {
            if (ct.IsPersonAccount) {
                if (ct.Account.personEmail == UNKNOWN_EMAIL) {
                    ct.Account.personEmail = '';
                    update ct.Account;
                }
            } else if (ct.email == UNKNOWN_EMAIL) {
                ct.email = '';
                update ct;
            }
        }

        return aCase.id;
    }


    /** 
      * @name: generateEmail
      * @desciption: new method to generate email based on values passes
      * @param: Messaging.SingleEmailMessage sem, String[] toAddresses, Contact ct, id emailTemplateId, id whatId
      * @return: String
      *
      */
    private string generateEmail(Messaging.SingleEmailMessage sem, String[] toAddresses, Contact ct, id emailTemplateId, id whatId) {
        string result = '';
        //set the messaging parameters for email
        sem.setTargetObjectId(ct.id);
        sem.setWhatId(whatId);
        sem.setTemplateId(emailTemplateId);
        sem.setToAddresses(toAddresses);

        Savepoint sp = Database.setSavepoint();
        try {
            system.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ct.email: ' + ct.email);
            if (string.isBlank(ct.email)) { // set the email address for sends
                ct.email = UNKNOWN_EMAIL;
                update ct;
            }
            //send the final email message
            Messaging.sendEmail(new Messaging.Email[]{
                sem
            });
        } catch (Exception ex) {
            result = 'Error: ' + ex.getMessage();
        } finally {
            Database.rollback(sp);
        }
        return result;
    }


    /** 
      * @name: sendAnEmail
      * @desciption: to send email in future context for avoiding mixed DML
      * @param: string caseID, string facilityID, string emailContent, string toAddress, string toName, string subject, string contactId
      * @return: NA
      *
      */
    @future(callout=true) //HANS : making the send email future to allow DMLs after the callout in the transactipn
    @TestVisible private static void sendAnEmail(string caseID, string facilityID, string emailContent, string toAddress, string toName, string subject, string contactId) {
        //get network email from custom setting
        QM__c qm = [Select NetworkEmail__c From QM__c limit 1];

        if (!isTest) {
            // added noreply@auspost.com.au as the subscriberID value
            ExactTargetEmail.ExactTargetSentResult sendResult = new ExacttargetEmail().sendSingleMail(qm.NetworkEmail__c, 'Customer Enquiry', toAddress, toName, emailContent, subject, contactId);
            // 04.28.17 - Angelo P. Rivera - Added contactID parameter that will be passed to sendSingleMail method as the subscriberID
            List<EmailMessage> list_emailMessages = new List<EmailMessage>();
            list_emailMessages.add(new EmailMessage(subject = subject, HtmlBody = emailContent, ParentId = caseID, 
                                        FromAddress = qm.NetworkEmail__c, FromName = 'Customer Enquiry', ToAddress = toaddress, MessageDate = datetime.now()));

            if (sendResult.isSuccessful) { insert list_emailMessages; }
            else {
                ExactTargetBacklog__c c = new ExactTargetBacklog__c();
                c.EmailContentJSON__c = sendResult.requestBody;
                c.ErrorMessage__c = sendResult.message;
                c.IsBatchEmail__c = sendResult.IsBatchEmail;
                c.EmailMessageObjectsJSON__c = JSON.serialize(list_emailMessages);
                insert c;
            }
        }
    }


    /** 
      * @name: contactViaFax
      * @desciption: New method to change the network to an fax contact method based network and re-set all clocks 
      * @param: string comment, string facilityID, string caseID, boolean preventStatusChange, boolean contactRequiresEscalation, string escalationEmail
      * @return: String
      *
      */
    @TestVisible private  String contactViaFax(string facilityID, string caseID, string comment, boolean preventStatusChange) {
        Case aCase = [select IsHLC__c,IsCR__c,Updated_Case_Comments__c,Account.ServiceSLA__c,Resolution_Result__c,
                                ResolutionCode__c,type, EscalationEmail__c, contactId from Case where id = :caseID];
        //for feedback cases check if resolution code is entered
        if (aCase.Type == 'Feedback' && String.isBlank(aCase.Resolution_Result__c) && 'Enterprise' == String.valueOf(aCase.Account.ServiceSLA__c)) {
            return 'Error: Please enter Resolution Result to proceed';
        }
        // query the new network for fax number
        network__c f = [
            select name, Fax_Number__c
            from network__c
            where id = :facilityID
        ];
        
        //setup fax for sendig
        RecordType rt = [select id from RecordType where DeveloperName = 'outbound' and sobjecttype = 'Fax__c'];
        Fax__c aFax = new Fax__c();
        String tempNumber = f.fax_number__c;
        system.debug('Original Fax:' + tempNumber);
        if (!String.isBlank(f.fax_number__c)) {
            tempNumber = tempNumber.replaceAll('[^0-9+]', '');
            if (tempNumber.startsWith('0')) {
                tempNumber = tempNumber.substring(1);
            }
            aFax.emailto__c = tempNumber + '@fax2mail.com';
        } else {
            aFax.emailto__c = '211119999@fax2mail.com';
        }
        system.debug('Cleaned Fax:' + tempNumber);

        aFax.to__c = tempNumber;
        aFax.from__c = userinfo.getUserName();
        aFax.subject__c = 'Fax to Network: ' + f.name;
        aFax.case__c = caseID;
        aFax.recordtypeid = rt.id;
        aFax.name = 'Fax - ' + datetime.now().format('dd-MM-yyyy hh:mm:ss a');

        //Assign Case to Network and move to Network Queue
        if (!preventStatusChange) {
            id ownerId = null;
            List<Group> groups = [select id from Group where developerName = 'SSSWNetworkQueue'];
            if (groups.size() > 0) {
                ownerId = groups[0].id;
            }

            if (ownerId != null && (!aCase.IsHLC__c && !aCase.IsCR__c)) {
                aCase.OwnerId = ownerId;
            }

            aCase.Network__c = facilityId.trim();
            if (aCase.Type == 'Feedback') {
                if (string.isBlank(aCase.ResolutionCode__c)) {
                    aCase.ResolutionCode__c = 'Feedback (Issue captured and logged)';
                }
                aCase.Status = 'Closed';
            } else {
                aCase.Status = 'Awaiting Network Response';

            }
            CaseMileStoneUtil.dontUpdateMilestone = true;
        }
        aCase.Root_cause__c = 'Awaiting Network Response';
        aCase.Checkbox__c = false;
        update aCase;

        insert aFax;
        system.debug('Fax Created:' + aFax.id);

        List<Fax__c> tempfax = new List<Fax__c>();
        tempfax.add(aFax);

        return aFax.Id;
    }  
    public static string trimContent(String content, integer length) {
		if(content.length() > length) {
			content = content.substring(0,length);
		}
		return content;
	}


}