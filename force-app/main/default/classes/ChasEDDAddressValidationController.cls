/**
 * @author Hasantha Liyanage
 * @date 2022-08-10
 * @group Chas
 * @tag EDD service
 * @tag DDS-11627
 * @domain Help & Support
 * @description calculated EDD service estimate
 * @changelog
 * 2022-08-10 - Hasantha Liyanage - Created
 */

public with sharing class ChasEDDAddressValidationController {
    @AuraEnabled
    public static ChasApexController.TrackingNumberDetails getEDDEstimates(String articleId, String recipientPostcode){
        return ChasEDDServiceEstimates.getEDDEstimates(articleId,recipientPostcode);
    }
}