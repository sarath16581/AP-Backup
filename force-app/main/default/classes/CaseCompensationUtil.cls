// created by shengpeng.xiao@bluewolf.com at 2014.7.1
// handle all logic in Compensation trigger
/** ----------------- HISTORY ----------------- **/
/** [Compensation Form] [DDS-8012]
 * Modified at: 2021.10.13
 * Modified by: Phap Mai (phap.mai@audpost.com.au)
 * Changes:
 * - Added updateCompensationToken public method
 * - Added sendCompensationEmails public method
 * - Added getQualifiedCompensations private method
 * - Added getRelatedCases private method
 * - Added updateCompensationEmail private method
 * - Added sendEmails private method
 * Why need changes: Development for H&S compensation form.
 * What is changed: Method for compensation trigger to populate compensation token, send compensation email and create comment on case about sent out email.
 */

public class CaseCompensationUtil {
    public static Id eftRecordTypeId
    {
        get {
            if(eftRecordTypeId == null)
            {
                eftRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Compensation__c', new Set<String> {'EFT'}).values()[0].Id;
            }
          return eftRecordTypeId;
        }
        private set;
    }
    public CaseCompensationUtil() {}
    
    public static void updateCaseOwnerWhenCompensionRejected(List<Compensation__c> list_newComps) {
        //change the case owner to compensation LastModifiedBy
        //map<Id, Id> map_caseId_compLastModifyUser = new map<Id, Id>();
        map<Id, Compensation__c> map_caseId_comp = new map<Id, Compensation__c>();
        //map<Id, Id> map_caseId_compLastModifyUser_rejection = new map<Id, Id>();      //collect cases been rejected
        for(Compensation__c comp : list_newComps) {
            map_caseId_comp.put(comp.Case__c, comp);
            //map_caseId_compLastModifyUser.put(comp.Case__c, comp.LastModifiedById);
            //if(comp.Status__c == 'Rejected'){
            //    map_caseId_compLastModifyUser_rejection.put(comp.Case__c, comp.LastModifiedById);
            //}
        }
        
        list<Case> list_case2update = new list<Case>();
        Set<id> set_comps2refresh = new Set<id>();
        if(!map_caseId_comp.isEmpty()) {
            for(Case case2update: [SELECT Id, OwnerId FROM Case WHERE Id in : map_caseId_comp.keySet()]) {
                if(map_caseId_comp.get(case2update.Id) != null && map_caseId_comp.get(case2update.Id).Status__c == 'Rejected') 
                {
                    case2update.OwnerId = map_caseId_comp.get(case2update.Id).LastModifiedById;
                    case2update.Bypass_Data_enforcement__c = true;
                    list_case2update.add(case2update);
                }
                else if (map_caseId_comp.get(case2update.Id) != null)
                {
                    set_comps2refresh.add(map_caseId_comp.get(case2update.Id).id);          
                }
                
            }
        }
        
        if(list_case2update.size() > 0) {
            update list_case2update;
        }
        
        if(set_comps2refresh.size() > 0) 
        {
            //Updating the Same Compensation records - will fire in Future. 
            //This is to ensuire cross object fires.
            futureRefreshComp(set_comps2refresh);
        }
        
        /*list<Case> list_2updateCaseOwner_rejection = new list<Case>();
        if(!map_caseId_compLastModifyUser_rejection.isEmpty()) {
            for(Case case2update : [SELECT Id, OwnerId FROM Case WHERE Id in : map_caseId_compLastModifyUser_rejection.keySet()]) {
                //system.debug('case2update >>>>>>> :' + case2update);
                case2update.OwnerId = map_caseId_compLastModifyUser_rejection.get(case2update.Id);
                list_2updateCaseOwner_rejection.add(case2update);
            }
        }
        
        list<Case> list_2updateCaseOwner = new list<Case>();
        if(!map_caseId_compLastModifyUser_rejection.isEmpty()) {
            for(Case case2update : [SELECT Id, OwnerId FROM Case WHERE Id in : map_caseId_compLastModifyUser.keySet()]) {
                list_2updateCaseOwner.add(case2update);
            }
        }
        
        //system.debug('list_2updateCaseOwner >>>>>>> :' + list_2updateCaseOwner);
        
        if(list_2updateCaseOwner.size() > 0 || list_2updateCaseOwner_rejection.size() > 0) {
            update list_2updateCaseOwner;
            update list_2updateCaseOwner_rejection;
        }*/
    }
    
    @future
    static void futureRefreshComp(Set<Id> set_compIDs)
    {   
        list<Compensation__c> list_comp2refresh = new list<Compensation__c>();
        for (Compensation__c comp : [select Id from Compensation__c where Id in :set_compIDs])
        {
            list_comp2refresh.add(comp);
        }
        update list_comp2refresh;
    }

    /**
     * [Compensation Development] [DDS-8012]
     * After compensation get approved, populate the record with compensation token
     * @param compensations : Trigger.new
     * @param beforeCompensations : Trigger.oldMap
     */
    public static void updateCompensationToken(List<Compensation__c> compensations, Map<Id, Compensation__c> beforeCompensations)
    {
        if (compensations == null || compensations.size() == 0) return;

        List<Compensation__c> qualifiedCompensations = getQualifiedCompensations(compensations, beforeCompensations);

        if (qualifiedCompensations.size() > 0)
        {
            // populate compensation token
            for (Compensation__c compensation : qualifiedCompensations)
            {
                compensation.Compensation_Form_Token__c = EncodingUtil.urlEncode(CHAS_CompensationFormController.generateToken(compensation), 'UTF-8');
            }

            Map<Id, Case> relatedCases = getRelatedCases(qualifiedCompensations);

            // update compensation email
            updateCompensationEmail(qualifiedCompensations, relatedCases);
        }
    }
    
