/*
 * changelog:
 * 2021-09-09	seth.heang@auspost.com.au	Uplift SF API version to 52
*/
@isTest
private class TIBCOUtilsTest {

    static testMethod void testParseDateYYYYMMDD() {
        String dateString = '20140123';
        System.assertEquals(Date.newInstance(2014, 01, 23), TIBCOUtils.parseDateYYYYMMDD(dateString));
        
        String dateString2 = 'asda2';
        System.assertEquals(null, TIBCOUtils.parseDateYYYYMMDD(dateString2));
        
        String dateString3 = null;
        System.assertEquals('', TIBCOUtils.removeNull(dateString3));
    }
}