/**
 *Test class for bspLoginComponent.
 @author Fuqi Tan
 @created 2014-06-20
 *- Test coverage 86%
*/

@isTest
private class bspLoginComponent_Test{
    @IsTest
    static void testGeneral(){
        test.startTest();
        ApexPages.currentPage().getParameters().put('section','forgotpassword');
        bspLoginComponent instance1 = new bspLoginComponent();
        ApexPages.currentPage().getParameters().put('section','passwordreset');
        bspLoginComponent instance2 = new bspLoginComponent();
        ApexPages.currentPage().getParameters().put('section','setpasswd');
        bspLoginComponent instance3 = new bspLoginComponent();
        ApexPages.currentPage().getParameters().put('section','login');
        bspLoginComponent instance4 = new bspLoginComponent();
        
        instance1.username = 'abcccc';
        instance1.password = 'bbccca';
        instance1.login();
        instance1.forgotPassword();
        /* the changePassword method not exist any more, so this piece test not needed
        instance1.newPassword = '23yy434';
        instance1.verifyNewPassword = '23yy434';
        instance1.changePassword();
        */
        test.stopTest();
    }
}