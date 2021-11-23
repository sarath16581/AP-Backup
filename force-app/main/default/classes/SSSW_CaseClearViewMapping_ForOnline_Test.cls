/**
  * @author       : Fuqi Tan
  * @date         : 2014-07-25
  * @description  : This test class is for AccountTrigger - Test coverage  87%
--------------------------------------- History --------------------------------------------------                      
01.06.2016  Andrew Judd (Salesforce.com)    Added Licence duplicate verification methods
                                            Added setting of Network.Org_Unit_Type__c and Facility.Licence_Type__c to LPO for filter
11/07/2016  Eugene Jandusay                 Created New Test Class to accomodate existing testing scenarios and perform code cleanup
26.08.2016  Kalpita T                       Added references to new trigger class and removed static references to old test classes 
**/
@isTest
private class SSSW_CaseClearViewMapping_ForOnline_Test {

     /**
      * @description       test Method for covering accountUtility Methods based on scenarios                      
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    private static testMethod void testAccountUtil(){
        SSSW_CaseClearViewMapping_ForOnline contr = new SSSW_CaseClearViewMapping_ForOnline ();
         Contact con = TestDataProvider.createTestContact();
        insert con;
        Case case1 = new Case();
        case1.ContactId = con.Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.SuppliedEmail = 'test@salesforce.com';
        case1.First_Name__c = 'test';
        case1.Last_Name__c = 'test';
        insert case1;
        SSSW_CaseClearViewMapping_ForOnline.processClearViewCodes(new List<Id>{case1.Id});
        
    }

}