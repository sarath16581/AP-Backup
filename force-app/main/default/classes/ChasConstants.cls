/**
* @description Chas Constants
* @author
* @date
* @group Communities
* @tags Constants, Help and Support, H&S, Help & Support
* @domain Help and Support
* @changelog
* 11-Oct-2018 - Nanda Kothamasu - REQ1567740 Enquiry Sub Type constant MAIL_NOT_BEING_REDIRECTED_OR_HELD is updated from "Mail not being redirected/held" to "Redirection Failure"
* 2019-08-30 hasantha.liyanage@auspost.com.au Modified : added EVENT_STATUS_* , TRACK_STAT_* and ENQ_SUB_TYPE_*
* 2020-04-24 - Nathan Franklin - Added new constants
* 2020-08-28 hara.sahoo@auspost.com.au Change made for roll out of Safe Drop feature on Missing Items form - Added the static variable SAFE_DROP_REDIRECT_ELIG_CODES, SAFE_DROP_REDIRECT_ELIG_CODES 
* 2020-09-09 hara.sahoo@auspost.com.au Change made for roll out of Transfer to another PO : Added the static variable for TRANSFER_TO_PO_PROD_SUBTYPE_EXCLUSIONS 
* 2020-09-28 hara.sahoo@auspost.com.au Change made for roll out of Transfer to another PO : Added 'NT-ER80' to EVENT_STATUS_AWAITING_COLLECTION.
* 2020-11-04 hara.sahoo@auspost.com.au Change made for roll out of delivery issue automation : Added DELIVERED_EVENT_TYPES_ALL
* 2021-09-08 Swati.mogadala Added SUB-PROD-ID-202 and 203 to TRANSFER_TO_PO_PROD_SUBTYPE_EXCLUSIONS for the new product subcategory- Premium express 
*/
public class ChasConstants {

    public static final String PERSON_ACCOUNT_RECORD_TYPE_DEVELOPER_NAME = 'PersonAccount';
    public static final String CONSUMER_COMMUNITY_PROFILE_NAME = 'DDC Consumer Community User';

    public static final String  CASE_RECORDTYPE_SSSWDELIVERY ='SSSWDelivery';
    public static final String  CASE_RECORDTYPE_SSSWGENERALDELIVERY='SSSWGeneralEnquiry';
    public static final String  ITEM_TYPE_DOMESTIC = 'Domestic';
    public static final String ITEM_TYPE_INTERNATIONAL = 'International';

    public static final String INVESTIGATION = 'Investigation';
    public static final String  MISSING_ITEM = 'Missing Item';
    public static final String  GENERAL_ENQUIRY = 'General Enquiry';
    public static final String  PARCEL = 'Parcel';
    public static final String  REGULAR_POST =  'Regular Post';
    public static final String  EXPRESS_POST = 'Express Post';
    public static final String  EXPRESS = 'Express';
    public static final String  REGISTERED_POST = 'Registered Post';
    public static final String  LETTER ='Letter';
    public static final String  COURIER ='Courier';
    public static final String  STANDARD ='Standard';
    public static final String  ECONOMY_AIR = 'Economy Air';
    public static final String  ECONOMY_SEA = 'Economy Sea';

