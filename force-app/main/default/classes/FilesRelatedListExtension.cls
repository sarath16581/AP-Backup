/*------------------------------------------------------------
Author:   :      Chester Borbon
Date Created:    01/10/2018
Description:     VF page to mimic the Files Related List to show the Document Type field for the Files
Test Class:      FilesRelatedListExtension_Test


History
<Date>           <Authors Name>      <Brief Description of Change>
01/10/2018       Chester Borbon      Created VF page to mimic the Files Related List to show the Document Type field for the Files
21/10/2018       Melissa Carino      Added code comments for FilesRelatedListExtension
------------------------------------------------------------*/
public class FilesRelatedListExtension {
    // Variable declaration
    public static final string INTERNAL_USERS = 'InternalUsers';
    public static final string VISIBILITY_INTERNAL_USERS = 'InternalUsers';
    public static final string SHARE_TYPE_V = 'V';
    // public static final String allString = 'All';
    private final sObject aptContract;
    public String finalStatus;
    public String isSignedCheckbox;
    public String docType;
    public List<ContentVersion> cvList { get; set; }
    public ID cdID { get; set; }
    public blob file { get; set; }
    public String fileName { get; set; }
    public String selectedType { get; set; }
    public String ifSigned { get; set; }
    public String docuType { get; set; }
    
    public static final String ISSIGNED_SIGNED = 'Signed';
    public static final String ISSIGNED_UNSIGNED = 'Unsigned';
    public static final String ISSIGNED_TRUE = 'TRUE';
    public static final String ISSIGNED_FALSE = 'FALSE';
    
    // Picklist Values for filters
    public List<SelectOption> optionsSignatureType {get; set;}
    public List<SelectOption> optionsDocumentType {get; set;}
    public List<SelectOption> optionsIfSigned {get; set;}

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
    public FilesRelatedListExtension(ApexPages.StandardController controller) {
        getPicklistValues();    // dynamically populate filter picklists
        // Instantiate agreement controller
        this.aptContract = (sObject)controller.getRecord();
        cvList = getFiles(aptContract, Constants.STRING_ALL, Constants.STRING_ALL, Constants.STRING_ALL);
    }

    /*------------------------------------------------------------
    Author:        Chester Borbon
    Company:       Accenture
    Description:   Get Files (ContentVersion) for given apttus agreements/contracts
    Inputs:        aptContract -  parent apttus contract record
    Returns:       List<ContentVersion> - list of files
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Chester Borbon     First version.
    28-May-2019  Jeoffrey Palmero   Refactored the method to remove the query within the loop
    07-Jun-2019  Prince Encina      Changed hard-coded strings to use class declared variables
    ------------------------------------------------------------*/
    public static List<ContentVersion> getFiles(sObject aptContract, String finalStatus, String isSignedCheckbox, String docType) {
        String SELECT_STRING = 'SELECT ID, Title, ContentDocumentID, Document_Type__C,Is_Signed__c,Signature_Type__c, IsLatest, LastModifiedDate, CreatedById FROM ContentVersion ';
        String WHERE_STRING = 'WHERE ID IN :cvListSelect';
        String ORDERBY_STRING = ' ORDER BY Sort_Technical_Field__c DESC, LastModifiedDate DESC ';
        String LIMIT_STRING = 'LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())';
        
        String SIGNATURETYPE_STRING = 'Signature_Type__c = \'';
        String ISSIGNED_STRING = 'Is_Signed__c = ';
        String DOCUMENTTYPE_STRING = 'Document_Type__c = \'';
        String AND_STRING = ' AND ';
    String QUERY_STRING;        // the assembled string for Database.query
        
        Boolean isItSigned;
        if(!isSignedCheckbox.equalsIgnoreCase(Constants.STRING_ALL)){
            isItSigned = Boolean.valueOf(isSignedCheckbox);
        }
        // Query list of content document links connected to apttus contract
        Set<Id> contentDocumentIdSet = new Set<Id>();
        String parentAgreementId;
        List<ContentVersion> cvListSelect = new List<ContentVersion>();
        List<ContentVersion> retCVList = new List<ContentVersion>();
        if(aptContract != NULL){
            
            for(ContentDocumentLink cdlList : [SELECT ID, ContentDocumentID, LinkedEntityID FROM ContentDocumentLink WHERE LinkedEntityID =: aptContract.Id]){
                contentDocumentIdSet.add(cdlList.ContentDocumentID);
            }
            
            // Get parent content version Ids
            for(ContentVersion cVersion : [SELECT ID, Title, ContentDocumentID, Document_Type__C, IsLatest,Is_Signed__c,Signature_Type__c, LastModifiedDate, CreatedById
                                           FROM ContentVersion
                                           WHERE ContentDocumentID IN : contentDocumentIdSet AND IsLatest=TRUE
                                           ORDER BY Sort_Technical_Field__c DESC, LastModifiedDate DESC
                                           LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())]) {
                cvListSelect.add(cVersion);
            }
        }

