/**
 * Created by MandavilD on 03/10/2019.
 * --------------------------------------- History --------------------------------------------------
03.10.2019    Dheeraj Mandavilli    Created
07.08.2020    Disha Kariya          Added GeoDataList for geo location.
 */

public with sharing class AMEInitialResponse {
        public class Address {
            public String singleLine;
            public Double score;
			public Integer dpid;
			public String confidence;
            public List<GeoDataLists> geoDataList;
        }
        public class GeoDataLists {
            public String featureType;
            public String confidence;
            public Double latitude;
            public Double longitude;
        }
        public String id;
        public List<Result> results;
        public class Result {
            public String id;
            public List<Address> addresses;
            public List<String> references;
        }

        public static AMEInitialResponse parse(String json) {
            return (AMEInitialResponse) System.JSON.deserialize(json, AMEInitialResponse.class);
        }

}