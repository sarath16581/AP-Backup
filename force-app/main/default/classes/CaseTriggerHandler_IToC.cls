/**
 * Date            Version          Owner               Desription
 * 28-Mar-17        1.0             Adrian A            Main I2c Case Trigger Handler Class
 */
public without sharing class CaseTriggerHandler_IToC {
    public static Boolean recursiveFlag = false;

    /* @created by: Adrian Recio
     * @description Main after insert trigger handler method              
     */ 
    public static void afterUpdateTriggerHandler(Map <Id, Case> oldMap, List <Case> newList){
        if(CaseTriggerHandler_IToC.recursiveFlag==false){
           newList = filterByECDCRecordtype(newList);
           populateCaseCloseAdjustment(oldMap, newList);
        }
    }
    
     /* Method to a list of Case records filtered by record type */
    public static List<Case> filterByECDCRecordtype(List<Case> caseList){
        Id ecdcRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Enterprise Credit Dispute Claim').getRecordTypeId();

        List<Case>cCaseTempList = new List<Case>();

        for(Case cVar: caseList){
            if(cVar.RecordTypeId==ecdcRTId){
                cCaseTempList.add(cVar);
            }
        }

        return cCaseTempList;
    }
    
     /* Method to populate adjustment records on closure of Case */
    public static void populateCaseCloseAdjustment(Map <Id, Case> oldMap, List <Case> caseList){

        Set<Id>caseIdSet = new Set<Id>();
        List<Case>closeCaseList = new List<Case>();
        for(Case cVar: caseList){
            if(cVar.Status == 'Closed'){
                caseIdSet.add(cVar.Id);
                closeCaseList.add(cVar);
            }
        }
        
        if(caseIdSet.size()>0){
            List<Case> childCAList = ([Select Id, Related_Billing_Account__r.Source_System__c,
                                                    (Select Id, Type__c, Adjustment__c, Status__c from Credit_Adjustments__r 
                                                    where Type__c IN ('Non-Discretionary','Discretionary Credit') ) ,
                                                    (Select Id from Disputed_Items__r where Status__c IN ('New')) 
                                                        from Case where Id IN :caseIdSet]);

            Map<Id, Case> mainCaseMap = new Map<Id, Case>(childCAList);
            Map<Id, Case> cMapD = new Map<Id, Case>();
            Map<Id, Case> cMapND = new Map<Id, Case>();

            for(Case cVar: childCAList){
                for(Credit_Approval__c caVar: cVar.Credit_Adjustments__r){
                    if(caVar.Status__c == 'Approved'){
                        if(caVar.Type__c == 'Discretionary Credit'){
                            cMapD.put(cVar.Id, cVar);
                        }
                        if(caVar.Type__c == 'Non-Discretionary'){
                            cMapND.put(cVar.Id, cVar);
                        }
                    }
                }
            }

            List<Adjustment__c> adNewList = new List<Adjustment__c>();

            for(Case cVar: closeCaseList){

                Boolean IsChanged = true;

                if(oldMap!=null && cVar.Status!=null){
                    Case oldC = oldMap.get(cVar.Id);
                    if(oldC.Status == cVar.Status){
                        IsChanged = false;
                    }
                }

                if(IsChanged && cVar.Status=='Closed'){
                    // Case level validations required on case close
                    if(cVar.Related_Billing_Account__c==null){
                        cVar.Related_Billing_Account__c.addError('Related Billing Account must be populated');
                    }
                    if(cVar.Billing_Number__c==null){
                        cVar.Billing_Number__c.addError('Billing Account Number must be populated');
                    }

                    
                    Case caseND = cMapND.get(cVar.Id);
                    Case caseD = cMapD.get(cVar.Id);

                    Boolean diError = false;

                    List<Credit_Approval__c> caCheckTempList = new List<Credit_Approval__c>();
                    
                    if(caseND!=null){
                        caCheckTempList.addAll(caseND.Credit_Adjustments__r);

                        if(caseND.Disputed_Items__r.size()>0){ // DI New status check
                            diError = true;
                        }
                    }else if(caseD!=null){
                        caCheckTempList.addAll(caseD.Credit_Adjustments__r);

                        if(caseD.Disputed_Items__r.size()>0){ // DI New status check
                            diError = true;
                        }
                    }

                    system.debug('Non-Discretionary:' + string.valueOf(caseND));
                    system.debug('Discretionary:' + string.valueOf(caseD));

                    // Child CA validation
                    Integer approveCount = 0;
                    Integer rejectCount = 0;
                    Integer invalidCount = 0;
                    
                    for(Credit_Approval__c caVar: caCheckTempList){
                        /*
                        if(caVar.Status__c != 'Rejected' && caVar.Status__c != 'Approved'){
                            cVar.Status.addError('Complete pending approval decisions before case close.');
                        }
                        */

                        if(caVar.Status__c == 'Approved'){
                            approveCount++;
                        }

                        if(caVar.Status__c == 'Rejected'){
                            rejectCount++;
                        }
                        
                        if(caVar.Status__c == 'Invalid'){
                            invalidCount++;
                        }
                    }

                    system.debug(cVar.Id + '-->Approve Count:' + approveCount);
                    system.debug(cVar.Id + '-->Reject Count:' + rejectCount);
                    system.debug(cVar.Id + '-->Invalid Count:' + invalidCount);
                    system.debug(cVar.Id + '-->Total Adjustment CA Count:' + caCheckTempList.size());
                    system.debug(cVar.Id + '-->Total Adjustment & incorrect CA Count:' + 
                                 mainCaseMap.get(cVar.Id).Credit_Adjustments__r.size());
                    
                    Boolean HasOtherStatus = false;
                    
                    if((approveCount+rejectCount+invalidCount)!=caCheckTempList.size()){
                        HasOtherStatus = true;
                    }else if(caCheckTempList.size() == 0){
                        for(Credit_Approval__c caTemp: mainCaseMap.get(cVar.Id).Credit_Adjustments__r){
                            if(caTemp.Status__c != 'Approved' && caTemp.Status__c != 'Rejected' && caTemp.Status__c != 'Invalid'){
                                HasOtherStatus = true;
                            }
                        }
                    }
                    
                    if(HasOtherStatus){
                        cVar.Status.addError('All associated Credit Approvals should be either \'Approved\' or \'Rejected\' or \'Invalid\' to close the case');
                    }

                    // DI validation
                    if(diError){
                        cVar.Status.addError('No associated Disputed Item status is \'New\'');
                    }

                    // Create adjustment if type CA exist for adjustment
                    if(caseND!=null){ // Non-Discretionary type
                        Adjustment__c adVarND = new Adjustment__c();
                        adVarND.Billing_Account__c = cVar.Related_Billing_Account__c;
                        adVarND.Organisation__c = cVar.AccountId;
                        adVarND.Case__c = cVar.Id;
                        adVarND.ERP__c = caseND.Related_Billing_Account__r.Source_System__c;
                        adVarND.Type__c = 'Non-Discretionary';
                        adNewList.add(adVarND);
                    }

                    if(caseD!=null){ // Discretionary type
                        Adjustment__c adVarD = new Adjustment__c();
                        adVarD.Billing_Account__c = cVar.Related_Billing_Account__c;
                        adVarD.Organisation__c = cVar.AccountId;
                        adVarD.Case__c = cVar.Id;
                        adVarD.ERP__c = caseD.Related_Billing_Account__r.Source_System__c;
                        adVarD.Type__c = 'Discretionary Credit';
                        adNewList.add(adVarD);
                    }

                    //cVar.Status.addError(string.valueOf(adNewList.size()));
                    system.debug('Adjustment size:' + adNewList.size());
                }

            }


            

            if(adNewList.size()>0){
                try{
                  insert adNewList;
                }catch(exception e){
                    system.debug('CaseCloseError:' + e.getStackTraceString());
                    for(Case cVar: closeCaseList){
                      cVar.Status.addError('Adjustment creation failed. Please contact your administrator.');  
                    }
                }
                CaseTriggerHandler_IToC.recursiveFlag = true;
            }
        }
        
    }
}