/**************************************************
Purpose:    Test for CountryLookupController
History:
--------------------------------------------------
18-04-2019 Gunith.Devasurendra@auspost.com.au   Created
**************************************************/
@IsTest
public with sharing class CountryLookupController_Test {

    @IsTest
    public static void correctlySearchesCountries(){
        CountryCodes__c codes = new CountryCodes__c();
        codes.Name = 'Australia';
        codes.Alpha2__c = 'AU';
        insert codes;

        List<CountryLookupController.AutoCompleteData> autoCompleteData = CountryLookupController.getData('Name', 'AUS');
        System.assertEquals('Australia (AU)', autoCompleteData.get(0).label);

        autoCompleteData = CountryLookupController.getData('code', 'AU');
        System.assertEquals('AU - Australia', autoCompleteData.get(0).label);
    }
}