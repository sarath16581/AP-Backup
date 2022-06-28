/***
 * @description Help and support : Invokes the EDD service and gets the service estimates
 * @date 2021-07-04
 * @group Article
 * @tags Chas, H&S, EDD
 * @domain Help and Support
 * @changelog
 * 2021-07-04 hara.sahoo@auspost.com.au Created
 */
public with sharing class ChasEDDServiceEstimates {
    @AuraEnabled
    public static ChasApexController.TrackingNumberDetails getEDDEstimates(String articleId, String recipientPostcode){
        HttpResponse httpRes = new HttpResponse();
        String jsonString='';
        //Initializing the return wrapper obj
        ChasApexController.TrackingNumberDetails trackingNumDetailsWrapperObj = new ChasApexController.TrackingNumberDetails();
        // when no EDD returned from consignment service, call the shipment edd service to get delivery estimates
        if(!String.isEmpty(articleId) && !String.isEmpty(recipientPostcode))
            {
                httpRes = ChasCallout.requestEDDEstimates(articleId,recipientPostcode);
                jsonString = httpRes.getBody();
            }
            // status code 200 is success and the response body is not empty
            if(httpRes.getStatusCode() == 200 && !String.isEmpty(jsonString))
            {
                ChasEDDResponse EDDresponse = (ChasEDDResponse) System.JSON.deserialize(jsonString, ChasEDDResponse.class);
                if (EDDresponse != null)
                {
                    
                    EstimateShipmentEDD eddEstimates = new EstimateShipmentEDD(EDDresponse, articleId);
                    
                    // update the wrapper class for deciding the Thank You page variations and isEligibleForHold in createCaseFromMissingWizard
                    trackingNumDetailsWrapperObj.deliveredByDateOrEDD = eddEstimates.estimatedOnDate;
                    trackingNumDetailsWrapperObj.deliveredByDateFrom = eddEstimates.fromDate;
                    trackingNumDetailsWrapperObj.deliveredByDateTo = eddEstimates.toDate;
                    trackingNumDetailsWrapperObj.isEnquiryDateWithinEDDPlusBusinessdays = eddEstimates.isEnquiryDateWithinEDDPlusBusinessdays;
                    trackingNumDetailsWrapperObj.isEnquiryDateWithinEDD = eddEstimates.isEnquiryDateWithinEDD;
                    trackingNumDetailsWrapperObj.isEnquiryDatePastEDDPlusBusinessdays = eddEstimates.isEnquiryDatePastEDDPlusBusinessdays;
                    
                    // update the from and to dates if there is a range available
                    if(eddEstimates.estimatedOnDate !=null)
                    {
                        trackingNumDetailsWrapperObj.deliveredByDatePlusBusinessDays = ChasUtil.calculateNextBusinessDay(eddEstimates.estimatedOnDate,Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c != null ? Integer.valueOf(Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c): 0 );
                        // set the track status to EDD ESTIMATED
                        trackingNumDetailsWrapperObj.isEDDEstimated = true;
                        trackingNumDetailsWrapperObj.isNoEddReturned = false;
                    }
                    if(eddEstimates.toDate != null)
                    {
                        trackingNumDetailsWrapperObj.deliveredByDateToUntil = ChasUtil.calculateNextBusinessDay(eddEstimates.toDate,Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c != null ? Integer.valueOf(Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c): 0 );
                    }  
                }
            }
        return trackingNumDetailsWrapperObj;
    }
    

}