    public static final String  RECIPIENT ='Recipient';
    public static final String  ADDRESSE ='Addressee';
    public static final String SENDER = 'Sender';
    public static final String DOMESTIC_PARCELS ='Domestic Parcels';
    public static final String PARCEL_POST ='Parcel Post';
    public static final String DOMESTIC_LETTERS ='Domestic Letters';
    public static final String REGULAR_MAIL = 'Regular Mail';
    public static final String INTERNATIONAL_PARCELS ='International Parcels';
    public static final String INTERNATIONAL_COURIER ='International Courier';
    public static final String INTERNATIONAL_EXPRESS ='International Express';
    public static final String INTERNATIONAL_STANDARD ='International Standard';
    public static final String ECONOMY_AIR_UNDER_2_KG = 'Economy Air under 2kg';
    public static final String ECONOMY_SEA_OVER_2_KG ='Economy Sea over 2kg';
    public static final String INTERNATIONAL_LETTERS ='International Letters';
    public static final String ECONOMY_AIR_UNDER_500_GM = 'Economy Air under 500g';
    public static final String INVESTIGATION_PLUS_DOMESTIC_PARCELS_PLUS_PARCEL_POST ='Investigation|Domestic Parcels|Parcel Post';
    public static final String INVESTIGATION_PLUS_DOMESTIC_PARCELS_PLUS_EXPRESS ='Investigation|Domestic Parcels|Express';
    public static final String INVESTIGATION_PLUS_DOMESTIC_LETTERS_PLUS_REGULAR_EMAIL ='Investigation|Domestic Letters|Regular Mail';
    public static final String INVESTIGATION_PLUS_DOMESTIC_LETTERS_PLUS_EXPRESS_POST = 'Investigation|Domestic Letters|Express Post';
    public static final String INVESTIGATION_PLUS_DOMESTIC_LETTERS_PLUS_REGISTERED_POST ='Investigation|Domestic Letters|Registered Post';
    public static final String INVESTIGATION_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_COURIER ='Investigation|International Parcels|International Courier';
    public static final String INVESTIGATION_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_EXPRESS ='Investigation|International Parcels|International Express';
    public static final String INVESTIGATION_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_STANDARD ='Investigation|International Parcels|International Standard';
    public static final String INVESTIGATION_PLUS_INTERNATIONAL_PARCELS_PLUS_ECONOMY_AIR_UNDER_2_KG = 'Investigation|International Parcels|Economy Air under 2kg';
    public static final String INVESTIGATION_PLUS_INTERNATIONAL_PARCELS_PLUS_ECONOMY_SEA_OVER_2_KG = 'Investigation|International Parcels|Economy Sea over 2kg';
    public static final String INVESTIGATION_PLUS_INTERNATIONAL_LETTERS_PLUS_INTERNATIONAL_COURIER = 'Investigation|International Letters|International Courier';
    public static final String INVESTIGATION_PLUS_INTERNATIONAL_LETTERS_PLUS_INTERNATIONAL_EXPRESS ='Investigation|International Parcels|International Express';
    //public static final String INVESTIGATION_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_STANDARD ='Investigation|International Parcels|International Standard';
    public static final String INVESTIGATION_PLUS_INTERNATIONAL_LETTERS_PLUS_ECONOMY_AIR_UNDER_500_GM ='Investigation|International Letters|Economy Air under 500g';

    public static final String GENERAL_ENQUIRY_PLUS_DOMESTIC_PARCELS_PLUS_PARCEL_POST ='General Enquiry|Domestic Parcels|Parcel Post';
    public static final String GENERAL_ENQUIRY_PLUS_DOMESTIC_PARCELS_PLUS_EXPRESS ='General Enquiry|Domestic Parcels|Express';
    public static final String GENERAL_ENQUIRY_PLUS_DOMESTIC_LETTERS_PLUS_REGULAR_EMAIL ='General Enquiry|Domestic Letters|Regular Mail';
    public static final String GENERAL_ENQUIRY_PLUS_DOMESTIC_LETTERS_PLUS_EXPRESS_POST = 'General Enquiry|Domestic Letters|Express Post';
    public static final String GENERAL_ENQUIRY_PLUS_DOMESTIC_LETTERS_PLUS_REGISTERED_POST ='General Enquiry|Domestic Letters|Registered Post';
    public static final String GENERAL_ENQUIRY_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_COURIER ='General Enquiry|International Parcels|International Courier';
    public static final String GENERAL_ENQUIRY_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_EXPRESS ='General Enquiry|International Parcels|International Express';
    public static final String GENERAL_ENQUIRY_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_STANDARD ='General Enquiry|International Parcels|International Standard';
    public static final String GENERAL_ENQUIRY_PLUS_INTERNATIONAL_PARCELS_PLUS_ECONOMY_AIR_UNDER_2_KG = 'General Enquiry|International Parcels|Economy Air under 2kg';
    public static final String GENERAL_ENQUIRY_PLUS_INTERNATIONAL_PARCELS_PLUS_ECONOMY_SEA_OVER_2_KG = 'General Enquiry|International Parcels|Economy Sea over 2kg';
    public static final String GENERAL_ENQUIRY_PLUS_INTERNATIONAL_LETTERS_PLUS_INTERNATIONAL_COURIER = 'General Enquiry|International Letters|International Courier';
    public static final String GENERAL_ENQUIRY_PLUS_INTERNATIONAL_LETTERS_PLUS_INTERNATIONAL_EXPRESS ='General Enquiry|International Parcels|International Express';
    //public static final String GENERAL_ENQUIRY_PLUS_INTERNATIONAL_PARCELS_PLUS_INTERNATIONAL_STANDARD ='General Enquiry|International Parcels|International Standard';
    public static final String GENERAL_ENQUIRY_PLUS_INTERNATIONAL_LETTERS_PLUS_ECONOMY_AIR_UNDER_500_GM ='General Enquiry|International Letters|Economy Air under 500g';

