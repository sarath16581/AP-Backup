/* @author Nasir Jawed
 * @date 2022-05-20
 * @tag Wrapper class
 * @tag APT_CompassPricingcontroller
 * @domain Core
 * @description A wrapper for the class to store the API values
 * @changelog: 
 	2023-01-24 - Sarath Burra - Added the evaluatedSpend field to capture the value received from Compass
 */
Public class CompassWrapper {

    Public class CompassPriceWrapper {
            Public string quoteId{ get; set; }
            Public string customerId{ get; set; }
            Public string customerType{ get; set; }
            Public string dsrId{ get; set; }
            Public string priceStructure{ get; set; }
            Public string customerTier{ get; set; }
            Public string ratingplanDwtconvfac{ get; set; }
            Public string weightRounding{ get; set; }
            Public decimal cubicConvfac{ get; set; }
            Public string cubingFlag{ get; set; }
            Public string ratingModel{ get; set; }
            Public string ratingGroup{ get; set; }
            Public string subsequentDiscount{ get; set; }
            Public string subsequentDiscountPriceType{ get; set; }
			//CI-772 Added the evaluatedSpend field to capture the value received from Compass
			Public decimal evaluatedSpend{ get; set; }
            Public string ratecardDwtconvfac{ get; set; }        
            Public List<ratecardItem> ratecardItem{ get; set; }   
    
            public CompassPriceWrapper (){
                ratecardItem = new List<ratecardItem>();
            }
        }
    
        Public class ratecardItem{
            Public string lodgementZone{ get; set; }
            Public string customerTier{ get; set; }
            Public string customRef{ get; set; }
            Public string ratingcardCategory{ get; set; }
            Public string priceStructure{ get; set; }
            Public List<serviceSpeeds> serviceSpeeds{ get; set; } 
            Public List<features> features{ get; set; }
            Public List<returns> returns{ get; set; }
            Public List<surcharges> surcharges{ get; set; }
            public ratecardItem(){
                serviceSpeeds= new List<serviceSpeeds>();
                features= new List<features>();
                returns= new List<returns>();
                surcharges= new List<surcharges>();
    
            }
        }
    
        Public class serviceSpeeds{
            Public string pricePoint{ get; set; }
            Public string priceFactor{ get; set; }
            Public string weightBreak{ get; set; }
            Public string weightBreakDesc{ get; set; }
            Public decimal basicRate{ get; set; }
            Public decimal kgRate{ get; set; }
            Public string priceType{ get; set; }
            
            public serviceSpeeds(){
                pricePoint=''; 
                priceFactor='';  
                weightBreak='';  
                weightBreakDesc='';
                basicRate = 0.00; 
                kgRate = 0.00;
                priceType='';
            }
        }
    
        Public class features{
            Public string pricePoint{ get; set; }
            Public string priceFactor{ get; set; }
            Public string name{ get; set; }
            Public string totDeclaredCover{ get; set; }
            Public decimal price{ get; set; }
            Public string minValue{ get; set; }
            Public string maxValue{ get; set; }
            Public string priceType{ get; set; }
                
            public features(){
                pricePoint=''; 
                priceFactor='';  
                name='';
                totDeclaredCover='';
                price= 0.00;
                minValue='';
                maxValue='';
                priceType='' ;     
            }
        }
    
        Public class returns{
            Public string pricePoint{ get; set; }
            Public string priceFactor{ get; set; }
            Public string name{ get; set; }        
            Public decimal price{ get; set; }        
            Public string priceType{ get; set; }
                
            public returns(){
                pricePoint=''; 
                priceFactor='';  
                name='';
                price= 0.00;
                priceType='' ;     
            }
        }
    
        Public class surcharges{
            Public string pricePoint{ get; set; }
            Public string priceFactor{ get; set; }
            Public string name{ get; set; }        
            Public decimal price{ get; set; }        
            Public string priceType{ get; set; }
                
            public surcharges(){
                pricePoint=''; 
                priceFactor='';  
                name ='';
                price = 0.00;
                priceType='' ;          
            }
        }
    
        Public class frsWrapper{
            Public string pricePoint{ get; set; }
            Public string priceFactor{ get; set; }            
            Public decimal price{ get; set; }          
                
            public frsWrapper(string pp, string pf, decimal fullprice){
                pricePoint = pp; 
                priceFactor = pf;             
                price = fullprice;                    
            }
        }
        
    }