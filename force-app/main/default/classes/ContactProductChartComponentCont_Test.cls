@isTest
private class ContactProductChartComponentCont_Test {

    static testMethod void myUnitTest() {
    	Contact contact = new Contact(FirstName = 'test', LastName = 'test', Phone = '718273672', Email = 'test@test.com', MailingCity = 'test city');
    	insert contact;
    	
    	List<Case> list_case2insert = new List<Case>();
    	
    	Case case1 = new Case();
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.EnquirySubType__c = 'Article carded - no card left';
        case1.DateofIncident__c = date.today();
        case1.ContactId = contact.Id;
        list_case2insert.add(case1); 
        
        Case case2 = new Case();
        case2.Type = 'Feedback';
        case2.Subject = 'Newsdd';
        case2.Status = 'Network Responded';
        case2.ProductCategory__c = 'Travel & ID';
        case2.EnquirySubType__c = 'Product Support';
        case2.ProductSubCategory__c = 'KeyPass';
        case2.EnquirySubType__c = 'Article carded - no card left';
        case2.DateofIncident__c = date.today();
        case2.ContactId = contact.Id;
        list_case2insert.add(case2); 
        
        Case case3 = new Case();
        case3.Type = 'Feedback';
        case3.Subject = 'Newsdd';
        case3.Status = 'Network Responded';
        case3.ProductCategory__c = 'Test Category';
        case3.EnquirySubType__c = 'Product Support';
        case3.ProductSubCategory__c = 'KeyPass';
        case3.EnquirySubType__c = 'Article carded - no card left';
        case3.DateofIncident__c = date.today();
        case3.ContactId = contact.Id;
        list_case2insert.add(case3); 
        insert list_case2insert;
        
        
        ContactProductChartComponentCont instance = new ContactProductChartComponentCont();
        instance.contId = contact.Id;
    }
}