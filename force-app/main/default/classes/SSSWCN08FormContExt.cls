/**************************************************
Type:       Controller Extension class       
Purpose:    Required controller extension because standard controller
            did not return all fields when trying to call page reference.
Used by:    SSSWCN08Form.page
History:
-------------------------------------------------- 
12.03.2014  A. Tran (Bluewolf)  Created.
**************************************************/

public with sharing class SSSWCN08FormContExt {

    public transient CN08__c cn08 { get; set; }
    
    public SSSWCN08FormContExt(apexPages.StandardController controller) {
        if (controller.getId() != null) {
            Id cn08Id = (Id)controller.getId();
                        
            if (cn08Id != null) {
                cn08 = getCN08(cn08Id);
            }
        } else if (controller.getRecord() != null) {
            cn08 = (CN08__c)controller.getRecord();
            if (cn08.Id != null) {
                cn08 = getCN08(cn08.Id);
            }
        }
    }
    
    private CN08__c getCN08(Id cn08Id) {
        String query = 'select AddresseeAddress__c, AddresseeDeclarationRequested__c, AddresseeName__c, AddresseePhone__c, AmountOfIndemnity__c, BillListNumber__c, BulkAdvice__c, Case__c,';
        query += ' ChargesPaid__c, CODAmount__c, CODCurrency__c, ContentsDescription__c, DateOfArrival__c, DateOfDuplicate__c, DateOfInquiry__c, DispatchDate__c,';
        query += ' DispatchingOffficeOfExchange__c, Id, InquiryType__c, InsuredValue__c, IsDeleted, IsPriority__c, ItemType__c, ItemWeight__c,';
        query += ' ListType__c, MailNumber__c, MailType__c, Name, NumberOfItems__c, OfficeOfExchangeOfDestination__c, OfficePostedFrom__c, OtherFees__c, PostedDate__c, ReasonForInquiry__c, ReceiptSeen__c,';
        query += ' Reference__c, ReturnAddress__c, SenderAddress__c, SenderName__c, SenderPhone__c, SerialNumber__c, ServiceOfDestination__c, SpecialIndications__c, ToBeSentTo__c';
        query += ' from CN08__c WHERE Id = :cn08Id';
        
        List<CN08__c> cn08List = Database.query(query);
        return cn08List.isEmpty() ? null : cn08List[0]; 
    }
}