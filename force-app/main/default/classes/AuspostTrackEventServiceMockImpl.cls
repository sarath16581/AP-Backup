/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 30/09/2015
  * @description  : Mock class for Tracking event service
  * changelog:
  * 2021-09-09	seth.heang@auspost.com.au		Uplift SF API version to 52
  */   
@isTest
public class AuspostTrackEventServiceMockImpl implements WebServiceMock{
    
    // constants
    private static final String ARTICLE_ID = '12345';
    
    /**
      * @description       Mock webservice which simulates the response for article tracking
      * @param             stub, request, response, endpoint, soapAction, requestName, responseNS, 
                           responseName, responseType
      * @return            Void
      * @throws            NA
      */
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
        
        System.debug('** trackingResults ==>'+ trackingResults);
        
        AuspostQueryTrackEventsSchema.ArticleDetails_element article = new  AuspostQueryTrackEventsSchema.ArticleDetails_element();
        
        AuspostQueryTrackEventsSchema.ArticleEnvelope envelope = new AuspostQueryTrackEventsSchema.ArticleEnvelope();
        
        AuspostMailProductSchema.Article art = new AuspostMailProductSchema.Article();
        art.ArticleId = ARTICLE_ID;
        
        envelope.Article = art;
        
        article.ArticleEnvelope = envelope;
        
        trackResult.ArticleDetails = article;
        trackResult.TrackingID = ARTICLE_ID;
        trackingResults.add(trackResult);
        
        resultsElem.TrackingResult = trackingResults;
        resp.TrackingResults = resultsElem ;
        System.debug('** resultsElem==>'+ resultsElem);
        response.put('response_x', resp); 
        System.debug('** response ==>'+ response);
   }
}