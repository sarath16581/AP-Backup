/*------------------------------------------------------------------------
Author:        Matt Yogaratnam
Company:       Salesforce.com
Description:   A test class created to test the Revenue by Organisation batch process
               Test executed:
               1 - Test where no prior record exists for Org for Fin year
               2 - Test where a prior record exists for org for fin year

Test Class:
History
<Date>      <Authors Name>     <Brief Description of Change>
27-03-2014  Mattt Yogaratnam    Initial Release
--------------------------------------------------------------------------*/
@isTest
private class CalcRevByOrg_Test {

    //Test where no prior record exists for Org for Fin year
    static testMethod void orgRevCalcTestNewOrgRev() {

        //creates a system settings environment in which all levels of logs are accepted.
        SystemSettings__c systemSettingsForTests = new SystemSettings__c(
                Loglevel_Debug__c = true,
                Loglevel_Error__c = true,
                Loglevel_Warning__c = true,
                Loglevel_Info__c = true
        );

        insert systemSettingsForTests;

        //create batch process custom setting

        BatchJobSettings__c settings = new BatchJobSettings__c(OrgRevCalcScopeSize__c = 2000, OrgRevCalcWindow__c = 7, OrgRevCalcWindowOffset__c = 0);
        insert settings;

        //create and org for testing
        Id orgID = createTestOrg();

        System.Debug('Test Org ID: ' + orgId);

        //create target and revenue recs 
        createTargRevRecs(orgId, '2012');

        //run test
        //Start the batch run       
        Test.startTest();

        Database.executeBatch(new CalcRevByOrgBatch(), 2000);    //batch size of 2000
        String jobId = System.schedule('CalcRevByOrgSchedule', '0 0 0 3 9 ? 2022', new CalcRevByOrgSchedule());                               
        Test.stopTest();


        //select output recs

        List<Revenue_by_Organisation__c> revList = [select 
                                                    Id,
                                                    Jan_Revenue_Amount__c,
                                                    Feb_Revenue_Amount__c,
                                                    Mar_Revenue_Amount__c,
                                                    Apr_Revenue_Amount__c,
                                                    May_Revenue_Amount__c,
                                                    Jun_Revenue_Amount__c,
                                                    Jul_Revenue_Amount__c,
                                                    Aug_Revenue_Amount__c,
                                                    Sep_Revenue_Amount__c,
                                                    Oct_Revenue_Amount__c,
                                                    Nov_Revenue_Amount__c,
                                                    Dec_Revenue_Amount__c,
                                                    Jan_Target_Amount__c,
                                                    Feb_Target_Amount__c,
                                                    Mar_Target_Amount__c,
                                                    Apr_Target_Amount__c,
                                                    May_Target_Amount__c,
                                                    Jun_Target_Amount__c,
                                                    Jul_Target_Amount__c,
                                                    Aug_Target_Amount__c,
                                                    Sep_Target_Amount__c,
                                                    Oct_Target_Amount__c,
                                                    Nov_Target_Amount__c,
                                                    Dec_Target_Amount__c,
                                                    Q1_Revenue__c,
                                                    Q2_Revenue__c,
                                                    Q3_Revenue__c,
                                                    Q4_Revenue__c,
                                                    Q1_Target__c,
                                                    Q2_Target__c,
                                                    Q3_Target__c,
                                                    Q4_Target__c,
                                                    Organisation__c,
                                                    Financial_Year__c
                                                    FROM Revenue_by_Organisation__c where Organisation__c =  :orgId];

        //check that there is only one rec
        system.assertEquals(revList.size(),1);  

        //check sum amounts
        Revenue_by_Organisation__c revOrg = revList[0];

        system.assertEquals(revOrg.Financial_Year__c, '2012');
        system.assertEquals(revOrg.Jan_Revenue_Amount__c,20);
        system.assertEquals(revOrg.Feb_Revenue_Amount__c,40);
        system.assertEquals(revOrg.Mar_Revenue_Amount__c,60);
        system.assertEquals(revOrg.Apr_Revenue_Amount__c,80);
        system.assertEquals(revOrg.May_Revenue_Amount__c,100);
        system.assertEquals(revOrg.Jun_Revenue_Amount__c,120);
        system.assertEquals(revOrg.Jul_Revenue_Amount__c,140);
        system.assertEquals(revOrg.Aug_Revenue_Amount__c,160);
        system.assertEquals(revOrg.Sep_Revenue_Amount__c,180);
        system.assertEquals(revOrg.Oct_Revenue_Amount__c,200);
        system.assertEquals(revOrg.Nov_Revenue_Amount__c,220);
        system.assertEquals(revOrg.Dec_Revenue_Amount__c,240);
        system.assertEquals(revOrg.Jan_Target_Amount__c,260);
        system.assertEquals(revOrg.Feb_Target_Amount__c,280);
        system.assertEquals(revOrg.Mar_Target_Amount__c,300);
        system.assertEquals(revOrg.Apr_Target_Amount__c,320);
        system.assertEquals(revOrg.May_Target_Amount__c,340);
        system.assertEquals(revOrg.Jun_Target_Amount__c,360);
        system.assertEquals(revOrg.Jul_Target_Amount__c,380);
        system.assertEquals(revOrg.Aug_Target_Amount__c,400);
        system.assertEquals(revOrg.Sep_Target_Amount__c,420);
        system.assertEquals(revOrg.Oct_Target_Amount__c,440);
        system.assertEquals(revOrg.Nov_Target_Amount__c,460);
        system.assertEquals(revOrg.Dec_Target_Amount__c,480);
        system.assertEquals(revOrg.Q1_Revenue__c,500);
        system.assertEquals(revOrg.Q2_Revenue__c,520);
        system.assertEquals(revOrg.Q3_Revenue__c,540);
        system.assertEquals(revOrg.Q4_Revenue__c,560);
        system.assertEquals(revOrg.Q1_Target__c,580);
        system.assertEquals(revOrg.Q2_Target__c,600);
        system.assertEquals(revOrg.Q3_Target__c,620);
        system.assertEquals(revOrg.Q4_Target__c,640);                

        //check that application log has been written
        List <Application_Log__c> al = [SELECT Id FROM Application_log__c Where Debug_Level__c = 'Info'];
        system.assertEquals(al.size(),1);


    }





