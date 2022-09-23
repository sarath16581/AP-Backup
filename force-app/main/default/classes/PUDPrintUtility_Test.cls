/**
* @author Dattaraj Deshmukh
* @date 2022-08-17
* @group PUD
* @domain PUD
* @description Test class for PUDPrintUtility 
* @changelog 
 * 2022-08-17- Dattaraj Deshmukh - Created
 */
@IsTest
private class PUDPrintUtility_Test {
    
    @IsTest
    public static void testGetDisplayTime() {
      
        
        // =====================================
		// Data Preparation - Not Requied
		// =====================================

        // =====================================
		// Stubbing - Not Required
		// =====================================

        Time startTime = Time.newInstance(7, 0, 0, 0);
        Time endTime = Time.newInstance(7, 5, 0, 0);

        Time startTimePostTenHour = Time.newInstance(11, 0, 0, 0);
        Time endTimePostTenMinute = Time.newInstance(12, 15, 0, 0);

        Test.startTest();

        String displayStartTimeString = PUDPrintUtility.getDisplayTime(startTime);
        String displayEndTimeString = PUDPrintUtility.getDisplayTime(endTime);
        
        String displayStartTimePostTenHour = PUDPrintUtility.getDisplayTime(startTimePostTenHour);
        String displayEndTimePostTenMinute = PUDPrintUtility.getDisplayTime(endTimePostTenMinute);
        

        Test.stopTest();

        System.assertEquals('0700', displayStartTimeString);
        System.assertEquals('0705', displayEndTimeString);

        System.assertEquals('1100', displayStartTimePostTenHour);
        System.assertEquals('1215', displayEndTimePostTenMinute);


    }

    @IsTest
    public static void testGetDuration() {
      
        
        // =====================================
		// Data Preparation - Not Requied
		// =====================================

        // =====================================
		// Stubbing - Not Required
		// =====================================

        Time startTime = Time.newInstance(7, 0, 0, 0);
        Time endTime = Time.newInstance(7, 5, 0, 0);

        Time startTimePostTenHour = Time.newInstance(11, 0, 0, 0);
        Time endTimePostTenMinute = Time.newInstance(12, 15, 0, 0);

        String displayStartTimeString = PUDPrintUtility.getDisplayTime(startTime);
        String displayEndTimeString = PUDPrintUtility.getDisplayTime(endTime);
        
        String displayStartTimePostTenHour = PUDPrintUtility.getDisplayTime(startTimePostTenHour);
        String displayEndTimePostTenMinute = PUDPrintUtility.getDisplayTime(endTimePostTenMinute);

        Test.startTest();

        String duration1 = PUDPrintUtility.getDuration(displayStartTimeString, displayEndTimeString);
        
        String durationWithStartTimeOnly = PUDPrintUtility.getDuration(displayStartTimePostTenHour, NULL);
        String durationWithEndTimeOnly = PUDPrintUtility.getDuration(null, displayEndTimePostTenMinute);


        Test.stopTest();

        //asserting duration is formated with '-'
        System.assertEquals('0700 - 0705', duration1,'Expected duration formatted with hyphen');
        System.assertEquals('1100 - ', durationWithStartTimeOnly, 'Expected duration formatted with hyphen without end date');
        System.assertEquals(' - 1215', durationWithEndTimeOnly, 'Expected duration formatted with hyphen without start date');
       
    }
}
