/**
* @author nasir jawed
* @date 2022-05-27
* @group Class
* @tag Apex MOCK Controller
* @domain Apttus
* @description A Mock Class for the Compass API response
* @changelog
*/
@isTest
public class APT_HttpCallouts_Mock implements HttpCalloutMock {       
        
    public HTTPResponse respond(HTTPRequest req) {             
        System.assertEquals('callout:CompassPricing', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        
           String json = '{'+
           '\"quoteId\": \"PDA-COMPASS-0000000103\", '+
          '\"customerId\": \"4604376\",'+
          '\"customerType\": \"SalesForce Billing Account Number\",'+
          '\"priceStructure\": \"Z006\",'+
          '\"customerTier\": \"T05\",'+
          '\"weightRounding\": \"Y\",'+
          '\"cubicConvfac\": 250,'+
          '\"cubingFlag\": \"Y\",'+
          '\"ratingModel\": \"PD\",'+
          '\"ratingGroup\": \"PARCEL\",'+
          '\"subsequentDiscount\": 1.36,'+
          '\"subsequentDiscountPriceType\": \"AUD\",'+
          '\"ratecardItem\": ['+
            '{'+
              '\"lodgementZone\": \"ME\",'+
              '\"priceStructure\": \"Z006\",'+
              '\"customerTier\": \"T05\",'+
              '\"customRef\": \"0000000103\",'+
              '\"ratingcardCategory\": \"SP00\",'+
              '\"serviceSpeeds\": ['+
               '{'+
                  '\"pricePoint\": \"MESSCAS\",'+
                  '\"priceFactor\": \"BRSP00S006ME\",'+
                  '\"weightBreak\": 0.5,'+
                  '\"weightBreakDesc\": \"Up to 500g\",'+
                  '\"basicRate\": 2.22,'+
                  '\"priceType\": \"AUD\"'+
                '},'+
                '{'+
                 '\"pricePoint\": \"MESSCAS\",'+
                  '\"priceFactor\": \"KRSP00S006ME\",'+
                  '\"weightBreak\": 0.5,'+
                  '\"weightBreakDesc\": \"Up to 500g\",'+
                  '\"kgRate\": 0,'+
                  '\"priceType\": \"AUD\"'+
                '},'+
               ' {'+
                  '\"pricePoint\": \"MESSCAM\",'+
                  '\"priceFactor\": \"BRSP00S006ME\",'+
                  '\"weightBreak\": 1,'+
                 '\"weightBreakDesc\": \"501g to 1kg\",'+
                  '\"basicRate\": 5.32,'+
                  '\"priceType\": \"AUD\"'+
                '},'+
                '{'+
                  '\"pricePoint\": \"MESSCAM\",'+
                  '\"priceFactor\": \"KRSP00S006ME\",'+
                  '\"weightBreak\": 1,'+
                  '\"weightBreakDesc\": \"501g to 1kg\",'+
                  '\"kgRate\": 0.08,'+
                  '\"priceType\": \"AUD\"'+
               ' },'+
               ' {'+
                  '\"pricePoint\": \"MESSCAL\",'+
                  '\"priceFactor\": \"BRSP00S006ME\",'+
                  '\"weightBreak\": 3,'+
                  '\"weightBreakDesc\": \"1.001kg to 3kg\",'+
                  '\"basicRate\": 5.95,'+
                  '\"priceType\": \"AUD\"'+
                '},'+
                '{'+
                  '\"pricePoint\": \"MESSCAL\",'+
                  '\"priceFactor\": \"KRSP00S006ME\",'+
                  '\"weightBreak\": 3,'+
                  '\"weightBreakDesc\": \"1.001kg to 3kg\",'+
                  '\"kgRate\": 0.05,'+
                  '\"priceType\": \"AUD\"'+
                '}'+
              ']'+
            '},'+
             
            '{'+
              '\"lodgementZone\": \"AN\",'+
              '\"priceStructure\": \"Z001\",'+
              '\"customerTie\": \"T05\",'+
              '\"ratingcardCategory\": \"FE00\",'+
              '\"features\": ['+
               ' {'+
                 '\"pricePoint\": \"TCOVER-1\",'+
                 '\"priceFactor\": \"FE000\",'+
                 '\"name\": \"Transit Cover - Requested\",'+
                 '\"totDeclaredCover\": 0,'+
                 '\"price\": 0.85,'+
                  '\"minValue\": 50,'+
                 '\"maxValue\": 5000,'+
                  '\"pricetype\": \"ART\"'+
               ' }'+
                
              ']'+
            '},'+
            '{'+
              '\"lodgementZone\": \"AN\",'+
              '\"priceStructure\": \"Z001\",'+
              '\"customerTier\": \"T05\",'+
              '\"ratingcardCategory\": \"RE00\",'+
              '\"returns\": ['+
               ' {'+
                  '\"pricePoint\": \"REFRSP00\",'+
                  '\"priceFactor\": \"RE000\",'+
                  '\"name\": \"Returns Flat Rate-Standard\",'+
                  '\"price\": 9.2,'+
                 '\"priceType\": \"AUD\"'+
                '}'+
                
            '  ]'+
            '},'+
            '{'+
             '\"lodgementZone\": \"AN\",'+
              '\"priceStructure\": \"Z001\",'+
              '\"customerTier\": \"T05\",'+
              '\"ratingcardCategory\": \"SU00\",'+
              '\"surcharges\": ['+
               ' {'+
                 '\"pricePoint\": \"MHS-LD\",'+
                  '\"priceFactor\": \"SU000\",'+
                  '\"name\": \"Manual Handling Charge based on Dimension\",'+
                  '\"price\": 9.5,'+
                 '\"priceType\": \"AUD\"'+
            '  }'+
                
           '  ]'+
          '  }'+
         ' ]'+
        '}';




                          
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');        
        res.setBody(json);
        res.setStatusCode(200);  
        res.setStatus('OK');
        return res;
    } 
    
    public class APT_HttpCallouts_MockInvalidCusID implements HttpCalloutMock { 
        public HTTPResponse respond(HTTPRequest req) { 
        
        String json1=    '{'+
                       '\"id\":\"978b0c893c46a361\",'+
                       '\"errors\":['+
                         ' {'+
                             '\"code\":\"INVALID_CUSTOMER_ID\",'+
                             '\"detail\":\"The customer id provided is not valid for the quote.\"'+
                         ' }'+
                      ' ]'+
                    '}';
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');        
        res.setBody(json1);
        res.setStatusCode(400);  
        res.setStatus('Bad Request');
        return res;    
        
        }
    }
    
    public class APT_HttpCallouts_MockDataNotFound implements HttpCalloutMock { 
        public HTTPResponse respond(HTTPRequest req) { 
        
        String json1=    '{'+
                       '\"id\":\"8cd172359c0c07de\",'+
                       '\"errors\":['+
                         ' {'+
                             '\"code\":\"DATA_NOT_FOUND\",'+
                             '\"detail\":\"The quote ID does not exist.\"'+
                         ' }'+
                      ' ]'+
                    '}';
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');        
        res.setBody(json1);
        res.setStatusCode(400);  
        res.setStatus('Bad Request');
        return res;    
        
        }
    }
    
    public class APT_HttpCallouts_MockInvalidRatingModel implements HttpCalloutMock { 
        public HTTPResponse respond(HTTPRequest req) { 
        
        String json1=    '{'+
                       '\"id\":\"8cd172359c0c07de\",'+
                       '\"errors\":['+
                         ' {'+
                             '\"code\":\"INVALID_RATING_MODEL\",'+
                             '\"detail\":\"Invalid rating model.\"'+
                         ' }'+
                      ' ]'+
                    '}';
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');        
        res.setBody(json1);
        res.setStatusCode(400);  
        res.setStatus('Bad Request');
        return res;    
        
        }
    }
   
    public class APT_HttpCallouts_MockInvalidHttpCall implements HttpCalloutMock { 

      public HttpResponse respond(HttpRequest request) {
        CalloutException e = (CalloutException)CalloutException.class.newInstance();
        e.setMessage('Unauthorized endpoint, please check Setup->Security->Remote site settings.');
        throw e;
        }
  }
    
    public HTTPResponse respond2(HTTPRequest req) {             
        System.assertEquals('callout:CompassPricing', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        
           String json = '{'+
           '\"quoteId\": \"PDA-COMPASS-0000000782\", '+
          '\"customerId\": \"4604376\",'+
          '\"customerType\": \"SalesForce Billing Account Number\",'+
          '\"priceStructure\": \"Z003\",'+
          '\"customerTier\": \"T07\",'+
          '\"weightRounding\": \"Y\",'+
          '\"cubicConvfac\": 250,'+
          '\"cubingFlag\": \"Y\",'+
          '\"ratingModel\": \"PD\",'+
          '\"ratingGroup\": \"PARCEL\",'+
          '\"subsequentDiscount\": 1.36,'+
          '\"subsequentDiscountPriceType\": \"AUD\",'+
          '\"ratecardItem\": ['+
            '{'+
              '\"lodgementZone\": \"ME\",'+
              '\"priceStructure\": \"Z003\",'+
              '\"customerTier\": \"T07\",'+
              '\"customRef\": \"0000000103\",'+
              '\"ratingcardCategory\": \"SP00\",'+
              '\"serviceSpeeds\": ['+
               '{'+
                  '\"pricePoint\": \"MESSCAS\",'+
                  '\"priceFactor\": \"BRSP00S006ME\",'+
                  '\"weightBreak\": 0.5,'+
                  '\"weightBreakDesc\": \"Up to 500g\",'+
                  '\"basicRate\": 2.22,'+
                  '\"priceType\": \"AUD\"'+
                '},'+
                '{'+
                 '\"pricePoint\": \"MESSCAS\",'+
                  '\"priceFactor\": \"KRSP00S006ME\",'+
                  '\"weightBreak\": 0.5,'+
                  '\"weightBreakDesc\": \"Up to 500g\",'+
                  '\"kgRate\": 0,'+
                  '\"priceType\": \"AUD\"'+
                '},'+
               ' {'+
                  '\"pricePoint\": \"MESSCAM\",'+
                  '\"priceFactor\": \"BRSP00S006ME\",'+
                  '\"weightBreak\": 1,'+
                 '\"weightBreakDesc\": \"501g to 1kg\",'+
                  '\"basicRate\": 5.32,'+
                  '\"priceType\": \"AUD\"'+
                '},'+
                '{'+
                  '\"pricePoint\": \"MESSCAM\",'+
                  '\"priceFactor\": \"KRSP00S006ME\",'+
                  '\"weightBreak\": 1,'+
                  '\"weightBreakDesc\": \"501g to 1kg\",'+
                  '\"kgRate\": 0.08,'+
                  '\"priceType\": \"AUD\"'+
               ' },'+
               ' {'+
                  '\"pricePoint\": \"MESSCAL\",'+
                  '\"priceFactor\": \"BRSP00S006ME\",'+
                  '\"weightBreak\": 3,'+
                  '\"weightBreakDesc\": \"1.001kg to 3kg\",'+
                  '\"basicRate\": 5.95,'+
                  '\"priceType\": \"AUD\"'+
                '},'+
                '{'+
                  '\"pricePoint\": \"MESSCAL\",'+
                  '\"priceFactor\": \"KRSP00S006ME\",'+
                  '\"weightBreak\": 3,'+
                  '\"weightBreakDesc\": \"1.001kg to 3kg\",'+
                  '\"kgRate\": 0.05,'+
                  '\"priceType\": \"AUD\"'+
                '}'+
              ']'+
            '},'+
             
            '{'+
              '\"lodgementZone\": \"AN\",'+
              '\"priceStructure\": \"Z001\",'+
              '\"customerTie\": \"T05\",'+
              '\"ratingcardCategory\": \"FE00\",'+
              '\"features\": ['+
               ' {'+
                 '\"pricePoint\": \"TCOVER-1\",'+
                 '\"priceFactor\": \"FE000\",'+
                 '\"name\": \"Transit Cover - Requested\",'+
                 '\"totDeclaredCover\": 0,'+
                 '\"price\": 0.85,'+
                  '\"minValue\": 50,'+
                 '\"maxValue\": 5000,'+
                  '\"pricetype\": \"ART\"'+
               ' }'+
                
              ']'+
            '},'+
            '{'+
              '\"lodgementZone\": \"AN\",'+
              '\"priceStructure\": \"Z001\",'+
              '\"customerTier\": \"T05\",'+
              '\"ratingcardCategory\": \"RE00\",'+
              '\"returns\": ['+
               ' {'+
                  '\"pricePoint\": \"REFRSP00\",'+
                  '\"priceFactor\": \"RE000\",'+
                  '\"name\": \"Returns Flat Rate-Standard\",'+
                  '\"price\": 9.2,'+
                 '\"priceType\": \"AUD\"'+
                '}'+
                
            '  ]'+
            '},'+
            '{'+
             '\"lodgementZone\": \"AN\",'+
              '\"priceStructure\": \"Z001\",'+
              '\"customerTier\": \"T05\",'+
              '\"ratingcardCategory\": \"SU00\",'+
              '\"surcharges\": ['+
               ' {'+
                 '\"pricePoint\": \"MHS-LD\",'+
                  '\"priceFactor\": \"SU000\",'+
                  '\"name\": \"Manual Handling Charge based on Dimension\",'+
                  '\"price\": 9.5,'+
                 '\"priceType\": \"AUD\"'+
            '  }'+
                
           '  ]'+
          '  }'+
         ' ]'+
        '}';




                          
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');        
        res.setBody(json);
        res.setStatusCode(200);  
        res.setStatus('OK');
        return res;
    } 
    public class APT_HttpCallouts_MockINVALID_QUOTE implements HttpCalloutMock { 
        public HTTPResponse respond(HTTPRequest req) { 
        
        String json1=    '{'+
                       '\"id\":\"978b0c893c46a361\",'+
                       '\"errors\":['+
                         ' {'+
                             '\"code\":\"INVALID_QUOTE\",'+
                             '\"detail\":\"The customer id provided is not valid for the quote.\"'+
                         ' }'+
                      ' ]'+
                    '}';
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');        
        res.setBody(json1);
        res.setStatusCode(400);  
        res.setStatus('Not Found');
        return res;    
        
        }
    }

    public class APT_HttpCallouts_MockEXPIRED_QUOTE implements HttpCalloutMock { 
      public HTTPResponse respond(HTTPRequest req) { 
      
      String json1=    '{'+
                     '\"id\":\"978b0c893c46a361\",'+
                     '\"errors\":['+
                       ' {'+
                           '\"code\":\"EXPIRED_QUOTE\",'+
                           '\"detail\":\"The customer id provided is not valid for the quote.\"'+
                       ' }'+
                    ' ]'+
                  '}';
      
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type','application/json');        
      res.setBody(json1);
      res.setStatusCode(400);  
      res.setStatus('Not Found');
      return res;    
      
      }
  }
  
  public class APT_HttpCallouts_MockSYSTEM_ERROR implements HttpCalloutMock { 
      public HTTPResponse respond(HTTPRequest req) { 
      
      String json1=    '{'+
                     '\"id\":\"978b0c893c46a361\",'+
                     '\"errors\":['+
                       ' {'+
                           '\"code\":\"SYSTEM_ERROR\",'+
                           '\"detail\":\"The customer id provided is not valid for the quote.\"'+
                       ' }'+
                    ' ]'+
                  '}';
      
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type','application/json');        
      res.setBody(json1);
      res.setStatusCode(500);  
      res.setStatus('Not Found');
      return res;    
      
      }
  }
    
    public class APT_HttpCallouts_MockDataNotFound404 implements HttpCalloutMock { 
        public HTTPResponse respond(HTTPRequest req) { 
        
        String json1=    '{'+
                       '\"id\":\"8cd172359c0c07de\",'+
                       '\"errors\":['+
                         ' {'+
                             '\"code\":\"DATA_NOT_FOUND\",'+
                             '\"detail\":\"The quote ID does not exist.\"'+
                         ' }'+
                      ' ]'+
                    '}';
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');        
        res.setBody(json1);
        res.setStatusCode(404);  
        res.setStatus('Not Found');
        return res;    
        
        }
    }
    
    
}