    //Test where a prior record exists for Org for Fin year
    static testMethod void orgRevCalcTestUpdateOrgRev() {

        //creates a system settings environment in which all levels of logs are accepted.
        SystemSettings__c systemSettingsForTests = new SystemSettings__c(
                Loglevel_Debug__c = true,
                Loglevel_Error__c = true,
                Loglevel_Warning__c = true,
                Loglevel_Info__c = true
        );

        insert systemSettingsForTests;

        //create batch process custom setting

        BatchJobSettings__c settings = new BatchJobSettings__c(OrgRevCalcScopeSize__c = 2000, OrgRevCalcWindow__c = 7, OrgRevCalcWindowOffset__c = 0);
        insert settings;

        //create and org for testing
        Id orgID = createTestOrg();

        System.Debug('Test Org ID: ' + orgId);

        //create target and revenue recs 
        createTargRevRecs(orgId, '2012');

        //create an existing revenue record for the org for the same fin year
        createOrgRevRecs(orgId, '2012');

        //run test
        //Start the batch run       
        Test.startTest();

        Database.executeBatch(new CalcRevByOrgBatch(), 2000);    //batch size of 2000
        String jobId = System.schedule('CalcRevByOrgSchedule', '0 0 0 3 9 ? 2022', new CalcRevByOrgSchedule());                               
        Test.stopTest();


        //select output recs

        List<Revenue_by_Organisation__c> revList = [select 
                                                    Id,
                                                    Jan_Revenue_Amount__c,
                                                    Feb_Revenue_Amount__c,
                                                    Mar_Revenue_Amount__c,
                                                    Apr_Revenue_Amount__c,
                                                    May_Revenue_Amount__c,
                                                    Jun_Revenue_Amount__c,
                                                    Jul_Revenue_Amount__c,
                                                    Aug_Revenue_Amount__c,
                                                    Sep_Revenue_Amount__c,
                                                    Oct_Revenue_Amount__c,
                                                    Nov_Revenue_Amount__c,
                                                    Dec_Revenue_Amount__c,
                                                    Jan_Target_Amount__c,
                                                    Feb_Target_Amount__c,
                                                    Mar_Target_Amount__c,
                                                    Apr_Target_Amount__c,
                                                    May_Target_Amount__c,
                                                    Jun_Target_Amount__c,
                                                    Jul_Target_Amount__c,
                                                    Aug_Target_Amount__c,
                                                    Sep_Target_Amount__c,
                                                    Oct_Target_Amount__c,
                                                    Nov_Target_Amount__c,
                                                    Dec_Target_Amount__c,
                                                    Q1_Revenue__c,
                                                    Q2_Revenue__c,
                                                    Q3_Revenue__c,
                                                    Q4_Revenue__c,
                                                    Q1_Target__c,
                                                    Q2_Target__c,
                                                    Q3_Target__c,
                                                    Q4_Target__c,
                                                    Organisation__c,
                                                    Financial_Year__c
                                                    FROM Revenue_by_Organisation__c where Organisation__c =  :orgId];

        //check that there is only one rec - existing record should have been updated
        system.assertEquals(revList.size(),1);  

        //check sum amounts
        Revenue_by_Organisation__c revOrg = revList[0];

        system.assertEquals(revOrg.Financial_Year__c, '2012');
        system.assertEquals(revOrg.Jan_Revenue_Amount__c,20);
        system.assertEquals(revOrg.Feb_Revenue_Amount__c,40);
        system.assertEquals(revOrg.Mar_Revenue_Amount__c,60);
        system.assertEquals(revOrg.Apr_Revenue_Amount__c,80);
        system.assertEquals(revOrg.May_Revenue_Amount__c,100);
        system.assertEquals(revOrg.Jun_Revenue_Amount__c,120);
        system.assertEquals(revOrg.Jul_Revenue_Amount__c,140);
        system.assertEquals(revOrg.Aug_Revenue_Amount__c,160);
        system.assertEquals(revOrg.Sep_Revenue_Amount__c,180);
        system.assertEquals(revOrg.Oct_Revenue_Amount__c,200);
        system.assertEquals(revOrg.Nov_Revenue_Amount__c,220);
        system.assertEquals(revOrg.Dec_Revenue_Amount__c,240);
        system.assertEquals(revOrg.Jan_Target_Amount__c,260);
        system.assertEquals(revOrg.Feb_Target_Amount__c,280);
        system.assertEquals(revOrg.Mar_Target_Amount__c,300);
        system.assertEquals(revOrg.Apr_Target_Amount__c,320);
        system.assertEquals(revOrg.May_Target_Amount__c,340);
        system.assertEquals(revOrg.Jun_Target_Amount__c,360);
        system.assertEquals(revOrg.Jul_Target_Amount__c,380);
        system.assertEquals(revOrg.Aug_Target_Amount__c,400);
        system.assertEquals(revOrg.Sep_Target_Amount__c,420);
        system.assertEquals(revOrg.Oct_Target_Amount__c,440);
        system.assertEquals(revOrg.Nov_Target_Amount__c,460);
        system.assertEquals(revOrg.Dec_Target_Amount__c,480);
        system.assertEquals(revOrg.Q1_Revenue__c,500);
        system.assertEquals(revOrg.Q2_Revenue__c,520);
        system.assertEquals(revOrg.Q3_Revenue__c,540);
        system.assertEquals(revOrg.Q4_Revenue__c,560);
        system.assertEquals(revOrg.Q1_Target__c,580);
        system.assertEquals(revOrg.Q2_Target__c,600);
        system.assertEquals(revOrg.Q3_Target__c,620);
        system.assertEquals(revOrg.Q4_Target__c,640);             

        //check that application log has been written
        List <Application_Log__c> al = [SELECT Id FROM Application_log__c Where Debug_Level__c = 'Info'];
        system.assertEquals(al.size(),1);


    }   

