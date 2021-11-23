/**************************************************
Description:    Handles BAM Application config API requests to get details of all Applications .
				Custom Metadatatype : ResourceAPI__mdt
				// /v1.0/bam/applications
History:
--------------------------------------------------
2019-04-30  	lija.jawahar@auspost.com.au  Created
2019-05-27  	nathan.franklin@auspost.com.au  Changed Icon URL to SVG Ref
2019-05-28  	nathan.franklin@auspost.com.au  Added Service Type field
2019-06-02  	nathan.franklin@auspost.com.au  Added a more robust return response capability
2019-06-03  	lija.jawahar@auspost.com.au  	Updates As per code review feedback
**************************************************/

public with sharing class ResourceBamAppConfigV1 extends ResourceAPIService.IApi {

    public ResourceBamAppConfigV1(){
        // these fields represent the field mappings that are used
        API_FIELD_MAPPINGS = new Map<String, String>{
            'id' => 'Id',
            'applicationName'=> 'Name',
            'accessUrl'=> 'AccessUrl__c',
            'appKey' => 'AppKey__c',
            'configurationModel' => 'ConfigurationModel__c',
            'deprovisioningUrl' => 'DeprovisioningAPIUrl__c',
            'deprovisioningResponseTimeout' => 'DeprovisioningTimeout__c',
            'cancellationUrl' => 'CancellationAPIUrl__c',
            'description' => 'Description__c',
            'iconRef' => 'SVGRefId__c',
            'serviceType' => 'ServiceType__c',
            'provisioningUrl' => 'ProvisioningAPIUrl__c',
            'provisioningResponseTimeout' => 'ProvisioningTimeout__c',
            'shortDescription' => 'ShortDescription__c',
            'status' => 'Status__c',
            'validationUrl' => 'ValidationAPIUrl__c',
            'createdDate' => 'CreatedDate',
            'lastModifiedDate' => 'LastModifiedDate'
        };
    }

    /// /1.0/bam/applications
    public override ResourceAPIService.IResourceResponse query() {

        Object output = null;
        
        try{

            String uriParts = requestParams.uri;
            system.debug('ResourceBamAppConfigV1 requestParams ==>'+uriParts);

            //Query all the BAM applications
            List<BAMApplication__c> applications   = [
                                                        SELECT Id,Name,CreatedDate,LastModifiedDate,
                                                                AccessUrl__c,AppKey__c,ConfigurationModel__c,
                                                                DeprovisioningAPIUrl__c,Description__c,
                                                                ProvisioningAPIUrl__c, CancellationAPIUrl__c,
                                                                ServiceType__c,ShortDescription__c,Status__c,SVGRefId__c,
                                                                DeprovisioningTimeout__c, ProvisioningTimeout__c, ValidationAPIUrl__c
                                                        FROM BAMApplication__c
                										WHERE Status__c = 'Active'
                                                     ];

            if(applications.size()>0 ) {
                // rewrite the output fields to confirm to the mappings specified in this class
                output = normaliseOutput(applications , API_FIELD_MAPPINGS);
                return new ResourceAPIService.ResourceResponse(200, output);
            } else {
                // 404 Not found error
                return new ResourceAPIService.ResourceResponse(404,'Not Found' ,output);
            }

        } catch (Exception exp){
             return new ResourceAPIService.ResourceResponse(500,'', exp);
        }
    }



    //This will convert the records queried into their mapped values defined within each class
    public List<Map<String, Object>> normaliseOutput(List<SObject> records, Map<String, String> fieldMappings) {
        List<Map<String, Object>> output = new List<Map<String, Object>>();
        for(SObject record : records) {
            Map<String, Object> mapRecord = new Map<String, Object>();
            for(String key : fieldMappings.keySet()) {
                if(record.isSet(fieldMappings.get(key))) {
                    mapRecord.put(key, record.get(fieldMappings.get(key)));
                }
            }
            output.add(mapRecord);
        }
        return output;
    }

}