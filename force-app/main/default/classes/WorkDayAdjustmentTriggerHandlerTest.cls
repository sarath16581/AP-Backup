/**************************************************
Purpose:    Test class for workday adjustment trigger and handler
History:
--------------------------------------------------
8.9.2017    Adrian Recio Created
31.01.2022  Naveen Rajanna REQ2723602 - Minor Fix to failing test class
**************************************************/

@IsTest
public class WorkDayAdjustmentTriggerHandlerTest {
    public static testMethod void testTrigger(){

        // Create test FY
        Fiscal_Year__c fyVar = new Fiscal_Year__c();
        fyVar.Name = '2017';
        insert fyVar;

        // Create test public holiday
        Public_Holiday__c holiVar = new Public_Holiday__c(); 
        holiVar.July__c = 1;
        holiVar.August__c = 1;
        holiVar.September__c = 1;
        holiVar.October__c = 1;
        holiVar.November__c = 1;
        holiVar.December__c = 1;
        holiVar.January__c = 1;
        holiVar.February__c = 1;
        holiVar.March__c = 1;
        holiVar.April__c = 1;
        holiVar.May__c = 1;
        holiVar.June__c = 1;
        holiVar.Fiscal_Year__c = fyVar.Id;
        insert holiVar;
        
        // Create test work day adjustment
        Work_Day_Adjustments__c wdVar = new Work_Day_Adjustments__c();
        wdVar.Sales_Team__c = 'Holding Sales Team';
        wdVar.fiscalYear__c = fyVar.Id;
		wdVar.holiday__c = holiVar.Id;
        
        // Create test sales segment reference
        List<Sales_Segment_Reference__c> ssrList = new List<Sales_Segment_Reference__c>();
        
        Sales_Segment_Reference__c ssrVar1 = new Sales_Segment_Reference__c();
        ssrVar1.Sales_Segment__c = 'Business Hubs';
        ssrVar1.Sales_Director__c = UserInfo.getUserId(); 
        ssrList.add(ssrVar1);
        
        Sales_Segment_Reference__c ssrVar2 = new Sales_Segment_Reference__c();
        ssrVar2.Sales_Segment__c = 'Enterprise';
        ssrVar2.Sales_Director__c = UserInfo.getUserId(); 
        ssrList.add(ssrVar2);
        
        insert ssrList;
        
        test.startTest();
        	insert wdVar;
        
        	wdVar.Sales_Team__c = 'Intermediaries';
        	update wdVar;
        
        test.stopTest();
    }

}