        // Query content version list and return value   
        if(!String.isEmpty(finalStatus)){
            if(finalStatus.equalsIgnoreCase(Constants.STRING_ALL) && isSignedCheckbox.equalsIgnoreCase(Constants.STRING_ALL) && docType.equalsIgnoreCase(Constants.STRING_ALL)){ //Show All
                QUERY_STRING = '';      // set this to empty string
                for(ContentVersion cvBuff : cvListSelect){
                    retCVList.add(cvBuff);
                }
            }
            else if(!finalStatus.equalsIgnoreCase(Constants.STRING_ALL) && isSignedCheckbox.equalsIgnoreCase(Constants.STRING_ALL) && docType.equalsIgnoreCase(Constants.STRING_ALL)){ //Sign Type is filtered
                QUERY_STRING = SELECT_STRING + WHERE_STRING + AND_STRING + SIGNATURETYPE_STRING + finalStatus + '\'' + ORDERBY_STRING;
            }
            else if(finalStatus.equalsIgnoreCase(Constants.STRING_ALL) && !isSignedCheckbox.equalsIgnoreCase(Constants.STRING_ALL) && docType.equalsIgnoreCase(Constants.STRING_ALL)){ //is Signed filtered
                QUERY_STRING = SELECT_STRING + WHERE_STRING + AND_STRING + ISSIGNED_STRING + isItSigned + ORDERBY_STRING;
            }
            else if(!finalStatus.equalsIgnoreCase(Constants.STRING_ALL) && !isSignedCheckbox.equalsIgnoreCase(Constants.STRING_ALL) && docType.equalsIgnoreCase(Constants.STRING_ALL)){ // Sign Type and is Signed filtered
                QUERY_STRING = SELECT_STRING + WHERE_STRING + AND_STRING + SIGNATURETYPE_STRING + finalStatus + '\'' + AND_STRING + ISSIGNED_STRING + isItSigned + ORDERBY_STRING;
            }
            else if(!finalStatus.equalsIgnoreCase(Constants.STRING_ALL) && isSignedCheckbox.equalsIgnoreCase(Constants.STRING_ALL) && !docType.equalsIgnoreCase(Constants.STRING_ALL)){ // Sign Type and is Doc Type filtered
                QUERY_STRING = SELECT_STRING + WHERE_STRING + AND_STRING + SIGNATURETYPE_STRING + finalStatus + '\'' + AND_STRING + DOCUMENTTYPE_STRING + docType + '\'' + ORDERBY_STRING;
            }
            else if(finalStatus.equalsIgnoreCase(Constants.STRING_ALL) && isSignedCheckbox.equalsIgnoreCase(Constants.STRING_ALL) && !docType.equalsIgnoreCase(Constants.STRING_ALL)){ // Doc Type filtered
                QUERY_STRING = SELECT_STRING + WHERE_STRING + AND_STRING + DOCUMENTTYPE_STRING + docType + '\'' + ORDERBY_STRING;
            }
            else if(finalStatus.equalsIgnoreCase(Constants.STRING_ALL) && !isSignedCheckbox.equalsIgnoreCase(Constants.STRING_ALL) && !docType.equalsIgnoreCase(Constants.STRING_ALL)){ // Doc Type and is Signed filtered
                QUERY_STRING = SELECT_STRING + WHERE_STRING + AND_STRING + DOCUMENTTYPE_STRING + docType + '\'' + AND_STRING + ISSIGNED_STRING + isItSigned + ORDERBY_STRING;
            }
            else if(!finalStatus.equalsIgnoreCase(Constants.STRING_ALL) && !isSignedCheckbox.equalsIgnoreCase(Constants.STRING_ALL) && !docType.equalsIgnoreCase(Constants.STRING_ALL)){ // All is filtered
                QUERY_STRING = SELECT_STRING + WHERE_STRING + AND_STRING + DOCUMENTTYPE_STRING + docType + '\'' + AND_STRING + ISSIGNED_STRING + isItSigned + AND_STRING + SIGNATURETYPE_STRING + finalStatus + '\'' + ORDERBY_STRING;
            }
            
            // call Database.query for the query string
            if (String.isNotEmpty(QUERY_STRING)) {
                retCVList = Database.query(QUERY_STRING);
            }
        }
        System.debug('retCVList: ' + retCVList);
        return retCVList;
    }

    /*------------------------------------------------------------
    Author:        Chester Borbon
    Company:       Accenture
    Description:   Redirect to current page after deletion.
    Inputs:        N/A
    Returns:       PageReference - redirect to standard agreement controller detail page
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Chester Borbon     First version.
    ------------------------------------------------------------*/
    public PageReference deleteFile() {
        ContentDocument delContentDoc = [SELECT ID FROM ContentDocument WHERE ID=:cdID];
        delete delContentDoc;
        
        PageReference refreshPage = ApexPages.currentPage();            
        refreshPage.setRedirect(true);
        return refreshPage;
    }

    /*------------------------------------------------------------
    Author:        Chester Borbon
    Company:       Accenture
    Description:   Upload files
    Inputs:        N/A
    Returns:       PageReference - redirect to standard agreement controller detail page
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Chester Borbon     First version.
    ------------------------------------------------------------*/
    public PageReference uploadFile() {

        // Retrieve current page reference
        PageReference refreshPage = ApexPages.currentPage();            
        refreshPage.setRedirect(true);

        // Validate that there is a file for upload
        if(file!=NULL) {
            // Build files objects for insert
            String fileTitle = fileName;
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
            conVer.PathOnClient =  '/'+fileName; // The files name, extension is very important here which will help the file in preview.
            conVer.Title = fileTitle; // Display name of the files
            conVer.VersionData = file; // converting your binary string to Blob
            insert conVer;

            // Query content version's contentdocumentId
            ContentVersion selectCV = [SELECT ID, ContentDocumentID, Title
                                        from ContentVersion
                                        where ID=:conver.ID];
            
            ContentDocumentLink cdlAPTContract = new ContentDocumentLink(ContentDocumentId=selectCV.ContentDocumentID, LinkedEntityId=aptContract.ID,ShareType=SHARE_TYPE_V,Visibility=VISIBILITY_INTERNAL_USERS);
            insert cdlAPTContract;

        } else {
            refreshPage = NULL;
        }
        return refreshPage;  
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
    
    /*************************************************************
     * Description: Sets the string to the selected value in the VisualForce Page
     * Author: JPalmero
     * History:
     * 05/29/2019           Created
     * 06/07/2019           Changed hard-coded strings to use class declared variables
     *************************************************************/
    public void setStatus(){
        finalStatus = selectedType;
        if(ifSigned.equalsIgnoreCase(ISSIGNED_SIGNED)){
            isSignedCheckbox = ISSIGNED_TRUE;
        }
        else if(ifSigned.equalsIgnoreCase(ISSIGNED_UNSIGNED)){
            isSignedCheckbox = ISSIGNED_FALSE;
        }
        else if(ifSigned.equalsIgnoreCase(Constants.STRING_ALL)){
            isSignedCheckBox = Constants.STRING_ALL;
        }
        docType = docuType;
        cvList = getFiles(aptContract, finalStatus, isSignedCheckbox, docuType);
    }
    
    /*************************************************************
     * Description: Sets the string to the selected value in the VisualForce Page
     * Author: JPalmero
     * History:
     * 05/29/2019           Created
     * 06/07/2019           Changed hard-coded strings to use class declared variables
     *************************************************************/
    public void setIsSigned(){
        finalStatus = selectedType;
        if(ifSigned.equalsIgnoreCase(ISSIGNED_SIGNED)){
            isSignedCheckbox = ISSIGNED_TRUE;
        }
        else if(ifSigned.equalsIgnoreCase(ISSIGNED_UNSIGNED)){
            isSignedCheckbox = ISSIGNED_FALSE;
        }
        else if(ifSigned.equalsIgnoreCase(Constants.STRING_ALL)){
            isSignedCheckBox = Constants.STRING_ALL;
        }
        docType = docuType;
        cvList = getFiles(aptContract, finalStatus, isSignedCheckbox, docuType);
    }
    
    /*************************************************************
     * Description: Sets the string to the selected value in the VisualForce Page
     * Author: JPalmero
     * History:
     * 05/29/2019           Created
     * 06/07/2019           Changed hard-coded strings to use class declared variables
     *************************************************************/
    public void setDocType(){
        finalStatus = selectedType;
        if(ifSigned.equalsIgnoreCase(ISSIGNED_SIGNED)){
            isSignedCheckbox = ISSIGNED_TRUE;
        }
        else if(ifSigned.equalsIgnoreCase(ISSIGNED_UNSIGNED)){
            isSignedCheckbox = ISSIGNED_FALSE;
        }
        else if(ifSigned.equalsIgnoreCase(Constants.STRING_ALL)){
            isSignedCheckBox = Constants.STRING_ALL;
        }
        docType = docuType;
        cvList = getFiles(aptContract, finalStatus, isSignedCheckbox, docuType);
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
        
        // Is_Signed__c values
        optionsIfSigned = new List<SelectOption>();
        optionsIfSigned.add(new SelectOption('All', 'All'));
        optionsIfSigned.add(new SelectOption('Signed', 'Signed'));
        optionsIfSigned.add(new SelectOption('Unsigned', 'Unsigned'));
    }
}