@isTest
private class brideas_UtilsTest {

    @isTest
    private static void testGenerateToken(){
        String test5 = brideas_Utils.generateToken(5);
        String test10 = brideas_Utils.generateToken(10);
        String test255 = brideas_Utils.generateToken(255);

        System.assertEquals(5, test5.length());
        System.assertEquals(10, test10.length());
        System.assertEquals(44, test255.length());
    }
}