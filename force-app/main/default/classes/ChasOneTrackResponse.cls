/**
*
* Help and support : Parser for the one track response, some of the areas are commented as it could be enabled for future use.
* only the used variables are uncommented, we can enable them by uncommenting them and use them in the future if needed
* History :
* --------------------------------------------------
* 2019-08-29 hasantha.liyanage@auspost.com.au Created
* 2020-07-12 haraprasad.sahoo@auspost.com.au Modified : Changed the wrapper classes to match the new One track service
* 2020-09-14 haraprasad.sahoo@auspost.com.au Modified : Caters to the new ChasTrackStatus wrapper class.
* 2020-10-06 haraprasad.sahoo@auspost.com.au Modified : Caters for consignment search API
* 2020-11-23 hara.sahoo@auspost.com.au Special handling for 403 response code for missing item form
*/

public with sharing class ChasOneTrackResponse {
    
    
    public class SafeDrop {
        public String status {get;set;} 
        //public Object location {get;set;} 
        public RedirectChange locationChange {get;set;} 
        
        public SafeDrop(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'status') {
                            status = parser.getText();
                        } else if (text == 'location') {
                            //location = parser.readValueAs(Object.class);
                        } else if (text == 'locationChange') {
                            locationChange = new RedirectChange(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'SafeDrop consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class SafeDropInArticle {
        public String eventDateTime {get;set;} // in json: on
        public Image image {get;set;} 
        
        public SafeDropInArticle(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'eventDateTime') {
                            eventDateTime = parser.getText();
                        } else if (text == 'image') {
                            image = new Image(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'SafeDrop consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    public class Image {
        public String href{get;set;}    ///ATLImage/d2b85736-816c-4e78-8eb6-b32cf9c00d21
        public String id{get;set;}  //d2b85736-816c-4e78-8eb6-b32cf9c00d21
        public Image(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'href') {
                            href = parser.getText();
                        } else if (text == 'id') {
                            id = parser.getText();
                        }
                        else {
                            System.debug(LoggingLevel.WARN, 'Redirect consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    
    public class DeliveryInstructions {
        //public SignatureOnDelivery signatureOnDelivery {get;set;} 
        public Redirect redirect {get;set;} 
        public SafeDrop safeDrop {get;set;} 
        
        public DeliveryInstructions(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'signatureOnDelivery') {
                            //signatureOnDelivery = new SignatureOnDelivery(parser);
                        } else if (text == 'redirect') {
                            redirect = new Redirect(parser);
                        } else if (text == 'safeDrop') {
                            safeDrop = new SafeDrop(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'DeliveryInstructions consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    
    
    public List<Articles> articles {get;set;} 
    public List<Errors> errors {get;set;} 
    
    public ChasOneTrackResponse(JSONParser parser) {
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                    if (text == 'articles') {
                        articles = arrayOfArticles(parser);
                    } else if (text == 'errors') {
                        errors = arrayOfErrors(parser);
                    } else {
                        System.debug(LoggingLevel.WARN, 'JSON2Apex consuming unrecognized property: '+text);
                        consumeObject(parser);
                    }
                }
            }
        }
    }
    
    public class DeliverySummary {
        public Boolean signedFor {get;set;} 
        //public Object redirect {get;set;} 
        public SafeDropInArticle safeDrop {get;set;} 
        
        public DeliverySummary(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'signedFor') {
                            signedFor = parser.getBooleanValue();
                        } else if (text == 'redirect') {
                            //redirect = parser.readValueAs(Object.class);
                        } else if (text == 'safeDrop') {
                            safeDrop = new SafeDropInArticle(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'DeliverySummary consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class Articles {
        public String href {get;set;} 
        public String id {get;set;} 
        public String code {get;set;} 
        public String consignmentId {get;set;} 
        public String consignmentCode {get;set;} 
        public String fullBarcode {get;set;} 
        public String shortBarcode {get;set;} 
        public Boolean isRegisteredByAP {get;set;} 
        public Boolean isReceivedByAP {get;set;} 
        public String lastModifiedOn {get;set;} 
        public String dispatchedOn {get;set;} 
        public String etag {get;set;} 
        public ExpectedDelivery expectedDelivery {get;set;} 
        public Service service {get;set;} 
        public Milestone milestone {get;set;} 
        public DestinationAddress destinationAddress {get;set;} 
        public DeliveryInstructions deliveryInstructions {get;set;} 
        public DeliverySummary deliverySummary {get;set;} 
        public ReturnInstructions returnInstructions {get;set;} 
        public Integer consignmentCount {get;set;} 
        //public Consignments consignments {get;set;} 
        //public List<FoundByTrackingReferences> foundByTrackingReferences {get;set;} 
        public Integer eventCount {get;set;} 
        public TrackingEvents trackingEvents {get;set;} 
        
        public Articles(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'href') {
                            href = parser.getText();
                        } else if (text == 'id') {
                            id = parser.getText();
                        } else if (text == 'code') {
                            code = parser.getText();
                        } else if (text == 'consignmentId') {
                            consignmentId = parser.getText();
                        } else if (text == 'consignmentCode') {
                            consignmentCode = parser.getText();
                        } else if (text == 'fullBarcode') {
                            fullBarcode = parser.getText();
                        } else if (text == 'shortBarcode') {
                            shortBarcode = parser.getText();
                        } else if (text == 'isRegisteredByAP') {
                            isRegisteredByAP = parser.getBooleanValue();
                        } else if (text == 'isReceivedByAP') {
                            isReceivedByAP = parser.getBooleanValue();
                        } else if (text == 'lastModifiedOn') {
                            lastModifiedOn = parser.getText();
                        } else if (text == 'dispatchedOn') {
                            dispatchedOn = parser.getText();
                        } else if (text == 'etag') {
                            etag = parser.getText();
                        } else if (text == 'expectedDelivery') {
                            expectedDelivery = new ExpectedDelivery(parser);
                        } else if (text == 'service') {
                            service = new Service(parser);
                        } else if (text == 'milestone') {
                            milestone = new Milestone(parser);
                        } else if (text == 'destinationAddress') {
                            destinationAddress = new DestinationAddress(parser);
                        } else if (text == 'deliveryInstructions') {
                            deliveryInstructions = new DeliveryInstructions(parser);
                        } else if (text == 'deliverySummary') {
                            deliverySummary = new DeliverySummary(parser);
                        } else if (text == 'returnInstructions') {
                            returnInstructions = new ReturnInstructions(parser);
                        } else if (text == 'consignmentCount') {
                            consignmentCount = parser.getIntegerValue();
                        } else if (text == 'consignments') {
                            //consignments = new Consignments(parser);
                        } else if (text == 'foundByTrackingReferences') {
                            //foundByTrackingReferences = arrayOfFoundByTrackingReferences(parser);
                        } else if (text == 'eventCount') {
                            eventCount = parser.getIntegerValue();
                        } else if (text == 'trackingEvents') {
                            trackingEvents = new TrackingEvents(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'Articles consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class RedirectChange {
        public Boolean allowed {get;set;} 
        public String reasonCode {get;set;} 
        
        public RedirectChange(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'allowed') {
                            allowed = parser.getBooleanValue();
                        } else if (text == 'reasonCode') {
                            reasonCode = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'RedirectChange consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class ReturnInstructions {
        public Boolean returnToSender {get;set;} 
        
        public ReturnInstructions(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'returnToSender') {
                            returnToSender = parser.getBooleanValue();
                        } else {
                            System.debug(LoggingLevel.WARN, 'ReturnInstructions consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class DeliveryPoint {
        public String href {get;set;} 
        public String id {get;set;} 
        
        public DeliveryPoint(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'href') {
                            href = parser.getText();
                        } else if (text == 'id') {
                            id = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'DeliveryPoint consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class Items {
        public String id {get;set;} 
        public String code {get;set;} 
        //public String eventDateTime {get;set;} // in json: on
        public String message {get;set;} 
        public String location {get;set;} 
        public String workCentreId {get;set;}
        public String eventDateTime { // in json: on
            get {
                if(eventDateTime!=null) {
                    List<String> dateTimeSplit = eventDateTime.split('\\+');
                    return dateTimeSplit[0].replace('T',' ');
                }
                
                return null;
            }
            set;
        }
        
        public Items(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'id') {
                            id = parser.getText();
                        } else if (text == 'code') {
                            code = parser.getText();
                        } else if (text == 'eventDateTime') {
                            eventDateTime = parser.getText();
                        } else if (text == 'message') {
                            message = parser.getText();
                        } else if (text == 'location') {
                            location = parser.getText();
                        } else if (text == 'workCentreId') {
                            workCentreId = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'Items consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class TrackingEvents {
        public String href {get;set;} 
        public List<Items> items {get;set;} 
        
        public TrackingEvents(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'href') {
                            href = parser.getText();
                        } else if (text == 'items') {
                            items = arrayOfItems(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'TrackingEvents consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class Milestone {
        public String eventDateTime {get;set;} // in json: on
        public String name {get;set;} 
        public String description {get;set;} 
        public Integer progressPercentage {get;set;} 
        
        public Milestone(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'eventDateTime') {
                            eventDateTime = parser.getText();
                        } else if (text == 'name') {
                            name = parser.getText();
                        } else if (text == 'description') {
                            description = parser.getText();
                        } else if (text == 'progressPercentage') {
                            progressPercentage = parser.getIntegerValue();
                        } else {
                            System.debug(LoggingLevel.WARN, 'Milestone consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    
    public class Service {
        public String productType {get;set;} // in json: type
        public String subProductId {get;set;}
        
        public Service(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'productType') {
                            productType = parser.getText();
                        } else if (text == 'subProductId') {
                            subProductId = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'Service consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    
    public class Redirect {
        public String status {get;set;} 
        public RedirectChange redirectChange {get;set;} 
        
        public Redirect(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'status') {
                            status = parser.getText();
                        } else if (text == 'redirectChange') {
                            redirectChange = new RedirectChange(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'Redirect consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class DestinationAddress {
        public String line1 {get;set;} 
        public String line2 {get;set;} 
        public String line3 {get;set;} 
        public String suburb {get;set;} 
        public String state {get;set;} 
        public String postcode {get;set;} 
        public String countryCode {get;set;} 
        public DeliveryPoint deliveryPoint {get;set;} 
        
        public DestinationAddress(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'line1') {
                            line1 = parser.getText();
                        } else if (text == 'line2') {
                            line2 = parser.getText();
                        } else if (text == 'line3') {
                            line3 = parser.getText();
                        } else if (text == 'suburb') {
                            suburb = parser.getText();
                        } else if (text == 'state') {
                            state = parser.getText();
                        } else if (text == 'postcode') {
                            postcode = parser.getText();
                        } else if (text == 'countryCode') {
                            countryCode = parser.getText();
                        } else if (text == 'deliveryPoint') {
                            deliveryPoint = new DeliveryPoint(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'DestinationAddress consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class ExpectedDelivery {
        public String eventDateTime {get;set;} // in json: on
        public Boolean onChanged {get;set;} 
        public Between between {get;set;} 
        
        public ExpectedDelivery(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'eventDateTime') {
                            eventDateTime = parser.getText();
                        } else if (text == 'onChanged') {
                            onChanged = parser.getBooleanValue();
                        } else if (text == 'between') {
                            between = new Between(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'ExpectedDelivery consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    public class Between {
		public String fromDateTime {get;set;} // in json: from
		public String to {get;set;} 

		public Between(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'from') {
							fromDateTime = parser.getText();
						} else if (text == 'to') {
							to = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Between consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
    public class Errors {
        public Integer responseCode;
        public String responseMessage;
        public String code;
        public String message;
        public String trackingRef;
        //public Object foundByTrackingReferences;
        //public Object developerMessage;
        public String href;
        public Errors(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'responseCode') {
                            responseCode = parser.getIntegerValue();
                        } else {
                            System.debug(LoggingLevel.WARN, 'Errors consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public static ChasOneTrackResponse parse(String json) {
        System.JSONParser parser = System.JSON.createParser(json);
        return new ChasOneTrackResponse(parser);
    }
    
    public static void consumeObject(System.JSONParser parser) {
        Integer depth = 0;
        do {
            System.JSONToken curr = parser.getCurrentToken();
            if (curr == System.JSONToken.START_OBJECT || 
                curr == System.JSONToken.START_ARRAY) {
                    depth++;
                } else if (curr == System.JSONToken.END_OBJECT ||
                           curr == System.JSONToken.END_ARRAY) {
                               depth--;
                           }
        } while (depth > 0 && parser.nextToken() != null);
    }
    
    private static List<Articles> arrayOfArticles(System.JSONParser p) {
        List<Articles> res = new List<Articles>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Articles(p));
        }
        return res;
    }
    
    private static List<Errors> arrayOfErrors(System.JSONParser p) {
        List<Errors> res = new List<Errors>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Errors(p));
        }
        return res;
    }
    
    
    private static List<Items> arrayOfItems(System.JSONParser p) {
        List<Items> res = new List<Items>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Items(p));
        }
        return res;
    }
    
}