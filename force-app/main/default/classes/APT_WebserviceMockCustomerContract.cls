/*
Created By - Drashtee Shah
Created Date - 29th Feb, 2016
Last Modified By -
Last Modified Date - 
 */
global with sharing class APT_WebserviceMockCustomerContract implements WebServiceMock {
    /**
     Invoke method for creating request data
    **/
    global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
        
        
        //RatecardContractDetailsType
        APT_SAP_QueryRateCardService.RatecardContractDetailsType rcdt1 = new APT_SAP_QueryRateCardService.RatecardContractDetailsType();
        rcdt1.SubProductName = APT_Constants.EMPTY_STRING;
        rcdt1.CustomerReferenceNumber = APT_Constants.STRING_60992317;
        rcdt1.OrganisationName = APT_Constants.EMPTY_STRING;
        rcdt1.ContractID = APT_Constants.EMPTY_STRING;
        rcdt1.ContractExpiryDate = System.Today();
        rcdt1.SAPERPContractNumber = APT_Constants.EMPTY_STRING;
        rcdt1.MinRevenuePerAnnum = 1;
        rcdt1.MinQuantityPerAnnum = 1;
        
        //List RateType
        List<APT_SAP_QueryRateCardService.RateType> rtList1 = new List<APT_SAP_QueryRateCardService.RateType>();
        APT_SAP_QueryRateCardService.RateType rt1 = new APT_SAP_QueryRateCardService.RateType();
        rt1.DestinationZoneCode = APT_Constants.EMPTY_STRING;
        rt1.WeightRangeCode = 1;
        rt1.LookupFull = APT_Constants.STRING_eParcelExpress;
        rt1.LookupSub = APT_Constants.EMPTY_STRING;
        rt1.PricingTotalRows = 1;
        rt1.PricingManuallyAdjustedRows = 1;
        rt1.RAFCode = APT_Constants.EMPTY_STRING;
        rt1.BaseRate = 1;
        rt1.SubsequentRate = 1;
        rt1.PerKgRate = 1;
        rt1.BaseRateManuallyAdjustedFlag = APT_Constants.EMPTY_STRING;
        rt1.PerKgManuallyAdjustedFlag = APT_Constants.EMPTY_STRING;
        rtList1.add(rt1);
        
        
        //RatesDetails_element
        APT_SAP_QueryRateCardService.RatesDetails_element rde1 = new APT_SAP_QueryRateCardService.RatesDetails_element();
        rde1.Rate = rtList1;
        
        //Comments_element
        APT_SAP_QueryRateCardService.Comments_element ce = new APT_SAP_QueryRateCardService.Comments_element();
        ce.Comment = null;
        
        //ExpressCourierRates_element
        APT_SAP_QueryRateCardService.ExpressCourierRates_element ecre1 = new APT_SAP_QueryRateCardService.ExpressCourierRates_element();
        ecre1.UpTo2KGPerItem = 1;
        ecre1.UpTo2KGPerKG = 1;
        ecre1.Over2KGPerItem = 1;
        ecre1.Over2KGPerKG = 1;
        
        //AirmailRates_element
        APT_SAP_QueryRateCardService.AirmailRates_element are1 = new APT_SAP_QueryRateCardService.AirmailRates_element();
        are1.UpTo2KGPerItem = 1;
        are1.UpTo2KGPerKG = 1;
        are1.Over2KGPerItem = 1;
        are1.Over2KGPerKG = 1;
        
        //NewZealandRatesDetailsType
        APT_SAP_QueryRateCardService.NewZealandRatesDetailsType nzrdt1 = new APT_SAP_QueryRateCardService.NewZealandRatesDetailsType();
        nzrdt1.AirmailRates = are1;
        nzrdt1.ExpressCourierRates = ecre1;
        
        //ExpressCourierRates_element
        APT_SAP_QueryRateCardService.ExpressCourierRates_element ecre11 = new APT_SAP_QueryRateCardService.ExpressCourierRates_element();
        ecre11.UpTo2KGPerItem = 1;
        ecre11.UpTo2KGPerKG = 1;
        ecre11.Over2KGPerItem = 1;
        ecre11.Over2KGPerKG = 1;
        
        //UKRatesDetailsType
        APT_SAP_QueryRateCardService.UKRatesDetailsType urdt1 = new APT_SAP_QueryRateCardService.UKRatesDetailsType();
        urdt1.ExpressCourierRates = ecre11;
        
        //BandRateDetailsType
        APT_SAP_QueryRateCardService.BandRateDetailsType brdt1 = new APT_SAP_QueryRateCardService.BandRateDetailsType();
        brdt1.Band = APT_Constants.EMPTY_STRING;
        brdt1.RevenueEstimation = 1;
        brdt1.RevenueRange = APT_Constants.EMPTY_STRING;
        
        //APT_SAP_QueryRateCardService.MaxWeightBreak_element
        APT_SAP_QueryRateCardService.MaxWeightBreak_element mwbe = new APT_SAP_QueryRateCardService.MaxWeightBreak_element();
        mwbe.Code = 1;
        mwbe.Description = APT_Constants.EMPTY_STRING;
        
        //FlatRatesDetailsType
        APT_SAP_QueryRateCardService.FlatRatesDetailsType frdt1 = new APT_SAP_QueryRateCardService.FlatRatesDetailsType();
        frdt1.UpTo500GRate = 1;
        frdt1.Over500GRate = 2;
        frdt1.DispersionType = APT_Constants.EMPTY_STRING;
        frdt1.MaxWeightBreak = mwbe;
        
        //NewPricingDetailsType
        APT_SAP_QueryRateCardService.NewPricingDetailsType npdt1 = new APT_SAP_QueryRateCardService.NewPricingDetailsType();
        npdt1.LodgementZoneCode = APT_Constants.EMPTY_STRING;
        npdt1.ChargeCode = APT_Constants.EMPTY_STRING;
        npdt1.Category = APT_Constants.EMPTY_STRING;
        npdt1.PriceZoneStructure = APT_Constants.EMPTY_STRING;
        npdt1.PriceStructure = APT_Constants.EMPTY_STRING;
        npdt1.ZoneStructure = APT_Constants.EMPTY_STRING;
        npdt1.ValidFrom = System.Today();
        npdt1.ValidTo = System.Today() + 100;
        
        //CurrentPricingDetailsType
        APT_SAP_QueryRateCardService.CurrentPricingDetailsType cpdt1 = new APT_SAP_QueryRateCardService.CurrentPricingDetailsType();
        cpdt1.LodgementZoneCode = APT_Constants.EMPTY_STRING;
        cpdt1.ChargeCode = APT_Constants.EMPTY_STRING;
        cpdt1.ContractStructure = APT_Constants.EMPTY_STRING;
        cpdt1.Category = APT_Constants.EMPTY_STRING;
        cpdt1.ContractTerm = APT_Constants.EMPTY_STRING;
        
        //StandardChargesType
        APT_SAP_QueryRateCardService.StandardChargesType sct1 = new APT_SAP_QueryRateCardService.StandardChargesType();
        sct1.MissingManifestFee = 1;
        sct1.DomesticAdminFee = 1;
        sct1.InternationalAdminFee = 1;
        sct1.ReturnToSenderFee = 1;
        sct1.CollectionFee = 1;
        sct1.MinimumCollectionFee = 1;
        
        //APT_SAP_QueryRateCardService.TransitCoverDetailsType
        APT_SAP_QueryRateCardService.TransitCoverDetailsType tdt1 = new APT_SAP_QueryRateCardService.TransitCoverDetailsType();
        tdt1.Percentage = 1;
        tdt1.MinimumTransitCover = 1;
        tdt1.MaximumTransitCover = 2;
        
        //FeaturesDetails
        APT_SAP_QueryRateCardService.FeaturesDetailsType fd1= new APT_SAP_QueryRateCardService.FeaturesDetailsType();
        fd1.ReturnsPercentageAnnualVolume = 1;
        fd1.UpTo500GTotalReturnsVolume = 1;
        fd1.AverageChargeableWeight = 1;
        fd1.EparcelReturnsDeliveryFee = 1;
        fd1.ParcelPostReturnsDeliveryFee = 1;
        fd1.ParcelPostReturnsPickupFee = 1;
        fd1.ReturnPaidUpTo500GParcelPostFee = 1;
        fd1.ReturnPaidOver500GParcelPostFee = 1;
        fd1.ReturnPaidAnnualFee = 1;
        fd1.IdentityDeliveryFee = 1;
        fd1.TransitCoverDetails = tdt1;
        
        //CustomerPricingDetailsType
        APT_SAP_QueryRateCardService.CustomerPricingDetailsType cpdt = new APT_SAP_QueryRateCardService.CustomerPricingDetailsType();
        cpdt.Domestic = APT_Constants.EMPTY_STRING;
        cpdt.IndustrySegment = APT_Constants.EMPTY_STRING;
        cpdt.InternationalLetters = APT_Constants.EMPTY_STRING;
        cpdt.EparcelLodgement = APT_Constants.EMPTY_STRING;
        cpdt.VolumeAvailable = APT_Constants.EMPTY_STRING;
        cpdt.DispersionType = APT_Constants.EMPTY_STRING;
        
        //ApprovalDetails
        APT_SAP_QueryRateCardService.ApprovalDetails ad1 = new APT_SAP_QueryRateCardService.ApprovalDetails();
        ad1.Flag = APT_Constants.EMPTY_STRING;
        ad1.Timestamp = System.Today();
        ad1.UserId = APT_Constants.EMPTY_STRING;
        
        //ExtractDetails
        APT_SAP_QueryRateCardService.ExtractDetails ed1= new APT_SAP_QueryRateCardService.ExtractDetails();
        ed1.Flag = APT_Constants.EMPTY_STRING;
        ed1.Timestamp = System.Today();
        ed1.UserId = APT_Constants.EMPTY_STRING;
        ed1.ApprovalDetails = ad1;
        
        //CreationType
        APT_SAP_QueryRateCardService.CreationType ct1= new APT_SAP_QueryRateCardService.CreationType();
        ct1.Timestamp = System.Today();
        ct1.DayId = 1;
        ct1.MonthId = 1;
        ct1.UserId = APT_Constants.EMPTY_STRING;
        ct1.UserLevel = APT_Constants.EMPTY_STRING;
        ct1.ToolName = APT_Constants.EMPTY_STRING;
        ct1.UploadType = APT_Constants.EMPTY_STRING;
        ct1.BulkRatecardOutputFlag = APT_Constants.EMPTY_STRING;
        
        //StatusDetails
        APT_SAP_QueryRateCardService.StatusDetails sd1= new APT_SAP_QueryRateCardService.StatusDetails();
        sd1.Type_x = APT_Constants.EMPTY_STRING;
        sd1.Flag = APT_Constants.EMPTY_STRING;
        sd1.Timestamp = System.Today();
        sd1.UserId = APT_Constants.EMPTY_STRING;
        
        // first sub sub response
        List<APT_SAP_QueryRateCardService.RateCardType> rctList = new List<APT_SAP_QueryRateCardService.RateCardType>();
        APT_SAP_QueryRateCardService.RateCardType rct = new APT_SAP_QueryRateCardService.RateCardType();
        rct.RateCardKey = APT_Constants.EMPTY_STRING;
        rct.PrecedingRateCardKey = APT_Constants.EMPTY_STRING;
        rct.Type_x = APT_Constants.RATE_CARD_TYPE_DOMESTIC; 
        rct.ScenarioType = APT_Constants.EMPTY_STRING;
        rct.QuoteNumber = APT_Constants.EMPTY_STRING;
        rct.ServiceTypeFlag = APT_Constants.EMPTY_STRING;
        rct.ServiceType = APT_Constants.EMPTY_STRING;
        rct.CubicFactor = 1;
        rct.BaseUpliftPercentage = 1;
        rct.CalculatedUpliftPercentage = 1;
        rct.SignatureFlag = APT_Constants.EMPTY_STRING;
        rct.ConsignmentPricingFlag = APT_Constants.EMPTY_STRING;
        rct.BarcodedParcelFlag = APT_Constants.EMPTY_STRING;
        rct.CreationDetails = ct1;
        rct.StatusDetails = sd1;
        rct.ExtractDetails = ed1;
        rct.CustomerPricingDetails = cpdt;
        rct.FeaturesDetails = fd1;
        rct.StandardCharges = sct1;
        rct.CurrentPricingDetails = cpdt1;
        rct.NewPricingDetails = npdt1;
        rct.FlatRatesDetails = frdt1;
        rct.BandRateDetails = brdt1;
        rct.UKRatesDetails = urdt1;
        rct.NewZealandRatesDetails = nzrdt1;
        rct.Comments = ce;
        rct.RatesDetails = rde1;
        rct.ContractDetails = rcdt1;
        rctList.add(rct);
        
        // first sub response
        APT_SAP_QueryRateCardService.Ratecards_element sub_response = new APT_SAP_QueryRateCardService.Ratecards_element();
        sub_response.Ratecard = rctList;
        
        // main response
        APT_SAP_QueryRateCardService.queryRatecardsResponseType mainResponse = new APT_SAP_QueryRateCardService.queryRatecardsResponseType();
        mainResponse.Ratecards = sub_response;
        
               
        response.put(APT_Constants.STRING_RESPONSE_MOCK, mainResponse);
        
   }

}