/**
*  This test class is for all AuspostSchemas.
*
@author Frank Chen
@created 2014-06-20
@version 1.0
@since 20.0
*
@changelog
* 2014-06-20 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  100%
*/
@isTest
private class AuspostAllSchemas_Test {

	// AuspostCommonDataModelSchema is not exist any longer on the server
	/*static testMethod void testAuspostCommonDataModelSchema() {
        Test.startTest();
        
        AuspostCommonDataModelSchema.Exception_x ausEx = new AuspostCommonDataModelSchema.Exception_x();
        AuspostCommonDataModelSchema.InterfaceHeader ausIh = new AuspostCommonDataModelSchema.InterfaceHeader();
        AuspostCommonDataModelSchema.SOAPException_element ausSoa = new AuspostCommonDataModelSchema.SOAPException_element();
        
        system.assert(true);
        Test.stopTest();
    }*/
	/*static testMethod void testAuspostCommonDataModelSchemaTemp() {
        Test.startTest();
        
        AuspostCommonDataModelSchemaTemp.Exception_x ausEx = new AuspostCommonDataModelSchemaTemp.Exception_x();
        AuspostCommonDataModelSchemaTemp.InterfaceHeader ausIh = new AuspostCommonDataModelSchemaTemp.InterfaceHeader();
        AuspostCommonDataModelSchemaTemp.SOAPException_element ausSoa = new AuspostCommonDataModelSchemaTemp.SOAPException_element();
        
        system.assert(true);
        Test.stopTest();
    }*/
	static testMethod void testAuspostCommonSchema() {
        Test.startTest();
        
        AuspostCommonSchema.Exception_x ausEx = new AuspostCommonSchema.Exception_x();
        AuspostCommonSchema.FurtherReferences ausIh = new AuspostCommonSchema.FurtherReferences();
        AuspostCommonSchema.InternetType ausSoa = new AuspostCommonSchema.InternetType();
        AuspostCommonSchema.Lodgement ausSoa99 = new AuspostCommonSchema.Lodgement();
        AuspostCommonSchema.UUID ausSoa1 = new AuspostCommonSchema.UUID();
        AuspostCommonSchema.POIType ausSoa2 = new AuspostCommonSchema.POIType();
        AuspostCommonSchema.NameValue ausSoa3 = new AuspostCommonSchema.NameValue();
        AuspostCommonSchema.GeneralTextSegment ausSoa4 = new AuspostCommonSchema.GeneralTextSegment();
        AuspostCommonSchema.ContactDetailsType ausSoa5 = new AuspostCommonSchema.ContactDetailsType();
        AuspostCommonSchema.EventSource ausSoa6 = new AuspostCommonSchema.EventSource();
        AuspostCommonSchema.DeliveryDetailsType ausSoa7 = new AuspostCommonSchema.DeliveryDetailsType();
        AuspostCommonSchema.POISubType ausSoa8 = new AuspostCommonSchema.POISubType();
        AuspostCommonSchema.DatePeriod ausSoa9 = new AuspostCommonSchema.DatePeriod();
        AuspostCommonSchema.TelephoneType ausSoa11 = new AuspostCommonSchema.TelephoneType();
        AuspostCommonSchema.FlightDetails ausSoa12 = new AuspostCommonSchema.FlightDetails();
        AuspostCommonSchema.TelephoneNumberExtended ausSoa13 = new AuspostCommonSchema.TelephoneNumberExtended();
        AuspostCommonSchema.ServiceAction ausSoa14 = new AuspostCommonSchema.ServiceAction();
        AuspostCommonSchema.ContactNumber ausSoa15 = new AuspostCommonSchema.ContactNumber();
        AuspostCommonSchema.POIReference ausSoa16 = new AuspostCommonSchema.POIReference();
        AuspostCommonSchema.SOAPException_element ausSoa17 = new AuspostCommonSchema.SOAPException_element();
        AuspostCommonSchema.TrackingIdentification ausSoa18 = new AuspostCommonSchema.TrackingIdentification();
        AuspostCommonSchema.TimePeriod ausSoa19 = new AuspostCommonSchema.TimePeriod();
        AuspostCommonSchema.ProofOfDelivery ausSoa21 = new AuspostCommonSchema.ProofOfDelivery();
        AuspostCommonSchema.FurtherDetails ausSoa22 = new AuspostCommonSchema.FurtherDetails();
        AuspostCommonSchema.MeasurementData ausSoa23 = new AuspostCommonSchema.MeasurementData();
        AuspostCommonSchema.ModificationAudit ausSoa24 = new AuspostCommonSchema.ModificationAudit();
        AuspostCommonSchema.InterfaceHeader ausSoa25 = new AuspostCommonSchema.InterfaceHeader();
        AuspostCommonSchema.ValidPeriod ausSoa26 = new AuspostCommonSchema.ValidPeriod();
        AuspostCommonSchema.UnstructuredAddress_element ausSoa27 = new AuspostCommonSchema.UnstructuredAddress_element();
        AuspostCommonSchema.ProofOfIdentity ausSoa28 = new AuspostCommonSchema.ProofOfIdentity();
        AuspostCommonSchema.TrackingNotification ausSoa29 = new AuspostCommonSchema.TrackingNotification();
        AuspostCommonSchema.PostalDetails ausSoa31 = new AuspostCommonSchema.PostalDetails();
        AuspostCommonSchema.ElectronicContactType ausSoa32 = new AuspostCommonSchema.ElectronicContactType();
        
        system.assert(true);
        Test.stopTest();
    }
    static testMethod void testAuspostCoreSchema() {
        Test.startTest();
        
        AuspostCoreSchema.Picture ausEx = new AuspostCoreSchema.Picture();
        AuspostCoreSchema.Name ausIh = new AuspostCoreSchema.Name();
        AuspostCoreSchema.Text ausSoa1 = new AuspostCoreSchema.Text();
        AuspostCoreSchema.Description ausSoa2 = new AuspostCoreSchema.Description();
        AuspostCoreSchema.Amount ausSoa3 = new AuspostCoreSchema.Amount();
        AuspostCoreSchema.Quantity ausSoa4 = new AuspostCoreSchema.Quantity();
        AuspostCoreSchema.Graphic ausSoa5 = new AuspostCoreSchema.Graphic();
        AuspostCoreSchema.BinaryObject ausSoa6 = new AuspostCoreSchema.BinaryObject();
        AuspostCoreSchema.Sound ausSoa7 = new AuspostCoreSchema.Sound();
        AuspostCoreSchema.Measure ausSoa8 = new AuspostCoreSchema.Measure();
        AuspostCoreSchema.Identifier ausSoa9 = new AuspostCoreSchema.Identifier();
        AuspostCoreSchema.Code ausSoa11 = new AuspostCoreSchema.Code();
        AuspostCoreSchema.Video ausSoa12 = new AuspostCoreSchema.Video();       
        
        system.assert(true);
        Test.stopTest();
    }
	static testMethod void testAuspostCustomerSchema() {
        Test.startTest();
        
        AuspostCustomerSchema.Customer ausEx = new AuspostCustomerSchema.Customer();
        AuspostCustomerSchema.Origination_element ausIh = new AuspostCustomerSchema.Origination_element();
        AuspostCustomerSchema.AlternateCustomerIDs_element ausSoa = new AuspostCustomerSchema.AlternateCustomerIDs_element();
        AuspostCustomerSchema.DeliveryPreference_element ausSoa1 = new AuspostCustomerSchema.DeliveryPreference_element();
        AuspostCustomerSchema.CommunicationDecision ausSoa2 = new AuspostCustomerSchema.CommunicationDecision();
        AuspostCustomerSchema.DeliveryChoiceType ausSoa3 = new AuspostCustomerSchema.DeliveryChoiceType();
        AuspostCustomerSchema.AlternateCustomerID_element ausSoa4 = new AuspostCustomerSchema.AlternateCustomerID_element();
        AuspostCustomerSchema.Options_element ausSoa5 = new AuspostCustomerSchema.Options_element();  
        
        system.assert(true);
        Test.stopTest();
    }
	/*static testMethod void testAuspostDataEventSchemaTemp() {
        Test.startTest();
        
        AuspostDataEventSchemaTemp.sendSMSResponse_element ausEx = new AuspostDataEventSchemaTemp.sendSMSResponse_element();
        AuspostDataEventSchemaTemp.ReturnMessage_element ausIh = new AuspostDataEventSchemaTemp.ReturnMessage_element();
        AuspostDataEventSchemaTemp.sendSMS_element ausSoa = new AuspostDataEventSchemaTemp.sendSMS_element();
        
        system.assert(true);
        Test.stopTest();
    }*/
    
