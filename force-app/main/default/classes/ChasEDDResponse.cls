public class ChasEDDResponse {
    public List<Articles> articles {get;set;} 
    public ChasEDDResponse(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'articles') {
						articles = arrayOfArticles(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'ChasEDDResponse consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
    
    public class Articles {
        public String id {get;set;}
        public String href {get;set;}
        public EstimatedDelivery estimatedDelivery {get;set;}
    
    public Articles(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'href') {
                            href = parser.getText();
                        } else if (text == 'id') {
                            id = parser.getText();
                        } else if (text == 'estimatedDelivery') {
							estimatedDelivery = new EstimatedDelivery(parser);
						}else {
                            System.debug(LoggingLevel.WARN, 'Articles consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    public class EstimatedDelivery {
		public String onDate {get;set;} 
		public ExpectedBetween expectedBetween {get;set;} 

		public EstimatedDelivery(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'onDate') {
							onDate = parser.getText();
						} else if (text == 'expectedBetween') {
							expectedBetween = new ExpectedBetween(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'EstimatedDelivery consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
    public class ExpectedBetween {
        public String fromDate {get;set;} // in json: from
        public String toDate {get;set;} 
        
        public expectedBetween(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();system.debug('text>>'+text);
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'fromDate') {
                            fromDate = parser.getText();
                        } else if (text == 'toDate') {
                            toDate = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'ExpectedBetween consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    public static ChasEDDResponse parse(String json) {
        System.JSONParser parser = System.JSON.createParser(json);
        return new ChasEDDResponse(parser);
    }
    private static List<Articles> arrayOfArticles(System.JSONParser p) {
        List<Articles> res = new List<Articles>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Articles(p));
        }
        return res;
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
}