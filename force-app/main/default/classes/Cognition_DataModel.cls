/**
 *  Type: DataModel for Cognition Project
 *  History:
 *	 17-05-2018: Created - Subbu C, Gaurav A and Omair A (Salesforce)
 *	 12-09-2018: Modified - H Liyanage : Cognition Phase 2 changes
 *  --------------------------------------------------
 **/
global with sharing class Cognition_DataModel {

    public with sharing class queryStatusResponse{
        @AuraEnabled public Integer PercentageComplete ;
        @AuraEnabled public String DisplayMessage;
    }

    public with sharing class queryStatusRequest extends Cognition_APICommons{
        @AuraEnabled public String RequestGUID ;
    }

    public with sharing class customerSummaryRequestWithRGUID extends Cognition_APICommons{
        @AuraEnabled public String RequestGUID ;
    }
    
    public with sharing class receiverETARequest extends Cognition_APICommons{


        @AuraEnabled public String id ;
        @AuraEnabled public String param1 ;
    }

    public with sharing class receiverETAResponse extends Cognition_APICommons{
        @AuraEnabled public String Consignment ;
        @AuraEnabled public String EmployeeId ;
        @AuraEnabled public String[] ContextualParagraghs ;
    }
	
	public with sharing class ReportDataRequest extends Cognition_APICommons{
		@AuraEnabled public String RequestGUID { get; set; }
		@AuraEnabled public string Category { get; set; }
		@AuraEnabled public Integer FromSeq { get; set; }
		@AuraEnabled public Integer ToSeq { get; set; }
		@AuraEnabled public String ClientIpAddress { get; set; }
		@AuraEnabled public String ClientUserName { get; set; }
}
    global with sharing class reportDataResponse extends Cognition_APICommons{
        @AuraEnabled public String RequestGUID; //9a84f658-8477-4f58-87f3-2ce08df7a35c
        @AuraEnabled public String Category;    //DUE_NOTONBOARD_ALREADYDELIVERED
        @AuraEnabled public Integer FromSeq;    //0
        @AuraEnabled public Integer ToSeq;  //10
        @AuraEnabled public String CustomerName;
        @AuraEnabled public String[] AssociatedAccountNbrs;
        @AuraEnabled public Integer NbrOfReportDataRows;    //76
        @AuraEnabled public reportData[] ReportData;
        @AuraEnabled public String CardedDepot;
    }
    
    global with sharing class reportData {
        @AuraEnabled public String Depot{get;set;}  //ADR
        @AuraEnabled public String Consignment{get;set;}    //HESZ11819146
        @AuraEnabled public String Product{get;set;}    //PRM
        @AuraEnabled public String SenderName{get;set;} //APPLE
        @AuraEnabled public String ReceiverName{get;set;}   //RICHARD BOSTON BOSTON FORD
        @AuraEnabled public String ReceiverSuburb{get;set;} //5491
        @AuraEnabled public String ReceiverSuburbName {get;set;} // suburb name
        @AuraEnabled public Integer NbrOfItems{get;set;}    //1
        @AuraEnabled public String Category{get;set;}   //DUE_NOTONBOARD_ALREADYDELIVERED
        @AuraEnabled public String LastEvent{get;set;}  //F-Delivery-Delivery_Success
        @AuraEnabled public String LastEventDateTime{get;set;}  ///Date(1517878418000+1100)/
        @AuraEnabled public String SendersReference{get;set;}
        @AuraEnabled public String CardedDepot{get;set;}
        @AuraEnabled public String BookingNbr{get;set;} // "4868467",
        @AuraEnabled public String BookingType{get;set;} // null,
        @AuraEnabled public String PickupAddress{get;set;} // "243 BURWOOD ROAD",
        @AuraEnabled public String ReadyTime{get;set;} ///Date(1534917600000+1000)/",
        @AuraEnabled public String CloseTime{get;set;}///Date(1534921200000+1000)/",
        @AuraEnabled public String ContactArea{get;set;}// "FRONT STORE",
        @AuraEnabled public String Contact{get;set;}// "KRISIN",
        @AuraEnabled public String BookingInstructions{get;set;}// "NEW STE PERM"
        @AuraEnabled public String SFCaseNumber { get; set; }
        @AuraEnabled public String SFCaseId { get; set; }
        @AuraEnabled public String ETADate { get; set; }
        @AuraEnabled public String Suburb { get; set; }
        @AuraEnabled public String Postcode { get; set; }

    }
    
    global with sharing class PickupReportDataResponse extends Cognition_APICommons{
        @AuraEnabled public String RequestGUID; 
        @AuraEnabled public String Category;
        @AuraEnabled public Integer FromSeq; 
        @AuraEnabled public Integer ToSeq; 
        @AuraEnabled public String CustomerName;
        @AuraEnabled public String[] AssociatedAccountNbrs;
        @AuraEnabled public Integer NbrOfReportDataRows;
        @AuraEnabled public PickupReportData[] ReportData;
    }
    
    global with sharing class PickupReportData {
        @AuraEnabled public String Depot { get; set; }
        @AuraEnabled public String Product { get; set; }
        @AuraEnabled public String ReceiverSuburb { get; set; }
        @AuraEnabled public Integer NbrOfItems { get; set; }
        @AuraEnabled public String Category { get; set; }
        @AuraEnabled public String LastEvent { get; set; }
        @AuraEnabled public String LastEventDateTime { get; set; }
        @AuraEnabled public String ReceiverSuburbName { get; set; }
        @AuraEnabled public String BookingNbr { get; set; }
        @AuraEnabled public String BookingType { get; set; }
        @AuraEnabled public String PickupAddress { get; set; }
        @AuraEnabled public String ReadyTime { get; set; }
        @AuraEnabled public String CloseTime { get; set; }
        @AuraEnabled public String ContactArea { get; set; }
        @AuraEnabled public String Contact { get; set; }
        @AuraEnabled public String BookingInstructions { get; set; }
        @AuraEnabled public String SFCaseNumber { get; set; }
        @AuraEnabled public String SFCaseId { get; set; }
    }
    
    public with sharing class CustomerViewDetailRequest extends Cognition_APICommons{
        @AuraEnabled public String RequestGUID; //efccfc7f-26d1-446f-8833-baccf32e1512
        @AuraEnabled public Integer Type;   //1
        @AuraEnabled public Integer Action; //2
        @AuraEnabled public Integer FromSeq;    //0
        @AuraEnabled public Integer ToSeq;  //499
        @AuraEnabled public String ClientIpAddress; //::1
        @AuraEnabled public String ClientUserName;  
    }

    public with sharing class CustomerViewDetailResponseV2 {
        @AuraEnabled public CustomerViewDetailRequest Request;
        @AuraEnabled public cls_ConInfo[] ConInfo;
    }

    public with sharing class cls_ConInfo {
        @AuraEnabled public String Consignment; //HESZ11768613
        @AuraEnabled public String BookingNbr;
        @AuraEnabled public Integer Type;   //2
        @AuraEnabled public String EventDateTime;   ///Date(1516060882000+1100)/
        @AuraEnabled public Double Latitude;    //-37.75667618908637
        @AuraEnabled public Double Longitude;   //145.05924945
    }    

    public with sharing class CustomerViewRequestV2 extends Cognition_APICommons{
        public String RequestGUID { get; set; }
        public integer Account { get; set; }
        public string AccountString { get; set; }
        public String ETADate { get; set; }
        public Integer RequestAction { get; set; }
        public string CustomerName { get; set; }
        public string DespatchId { get; set; }
        public string Depot { get; set; }
        public string ClientIpAddress { get; set; }
        public string ClientUserName { get; set; }
        public String ToDateTimeForced { get; set; }
    }
    
  public with sharing class CustomerViewResponse {
	 
	  public DisplayStats[] DisplayStats;
	  public cls_Depots[] Depots;
	
	  public String RequestGUID { get; set; }
	  public string ResponseType { get; set; }
	  public String RequestDateTime { get; set; }
	  public String FromDateTime { get; set; }
	  public String ToDateTime { get; set; }
	  
	  public Integer DueNbr { get; set; }
	  public string DueNbrName { get; set; }
	  public Integer OnBoardNbr { get; set; }
	  public Integer DeliveredSuccessNbr { get; set; }
	  public Integer DeliveredFailedNbr { get; set; }
	  public Integer DueOnboardDeliveryFailureCarded { get; set; }
	  public Integer TotalNbr { get; set; }
	  public Integer DueOnboard { get; set; }
	  public Integer DueOnboardDeliverySuccess { get; set; }
	  public Integer DueOnboardDeliveryFailed { get; set; }
	  public Integer DueNotOnboardDeliverySuccess { get; set; }
	  public Integer DueNotOnboardDeliveryFailed { get; set; }
	  public Integer DueOnboardStillOutstanding { get; set; }
	  public Integer DueNotOnboard { get; set; }
	  public Integer DueNotOnboardAlreadyDelivered { get; set; }
	  public Integer NotDueOnboard { get; set; }
	  public Integer NotDueOnboardDeliverySuccess { get; set; }
	  public Integer NotDueOnboardDeliveryFailed { get; set; }
	  public Integer NotDueOnboardStillOutstanding { get; set; }
	  public Integer NotDueOnboardLate { get; set; }
	  public Integer NotDueOnboardEarly { get; set; }
	  public Integer NotDueNotOnboardDeliverySuccess { get; set; }
	  public Integer NotDueNotOnboardDeliveryFailed { get; set; }
	  public Integer TDDue { get; set; }
	  public Integer TDEvents { get; set; }
	  public Integer DueNotOnboardHeldForCollection { get; set; }
	  public Integer DueNotOnboardNoEvents { get; set; }
	  public Integer DueUnknown { get; set; }
	  public Integer DueNotOnboardBeforeCutoff { get; set; }
	  public String customer_logo { get; set; }
      public String TruckLink { get; set; }


}
    public with sharing class Stats {
    @AuraEnabled public String Name;  
    @AuraEnabled public Integer Value;  
    @AuraEnabled public boolean Displayable;
    @AuraEnabled public String URLLink;  
    @AuraEnabled public Integer Category;
    @AuraEnabled public String Category_EnumString;
    @AuraEnabled public Integer GroupSequence;
    @AuraEnabled public String Description;
  }
    
    public with sharing class DisplayStats {
        @AuraEnabled public String Heading;
        @AuraEnabled public Stats[] Stats;
    }
    
    public with sharing class cls_Depots {
    @AuraEnabled public String Depot; 
    @AuraEnabled public String DepotName;

  }

    global with sharing class CustomerViewPickupInfo{
        @AuraEnabled public string BookingNbr { get; set; } // "4899212",
        @AuraEnabled public Integer Type { get; set; } // 11,
        @AuraEnabled public string Type_EnumString { get; set; } // "Pickup Success",
        @AuraEnabled public string EventDateTime { get; set; } // "/Date(1535070283000+1000)/",
        @AuraEnabled public string EventDesc { get; set; } // null,
        @AuraEnabled public string Depot { get; set; } // "ROK",
        @AuraEnabled public string Network { get; set; } // null,
        @AuraEnabled public string BookingType { get; set; } // "Adhoc",
        @AuraEnabled public string BusinessUnit { get; set; } // "ST100",
        @AuraEnabled public string CustomerNbr { get; set; } // "10140979",
        @AuraEnabled public string ServiceCode { get; set; } // "FPP",
        @AuraEnabled public string Address1 { get; set; } // "ANN STREET",
        @AuraEnabled public string Address2 { get; set; } // "",
        @AuraEnabled public string Address3 { get; set; } // "",
        @AuraEnabled public Double Latitude { get; set; } // -23.396409,
        @AuraEnabled public Double Longitude { get; set; } // 150.490377,
        @AuraEnabled public string Suburb { get; set; } // "ROCKHAMPTON",
        @AuraEnabled public string Postcode { get; set; } // "4700",
        @AuraEnabled public string State { get; set; } // "QLD",
        @AuraEnabled public string Contact { get; set; } // "JEFF",
        @AuraEnabled public string ContactArea { get; set; } // "FRONT COUNTER",
        @AuraEnabled public string ReadyTime { get; set; } // "/Date(1535065200000+1000)/",
        @AuraEnabled public string CloseTime { get; set; } // "/Date(1535094000000+1000)/",
        @AuraEnabled public string TimeZone { get; set; } // null,
        @AuraEnabled public string BookingInstructions { get; set; } // "RA: 4928156",
        @AuraEnabled public string EventType { get; set; } // "Pickup",
        @AuraEnabled public string EventSubType { get; set; } // "Pickup_Success",
        @AuraEnabled public string DeviceId { get; set; } // null,
        @AuraEnabled public string EmployeeId { get; set; } // null,
        @AuraEnabled public string EmployeeName { get; set; } // null,
        @AuraEnabled public string EventReason { get; set; } // "",
        @AuraEnabled public string Category { get; set; } // 31,
        @AuraEnabled public string Category_EnumString { get; set; } // "Pickup Success",
        @AuraEnabled public string ContextualParagragh1 { get; set; } // null,
        @AuraEnabled public string ContextualParagragh2 { get; set; } // null,
        @AuraEnabled public string ContextualParagragh3 { get; set; } // null,
        @AuraEnabled public string SignatureName { get; set; } // null,
        @AuraEnabled public string SignatureImageBase64 { get; set; } // null,
        @AuraEnabled public string DriverName { get; set; } // null,
        @AuraEnabled public string DriverImageBase64 { get; set; } // null,
        @AuraEnabled public string SendersReference { get; set; } // null,
        @AuraEnabled public cls_References[] References { get; set; } // null
        @AuraEnabled public Integer Quantity { get; set; } // 11,
        @AuraEnabled public String SFCaseNumber { get; set; }
        @AuraEnabled public String SFCaseId { get; set; }

    }

	global with sharing class CustomerViewConInfo{
    	@AuraEnabled public string Consignment { get; set; }
    	@AuraEnabled public Integer Type { get; set; }
	    @AuraEnabled public string EventDateTime { get; set; }
	    @AuraEnabled public string EventDesc { get; set; }
    	@AuraEnabled public string Network  { get; set; }
    	@AuraEnabled public string Depot { get; set; }
    	@AuraEnabled public string SenderName { get; set; }
    	@AuraEnabled public string ReceiverName { get; set; }
    	@AuraEnabled public string Address1 { get; set; }
    	@AuraEnabled public string Address2 { get; set; }
    	@AuraEnabled public string SenderSuburb { get; set; }
    	@AuraEnabled public string ReceiverSuburb { get; set; }
    	@AuraEnabled public string SenderPostcode { get; set; }
    	@AuraEnabled public string ReceiverPostcode { get; set; }
    	@AuraEnabled public string DespatchDate { get; set; }
    	@AuraEnabled public string ETADateTime { get; set; }
    	@AuraEnabled public double Latitude { get; set; }
    	@AuraEnabled public double Longitude { get; set; }
    	@AuraEnabled public string DateString { get; set; }
    	@AuraEnabled public string DespatchString { get; set; }
    	@AuraEnabled public string ETAString { get; set; }
    	@AuraEnabled public string PredictedETADateTime { get; set; } 
    	@AuraEnabled public string PredictedNbrStopsToDelivery { get; set; } 
    	@AuraEnabled public string PredictedDeliveryWindowStart { get; set; }
    	@AuraEnabled public string PredictedDeliveryWindowEnd { get; set; }
    	@AuraEnabled public string ContextualParagragh1 { get; set; }    
    	@AuraEnabled public string ContextualParagragh2 { get; set; }    
    	@AuraEnabled public string ContextualParagragh3 { get; set; }    
    	@AuraEnabled public string SignatureImageBase64 { get; set; }
    	@AuraEnabled public String Type_EnumString{get;set;}  
    	@AuraEnabled public Integer NbrItems { get; set; }    
    	@AuraEnabled public String SendersReference{get;set;}  
    	@AuraEnabled public String ServiceCode{get;set;}
    	@AuraEnabled public cls_References[] References;
        @AuraEnabled public String TruckLink { get; set; }
        @AuraEnabled public String CardedDepot { get; set; }
        @AuraEnabled public String SFCaseNumber { get; set; }
        @AuraEnabled public String SFCaseId { get; set; }
        @AuraEnabled public string Category_EnumString { get; set; }
	}     

    public with sharing class cls_References {
		@AuraEnabled public String Type;	//INVOICE.NO.
		@AuraEnabled public String Value;	//0969024
	}

    public with sharing class Config {
        @AuraEnabled public Boolean isInternalUser;
        @AuraEnabled public String baseUrl;
        @AuraEnabled public Integer refreshInterval;
    }

    public with sharing class ConsignmentInfoRequest extends Cognition_APICommons{
		public String RequestGUID { get; set; }
    	public string Consignment { get; set; }
    	public string ClientIpAddress { get; set; }
    	public string ClientUserName { get; set; }
	}

    public with sharing class PickupInfoRequest extends Cognition_APICommons{
        public String RequestGUID { get; set; }
        public string BookingNbr { get; set; }
        public string ClientIpAddress { get; set; }
        public string ClientUserName { get; set; }
    }

    public with sharing class CustomerDetailsResponse {
        public cls_ConInfo[] conInfo;
    }
}