    /**
     * [Compensation Development] [DDS-8012]
     * After compensation get approved and compensation token populate, send compensation email and create case comment
     * @param compensations : Trigger.new
     * @param beforeCompensations : Trigger.oldMap
     */
    public static void sendCompensationEmails(List<Compensation__c> compensations, Map<Id, Compensation__c> beforeCompensations)
    {
        System.debug('sendCompensationEmails BEGIN');
        if (compensations == null || compensations.size() == 0) return;

        List<Compensation__c> qualifiedCompensations = getQualifiedCompensations(compensations, beforeCompensations);

        // only send out email if token is not empty
        List<Compensation__c> compensationsToSendEmail = new List<Compensation__c>();
        for (Compensation__c compensation : qualifiedCompensations)
        {
            if (String.isNotEmpty(compensation.Compensation_Form_Token__c))
            {
                compensationsToSendEmail.add(compensation);
            }
        }

        if (compensationsToSendEmail.size() > 0)
        {
            Map<Id, Case> relatedCases = getRelatedCases(compensationsToSendEmail);
            
            // send compensation email to customer
            sendEmails(compensationsToSendEmail, relatedCases);

            // create comment on related case
            CHAS_CompensationFormController.createCaseCommentAboutEmailSent(compensationsToSendEmail);
        }
    }

    /**
     * [Compensation Development] [DDS-8012]
     * Get compensations thats qualify for compensation email
     *  # RecordType equal 'EFT'
     *  # The status is changed
     *  # New status equal 'Approved Awaiting Customer'
     *  # Compensation email checkbox is ticked
     *  # Has related case
     * @param compensations : Trigger.new
     * @param beforeCompensations : Trigger.oldMap
     */
    private static List<Compensation__c> getQualifiedCompensations(List<Compensation__c> compensations, Map<Id, Compensation__c> beforeCompensations)
    {
        List<Compensation__c> qualifiedCompensations = new List<Compensation__c>();

        if (compensations == null || compensations.size() ==0) return qualifiedCompensations;


        // no need to check for empty bank details since the Bank_Detail_Provided_By_Customer__c checkbox will be set to False when bank details populated
        for (Compensation__c compensation : compensations)
        {
            if (compensation.RecordTypeId != eftRecordTypeId) continue;
            if (compensation.Status__c != SSSWConstants.STATUS_APPROVED_AWAITING_CUSTOMER) continue;
            if (!compensation.Bank_Detail_Provided_By_Customer__c) continue;
            if (compensation.Status__c == beforeCompensations.get(compensation.Id).Status__c) continue;
            if (compensation.Case__c == null) continue;
            qualifiedCompensations.add(compensation);
        }

        return qualifiedCompensations;
    }

    /**
     * [Compensation Development] [DDS-8012]
     * get related cases of compensations
     * @param qualifiedCompensations : compensation records
     */
    private static Map<Id, Case> getRelatedCases(List<Compensation__c> qualifiedCompensations)
    {
        Set<Id> caseIds = new Set<Id>();

        for (Compensation__c compensation : qualifiedCompensations)
        {
            if (compensation.Case__c != null)
            {
                caseIds.add(compensation.Case__c);
            }
        }

        Map<Id, Case> relatedCases = new Map<Id, Case>([SELECT Contact.Email, ContactId FROM Case WHERE Id IN :caseIds]);

        return relatedCases;
    }

    /**
     * [Compensation Development] [DDS-8012]
     * update Compensation_Email__c field of compensation to be equal related case's contact email
     * @param qualifiedCompensations : compensation records
     * @param relatedCases : map of related cases
     */
    private static void updateCompensationEmail(List<Compensation__c> qualifiedCompensations, Map<Id, Case> relatedCases)
    {
        if (relatedCases == null || relatedCases.keySet().size() == 0) return;

        for (Compensation__c compensation : qualifiedCompensations)
        {
            Case relatedCase = (Case)relatedCases.get(compensation.Case__c);

            if (relatedCase != null && relatedCase.Contact != null)
            {
                compensation.Compensation_Email__c = relatedCase.Contact.Email;
            }
        }
    }

    /**
     * [Compensation Development] [DDS-8012]
     * send compensation email to customer
     * @param qualifiedCompensations : compensation records
     * @param relatedCases : map of related cases
     */
    private static void sendEmails(List<Compensation__c> compensations, Map<Id, Case> relatedCases)
    {
        if (relatedCases == null || relatedCases.keySet().size() == 0) return;

        // get OWD email
        List<OrgWideEmailAddress> owes = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :SSSWConstants.ORGWIDEEMAIL];

        // safe escape
        if (owes.size() == 0)
        {
            return;
        }

        // get email template
        List<EmailTemplate> templates = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'SSSW_Compensation_Form_Email'];

        // safe escape
        if (templates.size() == 0)
        {
            return;
        }

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> ();

        for (Compensation__c compensation : compensations)
        {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

            Case relatedCase = (Case)relatedCases.get(compensation.Case__c);

            if (relatedCase != null && relatedCase.ContactId != null && relatedCase.Contact.Email != null)
            {
                message.setTargetObjectId(relatedCase.ContactId);
            }
            message.setOrgWideEmailAddressId(owes[0].Id);
            message.setTemplateId(templates[0].Id);
            message.setWhatId(compensation.Id);
            messages.add(message);
        }
        Messaging.sendEmail(messages);
    }
}