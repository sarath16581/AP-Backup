/**
* @author       : kalpita.talwadekar@auspost.com.au
* @date         : 31/03/2017
* @description  : Controller Class for landing page to display a custom case list view
*/
/*******************************  History ************************************************
Date                User                                        Comments
18.02.18     kalpita.talwadekar@auspost.com.au            updated code for accomodation of icons and color coding map based on case where abouts for MW0002003
18.02.18     kalpita.talwadekar@auspost.com.au            updated query for feedback closed cases MW0001996
24.02.18     kalpita.talwadekar@auspost.com.au            updated code for Case Update scenario on list notifications MW0002003
05.06.18     kalpita.talwadekar@auspost.com.au            updated code for coding standard follow - TDO-199
2018-11-07 nathan.franklin@auspost.com.au added a temporary transient variable for the list of cases to load.
                                            NOTE: This is a dirty quick fix to address a viewstate issue. Proper pagination should be implemented
2018-11-27 nathan.franklin@auspost.com.au added a temporary fix to allow collections of over 1000 to be rendered in visualforce (wrapping variables in List<> and splitting them up)
2019-01-22 saiswetha.pingali@auspot.com.au REQ1673720 - Display total cases on MyNetwork Landing Page
2019-02-05 saiswetha.pingali@auspost.com.au REQ1613613 - Restrict visibility to damage property and staff compalint cases for standard users
2019-04-23 ronnie.yang@sodastrategic.com.au INC1328032 - Extends the display of the 'updated' icon to cases of the 'General Enquiry' type
2019-04-24 swati.mogadala@auspost.com.au REQ1769837 - Changing fields displayed on MyNetwork landing page,replaced Product Category with Enquiry Sub type and Sender and Addresses address
2019-06-24 saiswetha.pingali@auspost.com.au REQ1830310 - Display priority on the case list on MyNetwork landing page.
2019-11-26 gunith.devasurendra@auspost.com.au REQ1982330/REQ1962663 - Order by Priority and highlight High priority ones
******************************  History ************************************************/
public with sharing class SSSW_MyNetworkLandingContr {

    // sorting cases from oldest to newest
    @TestVisible
    private class CaseWrapper implements Comparable {

        public Case caseObj;

        // Constructor
        public CaseWrapper(Case caseObj) {
            this.caseObj = caseObj;
        }

        // Convert Priority string to a number
		private Integer priorityAsInteger(Case caseObj){
            switch on caseObj.Priority {
                when 'Medium' {
                    return 1;
                }
                when 'High' {
                    return 2;
                }
            }
            return 0;
        }

        // Implement the compareTo() method
        public Integer compareTo(Object compareTo) {

            CaseWrapper compareToCase = (CaseWrapper)compareTo;

            Integer firstCasePriority = priorityAsInteger(caseObj);
            Integer secondCasePriority = priorityAsInteger(compareToCase.caseObj);
            if (firstCasePriority != secondCasePriority) {
                return secondCasePriority - firstCasePriority;
            }
            return 0;
        }
    }

    // due to visualforce's limitation of only being able to hold a collection of 1000 elements
    // we wrap the caseIds and case list in List<> and only store chunks of 900 elements
    // in visualforce we interate over an index array 0, 1, 2, 3 etc... with an apex:repeat and then iterate over the wrapped variables caseIds[0][0], caseIds[0][1], caseIds[1][0] etc.. elements (multidimensional array)
    // NOTE: this is only a temp fix and proper pagination should be implemented rather than this hack.
    // NOTE: no final definition since this is modified in test class
    @TestVisible
    private static Integer ARRAY_CHUNK_SIZE = 500;
    private static Integer MAX_RECORDS_TO_DISPLAY = 500;
    public Integer TotalCases {get;set;} 

    //class variable declarations
    // load all the case data into this one view which is a transient
    // we can't iterate this in visualforce and use a commandbutton at the same time, because variable needs to be reconstructed serverside after the postback
    // given this variable is transient, it won't work.
    // See http://bobbuzzard.blogspot.com/2014/05/transient-list-command-button-woes.html
    // NOTE: wrapping List<> to workaround collection size of 1000 errors
    public transient List<Map<Id, Case>> caseList {get;set;}

    // Priority translation map from String to number. Used for sorting purposes
    public transient Map<String, Integer> casePriorityNumbers {get;set;}

    // store a list of caseIds which is an instance variable used purely for the iterator
    // since we are iterating with an instance variable, we can use a commandButton
    // NOTE: wrapping List<> to workaround collection size of 1000 errors
    public List<List<Id>> caseIds {get;set;}

    // this is for iterating over the caseIds array as per comments for ARRAY_CHUNK_SIZE
    public List<Integer> caseIdIndexes {get;set;}

    // stores the value that generates a redirect pagereference
    public String cseId {get;set;}

    private Set<String> enqubTypeNotVisible = new Set<String>{'Damage to property','Staff Complaint'};
    private String managerRoleId = [Select Id from UserRole where Name = 'SSSW MyNetwork Manager' limit 1].Id;
    private String networkQueue = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;

    //variables added for MW0002003 to hold the icon color and label and hover text
    public Map<String,STring> iconNameMap {get;set;}
    public Map<String,STring> colorMap {get;set;}
    public Map<String,String> hoverTextMap {get;set;}

    //variable added for MW0001996
    private datetime dt = Datetime.newInstance(2018,03,06,0,0,0); 

    /**
    * @description       constructor for the class to setup values
    * @param             ApexPages.StandardController
    * @return            Void
    * @throws            NA
    */  
    public SSSW_MyNetworkLandingContr(ApexPages.StandardController std) {
        //initialize the case list to be displayed on the myNtwork landing home page
        caseList = new List<Map<Id, Case>>();
        caseIds = new List<List<Id>>();
    }
    public SSSW_MyNetworkLandingContr() {}

    /****
        * @description       This method is used to initialie the list of cases based on case type and ownership and status
        * @param             NA
        * @return            Void
        * @throws            Handled exceptions using null checks, initialization of variables, etc.
        */  
    public void initialize() {

        Integer caseListIndex = 0;

        Map<Id, Case> currentCaseList = new Map<Id, Case>();
        List<Id> currentCaseIds = new List<Id>();

        //initialize the case list to be displayed on the myNtwork landing home page
        caseList = new List<Map<Id, Case>>();
        caseIds = new List<List<Id>>();
        caseIdIndexes = new List<Integer>();

        // Priority translation map from String to number. Used for sorting purposes
        casePriorityNumbers = new Map<String, Integer>();
        casePriorityNumbers.put('High', 3);
        casePriorityNumbers.put('Medium', 2);
        casePriorityNumbers.put('Low', 1);

        //variables re-set for mw0002003 - for color coding and icon mapping
        iconNameMap = new Map<STring,STring>();
        colorMap = new Map<STring,STring>();  
        hoverTextMap = new Map<STring,STring>();        

        //query the Investigation case records based on case team members and those in network queue
        //query updated for MW0001996(query split for investigation and feedback and inner query added for nw response) and 
        //MW0002003 - added fields like IsEscalated,Checkbox__c(for case print) 
        ////querying Address1__c,Address2__c as per REQ1769837 
        for(Case cse: [SELECT Id, Status, type,CaseNumber,Priority,ReferenceID__c, CreatedDate,NetworkTierSLA__c,ProductCategory__c,Address1Suburb__c,
                                EnquirySubType__c,LastModifiedById, LastModifiedBy.Name, IsEscalated, Address1Postcode__c,Address2Suburb__c,Address2Postcode__c,NetworkName__c,
                                Facility_Milestones_Violated__c,Checkbox__c,Root_cause__c,Address1__c,Address2__c,
                                (SELECT Request_Hold_Case__c,to_CCC_action__c FROM Network_Responses1__r ORDER BY CreatedDate DESC)
                        FROM Case
                        WHERE OwnerId = :networkQueue
                        AND type = 'Investigation'
                        AND Id IN (SELECT ParentId FROM caseteammember WHERE MemberId = :userinfo.getUserId())
                        ORDER BY createdDate ASC
                        LIMIT 10000]) {

            //for standard users, to display the open records of investigation type
            if('Awaiting Network Response'.equalsIgnoreCase(cse.Status) && userinfo.getUserRoleId().contains(managerRoleId)) {
                currentCaseList.put(cse.Id, cse);
                currentCaseIds.add(cse.Id);
            //for super users, to display the open records of investigation type as well as damage property and staff compalint cases.
            } else if('Awaiting Network Response'.equalsIgnoreCase(cse.Status) &&  
                    !userinfo.getUserRoleId().contains(managerRoleId) && 
                    !enqubTypeNotVisible.contains(cse.EnquirySubType__c)) {
                currentCaseList.put(cse.Id, cse);
                currentCaseIds.add(cse.Id);
            }
            //below conditions added for MW0002003 for icon and color coding mapping for SUI cases
            if(!cse.Network_Responses1__r.isEmpty() && 
                cse.Network_Responses1__r[0].Request_Hold_Case__c)  { 
                iconNameMap.put(cse.Id,'SUI'); 
                colorMap.put(cse.Id,'orange');
                hoverTextMap.put(cse.Id,'Case is under investigation');
            } else {  // if not SUI, then flag cases as new to work on
                iconNameMap.put(cse.Id,'NEW'); 
                colorMap.put(cse.Id,'green');
                hoverTextMap.put(cse.Id,'Case is awaiting action/response');
            }                    
        }

        //newly added split query for feedback cases starting 20th March, 2018 and limit to past 15 days for MW0001996. 
        //and accomodations same as above for MW0002003 (added fields like IsEscalated,Checkbox__c)
        //querying Address1__c,Address2__c as per REQ1769837
        for(Case cse: [SELECT Id, Status, type,CaseNumber,Priority,ReferenceID__c,CreatedDate,NetworkTierSLA__c, ProductCategory__c,Address1Suburb__c,EnquirySubType__c,LastModifiedById,
                                LastModifiedBy.Name, IsEscalated, Address1Postcode__c,Address2Suburb__c,Root_cause__c, Address2Postcode__c,NetworkName__c,Facility_Milestones_Violated__c,Checkbox__c,Address1__c,Address2__c,
                                (SELECT Request_Hold_Case__c, to_CCC_action__c, to_Reassign_Network__c FROM Network_Responses1__r ORDER BY CreatedDate DESC)
                        FROM Case
                        WHERE OwnerId = :networkQueue
                        AND type = 'Feedback'
                        AND closedDate>= :dt
                        AND closedDate = LAST_N_DAYS:15
                        AND Id IN  (SELECT ParentId FROM caseteammember WHERE MemberId = :userinfo.getUserId())  
                        ORDER BY createdDate ASC
                        LIMIT 10000]) {

            //criteria for Feedback cases which are not responded to earlier or SUI or which return back from CCC or new to a re-assigned network
            if(('Awaiting Network Response'.equalsIgnoreCase(cse.Status) || 
                    (cse.Network_Responses1__r.isEmpty() ) ||  'Awaiting Network Response'.equalsIgnoreCase(cse.Root_cause__c)  ||
                    (!cse.Network_Responses1__r.isEmpty() && cse.Network_Responses1__r[0].Request_Hold_Case__c  ) ||
                    (!cse.Network_Responses1__r.isEmpty() && cse.Network_Responses1__r[0].to_CCC_action__c) ||
                    (!cse.Network_Responses1__r.isEmpty() && cse.Network_Responses1__r[0].to_Reassign_Network__c != null))) {

                //for standard users, to display the open records and feedback cases which are auto-closed by agents
                if (userinfo.getUserRoleId().contains(managerRoleId)) {
                    currentCaseList.put(cse.Id, cse);
                    currentCaseIds.add(cse.Id);
                //for super users, to display the open records and feedback cases which are auto-closed by agents as well as damage property and staff compalint cases.
                } else if(!userinfo.getUserRoleId().contains(managerRoleId) && 
                            !enqubTypeNotVisible.contains(cse.EnquirySubType__c)) {
                    currentCaseList.put(cse.Id, cse);
                    currentCaseIds.add(cse.Id);
                }
            }

            //below conditions added for MW0002003 for SUI highlight
            if(!cse.Network_Responses1__r.isEmpty() && cse.Network_Responses1__r[0].Request_Hold_Case__c)  {
                iconNameMap.put(cse.Id,'SUI'); colorMap.put(cse.Id,'orange');  hoverTextMap.put(cse.Id,'Case is under investigation');
            } else { //for other cases yet to be responded to
                iconNameMap.put(cse.Id,'NEW');  colorMap.put(cse.Id,'green'); hoverTextMap.put(cse.Id,'Case is awaiting action/response');
            }                    
        }

        //for mw0002003 - to pull updated cases for notification (cases that have been in network queue, but due to some backend action moved of the case list)
        ////querying Address1__c,Address2__c as per REQ1769837
        for(Case cse: [ SELECT Id, Status, type,CaseNumber,Priority,ReferenceID__c,CreatedDate,NetworkTierSLA__c,ClosedDate, ProductCategory__c,Address1Suburb__c,EnquirySubType__c,LastModifiedById,
                                LastModifiedBy.Name, IsEscalated, Address1Postcode__c,Address2Suburb__c, Address2Postcode__c,NetworkName__c,Facility_Milestones_Violated__c,Checkbox__c,Root_cause__c,Address1__c,Address2__c,
                       (SELECT Id,Request_Hold_Case__c FROM Network_Responses1__r ORDER BY CreatedDate DESC)
                        FROM Case
                        WHERE Root_cause__c = 'Awaiting Network Response'
                        AND Last_Status_Change__c = LAST_N_DAYS:1
                        AND Id NOT IN :currentCaseIds
                        AND Id IN (SELECT ParentId FROM caseteammember WHERE MemberId = :userinfo.getUserId())
                        ORDER BY createdDate ASC
                        LIMIT 10000]) {
             
             //REQ1613613 - Restrict visibility to damage property and staff compalint cases for standard users
             
             //for super users, display all cases
                if (userinfo.getUserRoleId().contains(managerRoleId)) {
                    currentCaseList.put(cse.Id, cse);
                    currentCaseIds.add(cse.Id);
                //for standard users,  restrict visibility to damage property and staff compalint cases.
                } else if(!userinfo.getUserRoleId().contains(managerRoleId) && 
                            !enqubTypeNotVisible.contains(cse.EnquirySubType__c)) {
                    currentCaseList.put(cse.Id, cse);
                    currentCaseIds.add(cse.Id);
                }                
             //REQ1613613 - Restrict visibility to damage property and staff compalint cases for standard users

            //updated use case only for Investigation cases
            //INC1328032 Extends the display of the 'updated' icon to cases of the 'General Enquiry' type
            if('Investigation'.equalsIgnoreCase(cse.Type) || 'General Enquiry'.equalsIgnoreCase(cse.Type)){
                iconNameMap.put(cse.Id,'Updated');
                colorMap.put(cse.Id,'Red');
                hoverTextMap.put(cse.Id,'Case has been updated');
            }
            else if('Feedback'.equalsIgnoreCase(cse.Type) && !cse.Network_Responses1__r.isEmpty() && 
                cse.Network_Responses1__r[0].Request_Hold_Case__c) { //if SUI checked on existing response
                iconNameMap.put(cse.Id,'SUI');  
                colorMap.put(cse.Id,'orange'); 
                hoverTextMap.put(cse.Id,'Case is under investigation');}
            else { // all other cases yet to be responded
                iconNameMap.put(cse.Id,'NEW'); 
                colorMap.put(cse.Id,'green'); 
                hoverTextMap.put(cse.Id,'Case is awaiting action/response');
            }
        }

        // setup comparable to order cases by oldest to newest since we will be extracting only the first MAX_RECORDS_TO_DISPLAY
        List<CaseWrapper> caseWrappers = new List<CaseWrapper>();
        for(Id caseId : currentCaseList.keySet()) {
            caseWrappers.add(new CaseWrapper(currentCaseList.get(caseId)));
        }
        caseWrappers.sort();
        TotalCases = caseWrappers.size();
        
         System.Debug('Total Cases: ' + TotalCases);

        // temporary limit fix... hard limit MAX_RECORDS_TO_DISPLAY
        // after this we then chunk it into collection chunks to ensure visualforce can handle the count
        List<Case> allCases = new List<Case>();
        for(Integer i=0;i<MAX_RECORDS_TO_DISPLAY;i++) {
            // no more records to process
            if (i >= caseWrappers.size())
                break;

            allCases.add(caseWrappers[i].caseObj);
            System.Debug('CaseNumber : ' + caseWrappers[i].caseObj.CaseNumber + ' Priority: ' + caseWrappers[i].caseObj.Priority);
        }
        System.Debug('allCases size: ' + allCases.size());

        // chunk our results into collections no more than ARRAY_CHUNK_SIZE in size
        Integer currentIndex = 0;
        for(Integer i=0;i<allCases.size();i++) {

            // grab the next chunk of cases
            Map<Id, Case> chunkedCases = chunkCases(allCases, i);

            caseIdIndexes.add(currentIndex);
            caseList.add(chunkedCases);
            caseIds.add(new List<Id>(chunkedCases.keySet()));

            currentIndex++;
            i += chunkedCases.keySet().size() - 1;
        }
    }

    private Map<Id, Case> chunkCases(List<Case> allCases, Integer offset) {
        Map<Id, Case> output = new Map<Id, Case>();
        for(Integer i=offset;i<allCases.size();i++) {
            if(output.keySet().size() >= ARRAY_CHUNK_SIZE) {
                break;
            }
            output.put(allCases[i].Id, allCases[i]);
        }

        return output;
    }

    /**
    * @description       This method is to redirect the cases to relevant record to be responded to (Response Screen)
    * @param             NA
    * @return            PageReference
    * @throws            NA
    */  
    public PageReference respondtoCase() {
        PageReference pgRef = null;
        if(!String.isBlank(cseId)) { //check if case id is not blank when user clicks/picks from the landing screen
            pgRef = new PageReference('/apex/SSSW_MyNetworkResponsePage?Id='+cseId);
        }
        return pgRef;
    }

}