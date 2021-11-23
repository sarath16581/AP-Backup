/*------------------------------------------------------------
Author:   :      Dheeraj Mandavilli
Date Created:    12/11/2019
Description:     Mock Class For AME Response


History
<Date>           <Authors Name>    <Brief Description of Change>
12/11/2019      Dheeraj Mandavilli      Created
------------------------------------------------------------*/
global class PUD_MPBtoSFIntMockResponse2 implements HttpCalloutMock {
    /*public Id bookingId;
    public string conf;
    public string dpid;
    global PUD_MPBtoSFIntMockResponse2(final string dpid, final string conf,final Id bookingId){
         this.conf= conf;
         this.dpid = dpid;
         this.bookingId = bookingId;
 
    }*/
	global HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"id":"5e35c199-2ebf-42ac-ab1b-835b54efa4c2","results":[{"id":"75d04573-a9e1-414e-ace8-9845ff8f4be8","references":[],"addresses":[{"singleLine":"500 HAY ST PERTH WA 6000","score":1,"semiStructured":{"addressLines":["DISTRICT COURT OF WA","500 HAY ST"],"locality":"PERTH","state":"WA","postcode":"6000","countryName":"AUSTRALIA","countryCode":"AU"},"deliveryData":{"postcodeDID":"6000","localityDID":7608,"groupDID":123842,"roundDID":602862,"sectionDID":404527,"dpid":82496590,"sectionSequence":1260,"deliveryPointSequence":1,"deliveryOfficeRoundId":15,"phantom":false,"addressType":"THOROUGHFARE","thoroughfareAddressType":"PRIMARY","secondaryCount":0,"deliveryPointCategory":"BUSINESS"},"structured":{"locality":"PERTH","state":"WA","postcode":"6000","countryName":"AUSTRALIA","countryCode":"AU","thoroughfareName":"HAY","thoroughfareNumber1":"500","thoroughfareType":"ST","deliveryPointIdentifier":82496590,"buildingAliases":["DISTRICT COURT BUILDING","DISTRICT COURT OF WA"],"buildingName":"DISTRICT COURT OF WA"},"upu":{"addressLines":["DISTRICT COURT OF WA","500 HAY ST","PERTH WA 6000"]},"geoDataList":[{"featureType":"CENTROID","latitude":-31.95522663,"longitude":115.86339423}],"dpid":82496590,"confidence":"HIGH"}]}]}');
            return res;
        }
    
}