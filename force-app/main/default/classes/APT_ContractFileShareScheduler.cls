/*
@Description        : Class to schedule a class to share files of apttus contract
                      to related salesforce contracts when a salesforce contracts are
                      created or updated since creating file and creating/updating sf contract are not synchronous 
                      methods and can't link files in the same transaction.
================================ Modification Log =============================== 
Developer Name  Date            Comments
Ramtej          27/03/2019      Created
Ramtej          24/06/2019      Removed Scheduled method to link files which is pushed to daily batch job instead
*/
global class APT_ContractFileShareScheduler implements Schedulable{
    public static final string INTERNAL_USERS = 'InternalUsers';
    public static final string SHARE_TYPE_V = 'V';
    public static final string SIGNED = '__signed';
    public static final string COMPLETED= 'completed';
    public static final string DIGITAL= 'Digital';
    public List<Contract> contractList {get; set;} // list passing the sf contracts (from invoking method) to be processed to associate files under parent apttus contracts
    
    /*
        Schedulable method invoked when an apttus contract is activated or a file is uploaded for an apttus contract
    */    
    global void execute(SchedulableContext ctx) {
        //invoke method 
        //linkFiles();//Stop linking files method and use this class to schedule a batch to link the files from apttus contract to sf contract
        APT_ContractFileShareBatch fileShareBatch = new APT_ContractFileShareBatch();
        Database.executeBatch(fileShareBatch,1);
    }
    
    /*
        Method to link the files under apttus contracts to sf contracts
    */
    public void linkFiles(){
    
        map<Id,List<Contract>> contractToApttusContractMap = new map<Id,List<Contract>>();
        set<Id> sfContractIdSet = new set<Id>();
        Map<ID,ID> contentDocIdApptusContractIdMap = new Map<ID,ID>();
        List<ContentVersion> contentVersionListToBeUpdated = new List<ContentVersion>();
        
        try{

            for(Contract con :contractList){
            
                sfContractIdSet.add(con.Id);  
                
                //mapping of apttus contract id with it's child sf contracts
                List<Contract> contractListForApttusContract = new List<Contract>();
                if(contractToApttusContractMap.containsKey(con.Parent_Agreement__c)){
                    contractListForApttusContract = contractToApttusContractMap.get(con.Parent_Agreement__c);
                }
                contractListForApttusContract.add(con);
                contractToApttusContractMap.put(con.Parent_Agreement__c, contractListForApttusContract);
            }
            
            system.debug('sfContractIdSet '+sfContractIdSet);
            system.debug('contractToApttusContractMap '+contractToApttusContractMap);
            
            //Query existing file Ids for sf contracts using contentdocumentlink object
            set<Id> sfContractContentDocLinkSet = new set<Id>();
            for(ContentdocumentLink con :[SELECT Id, ContentDocumentId, LinkedEntityId, Visibility FROM 
                                                                      ContentDocumentLink WHERE LinkedEntityId IN :sfContractIdSet]){
                sfContractContentDocLinkSet.add(con.ContentDocumentId);
            }
            system.debug('sfContractContentDocLinkSet '+sfContractContentDocLinkSet);
            
            //Query existing file Ids for apttus contracts using contentdocumentlink object
            set<Id> apttusContractIdset = contractToApttusContractMap.keyset();

            List<ContentdocumentLink> apttusContractContentDocLinkList = [SELECT Id, ContentDocumentId, LinkedEntityId, Visibility FROM 
                                                                          ContentDocumentLink WHERE LinkedEntityId IN :apttusContractIdset
                                                                         AND Visibility = :INTERNAL_USERS];
            system.debug('apttusContractContentDocLinkList '+apttusContractContentDocLinkList);
            
            List<ContentdocumentLink> contentDocToBeInserted = new List<ContentdocumentLink>();
            
            //Iterate through contentdoclink/files under apttus contracts
            for(ContentdocumentLink apttusContractDoc :apttusContractContentDocLinkList){
                contentDocIdApptusContractIdMap.put(apttusContractDoc.ContentDocumentId , apttusContractDoc.LinkedEntityId);
                //Itertate through related sf contracts
                for(Contract sfContractDoc :contractToApttusContractMap.get(apttusContractDoc.LinkedEntityid)){
                    //if the sf contract doesn't have the contentdoclink record associated with the file proceed to create a contentdoclink record
                    if(!sfContractContentDocLinkSet.contains(apttusContractDoc.contentDocumentId)){
                        ContentDocumentLink cdlSFContract = new ContentDocumentLink();
                        cdlSFContract.ContentDocumentId = apttusContractDoc.ContentDocumentID;
                        cdlSFContract.LinkedEntityId = sfContractDoc.ID;
                        cdlSFContract.ShareType = SHARE_TYPE_V;
                        cdlSFContract.Visibility = apttusContractDoc.Visibility;
                        contentDocToBeInserted.add(cdlSFContract);
                    }
                }
            }
            system.debug('contentDocToBeInserted size '+contentDocToBeInserted.size());
            system.debug('contentDocToBeInserted '+contentDocToBeInserted);
            if(contentDocToBeInserted != null && contentDocToBeInserted.size() > 0){
                //if there are more than 5 files push the dml operation to queuable interface and insert in batches
                //This is due to the 101 SOQL exception on insertion of more than 5 records of contentdocument link records
                //Queue class will take the first 5 records and push the rest to next queue job by chaining the same job
                if(contentDocToBeInserted.size() > 3){
                    system.debug('contentDocToBeInserted in schedule class '+contentDocToBeInserted.size());
                    APT_ShareFilesQueueClass queuableClass = new APT_ShareFilesQueueClass();
                    queuableClass.contentDocToBeInserted = contentDocToBeInserted;
                    system.enqueueJob(queuableClass);
                }
                else{
                    //insert contentdoclink records collected 
                    Database.SaveResult[] results = Database.insert(contentDocToBeInserted);
                    system.debug('contentDoc Inserted successfully '+results);
                }
            }
            
            //Creating a map of Apptus Contract id and Apptus Contract Record
            Map<ID,Apttus__APTS_Agreement__c> apptusAgreementMap = new MAP<ID,Apttus__APTS_Agreement__c>([SELECT ID, Apttus_CMDSign__DocuSignEnvelopeId__r.Apttus_DocuApi__Status__c 
                                                                                                                FROM Apttus__APTS_Agreement__c
                                                                                                                WHERE ID IN:apttusContractIdset]);
            
            //Iterating on Content Version Records associated to the Apptus Contract to check if they are signed and Docusign Envelope is Completed                                        
            for(ContentVersion contVer : [Select id ,Title, ContentDocumentId, Is_Signed__c , Signature_Type__c from 
                                          ContentVersion Where ContentDocumentId IN : contentDocIdApptusContractIdMap.KeySet() AND IsLatest = TRUE AND Is_Signed__c = FALSE AND Signature_Type__c !=:DIGITAL]){
                                          
                if(contVer.title.contains(SIGNED) && contentDocIdApptusContractIdMap.get(contVer.ContentDocumentId) != NULL && 
                    apptusAgreementMap.get(contentDocIdApptusContractIdMap.get(contVer.ContentDocumentId)) != NULL && 
                    apptusAgreementMap.get(contentDocIdApptusContractIdMap.get(contVer.ContentDocumentId)).Apttus_CMDSign__DocuSignEnvelopeId__c!=null && 
                    COMPLETED.equalsIgnoreCase(apptusAgreementMap.get(contentDocIdApptusContractIdMap.get(contVer.ContentDocumentId)).Apttus_CMDSign__DocuSignEnvelopeId__r.Apttus_DocuApi__Status__c)){
                        //Updating the is signed checkbox and signature type value 
                        contVer.Is_Signed__c = true ;
                        contVer.Signature_Type__c = DIGITAL;
                        //adding to the list
                        contentVersionListToBeUpdated.add(contVer);
                }                                           
            }
            
            if(!contentVersionListToBeUpdated.isEmpty()){
                // updating the content version records collected
                Database.SaveResult[] updatedResults = Database.update(contentVersionListToBeUpdated);    
            }
            
        }
        catch(exception ex){
            system.debug('exception caught in sharing file to sf contracts '+ex.getMessage()+' at line '+ex.getStackTraceString());
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    'APT_ContractFileShareScheduler', 'linkFiles', 
                                                    'No trigger', LoggingLevel.ERROR);
        }
    }
    
    //Removed Scheduled method to link files which is pushed to daily batch job instead
    /*
        Helper method to link the files under apttus contracts to sf contracts
    */
    /*public void linkFilesHelper(List<Contract> contractUpdateList, integer minutesToRun, string methodName){
        try{
            APT_ContractFileShareScheduler fileShareScheduler = new APT_ContractFileShareScheduler();
            //feed contract list to scheduler class
            fileShareScheduler.contractList = contractUpdateList;
            //Schedule a class after two minutes
            datetime runScheduleTime = system.now().addMinutes(minutesToRun);
            string runScheduleTimeString = runScheduleTime.second()+' '+runScheduleTime.minute()+' '+runScheduleTime.hour()+' '+runScheduleTime.day()+' '+runScheduleTime.month()+' ?';
            system.schedule('share files job for '+methodName+' at '+string.valueOf(runScheduleTime)+' '+string.valueOf(Integer.valueOf(math.random()) * 100), runScheduleTimeString, fileShareScheduler);          
        }
        catch(exception ex){
            system.debug('exception caught in scheduling job file to sf contracts '+ex.getMessage()+' at line '+ex.getStackTraceString());
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    'APT_ContractFileShareScheduler', 'linkFilesHelper', 
                                                    'No trigger', LoggingLevel.ERROR);
        }
    }*/
}