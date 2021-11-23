/**
*
@author Jerry Huang
@created 2015-12-22
@version 1.0
*
@changelog
* 2015-12-22 created
*/
public class ProofOfDeliveryUtil {

    public static void createSignatureAttachments(Map<Id, Proof_of_Delivery__c> pods) {
    //public static Id createSignatureAttachments(List<Proof_of_Delivery__c> pods) {

        List<Attachment> attachments = new List<Attachment>();
        System.debug('>>>>>createSignatureAttachments: start <<<<<<');
        //List<Proof_of_Delivery__c> podsWithSignature = new List<Proof_of_Delivery__c>();

        for (Proof_of_Delivery__c p : pods.values()) {
            if(p.SignatureXString__c != null) {
                System.debug('>>>>>createSignatureAttachments: p.SignatureXString =' + p.SignatureXString__c);
                attachments.add(Util.createAttachment('Signature-' + (p.Signed_by__c == null ? '' : p.Signed_by__c) +'.png', p.SignatureXString__c, 'image/png', p.Id));
                //podsWithSignature.add(p);
            }
        }

        if(attachments.size() > 0) {
            System.debug('>>>>>createSignatureAttachments: insert attachments');
            insert attachments;
        }

        Map<Id, Proof_of_Delivery__c> podsMap = new Map<Id, Proof_of_Delivery__c>([SELECT Id, AttachmentId__c FROM Proof_of_Delivery__c WHERE Id IN :pods.keySet()]);

        for(Attachment att : attachments){
            podsMap.get(att.ParentId).AttachmentId__c = att.Id;
        }
        UPDATE podsMap.values();

        System.debug('>>>>>createSignatureAttachments: end');
    }
}