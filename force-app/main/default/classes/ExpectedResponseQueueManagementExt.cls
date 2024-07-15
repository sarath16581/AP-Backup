/************************************
 * History
 * Sep-2015:  paul.stamer@auspost.com.au            Added null to child case for ServcieNow fields - INC0592658
 * Jan-2016:  paul.stamer@auspost.com.au            Added false to child case for HLC & CR - INC0i636463
 * July-2018  kalpita.talwadekar@auspost.com.au     Added root cause for when again cases go awaiting for response
 * Jun-2018:  disha.kariya@auspost.com.au   Removed NPSRequired__c and NPSTagDate__c fields to be deleted.
 * 2021-09-06	seth.heang@auspost.com.au   Uplift SF API version to 52
 * 2022-08-04  swati.mogadala@auspost.com.au REQ2910384 - Parent case not sent to back network when -yesStillWaitingClicked()
 * 2022-08-25  swati.mogadala@auspost.com.au REQ2944040 - Parent case assigned to logged in agent when noStillWaitingClicked()
 * 2024-07-15  Paul Perry  Case Hand-off banner changes
* **********************************/
global with sharing class ExpectedResponseQueueManagementExt {
    //class variable for case details
    public Case currentCase {
        get;
        private set;
    }
    public Case proxyCase {
        get;
        set;
    }
    public boolean hasSystemUpdate {
        get;
        private set;
    }
    public boolean hasStatusResponded {
        get;
        private set;
    }
    public StatusTracking__c proxyStatusTracking {
        get;
        private set;
    }
    //constants for case status values
    string AWAITING_NETWORK_RESPONSE = 'Awaiting Network Response';
    string AWAITING_CUSTOMER_RESPONSE = 'Awaiting Customer Response';
    string CUSTOMER_RESPONDED = 'Customer Responded';
    string NETWORK_RESPONDED = 'Network Responded';
    //boolean for case ownership check
    public boolean isNotTheOwner {
        get;
        set;
    }
    public boolean isOpenFeedback {
        get;
        set;
    }
    public string ownedByName {
        get;
        set;
    }

    /**
     * @description       constructor for the class to setup values
     * @param             ApexPages.StandardController
     * @return            Void
     * @throws            NA
     */
    public ExpectedResponseQueueManagementExt(ApexPages.StandardController controller) {
        isNotTheOwner = false;
        isOpenFeedback = false;
        hasStatusResponded = false;
        //Added for  REQ0998943 DYU - Add isClosed field to disable contact another network button when its closed
        currentCase = [select ownerid, caseNumber, Network__c, SystemUpdate__c, status,
            Network_Response__c, ParentID, RelatedCase__c, Origin, Type, IsClosed, CaseTransferDate__c
            from
            case
            where
            id = :
                controller.getID()
                limit 1
        ];
        if (currentCase.status == NETWORK_RESPONDED || currentCase.status == CUSTOMER_RESPONDED) {
            hasStatusResponded = [select id
                from
                Case
                where
                parentId =: currentCase.id
                and(status =: AWAITING_NETWORK_RESPONSE or status =: AWAITING_CUSTOMER_RESPONSE)
                limit 2
            ].size() > 0;
        }
        proxyCase = new Case();
        proxyCase.Network_Response__c = currentCase.Network_Response__c;
        ExpectedResponseQueueManagement__c setting = ExpectedResponseQueueManagement__c.getValues(currentCase.status);
        for (StatusTracking__c st: [select NetworkResponseValue__c, StatusValue__c, Case__c
                from
                StatusTracking__c
                where
                Case__c =: currentCase.id
                and
                StatusValue__c =: AWAITING_NETWORK_RESPONSE
                order by
                StartDate__c desc
                limit 2
            ]) {
            proxyStatusTracking = st;
            if (!string.isEmpty(st.NetworkResponseValue__c)) {
                proxyCase.Network_Response__c = st.NetworkResponseValue__c;
            }
            break;
        }

        hasSystemUpdate = setting != null && !string.isEmpty(currentCase.SystemUpdate__c) &&
            (currentCase.status == AWAITING_NETWORK_RESPONSE || currentCase.status == AWAITING_CUSTOMER_RESPONSE);

        if (currentCase.ownerId != UserInfo.getUserId()) {
            isNotTheOwner = true;
            if (String.valueOf(currentCase.ownerId).startsWith(Group.SObjectType.getDescribe().getKeyPrefix())) {
                ownedByName = 'Queue: ' + [select name
                    from
                    Group
                    where
                    id =: currentCase.ownerid
                    limit 1
                ].name;
            } else if (String.valueOf(currentCase.ownerId).startsWith(User.SObjectType.getDescribe().getKeyPrefix())) {
                ownedByName = 'User: ' + [select name
                    from
                    User
                    where
                    id =: currentCase.ownerid
                    limit 1
                ].name;
            }
        }

        if (currentCase.Origin == 'Phone' && currentCase.Type == 'Feedback' && currentCase.Status == 'New') {
            isOpenFeedback = true;
        }

    }

    /**
     * @description       method to rate the response valueOf
     * @param             NA
     * @return            Void
     * @throws            NA
     */
    public void rateResponse() {
        if (proxyStatusTracking != null) {
            proxyStatusTracking.NetworkResponseValue__c = proxyCase.Network_Response__c;
            update proxyStatusTracking;
        }
    }

    /**
     * @description       method when system update happens and we accept the update
     * @param             NA
     * @return            Void
     * @throws            NA
     */
    public void yesSystemUpdateClicked() {
        ExpectedResponseQueueManagement__c setting = ExpectedResponseQueueManagement__c.getValues(currentCase.status);
        if (setting != null) {
            //as the case is again sent to network - we need to have the network respond again.
            currentCase.Root_cause__c = AWAITING_NETWORK_RESPONSE;
            currentCase.OwnerId = setting.QueueID__c;
            currentCase.Bypass_Data_enforcement__c = true;
            currentCase.SystemUpdate__c = null;
            update currentCase;
        }
    }

    /**
     * @description       method when system update happens and still work needs to be done on the case
     * @param             NA
     * @return            Void
     * @throws            NA
     */
    public void noSystemUpdateClicked() {
        currentCase.status = 'In Progress';
        currentCase.SystemUpdate__c = null;
        update currentCase;
    }

    /**
     * @description       method to set case status when case is responded to and we are still awaiting response
     * @param             NA
     * @return            Void
     * @throws            NA
     */
       public void yesStillWaitingClicked(){
        try {
            if(currentCase.status == CUSTOMER_RESPONDED){
                currentCase.status = AWAITING_CUSTOMER_RESPONSE; 
            }
            else {
                currentCase.status = NETWORK_RESPONDED;	// 04/08/22 -REQ2910384 Parent case to remain in 'Network responded' status and allocated to 'Awaiting ReOpen queue' 
        	}  
            // previously case was being assigned back to network if related child case was awaiting network reponse	
            //   else if(currentCase.status == NETWORK_RESPONDED) {		
            //	currentCase.status = AWAITING_NETWORK_RESPONSE;}	
            // 04/08/22 -REQ2910384 -Case not sent back to network		
            // currentCase.Root_cause__c = AWAITING_NETWORK_RESPONSE; // 04/08/22 -REQ2910384 -Case not sent back to network
            ExpectedResponseQueueManagement__c setting = ExpectedResponseQueueManagement__c.getValues(currentCase.status);
            if(setting != null) {
                currentCase.OwnerId = setting.QueueID__c;
                currentCase.Bypass_Data_enforcement__c = true;
                update currentCase;
            }
        }
        catch(Exception ex) {
            ApexPages.addMessages(ex);
        }
    }


    /**
     * @description       method when we are still to work on the case
     * @param             NA
     * @return            Void
     * @throws            NA
     */
    public void noStillWaitingClicked() {
        currentCase.status = 'In Progress';
        currentCase.OwnerId = userInfo.getUserId(); // Assign case to current agent REQ2944040
        update currentCase;
    }

    /**
     * @description       constructor for the class to setup values
     * @param             ApexPages.StandardController
     * @return            Void
     * @throws            NA
     */
    @RemoteAction
    global static String getChildCaseId(Id caseId) {
        Case toClone = Database.query(Util.getCreatableFieldsSOQL('Case', 'Id = :caseId limit 1'));
        system.debug('CaseId**' + caseId);
        //toClone = [Select Id from Case where Id=:caseId limit 1];
        Case childCase = toClone.clone(false, true);
        //childCase.ReferenceID__c = '';
        childCase.Unique_Case__c = '';
        childCase.Status = 'New';
        childCase.Permanent_Close__c = false;
        childCase.ResolutionCode__c = '';
        //childCase.ClosedDate = null;
        childCase.Network__c = null;
        childCase.Lodgement_Network__c = null;
        childCase.ParentId = caseId;
        childCase.Case_Milestone_Violation__c = false;
        childCase.Customer_Milestones_Violated__c = null;
        childCase.Internal_Milestones_Violated__c = null;
        childCase.Facility_Milestones_Violated__c = null;
        childCase.Customer_Email_Notification__c = null;
        childCase.Internal_Tier_Escalation_Email__c = null;
        childCase.Facility_Tier_Escalation_Email__c = null;
        childCase.parentId = toClone.id;
        childCase.NPSAgent__c = null;
        // childCase.NPSRequired__c = false;
        childCase.NPSScheduledDate__c = null;
        // childCase.NPSTagDate__c = null;
        childCase.Service_Now_Ticket_Number__c = null; //24-Sep-15 paul stamer
        childCase.IsHLC__c = false; //13-Jan-16 paul stamer
        childCase.IsCR__c = false; //13-Jan-16 paul stamer         


        insert childCase;
        if (childCase != null) {
            return String.valueOf(childCase.Id);
        } else {
            return 'child case = null';
        }
    }

	public Boolean isCaseTransfer {
		get {
			return currentCase?.CaseTransferDate__c != null;
		}
	}
}