/**
 * @author Hasantha Liyanage
 * @date 2023-07-17
 * @group lwc
 * @tag apex controller
 * @tag Attachments
 * @domain ui
 * @description support listing attachments and selecting them for the compensation record
 * @changelog
 * 2023-07-17 - hasantha.liyanage@auspost.com.au - Created
 * 2023-11-06 - hasantha.liyanage@auspost.com.au - Modified: update getAttachmentDetails method to get the attachments on the EmailMessage
 */
public with sharing class CompensationAttachmentsController {

    public static final Boolean isCompensationUser {
        get {
            if (isCompensationUser == null) {
                isCompensationUser = FeatureManagement.checkPermission('Is_Compensation_User');
            }
            return isCompensationUser;
        }
        private set;
    }

    public static final Boolean IsCompensationSupervisor {
        get {
            if (isCompensationSupervisor == null) {
                isCompensationSupervisor = FeatureManagement.checkPermission('Is_Compensation_Supervisor');
            }
            return isCompensationSupervisor;
        }
        private set;
    }

    public static Set<Id> RESTRICTED_COMPENSATION_RECORD_TYPES {
        get {
            if(RESTRICTED_COMPENSATION_RECORD_TYPES == null) {
                RESTRICTED_COMPENSATION_RECORD_TYPES = RecordTypesSelector.newInstance().selectByDeveloperName(
                        'Compensation__c',
                        new Set<String>{'EFT','Load_and_Go','Money_Order','Money_Order_Number_Required'}).keySet();
            }
            return RESTRICTED_COMPENSATION_RECORD_TYPES;
        }
        private set;
    }

    /**
     * pass the common configurations for the componsnt
     * @return PageConfig
     */
    @AuraEnabled
    public static PageConfig getPageConfig(Id recordId) {
        PageConfig config = new PageConfig();
        Compensation__c compensation = CompensationSelector.newInstance(1).getById(recordId, new Set<Object>())[0];
        if ((isCompensationUser || isCompensationSupervisor) || !RESTRICTED_COMPENSATION_RECORD_TYPES.contains(compensation.RecordTypeId)) {
            config.isAllowedToCreateCompensation = true;
        } else {
            config.isAllowedToCreateCompensation = false;
        }
        config.compensation = compensation;
        return config;
    }

    /**
     *  Prepare and return the AttachmentDetail wrapper after retrieving and comparing Attachments and Files linked to the case
     *  and the compensation record, any existing files/attachments linked to the compensations should not be allowed to de-select from the table
     * @param recordId compensation record ID
     *
     * @return List<AttachmentDetail>
     */
    @AuraEnabled
    public static List<AttachmentDetail> getAttachmentsByParentId(Compensation__c compensation) {
        List<AttachmentDetail> attachmentDetails = new List<AttachmentDetail>();
        if (compensation == null || compensation.Case__c == null) {
            return new List<AttachmentDetail>();
        }

        // get attachment details
        getAttachmentDetails(compensation, attachmentDetails);
        // get file details
        getFileAttachmentDetails(compensation, attachmentDetails);

        return attachmentDetails;
    }
    /**
     * Get file details
     * @param compensation
     * @param attachmentDetails
     */
    @TestVisible
    private static void getFileAttachmentDetails(Compensation__c compensation, List<AttachmentDetail> attachmentDetails) {
        // get files related to related case
        List<ContentDocumentLink> caseContentDocumentLinks = getContentDocumentLinksWithDocuments(compensation.Case__c);
        // get files related to compensation
        List<ContentDocumentLink> compensationContentDocumentLinks = getContentDocumentLinksWithDocuments(compensation.Id);

        // compare files and prepare the attachment details
        for (ContentDocumentLink contentDocumentLink : caseContentDocumentLinks) {
            AttachmentDetail detail = new AttachmentDetail();
            detail.BodyLength = contentDocumentLink.ContentDocument.ContentSize;
            detail.ContentType = contentDocumentLink.ContentDocument.FileType;
            detail.CreatedDate = contentDocumentLink.ContentDocument.CreatedDate;
            detail.Id = contentDocumentLink.ContentDocumentId;
            detail.Name = contentDocumentLink.ContentDocument.Title;
            detail.ParentId = contentDocumentLink.LinkedEntityId;
            detail.isAttachment = false;
            for (ContentDocumentLink compensationContentDocumentLink : compensationContentDocumentLinks) {
                if (contentDocumentLink.ContentDocument.Id == compensationContentDocumentLink.ContentDocument.Id) {
                    detail.isSelected = true;
                }
            }
            attachmentDetails.add(detail);
        }
    }

    /**
     * Get content documents with content documents per passed Id
     * @param entityId
     *
     * @return
     */
    private static List<ContentDocumentLink> getContentDocumentLinksWithDocuments(Id entityId) {
        Map<Id, ContentDocumentLink> caseContentDocumentLinks = ContentDocumentLinksSelector.newInstance().search(
                new Map<String, Object>{
                        'entityIds' => entityId
                },
                new Set<Object>{
                        ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT
                },
                true);
        return caseContentDocumentLinks != null ? caseContentDocumentLinks.values() : new List<ContentDocumentLink>();
    }

    /**
     * get attachment details
     * @param compensation current compensation record
     * @param attachmentDetails to storeattachment details
     */
   @TestVisible
    private static void getAttachmentDetails(Compensation__c compensation, List<AttachmentDetail> attachmentDetails) {
        Set<Id> emailMessageIds = new Set<Id>();
        Set<Id> parentIds = new Set<Id>();
        for(EmailMessage message :  EmailMessagesSelector.newInstance().selectByParentIds(new Set<Id>{compensation.Case__c},
                new Set<Object>())) {
            emailMessageIds.add(message.Id);
        }

        parentIds.addAll(emailMessageIds);
        parentIds.add(compensation.Case__c);
        parentIds.add(compensation.Id);
        // get attachments related to related case
        List<Attachment> allAttachments = AttachmentsSelector.newInstance().selectByParentId(parentIds);

        // group all attachments by parent Id to ignore the already created compensation attachments
        Map<Id, List<Attachment>> attachmentsByParentId = new Map<Id, List<Attachment>>();
        for (Attachment attachment : allAttachments) {
            Id parentId = attachment.ParentId;
            if (!attachmentsByParentId.containsKey(parentId)) {
                attachmentsByParentId.put(parentId, new List<Attachment>());
            }
            attachmentsByParentId.get(parentId).add(attachment);
        }

        // compare attachments and prepare the attachment details
        for (Id parentId : attachmentsByParentId.keySet()) {
            // do not need to list anything already on the compensation record
            if(parentId == compensation.Id) {
                continue;
            }
            for (Attachment attachment : attachmentsByParentId.get(parentId)) {
                AttachmentDetail detail = new AttachmentDetail();
                detail.BodyLength = attachment.BodyLength;
                detail.ContentType = attachment.ContentType;
                detail.CreatedDate = attachment.CreatedDate;
                detail.Id = attachment.Id;
                detail.Name = attachment.Name;
                detail.ParentId = attachment.ParentId;
                detail.isAttachment = true;

                // mark as selected when the attachment is already on compensation record
                if(attachmentsByParentId.get(compensation.Id) != null) {
                    for (Attachment attachment2 : attachmentsByParentId.get(compensation.Id)) {
                        if (attachment.Name == attachment2.Name) {
                            detail.isSelected = true;
                        }
                    }
                }

                attachmentDetails.add(detail);
            }
        }
    }

    /**
     * Create/link selected attachments/files against the compensation record
     */
    @AuraEnabled
    public static void createAttachments(List<AttachmentDetail> attachmentDetails, Id recordId) {

        Set<Id> attachmentIds = new Set<Id>();
        Compensation__c compensation;
        List<ContentDocumentLink> contentLinks = new List<ContentDocumentLink>();
        // read the attachment details passed and deviate between attachments and files
        for (AttachmentDetail detail : attachmentDetails) {
            if (detail.isSelectedNew) {
                // if the selected file is an attachment
                if (detail.isAttachment) {
                    attachmentIds.add(detail.Id);
                } else {
                    // otherwise salesforce files
                    ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                    contentDocumentLink.LinkedEntityId = recordId;
                    contentDocumentLink.ContentDocumentId = detail.Id;
                    contentDocumentLink.shareType = 'V';
                    contentLinks.add(contentDocumentLink);
                }

                // if the first time selection and no existing attachments, then update the POV checkbox
                if (!detail.isSelected) {
                    compensation = new Compensation__c (Id = recordId, Proof_of_Value__c = true);
                }
            }

        }

        // link the files found to the compensation
        if (!contentLinks.isEmpty()) {
            ApplicationDatabase.getInstance().dmlInsert(contentLinks);
        }

        // restive attachments to create duplicate attachments
        Map<Id, Attachment> attachmentsToDuplicate = AttachmentsSelector.newInstance().selectById(attachmentIds, new Set<Object>{
                AttachmentsSelector.Options.WITH_BODY
        });
        List<Attachment> duplicateAttachments = new List<Attachment>();

        if (attachmentsToDuplicate != null) {
            // prepare clones
            for (Attachment attachment : attachmentsToDuplicate.values()) {
                Attachment newAttachment = attachment.clone(false);
                newAttachment.ParentId = recordId;
                duplicateAttachments.add(newAttachment);
            }
        }

        // create new attachments against compensation record
        if (!duplicateAttachments.isEmpty()) {
            ApplicationDatabase.getInstance().dmlInsert(duplicateAttachments);
        }

        // update the POV checkbox if there is at least one of attachment OR file is selected
        if (compensation != null) {
            ApplicationDatabase.getInstance().dmlUpdate(new List<Compensation__c>{
                    compensation
            });
        }
    }

    /**
     *  Wrapper class to store attachment/file data to pass between apex class and the lwc component
     */
    public class AttachmentDetail {
        @AuraEnabled public Boolean isSelected {
            get {
                if (isSelected == null) {
                    return false;
                }
                return isSelected;
            }
            set;
        }
        @AuraEnabled public Boolean isSelectedNew {
            get {
                if (isSelectedNew == null) {
                    return false;
                }
                return isSelectedNew;
            }
            set;
        }
        @AuraEnabled public Boolean isAttachment { get; set; }
        @AuraEnabled public Integer bodyLength { get; set; }
        @AuraEnabled public String contentType { get; set; }
        @AuraEnabled public Datetime createdDate { get; set; }
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String parentId { get; set; }
    }

    /**
     * any configurations needs to pass to the front end
     */
    public class PageConfig {
        @AuraEnabled public Boolean isAllowedToCreateCompensation { get; set; }
        @AuraEnabled public Compensation__c compensation { get; set; }
    }
}