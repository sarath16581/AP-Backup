/**
 *
 *     @author Hasantha Liyanage
 *     @date 2023-07-17
 *     @group lwc
 *     @tag apex controller
 *     @tag Attachments
 *     @domain ui
 *     @description support listing attachments and selecting them for the compensation record
 *     @changelog
 *     2023-07-17 - hasantha.liyanage@auspost.com.au - Created
 *
 */
public with sharing class CompensationAttachmentsController {

    public static final Boolean isCompensationUser {
        get {
            if(isCompensationUser == null) {
                isCompensationUser = FeatureManagement.checkPermission('Is_Compensation_User');
            }
            return isCompensationUser;
        }
        private set;
    }
    public static final Boolean IsCompensationSupervisor {
        get {
            if(isCompensationSupervisor == null) {
                isCompensationSupervisor = FeatureManagement.checkPermission('Is_Compensation_Supervisor');
            }
            return isCompensationSupervisor;
        }
        private set;
    }

    @AuraEnabled
    public static PageConfig getPageConfig() {
        PageConfig config = new PageConfig();
        if (isCompensationUser || isCompensationSupervisor) {
            config.isAllowedToCreateCompensation = true;
        } else {
            config.isAllowedToCreateCompensation = false;
        }
        return config;
    }

    @AuraEnabled
    public static List<AttachmentDetail> getAttachmentsByParentId(Id recordId) {
        Compensation__c compensation = CompensationSelector.newInstance(1).getById(recordId, new Set<Object>())[0];
        if (compensation == null || compensation.Case__c == null) {
            return new List<AttachmentDetail>();
        }


        Map<Id, Attachment> caseAttachments = AttachmentsSelector.newInstance().selectByParentId(new Set<Id>{
                compensation.Case__c
        });
        Map<Id, Attachment> compensationAttachments = AttachmentsSelector.newInstance().selectByParentId(new Set<Id>{
                recordId
        });

        List<AttachmentDetail> attachmentDetails = new List<AttachmentDetail>();
        for (Attachment caseAttachment : caseAttachments.values()) {
            AttachmentDetail detail = new AttachmentDetail();
            detail.BodyLength = caseAttachment.BodyLength;
            detail.ContentType = caseAttachment.ContentType;
            detail.CreatedDate = caseAttachment.CreatedDate;
            detail.Id = caseAttachment.Id;
            detail.Name = caseAttachment.Name;
            detail.ParentId = caseAttachment.ParentId;
            detail.isAttachment = true;
            for (Attachment compensationAttachment : compensationAttachments.values()) {
                if (caseAttachment.Name == compensationAttachment.Name) {
                    detail.isSelected = true;
                }
            }
            attachmentDetails.add(detail);
        }




        List<ContentDocumentLink> caseContentDocumentLinks = ContentDocumentLinksSelector.newInstance().search(
                new Map<String, Object>{'entityIds' => compensation.Case__c },
                new Set<Object>{ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT},
                true).values();
        List<ContentDocumentLink> compensationContentDocumentLinks = ContentDocumentLinksSelector.newInstance().search(
                new Map<String, Object>{'entityIds' => recordId },
                new Set<Object>{ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT},
                true).values();


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

        return attachmentDetails;
    }

    // TODO UOW
    @AuraEnabled
    public static void createDuplicateAttachments(List<AttachmentDetail> attachmentDetails, Id recordId) {

        system.debug('attachmentDetails  '+attachmentDetails);
        Set<Id> attachmentIds = new Set<Id>();
        Compensation__c compensation;
        List<ContentDocumentLink> contentLinks = new List<ContentDocumentLink>();
        for (AttachmentDetail detail : attachmentDetails) {
            if(detail.isSelectedNew) {
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
                if(!detail.isSelected) {
                    compensation = new Compensation__c (Id = recordId, Proof_of_Value__c = true);
                }
            }

        }

        if(!contentLinks.isEmpty()) {
            insert contentLinks;
        }

        Map<Id, Attachment> attachmentsToDuplicate = AttachmentsSelector.newInstance().selectById(attachmentIds, new Set<Object>{AttachmentsSelector.Options.WITH_BODY});
        List<Attachment> duplicateAttachments = new List<Attachment>();

        for (Attachment attachment : attachmentsToDuplicate.values()) {
            Attachment newAttachment = attachment.clone(false);
            newAttachment.ParentId = recordId;
            duplicateAttachments.add(newAttachment);
        }

        if(!duplicateAttachments.isEmpty()) {
            insert duplicateAttachments;
        }

        if(compensation != null) {
            update compensation;
        }
    }


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
        @AuraEnabled public Boolean isAttachment {get;set;}
        @AuraEnabled public Integer BodyLength {get;set;}
        @AuraEnabled public String ContentType {get;set;}
        @AuraEnabled public Datetime CreatedDate {get;set;}
        @AuraEnabled public String Id {get;set;}
        @AuraEnabled public String Name {get;set;}
        @AuraEnabled public String ParentId {get;set;}
    }

    public class PageConfig {
        @AuraEnabled public Boolean isAllowedToCreateCompensation {get;set;}
    }
}
