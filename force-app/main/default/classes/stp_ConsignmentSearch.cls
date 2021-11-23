/**************************************************
Description:    Controller Class for Lightning components Startrack Consignment search

History:
--------------------------------------------------
2018-09-18  clint.dsilva@auspost.com.au Created
2019-01-02  hasantha.liyanage@auspost.com.au modified all the methods

**************************************************/
public without sharing class stp_ConsignmentSearch {

    public stp_ConsignmentSearch() {}

    /**
     * read PODs from Proof_of_Delivery__c table and access the attachments of it.
     * NOTE: Startrack PODs are attachments while AP Pod is a text field stores a base 64 on the object itself
     *
     * @param consignmentId
     *
     * @return
     */
    @AuraEnabled
    public static list < ProofOfDeliveryDTO > getPOD(string consignmentId) {
        try {
            List < String > relatedPODFields = new List < String > ();
            // reading feild set
            for (Schema.FieldSetMember fsm: SObjectType.Proof_of_Delivery__c.FieldSets.getMap().get('Startrack_Portal_PODs').getFields()) {
                relatedPODFields.add(fsm.getFieldPath());
            }

            if (relatedPODFields.size() > 0) {
                String podQuery = 'SELECT ' + String.join(relatedPODFields, ',') + ', (SELECT Id, ParentId, Title FROM NotesAndAttachments ORDER BY CreatedDate DESC LIMIT 1) FROM Proof_of_Delivery__c WHERE Consignment__c = \'' + consignmentId + '\' ORDER BY POD_Received_Date__c DESC';

                // let's get a map so I can access the id set to pull the attachments
                Map < Id, Proof_of_Delivery__c > relatedPODs = new Map < Id, Proof_of_Delivery__c > (
                        (List < Proof_of_Delivery__c > ) Database.query(podQuery)
                );
                //StarTrack_Related_PODs

                // query related attachments to access the images
                list < Attachment > attachments = [SELECT Id, ParentId, Body FROM Attachment WHERE ParentId =: relatedPODs.keySet()];

                //pod data transfer object
                List < ProofOfDeliveryDTO > pods = new List < ProofOfDeliveryDTO > ();

                // need an iteration to fin the related attachment of the POD
                for (String podId: relatedPODs.keySet()) {
                    // create a new ProofOfDelivery wrapper an assign the pod
                    ProofOfDeliveryDTO proofOfDelivery = new ProofOfDeliveryDTO();
                    pods.add(proofOfDelivery);
                    proofOfDelivery.pod = relatedPODs.get(podId);

                    for (Attachment attachment: attachments) {
                        if (attachment.ParentId == podId) {
                            // get the base 64 image to  render and display image in the table
                            proofOfDelivery.imageBase64 = EncodingUtil.base64Encode(attachment.Body);
                        }
                    }
                }

                return pods;
            }

            return null;
        } catch (Exception ex) {
            system.debug('[StarTrackPortalConsignmentSearch] : getConsignmentEvents() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * get consignment events by consignment id, EventMessage__c records are queried based on the consignment id passed.
     *
     * @param consignmentId
     *
     * @return
     **/
    @AuraEnabled
    public static List < EventMessage__c > getConsignmentEvents(String consignmentId) {
        try {
            List < EventMessage__c > eventMessages = new List < EventMessage__c > ();
            List < String > eventMessageFields = new List < String > ();

            for (Schema.FieldSetMember fsm: SObjectType.EventMessage__c.FieldSets.getMap().get('StarTrack_Consignment_Events').getFields()) {
                eventMessageFields.add(fsm.getFieldPath());
            }

            if (eventMessageFields.size() > 0) {
                String query = 'SELECT ' + String.join(eventMessageFields, ',') + ' ,Article__r.ArticleID__c, Article__r.Name ,(select id,name,msg_description__c,msg_name__c from Article_Attachment_Details__r) FROM EventMessage__c WHERE Article__c = \'' + consignmentId + '\' ORDER BY LastModifiedDate DESC';
                eventMessages = Database.query(query);
            }
            return eventMessages;
        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[StarTrackPortalConsignmentSearch] : getConsignmentEvents() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * get article events by consignment id, EventMessage__c records are queried based on the consignment id passed,
     * then the article id determined by the consignment's article ids.
     *
     * @param consignmentId
     *
     * @return
     **/
    @AuraEnabled
    public static List < EventMessage__c > getArticleEvents(String consignmentId) {
        try {
            // get the related articles, getting the map so we could access the id set
            Map < Id, Article__c > relatedArticles = new Map < Id, Article__c > ([
                    SELECT Id, ArticleID__c
                    FROM Article__c
                    WHERE Consignment__c =: consignmentId AND RecordType.DeveloperName = 'Article'
            ]);
            Set < Id > articleIds = relatedArticles.keySet();

            List < EventMessage__c > eventMessages = new List < EventMessage__c > ();
            List < String > eventMessageFields = new List < String > ();

            // get filed names to query
            for (Schema.FieldSetMember fsm: SObjectType.EventMessage__c.FieldSets.getMap().get('StarTrack_Consignment_Events').getFields()) {
                eventMessageFields.add(fsm.getFieldPath());
            }

            // if the fields are found in fieldSet anf the related articles are found to query, pass the articleIds and retrieve the related article events
            if (eventMessageFields.size() > 0 && relatedArticles.size() > 0) {
                String query = 'SELECT ' + String.join(eventMessageFields, ',') + ', Article__r.ArticleID__c, Article__r.Name ,(select id,name,msg_description__c,msg_name__c from Article_Attachment_Details__r) FROM EventMessage__c WHERE Article__c IN : articleIds  ORDER BY LastModifiedDate DESC';
                system.debug(query);
                eventMessages = Database.query(query);
            }
            return eventMessages;
        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[StarTrackPortalConsignmentSearch] : getArticleEvents() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }


    /**
     * read the fieldset based on the object name and the fieldset name provided, be used in the
     * SOQL queries and columns for lightning dataTable, if you need to make adjustments to behaviour of the table columns
     * hree's the place for it.
     *
     * @param fieldSetName
     * @param objectName
     * @param isStandard : if you want to get the standard FieldSet or the FieldSet in a custom mapped format
     *
     * @return Object contains the fields set values to be displayed
     */
    @AuraEnabled
    public static Object readFieldSet(String fieldSetName, String objectName, Boolean isStandard) {
        try {
            // read the Schema and access the requested field set of the object provided
            Map < String, Schema.SObjectType > GlobalDescribeMap = Schema.getGlobalDescribe();
            Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
            Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
            Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

            // if the standard field set is requested
            if (isStandard != null && isStandard) {
                return JSON.deserializeUntyped(JSON.serialize(fieldSetObj.getFields()));
            }

            // prepare field set details to be returned
            List < FieldSets > fieldSets = new List < FieldSets > ();

            // if the requested field set and/or object is not found
            if (fieldSetObj == null) {
                return '{error:FielsSet is blank or Object name is blank}';
            }

            // read field set's fields.
            for (Schema.FieldSetMember field: fieldSetObj.getFields()) {
                FieldSets fields = new FieldSets();
                fields.type = String.valueOf(field.getType());
                fields.label = field.getLabel();
                fields.fieldName = field.getFieldPath();
                fieldSets.add(fields);
            }

            // Lightning:datatable binding
            // Adding Article related fields in, Since this is from the parent object
            FieldSets fields = new FieldSets();
            fields.type = 'Text';
            fields.label = 'Article ID';
            fields.fieldName = 'ArticleId';
            fieldSets.add(fields);



            return JSON.deserializeUntyped(JSON.serialize(fieldSets));
        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[StarTrackPortalConsignmentSearch] : readFieldSet() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * Data Transfer Object instance for field set details
     */
    public with sharing class FieldSets {
        @AuraEnabled public String type {
            get;
            set;
        }
        @AuraEnabled public String label {
            get;
            set;
        }
        @AuraEnabled public String fieldName {
            get;
            set;
        }
    }

    /**
     * Data Transfer Object instance for POD details
     */
    public without sharing class ProofOfDeliveryDTO {
        @AuraEnabled public Proof_of_Delivery__c pod;
        @AuraEnabled public String imageBase64;
    }
}