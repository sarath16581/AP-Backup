/**
Description: 
Created By - Drashtee Shah
Created Date - 1st mar, 2016
Last Modified By -
Last Modified Date - 
**/
global with sharing class APT_WebserviceMockSyncContract1 implements WebServiceMock {
    /**
        Invoke Method
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
        /*
        List<APT_SAP_SyncContractAndRatesService.SubAccountType> satList = new List<APT_SAP_SyncContractAndRatesService.SubAccountType>();
        APT_SAP_SyncContractAndRatesService.SubAccountType sat1 = new APT_SAP_SyncContractAndRatesService.SubAccountType();
        sat1.Id = '';
        sat1.Name = '';
        sat1.Type_x = '';
        satList.add(sat1);
        
        APT_SAP_SyncContractAndRatesService.AccountType act4 = new APT_SAP_SyncContractAndRatesService.AccountType();
        act4.Id = '';
        act4.Name = '';
        act4.Type_x = '';
        act4.SubAccount = satList;
        
        APT_SAP_SyncContractAndRatesService.AddressType adt2 = new APT_SAP_SyncContractAndRatesService.AddressType();
        adt2.AddressLine = '';
        adt2.Suburb = '';
        adt2.State = '';
        adt2.PostCode = '';
        adt2.CountryCode = '';
        
        APT_SAP_SyncContractAndRatesService.ContactDetailsType cdt3 = new APT_SAP_SyncContractAndRatesService.ContactDetailsType();
        cdt3.PhoneNumber = '';
        cdt3.MobileNumber = '';
        cdt3.FaxNumber = '';
        cdt3.EmailAddress = '';
        
        APT_SAP_SyncContractAndRatesService.NameType nt1 = new APT_SAP_SyncContractAndRatesService.NameType();
        nt1.Title = '';
        nt1.FirstName = '';
        nt1.LastName = '';
        nt1.MiddleNames = null;
        nt1.FullName = '';
        
        APT_SAP_SyncContractAndRatesService.IndividualContactType ict1 = new APT_SAP_SyncContractAndRatesService.IndividualContactType();
        ict1.Name = nt1;
        ict1.ContactDetails = cdt3;
        ict1.Address = adt2;
        
        
        APT_SAP_SyncContractAndRatesService.AddressType adt1 = new APT_SAP_SyncContractAndRatesService.AddressType();
        adt1.AddressLine = '';
        adt1.Suburb = '';
        adt1.State = '';
        adt1.PostCode = '';
        adt1.CountryCode = '';
        
        APT_SAP_SyncContractAndRatesService.ContactDetailsType cdt2 = new APT_SAP_SyncContractAndRatesService.ContactDetailsType();
        cdt2.PhoneNumber = '';
        cdt2.MobileNumber = '';
        cdt2.FaxNumber = '';
        cdt2.EmailAddress = '';
        
        APT_SAP_SyncContractAndRatesService.OrganisationType ot1 = new APT_SAP_SyncContractAndRatesService.OrganisationType();
        ot1.OrganisationName = '';
        ot1.LegalName = '';
        
        APT_SAP_SyncContractAndRatesService.OrganisationContactType oct = new APT_SAP_SyncContractAndRatesService.OrganisationContactType();
        oct.Organisation = ot1;
        oct.ContactDetails = cdt2;
        oct.Address = adt1;
        
        APT_SAP_SyncContractAndRatesService.CustomerReferenceNumbers_element cfne = new APT_SAP_SyncContractAndRatesService.CustomerReferenceNumbers_element();
        cfne.CustomerReferenceNumber = null;
        
        //CustomerDetailsType
        APT_SAP_SyncContractAndRatesService.CustomerDetailsType cdt1 = new APT_SAP_SyncContractAndRatesService.CustomerDetailsType();
        cdt1.ID = '';
        cdt1.CustomerReferenceNumbers = cfne;
        cdt1.Type_x = '';
        cdt1.MinRevenuePerAnnum = 100;
        cdt1.MinQuantityPerAnnum = 10;
        
        //CustomerType
        APT_SAP_SyncContractAndRatesService.CustomerType ct1 = new APT_SAP_SyncContractAndRatesService.CustomerType();
        ct1.CustomerDetails = cdt1;
        ct1.OrganisationContact = oct;
        ct1.IndividualContact = ict1;
        ct1.Account = act4;
        
        //QuoteType
        List<APT_SAP_SyncContractAndRatesService.QuoteType> quotelist = new List<APT_SAP_SyncContractAndRatesService.QuoteType>();
        APT_SAP_SyncContractAndRatesService.QuoteType quotetype = new APT_SAP_SyncContractAndRatesService.QuoteType();
        quotetype.QuoteNumber = '';
        quotetype.QuoteType = '';
        quotetype.SourceSystem = '';
        quotelist.add(quotetype);
        
        //ReferenceNumber_element[]
        List<APT_SAP_SyncContractAndRatesService.ReferenceNumber_element> rneList = new List<APT_SAP_SyncContractAndRatesService.ReferenceNumber_element>();
        APT_SAP_SyncContractAndRatesService.ReferenceNumber_element rne1 = new APT_SAP_SyncContractAndRatesService.ReferenceNumber_element();
        rneList.add(rne1);
        
        //ReferenceNumbers_element
        APT_SAP_SyncContractAndRatesService.ReferenceNumbers_element rne = new APT_SAP_SyncContractAndRatesService.ReferenceNumbers_element();
        rne.ReferenceNumber = rneList;
        
        //ContractDetailsType
        APT_SAP_SyncContractAndRatesService.ContractDetailsType cdt = new APT_SAP_SyncContractAndRatesService.ContractDetailsType();
        cdt.ID = '';
        cdt.ReferenceNumbers = rne;
        cdt.Type_x = '';
        cdt.CommencementDate = System.Today();
        cdt.ExpiryDate = System.Today() + 100;
        cdt.SalesActivity = '';
        cdt.OpportunityID = '';
        cdt.SAPERPContractNumber = '';
        cdt.Quote = quotelist;
        
        //SAPFilesnames_element
        APT_SAP_SyncContractAndRatesService.SAPFilesnames_element sfe = new APT_SAP_SyncContractAndRatesService.SAPFilesnames_element();
        sfe.ContractFilename = '';
        sfe.RatecardsFilename = '';
        sfe.DetailedRatesFilename = '';
        
        APT_SAP_SyncContractAndRatesService.SalesRepDetailsType srdt1 = new APT_SAP_SyncContractAndRatesService.SalesRepDetailsType();
        srdt1.Id = '';
        srdt1.Type_x = '';
        
        APT_SAP_SyncContractAndRatesService.SalesRepresentativeType spt1 = new APT_SAP_SyncContractAndRatesService.SalesRepresentativeType();
        spt1.SalesRepDetails = srdt1;
        spt1.OrganisationContact = oct;
        spt1.IndividualContact = ict1;
        spt1.Account = act4;
        
        List<APT_SAP_SyncContractAndRatesService.RateCardType> rctList = new List<APT_SAP_SyncContractAndRatesService.RateCardType>();
        APT_SAP_SyncContractAndRatesService.RateCardType rct45 = new APT_SAP_SyncContractAndRatesService.RateCardType();
        rct45.RateCardKey = '';
        rct45.PrecedingRateCardKey = '';
        rct45.Type_x = '';
        rct45.ScenarioType = '';
        rct45.Recontracting = '';
        rct45.QuoteNumber = '';
        rct45.ServiceTypeFlag = '';
        rct45.ServiceType = '';
        rct45.ProvisioningMethod = '';
        rct45.CubicFactor = 10;
        rct45.BaseUpliftPercentage = 10;
        rct45.CalculatedUpliftPercentage = 10;
        rct45.SignatureFlag = '';
        rct45.ConsignmentPricingFlag = '';
        rct45.BarcodedParcelFlag = '';
        rct45.CreationDetails = null;
        rct45.ExtractDetails = null;
        rct45.CustomerPricingDetails = null;
        rct45.FeaturesDetails = null;
        rct45.StandardCharges = null;
        rct45.DeliveryChoicesFeeDetails = null;
        rct45.CurrentPricingDetails = null;
        rct45.NewPricingDetails = null;
        rct45.FlatRatesDetails = null;
        rct45.BandRateDetails = null;
        rct45.VolumeAverageWeightDetails = null;
        rct45.ZoneDispersionDetails = null;
        rct45.UKRatesDetails = null;
        rct45.NewZealandRatesDetails = null;
        rct45.Comments = null;
        rct45.RatesDetails = null;
        rct45.DetailedRatesDetails = null;
        rctList.add(rct45);
        
        APT_SAP_SyncContractAndRatesService.RateCards_element rce1 = new APT_SAP_SyncContractAndRatesService.RateCards_element();
        rce1.RateCard = rctList;
        
        APT_SAP_SyncContractAndRatesService.SubProductDetailsType spdt1 = new APT_SAP_SyncContractAndRatesService.SubProductDetailsType();
        spdt1.Id = '';
        spdt1.Name = '';
        spdt1.Type_x = '';
        spdt1.RateCards = rce1;
        
        List<APT_SAP_SyncContractAndRatesService.SubProducType> sptList = new List<APT_SAP_SyncContractAndRatesService.SubProducType>();
        APT_SAP_SyncContractAndRatesService.SubProducType spt11 = new APT_SAP_SyncContractAndRatesService.SubProducType();
        spt11.SubProductDetails = spdt1;
        sptList.add(spt11);
        
        //ProductType
        List<APT_SAP_SyncContractAndRatesService.ProductType> ptList1 = new List<APT_SAP_SyncContractAndRatesService.ProductType>();
        APT_SAP_SyncContractAndRatesService.ProductType pt11 = new APT_SAP_SyncContractAndRatesService.ProductType();
        pt11.ProductDetails = null;
        pt11.Customer = null;
        pt11.SalesRepresentative = null;
        pt11.LodgementPoints = null;
        pt11.CollectionPoints = null;
        pt11.SubProducts = null;
        ptList1.add(pt11);
        
        APT_SAP_SyncContractAndRatesService.ProductsType pt1 = new APT_SAP_SyncContractAndRatesService.ProductsType();
        pt1.Product = ptList1;//sptList;
        
        //CustomerContractType
        APT_SAP_SyncContractAndRatesService.CustomerContractType cct = new APT_SAP_SyncContractAndRatesService.CustomerContractType();
        cct.SAPFilesnames = sfe;
        cct.ContractDetails = cdt;
        cct.Customer = ct1;
        cct.SalesRepresentative = spt1;
        cct.Products = pt1;
        
        //syncContractAndRatesType
        APT_SAP_SyncContractAndRatesService.syncContractAndRatesType mainResponse = new APT_SAP_SyncContractAndRatesService.syncContractAndRatesType();
        mainResponse.CustomerContract = cct;
        
        APT_SAP_SyncContractAndRatesService.syncContractAndRatesResponseType scarrt1 = new APT_SAP_SyncContractAndRatesService.syncContractAndRatesResponseType();
        scarrt1.ResponseCode = '';
        scarrt1.ResponseDescription = '';
        
        response.put('response_x', mainResponse);
*/        
   }

}