    public static final String  FEEDBACK ='Feedback';
    public static final String  MAIL_NOT_BEING_REDIRECTED_OR_HELD = 'Redirection Failure'; //Mail not being redirected/held'; REQ1567740
    public static final String MAIL_REDIRECTION='Mail redirection';
    public static final String FEEDBACK_AND_DOMESTIC_PARCELS_AND_MAIL_REDIRECTION='Feedback|Domestic Parcels|Mail redirection';
    public static final String FEEDBACK_AND_DOMESTIC_LETTERS_AND_MAIL_REDIRECTION='Feedback|Domestic Letters|Mail redirection';
    public static final String FEEDBACK_AND_INTERNATIONAL_LETTERS_AND_MAIL_REDIRECTION='Feedback|International Letters|Mail redirection';
    public static final String MAIL_HOLD ='Mail hold';
    public static final String INVESTIGATION_AND_DOMESTIC_PARCELS_MAIL_HOLD='Investigation|Domestic Parcels|Mail hold';
    public static final String INVESTIGATION_AND_DOMESTIC_LETTERS_MAIL_HOLD= 'Investigation|Domestic Letters|Mail hold';

    public static final String EVENT_STATUS_DELIVERED='DD-ER13,DD-ER14,DD-ER37,DOM-0001,DD-ER39';
    public static final String EVENT_STATUS_DELIVERED_SAFE_DROP='DD-ER15,DD-ER38';
    public static final String EVENT_STATUS_ONBOARD_FOR_DELIVERY='AFP-ER13,AFP-ER15,AFP-ER65,DOM-0018,INT-2157,AFP-ER97';
    public static final String EVENT_STATUS_AWAITING_COLLECTION='DD-ER4,NT-ER4,NT-ER80,AFP-ER94,TTP-ER4';
    public static final String EVENT_STATUS_CUSTOMER_ENQUIRY_LODGED='ADMIN-ER44';

    public static final String EVENT_STATUS_ALL = EVENT_STATUS_DELIVERED + EVENT_STATUS_DELIVERED_SAFE_DROP + EVENT_STATUS_ONBOARD_FOR_DELIVERY +EVENT_STATUS_AWAITING_COLLECTION+EVENT_STATUS_CUSTOMER_ENQUIRY_LODGED;

    public static final String TRACK_STAT_NO_EDD_FOUND = 'NO_EDD';
    public static final String TRACK_STAT_DELIVERED = 'DELIVERED';
    public static final String TRACK_STAT_DELIVERING_LATE = 'LATE';
    public static final String TRACK_STAT_DELIVERING_ON_TIME = 'ON_TIME';
    public static final String TRACK_STAT_NOT_SCANNED_YET = 'NO_SCANS';
    public static final String TRACK_STAT_LEFT_IN_A_SAFE_PLACE = 'SAFE_DROP';
    public static final String TRACK_STAT_AWAITING_COLLECTION = 'AWAITING_COLLECTION';
    public static final String TRACK_STAT_COMING_TODAY = 'ONBOARD_FOR_DELIVERY';