    //method for creating a test account
    static Id createTestOrg(){

        Account acct = new Account (Name = 'TestOrg',
                Legal_Name__c = 'Test Org');

        insert acct;  

        return acct.Id;                                 

    }

    //method for creating Target and Revenue records for an org
    static void createTargRevRecs(Id orgId, String finYear){

        List<Budget_and_Revenue__c> targRevList = new List<Budget_and_Revenue__c>();

        for (Integer i=0; i <2; i++){

            Budget_and_Revenue__c targRev = new Budget_and_Revenue__c(
                    Jan_Revenue_Amount__c           =   10  ,
                    Feb_Revenue_Amount__c           =   20  ,
                    Mar_Revenue_Amount__c           =   30  ,
                    Apr_Revenue_Amount__c           =   40  ,
                    May_Revenue_Amount__c           =   50  ,
                    Jun_Revenue_Amount__c           =   60  ,
                    Jul_Revenue_Amount__c           =   70  ,
                    Aug_Revenue_Amount__c           =   80  ,
                    Sep_Revenue_Amount__c           =   90  ,
                    Oct_Revenue_Amount__c           =   100 ,
                    Nov_Revenue_Amount__c           =   110 ,
                    Dec_Revenue_Amount__c           =   120 ,
                    Jan_Original_Budget__c          =   130 ,
                    Feb_Original_Budget__c          =   140 ,
                    Mar_Original_Budget__c          =   150 ,
                    Apr_Original_Budget__c          =   160 ,
                    May_Original_Budget__c          =   170 ,
                    Jun_Original_Budget__c          =   180 ,
                    Jul_Original_Budget__c          =   190 ,
                    Aug_Original_Budget__c          =   200 ,
                    Sep_Original_Budget__c          =   210 ,
                    Oct_Original_Budget__c          =   220 ,
                    Nov_Original_Budget__c          =   230 ,
                    Dec_Original_Budget__c          =   240 ,
                    Q1_Revenue_Amount__c            =   250 ,
                    Q2_Revenue_Amount__c            =   260 ,
                    Q3_Revenue_Amount__c            =   270 ,
                    Q4_Revenue_Amount__c            =   280 ,
                    Q1_Original_Budget__c           =   290 ,
                    Q2_Original_Budget__c           =   300 ,
                    Q3_Original_Budget__c           =   310 ,
                    Q4_Original_Budget__c           =   320 ,
                    Organisation__c = orgId,
                    Financial_Year__c = finYear
            );

            targRevList.add(targRev);

        }       

        insert targRevList;


    }

