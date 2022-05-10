/**
 * Created by: Sautul Mehta
 * Description: Test class for Quote rate card utility factory.
 * @changelog
 * 2021-10-05 - Sautul Mehta - Test class Created as part of CI-8
 */
@istest
public class APT_QuoteRateCardUtilityFactoryTest {
    public static TestMethod void getInstance_APPC(){
        APT_QuoteRateCardUtilityFactory quoteRateCardFactory = new APT_QuoteRateCardUtilityFactory();
        APT_IQuoteRateCardUtility quoteRateCardUtility = quoteRateCardFactory.getInstance('APPC');
        System.assert(quoteRateCardUtility instanceof APT_QuoteRateCardUtility);
    } 
    
    public static TestMethod void getInstance_NonAPPC(){
        APT_QuoteRateCardUtilityFactory quoteRateCardFactory = new APT_QuoteRateCardUtilityFactory();
        APT_IQuoteRateCardUtility quoteRateCardUtility = quoteRateCardFactory.getInstance('NonAPPC');
        System.assert(quoteRateCardUtility instanceof APT_QuoteRateCardUtility);
    } 
}