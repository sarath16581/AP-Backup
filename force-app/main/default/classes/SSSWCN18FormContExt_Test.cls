/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 09/12/2015
  * @description  : test class for Controller for CN18 form
  */
/*******************************  History ************************************************
    
*******************************  History ************************************************/
@isTest
private class SSSWCN18FormContExt_Test {
    
     /** 
      * @name: myUnitTest()
      * @desciption: method to test the cn18 form creation
      * @param: NA
      * @return: NA
      */
    static testMethod void myUnitTest() {
      
        
        
        Case case1 = new Case();
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.datePosted__c = system.today();
        insert case1;
        
        Test.startTest();
            PageReference myVfPage = Page.SSSWCN18Form;
            Test.setCurrentPage(myVfPage);
            
            // Put Id into the current page Parameters
            ApexPages.currentPage().getParameters().put('id',case1.Id);
            ApexPages.currentPage().getParameters().put('create','true');
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(case1);   
            SSSWCN18FormContExt ext = new SSSWCN18FormContExt(stdCtl);
            ext.getBody();
            
        Test.stopTest();
    }
    
}