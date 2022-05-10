/**
 * Created by: Sautul Mehta
 * Description: Quote rate card utility factory to get the 
 * instance of quote rate card utility class based on product code
 * @changelog
 * 2021-10-05 - Sautul Mehta - Class Created as part of CI-8
 */
public class APT_QuoteRateCardUtilityFactory {
    public APT_IQuoteRateCardUtility getInstance(string productCode){
        
        return new APT_QuoteRateCardUtility();
    }
}