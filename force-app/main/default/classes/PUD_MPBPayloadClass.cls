/**
 * Created by MandavilD on 07/11/2019.
 */

public with sharing class PUD_MPBPayloadClass {

	public Requestor requestor;
	public Booking booking;

	public class Article {
		public String articleId;
		public String length;
		public String width;
		public String height;
		public String weight;
		public String internationalOrDomestic;
		public String destinationPostCode;
	}

	public class Booking {
		public String customerNumber;
		public String billingAccountNumber;
		public String customerId;
		public String locationName;
		public String dateVal;
		public String startTime;
		public String endTime;
		public String contactPhone;
		public String contactName;
		public String contactEmail;
		public String addressLine1;
        public String addressLine2;
        public String addressLine3;
		public String city;
		public String postCode;
		public String state;
		public String bookingComments;
		public String depot;
        public boolean revenueCheck;
        public String articleCount;
		public List<Article> articles;
	}

	public class Requestor {
		public String sourceSystem;
	}

	
	public static PUD_MPBPayloadClass parse(String json) {
		return (PUD_MPBPayloadClass) System.JSON.deserialize(json, PUD_MPBPayloadClass.class);
	}
}