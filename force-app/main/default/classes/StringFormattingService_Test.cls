/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description A very simple selector class that provides string formatting capabilities
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
@IsTest
public with sharing class StringFormattingService_Test {
    
    @IsTest
    static void formatPhoneNumber() {
        StringFormattingService service = StringFormattingService.getInstance();

        String phoneNumber = '0404 888 999';
        String actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+61404888999', actual);

        phoneNumber = '61 0404 888 991';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+61404888991', actual);

        phoneNumber = '61404 888 993';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+61404888993', actual);

        phoneNumber = '+61 404 888 992';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+61404888992', actual);

        phoneNumber = '+61 (02) 888 002';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+612888002', actual);

        phoneNumber = '61 (02) 888 991';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+612888991', actual);

        phoneNumber = '(02) 888 993';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+612888993', actual);

        phoneNumber = '02 888 994';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+612888994', actual);

        phoneNumber = '+61 (03) 888 002';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+613888002', actual);

        phoneNumber = '61 (03) 888 991';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+613888991', actual);

        phoneNumber = '(03) 888 993';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+613888993', actual);

        phoneNumber = '03 888 994';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+613888994', actual);

        phoneNumber = '+61 (06) 888 002';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+616888002', actual);

        phoneNumber = '61 (06) 888 991';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+616888991', actual);

        phoneNumber = '(06) 888 993';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+616888993', actual);

        phoneNumber = '06 888 994';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+616888994', actual);

        phoneNumber = '+61 (07) 888 002';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+617888002', actual);

        phoneNumber = '61 (07) 888 991';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+617888991', actual);

        phoneNumber = '(07) 888 993';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+617888993', actual);

        phoneNumber = '07 888 994';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+617888994', actual);

        phoneNumber = '+61 (08) 888 002';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+618888002', actual);

        phoneNumber = '61 (08) 888 991';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+618888991', actual);

        phoneNumber = '(08) 888 993';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+618888993', actual);

        phoneNumber = '08 888 994';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('+618888994', actual);

        phoneNumber = '13 12 11';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('131211', actual);

        phoneNumber = '1300 11 22 33';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('1300112233', actual);

        phoneNumber = '1800 33 66 55';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('1800336655', actual);

        phoneNumber = '0123 456 789';
        actual = service.formatPhoneNumber(phoneNumber);
        System.assertEquals('0123 456 789', actual);
    }
}