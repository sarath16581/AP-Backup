/**
 * @author Mausam Padhiyar
 * @date 2016-08-09
 * @description This Apex Class is handler for Apex trigger - APT_SAPContractTrigger
 * @changelog
 * 2016-08-09 - Mausam Padhiyar - Created
 * 2016-11-16 - Mausam Padhiyar - reduce logic
 * 2023-02-03 - Ranjeewa Silva - Switch to use ApplicationDatabase for dml operations. this is to allow mocking in unit tests.
 */
public with sharing class APT_SAPContractTriggerHandler {
    
    /**
     * before insert
     */
    public static string beforeInsertEvent(list<APT_SAP_Contracts__c> listSAPContract) {
    try {
            set<Id> setAgreementId = new set<Id>();
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                    setAgreementId.add(sc.APT_Apttus_Contract__c);
                }
            }
            
            map<Id, Apttus__APTS_Agreement__c> mapAgreement = new map<Id, Apttus__APTS_Agreement__c>([SELECT Id, Apttus__Account__c
                                                                                                    FROM Apttus__APTS_Agreement__c
                                                                                                    WHERE Id IN :setAgreementId]);
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                   sc.Organisation__c = mapAgreement.get(sc.APT_Apttus_Contract__c).Apttus__Account__c;
                }
            }
        } catch(system.exception e) {
            return e.getMessage();
            }
        
        return APT_Constants.SUCCESS_LABEL;
    }
    
    /**
     * before insert
     */
     /*
    @future
    public static void beforeInsertEvent(set<Id> setSAPContractIds) {
        try {
            
            list<APT_SAP_Contracts__c> listSAPContract = [SELECT Id, APT_Apttus_Contract__c, Organisation__c
                                                            FROM APT_SAP_Contracts__c 
                                                            WHERE Id IN :setSAPContractIds];
            
            set<Id> setAgreementId = new set<Id>();
            if(listSAPContract != null && listSAPContract.size() > 0) {
                for(APT_SAP_Contracts__c sc : listSAPContract) {
                    if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                        setAgreementId.add(sc.APT_Apttus_Contract__c);
                    }
                }
            }
            
            map<Id, Apttus__APTS_Agreement__c> mapAgreement = new map<Id, Apttus__APTS_Agreement__c>([SELECT Id, Apttus__Account__c
                                                                                                    FROM Apttus__APTS_Agreement__c
                                                                                                    WHERE Id IN :setAgreementId]);
            
            list<APT_SAP_Contracts__c> listUpdateSAPContract = new list<APT_SAP_Contracts__c>();
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                   sc.Organisation__c = mapAgreement.get(sc.APT_Apttus_Contract__c).Apttus__Account__c;
                   listUpdateSAPContract.add(sc);
                }
            }
            
            if(listUpdateSAPContract.size() > 0) {
                update listUpdateSAPContract;
            }
        } catch(system.exception e) {
            //return e.getMessage();
        }
    }
    */
    
    public static string beforeUpdateEvent(list<APT_SAP_Contracts__c> listSAPContract, map<Id, APT_SAP_Contracts__c> mapOldSAPContract) {
    try {
            set<Id> setAgreementId = new set<Id>();
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c) && (sc.APT_Apttus_Contract__c != mapOldSAPContract.get(sc.Id).APT_Apttus_Contract__c || null == sc.Organisation__c)) {
                    setAgreementId.add(sc.APT_Apttus_Contract__c);
                }
            }
            
            map<Id, Apttus__APTS_Agreement__c> mapAgreement = new map<Id, Apttus__APTS_Agreement__c>([SELECT Id, Apttus__Account__c
                                                                                                    FROM Apttus__APTS_Agreement__c
                                                                                                    WHERE Id IN :setAgreementId]);
            
            
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c) && (sc.APT_Apttus_Contract__c != mapOldSAPContract.get(sc.Id).APT_Apttus_Contract__c || null == sc.Organisation__c)) {
                   sc.Organisation__c = mapAgreement.get(sc.APT_Apttus_Contract__c).Apttus__Account__c;
                }
            }
        } catch(system.exception e) {
            // Updated by Adrian Recio
            // 8/8/2017
            // Log information increased to track unable to lock row error.
            return '(MESSAGE):' + e.getMessage() + 
                   '(STACKTRACE):' + e.getStackTraceString() + 
                   '(LINENUMBER):' + e.getLineNumber() + 
                   '(CASE):' + e.getCause();
            }
        
        return APT_Constants.SUCCESS_LABEL;
    }
    
    /**
     * After Insert Trigger Event
     */
     
    
    public static string afterInsertEvent(list<APT_SAP_Contracts__c> listSAPContract) {
        try {
            set<Id> setAgreementId = new set<Id>();
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                    setAgreementId.add(sc.APT_Apttus_Contract__c);
                }
            }
            
            map<Id, Apttus__APTS_Agreement__c> mapAgreement = new map<Id, Apttus__APTS_Agreement__c>([SELECT Id, APT_Mark_for_Review__c, APT_SAP_Contracts_Record_Count__c
                                                                                                    FROM Apttus__APTS_Agreement__c
                                                                                                    WHERE Id IN :setAgreementId]);
            
            /*
            AggregateResult[] groupedResults = [SELECT APT_Apttus_Contract__c, MIN(APT_Contract_End_Date__c) minDate FROM APT_SAP_Contracts__c WHERE (APT_Apttus_Contract__c IN :mapAgreement.keySet() AND APT_Contract_End_Date__c != null AND SAP_Contract_Status__c = 'Active') GROUP BY APT_Apttus_Contract__c];
            Map<String,Date> agreementIDtoEndDateMap = new Map<String,Date>();
            for (AggregateResult ar : groupedResults)  {
                agreementIDtoEndDateMap.put(String.valueOf(ar.get('APT_Apttus_Contract__c')), Date.valueOf(ar.get('minDate')));
            }
            */
            
            Apttus__APTS_Agreement__c agreement;
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                    agreement = mapAgreement.get(sc.APT_Apttus_Contract__c);
                    if(agreement != null) {
                        if(agreement.APT_SAP_Contracts_Record_Count__c != null) {
                            agreement.APT_SAP_Contracts_Record_Count__c += 1;
                        } else {
                            agreement.APT_SAP_Contracts_Record_Count__c = 1;
                        }
                        
                        /*
                        //Logic to get lowest End Date among SAP Contract records and update in corresponding contract
                        if(agreementIDtoEndDateMap.containsKey(sc.APT_Apttus_Contract__c) && mapAgreement.get(sc.APT_Apttus_Contract__c).APT_Mark_for_Review__c == false)
                        {
                            agreement.Apttus__Contract_End_Date__c = agreementIDtoEndDateMap.get(sc.APT_Apttus_Contract__c);
                        }
                        */
                        
                        mapAgreement.put(agreement.Id, agreement);
                    }
                }
            }
            
            // call ApplicationDatabase for update. calling dmlUpdate with allOrNothing=true to replicate existing functionality.
            // was previously:
            // update mapAgreement.values();
            ApplicationDatabase.getInstance().dmlUpdate(mapAgreement.values());
            
        } catch(system.exception e) {
            return e.getMessage();
        }
        
        return APT_Constants.SUCCESS_LABEL;
    }
    
    
    /**
     * after insert event
     */
    /*
    @future
    public static void afterInsertEvent(set<Id> setSAPContractIds) {
        try {
            list<APT_SAP_Contracts__c> listSAPContract = [SELECT Id, Name, APT_Apttus_Contract__c
                                                            FROM APT_SAP_Contracts__c
                                                            WHERE Id IN :setSAPContractIds];
            set<Id> setAgreementId = new set<Id>();
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                    setAgreementId.add(sc.APT_Apttus_Contract__c);
                }
            }
            
            map<Id, Apttus__APTS_Agreement__c> mapAgreement = new map<Id, Apttus__APTS_Agreement__c>([SELECT Id, APT_Mark_for_Review__c, APT_SAP_Contracts_Record_Count__c
                                                                                                    FROM Apttus__APTS_Agreement__c
                                                                                                    WHERE Id IN :setAgreementId]);
            AggregateResult[] groupedResults = [SELECT APT_Apttus_Contract__c, MIN(APT_Contract_End_Date__c) minDate FROM APT_SAP_Contracts__c WHERE (APT_Apttus_Contract__c IN :mapAgreement.keySet() AND APT_Contract_End_Date__c != null AND SAP_Contract_Status__c = 'Active') GROUP BY APT_Apttus_Contract__c];
            Map<String,Date> agreementIDtoEndDateMap = new Map<String,Date>();
            for (AggregateResult ar : groupedResults)  {
                agreementIDtoEndDateMap.put(String.valueOf(ar.get('APT_Apttus_Contract__c')), Date.valueOf(ar.get('minDate')));
            }
            
            Apttus__APTS_Agreement__c agreement;
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                    agreement = mapAgreement.get(sc.APT_Apttus_Contract__c);
                    if(agreement != null) {
                        if(agreement.APT_SAP_Contracts_Record_Count__c != null) {
                            agreement.APT_SAP_Contracts_Record_Count__c += 1;
                        } else {
                            agreement.APT_SAP_Contracts_Record_Count__c = 1;
                        }
                        //Logic to get lowest End Date among SAP Contract records and update in corresponding contract
                        if(agreementIDtoEndDateMap.containsKey(sc.APT_Apttus_Contract__c) && mapAgreement.get(sc.APT_Apttus_Contract__c).APT_Mark_for_Review__c == false)
                        {
                            agreement.Apttus__Contract_End_Date__c = agreementIDtoEndDateMap.get(sc.APT_Apttus_Contract__c);
                        }
                        mapAgreement.put(agreement.Id, agreement);
                    }
                }
            }
            
            update mapAgreement.values();
            
        } catch(system.exception e) {
            //return e.getMessage();
        }
        
        //return APT_Constants.SUCCESS_LABEL;
    }
    */
    
    /**
     * After Update Trigger Event
     */
    
    public static string afterUpdateEvent(list<APT_SAP_Contracts__c> listSAPContract, map<Id, APT_SAP_Contracts__c> mapSAPContract) {
        try {
            set<Id> setAgreementId = new set<Id>();
            set<Id> setAgreementIdSAP = new set<Id>();
            set<Id> setOldAgreementId = new set<Id>();
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c) && String.isNotBlank(mapSAPContract.get(sc.Id).APT_Apttus_Contract__c) && sc.APT_Apttus_Contract__c != mapSAPContract.get(sc.Id).APT_Apttus_Contract__c) {
                    setAgreementId.add(sc.APT_Apttus_Contract__c);
                    setOldAgreementId.add(mapSAPContract.get(sc.Id).APT_Apttus_Contract__c);
                }
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                    setAgreementIdSAP.add(sc.APT_Apttus_Contract__c);
                }
            }
            
            map<Id, Apttus__APTS_Agreement__c> mapAgreement = new map<Id, Apttus__APTS_Agreement__c>([SELECT Id, APT_Mark_for_Review__c, APT_SAP_Contracts_Record_Count__c
                                                                                                    FROM Apttus__APTS_Agreement__c
                                                                                                    WHERE Id IN :setAgreementIdSAP OR Id IN :setOldAgreementId]);
            
            map<Id, Apttus__APTS_Agreement__c> mapAgreementChange = new map<Id, Apttus__APTS_Agreement__c>();
            for(Apttus__APTS_Agreement__c agrSO : mapAgreement.values())
            {
                if(setAgreementId.contains(agrSO.ID) || setOldAgreementId.contains(agrSO.ID))
                {
                    mapAgreementChange.put(agrSO.ID, agrSO);
                }
            }
            map<Id, Apttus__APTS_Agreement__c> mapAgreementSAP = new map<Id, Apttus__APTS_Agreement__c>();
            for(Apttus__APTS_Agreement__c agrSO : mapAgreement.values())
            {
                if(setAgreementIdSAP.contains(agrSO.ID))
                {
                    mapAgreementSAP.put(agrSO.ID, agrSO);
                }
            }
            
            /*
            AggregateResult[] groupedResults = [SELECT APT_Apttus_Contract__c, MIN(APT_Contract_End_Date__c) minDate FROM APT_SAP_Contracts__c WHERE (APT_Apttus_Contract__c IN :mapAgreementSAP.keySet() AND APT_Contract_End_Date__c != null AND SAP_Contract_Status__c = 'Active') GROUP BY APT_Apttus_Contract__c];
            Map<String,Date> agreementIDtoEndDateMap = new Map<String,Date>();
            for (AggregateResult ar : groupedResults)  {
                agreementIDtoEndDateMap.put(String.valueOf(ar.get('APT_Apttus_Contract__c')), Date.valueOf(ar.get('minDate')));
            }                                                                                   
            */
            
                                                                                                    
            //new agreement, addition
            Apttus__APTS_Agreement__c agreement;
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                    agreement = mapAgreementChange.get(sc.APT_Apttus_Contract__c);
                    if(agreement != null) {
                        if(agreement.APT_SAP_Contracts_Record_Count__c != null) {
                            agreement.APT_SAP_Contracts_Record_Count__c += 1;
                        } else {
                            agreement.APT_SAP_Contracts_Record_Count__c = 1;
                        }
                        
                        mapAgreement.put(agreement.Id, agreement);
                    }
                }
                
                /*
                //Logic to get lowest End Date among SAP Contract records and update in corresponding contract
                if(agreementIDtoEndDateMap.containsKey(sc.APT_Apttus_Contract__c) && mapAgreement.containsKey(sc.APT_Apttus_Contract__c) && mapAgreement.get(sc.APT_Apttus_Contract__c).APT_Mark_for_Review__c == false)
                {
                    mapAgreement.get(sc.APT_Apttus_Contract__c).Apttus__Contract_End_Date__c = agreementIDtoEndDateMap.get(sc.APT_Apttus_Contract__c);
                }
                */
            }
            
            //old agreement, substraction
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c) && String.isNotBlank(mapSAPContract.get(sc.Id).APT_Apttus_Contract__c) && sc.APT_Apttus_Contract__c != mapSAPContract.get(sc.Id).APT_Apttus_Contract__c) {
                    agreement = mapAgreementChange.get(mapSAPContract.get(sc.Id).APT_Apttus_Contract__c);
                    if(agreement != null) {
                        if(agreement.APT_SAP_Contracts_Record_Count__c != null) {
                            agreement.APT_SAP_Contracts_Record_Count__c -= 1;
                        } else {
                            agreement.APT_SAP_Contracts_Record_Count__c = 0;
                        }
                        
                        mapAgreement.put(agreement.Id, agreement);
                    }
                }
            }
            
            // Updated by Adrian Recio
            // 18/9/2017
            // Removed to stop conflicting unable to lock row error in tibco batch
            //update mapAgreement.values();
            
        } catch(system.exception e) {
            // Updated by Adrian Recio
            // 8/8/2017
            // Log information increased to track unable to lock row error.
            return '(MESSAGE):' + e.getMessage() + 
                   '(STACKTRACE):' + e.getStackTraceString() + 
                   '(LINENUMBER):' + e.getLineNumber() + 
                   '(CASE):' + e.getCause();
        }
        
        return APT_Constants.SUCCESS_LABEL;
    }
    
    
    /**
     * after update
     */
    /*
    @future
    public static void afterUpdateEvent(set<Id> setSAPContractIds) {
        try {
            set<Id> setAgreementId = new set<Id>();
            set<Id> setAgreementIdSAP = new set<Id>();
            //set<Id> setOldAgreementId = new set<Id>();
            
            list<APT_SAP_Contracts__c> listSAPContract = [SELECT Id, Name, APT_Apttus_Contract__c
                                                            FROM APT_SAP_Contracts__c
                                                            WHERE Id IN :setSAPContractIds];
            
            map<Id, APT_SAP_Contracts__c> mapSAPContract = new  map<Id, APT_SAP_Contracts__c>();
            if(listSAPContract != null && listSAPContract.size() > 0) {
                for(APT_SAP_Contracts__c sapContract : listSAPContract) {
                    mapSAPContract.put(sapContract.id, sapContract);
                }
            }
            
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                
                //if(String.isNotBlank(sc.APT_Apttus_Contract__c) && String.isNotBlank(mapSAPContract.get(sc.Id).APT_Apttus_Contract__c) && sc.APT_Apttus_Contract__c != mapSAPContract.get(sc.Id).APT_Apttus_Contract__c) {
                //    setAgreementId.add(sc.APT_Apttus_Contract__c);
                //    setOldAgreementId.add(mapSAPContract.get(sc.Id).APT_Apttus_Contract__c);
                //}
                
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                    setAgreementId.add(sc.APT_Apttus_Contract__c);
                    setAgreementIdSAP.add(sc.APT_Apttus_Contract__c);
                }
            }
            
            map<Id, Apttus__APTS_Agreement__c> mapAgreement = new map<Id, Apttus__APTS_Agreement__c>([SELECT Id, APT_Mark_for_Review__c, APT_SAP_Contracts_Record_Count__c
                                                                                                    FROM Apttus__APTS_Agreement__c
                                                                                                    WHERE Id IN :setAgreementIdSAP ]);
            
            map<Id, Apttus__APTS_Agreement__c> mapAgreementChange = new map<Id, Apttus__APTS_Agreement__c>();
            for(Apttus__APTS_Agreement__c agrSO : mapAgreement.values())
            {
                if(setAgreementId.contains(agrSO.ID) )
                {
                    mapAgreementChange.put(agrSO.ID, agrSO);
                }
            }
            map<Id, Apttus__APTS_Agreement__c> mapAgreementSAP = new map<Id, Apttus__APTS_Agreement__c>();
            for(Apttus__APTS_Agreement__c agrSO : mapAgreement.values())
            {
                if(setAgreementIdSAP.contains(agrSO.ID))
                {
                    mapAgreementSAP.put(agrSO.ID, agrSO);
                }
            }
            AggregateResult[] groupedResults = [SELECT APT_Apttus_Contract__c, MIN(APT_Contract_End_Date__c) minDate FROM APT_SAP_Contracts__c WHERE (APT_Apttus_Contract__c IN :mapAgreementSAP.keySet() AND APT_Contract_End_Date__c != null AND SAP_Contract_Status__c = 'Active') GROUP BY APT_Apttus_Contract__c];
            Map<String,Date> agreementIDtoEndDateMap = new Map<String,Date>();
            for (AggregateResult ar : groupedResults)  {
                agreementIDtoEndDateMap.put(String.valueOf(ar.get('APT_Apttus_Contract__c')), Date.valueOf(ar.get('minDate')));
            }                                                                                   
            
                                                                                                    
            //new agreement, addition
            Apttus__APTS_Agreement__c agreement;
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                    agreement = mapAgreementChange.get(sc.APT_Apttus_Contract__c);
                    if(agreement != null) {
                        if(agreement.APT_SAP_Contracts_Record_Count__c != null) {
                            agreement.APT_SAP_Contracts_Record_Count__c += 1;
                        } else {
                            agreement.APT_SAP_Contracts_Record_Count__c = 1;
                        }
                        
                        mapAgreement.put(agreement.Id, agreement);
                    }
                }
                
                //Logic to get lowest End Date among SAP Contract records and update in corresponding contract
                if(agreementIDtoEndDateMap.containsKey(sc.APT_Apttus_Contract__c) && mapAgreement.containsKey(sc.APT_Apttus_Contract__c) && mapAgreement.get(sc.APT_Apttus_Contract__c).APT_Mark_for_Review__c == false)
                {
                    mapAgreement.get(sc.APT_Apttus_Contract__c).Apttus__Contract_End_Date__c = agreementIDtoEndDateMap.get(sc.APT_Apttus_Contract__c);
                }
            }
            
            //old agreement, substraction
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c) && String.isNotBlank(mapSAPContract.get(sc.Id).APT_Apttus_Contract__c) && sc.APT_Apttus_Contract__c != mapSAPContract.get(sc.Id).APT_Apttus_Contract__c) {
                    agreement = mapAgreementChange.get(mapSAPContract.get(sc.Id).APT_Apttus_Contract__c);
                    if(agreement != null) {
                        if(agreement.APT_SAP_Contracts_Record_Count__c != null) {
                            agreement.APT_SAP_Contracts_Record_Count__c -= 1;
                        } else {
                            agreement.APT_SAP_Contracts_Record_Count__c = 0;
                        }
                        
                        mapAgreement.put(agreement.Id, agreement);
                    }
                }
            }
            
            update mapAgreement.values();
            
        } catch(system.exception e) {
            //return e.getMessage();
        }
        
        //return APT_Constants.SUCCESS_LABEL;
    }
    */
    
    /**
     * before Delete Trigger Event
     */
    public static string beforeDeleteEvent(list<APT_SAP_Contracts__c> listSAPContract) {
        try {
            set<Id> setAgreementId = new set<Id>();
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                    setAgreementId.add(sc.APT_Apttus_Contract__c);
                }
            }
            
            map<Id, Apttus__APTS_Agreement__c> mapAgreement = new map<Id, Apttus__APTS_Agreement__c>([SELECT Id, APT_SAP_Contracts_Record_Count__c
                                                                                                    FROM Apttus__APTS_Agreement__c
                                                                                                    WHERE Id IN :setAgreementId]);
            Apttus__APTS_Agreement__c agreement;
            for(APT_SAP_Contracts__c sc : listSAPContract) {
                if(String.isNotBlank(sc.APT_Apttus_Contract__c)) {
                    agreement = mapAgreement.get(sc.APT_Apttus_Contract__c);
                    if(agreement != null) {
                        if(agreement.APT_SAP_Contracts_Record_Count__c != null) {
                            agreement.APT_SAP_Contracts_Record_Count__c -= 1;
                        } else {
                            agreement.APT_SAP_Contracts_Record_Count__c = 0;
                        }
                        
                        mapAgreement.put(agreement.Id, agreement);
                    }
                }
            }

            // call ApplicationDatabase for update. calling dmlUpdate with allOrNothing=true to replicate existing functionality.
            // was previously:
            // update mapAgreement.values();
            ApplicationDatabase.getInstance().dmlUpdate(mapAgreement.values());
        } catch(System.Exception e) {
            return e.getMessage();
        }
        return APT_Constants.SUCCESS_LABEL;
    }
}