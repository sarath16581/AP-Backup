/* @author Seth Heang
 * @date 2020-11-05
 * @tag Opp_Product_Classification__c
 * @domain Core
 * @description test class for OPCRevenuesRollUpBatchable
 */
@isTest
public with sharing class OPCRevenuesRollUpBatchable_Test {
    
    @TestSetup
    static void setup(){
        MockUtility.disableTriggerExecution();
        // Data Preparation
        BatchJobSettings__c jobsetting = new BatchJobSettings__c();
        jobsetting.Name = 'OPC Batchjob';
        jobsetting.OPC_Last_Modified_Date_Condition__c = 'LastModifiedDate = LAST_N_DAYS:1';
        insert jobsetting;
        
        Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert account;
        
        Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
        insert oppRec;

        // get current financial year value
        Integer currentFY = OPCRevenuesRollUpBatchable.getCurrentFinancialYear();
        

        // past financial year OPC
        Opp_Product_Classification__c opc1 = ApplicationTestDataFactory.getOpportunityProductClassification(1, account.id, oppRec.id, false, String.valueOf(currentFY-1), false)[0];
        // current financial year OPC
        Opp_Product_Classification__c opc2 = ApplicationTestDataFactory.getOpportunityProductClassification(1, account.id, oppRec.id, true, String.valueOf(currentFY), false)[0];
        Opp_Product_Classification__c opc3 = ApplicationTestDataFactory.getOpportunityProductClassification(1, account.id, oppRec.id, true, String.valueOf(currentFY), false)[0];
        // future financial year OPC
        Opp_Product_Classification__c opc4 = ApplicationTestDataFactory.getOpportunityProductClassification(1, account.id, oppRec.id, false, String.valueOf(currentFY+1), false)[0];
        
        List<Opp_Product_Classification__c> mockOPCList = new List<Opp_Product_Classification__c>();
        mockOPCList.add(opc1);
        mockOPCList.add(opc2);
        mockOPCList.add(opc3);
        mockOPCList.add(opc4);
        Database.insert(mockOPCList);
    }
    
    
    /**
     * @description     Testing the roll up calculation of schedule revenue, actual revenue, and actual to schedule ratio percentage from the OPC
     *                  to the parent Opportunity record
     */
    public static testMethod void testRollupOPCRevenues(){
		
        Opportunity oppRec = [SELECT id from Opportunity LIMIT 1];
        
        Test.startTest();
        // execute the batch
        OPCRevenuesRollUpBatchable rollUpOPCBatch = new OPCRevenuesRollUpBatchable();
        Id OPCId = Database.executeBatch(rollUpOPCBatch, 4);
        Test.stopTest();

        List<Opportunity> opp = [SELECT id, Opportunity_Traded_Revenue__c, Total_Schedule_Revenue_to_Date__c,Opportunity_Traded_Revenue_pc__c 
                                FROM Opportunity where id =: oppRec.id LIMIT 1];

        // test the calculated revenue month by month of the financial year
        if(system.now().month() == 7){
            System.assertEquals(opp[0].Total_Schedule_Revenue_to_Date__c, 14000, 'Total Schedule Revenue to Date of $14000 is expected');
            System.assertEquals(opp[0].Opportunity_Traded_Revenue_pc__c, ((opp[0].Opportunity_Traded_Revenue__c/opp[0].Total_Schedule_Revenue_to_Date__c)*100).setScale(0), 'Opportunity Traded Revenue % is not correctly calculated');
        }else if(system.now().month() == 8){
            System.assertEquals(opp[0].Total_Schedule_Revenue_to_Date__c, 16000, 'Total Schedule Revenue to Date of $16000 is expected');
            System.assertEquals(opp[0].Opportunity_Traded_Revenue_pc__c, ((opp[0].Opportunity_Traded_Revenue__c/opp[0].Total_Schedule_Revenue_to_Date__c)*100).setScale(0), 'Opportunity Traded Revenue % is not correctly calculated');
        }else if(system.now().month() == 9){
            System.assertEquals(opp[0].Total_Schedule_Revenue_to_Date__c, 18000, 'Total Schedule Revenue to Date of $18000 is expected');
            System.assertEquals(opp[0].Opportunity_Traded_Revenue_pc__c, ((opp[0].Opportunity_Traded_Revenue__c/opp[0].Total_Schedule_Revenue_to_Date__c)*100).setScale(0), 'Opportunity Traded Revenue % is not correctly calculated');
        }else if(system.now().month() == 10){
            System.assertEquals(opp[0].Total_Schedule_Revenue_to_Date__c, 20000, 'Total Schedule Revenue to Date of $20000 is expected');
            System.assertEquals(opp[0].Opportunity_Traded_Revenue_pc__c, ((opp[0].Opportunity_Traded_Revenue__c/opp[0].Total_Schedule_Revenue_to_Date__c)*100).setScale(0), 'Opportunity Traded Revenue % is not correctly calculated');
        }else if(system.now().month() == 11){
            System.assertEquals(opp[0].Total_Schedule_Revenue_to_Date__c, 22000, 'Total Schedule Revenue to Date of $22000 is expected');
            System.assertEquals(opp[0].Opportunity_Traded_Revenue_pc__c, ((opp[0].Opportunity_Traded_Revenue__c/opp[0].Total_Schedule_Revenue_to_Date__c)*100).setScale(0), 'Opportunity Traded Revenue % is not correctly calculated');
        }else if(system.now().month() == 12){
            System.assertEquals(opp[0].Total_Schedule_Revenue_to_Date__c, 24000, 'Total Schedule Revenue to Date of $24000 is expected');
            System.assertEquals(opp[0].Opportunity_Traded_Revenue_pc__c, ((opp[0].Opportunity_Traded_Revenue__c/opp[0].Total_Schedule_Revenue_to_Date__c)*100).setScale(0), 'Opportunity Traded Revenue % is not correctly calculated');
        }else if(system.now().month() == 1){
            System.assertEquals(opp[0].Total_Schedule_Revenue_to_Date__c, 26000, 'Total Schedule Revenue to Date of $26000 is expected');
            System.assertEquals(opp[0].Opportunity_Traded_Revenue_pc__c, ((opp[0].Opportunity_Traded_Revenue__c/opp[0].Total_Schedule_Revenue_to_Date__c)*100).setScale(0), 'Opportunity Traded Revenue % is not correctly calculated');
        }else if(system.now().month() == 2){
            System.assertEquals(opp[0].Total_Schedule_Revenue_to_Date__c, 28000, 'Total Schedule Revenue to Date of $28000 is expected');
            System.assertEquals(opp[0].Opportunity_Traded_Revenue_pc__c, ((opp[0].Opportunity_Traded_Revenue__c/opp[0].Total_Schedule_Revenue_to_Date__c)*100).setScale(0), 'Opportunity Traded Revenue % is not correctly calculated');
        }else if(system.now().month() == 3){
            System.assertEquals(opp[0].Total_Schedule_Revenue_to_Date__c, 30000, 'Total Schedule Revenue to Date of $30000 is expected');
            System.assertEquals(opp[0].Opportunity_Traded_Revenue_pc__c, ((opp[0].Opportunity_Traded_Revenue__c/opp[0].Total_Schedule_Revenue_to_Date__c)*100).setScale(0), 'Opportunity Traded Revenue % is not correctly calculated');
        }else if(system.now().month() == 4){
            System.assertEquals(opp[0].Total_Schedule_Revenue_to_Date__c, 32000, 'Total Schedule Revenue to Date of $32000 is expected');
            System.assertEquals(opp[0].Opportunity_Traded_Revenue_pc__c, ((opp[0].Opportunity_Traded_Revenue__c/opp[0].Total_Schedule_Revenue_to_Date__c)*100).setScale(0), 'Opportunity Traded Revenue % is not correctly calculated');
        }else if(system.now().month() == 5){
            System.assertEquals(opp[0].Total_Schedule_Revenue_to_Date__c, 34000, 'Total Schedule Revenue to Date of $34000 is expected');
            System.assertEquals(opp[0].Opportunity_Traded_Revenue_pc__c, ((opp[0].Opportunity_Traded_Revenue__c/opp[0].Total_Schedule_Revenue_to_Date__c)*100).setScale(0), 'Opportunity Traded Revenue % is not correctly calculated');
        }else if(system.now().month() == 6){
            System.assertEquals(opp[0].Total_Schedule_Revenue_to_Date__c, 36000, 'Total Schedule Revenue to Date of $36000 is expected');
            System.assertEquals(opp[0].Opportunity_Traded_Revenue_pc__c, ((opp[0].Opportunity_Traded_Revenue__c/opp[0].Total_Schedule_Revenue_to_Date__c)*100).setScale(0), 'Opportunity Traded Revenue % is not correctly calculated');
        }
        System.assertEquals(opp[0].Opportunity_Traded_Revenue__c, 36000, 'Opportunity Traded Revenue of $36000 is expected');
    }

    
    /**
     * @description     Test OPCRevenuesRollUpSchedulable class
     *                  Ensure that the schedule job is generated properly
     */
    private static testMethod void testOPCRevenuesRollUpSchedulable(){

        Test.startTest();
            OPCRevenuesRollUpSchedulable opcRollupSchedule = new OPCRevenuesRollUpSchedulable();
            String sch = '0 5 23 * * ?';

            //run the scheduled job
            String jobID = System.schedule('Scheduled Job', sch, opcRollupSchedule);
        Test.stopTest();
        System.assertNotEquals(jobID ,null, 'Job Id is null');
    }

    
}