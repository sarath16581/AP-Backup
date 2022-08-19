/**
 * Created by hasan on 10/08/2022.
 */

public with sharing class ChasEDDAddressValidationController {
    @AuraEnabled
    public static ChasApexController.TrackingNumberDetails getEDDEstimates(String articleId, String recipientPostcode){
        return ChasEDDServiceEstimates.getEDDEstimates(articleId,recipientPostcode);
    }
}