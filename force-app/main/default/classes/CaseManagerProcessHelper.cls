/**
* @author       : 
* @date         : 
* @description  : helper class for case manager allocation flow
*/
/*******************************  History ************************************************
23/01/2016  kalpita.talwadekar@auspost.com.au   Created
            snigdha.sahu@auspost.com.au         Updated
03/03/2019  disha.kariya@auspost.com.au         Updated    Added Workforce Verification to set Product Type on Deal Enablement Case creation.
09/05/2019  vera.octavia@auspost.com.au         Updated    Reverted NEWACC_WRKTYPE to the prev. value and added new product type
29/01/2020  seth.p.heang@accenture.com          Updated    Include Product Type and Product Group check and assignment for 'Local Pickup and Delivery Services' Product
13/10/2020  seth.p.heang@accenture.com          Decommissioned    This class and the flow 'CaseManagerAllocationFlow' which calls this class,
																  the entire functionality of 'Deal Enablement Centre' Case implementation is decommissioned 
																  and to be replaced with a new DSR implementation with 'Deal Enablement Centre' record type
*******************************  History ************************************************/
global class CaseManagerProcessHelper implements Process.Plugin {

    /*private static final String IDCASE = 'Id';
    private static final String CASE_SOBJ = 'Case';
    private static final String CLOSED_DATE = 'ClosedDate';
    private static final String CREATED_DATE = 'CreatedDate';
    private static final String CREATED_BY_ID = 'CreatedById';
    private static final String LAST_MOD_DATE = 'LastModifiedDate';
    private static final String LAST_MOD_ID = 'LastModifiedById';
    private static final String COMMA_SEP = ',';
    private static final String SEMICOLON = ';';
    private static final String IS_INSERT = 'isInsert';
    private static final String EPARCEL_STD = 'eparcelStandard';
    private static final String NEW_CASH_ACC = 'newCashAccount';
    private static final String NEW_CHARGE_ACC = 'newChargeAccount';
    private static final String NEW_SUB_ACC = 'newSubAccount';
    private static final String NEW_STATUS = 'New';
    private static final String OP_PARAM = 'newCaseId';
    private static final String APT_STATUS = 'SFDC Case Created';
    private static final String ON_BOARDING = 'Contract Management On-Boarding team';
    private static final String CREDIT_MGMT = 'Credit Management';
    private static final String BSI_TEAM = 'Business Systems Integration';
    private static final String CONTR_PROCESSING_TEAM = 'Contract Management Processing Team';
    private static final String CDM = 'Data Quality Management';
    private static final String EPARCEL_WRKTYPE = 'New Contract'; //'New eParcel Standard';
    private static final String NEWACC_WRKTYPE =  'New Account'; //'Billing Account/Sub Account Entry';
    private static final String NEWCHRG_WRKTYPE = 'New Charge Account';
    private static final String NEWSUBACC_WRKTYPE = 'New Sub-Account';
    private static final String DOV_WRKTYPE = 'Addendum/DOV';
    private static final String DEAL_PROCESSING = 'Deal Processing';
    private static final String Deal_Enablement_Centre = 'Deal Enablement Centre';
    private static final String WORKFORCE_VERIFICATION = 'Workforce Verification';
    private static final String COURIER = 'Courier';
    private static final String LOCAL_PICKUP_DELIVERY_SERVICE = 'Local Pickup and Delivery Services';
    private static final String DECIPHA = 'Decipha';
    private static final String STARTRACK = 'StarTrack';
    private static final String ON_DEMAND = 'On Demand';
    */


    /**
    @description  method invoked from the flow to send inpiut params and perform allocation accordinly.
    @param    Process.PluginRequest request
    @return   Process.PluginResult
    @throws NA
    */
    global Process.PluginResult invoke(Process.PluginRequest request) {
        System.debug('***Inside Helper***');
        Map<String,Object> result = new Map<String,Object>();
        /*try {
            Boolean triggerFileTransfer= false;

            String caseId = (String) request.inputParameters.get(IDCASE);
            String selects = '';

            // Get a map of field name and field token
            Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(CASE_SOBJ.toLowerCase()).getDescribe().Fields.getMap();
            list<string> selectFields = new list<string>();
            //for case fields creating dynamic query to include all fields for cloning.
            if (fMap != null){
                for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                    Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                    if (fd.isCreateable()){ // field is creatable
                        if(!CLOSED_DATE.equalsIgnoreCase(fd.getName()) || CREATED_DATE.equalsIgnoreCase(fd.getName()) ||
                                CREATED_BY_ID.equalsIgnoreCase(fd.getName()) || LAST_MOD_DATE.equalsIgnoreCase(fd.getName()) ||
                                LAST_MOD_ID.equalsIgnoreCase(fd.getName()))
                            selectFields.add(fd.getName());
                    }
                }
            }

            if (!selectFields.isEmpty()){
                for (string s:selectFields){
                    selects += s + COMMA_SEP;
                }
                if (selects.endsWith(COMMA_SEP)){selects = selects.substring(0,selects.lastIndexOf(COMMA_SEP));}

            }
            //create final query
            System.debug('--> selects --> '+selects);
            String query = 'SELECT Id, Parent.Status ,CaseNumber, ' + selects + ' FROM ' + 'case ' + ' WHERE ' + 'Id = :caseId';

            Case oldCase = (Case)Database.query(query);

            System.debug ( ' Old Case values = ' + oldCase);


            Case newCase = new Case();
            Map<String,String> attchMap = new Map<String,String>();
            List<Attachment> attlist = new List<Attachment>();
            List<caseComment> caseCommentList= new List<caseComment>();
            //Snigdha : Added to fix QC1699, QC1732
            List<caseTeamMember> caseTeamMemberList = new List <caseTeamMember>();
            String ProdGroup = oldCase.APT_Product_Group__c;
            String Prodtype = '';
            String MapProdType = '';

            if(!(Boolean) request.inputParameters.get(IS_INSERT)) {
                System.debug('***Inside Not(Insert)1***');
                newCase = oldCase.clone(false,true);
                newCase.parentId = caseId;
                newCase.status = NEW_STATUS ;


                triggerFileTransfer= (Boolean) request.inputParameters.get(EPARCEL_STD) ? false :
                        (Boolean) request.inputParameters.get(NEW_CASH_ACC) ? false  :
                                (Boolean) request.inputParameters.get(NEW_CHARGE_ACC) ? false  :
                                        (Boolean) request.inputParameters.get(NEW_SUB_ACC) ? false  : true;

                //grab if any notes and attachments on old case and duplicate them to the child case
                for(Attachment att : [select id, name, body from Attachment where ParentId = :oldcase.Id]) {
                    attList.add(att);
                }

                //Duplicate case comments into the new Case
                for(caseComment oldcaseComment: [Select Id, Parentid, CommentBody, IsPublished, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById from CaseComment where ParentId = :oldcase.Id]) {
                    caseCommentList.add(oldcaseComment);
                }


                //Snigdha : Duplicate case team members into the new Case
                for(caseTeamMember oldcaseTeamMember: [Select Id, Parentid, MemberId, TeamRoleId from caseTeamMember where ParentId = :oldcase.Id]) {
                    caseTeamMemberList.add(oldcaseTeamMember);
                }
            }
            else {
                //on insert
                newCase = oldCase;
                newCase.Origin = 'Salesforce';
                newCase.Subject = (Boolean) request.inputParameters.get(EPARCEL_STD) ? 'Contract Provisioning':
                        (Boolean) request.inputParameters.get(NEW_CASH_ACC) ?  'New Account'  :
                                (Boolean) request.inputParameters.get(NEW_CHARGE_ACC) ? NEWCHRG_WRKTYPE  :
                                        (Boolean) request.inputParameters.get(NEW_SUB_ACC) ? NEWSUBACC_WRKTYPE  : 'Contract Provisioning' ;
                newCase.Subject += '  Requested' ;
            }
            //create map of queue name and id
            Map<String, Id> queueNameMap = new map<String,Id>();
            for(Group grp: [Select Id, Name from Group where type = 'Queue']) {
                queueNameMap.put(grp.Name,grp.Id);
                system.debug(grp.Name);
            }

            //Snigdha : Add the Requestor to be the Contract Owner
            if (oldCase.APT_Contract_Owner__c != null)
                newCase.Requestor__c = oldCase.APT_Contract_Owner__c;
            //Snigdha: Update the Product Type
            system.debug ('ProdGroup before if ' + ProdGroup );
            if (oldCase.APT_Product_Group__c != null && !string.isBlank(oldCase.APT_Product_Group__c)) {
                Prodtype  = ProdGroup.substring(0,ProdGroup.IndexOf(SEMICOLON));
                if (Prodtype == 'Parcel')
                    MapProdType = 'Parcel';
                else if (Prodtype == 'International Postal')
                    MapProdType = 'International';
                else if (Prodtype == 'Unaddressed Mail')
                    MapProdType = 'UMS';
                else if (Prodtype == 'Print Post')
                    MapProdType = 'PrintPost';
                else if (WORKFORCE_VERIFICATION.equalsIgnoreCase(Prodtype))
                    MapProdType = WORKFORCE_VERIFICATION;
                else if (COURIER.equalsIgnoreCase(Prodtype))
                    MapProdType = COURIER;
                else if (LOCAL_PICKUP_DELIVERY_SERVICE.equalsIgnoreCase(Prodtype))
                    MapProdType = LOCAL_PICKUP_DELIVERY_SERVICE;
                else if (DECIPHA.equalsIgnoreCase(Prodtype))
                    MapProdType = DECIPHA;
                else if (STARTRACK.equalsIgnoreCase(Prodtype))
                    MapProdType = STARTRACK;
                else if (ON_DEMAND.equalsIgnoreCase(Prodtype))
                    MapProdType = ON_DEMAND;
            }
            System.debug('oldCase.APT_Product_Group__c--->'+oldCase.APT_Product_Group__c);
            System.debug('MapProdType--->'+MapProdType);
            //Id Workforce veirfication is in ProductGroup set Product type to Workforce verification else perform existing logic.
            if(WORKFORCE_VERIFICATION.equalsIgnoreCase(MapProdType)){
                newCase.Product_Type__c = WORKFORCE_VERIFICATION;
            //Added new ProductType
            }else if(COURIER.equalsIgnoreCase(MapProdType)){
                newCase.Product_Type__c= COURIER;
            }else if(LOCAL_PICKUP_DELIVERY_SERVICE.equalsIgnoreCase(MapProdType)){
                newCase.Product_Type__c= LOCAL_PICKUP_DELIVERY_SERVICE;
            }else if(DECIPHA.equalsIgnoreCase(MapProdType)){
                newCase.Product_Type__c= DECIPHA;
            }else if(STARTRACK.equalsIgnoreCase(MapProdType)){
                newCase.Product_Type__c= STARTRACK;
            }else if(ON_DEMAND.equalsIgnoreCase(MapProdType)){
                newCase.Product_Type__c= ON_DEMAND;                
            }
            else{ //existing logic to set Product Type
                newCase.Product_Type__c = (Boolean) request.inputParameters.get(EPARCEL_STD) ? 'Eparcel'  : MapProdType ;
            }
            System.debug('newCase.Product_Type__c--->'+newCase.Product_Type__c);
            system.debug('--> Eparcel STD--> '+(Boolean) request.inputParameters.get(EPARCEL_STD));
            system.debug('--> New Cash--> '+(Boolean) request.inputParameters.get(NEW_CASH_ACC));
            system.debug('--> New Charge--> '+(Boolean) request.inputParameters.get(NEW_CHARGE_ACC));
            system.debug('--> New Sub--> '+(Boolean) request.inputParameters.get(NEW_SUB_ACC));

            //update case owner based on work type update
            //SV: 16/3/2017
            //Updated the first condition to assign ownerid to the Queue - Contract Management Enquiry instead of Contract Management On-boarding Team
            newCase.ownerId =(Boolean) request.inputParameters.get(EPARCEL_STD) ? queueNameMap.get(Deal_Enablement_Centre) :
                    (Boolean) request.inputParameters.get(NEW_CASH_ACC) ? queueNameMap.get(Deal_Enablement_Centre) :
                            (Boolean) request.inputParameters.get(NEW_CHARGE_ACC) ? queueNameMap.get(CREDIT_MGMT ) :
                                    (Boolean) request.inputParameters.get(NEW_SUB_ACC) ? queueNameMap.get(BSI_TEAM) :
                                            queueNameMap.get(Deal_Enablement_Centre);

            //update record type based on work type
            newCase.recordTypeId = (Boolean) request.inputParameters.get(EPARCEL_STD) ? Schema.SObjectType.Case.getRecordTypeInfosByName().get(Deal_Enablement_Centre).getRecordTypeId() :
                    (Boolean) request.inputParameters.get(NEW_CASH_ACC) ?  Schema.SObjectType.Case.getRecordTypeInfosByName().get(Deal_Enablement_Centre).getRecordTypeId()  :
                            (Boolean) request.inputParameters.get(NEW_CHARGE_ACC) ? Schema.SObjectType.Case.getRecordTypeInfosByName().get(CREDIT_MGMT ).getRecordTypeId() :
                                    (Boolean) request.inputParameters.get(NEW_SUB_ACC) ? Schema.SObjectType.Case.getRecordTypeInfosByName().get(BSI_TEAM).getRecordTypeId() :
                                            Schema.SObjectType.Case.getRecordTypeInfosByName().get(Deal_Enablement_Centre).getRecordTypeId();

            //update work type
            //SV 31/03/2017 : Replaced the final else assignment from oldCase.APT_New_Contract__c to oldCase.Work_Type__c for the defect 1707
            newCase.Work_Type__c = (Boolean) request.inputParameters.get(EPARCEL_STD) ? EPARCEL_WRKTYPE  :
                    (Boolean) request.inputParameters.get(NEW_CASH_ACC) ?  NEWACC_WRKTYPE  :
                            (Boolean) request.inputParameters.get(NEW_CHARGE_ACC) ? NEWCHRG_WRKTYPE  :
                                    (Boolean) request.inputParameters.get(NEW_SUB_ACC) ? NEWSUBACC_WRKTYPE  : oldCase.APT_New_Contract__c ;


            newCase.Support_Work_Type__c = DEAL_PROCESSING ;

            //upsert case
            system.debug(newCase+'--'+newCase.Id+'----');
            system.debug('boolean'+ (Boolean) request.inputParameters.get(IS_INSERT));

            if(!(Boolean) request.inputParameters.get(IS_INSERT)) {
                System.debug('***Inside Not(Insert)2***');
                //system.debug (' IS_INSERT - False');
                database.insert(newCase);
                Attachment[] insertAttList = new Attachment[]{};
                caseComment[] insertcommentList = new caseComment[]{};
                CaseTeamMember[] insertCaseTeamList = new caseTeamMember[]{};

                for(Attachment a: attList)  {
                    Attachment att = new Attachment(name = a.name, body = a.body, parentid = newCase.id);
                    insertAttList.add(att);
                }
                //insert old case comments into the new case
                for(caseComment c: caseCommentList)  {
                    caseComment newCaseComment = new caseComment(CommentBody= c.CommentBody, Parentid= newCase.id,
                            IsPublished= c.IsPublished, CreatedDate = c.CreatedDate,
                            CreatedById = c.CreatedById, LastModifiedDate = c.LastModifiedDate, LastModifiedById = c.LastModifiedById);
                    insertcommentList.add(newCaseComment);
                }

                //insert old case team member into the new case ad exlude the team member if already exists
                Id newCaseContractOwn = [Select APT_Contract_Owner__c FROM Case WHERE Id =: newCase.Id LIMIT 1].APT_Contract_Owner__c;
                Integer countCTM = [Select Count() from CaseTeamMember where ParentId =: newCase.Id AND MemberId =: newCaseContractOwn];
                for(caseTeamMember ctm: caseTeamMemberList)  {
                    if(countCTM == 0 || (countCTM > 0 && (ctm.MemberId != newCaseContractOwn))) {
                        caseTeamMember newcaseTeamMember  = new caseTeamMember (ParentId = newCase.Id,
                                MemberId = ctm.MemberId,
                                TeamRoleId = ctm.TeamRoleId );
                        insertCaseTeamList.add(newcaseTeamMember);
                    }

                }

                if(!insertAttList.isEmpty()) {
                    database.insert(insertAttList);
                }
                if(!insertcommentList.isEmpty()) {
                    database.insert(insertcommentList);
                }

                if (!insertCaseTeamList.isEmpty()){
                    database.insert(insertCaseTeamList);
                }

                if(triggerFileTransfer) {
                    //trigger file transfer on CDM case closure
                    String casenumber = [Select Id, CaseNumber from Case where Id = :newCase.Id limit 1].CaseNumber;
                    system.debug(triggerFileTransfer+'---'+oldCase.APT_Contract__c+'--'+oldCase.CaseNumber);
                    newCase.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Deal_Enablement_Centre).getRecordTypeId();
                    Apttus__APTS_Agreement__c apt_Contr_Id = new Apttus__APTS_Agreement__c(Id = oldCase.APT_Contract__c,
                            APT_Salesforce_Case_Number__c = caseNumber,
                            Apttus__Status__c = APT_STATUS );
                    Database.SaveResult ds = database.update(apt_Contr_Id );
                    system.debug(ds+'--'+apt_Contr_Id );
                }
            }
            else {
                database.update(newCase);
                Case caseAfterInsert = [Select Id,APT_Contract_Owner__c from Case where Id =: newCase.Id LIMIT 1];
                Integer countCTM = [Select Count() from CaseTeamMember where ParentId =: newCase.Id AND MemberId =: caseAfterInsert.APT_Contract_Owner__c];
                System.debug('--> countCTM -> '+countCTM);
                if(countCTM == 0) {
                    String caseViewerTeamRoleId = [Select Id from CaseTeamRole where Name = 'Case Viewer'].Id;
                    CaseTeamMember caseTeamMemberFirst = new caseTeamMember(ParentId = newCase.Id,
                            MemberId = caseAfterInsert.APT_Contract_Owner__c,
                            TeamRoleId = caseViewerTeamRoleId);
                    Database.insert(caseTeamMemberFirst);
                }
            }

            result.put(OP_PARAM, newCase.Id);
        }
        catch (Exception exp) {
            //log the exception record
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    'CaseManagerProcessHelper', 'invoke',
                    null, LoggingLevel.ERROR);
        }*/
        return new Process.PluginResult(result);

    }

    /**
    @description  method to declare the input and output params for the helper class
    @param    NA
    @return   Process.PluginDescribeResult
    @throws   NA
    */
    global Process.PluginDescribeResult describe() {
        Process.PluginDescribeResult result = new Process.PluginDescribeResult();
        /*result.Name = 'Look Up Case By Id';
        result.Tag = 'Case Classes';
        result.inputParameters = new
                List<Process.PluginDescribeResult.InputParameter>{
                new Process.PluginDescribeResult.InputParameter(IDCASE,
                        Process.PluginDescribeResult.ParameterType.STRING, true) ,
                new Process.PluginDescribeResult.InputParameter(IS_INSERT,
                        Process.PluginDescribeResult.ParameterType.Boolean, true),
                new Process.PluginDescribeResult.InputParameter(EPARCEL_STD,
                        Process.PluginDescribeResult.ParameterType.Boolean, true) ,
                new Process.PluginDescribeResult.InputParameter(NEW_CASH_ACC,
                        Process.PluginDescribeResult.ParameterType.Boolean, true) ,
                new Process.PluginDescribeResult.InputParameter(NEW_CHARGE_ACC,
                        Process.PluginDescribeResult.ParameterType.Boolean, true) ,
                new Process.PluginDescribeResult.InputParameter(NEW_SUB_ACC,
                        Process.PluginDescribeResult.ParameterType.Boolean, true)
        };
        result.outputParameters = new
                List<Process.PluginDescribeResult.OutputParameter>{
                new Process.PluginDescribeResult.OutputParameter(OP_PARAM,
                        Process.PluginDescribeResult.ParameterType.STRING)
        };*/
        return result;
    }

}