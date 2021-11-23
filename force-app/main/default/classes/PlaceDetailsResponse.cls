/**
 * @description       : This class is wrapper class for the Google Maps Place API
 * @author            : ankur.gandhi@auspost.com.au
 * @group             : BCA
 * @last modified on  : 03-16-2021
 * @last modified by  : ankur.gandhi@auspost.com.au
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   03-16-2021   ankur.gandhi@auspost.com.au   Initial Version
**/
public with sharing class PlaceDetailsResponse {
    public class Address_components {
		public String long_name;
		public String short_name;
		public List<String> types;
	}

	public class Geometry {
		public Location location;
		public Viewport viewport;
	}

	public class Reviews {
		public String author_name;
		public String author_url;
		public String language;
		public String profile_photo_url;
		public Integer rating;
		public String relative_time_description;
		public String text;
		//public Integer time;
	}

	public List<Html_attributions> html_attributions;
	public Result result;
	public String status;

	public class Viewport {
		public Location northeast;
		public Location southwest;
	}

	public class Html_attributions {
	}

	public class Location {
		public Double lat;
		public Double lng;
	}

	public class Result {
		public List<Address_components> address_components;
		public String adr_address;
		public String formatted_address;
		public String formatted_phone_number;
		public Geometry geometry;
		public String icon;
		public String id;
		public String international_phone_number;
		public String name;
		public String place_id;
		public Double rating;
		public String reference;
		public List<Reviews> reviews;
		public List<String> types;
		public String url;
		public Integer utc_offset;
		public String vicinity;
		public String website;
	}

	
	public static PlaceDetailsResponse parse(String json) {
		return (PlaceDetailsResponse) System.JSON.deserialize(json, PlaceDetailsResponse.class);
	}
}