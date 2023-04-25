/**************************************************
Type:         Unit test class for BusinessHoursService
History:
--------------------------------------------------
19/04/2023    Created : hasantha.liyanage@auspost.com.au
**************************************************/
@IsTest
private class BusinessHoursService_Test {
    @IsTest
    static void testCalculateNextBusinessDay() {
        Date dateSent = Date.newInstance(2023, 4, 19);
        Integer maxDays = 3;

        Date expected = Date.newInstance(2023, 4, 24);
        Date actual = BusinessHoursService.newInstance().calculateNextBusinessDay(dateSent, maxDays);

        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testAddDays() {
        Datetime startDate = Datetime.newInstanceGmt(2023, 4, 19);
        Integer days = 3;

        // Expected result, 22nd and 23rd are Weekend days
        Datetime expected = Datetime.newInstanceGmt(2023, 4, 24);
        Datetime actual = BusinessHoursService.newInstance().addDays(startDate, days).date();

        System.assertEquals(expected, actual);
    }
}