    public static final String ENQ_SUB_TYPE_TRACKING = 'Tracking';
    public static final String ENQ_SUB_TYPE_MISSING = 'Missing Item';
    public static final String ENQ_SUB_TYPE_DISPUTED = 'Disputed delivery scan';
    public static final String SAFE_DROP_REDIRECT_ELIG_CODES='RD_STATUS_REQUEST_DISABLED,RD_STATUS_REQUEST_ENABLED';
    public static final String SAFE_DROP_INELIG_SIG_CODES='SD_ELIG_DISALLOWED_SIG_REQUIRED,SD_ELIG_ID_REQUIRED_ON_DELIVERY';
    public static final String TRANSFER_TO_PO_PROD_SUBTYPE_ID_EXCLUSIONS='SUB-PROD-ID-202,SUB-PROD-ID-203,SUB-PROD-ID-1046,SUB-PROD-ID-1047,SUB-PROD-ID-702,SUB-PROD-ID-1043,SUB-PROD-ID-1041,SUB-PROD-ID-1042,SUB-PROD-ID-1048,SUB-PROD-ID-1049,SUB-PROD-ID-1044,SUB-PROD-ID-1045,SUB-PROD-ID-703,SUB-PROD-ID-704,SUB-PROD-ID-705,SUB-PROD-ID-707,SUB-PROD-ID-1055,SUB-PROD-ID-1056,SUB-PROD-ID-1052,SUB-PROD-ID-1050,SUB-PROD-ID-1051,SUB-PROD-ID-1057,SUB-PROD-ID-1053,SUB-PROD-ID-1054,SUB-PROD-ID-1063,SUB-PROD-ID-1064,SUB-PROD-ID-1060,SUB-PROD-ID-1058,SUB-PROD-ID-1059,SUB-PROD-ID-1065,SUB-PROD-ID-1061,SUB-PROD-ID-1062,SUB-PROD-ID-1002,SUB-PROD-ID-1015,SUB-PROD-ID-1014,SUB-PROD-ID-715,SUB-PROD-ID-717,SUB-PROD-ID-1067,SUB-PROD-ID-1068,SUB-PROD-ID-1070,SUB-PROD-ID-1073,SUB-PROD-ID-1072,SUB-PROD-ID-1003,SUB-PROD-ID-1098,SUB-PROD-ID-1017,SUB-PROD-ID-1016,SUB-PROD-ID-1074,SUB-PROD-ID-1102,SUB-PROD-ID-1090,SUB-PROD-ID-1097,SUB-PROD-ID-1018,SUB-PROD-ID-716,SUB-PROD-ID-718,SUB-PROD-ID-712,SUB-PROD-ID-710,SUB-PROD-ID-1079,SUB-PROD-ID-1080,SUB-PROD-ID-1114,SUB-PROD-ID-1109,SUB-PROD-ID-1106,SUB-PROD-ID-719,SUB-PROD-ID-1105,SUB-PROD-ID-1107,SUB-PROD-ID-1108,SUB-PROD-ID-1099,SUB-PROD-ID-1100,SUB-PROD-ID-1019,SUB-PROD-ID-1021,SUB-PROD-ID-1081,SUB-PROD-ID-1022,SUB-PROD-ID-1023,SUB-PROD-ID-1024,SUB-PROD-ID-1020,SUB-PROD-ID-700,SUB-PROD-ID-1025,SUB-PROD-ID-1026,SUB-PROD-ID-1115,SUB-PROD-ID-1027,SUB-PROD-ID-1028,SUB-PROD-ID-1111,SUB-PROD-ID-1112,SUB-PROD-ID-1085,SUB-PROD-ID-709,SUB-PROD-ID-713,SUB-PROD-ID-1094,SUB-PROD-ID-711,SUB-PROD-ID-1101,SUB-PROD-ID-1082,SUB-PROD-ID-1071,SUB-PROD-ID-714,SUB-PROD-ID-1040,SUB-PROD-ID-1012,SUB-PROD-ID-1083,SUB-PROD-ID-1010,SUB-PROD-ID-1029,SUB-PROD-ID-1089,SUB-PROD-ID-1030,SUB-PROD-ID-1113,SUB-PROD-ID-1032,SUB-PROD-ID-1031,SUB-PROD-ID-1033,SUB-PROD-ID-1039,SUB-PROD-ID-1007,SUB-PROD-ID-1034,SUB-PROD-ID-1035,SUB-PROD-ID-1006,SUB-PROD-ID-1036,SUB-PROD-ID-1005,SUB-PROD-ID-706,SUB-PROD-ID-1091,SUB-PROD-ID-1103,SUB-PROD-ID-1001,SUB-PROD-ID-1037,SUB-PROD-ID-1093,SUB-PROD-ID-1008,SUB-PROD-ID-723,SUB-PROD-ID-39,SUB-PROD-ID-37,SUB-PROD-ID-724,SUB-PROD-ID-751,SUB-PROD-ID-750,SUB-PROD-ID-753,SUB-PROD-ID-752,SUB-PROD-ID-38,SUB-PROD-ID-550,SUB-PROD-ID-501';   
    public static final String CHAS_ENQUIRY_TYPE='Missing or lost item,Mail redirection & hold,Delivery issue,Products & services';

    @TestVisible
    public static final Id CONSUMER_COMMUNITY_PROFILE_ID {
        get {
            if(CONSUMER_COMMUNITY_PROFILE_ID == null) {
                CONSUMER_COMMUNITY_PROFILE_ID = ProfilesSelector.newInstance().selectByName(new Set<String>{CONSUMER_COMMUNITY_PROFILE_NAME}).values()[0].Id;
            }
            return CONSUMER_COMMUNITY_PROFILE_ID;
        }
        private set;
    }
    //-- change made for roll out of delivery issues network assignment automation
    @TestVisible
    public static final Map<String,String> DELIVERED_EVENT_TYPES_ALL {
        get {
            Map<String,String> AllEventTypes = new Map<String,String>();
            if(DELIVERED_EVENT_TYPES_ALL ==null)
            {
                for(EventMessageTypeMapping__mdt evType: [Select MasterLabel, Category__c From EventMessageTypeMapping__mdt Where Category__c IN ('AttemptedDelivery','Delivered','AwaitingCollection','Onboard')]){
                    AllEventTypes.put(evType.MasterLabel,evType.Category__c);             
                }  
            }
            return AllEventTypes;
        }
        private set;
    }
    
}