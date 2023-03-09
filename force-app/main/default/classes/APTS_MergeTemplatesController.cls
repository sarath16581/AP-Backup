/**************************************************
Description:  This apex class is controller for vf page - APTS_GenerateDocs used for generating the contract documents from the contract record.This class will generate contract doc for all the selected templates
History:
2016-07-01  Mausam Padhiyar Modified
2016-08-02  Mausam Padhiyar Modified Defect - 1230, set status category and status as In Author and Author Contract
2016-08-02  Mausam Padhiyar Modified Defect - 1230, set status category and status as In Author and Author Contract
2016-08-09  Mausam Padhiyar Modified Defect - 1336, populate status category and status only if customer signature is required
2017-02-01  Mausam Padhiyar Modified 1825 | R2T Pricing Schedule template should be unchecked by default for Offline Rates
2019-05-31 anshul.goyal@auspost.com.au Modified | 31052019 | to hide the common templates(i.e. cover page) for the exempted prod types(priority prod,workforce ver and startrack prod)
**************************************************
@ModifiedBy: Meet Desai
@ModifiedOn: 12 Mar, 2020
@Description: Updated Merge Documents logic to refer Files/ Content Documents instead of Attachments
**************************************************
@ModifiedBy: Mahesh Patel
@ModifiedOn: 15 Mar, 2021
@Description: Made removeTemplateCS to have unique templates

@ModifiedBy: Nasir Jawed
@ModifiedOn: 6 DEC, 2022
@Description: REmoved all the SOQL with Selectors
**************************************************/
public with sharing class APTS_MergeTemplatesController{
    
    //Neccessary for controller extension
    public final Apttus__APTS_Agreement__c APTSAgreement;
    
    //Declaration of variables
    public Apttus__APTS_Agreement__c Agreement; //Agreement that's in use
    List<APT_R2T_Templates_Settings__c> templateCS = new list<APT_R2T_Templates_Settings__c>(); //List of custom settings record
    List<APT_R2T_Templates_Settings__c> removeTemplateCS = new list<APT_R2T_Templates_Settings__c>(); //List of custom settings record to be removed
    List<Apttus__APTS_Template__c> templates = new list<Apttus__APTS_Template__c>(); //List of templates
    public List<TemplateWrapper> lstTemplateWrapper{get;set;}  //List of templates and information to be displayed in the visualforce page
    
    public Integer Sequence = 1; //Sequence of the templates
    public Integer totalFiles{get;set;} //Number of the total files need to be generated
    public Integer completedFiles{get;set;} //Number of the generated files
    
    public List<SelectOption> outputFormatOptions {get;set;} //Options of generated document output formats
    public String outputFormat {get;set;} //User's choice of generated document format
    public ID templateID {get;set;} //ID of the template the user is interacting with
    public Boolean processSubmitted{get;set;} //True if the user has not submitted the templates for processing
    public Boolean mergeDocuments{get;set;} //Merge generated documents if true
    public Boolean deleteGenDocs{get;set;} //Delete all generated files
    public Boolean noFile{get;set;} //True if there are only 1 or less files retrieved
    public Boolean outputFormatPermission{get;set;} //True if current user has the permission to change output format
    
    //Parameters for the generate and merge API
    public Apttus__ComplySystemProperties__c instanceurl = Apttus__ComplySystemProperties__c.getvalues('System Properties'); //Get the Instance URL
    
    public List<ID> templateIDs = new List<ID>(); //List of template's ID
    public List<String> templateOutputFormat = new List<String>(); //List of template's output format
    public ID agreementID; //ID of the agreement in use
    public List<String> templatepLevels = new List<String>(); //Protection level of the generated files
    public Boolean isDraft = false; //True if the generated document is a draft
    public String sessionID = userInfo.getSessionId(); //User session ID
    public String serverURL = instanceurl.Apttus__InstanceUrl__c +'/services/Soap/u/38.0/'+UserInfo.getOrganizationId(); //Merge server URL
    
    public List<ID> fileIDs = new List<ID>(); //List of newly generated file IDs
    public String FileName = 'Merge'; //Postfix file name of the merged document
    
    public list<Apttus__APTS_Template__c> listTemplate {get; set;}
    public Integer completedSubmitDocsCount = 0;
    public list<Id> listTemplateId;
    map<Id, String> mapTemplateOutputFormat = new map<Id, String>();
    map<Id, String> mapTemplatepLevel = new map<Id, String>();
    public set<Id> setAsyncMergeCallIds = new set<Id>();
    
    public Boolean haserrorMessages {get; set;}
    
    
    //Constructor
    public APTS_MergeTemplatesController(ApexPages.StandardController stdController){
        try {
            //Initialization
            processSubmitted = false;
            deleteGenDocs = true;
            mergeDocuments = true;
            lstTemplateWrapper = new list<TemplateWrapper> ();
            
            outputFormatOptions = new List<selectOption>();
            outputFormatOptions.add(new selectOption('PDF', 'PDF'));
            outputFormatOptions.add(new selectOption('DOCX', 'DOCX'));
            
            listTemplate = new list<Apttus__APTS_Template__c>();
            
            Apttus__ComplySystemProperties__c complySystemProperties = Apttus__ComplySystemProperties__c.getvalues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
            serverURL = complySystemProperties.Apttus__InstanceUrl__c + '/services/Soap/u/38.0/' + UserInfo.getOrganizationId();
            
            sessionId = userInfo.getSessionId();
            
            listTemplateId = new list<Id>();
            haserrorMessages = false;
            
            //Get the ID of the current agreement
            this.APTSAgreement = (Apttus__APTS_Agreement__c)stdController.getRecord();
            Id IdAgreement = Apexpages.currentPage().getParameters().get('Id');
            Agreement = new Apttus__APTS_Agreement__c();            
            Agreement = APT_AgreementObjectsSelector.newInstance().selectByConfigId(new set<ID>{(ID)IdAgreement},new set<Object>{APT_AgreementObjectsSelector.options.WITH_RECORDTYPE,APT_AgreementObjectsSelector.options.WITH_PROPOSAL})[0] ;
           
            agreementID = Agreement.ID;
            
            //1825
            Boolean hasOfflineRates = false;
            if(Agreement != null && Agreement.Apttus_QPComply__RelatedProposalId__r.APT_Use_Offline_Rates__c && String.isNotBlank(Agreement.APT_Pricing_Category__c) && Agreement.APT_Pricing_Category__c.equalsIgnoreCase(APT_Constants.OFFLINE_RATES))  {
                hasOfflineRates = true;
            }
            //1825            
            
            if(Agreement.RecordType.DeveloperName!=null){
                mergeDocuments = (Agreement.RecordType.DeveloperName.equalsIgnoreCase(Label.APT_Letter_of_Intent_RecordType) 
                                && Agreement.Apttus__Subtype__c.equalsIgnoreCase(Label.APT_Applications_and_Questionnaire_Subtype)) ? false : true;
            }
            
            //Query the custom setting records that have the same Record Type and Subtype
            templateCS = [SELECT Id, Name, Compare_against_IPL__c, Template_Product_Name__c, Sequence_No__c, Template_ID__c, Default_Document_Output__c, Security_Level__c,
                         APT_Check_Against_NPL__c, APT_Change_in_Pricing__c, APT_Rate_Type__c
                         FROM APT_R2T_Templates_Settings__c 
                         WHERE Record_Type_API__c = :Agreement.RecordType.DeveloperName 
                               AND 
                               Subtype__c = :Agreement.Apttus__Subtype__c
                               AND
                               Contract_Type__c = :Agreement.APT_Contract_Type__c
                               AND
                               Settings_Type__c = 'Template'
                         ORDER BY Sequence_No__c];
            
            //Set noFile to false if there are at least one template retrived
            if(templateCS.size() > 0) {
                noFile = false;
            } else {
                noFile = true;
            }
            
            //1084
            //Find original contract
            map<Id, String> mapOriginalIncludedProductLines = new map<Id, String>();
            
            List<Apttus__APTS_Related_Agreement__c> relatedAgreementList = APT_RelatedAgreementsSelector.newInstance().selectByAgreementId(new set<ID>{agreementID},new set<Object>{APT_RelatedAgreementsSelector.options.WITH_AGREEMENT});
                                                                                
            for(Apttus__APTS_Related_Agreement__c relatedAgreement :relatedAgreementList){
                if(String.isBlank(mapOriginalIncludedProductLines.get(relatedAgreement.Apttus__APTS_Contract_To__c))){
                    mapOriginalIncludedProductLines.put(relatedAgreement.Apttus__APTS_Contract_To__c, relatedAgreement.Apttus__APTS_Contract_From__r.Included_Product_Lines__c);
                }
            }
            
            set<String> setOldIncludedProductLines = new set<String>();
            set<String> setNewProductLines = new set<String>();
            if(String.isNotBlank(Agreement.Included_Product_Lines__c) && String.isNotBlank(mapOriginalIncludedProductLines.get(Agreement.Id)) && !Agreement.Included_Product_Lines__c.equalsIgnoreCase(mapOriginalIncludedProductLines.get(Agreement.Id))) {
                list<String> listNewIncludedProductLines = Agreement.Included_Product_Lines__c.split(APT_Constants.SEPERATOR_SEMI_COLON);
                list<String> listOldIncludedProductLines = mapOriginalIncludedProductLines.get(Agreement.Id).split(APT_Constants.SEPERATOR_SEMI_COLON);
                if(listOldIncludedProductLines != null && listOldIncludedProductLines.size() > 0) {
                    for(String ipl : listOldIncludedProductLines) {
                        setOldIncludedProductLines.add(ipl);
                    }
                    
                    for(String ipl : listNewIncludedProductLines) {
                        if(!setOldIncludedProductLines.contains(ipl) && !ipl.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST)) {
                            setNewProductLines.add(ipl);
                        }
                    }
                }
            }
            
            
            //check if print post is added and having new pricing?
            Boolean bPrintPostNewPricing = false;
            if(String.isNotBlank(Agreement.Included_Product_Lines__c) && Agreement.Included_Product_Lines__c.contains(APT_Constants.PRODUCT_CODE_PRINT_POST)) {
                list<Apttus__AgreementLineItem__c> listAgreementLineItem = APT_AgreementLineItemsSelector.newInstance().selectByContractIdsLineTypeProduct(new set<ID>{(ID)agreementID},new set<String>{APT_Constants.LINE_TYPE_PRODUCT_SERVICE},new set<String>{APT_Constants.PRODUCT_CODE_PRINT_POST}) ;
                system.debug('listAgreementLineItem :'+ listAgreementLineItem );
                if(listAgreementLineItem != null && listAgreementLineItem.size() > 0) {
                    bPrintPostNewPricing = true;  
                }                                                     
                //system.debug('*** Print Post - New Pricing? ***'+(listAgreementLineItem != null && listAgreementLineItem.size() > 0 ? true : false));
            }
            //1084
            
            //Find the list of custom setting records to be removed
            set<String> setTemplateReferenceIds = new set<String>();
            for(APT_R2T_Templates_Settings__c tmpCS : templateCS) {
                //system.debug('*** Name **'+tmpCS.Name);

                //31052019- collect exempted contract custom metadata values
                Set <String> excludedProdLinesSet = new Set <String> ();
                for(R2T_Exempted_Contract_Settings__mdt rec : [SELECT MasterLabel,DeveloperName FROM R2T_Exempted_Contract_Settings__mdt]){
                    excludedProdLinesSet.add(rec.MasterLabel.toLowerCase());
                }
                //31052019-check for the custom setting record where no product is defined(i.e. cover page) and add in the remove list to not show it for the exempted prods
                if(String.isBlank(tmpCS.Template_Product_Name__c) && (excludedProdLinesSet.contains(Agreement.Included_Product_Lines__c.toLowerCase()))){
                    removeTemplateCS.add(tmpCS);
                }
                 //check against included product lines
                if(tmpCS.Compare_against_IPL__c && !String.isEmpty(Agreement.Included_Product_Lines__c) && !String.isEmpty(tmpCS.Template_Product_Name__c)) {
                    if(!(Agreement.Included_Product_Lines__c.Contains(tmpCS.Template_Product_Name__c))) {
                        //system.debug('*** Name1 **'+tmpCS.Name);
                        removeTemplateCS.add(tmpCS);
                    }
                }

                //For startrack
                if(!String.isEmpty(Agreement.Included_Product_Lines__c) && Agreement.Included_Product_Lines__c.Contains(APT_Constants.PRODUCTTYPE_STARTRACK)) 
                {
                    //R2T templates are not required
                    //For offline and standard rate type, pricing schedule templates are different
                    if((tmpCS.Template_Product_Name__c == null || string.isBlank(tmpCS.Template_Product_Name__c))
                       || (!hasOfflineRates && tmpCS.APT_Rate_Type__c == APT_Constants.RATE_TYPE_OFFLINE)
                       || (hasOfflineRates && tmpCS.APT_Rate_Type__c == APT_Constants.RATE_TYPE_STANDARD))
                    {
                        removeTemplateCS.add(tmpCS);
                    }
                }
                
                //1084
                //check againt new product lines
                //system.debug('*** tmpCS.APT_Check_Against_NPL__c ***'+tmpCS.APT_Check_Against_NPL__c);
                //system.debug('*** template name ***'+tmpCS.Template_Product_Name__c);
                //system.debug('*** bPrintPostNewPricing ***'+bPrintPostNewPricing);
                //system.debug('*** included product lines ***'+Agreement.Included_Product_Lines__c);
                //system.debug('*** setNewProductLines ***'+setNewProductLines);
                if(tmpCS.APT_Check_Against_NPL__c && String.isNotBlank(tmpCS.Template_Product_Name__c) && setNewProductLines.size() > 0) {
                    //system.debug('*** setNewProductLines ***'+setNewProductLines);
                    if(!(setNewProductLines.Contains(tmpCS.Template_Product_Name__c))) {
                        //1242
                        if(tmpCS.Template_Product_Name__c.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST)) {
                            if(String.isNotBlank(Agreement.Included_Product_Lines__c) && Agreement.Included_Product_Lines__c.Contains(tmpCS.Template_Product_Name__c) && !bPrintPostNewPricing) {
                                removeTemplateCS.add(tmpCS);
                            } else if(String.isNotBlank(Agreement.Included_Product_Lines__c) && !Agreement.Included_Product_Lines__c.Contains(tmpCS.Template_Product_Name__c)) {
                                removeTemplateCS.add(tmpCS);
                            } else {}
                        } else {
                            removeTemplateCS.add(tmpCS);
                        }
                        //1242
                        //system.debug('*** 1 ***');
                    } else if(Agreement.Included_Product_Lines__c.Contains(tmpCS.Template_Product_Name__c) && tmpCS.Template_Product_Name__c.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST) && !bPrintPostNewPricing) {
                        removeTemplateCS.add(tmpCS);
                        //system.debug('*** 2 ***');
                    } else {}
                } else if(tmpCS.APT_Check_Against_NPL__c && String.isNotBlank(tmpCS.Template_Product_Name__c) && setNewProductLines.size() == 0 && !tmpCS.Template_Product_Name__c.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST)) {
                    removeTemplateCS.add(tmpCS);
                    //system.debug('*** 3 ***');
                } else if(tmpCS.APT_Check_Against_NPL__c && String.isNotBlank(tmpCS.Template_Product_Name__c) && setNewProductLines.size() == 0 && tmpCS.Template_Product_Name__c.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST) && String.isNotBlank(Agreement.Included_Product_Lines__c) && !Agreement.Included_Product_Lines__c.contains(APT_Constants.PRODUCT_CODE_PRINT_POST)) {
                    removeTemplateCS.add(tmpCS);
                    //system.debug('*** 4 ***');
                } else if(tmpCS.APT_Check_Against_NPL__c && String.isNotBlank(tmpCS.Template_Product_Name__c) && setNewProductLines.size() == 0 && tmpCS.Template_Product_Name__c.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST) && String.isNotBlank(Agreement.Included_Product_Lines__c) && Agreement.Included_Product_Lines__c.contains(APT_Constants.PRODUCT_CODE_PRINT_POST) && !bPrintPostNewPricing) {
                    removeTemplateCS.add(tmpCS);
                    //system.debug('*** 5 ***');
                } else {}
                
                //change in pricing
                //system.debug('*** change in Pricing? ***'+tmpCS.APT_Change_in_Pricing__c);
                //system.debug('*** Agreement.APT_New_Pricing__c ***'+Agreement.APT_New_Pricing__c);
                if(tmpCS.APT_Change_in_Pricing__c && !Agreement.APT_New_Pricing__c){
                    removeTemplateCS.add(tmpCS);
                }
                //1084
                
                //defect-1253
                if(String.isNotBlank(Agreement.Included_Product_Lines__c) && String.isNotBlank(tmpCS.Name) && tmpCS.Name.contains(APT_Constants.PRICING_SCHEDULE) 
                    && Agreement.Included_Product_Lines__c.contains(APT_Constants.PRODUCT_CODE_PRINT_POST) 
                    && !Agreement.Included_Product_Lines__c.contains(APT_Constants.EPARCELS_DOMESTIC)
                    && !Agreement.Included_Product_Lines__c.contains(APT_Constants.INTERNATIONAL)
                    && !Agreement.Included_Product_Lines__c.contains(APT_Constants.PRODUCT_CODE_UMS)
                    ) {
                        
                    removeTemplateCS.add(tmpCS);
                }
                
                /*
                if(String.isNotBlank(tmpCS.Template_ID__c)) {
                    if(setTemplateReferenceIds.contains(tmpCS.Template_ID__c)) {
                        system.debug('*** Name2 ***'+tmpCS.Name);
                        removeTemplateCS.add(tmpCS);
                    }
                    setTemplateReferenceIds.add(tmpCS.Template_ID__c);
                }
                */
                //defect-1253
            }

            //remove duplicate entries from list
            Map<Id, APT_R2T_Templates_Settings__c> mapUniqueTempsToRemove = new Map<Id, APT_R2T_Templates_Settings__c>();
            for(APT_R2T_Templates_Settings__c tmpCSremove : removeTemplateCS)
            {
                mapUniqueTempsToRemove.put(tmpCSremove.Id, tmpCSremove);
            }

            List<APT_R2T_Templates_Settings__c> uniqueTempsToRemove = mapUniqueTempsToRemove.values();
            
            //Find the indexes of the templates to be removed
            List<Integer> removeTemplateCSIndexes = new List<Integer>();
            //system.debug('*** removeTemplateCS **'+removeTemplateCS);
            for(APT_R2T_Templates_Settings__c tmpCSremove : uniqueTempsToRemove) {
                //system.debug('*** Name All **'+tmpCSremove.Name);
                for(Integer i = 0; i < templateCS.size(); i++) {
                    if(tmpCSremove.ID == templateCS[i].ID)
                        removeTemplateCSIndexes.add(i);
                }
            }
            
            //Remove custom settings from the complete list
            for(Integer i = 0; i < removeTemplateCSIndexes.size(); i++) {
                templateCS.remove(removeTemplateCSIndexes[i] - i);
            }
            
            
            List<String> templatesRefList = new List<String>();
            
            for(APT_R2T_Templates_Settings__c  tem  : templateCS){
               // system.debug('*** tem1 **'+tem.Name);
                templatesRefList.add(tem.Template_ID__c);
            }            
                                                               
            List<Apttus__APTS_Template__c> templatesList = APT_TemplateObjectSelector.newInstance().selectByRefrenceId(templatesRefList);                                                    
            //Query the templates from the remaining custom setting records
            map<String, Apttus__APTS_Template__c> mapTemplates = new map<String, Apttus__APTS_Template__c>();
            if(templatesList != null && templatesList.size() > 0 ){
                for(Apttus__APTS_Template__c tem : templatesList ) {
                    //system.debug('*** tem2 **'+tem.Name);
                    mapTemplates.put(tem.Apttus__ReferenceId__c, tem);
                    templates.add(tem);
                }
            }
            
            //Set the permission for changing output format
            List<APT_R2T_Templates_Settings__c> PermissionCS = [SELECT Permission_ID__c
                                                                FROM APT_R2T_Templates_Settings__c 
                                                                WHERE Settings_Type__c = 'Permission'];
            
            outputFormatPermission = false;
            for(APT_R2T_Templates_Settings__c pCS : PermissionCS) {
                if(pCS.Permission_ID__c.equalsIgnoreCase(UserInfo.getUserId().left(15)) || pCS.Permission_ID__c.equalsIgnoreCase(userinfo.getProfileId().left(15)))
                    outputFormatPermission = true;
            }
            
            //Add the templates to the wrapper with additional information
            //1825
            Boolean isSelected = false;
            TemplateWrapper tempWrp;
            //1825

            //uncheck pricing schedule templates for offline rates
            List<string> templatesToUncheck = APT_Utils.getContractTemplatesToUncheck();

            for(Integer i = 0; i < templateCS.size(); i++) {    
                
                Apttus__APTS_Template__c template = mapTemplates.get(templateCS[i].Template_ID__c);
                
                //1825
                isSelected = false;
                if(hasOfflineRates && template != null && String.isNotBlank(template.Name) && templatesToUncheck.contains(template.Name)) {
                    isSelected = false;
                } else {
                    isSelected = true;
                }
                //1825

                if(template != null) {
                    if(Sequence == 1 ) {
                        //Do not display the up button when it's the first item
                        //1825
                        tempWrp = new TemplateWrapper(template, Agreement.ID, Sequence, templateCS[i].Default_Document_Output__c, templateCS[i].Security_Level__c, false, true);
                        tempWrp.selected = isSelected;
                        lstTemplateWrapper.add(tempWrp);

                        //lstTemplateWrapper.add(new TemplateWrapper(template, Agreement.ID, Sequence, templateCS[i].Default_Document_Output__c, templateCS[i].Security_Level__c, false, true));

                        //1825
                    } else if(Sequence == templates.size()) {
                        //1825
                        tempWrp = new TemplateWrapper(template, Agreement.ID, Sequence, templateCS[i].Default_Document_Output__c, templateCS[i].Security_Level__c, true, false);
                        tempWrp.selected = isSelected;
                        lstTemplateWrapper.add(tempWrp);
                        //lstTemplateWrapper.add(new TemplateWrapper(template, Agreement.ID, Sequence, templateCS[i].Default_Document_Output__c, templateCS[i].Security_Level__c, true, false));
                        //1825
                    } else {
                        //Display both buttons for other items
                        //1825
                        tempWrp = new TemplateWrapper(template, Agreement.ID, Sequence, templateCS[i].Default_Document_Output__c, templateCS[i].Security_Level__c, true, true);
                        tempWrp.selected = isSelected;
                        lstTemplateWrapper.add(tempWrp);

                        //lstTemplateWrapper.add(new TemplateWrapper(template, Agreement.ID, Sequence, templateCS[i].Default_Document_Output__c, templateCS[i].Security_Level__c, true, true));

                        //1825
                    }
                }           
                
                Sequence++;
            }
        } catch(system.exception ex) {
            haserrorMessages = true;            
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    //Prepare templates for generation
    public void GenerateDocument() {
        try {
            /**
            //Initialization
            totalFiles = 0;
            completedFiles = 0;
            
            //Find the selected templates
            for(Integer i = 0; i < lstTemplateWrapper.size(); i++) {
                if(lstTemplateWrapper[i].selected) {
                    templateIDs.add(lstTemplateWrapper[i].template.ID);
                    templateOutputFormat.add(lstTemplateWrapper[i].outputFormat);
                    templatepLevels.add(lstTemplateWrapper[i].pLevel);
                    totalFiles++;
                }
            }
            
            //Document processing begins
            processSubmitted = true;
            
            **/
            
            
            //Find the selected templates
            String templateOrder;
            for(Integer i = 0; i < lstTemplateWrapper.size(); i++) {
                if(lstTemplateWrapper[i].selected) {
                    //templateIDs.add(lstTemplateWrapper[i].template.ID);
                    //templateOutputFormat.add(lstTemplateWrapper[i].outputFormat);
                    //templatepLevels.add(lstTemplateWrapper[i].pLevel);
                    //totalFiles++;
                    
                    Apttus__APTS_Template__c templateSO = lstTemplateWrapper[i].template;
                    if(templateSO != null && !String.isEmpty(templateSO.Apttus__Category__c)) {
                        if(!String.isEmpty(templateOrder)) {
                            templateOrder += ',' + templateSO.id;
                        } else {
                            templateOrder = templateSO.id;
                        }
                           
                        if(templateSO.Apttus__Category__c.equalsIgnoreCase(APT_Constants.CATEGORY_SUBMIT)) {
                            //submit gen doc
                            listTemplate.add(templateSO);                        
                        } else {
                            //gen doc
                            listTemplateId.add(templateSO.ID);
                        }
                    }
                    
                    mapTemplateOutputFormat.put(lstTemplateWrapper[i].template.ID, lstTemplateWrapper[i].outputFormat);
                    mapTemplatepLevel.put(lstTemplateWrapper[i].template.ID, lstTemplateWrapper[i].pLevel);
                }
            }
            
            /*
            Apttus__APTS_Agreement__c agreement = [SELECT Id, Name, Document_Generated_by_Merge__c, 
                                                    APT_Is_Create_Contract_Batch_Job_Running__c, APT_Merge_Documents__c,
                                                    APT_Remove_Standalone_Docs__c
                                                    FROM Apttus__APTS_Agreement__c WHERE Id = :agreementID];
            */
            
            //update agreement
            agreement.APT_Is_Create_Contract_Batch_Job_Running__c = true;
            //agreement.APT_Is_Generate_Doc_Batch_Running__c = true;
            agreement.APT_Merge_Documents__c = mergeDocuments;
            agreement.APT_Remove_Standalone_Docs__c = deleteGenDocs;
            agreement.APT_Template_Order_Sequence__c = templateOrder;
            
            //defect-1230
            if(agreement.APT_Require_Customer_Signature__c) {   //defect-1336
                agreement.Apttus__Status_Category__c = APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_AUTHORING;
                agreement.Apttus__Status__c = APT_Constants.AGREEMENT_STATUS_AUTHOR_CONTRACT;
            }
            //defect-1230
            
            update agreement;
            
            //noFile = false;
            processSubmitted = true;
        } catch(system.exception ex) {
            haserrorMessages = true;            
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        
        //return null;
    }
    
    /*
    public PageReference completeGenDocs() {
        return new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + agreementID);
    }
    */
    
    public PageReference processSubmitDocs() {
        try {     
            
            if(listTemplate != null && listTemplate.size() > 0 && completedSubmitDocsCount < listTemplate.size()) {
                system.debug('*** template id ***'+listTemplate[completedSubmitDocsCount].Id);
                system.debug('*** agreementID ***'+agreementID);
                system.debug('*** pLevele ***'+mapTemplatepLevel.get(listTemplate[completedSubmitDocsCount].Id));
                system.debug('*** outptu format ***'+mapTemplateOutputFormat.get(listTemplate[completedSubmitDocsCount].Id));
                system.debug('*** sessionId ***'+sessionId);
                system.debug('*** serverURL ***'+serverURL);
                Id fileId = Apttus.MergeWebService.submitGenerateDoc(listTemplate[completedSubmitDocsCount].Id, agreementID, mapTemplatepLevel.get(listTemplate[completedSubmitDocsCount].Id), mapTemplateOutputFormat.get(listTemplate[completedSubmitDocsCount].Id), false, sessionId, serverURL);
                system.debug('*** fileId ***'+fileId);
                setAsyncMergeCallIds.add(fileId);
                completedSubmitDocsCount++;
            } else {
                agreement.APT_Is_Generate_Doc_Batch_Running__c = true;
                if(setAsyncMergeCallIds.size() > 0) {
                    String submittedAsynMergeCallIds;
                    for(Id asyncMergeCallId : setAsyncMergeCallIds) {
                        if(!String.isEmpty(submittedAsynMergeCallIds)){
                            submittedAsynMergeCallIds += ',' + asyncMergeCallId;
                        } else {
                            submittedAsynMergeCallIds = asyncMergeCallId;
                        }
                    }
                    agreement.APT_Submitted_Async_Merge_Call_Ids__c = submittedAsynMergeCallIds;
                }
                update agreement;
                
                //call gen doc api
                APT_CreateContractBatch controller = new APT_CreateContractBatch(agreementID, listTemplateId, mapTemplatepLevel, mapTemplateOutputFormat, mergeDocuments, deleteGenDocs);
                database.executeBatch(controller, 1);
                
                return new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + agreementID);
            }
        } catch(system.exception ex) {
            haserrorMessages = true;            
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }
    
    /**
    //Generate all the templates and then combine them
    public PageReference processDocs() {
        
        //Initialize return page to null
        Pagereference pageref = null;
        try{
        //Generate attachments
        if(completedAttachments < totalAttachments) {
            
            ID attachmentID;
            
            attachmentID = Apttus.MergeWebService.generateDoc2(templateIDs[0], agreementID, templatepLevels[0], templateOutputFormat[0], isDraft, sessionID, serverURL);
            
            attachmentIDs.add(attachmentID);
            
            templateIDs.remove(0);
            templateOutputFormat.remove(0);
            templatepLevels.remove(0);
            
            completedAttachments++; 
        }
        
        //Combine generated attachments after the generation is completed if mergeDocument is true
        else if(mergeDocuments) {
            
            ID DocumentGeneratedbyMerge;
            
            DocumentGeneratedbyMerge = Apttus.MergeWebService.mergeDocsToPDF(agreementID, attachmentIDs, Agreement.Name + '_' + FileName + '.pdf', sessionID, serverURL);
            
            //Delete all the generated attachments if user choose to do so
            if(deleteGenDocs) {
                List<Attachment> DeleteAttachments = new List<Attachment>();
                
                DeleteAttachments = [SELECT ID
                                    FROM Attachment
                                    WHERE ID = :attachmentIDs];
                                    
                delete DeleteAttachments;
            }
            
            //Save the ID of the attachment generated by merging
            if(Agreement.Document_Generated_by_Merge__c == null && DocumentGeneratedbyMerge != null)
                Agreement.Document_Generated_by_Merge__c = DocumentGeneratedbyMerge + ';';
            else
                Agreement.Document_Generated_by_Merge__c = Agreement.Document_Generated_by_Merge__c + DocumentGeneratedbyMerge + ';';
            
            update Agreement;
            
            pageref = new pagereference('/'+Agreement.Id); //return to record page
        }
        
        //Do not merge documents if mergeDocuments is false
        else {
            pageref = new pagereference('/'+Agreement.Id); //return to record page
        }
        } Catch (Exception ex){
            system.debug('Exception : ' + ex);
        }
        return pageref;
    }
    **/
    //Return to record page
    public PageReference Cancel() {
        Pagereference pageref = new pagereference(APT_Constants.SEPERATOR_BACKWARD_SLASH + Agreement.Id);
        pageref.setredirect(true);
        return pageref;
    }
    
    //Action to move the template up
    public void upAction() {
        try{
            TemplateWrapper tempTemplateWrapper; //Temporary placeholder
            
            //Find the template that needs to be moved
            for(Integer i = 0; i < lstTemplateWrapper.size(); i++) {
                if(lstTemplateWrapper[i].template.ID == templateID) {
                    
                    //Do not do anything if the template is the first template
                    if(lstTemplateWrapper[i].Sequence == 1) {
                        return;
                    }
                    
                    //Swap the selected template with the template above it
                    else {
                        
                        tempTemplateWrapper = lstTemplateWrapper[i];
                        
                        lstTemplateWrapper[i].Sequence--;
                        lstTemplateWrapper[i-1].Sequence++;
                        
                        lstTemplateWrapper[i] = lstTemplateWrapper[i-1];
                        lstTemplateWrapper[i-1] = tempTemplateWrapper;
                        
                        //Reevaluate upVisible and downVisible
                        for(Integer j = 0; j <= 1; j++) {
                            if(lstTemplateWrapper[i-j].Sequence == 1) {
                                lstTemplateWrapper[i-j].upVisible = false;
                                lstTemplateWrapper[i-j].downVisible = true;
                            }
                            else if(lstTemplateWrapper[i-j].Sequence == lstTemplateWrapper.size()) {
                                lstTemplateWrapper[i-j].upVisible = true;
                                lstTemplateWrapper[i-j].downVisible = false;
                            }
                            else {
                                lstTemplateWrapper[i-j].upVisible = true;
                                lstTemplateWrapper[i-j].downVisible = true;
                            }
                        }
                        
                        return;
                    }
                }
            }
        } catch(system.exception ex) {
            haserrorMessages = true;            
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    //Action to move the template down
    public void downAction() {
        try{
            TemplateWrapper tempTemplateWrapper; //Temporary placeholder
            
            //Find the template that needs to be moved
            for(Integer i = 0; i < lstTemplateWrapper.size(); i++) {
                if(lstTemplateWrapper[i].template.ID == templateID) {
                    
                     //Do not do anything if the template is the last item
                    if(lstTemplateWrapper[i].Sequence == lstTemplateWrapper.size()) {
                        return;
                    }
                    
                    //Swap the selected template with the template below it
                    else {
                        tempTemplateWrapper = lstTemplateWrapper[i];
                                            
                        lstTemplateWrapper[i].Sequence++;
                        lstTemplateWrapper[i+1].Sequence--;
                        
                        lstTemplateWrapper[i] = lstTemplateWrapper[i+1];
                        lstTemplateWrapper[i+1] = tempTemplateWrapper;
                        
                        //Reevaluate upVisible and downVisible
                        for(Integer j = 0; j <= 1; j++) {
                            if(lstTemplateWrapper[i+j].Sequence == 1) {
                                lstTemplateWrapper[i+j].upVisible = false;
                                lstTemplateWrapper[i+j].downVisible = true;
                            }
                            else if(lstTemplateWrapper[i+j].Sequence == lstTemplateWrapper.size()) {
                                lstTemplateWrapper[i+j].upVisible = true;
                                lstTemplateWrapper[i+j].downVisible = false;
                            }
                            else {
                                lstTemplateWrapper[i+j].upVisible = true;
                                lstTemplateWrapper[i+j].downVisible = true;
                            }
                        }
                        
                        return;
                    }
                }
            }
        } catch(system.exception ex) {
            haserrorMessages = true;            
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    //wrapper class for templates
    public class TemplateWrapper{
        public Apttus__APTS_Template__c template{get;set;}
        public ID AgreementID{get;set;}
        public Integer Sequence {get;set;}
        public String outputFormat {get;set;}
        public String pLevel {get;set;}
        public boolean upVisible{get;set;}
        public boolean downVisible{get;set;}
        
        public boolean selected{get;set;}
        
        public TemplateWrapper(Apttus__APTS_Template__c template, ID AgreementID, Integer Sequence, String outputFormat, String pLevel, boolean upVisible, boolean downVisible) {
            this.template = template;
            this.AgreementID = AgreementID;
            this.Sequence = Sequence;
            this.outputFormat = outputFormat;
            this.pLevel = pLevel;
            this.upVisible = upVisible;
            this.downVisible = downVisible;
            
            this.selected = true;
        }
    }
}