    static void createOrgRevRecs(Id orgId, String finYear){

        Revenue_by_Organisation__c orgRev = new Revenue_by_Organisation__c(
                Jan_Revenue_Amount__c   =   10  ,
                Feb_Revenue_Amount__c   =   20  ,
                Mar_Revenue_Amount__c   =   30  ,
                Apr_Revenue_Amount__c   =   40  ,
                May_Revenue_Amount__c   =   50  ,
                Jun_Revenue_Amount__c   =   60  ,
                Jul_Revenue_Amount__c   =   70  ,
                Aug_Revenue_Amount__c   =   80  ,
                Sep_Revenue_Amount__c   =   90  ,
                Oct_Revenue_Amount__c   =   100 ,
                Nov_Revenue_Amount__c   =   110 ,
                Dec_Revenue_Amount__c   =   120 ,
                Jan_Target_Amount__c    =   130 ,
                Feb_Target_Amount__c    =   140 ,
                Mar_Target_Amount__c    =   150 ,
                Apr_Target_Amount__c    =   160 ,
                May_Target_Amount__c    =   170 ,
                Jun_Target_Amount__c    =   180 ,
                Jul_Target_Amount__c    =   190 ,
                Aug_Target_Amount__c    =   200 ,
                Sep_Target_Amount__c    =   210 ,
                Oct_Target_Amount__c    =   220 ,
                Nov_Target_Amount__c    =   230 ,
                Dec_Target_Amount__c    =   240 ,
                Q1_Revenue__c   =   250 ,
                Q2_Revenue__c   =   260 ,
                Q3_Revenue__c   =   270 ,
                Q4_Revenue__c   =   280 ,
                Q1_Target__c    =   290 ,
                Q2_Target__c    =   300 ,
                Q3_Target__c    =   310 ,
                Q4_Target__c    =   320 ,
                Organisation__c = orgId,
                Financial_Year__c = finYear
        );
 



        insert orgRev;
    }
}