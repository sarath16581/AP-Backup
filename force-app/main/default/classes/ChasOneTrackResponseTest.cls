/**
*
* Response Parser test class
*
* History :
* --------------------------------------------------
* 2019-09-23 hasantha.liyanage@auspost.com.au Created
* 2020-08-13 hara.sahoo@auspost.com.au Modified
* 2020-09-15 hara.sahoo@auspost.com.au Modified to cater to the new ChasTrackStatus changes
* 2020-10-06 haraprasad.sahoo@auspost.com.au Modified : Caters for consignment search API
*/

@isTest
public with sharing class ChasOneTrackResponseTest {
    static testMethod void testParse() {
       
        String json = '{'+
            '    \"articles\": ['+
            '        {'+
            '            \"href\": \"/consignment/v2/articles/3BE501273001000934506\",'+
            '            \"id\": \"3BE501273001000934506\",'+
            '            \"code\": \"3BE501273001000934506\",'+
            '            \"consignmentId\": \"UhcyXLoRPb9dIVzjybV65huQecJCLpIxXRom9cFCl7-WF80Negg=\",'+
            '            \"consignmentCode\": \"3BE5012730\",'+
            '            \"fullBarcode\": \"0199312650999998913BE501273001000934506|4203057|9237133425|8008200928134027\",'+
            '            \"shortBarcode\": \"0199312650999998913BE501273001000934506\",'+
            '            \"isRegisteredByAP\": true,'+
            '            \"isReceivedByAP\": false,'+
            '            \"lastModifiedOn\": \"2020-10-04T23:40:33+00:00\",'+
            '            \"dispatchedOn\": \"2020-09-28T05:34:01+00:00\",'+
            '            \"etag\": \"6c0edd304214fe7f096a05b1c3abae5c\",'+
            '            \"expectedDelivery\": {'+
            '                \"eventDateTime\": \"2020-10-01T00:00:00+00:00\",'+
            '                \"eventDateTimeChanged\": false,'+
            '                \"between\": {'+
            '                    \"from\": \"2020-09-30T00:00:00+00:00\",'+
            '                    \"to\": \"2020-10-02T00:00:00+00:00\"'+
            '                }'+
            '            },'+
            '            \"service\": {'+
            '                \"productId\": null,'+
            '                \"productType\": \"Parcel Post\",'+
            '                \"subProductId\": null,'+
            '                \"subProductType\": null'+
            '            },'+
            '            \"milestone\": {'+
            '                \"eventDateTime\": \"2020-09-29T09:52:25+00:00\",'+
            '                \"name\": \"Delivered\",'+
            '                \"description\": null,'+
            '                \"progressPercentage\": 100'+
            '            },'+
            '            \"destinationAddress\": {'+
            '                \"line1\": \"13 IVORY WAY\",'+
            '                \"line2\": null,'+
            '                \"line3\": null,'+
            '                \"suburb\": \"BRUNSWICK EAST\",'+
            '                \"state\": \"VIC\",'+
            '                \"postcode\": \"3057\",'+
            '                \"countryCode\": \"AU\",'+
            '                \"deliveryPoint\": {'+
            '                    \"href\": \"/locations/v2/points/deliverypoints/37133425\",'+
            '                    \"id\": \"37133425\"'+
            '                }'+
            '            },'+
            '            \"deliveryInstructions\": {'+
            '                \"signatureOnDelivery\": {'+
            '                    \"required\": true,'+
            '                    \"instruction\": {'+
            '                        \"code\": \"SIG_ALWAYS_REQUIRED\"'+
            '                    }'+
            '                },'+
            '                \"redirect\": {'+
            '                    \"status\": \"RD_STATUS_REQUEST_DISABLED\",'+
            '                    \"redirectChange\": {'+
            '                        \"allowed\": false,'+
            '                        \"reasonCode\": \"RD_ELIG_TOO_LATE\"'+
            '                    }'+
            '                },'+
            '                \"safeDrop\": {'+
            '                    \"status\": \"SD_STATUS_INELIGIBLE\",'+
            '                    \"location\": null,'+
            '                    \"locationChange\": {'+
            '                        \"allowed\": false,'+
            '                        \"reasonCode\": \"SD_ELIG_DISALLOWED_SIG_REQUIRED\"'+
            '                    }'+
            '                }'+
            '            },'+
            '            \"deliverySummary\": {'+
            '                \"signedFor\": true,'+
            '                \"redirect\": null,'+
            '                \"safeDrop\": null'+
            '            },'+
            '            \"returnInstructions\": {'+
            '                \"returnToSender\": false'+
            '            },'+
            '            \"consignmentCount\": 1,'+
            '            \"consignments\": {'+
            '                \"items\": ['+
            '                    {'+
            '                        \"href\": \"/consignment/v2/consignments/@UhcyXLoRPb9dIVzjybV65huQecJCLpIxXRom9cFCl7-WF80Negg=\",'+
            '                        \"id\": \"UhcyXLoRPb9dIVzjybV65huQecJCLpIxXRom9cFCl7-WF80Negg=\",'+
            '                        \"code\": \"3BE5012730\",'+
            '                        \"primary\": true'+
            '                    }'+
            '                ]'+
            '            },'+
            '            \"foundByTrackingReferences\": ['+
            '                {'+
            '                    \"id\": \"3BE5012730\",'+
            '                    \"type\": \"IDTYPE_CONSIGNMENT_CODE\"'+
            '                }'+
            '            ],'+
            '            \"eventCount\": 7,'+
            '            \"trackingEvents\": {'+
            '                \"href\": \"/consignment/v2/articles/3BE501273001000934506?expand=articles,events\",'+
            '                \"items\": ['+
            '                    {'+
            '                        \"id\": \"3BE501273001000934506\",'+
            '                        \"code\": \"DD-ER13\",'+
            '                        \"eventDateTime\": \"2020-09-29T09:52:25+00:00\",'+
            '                        \"message\": \"Delivered\",'+
            '                        \"location\": \"BRUNSWICK EAST VIC, 3057\",'+
            '                        \"workCentreId\": \"351476\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273001000934506\",'+
            '                        \"code\": \"AFP-ER13\",'+
            '                        \"eventDateTime\": \"2020-09-29T07:55:53+00:00\",'+
            '                        \"message\": \"Onboard for delivery\",'+
            '                        \"location\": \"CRAIGIEBURN VIC, 3064\",'+
            '                        \"workCentreId\": \"351476\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273001000934506\",'+
            '                        \"code\": \"NSS-ER42\",'+
            '                        \"eventDateTime\": \"2020-09-29T05:43:35+00:00\",'+
            '                        \"message\": \"Item processed at facility\",'+
            '                        \"location\": \"SOMERTON VIC, 3062\",'+
            '                        \"workCentreId\": \"307969\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273001000934506\",'+
            '                        \"code\": \"NT-ER37\",'+
            '                        \"eventDateTime\": \"2020-09-28T21:28:00+00:00\",'+
            '                        \"message\": \"In transit\",'+
            '                        \"location\": \"DANDENONG SOUTH VIC, 3175\",'+
            '                        \"workCentreId\": \"353316\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273001000934506\",'+
            '                        \"code\": \"AFC-ER15\",'+
            '                        \"eventDateTime\": \"2020-09-28T17:20:12+00:00\",'+
            '                        \"message\": \"Picked up from Sender\",'+
            '                        \"location\": \"DANDENONG SOUTH VIC, 3175\",'+
            '                        \"workCentreId\": \"352233\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273001000934506\",'+
            '                        \"code\": \"ADMIN-ER39\",'+
            '                        \"eventDateTime\": \"2020-09-28T13:51:32+00:00\",'+
            '                        \"message\": \"Shipping information received by Australia Post\",'+
            '                        \"location\": null,'+
            '                        \"workCentreId\": \"346837\"'+
            '                    }'+
            '                ]'+
            '            }'+
            '        },'+
            '        {'+
            '            \"href\": \"/consignment/v2/articles/3BE501273002000934503\",'+
            '            \"id\": \"3BE501273002000934503\",'+
            '            \"code\": \"3BE501273002000934503\",'+
            '            \"consignmentId\": \"UhcyXLoRPb9dIVzjybV65huQecJCLpIxXRom9cFCl7-WF80Negg=\",'+
            '            \"consignmentCode\": \"3BE5012730\",'+
            '            \"fullBarcode\": \"0199312650999998913BE501273002000934503|4203057|9237133425|8008200928134027\",'+
            '            \"shortBarcode\": \"0199312650999998913BE501273002000934503\",'+
            '            \"isRegisteredByAP\": true,'+
            '            \"isReceivedByAP\": false,'+
            '            \"lastModifiedOn\": \"2020-10-04T23:40:33+00:00\",'+
            '            \"dispatchedOn\": \"2020-09-28T05:34:01+00:00\",'+
            '            \"etag\": \"6c0edd304214fe7f096a05b1c3abae5c\",'+
            '            \"expectedDelivery\": {'+
            '                \"eventDateTime\": \"2020-10-01T00:00:00+00:00\",'+
            '                \"eventDateTimeChanged\": false,'+
            '                \"between\": {'+
            '                    \"from\": \"2020-09-30T00:00:00+00:00\",'+
            '                    \"to\": \"2020-10-02T00:00:00+00:00\"'+
            '                }'+
            '            },'+
            '            \"service\": {'+
            '                \"productId\": null,'+
            '                \"productType\": \"Parcel Post\",'+
            '                \"subProductId\": null,'+
            '                \"subProductType\": null'+
            '            },'+
            '            \"milestone\": {'+
            '                \"eventDateTime\": \"2020-09-29T07:06:50+00:00\",'+
            '                \"name\": \"It\'s on its way\",'+
            '                \"description\": null,'+
            '                \"progressPercentage\": 45'+
            '            },'+
            '            \"destinationAddress\": {'+
            '                \"line1\": \"13 IVORY WAY\",'+
            '                \"line2\": null,'+
            '                \"line3\": null,'+
            '                \"suburb\": \"BRUNSWICK EAST\",'+
            '                \"state\": \"VIC\",'+
            '                \"postcode\": \"3057\",'+
            '                \"countryCode\": \"AU\",'+
            '                \"deliveryPoint\": {'+
            '                    \"href\": \"/locations/v2/points/deliverypoints/37133425\",'+
            '                    \"id\": \"37133425\"'+
            '                }'+
            '            },'+
            '            \"deliveryInstructions\": {'+
            '                \"signatureOnDelivery\": {'+
            '                    \"required\": true,'+
            '                    \"instruction\": {'+
            '                        \"code\": \"SIG_ALWAYS_REQUIRED\"'+
            '                    }'+
            '                },'+
            '                \"redirect\": {'+
            '                    \"status\": \"RD_STATUS_REQUEST_ENABLED\",'+
            '                    \"redirectChange\": {'+
            '                        \"allowed\": true,'+
            '                        \"reasonCode\": null'+
            '                    }'+
            '                },'+
            '                \"safeDrop\": {'+
            '                    \"status\": \"SD_STATUS_INELIGIBLE\",'+
            '                    \"location\": null,'+
            '                    \"locationChange\": {'+
            '                        \"allowed\": false,'+
            '                        \"reasonCode\": \"SD_ELIG_DISALLOWED_SIG_REQUIRED\"'+
            '                    }'+
            '                }'+
            '            },'+
            '            \"deliverySummary\": null,'+
            '            \"returnInstructions\": {'+
            '                \"returnToSender\": false'+
            '            },'+
            '            \"consignmentCount\": 1,'+
            '            \"consignments\": {'+
            '                \"items\": ['+
            '                    {'+
            '                        \"href\": \"/consignment/v2/consignments/@UhcyXLoRPb9dIVzjybV65huQecJCLpIxXRom9cFCl7-WF80Negg=\",'+
            '                        \"id\": \"UhcyXLoRPb9dIVzjybV65huQecJCLpIxXRom9cFCl7-WF80Negg=\",'+
            '                        \"code\": \"3BE5012730\",'+
            '                        \"primary\": true'+
            '                    }'+
            '                ]'+
            '            },'+
            '            \"foundByTrackingReferences\": ['+
            '                {'+
            '                    \"id\": \"3BE5012730\",'+
            '                    \"type\": \"IDTYPE_CONSIGNMENT_CODE\"'+
            '                }'+
            '            ],'+
            '            \"eventCount\": 4,'+
            '            \"trackingEvents\": {'+
            '                \"href\": \"/consignment/v2/articles/3BE501273002000934503?expand=articles,events\",'+
            '                \"items\": ['+
            '                    {'+
            '                        \"id\": \"3BE501273002000934503\",'+
            '                        \"code\": \"NSS-ER42\",'+
            '                        \"eventDateTime\": \"2020-09-29T07:06:50+00:00\",'+
            '                        \"message\": \"Item processed at facility\",'+
            '                        \"location\": \"MELBOURNE VIC\",'+
            '                        \"workCentreId\": \"350350\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273002000934503\",'+
            '                        \"code\": \"AFC-ER15\",'+
            '                        \"eventDateTime\": \"2020-09-28T17:20:12+00:00\",'+
            '                        \"message\": \"Picked up from Sender\",'+
            '                        \"location\": \"DANDENONG SOUTH VIC, 3175\",'+
            '                        \"workCentreId\": \"352233\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273002000934503\",'+
            '                        \"code\": \"ADMIN-ER39\",'+
            '                        \"eventDateTime\": \"2020-09-28T13:51:32+00:00\",'+
            '                        \"message\": \"Shipping information received by Australia Post\",'+
            '                        \"location\": null,'+
            '                        \"workCentreId\": \"346837\"'+
            '                    }'+
            '                ]'+
            '            }'+
            '        },'+
            '        {'+
            '            \"href\": \"/consignment/v2/articles/3BE501273003000934500\",'+
            '            \"id\": \"3BE501273003000934500\",'+
            '            \"code\": \"3BE501273003000934500\",'+
            '            \"consignmentId\": \"UhcyXLoRPb9dIVzjybV65huQecJCLpIxXRom9cFCl7-WF80Negg=\",'+
            '            \"consignmentCode\": \"3BE5012730\",'+
            '            \"fullBarcode\": \"0199312650999998913BE501273003000934500|4203057|9237133425|8008200928134027\",'+
            '            \"shortBarcode\": \"0199312650999998913BE501273003000934500\",'+
            '            \"isRegisteredByAP\": true,'+
            '            \"isReceivedByAP\": false,'+
            '            \"lastModifiedOn\": \"2020-10-04T23:40:33+00:00\",'+
            '            \"dispatchedOn\": \"2020-09-28T05:34:01+00:00\",'+
            '            \"etag\": \"6c0edd304214fe7f096a05b1c3abae5c\",'+
            '            \"expectedDelivery\": {'+
            '                \"eventDateTime\": \"2020-10-01T00:00:00+00:00\",'+
            '                \"eventDateTimeChanged\": false,'+
            '                \"between\": {'+
            '                    \"from\": \"2020-09-30T00:00:00+00:00\",'+
            '                    \"to\": \"2020-10-02T00:00:00+00:00\"'+
            '                }'+
            '            },'+
            '            \"service\": {'+
            '                \"productId\": null,'+
            '                \"productType\": \"Parcel Post\",'+
            '                \"subProductId\": null,'+
            '                \"subProductType\": null'+
            '            },'+
            '            \"milestone\": {'+
            '                \"eventDateTime\": \"2020-09-29T09:52:25+00:00\",'+
            '                \"name\": \"Delivered\",'+
            '                \"description\": null,'+
            '                \"progressPercentage\": 100'+
            '            },'+
            '            \"destinationAddress\": {'+
            '                \"line1\": \"13 IVORY WAY\",'+
            '                \"line2\": null,'+
            '                \"line3\": null,'+
            '                \"suburb\": \"BRUNSWICK EAST\",'+
            '                \"state\": \"VIC\",'+
            '                \"postcode\": \"3057\",'+
            '                \"countryCode\": \"AU\",'+
            '                \"deliveryPoint\": {'+
            '                    \"href\": \"/locations/v2/points/deliverypoints/37133425\",'+
            '                    \"id\": \"37133425\"'+
            '                }'+
            '            },'+
            '            \"deliveryInstructions\": {'+
            '                \"signatureOnDelivery\": {'+
            '                    \"required\": true,'+
            '                    \"instruction\": {'+
            '                        \"code\": \"SIG_ALWAYS_REQUIRED\"'+
            '                    }'+
            '                },'+
            '                \"redirect\": {'+
            '                    \"status\": \"RD_STATUS_REQUEST_DISABLED\",'+
            '                    \"redirectChange\": {'+
            '                        \"allowed\": false,'+
            '                        \"reasonCode\": \"RD_ELIG_TOO_LATE\"'+
            '                    }'+
            '                },'+
            '                \"safeDrop\": {'+
            '                    \"status\": \"SD_STATUS_INELIGIBLE\",'+
            '                    \"location\": null,'+
            '                    \"locationChange\": {'+
            '                        \"allowed\": false,'+
            '                        \"reasonCode\": \"SD_ELIG_DISALLOWED_SIG_REQUIRED\"'+
            '                    }'+
            '                }'+
            '            },'+
            '            \"deliverySummary\": {'+
            '                \"signedFor\": true,'+
            '                \"redirect\": null,'+
            '                \"safeDrop\": null'+
            '            },'+
            '            \"returnInstructions\": {'+
            '                \"returnToSender\": false'+
            '            },'+
            '            \"consignmentCount\": 1,'+
            '            \"consignments\": {'+
            '                \"items\": ['+
            '                    {'+
            '                        \"href\": \"/consignment/v2/consignments/@UhcyXLoRPb9dIVzjybV65huQecJCLpIxXRom9cFCl7-WF80Negg=\",'+
            '                        \"id\": \"UhcyXLoRPb9dIVzjybV65huQecJCLpIxXRom9cFCl7-WF80Negg=\",'+
            '                        \"code\": \"3BE5012730\",'+
            '                        \"primary\": true'+
            '                    }'+
            '                ]'+
            '            },'+
            '            \"foundByTrackingReferences\": ['+
            '                {'+
            '                    \"id\": \"3BE5012730\",'+
            '                    \"type\": \"IDTYPE_CONSIGNMENT_CODE\"'+
            '                }'+
            '            ],'+
            '            \"eventCount\": 7,'+
            '            \"trackingEvents\": {'+
            '                \"href\": \"/consignment/v2/articles/3BE501273003000934500?expand=articles,events\",'+
            '                \"items\": ['+
            '                    {'+
            '                        \"id\": \"3BE501273003000934500\",'+
            '                        \"code\": \"DD-ER13\",'+
            '                        \"eventDateTime\": \"2020-09-29T09:52:25+00:00\",'+
            '                        \"message\": \"Delivered\",'+
            '                        \"location\": \"BRUNSWICK EAST VIC, 3057\",'+
            '                        \"workCentreId\": \"351476\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273003000934500\",'+
            '                        \"code\": \"AFP-ER13\",'+
            '                        \"eventDateTime\": \"2020-09-29T07:55:53+00:00\",'+
            '                        \"message\": \"Onboard for delivery\",'+
            '                        \"location\": \"CRAIGIEBURN VIC, 3064\",'+
            '                        \"workCentreId\": \"351476\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273003000934500\",'+
            '                        \"code\": \"NSS-ER42\",'+
            '                        \"eventDateTime\": \"2020-09-29T05:43:26+00:00\",'+
            '                        \"message\": \"Item processed at facility\",'+
            '                        \"location\": \"SOMERTON VIC, 3062\",'+
            '                        \"workCentreId\": \"307969\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273003000934500\",'+
            '                        \"code\": \"NT-ER37\",'+
            '                        \"eventDateTime\": \"2020-09-28T21:28:00+00:00\",'+
            '                        \"message\": \"In transit\",'+
            '                        \"location\": \"DANDENONG SOUTH VIC, 3175\",'+
            '                        \"workCentreId\": \"353316\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273003000934500\",'+
            '                        \"code\": \"AFC-ER15\",'+
            '                        \"eventDateTime\": \"2020-09-28T17:20:12+00:00\",'+
            '                        \"message\": \"Picked up from Sender\",'+
            '                        \"location\": \"DANDENONG SOUTH VIC, 3175\",'+
            '                        \"workCentreId\": \"352233\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273003000934500\",'+
            '                        \"code\": \"ADMIN-ER39\",'+
            '                        \"eventDateTime\": \"2020-09-28T13:51:32+00:00\",'+
            '                        \"message\": \"Shipping information received by Australia Post\",'+
            '                        \"location\": null,'+
            '                        \"workCentreId\": \"346837\"'+
            '                    }'+
            '                ]'+
            '            }'+
            '        },'+
            '        {'+
            '            \"href\": \"/consignment/v2/articles/3BE501273004000934507\",'+
            '            \"id\": \"3BE501273004000934507\",'+
            '            \"code\": \"3BE501273004000934507\",'+
            '            \"consignmentId\": \"UhcyXLoRPb9dIVzjybV65huQecJCLpIxXRom9cFCl7-WF80Negg=\",'+
            '            \"consignmentCode\": \"3BE5012730\",'+
            '            \"fullBarcode\": \"0199312650999998913BE501273004000934507|4203057|9237133425|8008200928134027\",'+
            '            \"shortBarcode\": \"0199312650999998913BE501273004000934507\",'+
            '            \"isRegisteredByAP\": true,'+
            '            \"isReceivedByAP\": false,'+
            '            \"lastModifiedOn\": \"2020-10-04T23:40:34+00:00\",'+
            '            \"dispatchedOn\": \"2020-09-28T05:34:01+00:00\",'+
            '            \"etag\": \"1f14f7fd168fa43e68f990423a231eab\",'+
            '            \"expectedDelivery\": {'+
            '                \"eventDateTime\": \"2020-10-01T00:00:00+00:00\",'+
            '                \"eventDateTimeChanged\": false,'+
            '                \"between\": {'+
            '                    \"from\": \"2020-09-30T00:00:00+00:00\",'+
            '                    \"to\": \"2020-10-02T00:00:00+00:00\"'+
            '                }'+
            '            },'+
            '            \"service\": {'+
            '                \"productId\": null,'+
            '                \"productType\": \"Parcel Post\",'+
            '                \"subProductId\": null,'+
            '                \"subProductType\": null'+
            '            },'+
            '            \"milestone\": {'+
            '                \"eventDateTime\": \"2020-09-29T16:09:55+00:00\",'+
            '                \"name\": \"Delivered\",'+
            '                \"description\": null,'+
            '                \"progressPercentage\": 100'+
            '            },'+
            '            \"destinationAddress\": {'+
            '                \"line1\": \"13 IVORY WAY\",'+
            '                \"line2\": null,'+
            '                \"line3\": null,'+
            '                \"suburb\": \"BRUNSWICK EAST\",'+
            '                \"state\": \"VIC\",'+
            '                \"postcode\": \"3057\",'+
            '                \"countryCode\": \"AU\",'+
            '                \"deliveryPoint\": {'+
            '                    \"href\": \"/locations/v2/points/deliverypoints/37133425\",'+
            '                    \"id\": \"37133425\"'+
            '                }'+
            '            },'+
            '            \"deliveryInstructions\": {'+
            '                \"signatureOnDelivery\": {'+
            '                    \"required\": true,'+
            '                    \"instruction\": {'+
            '                        \"code\": \"SIG_ALWAYS_REQUIRED\"'+
            '                    }'+
            '                },'+
            '                \"redirect\": {'+
            '                    \"status\": \"RD_STATUS_REQUEST_DISABLED\",'+
            '                    \"redirectChange\": {'+
            '                        \"allowed\": false,'+
            '                        \"reasonCode\": \"RD_ELIG_TOO_LATE\"'+
            '                    }'+
            '                },'+
            '                \"safeDrop\": {'+
            '                    \"status\": \"SD_STATUS_INELIGIBLE\",'+
            '                    \"location\": null,'+
            '                    \"locationChange\": {'+
            '                        \"allowed\": false,'+
            '                        \"reasonCode\": \"SD_ELIG_DISALLOWED_SIG_REQUIRED\"'+
            '                    }'+
            '                }'+
            '            },'+
            '            \"deliverySummary\": {'+
            '                \"signedFor\": true,'+
            '                \"redirect\": null,'+
            '                \"safeDrop\": null'+
            '            },'+
            '            \"returnInstructions\": {'+
            '                \"returnToSender\": false'+
            '            },'+
            '            \"consignmentCount\": 1,'+
            '            \"consignments\": {'+
            '                \"items\": ['+
            '                    {'+
            '                        \"href\": \"/consignment/v2/consignments/@UhcyXLoRPb9dIVzjybV65huQecJCLpIxXRom9cFCl7-WF80Negg=\",'+
            '                        \"id\": \"UhcyXLoRPb9dIVzjybV65huQecJCLpIxXRom9cFCl7-WF80Negg=\",'+
            '                        \"code\": \"3BE5012730\",'+
            '                        \"primary\": true'+
            '                    }'+
            '                ]'+
            '            },'+
            '            \"foundByTrackingReferences\": ['+
            '                {'+
            '                    \"id\": \"3BE5012730\",'+
            '                    \"type\": \"IDTYPE_CONSIGNMENT_CODE\"'+
            '                }'+
            '            ],'+
            '            \"eventCount\": 7,'+
            '            \"trackingEvents\": {'+
            '                \"href\": \"/consignment/v2/articles/3BE501273004000934507?expand=articles,events\",'+
            '                \"items\": ['+
            '                    {'+
            '                        \"id\": \"3BE501273004000934507\",'+
            '                        \"code\": \"DD-ER13\",'+
            '                        \"eventDateTime\": \"2020-09-29T16:09:55+00:00\",'+
            '                        \"message\": \"Delivered\",'+
            '                        \"location\": \"BRUNSWICK EAST VIC, 3057\",'+
            '                        \"workCentreId\": \"351476\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273004000934507\",'+
            '                        \"code\": \"AFP-ER13\",'+
            '                        \"eventDateTime\": \"2020-09-29T16:00:32+00:00\",'+
            '                        \"message\": \"Onboard for delivery\",'+
            '                        \"location\": \"BRUNSWICK EAST VIC, 3057\",'+
            '                        \"workCentreId\": \"351476\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273004000934507\",'+
            '                        \"code\": \"NSS-ER42\",'+
            '                        \"eventDateTime\": \"2020-09-29T06:01:34+00:00\",'+
            '                        \"message\": \"Item processed at facility\",'+
            '                        \"location\": \"SOMERTON VIC, 3062\",'+
            '                        \"workCentreId\": \"307969\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273004000934507\",'+
            '                        \"code\": \"NT-ER37\",'+
            '                        \"eventDateTime\": \"2020-09-28T21:27:57+00:00\",'+
            '                        \"message\": \"In transit\",'+
            '                        \"location\": \"DANDENONG SOUTH VIC, 3175\",'+
            '                        \"workCentreId\": \"353316\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273004000934507\",'+
            '                        \"code\": \"AFC-ER15\",'+
            '                        \"eventDateTime\": \"2020-09-28T17:20:12+00:00\",'+
            '                        \"message\": \"Picked up from Sender\",'+
            '                        \"location\": \"DANDENONG SOUTH VIC, 3175\",'+
            '                        \"workCentreId\": \"352233\"'+
            '                    },'+
            '                    {'+
            '                        \"id\": \"3BE501273004000934507\",'+
            '                        \"code\": \"ADMIN-ER39\",'+
            '                        \"eventDateTime\": \"2020-09-28T13:51:32+00:00\",'+
            '                        \"message\": \"Shipping information received by Australia Post\",'+
            '                        \"location\": null,'+
            '                        \"workCentreId\": \"346837\"'+
            '                    }'+
            '                ]'+
            '            }'+
            '        }'+
            '    ],'+
            '    \"errors\": []'+
            '}';
        ChasOneTrackResponse objChasOneTrackResponse = new ChasOneTrackResponse(System.JSON.createParser(json));
        System.assert(objChasOneTrackResponse != null);
        
        //--Error
        json = '{\"responseCode\": 404}';
        ChasOneTrackResponse.Errors error = new ChasOneTrackResponse.Errors(System.JSON.createParser(json));
        System.assert(error != null);
        System.assert(error.responseCode != null);
        
        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ChasOneTrackResponse objJSON2Apex = new ChasOneTrackResponse(System.JSON.createParser(json));
        System.assert(objJSON2Apex != null);
		System.assert(objJSON2Apex.articles == null);
		System.assert(objJSON2Apex.errors == null);
        
        //--TrackingEvents
        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ChasOneTrackResponse.TrackingEvents objTrackingEvents = new ChasOneTrackResponse.TrackingEvents(System.JSON.createParser(json));
        System.assert(objTrackingEvents != null);
        System.assert(objTrackingEvents.href == null);
        System.assert(objTrackingEvents.items == null);
        
        //--Events
        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ChasOneTrackResponse.Items events = new ChasOneTrackResponse.Items(System.JSON.createParser(json));
        System.assert(events != null);
        System.assert(events.id == null);
        System.assert(events.code == null);
        System.assert(events.eventDateTime == null);
        System.assert(events.message == null);
        System.assert(events.location == null);
        System.assert(events.workCentreId == null);
        
        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ChasOneTrackResponse.DeliveryInstructions objDeliveryInstructionsInArticle = new ChasOneTrackResponse.DeliveryInstructions(System.JSON.createParser(json));
        System.assert(objDeliveryInstructionsInArticle != null);
        System.assert(objDeliveryInstructionsInArticle.redirect == null);
        System.assert(objDeliveryInstructionsInArticle.safeDrop == null);
        
        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ChasOneTrackResponse.DeliverySummary objDeliverySummaryInArticle = new ChasOneTrackResponse.DeliverySummary(System.JSON.createParser(json));
        System.assert(objDeliverySummaryInArticle != null);
        System.assert(objDeliverySummaryInArticle.signedFor == null);
        System.assert(objDeliverySummaryInArticle.safeDrop == null);
        
        //--Safedrop - Delivery Summary
        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ChasOneTrackResponse.SafeDropInArticle objSafeDrop = new ChasOneTrackResponse.SafeDropInArticle(System.JSON.createParser(json));
        System.assert(objSafeDrop != null);
        System.assert(objSafeDrop.eventDateTime == null);
        System.assert(objSafeDrop.image == null);
        
        //--Safedrop - Delivery Instruction
        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ChasOneTrackResponse.SafeDrop objSafeDropDeliveryInstructions = new ChasOneTrackResponse.SafeDrop(System.JSON.createParser(json));
        System.assert(objSafeDropDeliveryInstructions != null);
        System.assert(objSafeDropDeliveryInstructions.status == null);
        //System.assert(objSafeDropDeliveryInstructions.location == null);
        System.assert(objSafeDropDeliveryInstructions.locationChange == null);
        
        //--Image
        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ChasOneTrackResponse.Image objImage = new ChasOneTrackResponse.Image(System.JSON.createParser(json));
        System.assert(objImage != null);
        System.assert(objImage.href == null);
        System.assert(objImage.id == null);
        
        //--Milestone
        json = '{\"eventDateTime\": \"Some Value\",\"name\": \"Some Value\",\"description\": \"Some Value\",\"progressPercentage\": 100}';
        ChasOneTrackResponse.Milestone objMilestone = new ChasOneTrackResponse.Milestone(System.JSON.createParser(json));
        System.assert(objMilestone != null);
        System.assert(objMilestone.eventDateTime != null);
        System.assert(objMilestone.name != null);
        System.assert(objMilestone.description != null);
        System.assert(objMilestone.progressPercentage != null);
        
        //--Articles
        json = '{\"href\": \"Some Value\",\"item\": \"Some Value\"}';
        ChasOneTrackResponse.Articles objArticles = new ChasOneTrackResponse.Articles(System.JSON.createParser(json));
        System.assert(objArticles != null);
        System.assert(objArticles.href != null);
        System.assert(objArticles.id == null);
		System.assert(objArticles.code == null);
		System.assert(objArticles.consignmentId == null);
		System.assert(objArticles.consignmentCode == null);
		System.assert(objArticles.fullBarcode == null);
		System.assert(objArticles.shortBarcode == null);
		System.assert(objArticles.isRegisteredByAP == null);
		System.assert(objArticles.isReceivedByAP == null);
		System.assert(objArticles.lastModifiedOn == null);
		System.assert(objArticles.dispatchedOn == null);
		System.assert(objArticles.etag == null);
		System.assert(objArticles.expectedDelivery == null);
		System.assert(objArticles.service == null);
		System.assert(objArticles.milestone == null);
		System.assert(objArticles.destinationAddress == null);
		System.assert(objArticles.deliveryInstructions == null);
		System.assert(objArticles.deliverySummary == null);
		System.assert(objArticles.returnInstructions == null);
		System.assert(objArticles.consignmentCount == null);
		System.assert(objArticles.eventCount == null);
		System.assert(objArticles.trackingEvents == null);
        
        //--Service
        json = '{\"productType\": \"Some Value\",\"subProductId\": \"60\"}';
        ChasOneTrackResponse.Service objService = new ChasOneTrackResponse.Service(System.JSON.createParser(json));
        System.assert(objService != null);
        System.assert(objService.productType != null);
        System.assert(objService.subProductId != null);
        
        
        //--Destination address
        json = '{ \"line1\": \"Some Value\",\"line2\": \"Some Value\",\"line3\": \"Some Value\",\"suburb\": \"Some Value\",\"state\": \"Some Value\",\"postcode\": \"Some Value\",\"countrycode\": \"Some Value\", \"deliveryPoint\": {\"href\": \"Some Value\",\"id\": \"Some Value\"}}';
        ChasOneTrackResponse.DestinationAddress objDestinationAddress = new ChasOneTrackResponse.DestinationAddress(System.JSON.createParser(json));
        System.assert(objDestinationAddress != null);
        System.assert(objDestinationAddress.line1 != null);
        System.assert(objDestinationAddress.line2 != null);
        System.assert(objDestinationAddress.line3 != null);
        System.assert(objDestinationAddress.suburb != null);
        System.assert(objDestinationAddress.state != null);
        System.assert(objDestinationAddress.postcode != null);
        System.assert(objDestinationAddress.countryCode != null);
        System.assert(objDestinationAddress.deliveryPoint != null);
        
        json = '{\"returnToSender\": false}';
        ChasOneTrackResponse.ReturnInstructions objReturnInstructions = new ChasOneTrackResponse.ReturnInstructions(System.JSON.createParser(json));
        System.assert(objReturnInstructions != null);
        System.assert(objReturnInstructions.returnToSender == false);
        
        
        json = '{\"href\": \"Some Value\",\"id\": \"Some Value\"}';
        ChasOneTrackResponse.DeliveryPoint objDeliveryPoint = new ChasOneTrackResponse.DeliveryPoint(System.JSON.createParser(json));
        System.assert(objDeliveryPoint != null);
        System.assert(objDeliveryPoint.href != null);
        System.assert(objDeliveryPoint.id != null);
        
        //--Redirectchange
        json = '{\"allowed\": false,\"reasonCode\": \"Some Value\"}';
        ChasOneTrackResponse.RedirectChange objRedirectChange = new ChasOneTrackResponse.RedirectChange(System.JSON.createParser(json));
        System.assert(objRedirectChange != null);
        System.assert(objRedirectChange.allowed == false);
        System.assert(objRedirectChange.reasonCode != null);
        
        //--Redirect
        json = '{\"status\": \"Some Value\",\"redirectChange\": {\"allowed\": false,\"reasonCode\": \"Some Value\"}}';
        ChasOneTrackResponse.Redirect objRedirect = new ChasOneTrackResponse.Redirect(System.JSON.createParser(json));
        System.assert(objRedirect != null);
        System.assert(objRedirect.status != null);
        System.assert(objRedirect.redirectChange != null);
        
        
    }
    
}