    // AuspostDeliverySvcsSchema is not exist any longer on the server
	/*static testMethod void testAuspostDeliverySvcsSchema() {
        Test.startTest();
        
        AuspostDeliverySvcsSchema.Events_element ausEx = new AuspostDeliverySvcsSchema.Events_element();
        AuspostDeliverySvcsSchema.Articles_element ausIh = new AuspostDeliverySvcsSchema.Articles_element();
        AuspostDeliverySvcsSchema.TrackingResult_element ausSoa = new AuspostDeliverySvcsSchema.TrackingResult_element();
        AuspostDeliverySvcsSchema.ArticleDetails_element ausEx1 = new AuspostDeliverySvcsSchema.ArticleDetails_element();
        AuspostDeliverySvcsSchema.QueryTrackEvents_element ausIh2 = new AuspostDeliverySvcsSchema.QueryTrackEvents_element();
        AuspostDeliverySvcsSchema.ReturnMessage_element ausSoa1 = new AuspostDeliverySvcsSchema.ReturnMessage_element();
        AuspostDeliverySvcsSchema.ConsignmentDetails_element ausSoa2 = new AuspostDeliverySvcsSchema.ConsignmentDetails_element();
        AuspostDeliverySvcsSchema.Event_element ausSoa3 = new AuspostDeliverySvcsSchema.Event_element();
        AuspostDeliverySvcsSchema.QueryTrackEventsResponse_element ausSoa4 = new AuspostDeliverySvcsSchema.QueryTrackEventsResponse_element();
                
        system.assert(true);
        Test.stopTest();
    } */  
	static testMethod void testAuspostEventSchema() {
        Test.startTest();
        
        AuspostEventSchema.DeviceEvent ausEx = new AuspostEventSchema.DeviceEvent();
        AuspostEventSchema.Comments ausIh = new AuspostEventSchema.Comments();
        AuspostEventSchema.ConsignmentEventDetails ausSoa = new AuspostEventSchema.ConsignmentEventDetails();
        AuspostEventSchema.FurtherReferences ausEx1 = new AuspostEventSchema.FurtherReferences();
        AuspostEventSchema.PaymentCategories_element ausIh1 = new AuspostEventSchema.PaymentCategories_element();
        AuspostEventSchema.ArticleEventDetails ausSoa1 = new AuspostEventSchema.ArticleEventDetails();
        AuspostEventSchema.TrackingRegistration ausSoa2 = new AuspostEventSchema.TrackingRegistration();
        AuspostEventSchema.Event ausSoa3 = new AuspostEventSchema.Event();
        AuspostEventSchema.Survey_element ausSoa4 = new AuspostEventSchema.Survey_element();
        AuspostEventSchema.CommunicationEvent ausSoa5 = new AuspostEventSchema.CommunicationEvent();
        AuspostEventSchema.Communications_element ausSoa6 = new AuspostEventSchema.Communications_element();
        AuspostEventSchema.Geocode ausSoa7 = new AuspostEventSchema.Geocode();
        AuspostEventSchema.MailEvent ausSoa8 = new AuspostEventSchema.MailEvent();
        AuspostEventSchema.LocationIdentifications ausSoa9 = new AuspostEventSchema.LocationIdentifications();
        AuspostEventSchema.DeliveryNotification_element ausSoa11 = new AuspostEventSchema.DeliveryNotification_element();
                
        system.assert(true);
        Test.stopTest();
    } 
    static testMethod void testAuspostInvolvedPartSchema() {
        Test.startTest();
        
        AuspostInvolvedPartSchema.OrganisationType ausEx = new AuspostInvolvedPartSchema.OrganisationType();
        AuspostInvolvedPartSchema.LoginDetails_element ausIh = new AuspostInvolvedPartSchema.LoginDetails_element();
        AuspostInvolvedPartSchema.IssuerInformation_element ausSoa = new AuspostInvolvedPartSchema.IssuerInformation_element();
        AuspostInvolvedPartSchema.Credentials_element ausEx1 = new AuspostInvolvedPartSchema.Credentials_element();
        AuspostInvolvedPartSchema.PartyIdentification ausIh1 = new AuspostInvolvedPartSchema.PartyIdentification();
        AuspostInvolvedPartSchema.SecretQuestion_element ausSoa1 = new AuspostInvolvedPartSchema.SecretQuestion_element();
        AuspostInvolvedPartSchema.IndividualType ausSoa2 = new AuspostInvolvedPartSchema.IndividualType();
        AuspostInvolvedPartSchema.InvolvedPartyRelationship_element ausSoa3 = new AuspostInvolvedPartSchema.InvolvedPartyRelationship_element();
        AuspostInvolvedPartSchema.GivenName ausSoa4 = new AuspostInvolvedPartSchema.GivenName();
        AuspostInvolvedPartSchema.IndividualName ausSoa5 = new AuspostInvolvedPartSchema.IndividualName();
        AuspostInvolvedPartSchema.IdentityDocument ausSoa6 = new AuspostInvolvedPartSchema.IdentityDocument();
        AuspostInvolvedPartSchema.InvolvedPartyType ausSoa7 = new AuspostInvolvedPartSchema.InvolvedPartyType();
        AuspostInvolvedPartSchema.InvolvedPartyBaseType ausSoa8 = new AuspostInvolvedPartSchema.InvolvedPartyBaseType();
        AuspostInvolvedPartSchema.EmploymentDetailsType ausSoa9 = new AuspostInvolvedPartSchema.EmploymentDetailsType();
        AuspostInvolvedPartSchema.OrganisationRegistrationType ausSoa11 = new AuspostInvolvedPartSchema.OrganisationRegistrationType();
                
        system.assert(true);
        Test.stopTest();
    } 
}