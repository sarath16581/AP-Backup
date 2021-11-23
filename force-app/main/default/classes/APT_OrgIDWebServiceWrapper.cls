/**
* Description: This Wrapper class is used to parse response 
* from TIBCO web service to APEX class for ORG ID web service.
* Most of the properties names are same as Schema party service
* we need this class to show results on VF page.
* Created By: Himanshu jain
* Created Date: 1st Oct, 2015
**/
public with sharing class APT_OrgIDWebServiceWrapper {

   /*
        This class is used for creating variables.
   */     
    public with sharing class BusinessName_element {
        public String RegisteredBusinessName {get; set;}
        public String DistinguishedWord {get; set;}
        public String VedaBusinessNameId {get; set;}
    }    
   /*
        This class is used for creating variables.
   */        
    public with sharing class queryABNType {
        public String OrganisationNumber {get; set;}
        public String AustralianBusinessNumber {get; set;}
        public String OrgName {get; set;}
        public APT_OrgIDWebServiceWrapper.BusinessRegistrationNumber_element BusinessRegistrationNumber {get; set;}
        public String BureauReference {get; set;}
        public String SearchType {get; set;}
    }
   /*
        This class is used for creating variables.
   */        
    public with sharing class OrgIdResult_element {
        
        //custom
        public integer OrgIdResultUniqueNumber {get;set;}
        public Boolean ShowSelect {get;set;}
        public String EntityTypeCustom {get;set;}
        public String EntityTypeMasterLabel {get;set;}
        public String EntityTypeLabel {get;set;}
        public String StatusString {get;set;}
        
        
        
        
        public String MatchName {get;set;}
        public String OrganisationNumber {get;set;}
        public APT_OrgIDWebServiceWrapper.OrganisationType_element OrganisationType {get;set;}
        public String AustralianBusinessNumber {get;set;}
        public String OrganisationNumberHeading {get;set;}
        public String State {get;set;}
        public APT_OrgIDWebServiceWrapper.ASICReport_element ASICReport {get;set;}
        public APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element AustralianBusinessRegisterReport {get;set;}
        public APT_OrgIDWebServiceWrapper.BureauReport_element BureauReport {get; set;}
        public APT_OrgIDWebServiceWrapper.ASICBNRReport_element ASICBNRReport {get; set;}
    }
   /*
        This class is used for creating variables.
   */    
    public with sharing class BureauReport_element {
        public APT_OrgIDWebServiceWrapper.Address_element[] Address {get; set;}
        public String LastSearchDate {get; set;}
        public String NatureOfBusiness {get; set;}
        public String[] ErrorMsg {get; set;}
        public String[] WarningMsg {get; set;}
        public String BureauReference {get; set;}
        public String BCACompanyType {get; set;}
        public String BCAName {get; set;}
    }
   /*
        This class is used for creating variables.
   */     
    public with sharing class DGR_element {
        public String DGRName {get; set;}
        public String DGRStatus {get; set;}
        public Date DGRFromDate {get; set;}
        public String DGRType {get; set;}
    }
   /*
        This class is used for creating variables.
   */     
    public with sharing class HolderReference_element {
        public String ABN {get; set;}
        public String ABREntityName {get; set;}
    }
       /*
        This class is used for creating variables.
   */ 
    public with sharing class BusinessNameHolderType {
        public String ABN {get; set;}
        public String ABREntityName {get; set;}
        public APT_OrgIDWebServiceWrapper.Individual_element Individual {get; set;}
        public APT_OrgIDWebServiceWrapper.Organisation_element Organisation {get; set;}
        public APT_OrgIDWebServiceWrapper.AssociatedBusinessNames_element AssociatedBusinessNames {get; set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class ErrorType {
        public String ErrorTypeCode {get; set;}
        public String InputContainer {get; set;}
        public String ErrorDescriptionTypeCode {get; set;}
        public String ErrorDescriptiontype {get;set;}
        public String ErrorTypeDesc {get;set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class ASICBNRReport_element {
        public APT_OrgIDWebServiceWrapper.BusinessNameType BusinessName {get; set;}
        public APT_OrgIDWebServiceWrapper.BusinessNameHolderType BusinessNameHolder {get;set;}
        public String[] ErrorMsg  {get;set;}
        public String[] WarningMsg {get;set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class OtherEntity_element {
        public String OtherEntityType {get; set;}
        public String OtherEntityName {get; set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class queryABNResponseType {
        public APT_OrgIDWebServiceWrapper.OrgIdResult_element[] OrgIdResult {get; set;}
        public APT_OrgIDWebServiceWrapper.ErrorType Error {get; set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class AssociatedBusinessNames_element {
        public APT_OrgIDWebServiceWrapper.BusinessName_element[] BusinessName {get; set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class StreetType_element  {
        public String Code {get; set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class Address_element {
        public String FirstReported {get; set;}
        public String Type_x {get; set;}
        
        public String UnitNumber {get; set;}
        public String StreetNumber {get; set;}
        public String Property {get; set;}
        public String StreetName {get; set;}
        public APT_OrgIDWebServiceWrapper.StreetType_element StreetType {get; set;}
        public String Suburb {get; set;}
        public String City {get; set;}
        public String State {get; set;}
        public String Postcode {get; set;}
        public APT_OrgIDWebServiceWrapper.Country_element Country {get; set;}
        public String DPID {get; set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class Country_element {
        public String CountryCode {get; set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class Organisation_element {
        public String Name {get; set;}
        public String ACN {get; set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class ErrorDescriptionType {
        
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class BusinessRegistrationNumber_element {
        public String State {get; set;}
        public String Number_x {get; set;}
    }
   /*
        This class is used for creating variables.
   */     
    public with sharing class Individual_element {
        public String GivenNames {get; set;}
        public String FamilyName {get; set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class ASICReport_element {
        public String ASICName {get; set;}
        public String ASICOrganisationNumber {get;set;}
        public String ASICABN {get;set;}
        public String ASICOrganisationNumberHeading {get;set;}
        public String ASICPrescribedInterestNumber {get;set;}
        public String ASICUndertakingName {get;set;}
        public String ASICType {get;set;}
        public Date ASICRegistrationDate {get;set;}
        public String ASICStatus {get;set;}
        public String ASICState {get;set;}
        public String ASICBusinessRegistrationNumber {get;set;}
        public String ASICJurisdiction {get;set;}
        public String[] ErrorMsg {get;set;}
        public String[] WarningMsg {get;set;}
        public String ASICLocality {get;set;}
        public String ASICAddressState {get;set;}
        public String ASICPostcode {get;set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class Status_element {
        public String Code {get; set;}
        public String Description {get; set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class BusinessNameType {
        public String RegisteredBusinessName {get; set;}
        public String DistinguishedWord {get; set;}
        public String VedaBusinessNameId {get; set;}
        public String PreviousStateTerritoryCode {get; set;}
        public String PreviousStateRegistrationNumber {get; set;}
        public APT_OrgIDWebServiceWrapper.HolderReference_element HolderReference {get; set;}
        public APT_OrgIDWebServiceWrapper.Status_element Status {get; set;}
        public APT_OrgIDWebServiceWrapper.Address_element[] Address {get; set;}
    }
   /*
        This class is used for creating variables.
   */ 
    public with sharing class OrganisationType_element {
        private String[] apex_schema_type_info = new String[]{APT_Constants.APEX_SCHEMA_URL1,APT_Constants.BOOLEAN_TRUE,APT_Constants.FALSE_2};
        private String[] field_order_type_info = new String[]{};
    }
   /*
        This class is used for creating variables.
   */     
    public with sharing class AustralianBusinessRegisterReport_element {
        public String ASICNumber {get;set;}
        public String ASICNumberType {get;set;}
        public String ABN {get;set;}
        public String ABNStatus {get;set;}
        public Date ABNStatusFromDate {get;set;}
        public String EntityTypeInd {get;set;}
        public String EntityTypeText {get;set;}
        public String[] IndividualName {get;set;}
        public String NonIndividualName {get;set;}
        public String BusinessAddressState {get;set;}
        public String BusinessAddressPostcode {get;set;}
        public String GSTStatus {get;set;}
        public Date GSTStatusFromDate {get;set;}
        public String TradingName {get;set;}
        public String[] ErrorMsg {get;set;}
        public String[] WarningMsg {get;set;}
        public APT_OrgIDWebServiceWrapper.DGR_element[] DGR {get;set;}
        public APT_OrgIDWebServiceWrapper.OtherEntity_element[] OtherEntity {get;set;}
    }    
}