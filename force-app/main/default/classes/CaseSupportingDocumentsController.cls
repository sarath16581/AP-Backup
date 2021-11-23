/**
 * @author Ranjeewa Silva
 * @date 2021-02-12
 * @tag Case
 * @description Controller for supporting document upload on cases.
 * @changelog
 * 2020-02-12 - Ranjeewa Silva - Created
 */
public with sharing class CaseSupportingDocumentsController {

    /**
     * Search Cases and return case details
     *
     * @param searchTerms search terms for looking up cases. search term could be a case number or a case reference id
     * @param recordTypeIds filter the records based on the record types. passing an empty list bypasses record type filter.
     * @return map of case records indexed by search term. Only Id,Case Number and Reference Id fields are populated in case records returned.
     */
    @AuraEnabled
    public static Map<String, List<Case>> searchCases(List<String> searchTerms, List<Id> recordTypeIds) {
        Map<String, List<Case>> results = new Map<String, List<Case>>();
        Map<Id,Case> cases = CasesSelector.newInstance(new Set<SObjectField>{Case.Id, Case.RecordTypeId, Case.CaseNumber, Case.ReferenceID__c}).selectOpenCasesByCaseNumberOrReferenceId(new Set<String>(searchTerms), new Set<Id>(recordTypeIds), new Set<Object>{CasesSelector.Options.WITH_RECORDTYPE});
        for (Case c: cases.values()) {
            String matchedSearchTerm = null;
            if (searchTerms.contains(c.CaseNumber)) {
                // case matched by case number.
                matchedSearchTerm = c.CaseNumber;
            } else if (searchTerms.contains(c.ReferenceID__c)) {
                // case matched by reference id
                matchedSearchTerm = c.ReferenceID__c;
            }

            if (!results.containsKey(matchedSearchTerm)) {
                results.put(matchedSearchTerm, new List<Case>());
            }
            results.get(matchedSearchTerm).add(c);
        }
        return results;
    }

    /**
     * Upload supporting document and link to the case
     *
     * @param caseId Id of the case to link the document
     * @param fileContentBase64 Base64 encoded file contents
     * @param fileName file name
     */
    @AuraEnabled
    public static void uploadSupportingDocument(Id caseId, String fileContentBase64, String fileName) {

        try {
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.VersionData = EncodingUtil.base64Decode(fileContentBase64);
            contentVersion.Title = fileName;
            contentVersion.PathOnClient = fileName;
            contentVersion.FirstPublishLocationId = caseId;
            ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{contentVersion});
        } catch (Exception ex) {
            AuraHandledException auraEx = new AuraHandledException(ex.getMessage());
            auraEx.initCause(ex);
            throw auraEx;
        }
    }

}