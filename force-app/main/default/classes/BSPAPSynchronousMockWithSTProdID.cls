//Created by David Catindoy - March 30, 2017
@isTest
public class BSPAPSynchronousMockWithSTProdID implements WebServiceMock{
    
    // constants
    public void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
        
        AuspostQueryTrackEventsSchema.QueryTrackEventsResponse_element resp = new AuspostQueryTrackEventsSchema.QueryTrackEventsResponse_element();
        AuspostQueryTrackEventsSchema.TrackingResults_element resultsElem = new AuspostQueryTrackEventsSchema.TrackingResults_element();
        List<AuspostQueryTrackEventsSchema.TrackingResults> trackingResults = new List<AuspostQueryTrackEventsSchema.TrackingResults>();
        AuspostQueryTrackEventsSchema.TrackingResults trackResult = new AuspostQueryTrackEventsSchema.TrackingResults();
        
        AuspostQueryTrackEventsSchema.ConsignmentDetails_element consignment = new AuspostQueryTrackEventsSchema.ConsignmentDetails_element();
        AuspostQueryTrackEventsSchema.ArticleEnvelope artEnvelope = new AuspostQueryTrackEventsSchema.ArticleEnvelope();
        AuspostQueryTrackEventsSchema.ConsignmentEnvelope conEnvelope = new AuspostQueryTrackEventsSchema.ConsignmentEnvelope();
        AuspostMailProductSchema.Article art = new AuspostMailProductSchema.Article();
        AuspostMailProductSchema.Consignment consign = new AuspostMailProductSchema.Consignment();
        
        //Assign field values to child article.
        art.ArticleId = '2G897466';
        art.ProductID = '002'; //Assign ST Product ID
        art.ProductName = 'eParcel';
        art.MerchantLocationId = 'NLP';
        
        //Assign created article to article envelope.
        artEnvelope.Article = art;
        
        //Assign field values to the parent consignment.
        consign.ConsignmentId = '2AT71923';
        consign.MerchantId = '20374611';
        consign.MerchantLocationId = 'NLP';
        
        //Assign consignment and its child article to the consignment envelope.
        conEnvelope.Consignment = consign;
        conEnvelope.ArticleEnvelope = new List<AuspostQueryTrackEventsSchema.ArticleEnvelope>{artEnvelope};
        
        //Assign consignment envelope to consignment details element.
        consignment.ConsignmentEnvelope = conEnvelope;
        
        //Assign consignment details element, tracking id and result description to tracking result.
        trackResult.ConsignmentDetails = consignment;
        trackResult.TrackingID = '2AT71923';
        trackResult.ResultDescription = BspConstants.SUCCESS;
        trackingResults.add(trackResult);
        
        resultsElem.TrackingResult = trackingResults;
        resp.TrackingResults = resultsElem ;
        response.put('response_x', resp);
        System.debug('Synchronous Response: ' + response);
   }
}