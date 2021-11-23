/**
* @author Ranjeewa Silva
* @date 2021-02-04
* @description Batch class for retrieving Startrack credit claim supporting documents specified in the disputed credit claims
*              csv file uploaded via the bulk upload tool. Document urls (public urls only) can be specified with each of the
*             csv line item.
* @changelog
* 2021-02-04 - Ranjeewa Silva - Created.
*/
public with sharing class RetrieveDisputedCreditDocumentsBatchable implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    // list of newly created Disputed Credit Claim Case Ids where supporting documents may need to be downloaded and attached.
    // supporting document urls are captured in child disputed item (Disputed_Item__c) records.
    List<Id> disputedCreditClaimIds;

    // collection of public urls and related case Ids which has been retrieved by this instance of batchable class.
    // this collection is checked to avoid duplicate documents getting attached to a given case.
    Map<String, Set<Id>> linkedCaseIdsByRetrievedDocumentURL;

    // if set to true, save application logs for analysis.
    Boolean enableApplicationLogs = false;

    // maximum file size supported. if the document url is pointing to a file larger than the supported file size, the
    // file is ignored. log record is generated if application logs is enabled.
    Integer maximumFileSize = Integer.valueOf(2.0 * 1024 * 1024);

    // request time out on the callout to retrieve the document.
    Integer requestTimeOut = 10000;

    // application logs collected during execution.
    private List<Application_Log__c> applicationLogs = new List<Application_Log__c>();

    public RetrieveDisputedCreditDocumentsBatchable(List<Id> caseIds, Decimal maximumFileSizeInMB, Integer requestTimeOutInSeconds, Boolean enableApplicationLogs) {
        this.disputedCreditClaimIds = caseIds;
        this.linkedCaseIdsByRetrievedDocumentURL = new Map<String, Set<Id>>();

        if (maximumFileSizeInMB != null) {
            this.maximumFileSize = Integer.valueOf(maximumFileSizeInMB * 1024 * 1024);
        }

        if (requestTimeOutInSeconds != null) {
            this.requestTimeOut = requestTimeOutInSeconds * 1000;
        }

        if (enableApplicationLogs != null) {
            this.enableApplicationLogs = enableApplicationLogs;
        }
    }

    public Database.QueryLocator start(Database.BatchableContext ctx) {

        // return a query locator for Disputed Items linked to the Cases passed In.
        DisputedItemsSelector disputedItemsSelector = DisputedItemsSelector.newInstance(0, new Set<SObjectField>{Disputed_Item__c.Id, Disputed_Item__c.Case__c, Disputed_Item__c.SupportingDocumentDownloadURL__c});
        return disputedItemsSelector.selectByCaseIdQueryLocator(new Set<Id>(disputedCreditClaimIds), new Set<Object>());
    }

    public void execute(Database.BatchableContext ctx, List<SObject> scope) {

        try {

            List<Disputed_Item__c> disputedItems = (List<Disputed_Item__c>) scope;

            // iterate over the list of disputed items and gather a list of supporting document urls that need to be retrieved
            // together with the list of cases the document needs to be attached.
            Map<String, Set<Id>> documentsToRetrieve = new Map<String, Set<Id>>();

            for (Disputed_Item__c disputedItem : disputedItems) {

                if (String.isNotEmpty(disputedItem.SupportingDocumentDownloadURL__c)) {

                    // supporting document url is specified for the disputed item.
                    String documentUrl = disputedItem.SupportingDocumentDownloadURL__c.trim();

                    // check if this document is already retrieved during current run. it is possible that the same url may be specified
                    // for multiple disputed items related to the case. in this scenario we only need to download the document once.
                    if (this.linkedCaseIdsByRetrievedDocumentURL.containsKey(documentUrl) && this.linkedCaseIdsByRetrievedDocumentURL.get(documentUrl).contains(disputedItem.Case__c)) {
                        // current document is already linked to case - nothing to do here.
                        continue;
                    }

                    Set<Id> parentCaseIds = documentsToRetrieve.get(documentUrl);
                    if (parentCaseIds == null) {
                        parentCaseIds = new Set<Id>();
                        documentsToRetrieve.put(documentUrl, parentCaseIds);
                    }
                    parentCaseIds.add(disputedItem.Case__c);
                }
            }

            if (!documentsToRetrieve.isEmpty()) {
                // found document urls specified in disputed items. retrieve documents and insert Salesforce file and link
                // to the relevant case records.
                List<SupportingDocument> documents = retrieveDocuments(documentsToRetrieve);
                insertContentDocumentsAndLinkToCases(documents);
            }
        } catch (Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Customer Resolutions', RetrieveDisputedCreditDocumentsBatchable.class.getName(), 'execute', null, LoggingLevel.ERROR);
        } finally {
            saveApplicationLogs();
        }
    }

    public void finish(Database.BatchableContext ctx) {
    }

    /**
     * Insert retrieved document content as Salesforce files (i.e. ContentVersion / ContentDocument and ContentDocumentLink).
     *
     * @param documents list of documents to be created as Salesforce files.
     */
    private void insertContentDocumentsAndLinkToCases(List<SupportingDocument> documents) {

        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        for (SupportingDocument document: documents) {
            if (document.contentVersion != null) {
                contentVersionsToInsert.add(document.contentVersion);
            }
        }

        if (!contentVersionsToInsert.isEmpty()) {

            // insert ContentVersion records.
            ApplicationDatabase.getInstance().dmlInsert(contentVersionsToInsert, false);

            Set<Id> contentVersionIds = new Map<Id,ContentVersion>(contentVersionsToInsert).keySet();

            // query inserted content versions to retrieve the ContentDocumentId for each of the content version.
            // use retrieved ContentDocumentId in ContentDocumentLink records to relate the file to relevant Cases
            ContentVersionsSelector contentVersionsSelector = ContentVersionsSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>> {ContentVersion.SObjectType => new Set<SObjectField>{ContentVersion.Id, ContentVersion.ContentDocumentId}});
            Map<Id, ContentVersion> contentVersionsWithDocumentIds = contentVersionsSelector.selectById(contentVersionIds);

            List<ContentDocumentLink> contentDocumentLinks = newContentDocumentLinksToInsert(documents, contentVersionsWithDocumentIds);
            if (!contentDocumentLinks.isEmpty()) {
                ApplicationDatabase.getInstance().dmlInsert(contentDocumentLinks, false);

                // document retrieval is now complete for the current batch of disputed items.
                // collect the urls and related case ids for the documents retrieved for current batch, so that we could prevent
                // duplicating documents on the same case if same url / case id combination is specified in a disputed item included in another batch.
                populateDocumentsSuccessfullyRetrievedInCurrentBatch(documents);
            }
        }
    }

    private List<ContentDocumentLink> newContentDocumentLinksToInsert(List<SupportingDocument> documents, Map<Id, ContentVersion> contentVersionsWithDocumentIds) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

        for (SupportingDocument document: documents) {
            if (document.contentVersion.Id != null && contentVersionsWithDocumentIds.containsKey(document.contentVersion.Id)) {
                for (Id caseId: document.caseIds) {
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = contentVersionsWithDocumentIds.get(document.contentVersion.Id).ContentDocumentId;
                    cdl.LinkedEntityId = caseId;
                    document.contentDocumentLinks.add(cdl);
                    contentDocumentLinks.add(cdl);
                }
            }
        }
        return contentDocumentLinks;
    }

    private List<SupportingDocument> retrieveDocuments(Map<String, Set<Id>> documentsToRetrieve) {
        List<SupportingDocument> supportingDocuments = new List<SupportingDocument>();
        for (String documentUrl: documentsToRetrieve.keySet()) {
            HttpRequest req = getHttpRequest(documentUrl);
            Http http = new Http();
            HttpResponse resp = http.send(req);
            if (resp.getStatusCode() == 200) {
                String fileName = getSupportingDocumentFileName(resp, documentUrl);
                SupportingDocument document = new SupportingDocument(documentUrl, documentsToRetrieve.get(documentUrl), resp.getBodyAsBlob(), fileName);
                if (document.contentVersion.VersionData.size() <= maximumFileSize) {
                    supportingDocuments.add(document);
                } else {
                    String message = 'Size exceed the maximum size supported. Ignoring document [URL = ' + documentUrl + '].';
                    Id referenceId = documentsToRetrieve.get(documentUrl) != null ? new List<Id>(documentsToRetrieve.get(documentUrl))[0] : null;
                    applicationLogs.add(new Application_Log__c(Reference_Id__c = referenceId, Debug_Level__c = 'Info', Source__c = RetrieveDisputedCreditDocumentsBatchable.class.getName(), Source_Function__c = 'retrieveDocuments', Reference_Information__c = 'Case', Message__c = message));
                }
            } else {
                String message = 'Unable to access endpoint URL - ' + documentUrl + ' [ Status Code = ' + resp.getStatusCode() + '; Status = ' + resp.getStatus() + '];';
                Id referenceId = documentsToRetrieve.get(documentUrl) != null ? new List<Id>(documentsToRetrieve.get(documentUrl))[0] : null;
                applicationLogs.add(new Application_Log__c(Reference_Id__c = referenceId, Debug_Level__c = 'Info', Source__c = RetrieveDisputedCreditDocumentsBatchable.class.getName(), Source_Function__c = 'retrieveDocuments', Reference_Information__c = 'Case', Message__c = message));
            }
        }

        return supportingDocuments;
    }

    private void populateDocumentsSuccessfullyRetrievedInCurrentBatch(List<SupportingDocument> documents) {

        for (SupportingDocument document: documents) {
            if (document.contentVersion.Id != null) {
                for (ContentDocumentLink cdl: document.contentDocumentLinks) {
                    if (cdl.Id != null) {
                        Set<Id> caseIdsForDocumentUrl = this.linkedCaseIdsByRetrievedDocumentURL.get(document.url);
                        if (caseIdsForDocumentUrl == null) {
                            caseIdsForDocumentUrl = new Set<Id>();
                            this.linkedCaseIdsByRetrievedDocumentURL.put(document.url, caseIdsForDocumentUrl);
                        }
                        caseIdsForDocumentUrl.add(cdl.LinkedEntityId);
                    }
                }
            }
        }
    }

    private HttpRequest getHttpRequest(String url) {

        System.Debug('>>> Supporting Document Public URL: ' + url);

        HttpRequest req = new HttpRequest();
        req.setTimeout(requestTimeOut);
        //req.setHeader('Authorization', login.get('auth'));
        req.setEndpoint(url);
        req.setMethod('GET');
        return req;
    }

    private String getSupportingDocumentFileName(HttpResponse response, String documentUrl) {
        String fileName =  (documentUrl.contains('/') ? documentUrl.substringAfterLast('/'): documentUrl);
        String contentDisposition = getHeaderValue(response, 'Content-Disposition');
        if (contentDisposition != null) {
            // content disposition header is available in response. extract filename from content disposition.
            Pattern p = Pattern.compile('filename[^;=\\n]*=(([\'"]).*?\\2|[^;\\n]*)');
            Matcher m = p.matcher(contentDisposition);
            if(m.find()) {
                fileName = m.group(1);
                fileName = fileName.replaceAll('["\']', '');
            }
        }
        return fileName;
    }

    private String getHeaderValue(HttpResponse response, String headerName) {
        for (String headerKey: response.getHeaderKeys()) {
            if (headerKey.equalsIgnoreCase(headerName)) {
                return response.getHeader(headerKey);
            }
        }
        return null;
    }

    private void saveApplicationLogs() {
        if(!applicationLogs.isEmpty() && enableApplicationLogs) {
            List<Database.SaveResult> results = ApplicationDatabase.getInstance().dmlInsert(applicationLogs, false);
            System.debug('log results: ' + results);
        }

        applicationLogs.clear();
    }

    private class SupportingDocument {
        String url;
        ContentVersion contentVersion;
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        Set<Id> caseIds;

        private SupportingDocument(String url, Set<Id> caseIds, Blob documentContent, String fileName) {
            this.url = url;
            this.caseIds = caseIds;
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.VersionData = documentContent;
            contentVersion.PathOnClient = fileName;
            contentVersion.Title = contentVersion.PathOnClient;
            this.contentVersion = contentVersion;
        }
    }

}