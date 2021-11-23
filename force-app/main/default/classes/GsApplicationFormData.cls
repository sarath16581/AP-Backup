public without sharing class GsApplicationFormData {

    //Properties that are not bound to the lead object.
    public boolean soleTraderCheckbox{get; set;}
    public boolean companyCheckbox{get; set;}
    public boolean tradingTrustCheckbox{get; set;}
    public boolean partnershipCheckbox{get; set;}
    public boolean govAuthCheckbox{get; set;}
    public boolean localGovCheckbox{get; set;}
    public boolean intCusCheckbox{get; set;}
	public String businessType {get;Set;}
	
	
    //Trust Detauls
    public string nameOfTrust{get; set;}
    public string nameOfTrustee{get; set;}
    public string abnAcnTrust{get; set;}
    
    //Business Type Section
    public string natureOfBusiness{get; set;}
    public string industryType{get; set;}
    public string dateCommenced{get; set;}
    public string premisesRadio{get; set;}
    public string creditLimit5000{get; set;}
    public string parcelsPerYear{get; set;}
    public string numOfEmployees{get; set;}
    public string eciApplication{get; set;}
    public string sendParcelsOverseas{get; set;}
    public string whichECI{get; set;}
    
    //value of eParcelApp should be mapped to Product__c as multi select picklist value
    public string eParcelApplication{get; set;}
    
    // credit account application
    public string creditAmountRequired{get; set;}
    public string companyorBusinessName{get; set;}
    public string contactName1{get; set;}
    public string contactPositionTitle1{get; set;}
    public string phone1{get; set;}
    public string email1{get; set;}
    public string companyOrBusinessName2{get; set;}
    public string contactName2{get; set;}
    public string contactPositionTitle2{get; set;}
    public string phone2{get; set;}
    public string email2{get; set;}
    public string companyOrBusinessName3{get; set;}
    public string contactName3{get; set;}
    public string contactPositionTitle3{get; set;}
    public string phone3{get; set;}
    public string email3{get; set;}
    
    //Personal Details Section
    public string titlePD1{get; set;}
    public string namePD1{get; set;}
    public string address1PD1{get; set;}
    public string address2PD1{get; set;}
    public string cityPD1{get; set;}
    public string statePD1{get; set;}
    public string postcodePD1{get; set;}
    public string premisesPD1{get; set;}
    public string driversLicensePD1{get; set;}
    public string birthDatePD1{get; set;}
    public string nameOfSpousePD1{get; set;}
    public string titlePD2{get; set;}
    public string namePD2{get; set;}
    public string address1PD2{get; set;}
    public string address2PD2{get; set;}
    public string cityPD2{get; set;}
    public string statePD2{get; set;}
    public string postcodePD2{get; set;}
    public string premisesPD2{get; set;}
    public string driversLicensePD2{get; set;}
    public string birthDatePD2{get; set;}
    public string nameOfSpousePD2{get; set;}
    /////-------/////
    
    
    
    //eParcel Application
    public boolean parcelPickUp{get; set;}
    public boolean parelDropOff{get; set;}
    
    //Lodgement Centres
    public string principalLC{get; set;}
    public string alternativeLC1{get; set;}
    public string alternativeLC2{get; set;}
    public string alternativeLC3{get; set;}
    
    //Pickup Address
    public string address1PA{get; set;}
    public string address2PA{get; set;}
    public string cityPA{get; set;}
    public string statePA{get; set;}
    public string postcodePA{get; set;}
    
    //Pickup Dropoff Times
    public boolean mondayPickup{get; set;}
    public boolean tuesdayPickup{get; set;}
    public boolean wednesdayPickup{get; set;}
    public boolean thursdayPickup{get; set;}
    public boolean fridayPickup{get; set;}
    public string requestedPickupTime{get; set;}
    
    //Transport & Volume Details
    public string pickupVolume{get; set;}
    public boolean pickupTransportVan{get; set;}
    public boolean pickupTransportTruck{get; set;}
    public boolean pickupPresentationMethodBag{get; set;}
    public boolean pickupPresentationMethodLoose{get; set;}
    public boolean pickupPresentationMethodULD{get; set;}
    public boolean pickupDestinationMetro{get; set;}
    public boolean pickupDestinationState{get; set;}
    public boolean pickupDestinationInterstate{get; set;}
    public boolean pickupDestinationInternational{get; set;}
    
    // Computer Hardware and Software
    public boolean osWinXp{get;set;}
    public boolean osWin7{get;set;}
    public boolean osMaxOs{get;set;}
    public string osOther{get;set;}
    public string javaRuntimeV6Above{get;set;}
    public string AdobeReaderV8above{get;set;}
    public boolean browserIE7Above{get;set;}
    public boolean browserFF{get;set;}
    public boolean browserSafari{get;set;}
    public boolean browserChrome{get;set;}
    public string printerMakeModel {get;set;}
    
    // Vehicle and pedestrian access
    public string freeOfObstacles{get;set;}
    public string freeOfObstaclesComment{get;set;}    
    
    public string designatedLoadingParkingArea{get;set;}
    public string designatedLoadingParkingAreaComment{get;set;}
    
    public string noReversing{get;set;}
    public string noReversingComment{get;set;}
    
    public string enoughRoom{get;set;}
    public string enoughRoomComment{get;set;}
    
    public string controlledAccess{get;set;}
    public string controlledAccessComment{get;set;}
    
    public string noSlopes{get;set;}
    public string noSlopesComment{get;set;}
    
    
    //Falls, slips and trips
    public string noSlipTripFallHazards{get;set;}
    public string noSlipTripFallHazardsComment{get;set;}
    
    public string adequateLighting{get;set;}
    public string adequateLightingComment{get;set;}
    
    //Manual handling
    public string noAbove16kgs{get;set;}
    public string noAbove16kgsComment{get;set;}
    
    public string stableBalancedParcel{get;set;}
    public string stableBalancedParcelComment{get;set;}
    
    public string noStairNeeded{get;set;}
    public string noStairNeededComment{get;set;}
    
    public string noMoreThan10meters{get;set;}
    public string noMoreThan10metersComment{get;set;}
    
    public string noShoulderHeight{get;set;}
    public string noShoulderHeightComment{get;set;}
    
    public string noLift{get;set;}
    public string noLiftComment{get;set;}
    
    public string noHazardousOrSharp{get;set;}
    public string noHazardousOrSharpComment{get;set;}
    
    public string staffOnSite{get;set;}
    public string staffOnSiteComment{get;set;}
    
    //Forklifts and moving vehicles
    public string noMovingVehicles{get;set;}
    public string noMovingVehiclesComment{get;set;}
    
    public string noLoadShiftingEquipment{get;set;}
    public string noLoadShiftingEquipmentComment{get;set;}
    
    public string hasFloorTrafficManagementPlan{get;set;}
    public string hasFloorTrafficManagementPlanComment{get;set;}
    
    // comment
    public string comment {get;set;}
    
    //RadioButton values for display
    //public boolean isAusPostCreditAccountCustomer {get;set;}
	//public boolean isNOTAusPostCreditAccountCustomer {get;set;}
	
	//Boolean Values for Terms Acceptance / Marketing
	public string termsCreditAccount{get; set;}
	public string termsParcelService{get; set;}
	public string generalTAndC{get; set;}
	public string termsInternationalParcels{get; set;}
	//the var below should map to Legal_Marketing_Opt_In__c on the lead, but can't access the controller atm (CW Aprika)
    public string marketingOptIn{get; set;}
    
    //Credit account details
    public boolean austPostCreditAccountCustomer{get;set;}
    public string creditAccountNumber{get;set;}
    public boolean applyForCreditAcct{get;set;}
    //public boolean creditLimitGreaterThan5000{get;set;}
    
    //Generate PDF attachmentId
    public String generatedPDFID {get;set;}
    
    // existing credit account
    public String lodgeOverTheCounter {get;set;}
    public String lodgePostOutlet {get;set;}
    
}