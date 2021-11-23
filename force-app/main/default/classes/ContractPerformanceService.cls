/**************************************************
Type:		Service Class for Contract Performance 
Purpose:	Provide functionality for complete Contract Performance that spans multiple Objects.
			Objects involved 
			ContractPerformanceAgreement : Agreement Object
            ContractPerformanceSLACOA	 : Define an SLA or COA
            ContractPerformanceResult	 : Capture the relult of SLA or COA
            Contract_Performance_Measurement__c : Define a Measurement
            Contract_Performance_Related_Billing__c : Link related Account Billing to Contract Performance Agreement
			Contract_Performance_SLA_Team__c : Create list of SLA members , that can be assigned functionality Eg: receive reminder emails 
			Constructor will load / retrieve parent object for child objects : ie At Result level , Agreement and SLA/COA ids are populated into data structure
History:
--------------------------------------------------
07.12.2017	Clint D'Silva		Created
**************************************************/

public with sharing class ContractPerformanceService {
    private map<id, ContractPerformance> cpById;
    private MAP<id,id> cpaIDBySlaCOAid ;
    private MAP<id,id> cpaIDByResultid ;
    public Map<string,recordtype> recTyBysObjNamRecTyNam;

    public ContractPerformanceService(list<sObject> objLst, Map<id,sObject> oldObjLst  ) {
        cpById = new map<id, ContractPerformance>();
        recTyBysObjNamRecTyNam = new Map<string,recordtype>();

        cpaIDBySlaCOAid = new MAP<id,id>();
        cpaIDByResultid = new MAP<id,id>();
                list<RecordType> recTyLst = [select id,name,sobjecttype, developername from recordtype where  developername in ('COA','SLA') and sObjectType in ('Contract_Performance_SLA_COA__c') ];
        for(Recordtype rec: recTyLst){
            recTyBysObjNamRecTyNam.put(rec.sobjecttype + '|' + rec.developername,rec );
        }
        Schema.sObjectType cpaType = schema.Contract_Performance_Agreement__c.getSObjectType();
        Schema.sObjectType slaCOAType = schema.Contract_Performance_SLA_COA__c.getSObjectType();
        Schema.sObjectType rsltType = schema.Contract_Performance_Result__c.getSObjectType();
        string mainsObject = '';
        set<id> cpaIDs = new set<id>();

        for(sObject obj : objLst ){
            if(cpaType == obj.getSObjectType() ){
                Contract_Performance_Agreement__c oldCpa =  oldObjLst == null?null: (Contract_Performance_Agreement__c)oldObjLst.get(obj.id);
                Contract_Performance_Agreement__c cpa = (Contract_Performance_Agreement__c)obj;
                mainsObject = 'Contract_Performance_Agreement__c';
                ContractPerformance cp = new ContractPerformance(mainsObject);
                cp.cpa = cpa;
                cp.oldCpa = oldCpa;
                if(cpa.Active__c == true) {
                    cpById.put(cpa.id, cp);
                }
            }
            if(slaCOAType == obj.getSObjectType() ){
                mainsObject = 'Contract_Performance_SLA_COA__c';
                Contract_Performance_SLA_COA__c oldSlaCOA  =  oldObjLst == null?null: (Contract_Performance_SLA_COA__c)oldObjLst.get(obj.id);
                Contract_Performance_SLA_COA__c slaCOA  = (Contract_Performance_SLA_COA__c)obj;
                if(slaCOA.Active__c == true) {
                    cpaIDBySlaCOAid.put(slaCOA.id,slaCOA.Contract_Performance_Agreement__c);
                }
            }
            if(rsltType == obj.getSObjectType() ){
                mainsObject = 'Contract_Performance_Result__c';
                Contract_Performance_Result__c oldRslt  =  oldObjLst == null?null: (Contract_Performance_Result__c)oldObjLst.get(obj.id);
                Contract_Performance_Result__c rslt  = (Contract_Performance_Result__c)obj;

                cpaIDByResultid.put(rslt.id,rslt.ContractPerformanceAgreementID__c);

            }
        }
        if(mainsObject == 'Contract_Performance_Agreement__c' ){
            populateSLACOAfromCPA();
        } else if(mainsObject == 'Contract_Performance_SLA_COA__c') {
            populateCPAfromSLACOA((list<Contract_Performance_SLA_COA__c>)objLst, (map<id, Contract_Performance_SLA_COA__c>)oldObjLst,cpaIDBySlaCOAid );
        } else if(mainsObject == 'Contract_Performance_Result__c') {
            populateCPAfromResult((list<Contract_Performance_Result__c>)objLst, (map<id, Contract_Performance_Result__c>)oldObjLst,cpaIDByResultid );
        }
    }

    public static void setNewRsltFlagSLACOA(set<id> SLACOA_Ids){
    	list<Contract_Performance_SLA_COA__c> slaCoaLst = [select id ,Create_New_Result_Records__c from Contract_Performance_SLA_COA__c where id in :SLACOA_Ids and Create_New_Result_Records__c = true  ];
        for(Contract_Performance_SLA_COA__c slaCoa : slaCoaLst ){
        	slaCoa.Create_New_Result_Records__c = false;
        }
        update slaCoaLst;

        system.debug('after updt slaCoaLst.size()=' + slaCoaLst.size());
    }

    private static date calQuaterly(Date changeDueDateTo){
    	Integer mth = changeDueDateTo.month();
        Integer quarter = mth/3;
        if(quarter == 0 ||  (quarter == 1 && mth == 3  ) ){
            system.debug('==FirstQuarter==');
            changeDueDateTo = date.newinstance( changeDueDateTo.year(), 3,31 );  
        } else if(quarter == 1 ||  (quarter == 2 && mth == 6  ) ){
            system.debug('==SecondQuarter==');
            changeDueDateTo = date.newinstance( changeDueDateTo.year(), 6,30 );    
        } else if (quarter == 2 ||  (quarter == 3 && mth == 9  ) ){
            system.debug('==ThirdQuarter==');
            changeDueDateTo = date.newinstance( changeDueDateTo.year(), 9,30 );    
        } else {
            system.debug('==fourthQuarter==');
            changeDueDateTo = date.newinstance( changeDueDateTo.year(), 12,31 );    
        }   	
        //if weekend then go to  friday prior
        integer weekNumberPrior = math.mod(date.newInstance(1900,1,7).daysBetween(changeDueDateTo) ,7);
        changeDueDateTo =  weekNumberPrior == 6?changeDueDateTo.addDays(-1):changeDueDateTo ;
        changeDueDateTo =  weekNumberPrior == 0?changeDueDateTo.addDays(-2):changeDueDateTo ; 
        
        return changeDueDateTo;
    }
    
    // Calculate the next Due Date, skip weekend
    public static DueDates setNextDueDateValues(DueDates dueDtVal, Date startDt, string cycle, string cycleSpeicficWeek, string cycleSpecificWeekDay , string CycleDaysFromMonthStart){
        date changeDueDateTo ;
        // Set Due Date
        if(dueDtVal != null && dueDtVal.dueDate == null) {
            dueDtVal.dueDateReminder = null;
        }
        dueDtVal = dueDtVal ==null?(new DueDates(null) ):dueDtVal;
        date currentDueDate = dueDtVal.dueDate == null ?(startDt <= date.today()?date.today():startDt ): dueDtVal.dueDate  ;
        changeDueDateTo = currentDueDate;
        date startMonth = changeDueDateTo.toStartOfMonth();
        integer icnt = 0;
        if(currentDueDate != null ){
                date tempDt ;
                if (cycle == 'Daily') {
                    changeDueDateTo = currentDueDate.addDays(1);
                } else if (cycle == 'Monthly') {
                    //changeDueDateTo = currentDueDate.toStartOfMonth().toStartOfWeek();
                    changeDueDateTo = currentDueDate.toStartOfMonth();
                } else if (cycle == 'Weekly') {
                    changeDueDateTo = currentDueDate.addDays(7).toStartOfWeek().AddDays(1);
                } else if (cycle == 'Quaterly') {
                    
                    // Get End of month for Quaterly
                    //changeDueDateTo = currentDueDate.toStartOfMonth().addMonths(3).toStartOfMonth().AddDays(-1);
                   	date initialDt = changeDueDateTo;
                    changeDueDateTo = calQuaterly(changeDueDateTo);
                    //a weekend could return same friday ,  for sat, sun as well . if calculated date is same as input date , increment by one day to move ahead  
                    if(changeDueDateTo ==  initialDt){
                    	for(integer i = 1; i < 4 ; i++){  
                            //add 3 to ensure skipping week day
                            changeDueDateTo = calQuaterly(changeDueDateTo.addDays(3));   
                                if(changeDueDateTo !=initialDt ){
                                	break;    
                                }     
                        }    
                    }
                    
                    
                    //system.debug('In Quaterly: changeDueDateTo= ' + changeDueDateTo + ' debugTmpDt=' + debugTmpDt  + ' quarter=' + quarter + ' weekNumberPrior=' + weekNumberPrior);
                } else if (cycle == 'Annual') {
                    changeDueDateTo = currentDueDate.addYears(1).toStartOfMonth().toStartOfWeek();
                } 

                if(!string.isBlank(CycleDaysFromMonthStart)){
                    system.debug('CycleDaysFromMonthStart='+ CycleDaysFromMonthStart);
                    integer daysInMth = 0;
                    boolean isLastDayOfMonth = false;
                    if(CycleDaysFromMonthStart == 'Last Day Of Month'){
                        isLastDayOfMonth = true;
                    }
                    // set to end of month if CycleDaysFromMonthStart > end of month
                    integer daysInMthTmp  = date.daysInMonth(changeDueDateTo.year(), changeDueDateTo.month());
                    integer cycleDaysFromMonthStartInt = isLastDayOfMonth == true?daysInMthTmp:integer.valueof(CycleDaysFromMonthStart);
                    daysInMth =   cycleDaysFromMonthStartInt > daysInMthTmp?daysInMthTmp:cycleDaysFromMonthStartInt  ;
                    changeDueDateTo = changeDueDateTo.AddDays(daysInMth - 1);
                    if(changeDueDateTo < currentDueDate){
                        tempDt = changeDueDateTo.toStartOfMonth().addMonths(1);
                        daysInMthTmp  = date.daysInMonth(tempDt.year(), tempDt.month());
                        daysInMth =   cycleDaysFromMonthStartInt > daysInMthTmp?daysInMthTmp:cycleDaysFromMonthStartInt  ;
                        changeDueDateTo = tempDt.AddDays(daysInMth - 1);
                    }
                }
				//  
                //CycleDaysFromMonthStart and cycleSpeicficWeek are mutually elclusive , since cycles = monthly and quaterly are using days from month start
                //  and none using cycleSpeicficWeek ,  commenting cycleSpeicficWeek
               /*   
                if (string.isBlank(CycleDaysFromMonthStart) && ( cycle == 'Monthly' || cycle == 'Quaterly') ) {
                    changeDueDateTo = changeDueDateTo.toStartOfWeek();
                    if (cycleSpeicficWeek == '1st week of Month' || string.isBlank(cycleSpeicficWeek)) {
                        if(changeDueDateTo < currentDueDate ){
                            changeDueDateTo = changeDueDateTo.toStartOfMonth().addMonths(2).toStartOfWeek().AddDays(1);
                        } else {
                            changeDueDateTo = changeDueDateTo.toStartOfWeek().AddDays(1);
                        }
                    } else if (cycleSpeicficWeek == '2nd week of Month') {
                        changeDueDateTo = changeDueDateTo.addDays(7).toStartOfWeek().AddDays(1);
                        if(changeDueDateTo < currentDueDate ){
                            tempDt = changeDueDateTo.toStartOfMonth().addMonths(1).toStartOfWeek().AddDays(1);
                            changeDueDateTo = tempDt.addDays(7).toStartOfWeek().AddDays(1);
                        }
                    } else if (cycleSpeicficWeek == '3rd week of Month') {
                        changeDueDateTo = changeDueDateTo.addDays(14).toStartOfWeek().AddDays(1);
                        if(changeDueDateTo < currentDueDate ){
                            tempDt = changeDueDateTo.toStartOfMonth().addMonths(1).toStartOfWeek().AddDays(1);
                            changeDueDateTo = tempDt.addDays(14).toStartOfWeek().AddDays(1);
                        }
                    } else if (cycleSpeicficWeek == '4th week of Month') {
                        changeDueDateTo = changeDueDateTo.addDays(21).toStartOfWeek().toStartOfWeek().AddDays(1);
                        if(changeDueDateTo < currentDueDate ){
                            tempDt = changeDueDateTo.toStartOfMonth().addMonths(1).toStartOfWeek().AddDays(1);
                            changeDueDateTo = tempDt.addDays(21).toStartOfWeek().toStartOfWeek().AddDays(1);
                        }
                    } else if (cycleSpeicficWeek == 'Last week of Month') {
                        tempDt = changeDueDateTo.toStartOfMonth();
                        integer daysInMth  =  date.daysInMonth(changeDueDateTo.year(), changeDueDateTo.month());
                        changeDueDateTo = tempDt.addDays(daysInMth - 1).toStartOfWeek().AddDays(1);
                        if(changeDueDateTo < currentDueDate ){
                            tempDt = changeDueDateTo.toStartOfMonth().addMonths(1).toStartOfWeek().AddDays(1);
                            daysInMth  =  date.daysInMonth(changeDueDateTo.year(), changeDueDateTo.month());
                            changeDueDateTo = tempDt.addDays(daysInMth - 1).toStartOfWeek().AddDays(1);
                        }
                    }
                } */
                if (cycle != 'Daily' && string.isBlank(CycleDaysFromMonthStart)) {
                    if (cycleSpecificWeekDay == 'Tuesday') {
                        changeDueDateTo = changeDueDateTo.addDays(1) ;
                    } else if (cycleSpecificWeekDay == 'Wednesday') {
                        changeDueDateTo = changeDueDateTo.addDays(2) ;
                    } else if (cycleSpecificWeekDay == 'Thursday') {
                        changeDueDateTo = changeDueDateTo.addDays(3) ;
                    } else if (cycleSpecificWeekDay == 'Friday') {
                        changeDueDateTo = changeDueDateTo.addDays(4) ;
                    }
                }
                system.debug('in while= changeDueDateTo = ' + changeDueDateTo  + ' currentDueDate= ' + currentDueDate + ' dueDtVal.dueDate=' + dueDtVal.dueDate );
        }
        system.debug('cycle=' + cycle + ', changeDueDateTo='+ changeDueDateTo);
        // if Due date falls on a weekend move it to the following monday
        integer weekNumber = math.mod(date.newInstance(1900,1,7).daysBetween(changeDueDateTo) ,7);
        changeDueDateTo =  weekNumber == 6?changeDueDateTo.addDays(2):changeDueDateTo ;
        changeDueDateTo =  weekNumber == 0?changeDueDateTo.addDays(1):changeDueDateTo ;
        dueDtVal.dueDate = changeDueDateTo;
        system.debug('2 cycle=' + cycle + ', changeDueDateTo='+ changeDueDateTo);
        return dueDtVal;
    }


    Public Void reSetTriggerFlowFlagAgrmnt(){
        set<id> cpaIds = new set<id>();
        for( ContractPerformance cp : cpById.values() ){
            if(cp.mainsObjectName == 'Contract_Performance_Agreement__c' ){
                cpaIds.add(cp.cpa.id);
            }
        }
        if(!(system.isbatch() || system.isFuture())){
            reSetTriggerWorkFlowFlagAgreement(cpaIds);
        }
    }

    @future
    public static void reSetTriggerWorkFlowFlagAgreement(set<id> cpaIds){
        if(cpaIds.size() > 0 ){
            list<Contract_Performance_Agreement__c> cpaLst = [select id, TriggerTimeBasedWorkflow__c ,TriggerTimeBasedWorkflowSetNextFlag__c from Contract_Performance_Agreement__c where id in :cpaIds and TriggerTimeBasedWorkflowSetNextFlag__c = true];
            for(Contract_Performance_Agreement__c cpa : cpaLst){

                cpa.TriggerTimeBasedWorkflowSetNextFlag__c = false;
            }
            update cpaLst;
        }
    }

    Public Void reSetTriggerFlowFlagSLACOA(){
        set<id> cpaIds = new set<id>();
        for( ContractPerformance cp : cpById.values() ){
            if(cp.mainsObjectName == 'Contract_Performance_SLA_COA__c' ){
                for( Contract_Performance_SLA_COA__c slaCoa : cp.slaCoaLst ){
                    cpaIds.add(slaCoa.id);
                }
            }
        }
        if(!(system.isbatch() || system.isFuture())){
            reSetTriggerWorkFlowFlagSLACOA(cpaIds);
        }

    }

    @future
    public static void reSetTriggerWorkFlowFlagSLACOA(set<id> cpaIds){
        if(cpaIds.size() > 0 ){
            list<Contract_Performance_SLA_COA__c> slaCoaLst = [select id, TriggerTimeBasedWorkflow__c,TriggerTimeBasedWorkflowSetNextFlag__c from Contract_Performance_SLA_COA__c where id in :cpaIds and TriggerTimeBasedWorkflowSetNextFlag__c = true];
            for(Contract_Performance_SLA_COA__c slacoa : slaCoaLst){
                slacoa.TriggerTimeBasedWorkflow__c = true;
                slacoa.TriggerTimeBasedWorkflowSetNextFlag__c = false;
            }
            update slaCoaLst;
        }
    }
    
	// set DueDate for Agreement
    public void setNextDueDateAgreement(){
        date changeDueDateTo ;
        for( ContractPerformance cp : cpById.values() ){
            // process next due date
            if((
                    cp.Cpa.Re_calculate_DueDate__c == true
            )  )
            {
                // Set Due Date
                cp.Cpa.TriggerTimeBasedWorkflow__c = false;
                cp.Cpa.Re_calculate_DueDate__c = false;
                cp.cpa.TriggerTimeBasedWorkflowSetNextFlag__c = true;
                DueDates dueDateVal = new DueDates(cp.Cpa.Due_Date__c );
                dueDateVal.LeadTimeReminderInDays = integer.valueOf(cp.Cpa.Lead_Time_Reminder_in_Days__c) ;
                dueDateVal.LeadTimeReminderInHours = integer.valueOf(cp.Cpa.Lead_Time_Reminder_in_Hours__c) ;

                dueDateVal = setNextDueDateValues(dueDateVal,cp.Cpa.Start_Date__c,cp.Cpa.Cycle__c, cp.Cpa.Cycle_Specific_Week__c, cp.Cpa.Cycle_Specific_Weekday__c, cp.Cpa.Cycle_Days_From_Month_Start__c );
                system.debug('dueDateVal=' + dueDateVal  );
                cp.Cpa.Due_Date__c = dueDateVal.dueDate;
                cp.Cpa.Due_Date_Reminder__c = dueDateVal.dueDateReminder;
                system.debug('cp.Cpa.Due_Date__c='+ cp.Cpa.Due_Date__c + ' , cp.Cpa.Due_Date_Reminder__c= '+   cp.Cpa.Due_Date_Reminder__c);
                cp.Cpa.Cycle_Specific_Week__c =  cp.Cpa.Cycle__c == 'Daily' || cp.Cpa.Cycle__c == 'Weekly' ? '':cp.Cpa.Cycle_Specific_Week__c;
                cp.Cpa.Cycle_Specific_Weekday__c =  cp.Cpa.Cycle__c == 'Daily'  ? '':cp.Cpa.Cycle_Specific_Weekday__c;
                if(cp.Cpa.Cycle__c == null){
                    cp.Cpa.Cycle_Specific_Week__c = '';
                    cp.Cpa.Cycle_Specific_Weekday__c  = '';
                }
                // if duedate has changed
            } else if(cp.oldCpa == null || (
                        cp.oldCpa.Due_Date__c != cp.Cpa.Due_Date__c
                    ||  cp.oldCpa.Lead_Time_Reminder_in_Days__c != cp.Cpa.Lead_Time_Reminder_in_Days__c
                    ||  cp.oldCpa.Lead_Time_Reminder_in_Hours__c != cp.Cpa.Lead_Time_Reminder_in_Hours__c
            ) ){
                // Only due date and related field  has changed synch dueDateReminder
                DueDates dueDateVal = new DueDates(cp.Cpa.Due_Date__c );
                dueDateVal.LeadTimeReminderInDays = integer.valueOf(cp.Cpa.Lead_Time_Reminder_in_Days__c) ;
                dueDateVal.LeadTimeReminderInHours = integer.valueOf(cp.Cpa.Lead_Time_Reminder_in_Hours__c) ;
                cp.Cpa.Due_Date_Reminder__c = dueDateVal.dueDateReminder;
            }
        }
    }
	
    public void onResultSendReminder(){
    	list<task> tskLst = new list<task>();
        map<id,Contract_Performance_Result__c> reminderRsltBySLACOAID = new map<id,Contract_Performance_Result__c>(); 
        
        for( ContractPerformance cp : cpById.values() ){
            if(cp.mainsObjectName == 'Contract_Performance_Result__c'){
                for( Contract_Performance_Result__c rslt : cp.rsltLst ){
                    system.debug('in trigger 1 cp.rsltLst=' + cp.rsltLst.size() + ' rslt id' + rslt.id );
                    if(rslt.isReminderEmailWorkflowFlag__c == true){
                        reminderRsltBySLACOAID.put(rslt.Contract_Performance_SLA_COA__c , rslt);
                    }
                } 
            }
        }
        
        if(reminderRsltBySLACOAID.size() > 0){
            list<Contract_Performance_SLA_Team__c> remLst = [select id, SLA__c,Team_Member__c,Team_Member_Email__c from Contract_Performance_SLA_Team__c where SLA__c in : reminderRsltBySLACOAID.keySet() ];
            
            for( ContractPerformance cp : cpById.values() ) { 
                for (Contract_Performance_Result__c rslt : cp.rsltLst) {
                    system.debug('cp.rsltLst size=' + cp.rsltLst.size() + 'rslt..id=' + rslt.id + 'rslt.isBreachedWorkflowFlag__c = ' + rslt.isBreachedWorkflowFlag__c );
                    if(rslt.isReminderEmailWorkflowFlag__c == true){
                        rslt.isReminderEmailWorkflowFlag__c = false;
                        // Create Task for owner of SLA
                        date dt = rslt.Result_Due_Date__c;
                        string sDescription = 'The following Customer Performance SLA Result is Due on:\t' +  dt.format() ;
                        sDescription = sDescription +  '\r\nResult Record Name:\t' +  rslt.name + '\r\nEntity Name:\t' +  rslt.Legal_Entity_Name__c  +   '\r\nContract Performance Agreement:\t' + rslt.Contract_Performance_Agreement_Name__c  + '\r\n' + rslt.Type__c +  'Name:\t' +  rslt.SLACOA_Name__c +  '\r\nMeasure:\t' +  rslt.Measurement_Name__c + '\r\nMeasure Description:\t' +  rslt.Measurement_Description__c  + '\r\nResult Cycle:\t' +  rslt.Cycle__c;    
                        task tsk = new Task(subject = 'Contract Performance SLA Reminder'
                            , Type = 'Email'
                            , Category__c = 'Internal'
                            , Status = 'Completed'
                            , Priority = 'High'
                            , WhatId =  rslt.id
                            ,OwnerId = rslt.ownerid
                            , email__c = userinfo.getUserEmail()
                            , Description = sDescription
                            ,ActivityDate = rslt.Result_Due_Date__c > date.today()?date.today():rslt.Result_Due_Date__c
                            );
                            tskLst.add(tsk);	
                        //Create Task for Team Members 
                        for(Contract_Performance_SLA_Team__c cpt : remLst ){
                            tsk = new Task(subject = 'Contract Performance SLA Reminder'
                            , Type = 'Email'
                            , Category__c = 'Internal'
                            , Status = 'Completed'
                            , Priority = 'High'
                            , WhatId =  rslt.id
                            ,OwnerId = cpt.Team_Member__c
                            , email__c = cpt.Team_Member_Email__c
                            , Description = sDescription
                            ,ActivityDate = rslt.Result_Due_Date__c > date.today()?date.today():rslt.Result_Due_Date__c
                            );
                            tskLst.add(tsk);
                            system.debug('In Trigger Breach Task created for what.id ' + rslt.id  );
                        }  
                    }
                }
            }
            insert tskLst;
            system.debug('Tasks inserted');
        }
    }
    
    public void onResultIsBreached(){

        list<task> tskLst = new list<task>();
        map<id,Contract_Performance_Result__c> breachedRsltByCpaID = new map<id,Contract_Performance_Result__c>();

        for( ContractPerformance cp : cpById.values() ){
            if(cp.mainsObjectName == 'Contract_Performance_Result__c'){
                for( Contract_Performance_Result__c rslt : cp.rsltLst ){
                    system.debug('in trigger 1 cp.rsltLst=' + cp.rsltLst.size() + ' rslt id' + rslt.id );
                    if(rslt.isBreachedWorkflowFlag__c == true){
                        breachedRsltByCpaID.put(rslt.ContractPerformanceAgreementID__c , rslt);
                    }
                }
            }
            
            
        }
        if(breachedRsltByCpaID.size() > 0){
            //Team_Member__c,
            list<Contract_Performance_Team__c> breachLst = [select id, Contract_Performance_Agreement__c,Email_To__c from Contract_Performance_Team__c where Contract_Performance_Agreement__c in : breachedRsltByCpaID.keySet() and role__c = 'Contact on Breach'  ];
            for( ContractPerformance cp : cpById.values() ) {
                //system.debug('cp.rsltLst.size=' + cp.rsltLst.size() );
                for (Contract_Performance_Result__c rslt : cp.rsltLst) {
                    system.debug('cp.rsltLst size=' + cp.rsltLst.size() + 'rslt..id=' + rslt.id + 'rslt.isBreachedWorkflowFlag__c = ' + rslt.isBreachedWorkflowFlag__c );
                    if(rslt.isBreachedWorkflowFlag__c == true){
                        rslt.isBreachedWorkflowFlag__c = false;
                        rslt.Result_Has_Breached__c = true;
                        for(Contract_Performance_Team__c cpt : breachLst ){
                            /*task tsk = new Task(subject = 'Contract Performance SLA/COA Breached'
                            , Type = 'Reminder'
                            , Category__c = 'Internal'
                            , Status = 'Completed'
                            , Priority = 'High'
                            , WhatId =  rslt.id
                            ,OwnerId = cpt.Team_Member__c
                            , Description = 'Result Record Name:\t' +  rslt.name + '\r\nEntity Name:\t' +  rslt.Legal_Entity_Name__c  +   '\r\nContract Performance Agreement:\t' + rslt.Contract_Performance_Agreement_Name__c  + '\r\n' + rslt.Type__c +  'Name:\t' +  rslt.SLACOA_Name__c +  '\r\nMeasure:\t' +  rslt.Measurement_Name__c + '\r\nMeasure Description:\t' +  rslt.Measurement_Description__c  + '\r\nResult Cycle:\t' +  rslt.Cycle__c
                            ,ActivityDate = rslt.Result_Due_Date__c > date.today()?date.today():rslt.Result_Due_Date__c
                            );
*/
                            task tsk = new Task(subject = 'Contract Performance SLA/COA Breached'
                            , Type = 'Email'
                            , Category__c = 'Internal'
                            , Status = 'Completed'
                            , Priority = 'High'
                            , WhatId =  rslt.id
                            //,OwnerId = cpt.Team_Member__c
                            , email__c = cpt.Email_To__c
                            , Description = 'Result Record Name:\t' +  rslt.name + '\r\nEntity Name:\t' +  rslt.Legal_Entity_Name__c  +   '\r\nContract Performance Agreement:\t' + rslt.Contract_Performance_Agreement_Name__c  + '\r\n' + rslt.Type__c +  'Name:\t' +  rslt.SLACOA_Name__c +  '\r\nMeasure:\t' +  rslt.Measurement_Name__c + '\r\nMeasure Description:\t' +  rslt.Measurement_Description__c  + '\r\nResult Cycle:\t' +  rslt.Cycle__c
                            ,ActivityDate = rslt.Result_Due_Date__c > date.today()?date.today():rslt.Result_Due_Date__c
                            );
                            tskLst.add(tsk);
                            system.debug('In Trigger Breach Task created for what.id ' + rslt.id  );
                        }
                    }
                }
            }
            insert tskLst;
            system.debug('Tasks inserted');
        }

    }

    public void setNextDueDateSLACOA(){
        date changeDueDateTo ;
        date startDt;
        // cpaIDBySlaCOAid
        set<id> slaCoaIdsToCreateNewResults  = new set<id>();
        for( ContractPerformance cp : cpById.values() ){
            if(cp.mainsObjectName == 'Contract_Performance_SLA_COA__c'){
                for( Contract_Performance_SLA_COA__c slaCoa : cp.slaCoaLst ){
                    // only process rows that are in  cpById ie: Active rows only
                    Contract_Performance_SLA_COA__c oldSLACOA = cp.oldSlaCoaById != null?cp.oldSlaCoaByID.get(slaCoa.id):null;
                    if(cpaIDBySlaCOAid.containsKey(slaCoa.id) ){
                        startDt = cpById.get(cpaIDBySlaCOAid.get(slaCoa.id)).cpa.Start_Date__c;

                        if(oldSLACOA == null || (
                                slaCoa.Re_calculate_DueDate__c == true
                        )  )
                        {
                            // Set Due Date
                            slaCoa.TriggerTimeBasedWorkflow__c = false;
                            slaCoa.Re_calculate_DueDate__c = false ;
                            slaCoa.TriggerTimeBasedWorkflowSetNextFlag__c = true;
                            DueDates dueDateVal = new DueDates(slaCoa.Due_Date__c );
                            dueDateVal.LeadTimeReminderInDays = integer.valueOf(slaCoa.Lead_Time_Reminder_in_Days__c) ;
                            dueDateVal.LeadTimeReminderInHours = integer.valueOf(slaCoa.Lead_Time_Reminder_in_Hours__c) ;

                            dueDateVal = setNextDueDateValues(dueDateVal,startDt,slaCoa.Cycle__c, slaCoa.Cycle_Specific_Week__c, slaCoa.Cycle_Specific_Weekday__c,slacoa.Cycle_Days_From_Month_Start__c );
                            //slaCoa.TriggerTimeBasedWorkflow__c = false;

                            slaCoa.Due_Date__c = dueDateVal.dueDate;
                            slaCoa.Due_Date_Reminder__c = dueDateVal.dueDateReminder;
                            slaCoa.Cycle_Specific_Week__c =  slaCoa.Cycle__c == 'Daily' || slaCoa.Cycle__c == 'Weekly' ? '':slaCoa.Cycle_Specific_Week__c;
                            slaCoa.Cycle_Specific_Weekday__c =  slaCoa.Cycle__c == 'Daily'  ? '':slaCoa.Cycle_Specific_Weekday__c;
                            if(slaCoa.Cycle__c == null){
                                slaCoa.Cycle_Specific_Week__c = '';
                                slaCoa.Cycle_Specific_Weekday__c  = '';
                            }

                        } else if(oldSLACOA== null || (
                                oldSLACOA.Due_Date__c != slaCoa.Due_Date__c
                                        ||  oldSLACOA.Lead_Time_Reminder_in_Days__c != slaCoa.Lead_Time_Reminder_in_Days__c
                                        ||  oldSLACOA.Lead_Time_Reminder_in_Hours__c != slaCoa.Lead_Time_Reminder_in_Hours__c
                        ) ){
                            // Only due date and related field  has changed synch dueDateReminder
                            DueDates dueDateVal = new DueDates(slaCoa.Due_Date__c );
                            dueDateVal.LeadTimeReminderInDays = integer.valueOf(slaCoa.Lead_Time_Reminder_in_Days__c) ;
                            dueDateVal.LeadTimeReminderInHours = integer.valueOf(slaCoa.Lead_Time_Reminder_in_Hours__c) ;
                            slaCoa.Due_Date_Reminder__c = dueDateVal.dueDateReminder;
                    }
                    }
                }
            }
        }

    }

    //populateContractPerformanceAgrement is object is SLACOA
    private void populateCPAfromSLACOA(list<Contract_Performance_SLA_COA__c> slaCoaLst, map<id,Contract_Performance_SLA_COA__c> oldSlaCoaLst, map<id,id> mappingCPAidBySlaCoa){
        set<id> cpaIds = new set<id>(mappingCPAidBySlaCoa.values());
        list<Contract_Performance_Agreement__c> cpaLst =  [select id,Cycle__c, Cycle_Specific_Week__c,Cycle_Specific_Weekday__c, Cycle_Days_From_Month_Start__c, Due_Date__c, Due_Date_Reminder__c, Active__c,Start_Date__c ,TriggerTimeBasedWorkflow__c  from Contract_Performance_Agreement__c where id in  :cpaIds ] ;
        ContractPerformance cp;
        string mainsObject = 'Contract_Performance_SLA_COA__c';
        for(Contract_Performance_Agreement__c cpa : cpaLst ){
           if(cpa.Active__c == true) {
               cp = new ContractPerformance(mainsObject);
               cp.cpa = cpa;
               cpById.put(cpa.id, cp);
               cp.mainsObjectName = mainsObject ;
               for(Contract_Performance_SLA_COA__c slaCOA : slaCoaLst){
                   if(mappingCPAidBySlaCoa.containsKey(slaCOA.id) ){
                       cp.slaCoaLst.add(slaCOA)  ;
                       if(oldSlaCoaLst != null){
                           cp.oldSlaCoaByID = cp.oldSlaCoaByID == null? (new map<id, Contract_Performance_SLA_COA__c>() ) : cp.oldSlaCoaByID;
                           cp.oldSlaCoaByID.put(oldSlaCoaLst.get(slaCOA.id).id,oldSlaCoaLst.get(slaCOA.id) );
                       }
                   }
               }
           }
       }
    }

	
	// Populate parent data from Result object
    private void populateCPAfromResult(list<Contract_Performance_Result__c> objLst, map<id, Contract_Performance_Result__c> oldObjLst , map<id,id> mappingCpaByResult ) {
        string mainsObject = 'Contract_Performance_Result__c';
        ContractPerformance cp;
        Contract_Performance_Agreement__c cpa;
        Contract_Performance_SLA_COA__c slaCOA ;
        system.debug('in populate CPA from Result orig rlst size' + objLst.size());
        for(Contract_Performance_Result__c cpr: objLst ){
            cpa = new Contract_Performance_Agreement__c(id=cpr.ContractPerformanceAgreementID__c);
            if( cpById.containsKey(cpa.id) ) {
              cp =   cpById.get(cpa.id);
            } else {
                cp = new ContractPerformance(mainsObject);

                cp.cpa = cpa;
                cpById.put(cpa.id, cp);
                cp.mainsObjectName = mainsObject ;
            }
            slaCOA = new Contract_Performance_SLA_COA__c(id = cpr.Contract_Performance_SLA_COA__c);
            cp.slaCoaLst.add(slaCOA);
            cp.mappingSLACOAbyResultID.put(cpr.id,cpr.Contract_Performance_SLA_COA__c);
            cp.rsltLst.add(cpr);
            if(oldObjLst != null ){
                cp.oldRsltById = cp.oldRsltById == null?(new map<id,Contract_Performance_Result__c>() ):cp.oldRsltById;
                cp.oldRsltById.put(cpr.id,oldObjLst.get(cpr.id) );
            }
        }
        system.debug('in populate CPA from Result cp.rsltLst' + cp.rsltLst.size());
    }

	// populate SLACOA form Agreement
    private void populateSLACOAfromCPA(){
        list<Contract_Performance_SLA_COA__c> slaCoaLst = [select id, Contract_Performance_Agreement__c , Due_Date__c, Due_Date_Reminder__c,Create_New_Result_Records__c,COA_Result_Owner_Email__c from Contract_Performance_SLA_COA__c where  Contract_Performance_Agreement__c in :cpById.keySet() and Active__c = true ];
        for(Contract_Performance_SLA_COA__c slaCoa : slaCoaLst ){
            cpById.get(slaCoa.Contract_Performance_Agreement__c).slaCoaLst.add(slaCoa);
        }
    }

	// Create new Result Records
    public void CreateResultRecords(){
        list<Contract_Performance_Result__c> rslt = new list<Contract_Performance_Result__c>();
        id SLAQueueId ;
        try{
            SLAQueueId= [SELECT Id from group where developername = 'Contract_Performance_SLA_Queue' and type = 'Queue'].id;
        } catch(exception ex){
            SLAQueueId = null;
        }

        SLAQueueId = SLAQueueId == null?userinfo.getUserId():SLAQueueId;
        set<id> slaCoaIds = new set<id>();

        Map<id, Contract_Performance_SLA_COA__c> tmpTriggerNewMap  = new Map<id, Contract_Performance_SLA_COA__c>((list<Contract_Performance_SLA_COA__c>)trigger.new);

        for( ContractPerformance cp : cpById.values() ){
            for(Contract_Performance_SLA_COA__c slaCoa : cp.slaCoaLst){
                Contract_Performance_SLA_COA__c oldSLACOA =  cp.oldSlaCoaByID == null?null:cp.oldSlaCoaByID.get(slaCoa.id);
                    slaCoaIds.add(slaCoa.id);
            }
        }

        list<Contract_Performance_SLA_COA__c> slaCoaLst = [select id,recordtypeid, recordtype.name,Assigned_To__c ,Contract_Performance_Agreement__c, Due_Date__c,Due_Date_Reminder__c,Create_New_Result_Records__c,COA_Result_Owner_Email__c from Contract_Performance_SLA_COA__c where id in :slaCoaIds and Create_New_Result_Records__c = true ];
        string  sOwnerID;
        for(Contract_Performance_SLA_COA__c slaCoa : slaCoaLst ){
            if (slaCoa.recordtype.name ==  'SLA' ){
                //sOwnerID = SLAQueueID;
                sOwnerID = slaCoa.Assigned_To__c;
            } else if(slaCoa.recordtype.name == 'COA') {
                sOwnerID = slaCoa.Assigned_To__c;
            }
            sOwnerID = sOwnerID == null?userinfo.getUserId():sOwnerID;
            Contract_Performance_Result__c cpr = new Contract_Performance_Result__c(
                    CPA_SLACOA_ID_DueDate__c = slaCoa.Contract_Performance_Agreement__c + '|' +  slaCoa.id + '|' + slaCoa.Due_Date__c.format()
            , Contract_Performance_SLA_COA__c = slaCoa.id
            , Result_Due_Date__c = slaCoa.Due_Date__c
            , Result_Due_Date_Reminder__c = slaCoa.Due_Date_Reminder__c
            , ownerid =  sOwnerID
            , COA_Result_Owner_Email__c = slaCoa.recordtype.name == 'COA'?slaCoa.COA_Result_Owner_Email__c:null
            );
            rslt.add(cpr);
        }
        Database.UpsertResult[] srList = Database.upsert(rslt,Contract_Performance_Result__c.Fields.CPA_SLACOA_ID_DueDate__c ,false);
        for (Database.UpsertResult sr : srList) {
            if (!sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                // Operation failed, so get all errors
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        }
        setNewRsltFlagSLACOA(slaCoaIds);

    }



	// Flattened container object for Agreement, SLA/COA and Result
    public class ContractPerformance{
        public Contract_Performance_Agreement__c cpa {get;  set;}
        public Contract_Performance_Agreement__c oldCpa {get;  set;}
        public boolean cpaUpdated {get; set;}
        public list<Contract_Performance_SLA_COA__c> slaCoaLst {get;  set ;}
        public Map<id,Contract_Performance_SLA_COA__c> oldSlaCoaByID {get;  set ;}
        public list<Contract_Performance_Result__c> rsltLst {get;  set;}
        public map<id,Contract_Performance_Result__c> oldRsltById {get;  set;}
        public map<id,id> mappingSLACOAbyResultID {get; set;}
        public string mainsObjectName {get;  private set;}
        Public ContractPerformance(string sObjName){
            mainsObjectName = sObjName;
            cpaUpdated = false;
            slaCoaLst = new list<Contract_Performance_SLA_COA__c>();
            rsltLst = new list<Contract_Performance_Result__c>();
            mappingSLACOAbyResultID = new map<id,id>();
        }
    }
	
    // Container object for DueDate and Reminder Due Date
    public class DueDates{
        public Date dueDate {get;
            set{ this.dueDate = value;
                this.setDueDateReminder();
            }
        }
        public DateTime dueDateReminder {get; private set;}
        Integer LeadTimeReminderInDays {get;
            set{
                this.LeadTimeReminderInDays = value;
                this.setDueDateReminder();
            }
        }
        Integer LeadTimeReminderInHours {get;
            set{
                this.LeadTimeReminderInHours = value;
                this.setDueDateReminder();
            }
        }
        public DueDates(date dueDateVal){
            dueDate = dueDateVal;
            LeadTimeReminderInDays = 0;
            LeadTimeReminderInHours = 0;
        }
        private void setDueDateReminder(){
            if(this.dueDate != null){
                datetime remiderDt = datetime.newInstance(this.dueDate ,Time.newinstance(0,0,0,0));
                integer days = integer.valueOf(this.LeadTimeReminderInDays == null?0:this.LeadTimeReminderInDays) ;
                integer hours = integer.valueof( this.LeadTimeReminderInHours == null?0:this.LeadTimeReminderInHours);
                this.dueDateReminder = remiderDt.addDays(-days).addHours(- hours );
            } else {
                this.dueDateReminder = null;
            }
        }
    }
}