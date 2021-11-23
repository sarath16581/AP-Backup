public class GsUseCaseSetup{

 	public static map<String, GsUseCase> useCases
	{
		get
		{
			if(useCases == null)
			{			
				useCases = new  map<String, GsUseCase>();
				/*		Legend
								01	Boolean inAcknowledgementEmail,
								02	String 	inThankYouPageMessageCode,
				    			03	String 	inThankYouPageMessage,
				    			04	Boolean inOfferEmailRequired,
				    			05	String 	inOfferEmailText,
				    			06	Boolean inAttchApplicationResponse,
				    			07	Boolean inAttchCreditAccountTC,
				    			08	Boolean inAttchEParcelTC,
				    			09	Boolean inAttchBonusOfferTC,
				    			10	Boolean inAttchParcelRateCard,
				    			11	String 	inAcceptancePage,
				    			12	Boolean inWfCallToActionCredit,
								13	Boolean inWfCallToActionCustData,
								14	Boolean inWfCallToActionContract,
				    			15	Boolean inWfCallToActionEParcel,
								16	Boolean inWfBHActivatePickups,
				    			17	Boolean inWfUnsubscribe,
				    			18	Boolean inWfSalesReferal
				    			19	String	cmsvAfterSubmission
				    			20	String	cmsvAfterProceedAccept
						*/
			
	            //Use case setup					01		02		03			04		05		06		07		08		09		10					11				12					13					14					15					16					17					18					19		20
				useCases.put('0', new GsUseCase(	false,	null,	null,		false,	null ,	false,	false,	false,	false,	false,	null,	false,	false,	false,	false,	false,	false,	false, '', ''));
				
				useCases.put('1', new GsUseCase(	false,	'A',	'success',	false,	null ,	false,	false,	false,	false,	false,	null,	false,	false,	false,	false,	false,	false,	true , 'Submitted - CR Followup/eParcel Followup', null ));
				//removed in v10
				//useCases.put('1B', new GsUseCase(	false,	'A',	'success',	false,	null,	false,	false,	false,	false,	false,	null,	false,	false,	false,	false,	false,	false,	true , 'Submitted - Existing CR/eParcel Followup', null ));
				useCases.put('2', new GsUseCase(	false,	'B',	'result',	false,	null,	false,	false,	false,	false,	false,	null,	false,	false,	false,	false,	false,	false,	false, 'Not Interested – No CR', null));
				useCases.put('3', new GsUseCase(	false,	'A', 	'success',	false,	null,	false,	false,	false,	false,	false,	null,	false,	false,	false,	false,	false,	false,	true , 'Submitted - CR Followup', null));
				useCases.put('4', new GsUseCase(	true ,	'C',	'received',	true,	'H' ,	true ,	true ,	false,	false,	false,	'K',		true ,	true ,	false,	false,	true ,	false,	false, 'Submitted - New CR/CnS', 'Accepted - New CR/CnS'));
				useCases.put('5', new GsUseCase(	true ,	'D', 	'confirmed',true,	'L' ,	true ,	true ,	false,	false,	false,	'K',		true ,	true ,	false,	false,	false,	false,	false, 'Submitted - New CR/No eParcel', 'Accepted - New CR/No eParcel'));
				useCases.put('6', new GsUseCase(	true ,	'E',		'submitted',true,	'I' ,	true ,	true ,	true ,	true ,	true,		'K',		true ,	true ,	true ,	true ,	true ,	false,	false, 'Submitted - New CR/New eParcel', 'Accepted - New CR/New eParcel'));    
				useCases.put('7', new GsUseCase(	false,	'F',	'lodged',	false,	null,	false,	false,	false,	false,	false,	null,	false,	false,	false,	false,	true ,	false,	false, 'Submitted - Existing CR/CnS', null));    
				useCases.put('8', new GsUseCase(	false,	'M',	'eParcel',	false,	null,	false,	false,	false,	false,	false,	null,	false,	false,	false,	false,	false,	false,	false, 'Submitted - Existing CR/No eParcel', null));
				useCases.put('9', new GsUseCase(	true ,	'G',	'applied',	true,	'J' ,	true ,	false,	true ,	true ,	true,		'K',		false,	false,	true ,	true ,	true ,	false,	false, 'Submitted - Existing CR/New eParcel', 'Accepted - Existing CR/New eParcel'));      
				
				useCases.put('10', new GsUseCase(	false,	'Y',	'cancel',	false,	null ,	false,	false,	false,	false,	false,	null,	false,	false,	false,	false,	false,	false,	false, 'Not Interested – Cancelled', null)); 
				useCases.put('11', new GsUseCase(	false,	'U',	'disagree',	false,	null ,	false,	false,	false,	false,	false,	null,	false,	false,	false,	false,	false,	false,	false, 'Not Interested – Unsubscribed', null)); 
				useCases.put('12A', new GsUseCase(	false,	'X',	'disagree',	false,	null ,	false,	false,	false,	false,	false,	null,	false,	false,	false,	false,	false,	false,	false, 'Submitted - Disagreed', null)); 
				useCases.put('12B', new GsUseCase(	false,	'X',	'disagree',	false,	null ,	false,	false,	false,	false,	false,	null,	false,	false,	false,	false,	false,	false,	false, 'Submitted - Disagreed', null)); 
		
		
				useCases.put('99', new GsUseCase(	false,	null,	'disagree',	false,	'I' ,	false,	false,	false,	false,	false,	null,	false,	false,	false,	false,	false,	false,	false, '', '')); //User declines T&C's
			
			}

				return useCases;
		
		}
	
		Set;
	
	}
	
	
    public static map<String, String> emailsTemplateNameByOfferEmailText 
	{
		get
		{
			if(emailsTemplateNameByOfferEmailText == null)
			{
				emailsTemplateNameByOfferEmailText = new map<String, String>();
				//Set Email Map by leter 
				emailsTemplateNameByOfferEmailText.put('H','Greenshoots_Offer_Email_CreditOnly_ACCEPT');
				emailsTemplateNameByOfferEmailText.put('I','Greenshoots_Offer_Email_CreditAndEParcel_ACCEPT');
				emailsTemplateNameByOfferEmailText.put('J','Greenshoots_Offer_Email_EParcel_Only_ACCEPT');
				emailsTemplateNameByOfferEmailText.put('L','Greenshoots_Offer_Email_CreditOnly_ClickAndSend_ACCEPT');
			}
			
			return emailsTemplateNameByOfferEmailText;
		}
		Set;
	}	
		

		
		
		

				
	
	
}