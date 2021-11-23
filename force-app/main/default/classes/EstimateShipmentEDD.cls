/***
 * @description Help and support : Common wrapper class/ utility methods to process the shipment EDD service response
 * @date 2021-07-04
 * @group Article
 * @tags Chas, H&S, EDD
 * @domain Core
 * @changelog
 * 2021-07-04 hara.sahoo@auspost.com.au Created
 */
public with sharing class EstimateShipmentEDD {
    public String receiverPostCode='';
    public ChasEDDResponse.Articles article;
    public String articleId ='';
    public Date estimatedOnDate;
    public Date fromDate;
    public Date toDate;
    public Date deliveredByDatePlusBusinessDays;
    public Date deliveredByDateToUntil;
    public ChasEDDResponse.EstimatedDelivery estimatedDelivery;
    public ChasEDDResponse.ExpectedBetween expectedBetween;
    public class ArticleStatusException extends Exception {}
    public Integer responseCode;
    
    public EstimateShipmentEDD(ChasEDDResponse response, String trackingId) {
        if(response == null) {
            throw new ArticleStatusException('Article could not be found.');
        }else 
        {
            article = response.articles[0];
            this.articleId = article.Id;
            // article id from consignment service matches to that of the EDD service
            if(articleId == trackingId){
                estimatedDelivery = article.estimatedDelivery;
                if(article.estimatedDelivery.expectedBetween != null)
                {
                    expectedBetween = article.estimatedDelivery.expectedBetween;
                    
                }
            }
        }
        // assign the EDD
        if(estimatedDelivery != null)
        {
            estimatedOnDate = Date.valueOf(article.estimatedDelivery.onDate);
        }
        // assign EDD range if available
        if(expectedBetween != null)
        {
            fromDate=Date.valueOf(article.estimatedDelivery.expectedBetween.fromDate);
            toDate=Date.valueOf(article.estimatedDelivery.expectedBetween.toDate);
        }
    }
    // check if estimatedOnDate is within EDD
    public Boolean isEnquiryDateWithinEDD {
       get {	
            if (estimatedOnDate != null && Date.Today() <= estimatedOnDate)	
            {	
                return true;	
            }	
            return false;	
        }	
        set;	 
    }
    // check if estimatedOnDate is within EDD Plus Business days
    public Boolean isEnquiryDateWithinEDDPlusBusinessdays {	
        get {	
            if (estimatedOnDate != null && ChasUtil.isTheDateWithinEDDPlusBusinessdays(estimatedOnDate))	
            {	
                return true;	
            }	
            return false;	
        }	
        set;	
    }	
    // check if current date is past EDD Plus Business days	
    public Boolean isEnquiryDatePastEDDPlusBusinessdays {	
        get {	
            if (estimatedOnDate != null && ChasUtil.isTheDatePastEDDPlusBusinessdays(estimatedOnDate))	
            {	
                return true;	
            }	
            return false;	
        }	
        set;	
    }
}