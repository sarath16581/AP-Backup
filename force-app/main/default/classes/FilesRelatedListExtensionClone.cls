/*------------------------------------------------------------
Author:   :      Jeoffrey Palmero/Prince Encina
Date Created:    5/28/2019
Description:     VF page to mimic the Files Related List to show the Signed Documents for the Contract object
Test Class:      FilesRelatedListExtensionClone_Test


History
<Date>           <Authors Name>     <Brief Description of Change>
05/28/2019        JPalmero           Created
------------------------------------------------------------*/
public class FilesRelatedListExtensionClone {
    // Variable declaration
    public static final string INTERNAL_USERS = 'InternalUsers';
    public static final string VISIBILITY_INTERNAL_USERS = 'InternalUsers';
    public static final string SHARE_TYPE_V = 'V';
    public static final String allString = 'All';
    private final Contract aptContract;
    private String finalStatus;
    private String docType;
    public List<ContentVersion> cvList { get; set; }
    public String selectedType { get; set; }
    public String docuType { get; set; }
    
    // Picklist Values for filters
    public List<SelectOption> optionsSignatureType {get; set;}
    public List<SelectOption> optionsDocumentType {get; set;}

    /*------------------------------------------------------------
    Author:        Chester Borbon
    Company:       Accenture
    Description:   Contructor to instantiate apttus contract controller
    Inputs:        N/A
    Returns:       N/A
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Chester Borbon     First version.
    ------------------------------------------------------------*/
    public FilesRelatedListExtensionClone(ApexPages.StandardController controller) {
        getPicklistValues();    // dynamically populate filter picklists
        // Instantiate agreement controller
        this.aptContract = (Contract)controller.getRecord();
        cvList = getFiles(aptContract, allString, allString);
    }

    /*------------------------------------------------------------
    Author:        Jeoffrey Palmero
    Company:       Accenture
    Description:   Get Files (ContentVersion) for given apttus agreements/contracts
    Inputs:        aptContract -  parent apttus contract record
    Returns:       List<ContentVersion> - list of files
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    28-May-2019  Jeoffrey Palmero   Created
    ------------------------------------------------------------*/
    public static List<ContentVersion> getFiles(sObject aptContract, String finalStatus, String docType) {
        String SELECT_STRING = 'SELECT ID, Title, ContentDocumentID, Document_Type__C,Is_Signed__c,Signature_Type__c, IsLatest, LastModifiedDate, CreatedById FROM ContentVersion ';
        String WHERE_STRING = 'WHERE ID IN: cvListSelect';
        STRING AND_SIGNTYPE = ' AND Signature_Type__c = \'';
        STRING AND_DOCTYPE = ' AND Document_Type__c = \'';
        String ORDERBY_STRING = ' ORDER BY Sort_Technical_Field__c DESC, LastModifiedDate DESC ';
        String QUERY_STRING;        // the assembled string for Database.query
        
        Set<Id> contentDocumentIdSet = new Set<Id>();
        String parentAgreementId;
        List<ContentVersion> cvListSelect = new List<ContentVersion>();
        List<ContentVersion> retCVList = new List<ContentVersion>();
        List<ContentVersion> retAnalogCVList = new List<ContentVersion>();
        if(aptContract != NULL){
            Contract contractObj = [SELECT Id, Parent_Agreement__c 
                                    FROM Contract 
                                    WHERE Id =: aptContract.Id
                                    LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())];
            
            if(contractObj.Parent_Agreement__c != NULL){
                parentAgreementId = contractObj.Parent_Agreement__c;
            }
            for(ContentDocumentLink cdlList : [SELECT ID, ContentDocumentID, LinkedEntityID 
                                               FROM ContentDocumentLink 
                                               WHERE LinkedEntityID =: parentAgreementId
                                               LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())]){
                contentDocumentIdSet.add(cdlList.ContentDocumentID);
            }
            
            // Get parent content version Ids
            
