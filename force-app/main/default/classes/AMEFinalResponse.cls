/**
 * Created by MandavilD on 03/10/2019.
 * REQ2529715 - Naveen Rajanna - 17/06/2021 - concatenate address lines 2 and 3
 * Use the parse method of the AMEFinalResponse class to deserialise so the additional logic of concat of addresslines are also handeled
 * 2021-09-28 - Ranjeewa Silva - Expose additional address fields returned by AME.
 */

public with sharing class AMEFinalResponse {

    // geo data for the centroid
    public static final String GEO_FEATURE_TYPE_CENTROID = 'CENTROID';

    // geo data for street frontage
    public static final String GEO_FEATURE_TYPE_GNAF_FRONTAGE = 'GNAF_FRONTAGE';

    public class Address {
        public String singleLine;
        public SemiStructured semiStructured;
        public List<GeoDataList> geoDataList;
        public String dpid;
        public DeliveryData deliveryData;

        /**
		 * Returns address geo data for the feature type passed in. Returns null if geo data for that feature type
		 * is not available for this address.
		 *
		 * @param featureType feature type (e.g. CENTROID, GNAF_FRONTAGE)
		 *
		 * @return geo data, returns null if not available.
		 */
        public GeoDataList getGeoData(String featureType) {
            if (geoDataList != null) {
                for (GeoDataList geoData: geoDataList) {
                    if (geoData.featureType == featureType) {
                        return geoData;
                    }
                }
            }
            return null;
        }
    }

    public String id;
    public List<Result> results;

    public class GeoDataList {
        public String featureType;
        public Double latitude;
        public Double longitude;
    }

    public class Result {
        public String id;
        public List<Address> addresses;
    }

    public class SemiStructured {
        public List<String> addressLines;
        public String locality;
        public String state;
        public String postcode;
        public String countryName;
        public String countryCode;
    }

    public class DeliveryData {
        public String sideOfStreetCode;
    }

    public static AMEFinalResponse parse(String json) {
        AMEFinalResponse ameResponse = (AMEFinalResponse) System.JSON.deserialize(json, AMEFinalResponse.class);
        concatenateAddressLines(ameResponse); //REQ2529715
        return ameResponse;
    }

    private static void concatenateAddressLines(AMEFinalResponse ameResponse) {
        if(ameResponse != null && !ameResponse.results.isEmpty()) {
            for (AMEFinalResponse.Address address : ameResponse.results[0].addresses) {
                if(address.semiStructured != null
                        && address.semiStructured.addressLines != null
                        && address.semiStructured.addressLines.size() >= 3
                        && String.isNotBlank(address.semiStructured.addressLines[2])) {
                    // concatenate address lines 2 and 3
                    address.semiStructured.addressLines[1] = (address.semiStructured.addressLines[1] != null ? address.semiStructured.addressLines[1] + ' ' : '') + address.semiStructured.addressLines[2];
                    // blank out the 3rd address line
                    address.semiStructured.addressLines[2] = '';
                }
            }
        }
    }
}