/**
 * @description       : This is the wrapper class for Google Maps Place APIs Response
 * @author            : ankur.gandhi@auspost.com.au
 * @last modified on  : 03-15-2021
 * @last modified by  : ankur.gandhi@auspost.com.au
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   03-15-2021   ankur.gandhi@auspost.com.au   Initial Version
**/
public without sharing class PlaceAutocompleteResponse {
    public class Matched_substrings {
        public Integer length;
        public Integer offset;
    }

    public String status;
    public List<Predictions> predictions;

    public class Predictions {
        public String description;
        public String id;
        public List<Matched_substrings> matched_substrings;
        public String place_id;
        public String reference;
        public List<Terms> terms;
        public List<String> types;
    }

    public class Terms {
        public Integer offset;
        public String value;
    }

    public static PlaceAutocompleteResponse parse(String json) {
         return (PlaceAutocompleteResponse) System.JSON.deserialize(json, PlaceAutocompleteResponse.class);
    }
}