            for(ContentVersion cVersion : [SELECT ID, Title, ContentDocumentID, Document_Type__C, IsLatest,Is_Signed__c,Signature_Type__c, LastModifiedDate, CreatedById
                                           FROM ContentVersion
                                           WHERE ContentDocumentID IN : contentDocumentIdSet AND IsLatest=TRUE AND Is_Signed__c = TRUE
                                           LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())])
            {
                if(cVersion != NULL) {
                    cvListSelect.add(cVersion);
                }
            }
        }

        if(!String.isEmpty(finalStatus)){ 
            if(finalStatus.equalsIgnoreCase(allString) && docType.equalsIgnoreCase(allString)){ //Show All
                QUERY_STRING = '';      // set this to empty string
                for(ContentVersion cvBuff : cvListSelect){
                    retCVList.add(cvBuff);
                }
            }
            else if(!finalStatus.equalsIgnoreCase(allString) && docType.equalsIgnoreCase(allString)){ //Sign Type is filtered
                QUERY_STRING = SELECT_STRING + WHERE_STRING + AND_SIGNTYPE + finalStatus + '\'' + ORDERBY_STRING;
            }
            else if(!finalStatus.equalsIgnoreCase(allString) && !docType.equalsIgnoreCase(allString)){ // Sign Type and is Doc Type filtered
                QUERY_STRING = SELECT_STRING + WHERE_STRING + AND_SIGNTYPE + finalStatus + '\'' + AND_DOCTYPE + docType + '\'' + ORDERBY_STRING;
            }
            else if(finalStatus.equalsIgnoreCase(allString) && !docType.equalsIgnoreCase(allString)){ // Doc Type filtered
                QUERY_STRING = SELECT_STRING + WHERE_STRING + AND_DOCTYPE + docType + '\'' + ORDERBY_STRING;
            }
            
            // call Database.query for the query string
            if (String.isNotEmpty(QUERY_STRING)) {
                retCVList = Database.query(QUERY_STRING);
            }
        }
        return retCVList;
        
    }
    
    /*------------------------------------------------------------
    Author:        Chester Borbon
    Company:       Accenture
    Description:   Redirect null
    Inputs:        N/A
    Returns:       Pagereference - redirect null
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Chester Borbon     First version.
    ------------------------------------------------------------*/
    public PageReference goToFilesEditPage() {
        return null;
    }
    
    /* Description: Sets the string to the selected value in the VisualForce Page
     * Author: JPalmero
     * History:
     * 05/29/2019           Created
     */
    public void setStatus(){
        finalStatus = selectedType;
        docType = docuType;
        cvList = getFiles(aptContract, finalStatus, docuType);
    }
    
    /*************************************************************
     * Description: Sets the string to the selected value in the VisualForce Page
     * Author: JPalmero
     * History:
     * 05/29/2019           Created
     *************************************************************/
    public void setDocType(){
        finalStatus = selectedType;
        docType = docuType;
        cvList = getFiles(aptContract, finalStatus, docuType);
    }
    
    /*************************************************************
     * Description: Dynamically gets the picklist values of fields used for filtering
     * Author: Prince Encina
     * History:
     * 06/25/2019           Created
     *************************************************************/
    public void getPicklistValues() {
        // Signature_Type__c values
        Schema.DescribeFieldResult signatureTypeDesc = ContentVersion.Signature_Type__c.getDescribe();
        optionsSignatureType = new List<SelectOption>();
        optionsSignatureType.add(new SelectOption('All', 'All'));
        for (Schema.PicklistEntry picklistEntry: signatureTypeDesc.getPicklistValues()) {
            optionsSignatureType.add(new SelectOption(picklistEntry.getValue(), picklistEntry.getLabel()));
        }
        
        // Document_Type__c values
        Schema.DescribeFieldResult documentTypeDesc = ContentVersion.Document_Type__c.getDescribe();
        optionsDocumentType = new List<SelectOption>();
        optionsDocumentType.add(new SelectOption('All', 'All'));
        for (Schema.PicklistEntry picklistEntry: documentTypeDesc.getPicklistValues()) {
            optionsDocumentType.add(new SelectOption(picklistEntry.getValue(), picklistEntry.getLabel()));
        }
    }
}