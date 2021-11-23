/**************************************************
Type:		Test Class for ContractPerformanceService
Purpose:	
History:
--------------------------------------------------
07.12.2017    Clint D'Silva    Created
**************************************************/
@IsTest
public with sharing class ContractPerformanceService_Test {
    static Account acc;
    static Contract_Performance_Measurement__c cpm;
    static Contract_Performance_Agreement__c cpa;
    static List<Contract_Performance_SLA_COA__c>  slaCoaLst;
    static Contract_Performance_Team__c cpt;
    static Map<string,recordtype> recTyBysObjNamRecTyNam = new Map<string,recordtype>();

    static testMethod void CheckNextDueDate() {
        createData();
        test.startTest();

            cpa.Cycle__c = 'Daily';
            cpa.Lead_Time_Reminder_in_Days__c = 1;
            cpa.Re_calculate_DueDate__c = true;


            for(Contract_Performance_SLA_COA__c slacoa : slaCoaLst){
                slacoa.Cycle__c = 'Daily';
                slacoa.Lead_Time_Reminder_in_Days__c = 1;
                slacoa.Re_calculate_DueDate__c = true;
            }
        update cpa;
        test.stopTest();
       
        list<Contract_Performance_Agreement__c> cpaRslt =  [select id, Due_Date__c from Contract_Performance_Agreement__c where id = :cpa.id ];
         system.assert(   cpaRslt[0].Due_Date__c >= date.today().addDays(1) , 'Next due date not calculated for Contract Agreement');


        update slaCoaLst;
        list<Contract_Performance_SLA_COA__c> slacoaRslt = [select id ,Due_Date__c, Due_Date_Reminder__c from Contract_Performance_SLA_COA__c where id in : slaCoaLst  ];
        for(Contract_Performance_SLA_COA__c slacoa : slaCoaRslt) {
             system.assert(slacoa.Due_Date__c >= date.today().addDays(1), 'Next due date not calculated for SLA/COA');
             system.assert( slacoa.Due_Date_Reminder__c.date() >=  date.today(), 'Reminder date is incorrect');
        }
		 // cpa.Due_Date__c = date.today();
         system.debug('$$$@ cpa.Due_Date__c='+ cpa.Due_Date__c + ' , ' + cpa.Start_Date__c + ',  End_Date__c=' +  cpa.End_Date__c);
         
         cpa.Start_Date__c = date.today().addDays(-40);
         cpa.End_Date__c = date.today().addYears(5);
         cpa.Due_Date__c = date.today();
         cpa.Cycle__c = 'Monthly';
         cpa.Re_calculate_DueDate__c = true;	
         update cpa;
        
         cpa.Cycle__c = 'Weekly';
         cpa.Re_calculate_DueDate__c = true;
         update cpa;
        
         cpa.Cycle__c = 'Quaterly';
         cpa.Re_calculate_DueDate__c = true;
         update cpa;
        
         /*cpa.Cycle_Specific_Week__c = '2nd week of Month';
         update cpa;
        
		 cpa.Cycle_Specific_Week__c ='3rd week of Month';
         update cpa;
        
         cpa.Cycle_Specific_Week__c ='4th week of Month' ;    
         update cpa;
        
         cpa.Cycle_Specific_Week__c ='Last week of Month' ;    
         update cpa;
        */
        cpa.Cycle__c = 'Annual';
        cpa.Cycle_Specific_Week__c ='';
        cpa.Re_calculate_DueDate__c = true;
         update cpa;
    }

    static testMethod void CreateNewResultsandCheckBreach() {
        createData();
        test.startTest();
        map<id,Contract_Performance_SLA_COA__c> slacoaByID = new  map<id,Contract_Performance_SLA_COA__c>(slaCoaLst);
        for(Contract_Performance_SLA_COA__c slacoa : slaCoaLst){
            slacoa.Due_Date__c = system.today();

            slacoa.Create_New_Result_Records__c = true;
        }
        test.stopTest();
        update slaCoaLst;

        list<Contract_Performance_Result__c> cprLst = [select id,Contract_Performance_SLA_COA__c ,isBreachedWorkflowFlag__c,Result_Due_Date__c , type__C from Contract_Performance_Result__c where Contract_Performance_SLA_COA__c in : slaCoaLst ];
        //system.assertEquals(slaCoaLst.size() , cprLst.size() , 'Contract Performance Results not created');
        for(Contract_Performance_Result__c cpr : cprLst) {
            ////system.assertEquals(slacoaByID.get(cpr.Contract_Performance_SLA_COA__c).Due_Date__c, cpr.Result_Due_Date__c,'Result due date incorrectly calculated');
            //system.debug('cpr type:' + cpr.type__c +  'cpr.Result_Due_Date__c='+ cpr.Result_Due_Date__c);
            cpr.isBreachedWorkflowFlag__c = true;
            cpr.isReminderEmailWorkflowFlag__c = true;

        }
        Update cprLst;

        list<Task> tskLst = [select id, subject from task where WhatId in :cprLst   ];
        boolean bBreached = false;
        boolean bReminderSent = false;
        for(Task tsk : tskLst ){
        	if(tsk.subject.contains('Breached')) {
            	bBreached = true;    
            }  
            if(tsk.subject.contains('Reminder')) {
            	bReminderSent = true;    
            }  
        }
        system.assert( bBreached == true , 'Breach Tasks not created');
        system.assert(bReminderSent == true , 'Reminder Tasks not created');
    }


    public static void createData(){

        list<RecordType> recTyLst = [select id,name,sobjecttype, developername from recordtype where  developername in ('COA','SLA', 'Business_Account') and sObjectType in ('Contract_Performance_SLA_COA__c','Account') ];

        for(Recordtype rec: recTyLst){
            recTyBysObjNamRecTyNam.put(rec.sobjecttype + '|' + rec.developername,rec );
        }
        acc = new Account(name = 'AccOrg', recordtypeid = recTyBysObjNamRecTyNam.get('Account|Business_Account').id);
        insert acc;
        cpm = new Contract_Performance_Measurement__c(name = 'Measure 1', Measurement_Name__c= 'Measure 1');
        insert cpm;
        cpa = new Contract_Performance_Agreement__c(Performance_Agreement_Name__c = 'cpa1' , Start_Date__c = date.today().adddays(-10), End_Date__c = date.today().addYears(5),Due_Date__c = date.today(),  Account__c = acc.id , Active__c = true,Cycle__c = 'Daily', Lead_Time_Reminder_in_Days__c = 1	);
        insert cpa;
        cpt = new  Contract_Performance_Team__c(Email_To__c = userinfo.getUserEmail() , Contract_Performance_Agreement__c = cpa.id );
        insert cpt;
        slaCoaLst = new list<Contract_Performance_SLA_COA__c>();
        Contract_Performance_SLA_COA__c sla = new Contract_Performance_SLA_COA__c(	RecordTypeid = recTyBysObjNamRecTyNam.get('Contract_Performance_SLA_COA__c|SLA').id
        , Contract_Performance_Measurement__c = cpm.id
        , Contract_Performance_Agreement__c = cpa.id
        , Cycle__c =  cpa.Cycle__c
        , Cycle_Specific_Week__c =  cpa.Cycle_Specific_Week__c
        , Cycle_Specific_Weekday__c = cpa.Cycle_Specific_Weekday__c
        , Lead_Time_Reminder_in_Days__c = cpa.Lead_Time_Reminder_in_Days__c
        , Lead_Time_Reminder_in_Hours__c = cpa.Lead_Time_Reminder_in_Hours__c
        , Due_Date__c = cpa.Due_Date__c
                ,Active__c = true
        );
        slaCoaLst.add(sla);
        
        

        Contract_Performance_SLA_COA__c Coa = new Contract_Performance_SLA_COA__c(	RecordTypeid = recTyBysObjNamRecTyNam.get('Contract_Performance_SLA_COA__c|COA').id
        , Contract_Performance_Measurement__c = cpm.id
        , Contract_Performance_Agreement__c = cpa.id
        , Cycle__c =  cpa.Cycle__c
        , Cycle_Specific_Week__c =  cpa.Cycle_Specific_Week__c
        , Cycle_Specific_Weekday__c = cpa.Cycle_Specific_Weekday__c
        , Lead_Time_Reminder_in_Days__c = cpa.Lead_Time_Reminder_in_Days__c
        , Lead_Time_Reminder_in_Hours__c = cpa.Lead_Time_Reminder_in_Hours__c
        , Due_Date__c = cpa.Due_Date__c
        ,Active__c = true
        ,Assigned_To__c = userinfo.getUserId()
        );
        slaCoaLst.add(Coa);
        insert slaCoaLst;
        
        Contract_Performance_SLA_Team__c sLATeam = new Contract_Performance_SLA_Team__c(SLA__c = sla.id, Team_Member__c = userinfo.getUserId()  );
        
        insert sLATeam;
    }
}