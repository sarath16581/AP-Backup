/**
 *Test class for schema classes.
 @author Fuqi Tan
 @created 2014-06-20
 *- Test coverage 99%
*/

@isTest
private class SchemaClassesGroupA_Test{
    @IsTest
    static void testGeneral(){
        AuspostLocationSchema schema1 = new AuspostLocationSchema();
        AuspostLocationSchema.InternationalAddress innerClass1 = new AuspostLocationSchema.InternationalAddress();
        AuspostLocationSchema.DetailedInternationalAddress innerClass2 = new AuspostLocationSchema.DetailedInternationalAddress();
        AuspostLocationSchema.optionalDateArgumentsType innerClass3 = new AuspostLocationSchema.optionalDateArgumentsType();
        AuspostLocationSchema.PostalDelivery_element innerClass4 = new AuspostLocationSchema.PostalDelivery_element();
        AuspostLocationSchema.AustralianStructuredAddressPartialComponents innerClass5 = new AuspostLocationSchema.AustralianStructuredAddressPartialComponents();
        AuspostLocationSchema.PostalDeliveryType innerClass6 = new AuspostLocationSchema.PostalDeliveryType();
        AuspostLocationSchema.StreetType innerClass7 = new AuspostLocationSchema.StreetType();
        AuspostLocationSchema.FloorOrLevel_element innerClass8 = new AuspostLocationSchema.FloorOrLevel_element();
        AuspostLocationSchema.UnstructuredAddressLineType innerClass9 = new AuspostLocationSchema.UnstructuredAddressLineType();
        AuspostLocationSchema.ThoroughfareAddressType innerClass10 = new AuspostLocationSchema.ThoroughfareAddressType();
        AuspostLocationSchema.PrivateThoroughfareType innerClass11 = new AuspostLocationSchema.PrivateThoroughfareType();
        AuspostLocationSchema.AustralianPartialAddress innerClass12 = new AuspostLocationSchema.AustralianPartialAddress();
        AuspostLocationSchema.AustralianAddressSearch innerClass13 = new AuspostLocationSchema.AustralianAddressSearch();
        AuspostLocationSchema.House_element innerClass14 = new AuspostLocationSchema.House_element();
        AuspostLocationSchema.StandardInternationalAddressType innerClass15 = new AuspostLocationSchema.StandardInternationalAddressType();
        AuspostLocationSchema.LotType innerClass16 = new AuspostLocationSchema.LotType();
        AuspostLocationSchema.CountryType innerClass17 = new AuspostLocationSchema.CountryType();
        AuspostLocationSchema.FlatOrUnit_element innerClass18 = new AuspostLocationSchema.FlatOrUnit_element();
        AuspostLocationSchema.HouseType innerClass19 = new AuspostLocationSchema.HouseType();
        AuspostLocationSchema.InternationalUnstructuredAddressType innerClass20 = new AuspostLocationSchema.InternationalUnstructuredAddressType();
        AuspostLocationSchema.FlatOrUnitType innerClass21 = new AuspostLocationSchema.FlatOrUnitType();
        AuspostLocationSchema.AddressDetailsType innerClass22 = new AuspostLocationSchema.AddressDetailsType();
        AuspostLocationSchema.StandardAustralianAddressType innerClass23 = new AuspostLocationSchema.StandardAustralianAddressType();
        AuspostLocationSchema.Lot_element innerClass24 = new AuspostLocationSchema.Lot_element();
        AuspostLocationSchema.AddressPeriod_element innerClass25 = new AuspostLocationSchema.AddressPeriod_element();
        AuspostLocationSchema.AustralianAddress innerClass26 = new AuspostLocationSchema.AustralianAddress();
        AuspostLocationSchema.FloorOrLevelType innerClass27 = new AuspostLocationSchema.FloorOrLevelType();
        AuspostLocationSchema.Address innerClass28 = new AuspostLocationSchema.Address();
        AuspostLocationSchema.Street_element innerClass29 = new AuspostLocationSchema.Street_element();
        AuspostLocationSchema.PostalDeliveryNumber_element innerClass30 = new AuspostLocationSchema.PostalDeliveryNumber_element();
        AuspostLocationSchema.UnstructuredAddress_element innerClass31 = new AuspostLocationSchema.UnstructuredAddress_element();
        AuspostLocationSchema.AddressType innerClass32 = new AuspostLocationSchema.AddressType();
        AuspostLocationSchema.AustralianStructuredAddressComponents innerClass33 = new AuspostLocationSchema.AustralianStructuredAddressComponents();
        
        AuspostMailProductSchema schema2 = new AuspostMailProductSchema();
        AuspostMailProductSchema.InternationalDetails  innerClass101 = new AuspostMailProductSchema.InternationalDetails();
        AuspostMailProductSchema.TransportDetails_element  innerClass102 = new AuspostMailProductSchema.TransportDetails_element();
        AuspostMailProductSchema.Device  innerClass103 = new AuspostMailProductSchema.Device();
        AuspostMailProductSchema.ArticleContentsItemType  innerClass104 = new AuspostMailProductSchema.ArticleContentsItemType();
        AuspostMailProductSchema.Consignment  innerClass105 = new AuspostMailProductSchema.Consignment();
        AuspostMailProductSchema.DeliveryContact  innerClass106 = new AuspostMailProductSchema.DeliveryContact();
        AuspostMailProductSchema.InternationalContentsItemType  innerClass107 = new AuspostMailProductSchema.InternationalContentsItemType();
        AuspostMailProductSchema.DeliveryFailureDetailsType  innerClass108 = new AuspostMailProductSchema.DeliveryFailureDetailsType();
        AuspostMailProductSchema.Insurance  innerClass109 = new AuspostMailProductSchema.Insurance();
        AuspostMailProductSchema.TrackableObject  innerClass110 = new AuspostMailProductSchema.TrackableObject();
        AuspostMailProductSchema.Article  innerClass111 = new AuspostMailProductSchema.Article();
        AuspostMailProductSchema.Manifest  innerClass112 = new AuspostMailProductSchema.Manifest();
        AuspostMailProductSchema.BulkDeliveryManifest  innerClass113 = new AuspostMailProductSchema.BulkDeliveryManifest();
        AuspostMailProductSchema.Document_element  innerClass114 = new AuspostMailProductSchema.Document_element();
        AuspostMailProductSchema.Despatch  innerClass115 = new AuspostMailProductSchema.Despatch();
        AuspostMailProductSchema.OrderNumber  innerClass116 = new AuspostMailProductSchema.OrderNumber();
        AuspostMailProductSchema.ArticleStatus  innerClass117 = new AuspostMailProductSchema.ArticleStatus();
        AuspostMailProductSchema.InternationalReceptacle  innerClass118 = new AuspostMailProductSchema.InternationalReceptacle();
        AuspostMailProductSchema.ReferenceDetails  innerClass119 = new AuspostMailProductSchema.ReferenceDetails();
        AuspostMailProductSchema.ServiceProfiles_element  innerClass120 = new AuspostMailProductSchema.ServiceProfiles_element();
        
        AuspostProductSchema schema3 = new AuspostProductSchema();
        AuspostProductSchema.ServiceCodes_element innerClass201 = new AuspostProductSchema.ServiceCodes_element();
        AuspostProductSchema.Product_v2 innerClass202 = new AuspostProductSchema.Product_v2();
        AuspostProductSchema.ApplicationIdentifierDetails innerClass203 = new AuspostProductSchema.ApplicationIdentifierDetails();
        AuspostProductSchema.Barcode innerClass204 = new AuspostProductSchema.Barcode();
        AuspostProductSchema.Service innerClass205 = new AuspostProductSchema.Service();
        AuspostProductSchema.ServiceQualifier_element innerClass206 = new AuspostProductSchema.ServiceQualifier_element();
        AuspostProductSchema.ProductInstanceID innerClass207 = new AuspostProductSchema.ProductInstanceID();
        AuspostProductSchema.AIDefinitions innerClass208 = new AuspostProductSchema.AIDefinitions();
        AuspostProductSchema.Product innerClass209 = new AuspostProductSchema.Product();
        AuspostProductSchema.ServiceProfile innerClass210 = new AuspostProductSchema.ServiceProfile();
        AuspostProductSchema.BarcodeMask innerClass211 = new AuspostProductSchema.BarcodeMask();
        AuspostProductSchema.ProductID innerClass212 = new AuspostProductSchema.ProductID();
        AuspostProductSchema.MaskExtensionIdentification_element innerClass213 = new AuspostProductSchema.MaskExtensionIdentification_element();
        AuspostProductSchema.MaskProfileDetails innerClass214 = new AuspostProductSchema.MaskProfileDetails();
        AuspostProductSchema.ProductBasicDetails innerClass215 = new AuspostProductSchema.ProductBasicDetails();
        AuspostProductSchema.SubProduct innerClass216 = new AuspostProductSchema.SubProduct();
        AuspostProductSchema.ServiceCodeExtension innerClass217 = new AuspostProductSchema.ServiceCodeExtension();
        AuspostProductSchema.MaskProfile innerClass218 = new AuspostProductSchema.MaskProfile();
        AuspostProductSchema.Services innerClass219 = new AuspostProductSchema.Services();
        AuspostProductSchema.ServiceProfileActions innerClass220 = new AuspostProductSchema.ServiceProfileActions();
        AuspostProductSchema.ProductClass innerClass221 = new AuspostProductSchema.ProductClass();
        AuspostProductSchema.ServiceCode innerClass222 = new AuspostProductSchema.ServiceCode();
        AuspostProductSchema.ApplicationIdentifiers innerClass223 = new AuspostProductSchema.ApplicationIdentifiers();
        AuspostProductSchema.BarcodeMaskExtension innerClass224 = new AuspostProductSchema.BarcodeMaskExtension();
        AuspostProductSchema.ServiceCodeGroup_element innerClass225 = new AuspostProductSchema.ServiceCodeGroup_element();
        AuspostProductSchema.AIDataProfiles innerClass226 = new AuspostProductSchema.AIDataProfiles();
        
        AuspostQueryTrackEventsSchema schema4 = new AuspostQueryTrackEventsSchema();
        AuspostQueryTrackEventsSchema.QueryTrackEventsRequest_element innerClass301 = new AuspostQueryTrackEventsSchema.QueryTrackEventsRequest_element();
        AuspostQueryTrackEventsSchema.TrackingResults_element innerClass302 = new AuspostQueryTrackEventsSchema.TrackingResults_element();
        AuspostQueryTrackEventsSchema.ArticleDetails_element innerClass303 = new AuspostQueryTrackEventsSchema.ArticleDetails_element();
        AuspostQueryTrackEventsSchema.ArticleEnvelope innerClass304 = new AuspostQueryTrackEventsSchema.ArticleEnvelope();
        AuspostQueryTrackEventsSchema.ConsignmentEnvelope innerClass305 = new AuspostQueryTrackEventsSchema.ConsignmentEnvelope();
        AuspostQueryTrackEventsSchema.ReturnMessage_element innerClass306 = new AuspostQueryTrackEventsSchema.ReturnMessage_element();
        AuspostQueryTrackEventsSchema.ConsignmentDetails_element innerClass307 = new AuspostQueryTrackEventsSchema.ConsignmentDetails_element();
        AuspostQueryTrackEventsSchema.TrackingResults innerClass308 = new AuspostQueryTrackEventsSchema.TrackingResults();
        AuspostQueryTrackEventsSchema.QueryTrackEventsResponse_element innerClass309 = new AuspostQueryTrackEventsSchema.QueryTrackEventsResponse_element();
    }
}