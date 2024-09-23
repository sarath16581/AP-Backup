/**
  * @author       : Rajesh Punjabi
  * @date         : 01/06/2019
  * @description  : Handles case creation from the MyNetwork Smart forms

--------------------------------------- History --------------------------------------------------
01.06.2019    Rajesh Punjabi(Mav3rik)    Created
19.07.2019    Ronnie Yang (Soda)         REQ1838226: capturing the originating network from which the case is raised
08.10.2020    SaiSwetha Pingali          Fix for issues reported with critical update ' Use with sharing for @AuraEnabled Apex Controllers with Implicit Sharing
22.03.2021    Suman Gunaganti            MW0004436: Wine Damages instructions changes
03.05.2021    Naveen Rajanna             REQ2483999 : Change eParcelDamages__c to text area and also append product damage details
09.06.2021    Naveen Rajanna             REQ2525818 : Include Store the Customer Ref from Article (if it exists) in eParcelDamages__c for eparcel form
28.05.2024    Snigdha Sahu               REQ2911157 : Update for additional question to Lost Article Form            
**/

public with sharing class MyNetworkSmartForms {
    @auraEnabled
    public static List<Case> createCase(String smartFormIdJson){
        try{
            List<Case> returnCase = new List<Case>();
            String sReturnQueryString = '';
            String rawQuery = 'SELECT {0} FROM Case WHERE Id={1} LIMIT 1';
            
            List<MyNetworkSmartFormsWrapper> caseWrapperList = (List<MyNetworkSmartFormsWrapper>) System.JSON.deserialize(smartFormIdJson, List<MyNetworkSmartFormsWrapper>.class);
            
            for(MyNetworkSmartFormsWrapper caseWrapper:caseWrapperList){
                System.debug(' inside createCase method..');
                Case oCase = new Case();
                MyNetworkSmartFormsService smartService = new MyNetworkSmartFormsService();
                //spingali - Added MyNetworkCaseSharing inner class to fix for issues reported with critical update ' Use with sharing for @AuraEnabled Apex Controllers with Implicit Sharing
                MyNetworkSmartFormsService.MyNetworkCaseSharing smartCaseService = new MyNetworkSmartFormsService.MyNetworkCaseSharing();
                
                // Get detfault value from Custom Metadata.
                MyNetworkSmartForms__mdt  SmartFormPreDefValues = [SELECT Id, MasterLabel, containsArticleId__c, caseIsNewForRouting__c, returnFields__c, CaseOriginator__c, caseOrigin__c, casePriority__c, caseStatus__c, caseType__c, enquirySubType__c, productName__c, subProductName__c, allocateToQueue__c 
                                                                   FROM MyNetworkSmartForms__mdt 
                                                                   WHERE MasterLabel =:caseWrapper.formId];
                System.debug(' Fetch Metadata FormId=' + SmartFormPreDefValues.MasterLabel);
                
                //.. Set record type Id
                oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(SSSWConstants.CASE_RT_SSSW_DELIVERY).getRecordTypeId();
                
                //.. pre-defined fields
                oCase.AllocateToQueue__c = SmartFormPreDefValues.allocateToQueue__c;
                oCase.Origin = SmartFormPreDefValues.caseOrigin__c;
                oCase.Status = SmartFormPreDefValues.caseStatus__c;
                oCase.IsNewForRouting__c = SmartFormPreDefValues.caseIsNewForRouting__c;
                oCase.Priority = SmartFormPreDefValues.casePriority__c;
                
                /*** Case type will be updated with form data of FormType = SomethingElse ***/
                oCase.Type = SmartFormPreDefValues.caseType__c;
                if(!String.isBlank(caseWrapper.caseType)){
                    oCase.Type = caseWrapper.caseType;
                }
                
                //.. other defualt values required for case.
                oCase.Bypass_Data_enforcement__c = true;
                oCase.Email_Bypass_Data_enforcement__c = true;
                
                //.. Validate if enquiryType is part of form data and if type = Staff Complaint, set priority to High.

                //Snigdha : REQ2911157 : Add for lost article form
                if (caseWrapper.scannedDelivered == 'Yes')
                {
                    oCase.EnquirySubType__c = 'Disputed Delivery scan';
                }
                else
                {   
                    oCase.EnquirySubType__c = SmartFormPreDefValues.enquirySubType__c;
                }
                
                if(!String.isBlank(caseWrapper.enquirySubType)){
                    oCase.EnquirySubType__c = caseWrapper.enquirySubType;
                    if(caseWrapper.enquirySubType == SmartFormPreDefValues.enquirySubType__c){
                        oCase.Priority = 'High';
                    }
                }
                
                //.. CaseOriginator__c = senderOrAddressee for (Damaged article, Lost article, Delivery Concerns) forms.
                //.. All other forms will be set to 'Customer' as defined in Custom Metadata.
                oCase.CaseOriginator__c = SmartFormPreDefValues.CaseOriginator__c;
                if(!String.isBlank(caseWrapper.caseOriginator)){
                    oCase.CaseOriginator__c = caseWrapper.caseOriginator;
                }
                
                if(!String.isBlank(caseWrapper.caseLocality)){
                  oCase.CaseLocality__c = caseWrapper.caseLocality;
                }
                else if(String.isBlank(caseWrapper.caseLocality)){
                  oCase.CaseLocality__c = 'Domestic';
                }
                
                oCase.ProductCategory__c = SmartFormPreDefValues.productName__c;
                oCase.ProductSubCategory__c = SmartFormPreDefValues.subProductName__c;
                
                if(!String.isBlank(caseWrapper.productCategory)){oCase.ProductCategory__c = caseWrapper.productCategory;}
                if(!String.isBlank(caseWrapper.productSubCategory)){oCase.ProductSubCategory__c = caseWrapper.productSubCategory;}
                
          //      oCase.Network__c = caseWrapper.facility;
                if(!String.isBlank(caseWrapper.networkId)){
                    oCase.Network__c = caseWrapper.networkId;
                }
                // REQ1838226 Assigning the originating network to case
                if(!String.isBlank(caseWrapper.facilityId)){
                    oCase.Originating_Network__c = caseWrapper.facilityId;
                }
                
           //     if(!Test.isRunningTest()){
                    System.debug('articleId' + caseWrapper.articleId);
              //    if(SmartFormPreDefValues.containsArticleId__c || caseWrapper.enquiryLinkedArticle =='yes'){
                   if(caseWrapper.enquiryLinkedArticle =='yes' || (!String.isBlank(caseWrapper.articleId)) ){ 
                       // Existing code will do the Article lookup, based on the value in the Reference ID field
                       // oCase.ArticleTest__c = smartService.getArticleId(caseWrapper.articleId);
                        oCase.ReferenceId__c = caseWrapper.articleId;
                        System.debug('Article Id - ' + oCase.ArticleTest__c);
                    }
                    else if(!String.isBlank(caseWrapper.custRefID)){
                    oCase.ReferenceID__c= caseWrapper.custRefID;
                    //oCase.CRN__c= caseWrapper.custRefID;
                }
                
                // Update Value of contents
                if(!String.isBlank(caseWrapper.valueOfContents)){
                    oCase.ValueofContents__c= Decimal.valueOf(caseWrapper.valueOfContents);
                }
                // Update Description of contents
                if(!String.isBlank(caseWrapper.contents)){
                    oCase.DescriptionofContents__c= caseWrapper.contents;
                }
                
                if(caseWrapper.senderAddress != null){
                    system.debug('setting sender address');
                    //.. Sender Address and other details
                    oCase.Address1__c = smartService.getAddressAsString(caseWrapper, MyNetworkSmartFormsService.AddressType.Sender);
                    oCase.Address1Line1__c = caseWrapper.senderAddress.addressLine1;
                    if(!String.isBlank(caseWrapper.senderAddress.addressLine2)){
                        oCase.Address1line2__c = caseWrapper.senderAddress.addressLine2;
                    }
                    //oCase.Address1Country__c = caseWrapper.senderAddress.countrycode;
                    oCase.Address1Postcode__c  = caseWrapper.senderAddress.postcode;
                    oCase.Address1State__c  = caseWrapper.senderAddress.state;
                    oCase.Address1Suburb__c  = caseWrapper.senderAddress.city;
                    oCase.Primary_Name__c = caseWrapper.senderName;
                    oCase.Primary_Email__c = caseWrapper.senderEmail;
                    oCase.Primary_Company__c = caseWrapper.senderCompany;
                }
                
                if(caseWrapper.addresseeAddress != null){
                    system.debug('setting addressee address');
                    //.. Addressee Address and other details
                    oCase.Address2__c = smartService.getAddressAsString(caseWrapper, MyNetworkSmartFormsService.AddressType.Addressee);
                    oCase.Address2Line1__c = caseWrapper.addresseeAddress.addressLine1;
                    if(!String.isBlank(caseWrapper.addresseeAddress.addressLine2)){
                       oCase.Address2line2__c = caseWrapper.addresseeAddress.addressLine2;
                    }
                    //oCase.Address2Country__c  = caseWrapper.addresseeAddress.countrycode;
                    oCase.Address2Postcode__c  = caseWrapper.addresseeAddress.postcode;
                    oCase.Address2State__c  = caseWrapper.addresseeAddress.state;
                    oCase.Address2Suburb__c  = caseWrapper.addresseeAddress.city;
                    oCase.Secondary_Contact__c = caseWrapper.addresseeName;
                    oCase.SecondaryEmail__c = caseWrapper.addresseeEmail;
                }
                else{
                    system.debug('setting Customer address');
                    //Addressee Address and other details
                    oCase.Address2__c = smartService.getAddressAsString(caseWrapper, MyNetworkSmartFormsService.AddressType.Customer);
                    oCase.Address2Line1__c = caseWrapper.customerAddress.addressLine1;
                    if(!String.isBlank(caseWrapper.customerAddress.addressLine2)){
                       oCase.Address2line2__c = caseWrapper.customerAddress.addressLine2;
                    }
                    //oCase.Address2Country__c  = caseWrapper.customerAddress.countrycode;
                    oCase.Address2Postcode__c  = caseWrapper.customerAddress.postcode;
                    oCase.Address2State__c  = caseWrapper.customerAddress.state;
                    oCase.Address2Suburb__c  = caseWrapper.customerAddress.city;
                    oCase.Secondary_Contact__c = caseWrapper.FirstName + + SSSWConstants.WHITE_SPACE + caseWrapper.LastName;
                    oCase.SecondaryEmail__c = caseWrapper.Email;
                    oCase.Phone__c = caseWrapper.MobilePhone;
                }
                
                //Customer Address and other details
                if(!String.isBlank(caseWrapper.AccountId)){
                    oCase.AccountId = caseWrapper.AccountId;
                }
                
                if(!String.isBlank(caseWrapper.contactId)){
                    oCase.ContactId = caseWrapper.contactId;
                }
                
                if(caseWrapper.compensationBeingPaid == 'yes' && (Double.valueOf(caseWrapper.postagevalue) + Double.valueOf(caseWrapper.compensationAmount) <= SSSWConstants.COMPENSTATION_VALUE)){
                    oCase.Status = SSSWConstants.CASE_STATUS_CLOSED;
                    oCase.ResolutionCode__c = SSSWConstants.CASE_RESOLUTION_CODE;
                }
                //eParcel Wine damages
                if(caseWrapper.doesContainWine =='yes' ){
                    oCase.TypeofDamage__c = SSSWConstants.CASE_TYPE_OF_DAMAGE_WINE_DAMAGE;
                    if(caseWrapper.isArticleInsured =='no' && !String.isBlank(caseWrapper.actionTaken)){
                        oCase.Status = SSSWConstants.CASE_STATUS_CLOSED;
                        oCase.resolutionCode__c = SSSWConstants.CASE_RESOLUTION_CODE;
                        oCase.Resolution_Result__c = SSSWConstants.CASE_RESOLUTION_RESULT_DAMAGES_MISSING_CONTENTS;
                        oCase.NetworkComments__c = caseWrapper.additionalInformation;
                        oCase.Issue_Resolution__c = caseWrapper.actionTaken;
                        oCase.eParcelDamages__c = caseWrapper.damageDetails+'\n\n'+
                                                'Total bottles despatched: '+caseWrapper.totalBottlesInCarton+', '+
                                                'Damaged: '+caseWrapper.totalBottlesDamaged+', '+
                                                'Not damaged: '+caseWrapper.totalBottlesNotDamaged+', '+
                                                'Labels: '+caseWrapper.noOfLabelsDamaged+', '+
                                                'Tops: '+caseWrapper.noOfCapsDamaged;
                        //REQ2525818
                        if(!String.isBlank(caseWrapper.custRefID) && caseWrapper.formId.equalsIgnoreCase('eParcel')){
                            oCase.eParcelDamages__c += '\n\n'+ 'Sender Reference: '+ caseWrapper.custRefID;
                        }
                    }
                }
                
                insert oCase;
                system.debug(' Case Created -'+oCase);
                // re-selecting case record to get case number and other required field for UI. Add new fields in metadata
                String formattedQuery = String.format (rawQuery, new String[] {smartService.toSOQLwithoutQuotes(SmartFormPreDefValues.returnFields__c),smartService.toSOQL(oCase.Id)});
                //Case newCase = Database.query(formattedQuery); 
                
                //spingali - Fix for issues reported with critical update ' Use with sharing for @AuraEnabled Apex Controllers with Implicit Sharing
                Case newCase = smartCaseService.getCasedetail(formattedQuery); 

                // Create case comments
                smartService.createCaseComments(caseWrapper, newCase);
                
                // Create compensation record
                if(caseWrapper.compensationBeingPaid == 'yes'){
                    smartCaseService.createCompensation(caseWrapper, newCase);
                }
                //eParcel Wine damages
                if(caseWrapper.doesContainWine =='yes' && caseWrapper.isArticleInsured =='no' && !String.isBlank(caseWrapper.actionTaken)){
                    smartCaseService.createNetworkResponseforWineDamageArticle(newCase.Id, 
                                                                              caseWrapper.actionTaken, 
                                                                              caseWrapper.additionalInformation,
                                                                              caseWrapper.facilityId );
                    
                }
                
                System.debug(' Case Id - ' + newCase.Id);
                System.debug(' Case Number - ' + newCase.CaseNumber);
                System.debug(' Case created from Smart Form');
                
                System.debug('return Case -'+newCase);
                returnCase.add(newCase);
            }
            return returnCase;
        }
        catch(Exception ex){
            System.debug(' Case Creation failed with an exception ..'+ ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }
}