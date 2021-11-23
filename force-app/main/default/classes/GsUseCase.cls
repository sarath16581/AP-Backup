public with sharing class GsUseCase {
	public	String UseCaseNumber {get;set;}
	public	Boolean AcknowledgementEmail {get;set;}
	public	String thankYouPageMessageCode {get;set;}
    public	String thankYouPageMessage {get;set;}
    public	Boolean offerEmailRequired {get;set;}
    public	String offerEmailText {get;set;}

    	//Attachments
    public	Boolean attchApplicationResponse {get;set;}
    public	Boolean attchCreditAccountTC {get;set;}
    public	Boolean attchEParcelTC {get;set;}
    public	Boolean attchBonusOfferTC {get;set;}
    public	Boolean attchParcelRateCard {get;set;}

    public	String acceptancePage {get;set;}

    	//Internal Workflow (wf)
    public	Boolean wfCallToActionCredit {get;set;}
	public	Boolean wfCallToActionCustData {get;set;}
	public	Boolean wfCallToActionContract {get;set;}
    public	Boolean wfCallToActionEParcel {get;set;}
    public	Boolean wfBHActivatePickups {get;set;}
	public	Boolean wfUnsubscribe {get;set;}
    public	Boolean wfSalesReferal {get;set;}

	//Campaign Member Status Value (cmsv)
	public String cmsvAfterSubmission{get;set;}
	public String cmsvAfterProceedAccept{get;set;}	

    	public GsUseCase()
    	{}

    	public GsUseCase(
						Boolean inAcknowledgementEmail,
						String inThankYouPageMessageCode,
    					String inThankYouPageMessage,
    					Boolean inOfferEmailRequired,
    					String inOfferEmailText,
    					Boolean inAttchApplicationResponse,
    					Boolean inAttchCreditAccountTC,
    					Boolean inAttchEParcelTC,
    					Boolean inAttchBonusOfferTC,
    					Boolean inAttchParcelRateCard,
    					String inAcceptancePage,
    					Boolean inWfCallToActionCredit,
						Boolean inWfCallToActionCustData,
						Boolean inWfCallToActionContract,
    					Boolean inWfCallToActionEParcel,
    					Boolean inWfBHActivatePickups,
						Boolean inWfUnsubscribe,
    					Boolean inWfSalesReferal,
    					String inCmsvAfterSubmission,
    					String inCmsvAfterProceedAccept)
    	{
						AcknowledgementEmail = inAcknowledgementEmail;
						ThankYouPageMessageCode    	=   inThankYouPageMessageCode;
						ThankYouPageMessage        	=   inThankYouPageMessage;
						OfferEmailRequired         	=   inOfferEmailRequired;
						OfferEmailText             	=   inOfferEmailText;
						AttchApplicationResponse   	=   inAttchApplicationResponse;
						AttchCreditAccountTC       	=   inAttchCreditAccountTC;
						AttchEParcelTC            	=   inAttchEParcelTC;
						AttchBonusOfferTC          	=   inAttchBonusOfferTC;
						AttchParcelRateCard        	=   inAttchParcelRateCard;
						AcceptancePage             	=   inAcceptancePage;
						WfCallToActionCredit       	=   inWfCallToActionCredit;
						WfCallToActionCustData		=	inWfCallToActionCustData;
						WfCallToActionContract		=	inWfCallToActionContract;
						WfCallToActionEParcel      	=   inWfCallToActionEParcel;
						WfBHActivatePickups			=   inWfBHActivatePickups;
						WfUnsubscribe 				= 	inWfUnsubscribe;
						WfSalesReferal            	=   inWfSalesReferal;
						CmsvAfterSubmission			=	inCmsvAfterSubmission;
						CmsvAfterProceedAccept		=	inCmsvAfterProceedAccept;
    	}





 
	 public String caseSelection(String existingCreditAccount,
								String applyForCreditAccount,
								String creditLimit5000,
								String parcelsPerYear,
								String eParcelApplication,
								String termsCreditAccount,
								String termsParcelService,
								String generalTAndC)
    {

	    boolean parcelPerYearGreaterThan500 = (parcelsPerYear == '500 - 999');
	    boolean parcelPerYearGreaterThan1000 = (parcelsPerYear == '1000 - 4999' ||
	    										parcelsPerYear == '5000 - 9999');



		System.debug('### existingCreditAccount :' + 	existingCreditAccount);
		System.debug('### applyForCreditAccount :' + 	applyForCreditAccount);		
		System.debug('### creditLimit5000 		:' + 	creditLimit5000		);	
		System.debug('### parcelsPerYear 		:' + 	parcelsPerYear		);							
		System.debug('### eParcelApplicaion 	:' + 	eParcelApplication	);
		System.debug('### termsCreditAccount 	:' + 	termsCreditAccount	);
		System.debug('### termsParcelService 	:' + 	termsParcelService	);
		System.debug('### generalTAndC 			:' + 	generalTAndC		);
		
		
		UseCaseNumber = '0'; //Case not Found

        if( (generalTAndC == 'I do not agree') ||
        	(eParcelApplication =='Yes' && parcelPerYearGreaterThan500 && termsParcelService == 'I do not agree'))
		{
			UseCaseNumber = '12A';
		}else if( (applyForCreditAccount == 'Yes' && termsCreditAccount == 'I do not agree'))
		{
			UseCaseNumber = '12B';
		}
	    else if(//existingCreditAccount=='No' && 
	    		//applyForCreditAccount == 'Yes' &&
	    		//creditLimit5000 == 'No' &&
	    		parcelPerYearGreaterThan1000) //Case A: success
	    {
	    	UseCaseNumber = '1';
	    }
	   /*//Removed in v10
	    else if(existingCreditAccount=='Yes' && 
	    		parcelPerYearGreaterThan1000) //Case A: success
	    {
	    	UseCaseNumber = '1B';
	    }
	    */
	    else if(existingCreditAccount == 'No'  &&
	    		applyForCreditAccount == 'No'  &&
	    		!parcelPerYearGreaterThan1000) //Case B: result
	    {
	    	UseCaseNumber = '2';
	    }
	    else if(existingCreditAccount == 'No'  	&&
	    		applyForCreditAccount == 'Yes'	&&
	    		creditLimit5000 == 'Yes'		&&
	    		!parcelPerYearGreaterThan1000) //Case A: success
		{
			UseCaseNumber = '3';
		}
	    else if(existingCreditAccount == 'No'	&&
	    		applyForCreditAccount == 'Yes' 	&&
	    		creditLimit5000 == 'No'			&&
	    		!parcelPerYearGreaterThan500	&&
	    		!parcelPerYearGreaterThan1000) //Case C: received - H
	    {
	    	UseCaseNumber = '4';
	    }
	    else if(existingCreditAccount == 'No'  	&&
	    		applyForCreditAccount == 'Yes' 	&&
	    		creditLimit5000 == 'No'			&&
	    		parcelPerYearGreaterThan500 	&&
	    		!parcelPerYearGreaterThan1000	&&
	    		eParcelApplication == 'No') //Case D: confirmed - L
	    {
	    	UseCaseNumber = '5';
	    }
	    else if(existingCreditAccount == 'No'  	&&
	    		applyForCreditAccount == 'Yes' 	&&
	    		creditLimit5000 == 'No'			&&
	    		parcelPerYearGreaterThan500 	&&
	    		!parcelPerYearGreaterThan1000	&&
	    		eParcelApplication == 'Yes') //Case E:submitted - I
	    {
	    	UseCaseNumber = '6';
	    }
	    else if(existingCreditAccount == 'Yes' 	&&
	    		!parcelPerYearGreaterThan500 	&&
	    		!parcelPerYearGreaterThan1000) //Case F:lodged
	    {
	    	UseCaseNumber = '7';
	    }
	    else if(existingCreditAccount == 'Yes'  	&&
	    		parcelPerYearGreaterThan500 	&&
	    		!parcelPerYearGreaterThan1000	&&
	    		eParcelApplication == 'No') //Case B:lodged
	    {
	    	UseCaseNumber = '8';
	    }
	    else if(existingCreditAccount == 'Yes' 	&&
	    		parcelPerYearGreaterThan500 	&&
	    		!parcelPerYearGreaterThan1000	&&
	    		eParcelApplication == 'Yes') //Case G:applied - J
	    {
	    	UseCaseNumber = '9';
	    }

		System.debug('### UseCaseNumber:' + UseCaseNumber);
		
		return UseCaseNumber; 

    }



}