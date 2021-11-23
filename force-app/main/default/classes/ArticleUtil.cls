/***
 * @description
 * @author
 * @date
 * @group
 * @tags Utility, Articles, Tracking, SAPEM, .net, TEAM
 * @domain
 * @changelog
 * 2020-04-04 - Nathan Franklin - Added getArticleTypes method to pull out details relating to each type of product retrievable via the tracking API interface
 * 2020-07-30 - Dheeraj Mandavilli - Refactored cntCodes query to fix SOQL101 issue.
 * 2021-08-24 - Steve Judd Modified SubscriptionModel query to refer to IsClosed
 */
public class ArticleUtil {
	public static Map<String, ArticleTypeMapping__mdt> articleTypeDefinitionsCache = new Map<String, ArticleTypeMapping__mdt>();

    public static void setCountryName(List<Article__c> articles) {
        Map<string, string> loadedCodes = new Map<string, string>();
        Map<id, Article__c> receivers = new Map<id, Article__c>();
        Map<id, Article__c> senders = new Map<id, Article__c>();
        for(Article__c a: articles){
            if(!string.isBlank(a.ReceiverCountry__c) && string.isBlank(a.ReceiverCountryName__c)) {
                if(loadedCodes.get(a.receiverCountry__c.trim()) == null){
                    loadedCodes.put(a.receiverCountry__c.trim(), '');
                }
                receivers.put(a.id, a);
            }

            if(!string.isBlank(a.SenderCountry__c) && string.isBlank(a.SenderCountryName__c)){
                if(loadedCodes.get(a.SenderCountry__c.trim()) == null){
                    loadedCodes.put(a.SenderCountry__c.trim(), '');
                }
                senders.put(a.id, a);
            }
        }
		//Refactored this query to fix SOQL 101 error.
		List<CountryCodes__c> cntCodes = [select Name, Alpha2__c from CountryCodes__c where Alpha2__c in :loadedCodes.keySet()];
        
        for(CountryCodes__c c:cntCodes){
            loadedCodes.put(c.Alpha2__c, c.Name);
        }


        for(Article__c a: receivers.values()){
            a.ReceiverCountryName__c = loadedCodes.get(a.ReceiverCountry__c.trim());
        }
        for(Article__c a: senders.values()){
            a.SenderCountryName__c = loadedCodes.get(a.SenderCountry__c.trim());
        }
    }

    public static void updateAddressesWithCountryNames(List<Article__c> articles) {
        for (Article__c a : articles) {
            a.SenderAddress__c = getUpdatedAddress(a.SenderAddress__c, a.SenderCountry__c, a.SenderCountryName__c);
            a.ReceiverAddress__c = getUpdatedAddress(a.ReceiverAddress__c, a.ReceiverCountry__c, a.ReceiverCountryName__c);
        }
    }

    private static String getUpdatedAddress(String address, String countryCode, String countryName) {
        if (String.isNotBlank(address) &&
                String.isNotBlank(countryCode) &&
                String.isNotBlank(countryName) &&
                address.endsWithIgnoreCase(',' + countryCode)) {
            return address.removeEndIgnoreCase(countryCode) + countryName;
        }
        return address;
    }

    private static Map<String, AdditionalServicesCodes__c> additionalServicesCodes
    {
        get
        {
            if (additionalServicesCodes == null)
            {
                additionalServicesCodes = AdditionalServicesCodes__c.getAll();
                additionalServicesCodes = additionalServicesCodes == null
                    ? new Map<String, AdditionalServicesCodes__c>()
                    : additionalServicesCodes;
            }
            return additionalServicesCodes;
        }
    }

    private static Map<String, CommunicationDecisionCodes__c> communicationDecisionCodes
    {
        get
        {
            if (communicationDecisionCodes == null)
            {
                communicationDecisionCodes = CommunicationDecisionCodes__c.getAll();
                communicationDecisionCodes = communicationDecisionCodes == null
                    ? new Map<String, CommunicationDecisionCodes__c>()
                    : communicationDecisionCodes;
            }
            return communicationDecisionCodes;
        }
    }

    private static Map<String, DeliveryPreferenceOptionCodes__c> deliveryPreferenceOptionCodes
    {
        get
        {
            if (deliveryPreferenceOptionCodes == null)
            {
                deliveryPreferenceOptionCodes = DeliveryPreferenceOptionCodes__c.getAll();
                deliveryPreferenceOptionCodes = deliveryPreferenceOptionCodes == null
                    ? new Map<String, DeliveryPreferenceOptionCodes__c>()
                    : deliveryPreferenceOptionCodes;
            }
            return deliveryPreferenceOptionCodes;
        }
    }

    private static Map<String, String> weekdays = new Map<String, String>
    {
        '1' => 'Monday',
        '2' => 'Tuesday',
        '3' => 'Wednesday',
        '4' => 'Thursday',
        '5' => 'Friday',
        '6' => 'Saturday',
        '7' => 'Sunday'
    };

    public static void setAdditionalServices(AuspostProductSchema.Services addSvc, Article__c a, List<TIBCOEventMessageWrapper> eventMessages)
    {
        String addSvcStr = '';
        Integer count = 1;

        if (addSvc != null && addSvc.ServiceCodeGroup != null)
        {
            for (AuspostProductSchema.ServiceCodeGroup_element svg : addSvc.ServiceCodeGroup)
            {
                if (svg.ServiceCodes != null)
                {
                    addSvcStr += 'Service code Group ' + (count++) + '\n';

                    for (AuspostProductSchema.ServiceCodes_element sce : svg.ServiceCodes)
                    {
                        if (additionalServicesCodes.containsKey(sce.ServiceCode) && sce.ServiceQualifier != null)
                        {
                            for (AuspostProductSchema.ServiceQualifier_element sqe : sce.ServiceQualifier)
                            {
                                addSvcStr += additionalServicesCodes.get(sce.ServiceCode).Description__c + ' : ';

                                if (sqe.ServiceAttributeName == 'NON_DL_DAY')
                                {
                                    addSvcStr += getWeekdays(sqe);
                                }
                                else if (sqe.ServiceAttributeName == 'EXP_DL_DAT')
                                {
                                    addSvcStr += getDates(sqe);
                                }
                                else if (sqe.ServiceAttributeName == 'EMBARGO')
                                {
                                    addSvcStr += getDates(sqe);
                                }
                                else if (sqe.ServiceAttributeName == 'DEL_DAY')
                                {
                                    addSvcStr += getWeekdays(sqe);
                                }
                                else if (sqe.ServiceAttributeName == 'DEL_DATE')
                                {
                                    addSvcStr += getDates(sqe);
                                }
                                else if (sqe.ServiceAttributeName == 'DEL_TIME')
                                {
                                    addSvcStr += getTimePeriods(sqe);
                                }
                                else if (sqe.ServiceAttributeName == 'REDIRECT')
                                {
                                    addSvcStr += 'Yes';
                                }
                                else if (sqe.ServiceAttributeName == 'UPL_DEL')
                                {
                                    addSvcStr += 'Yes';
                                    a.Notification__c = true;
                                }
                                else if (sqe.ServiceAttributeName == 'UPL_SIZE')
                                {
                                    addSvcStr += getServiceAttributeQualifier(sqe);
                                }
                                else if (sqe.ServiceAttributeName == 'UPL_EXP')
                                {
                                    addSvcStr += calculateUnattendedParcelLockerExpiry(eventMessages, getServiceAttributeQualifier(sqe));
                                }
                                else if (sqe.ServiceAttributeName == 'CSP_DEL')
                                {
                                    addSvcStr += 'Yes';
                                }
                                else if (sqe.ServiceAttributeName == 'CDP_DEL')
                                {
                                    addSvcStr += 'Yes';
                                    a.Notification__c = true;
                                }
                                else if (sqe.ServiceAttributeName == 'SURVEY_REQ')
                                {
                                    addSvcStr += getServiceAttributeQualifier(sqe);
                                }

                                addSvcStr += '\n';
                            }
                        }
                    }

                    addSvcStr += '\n';
                }
            }
        }

        a.AdditionalServices__c = addSvcStr;
    }

    public static void setAdditionalServices(Article__c a, List<TIBCOEventMessageWrapper> eventMessages)
    {
        if (a.AdditionalServicesPayload__c != null)
        {
            try
            {
                Dom.Document doc = new Dom.Document();
                doc.load(a.AdditionalServicesPayload__c);
                Dom.XmlNode root = doc.getRootElement();

                String addSvcStr  = '';
                Integer count = 1;
                for (Dom.XmlNode scg :root.getChildElements() )
                {
                    addSvcStr += 'Service code Group ' + (count++) + '\n';
                    for (Dom.XmlNode scs :scg.getChildElements() )
                    {
                        String serviceCode = scs.getChildElement('ServiceCode', scs.getNamespace()).getText();
                        if (additionalServicesCodes.containsKey(serviceCode))
                        {
                            for (Dom.XmlNode sq :scs.getChildElements())
                            {
                                if (sq.getName() == 'ServiceQualifier')
                                {
                                    addSvcStr += additionalServicesCodes.get(serviceCode).Description__c + ' : ';

                                    String svcAttrName = sq.getChildElement('ServiceAttributeName', sq.getNamespace()).getText();

                                    if (svcAttrName == 'NON_DL_DAY')
                                    {
                                        addSvcStr += getWeekdays(sq);
                                    }
                                    else if (svcAttrName == 'EXP_DL_DAT')
                                    {
                                        addSvcStr += getDates(sq);
                                    }
                                    else if (svcAttrName == 'EMBARGO')
                                    {
                                        addSvcStr += getDates(sq);
                                    }
                                    else if (svcAttrName == 'DEL_DAY')
                                    {
                                        addSvcStr += getWeekdays(sq);
                                    }
                                    else if (svcAttrName == 'DEL_DATE')
                                    {
                                        addSvcStr += getDates(sq);
                                    }
                                    else if (svcAttrName == 'DEL_TIME')
                                    {
                                        addSvcStr += getTimePeriods(sq);
                                    }
                                    else if (svcAttrName == 'REDIRECT')
                                    {
                                        addSvcStr += 'Yes';
                                    }
                                    else if (svcAttrName == 'UPL_DEL')
                                    {
                                        addSvcStr += 'Yes';
                                        a.Notification__c = true;
                                    }
                                    else if (svcAttrName == 'UPL_SIZE')
                                    {
                                        addSvcStr += getServiceAttributeQualifier(sq);
                                    }
                                    else if (svcAttrName == 'UPL_EXP')
                                    {
                                        addSvcStr += calculateUnattendedParcelLockerExpiry(eventMessages, getServiceAttributeQualifier(sq));
                                    }
                                    else if (svcAttrName == 'CSP_DEL')
                                    {
                                        addSvcStr += 'Yes';
                                    }
                                    else if (svcAttrName == 'CDP_DEL')
                                    {
                                        addSvcStr += 'Yes';
                                        a.Notification__c = true;
                                    }
                                    else if (svcAttrName == 'SURVEY_REQ')
                                    {
                                        addSvcStr += getServiceAttributeQualifier(sq);
                                    }

                                    addSvcStr += '\n';
                                }
                            }
                        }
                    }

                    addSvcStr += '\n';
                }

                a.AdditionalServices__c = addSvcStr;
            }
            catch (Exception e)
            {
                System.debug('---Error parsing additional services: ' + e);
            }
        }
    }

    public static void setContentsItems(AuspostMailProductSchema.ArticleContentsItemType[] contItems, Article__c a)
    {
        String contItemsStr = '';
        Integer count = 1;

        if (contItems != null)
        {
            for (AuspostMailProductSchema.ArticleContentsItemType ci : contItems)
            {
                contItemsStr += 'Contents Item ' + (count++) + '\n';
                contItemsStr += ci.Description != null ? 'Description: ' + ci.Description + '\n' : '';
                contItemsStr += ci.Weight != null ? 'Weight: ' + ci.Weight + '\n' : '';
                contItemsStr += ci.Quantity != null ? 'Quantity: ' + ci.Quantity + '\n' : '';
                contItemsStr += ci.UnitValue != null ? 'UnitValue: ' + ci.UnitValue + '\n' : '';
                contItemsStr += ci.Value != null ? 'Value: ' + ci.Value + '\n' : '';

                if (ci.InternationalContentsItemDetails != null)
                {
                    contItemsStr += ci.InternationalContentsItemDetails.ProductType != null
                        ? 'ProductType: ' + ci.InternationalContentsItemDetails.ProductType + '\n' : '';
                    contItemsStr += ci.InternationalContentsItemDetails.CountryOriginCode != null
                        ? 'CountryOriginCode: ' + ci.InternationalContentsItemDetails.CountryOriginCode + '\n' : '';
                    contItemsStr += ci.InternationalContentsItemDetails.HSTariff != null
                        ? 'HSTariff: ' + ci.InternationalContentsItemDetails.HSTariff + '\n' : '';
                    contItemsStr += ci.InternationalContentsItemDetails.ProductClassification != null
                        ? 'ProductClassification: ' + ci.InternationalContentsItemDetails.ProductClassification + '\n' : '';
                }
                contItemsStr += '\n';
            }
        }
        a.ContentsItems__c = contItemsStr;
    }

    public static void setContentsItems(Article__c a)
    {
        if (a.ContentsItemsPayload__c != null)
        {
            try
            {
                Dom.Document doc = new Dom.Document();
                doc.load(a.ContentsItemsPayload__c);
                Dom.XmlNode root = doc.getRootElement();

                String contItemsStr  = '';
                Integer count = 1;
                for (Dom.XmlNode xn :root.getChildElements() )
                {
                    contItemsStr += 'Contents Item ' + (count++) + '\n';
                    for (Dom.XmlNode xnc :xn.getChildElements() )
                    {
                        if (xnc.getName() == 'InternationalContentsItemDetails')
                        {
                            for (Dom.XmlNode xncc :xnc.getChildElements() )
                            {
                                contItemsStr += xncc.getName() + ': ' + xncc.getText() + '\n';
                            }
                        }
                        else
                        {
                            contItemsStr += xnc.getName() + ': ' + xnc.getText() + '\n';
                        }
                    }
                    contItemsStr += '\n';
                }
                a.ContentsItems__c = contItemsStr;
            }
            catch (Exception e)
            {
                System.debug('---Error parsing contents items: ' + e);
            }
        }
    }

    public static void setCommunicationDecisionDescription(Article__c a)
    {
        if (a.CustCommDecisionCode__c != null)
        {
            String cdDescriptions = '';
            String[] codes = a.CustCommDecisionCode__c.split('\\|');//separator is |
            for (String s : codes)
            {
                String d = ArticleUtil.getCommunicationDecisionDescription(s.trim());
                if (d != null)
                {
                    cdDescriptions += d + '\n';
                }
            }
            a.CustCommDecisionDescription__c = cdDescriptions;
        }
    }

    public static void setDeliveryPreferenceOptionDescription(Article__c a)
    {
        if (a.CustDelPrefOptionCode__c != null)
        {
            String dpDescriptions = '';
            String[] codes = a.CustDelPrefOptionCode__c.split('\\|');//separator is |
            for (String s : codes)
            {
                String d = ArticleUtil.getDeliveryPreferenceOptionDescription(s.trim());
                System.debug('---d ' + d);
                if (d != null)
                {
                    dpDescriptions += d + '\n';
                }
            }
            a.CustDelPrefDescription__c = dpDescriptions;
        }
    }

    public static void processContentsItems(Map<Id, Article__c> newMap, Map<Id, Article__c> oldMap)
    {
        for (Article__c newArticle : newMap.values())
        {
            Article__c oldArticle = oldMap.get(newArticle.Id);
            if (newArticle.ContentsItemsPayload__c != null && newArticle.ContentsItemsPayload__c != oldArticle.ContentsItemsPayload__c)
            {
                setContentsItems(newArticle);
            }
        }
    }

    public static void processAdditionalServices(Map<Id, Article__c> newMap, Map<Id, Article__c> oldMap)
    {
        Map<Id, List<TIBCOEventMessageWrapper>> articleEventMessages = new Map<Id, List<TIBCOEventMessageWrapper>>();
        for (EventMessage__c em : [SELECT Article__c, EventType__c, SenderID__c, ActualDateTime__c FROM EventMessage__c WHERE Article__c IN :newMap.values()] )
        {
            if (articleEventMessages.get(em.Article__c) == null)
            {
                articleEventMessages.put(em.Article__c, new List<TIBCOEventMessageWrapper>());
            }
            articleEventMessages.get(em.Article__c).add(new TIBCOEventMessageWrapper(em));
        }


        for (Article__c newArticle : newMap.values())
        {
            Article__c oldArticle = oldMap.get(newArticle.Id);
            if (newArticle.AdditionalServicesPayload__c != null && newArticle.AdditionalServicesPayload__c != oldArticle.AdditionalServicesPayload__c)
            {
                setAdditionalServices(newArticle, articleEventMessages.get(newArticle.Id));
            }
        }
    }

    public static void processCommunicationDecisions(Map<Id, Article__c> newMap, Map<Id, Article__c> oldMap)
    {
        for (Article__c newArticle : newMap.values())
        {
            Article__c oldArticle = oldMap.get(newArticle.Id);
            if (newArticle.CustCommDecisionCode__c != null && newArticle.CustCommDecisionCode__c != oldArticle.CustCommDecisionCode__c)
            {
                setCommunicationDecisionDescription(newArticle);
            }
        }
    }

    public static void processDeliveryPreferenceOptions(Map<Id, Article__c> newMap, Map<Id, Article__c> oldMap)
    {
        for (Article__c newArticle : newMap.values())
        {
            Article__c oldArticle = oldMap.get(newArticle.Id);
            if (newArticle.CustDelPrefOptionCode__c != null && newArticle.CustDelPrefOptionCode__c != oldArticle.CustDelPrefOptionCode__c)
            {
                setDeliveryPreferenceOptionDescription(newArticle);
            }
        }
    }

    public static String getCommunicationDecisionDescription(String code)
    {
        CommunicationDecisionCodes__c cdc = communicationDecisionCodes.get(code);
        return cdc != null ? cdc.Description__c : null;
    }

    public static String getDeliveryPreferenceOptionDescription(String code)
    {
        DeliveryPreferenceOptionCodes__c dpoc = deliveryPreferenceOptionCodes.get(code);
        return dpoc != null ? dpoc.Description__c : null;
    }

    private static String getWeekdays(AuspostProductSchema.ServiceQualifier_element sqe)
    {
        String wd = '';
        if (sqe.Weekday != null)
        {
            for (String s : sqe.Weekday)
            {
                wd += weekdays.get(s) + ', ';
            }
        }
        wd = removeAtEnd(wd, ', ');
        return wd;
    }

    private static String getWeekdays(Dom.XmlNode sq)
    {
        String wd = '';
        for (Dom.XmlNode cn : sq.getChildElements())
        {
            if (cn.getName() == 'Weekday')
            {
                wd += weekdays.get(cn.getText()) + ', ';
            }
        }
        wd = removeAtEnd(wd, ', ');
        return wd;
    }

    private static String getDates(AuspostProductSchema.ServiceQualifier_element sqe)
    {
        String dates = '';
        if (sqe.Date_x != null)
        {
            for (Date d : sqe.Date_x)
            {
                dates += d.format() + ', ';
            }
        }
        dates = removeAtEnd(dates, ', ');
        return dates;
    }

    private static String getDates(Dom.XmlNode sq)
    {
        String dates = '';
        for (Dom.XmlNode cn : sq.getChildElements())
        {
            if (cn.getName() == 'Date')
            {
                dates += cn.getText() + ', ';
            }
        }
        dates = removeAtEnd(dates, ', ');
        return dates;
    }

    private static String getServiceAttributeQualifier(AuspostProductSchema.ServiceQualifier_element sqe)
    {
        String saq = '';
        if (sqe.ServiceAttributeQualifier != null)
        {
            for (String s : sqe.ServiceAttributeQualifier)
            {
                saq += s + ', ';
            }
        }
        saq = removeAtEnd(saq, ', ');
        return saq;
    }

    private static String getServiceAttributeQualifier(Dom.XmlNode sq)
    {
        String saq = '';
        for (Dom.XmlNode cn : sq.getChildElements())
        {
            if (cn.getName() == 'ServiceAttributeQualifier')
            {
                saq += cn.getText() + ', ';
            }
        }
        saq = removeAtEnd(saq, ', ');
        return saq;
    }

    private static String getTimePeriods(AuspostProductSchema.ServiceQualifier_element sqe)
    {
        String tps = '';
        if (sqe.TimePeriod != null)
        {
            for (AuspostCommonSchema.TimePeriod tp : sqe.TimePeriod)
            {
                if (tp.StartTime != null)
                {
                    tps += 'StartTime = ' + tp.StartTime;
                }
                if (tp.EndTime != null)
                {
                    tps += ' EndTime = ' + tp.EndTime;
                }
                if (tp.Duration != null)
                {
                    tps += ' Duration = ' + tp.Duration;
                }
                tps += ', ';
            }
        }
        tps = removeAtEnd(tps, ', ');
        return tps;
    }

    private static String getTimePeriods(Dom.XmlNode sq)
    {
        String tps = '';
        for (Dom.XmlNode cn : sq.getChildElements())
        {
            if (cn.getName() == 'TimePeriod')
            {
                for (Dom.XmlNode cnn : cn.getChildElements())
                {
                    if (cnn.getName() == 'StartTime')
                    {
                        tps += 'StartTime = ' + cnn.getText();
                    }
                    if (cnn.getName() == 'EndTime')
                    {
                        tps += ' EndTime = ' + cnn.getText();
                    }
                    if (cnn.getName() == 'Duration')
                    {
                        tps += ' Duration = ' + cnn.getText();
                    }
                }
                tps += ', ';
            }
        }
        tps = removeAtEnd(tps, ', ');
        return tps;
    }

    private static String calculateUnattendedParcelLockerExpiry(List<TIBCOEventMessageWrapper> eventMessages, String expHours)
    {
        String res = expHours + ' hours after AFP-ER37 Mail Event with Sender ID PAA or PAAM';

        if (eventMessages != null && eventMessages.size() > 0)
        {
            DateTime dt = null;
            for (TIBCOEventMessageWrapper em : eventMessages)
            {
                if (em.proxyEM.EventType__c == 'AFP-ER37' && (em.proxyEM.SenderID__c == 'PAA' || em.proxyEM.SenderID__c == 'PAAM'))
                {
                    dt = em.proxyEM.ActualDateTime__c;
                    break;
                }
            }

            Integer h = 0;
            try {h = Integer.valueOf(expHours.trim());} catch (Exception e){System.debug('---Unattended Parcel Locker Expiry Error: ' + e);}

            if (dt != null)
            {
                dt = dt.addHours(h);
                res = dt.format('dd/MM/yyyy h:mm a');
            }
        }

        return res;
    }

    //removes one occurance of t at the end of s
    public static String removeAtEnd(String s, String t)
    {
        String res = s;
        if (s != null && t != null && s.endsWith(t))
        {
            res = s.substring(0, s.length() - t.length());
        }
        return res;
    }

    //Calculate consignment service type and product group based on the changes made on the article record. - David Catindoy (Aug 22, 2016)
    public static void serviceTypeCalculation(List<Article__c> newArticles, Map<Id, Article__c> oldArticles) {
        List<Article__c> validArt = new List<Article__c>();
        //Check if new article records.
        if(oldArticles.isEmpty()){
            for(Article__c newArt : newArticles){
                if(String.isNotBlank(newArt.ServiceCode__c) && String.isNotBlank(newArt.Customer_Type__c)){
                    validArt.add(newArt);
                }
            }
        }else{
            for(Article__c newArt : newArticles){
                Article__c oldArt = oldArticles.get(newArt.Id);
                if(String.isNotBlank(newArt.ServiceCode__c) && String.isNotBlank(newArt.Customer_Type__c) &&
                    (!newArt.ServiceCode__c.equals(oldArt.ServiceCode__c) || !newArt.Customer_Type__c.equals(oldArt.Customer_Type__c))){
                    validArt.add(newArt);
                }
            }
        }

        if(!validArt.isEmpty()){
            //Call method to perform service type and product group calculation.
            StarTrackUtil.calculateConsignmentServiceType(validArt);
        }
    }

    //Update related case records and/or LDC cases when specific consignment fields was changed. - David Catindoy (Aug 22, 2016)
    public static void updateRelatedCases(Map<Id, Article__c> newArticles, Map<Id, Article__c> oldArticles) {

        //Initialize container
        Map<Id, Id> caseIds = new Map<Id, Id>();
        Map<Id, Case> caseList = new Map<Id, Case>();

        newArticles = new Map<Id, Article__c>([SELECT Id, Last_Update_Type__c, Case__c, Freight_Amount__c, CID__c, (SELECT Id, Enquiry_Type__c, Status, Total_Amount_of_Claim__c, Delivery_Date__c FROM Cases__r WHERE Enquiry_Type__c =: StarTrack_Constants.CASE_ENQUIRY_LDC)
                                              FROM Article__c WHERE Id =: newArticles.keySet()]);

        for(Article__c newArt : newArticles.values()){
            Article__c oldArt = oldArticles.get(newArt.Id);
            //Check if case/last update type field was update on the consignment record.
            if(String.isNotBlank(newArt.Last_Update_Type__c) && newArt.Last_Update_Type__c.equals(StarTrack_Constants.CON_LASTUP_TYPE) && newArt.Case__c != null &&
                (!newArt.Last_Update_Type__c.equals(oldArt.Last_Update_Type__c) || !newArt.Case__c.equals(oldArt.Case__c))){
                caseIds.put(newArt.Case__c, newArt.Id);
                for(Case caseRec : newArt.Cases__r){
                    if(!StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status) && caseRec.Total_Amount_of_Claim__c == null){
                        //Update case total amount claim to matched with consignment freight amount.
                        caseRec.Total_Amount_of_Claim__c = newArt.Freight_Amount__c;
                        caseList.put(caseRec.Id, caseRec);
                    }
                }
            } else if(newArt.CID__c != oldArt.CID__c || newArt.Freight_Amount__c != oldArt.Freight_Amount__c){ //Check if CID/freight amount field was updated.
                for(Case caseRec : newArt.Cases__r){
                    if(!StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status)){
                        //Update case total amount claim and case delivery date to matched with consignment freight amount/CID.
                        caseRec.Delivery_Date__c = String.isNotBlank(newArt.CID__c) ? Date.valueOf(newArt.CID__c.left(4) + '-' + newArt.CID__c.mid(4, 2) + '-' + newArt.CID__c.right(2)) : null;
                        caseRec.Total_Amount_of_Claim__c = newArt.Freight_Amount__c;
                        caseList.put(caseRec.Id, caseRec);
                    }
                }
            }
        }

        for(Case caseRec : [SELECT Id, ArticleTest__c, Status, Enquiry_Type__c, Total_Amount_of_Claim__c FROM Case WHERE Id IN :caseIds.keySet()]){
            Id caseArtId = caseIds.get(caseRec.Id);
            //Check if current consignment id matched with the expected consignment id value and exclude closed cases.
            if(!caseArtId.equals(caseRec.ArticleTest__c) && !StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status)){
                caseRec.ArticleTest__c = caseArtId;
                if(StarTrack_Constants.CASE_ENQUIRY_LDC.equals(caseRec.Enquiry_Type__c)){
                    //If current case type is LDC, then make sure freight amount was copied from the parent consignment.
                    caseRec.Total_Amount_of_Claim__c = newArticles.get(caseArtId).Freight_Amount__c;
                }
                caseList.put(caseRec.Id, caseRec);
            }
        }

        if(!caseList.isEmpty()){
            //update all valid case records.
            Database.update(caseList.values());
        }
    }

    //Update Consignment depot based on consignment delivery type, receiver suburb, and receiver postcode. - David Catindoy (Aug 25, 2016)
    public static void consignmentDepotCalculation(Map<Id, Article__c> newArticles, Map<Id, Article__c> oldArticles) {
        newArticles = new Map<Id, Article__c>([SELECT Id, Receiver_Suburb__c, ReceiverPostcode__c, Service_Type__c, RecordType.Name, Network__c, Network__r.RecordType.DeveloperName FROM Article__c WHERE Id =: newArticles.keySet()]);
        //Initialize containers
        List<Article__c> validArt = new List<Article__c>();
        List<Article__c> invalidArt = new List<Article__c>();
        Map<Id, Article__c> comList = new Map<Id, Article__c>();

        //Check if new consignment records.
        if(oldArticles.isEmpty()){
            for(Article__c newArt : newArticles.values()){
                //Check if receiver suburb, receiver postcode and consignment service type is not blank. Also, check if record type is 'Consignment'.
                if(String.isNotBlank(newArt.Receiver_Suburb__c) && String.isNotBlank(newArt.ReceiverPostcode__c) && String.isNotBlank(newArt.Service_Type__c) && StarTrack_Constants.CON_REC_TYPE.equals(newArt.RecordType.Name)){
                    validArt.add(newArt);
                }
            }
        }else{ //All updated consignment records enter here.
            for(Article__c newArt : newArticles.values()){
                Article__c oldArt = oldArticles.get(newArt.Id);
                if(StarTrack_Constants.CON_REC_TYPE.equals(newArt.RecordType.Name)){
                    //Check if associated network was updated without updating receiver suburb, receiver postcode and consignment service type.
                    if((newArt.Receiver_Suburb__c == oldArt.Receiver_Suburb__c || newArt.ReceiverPostcode__c == oldArt.ReceiverPostcode__c || newArt.Service_Type__c == oldArt.Service_Type__c) && newArt.Network__c != oldArt.Network__c){
                        invalidArt.add(newArt);
                    //Check if either of the three (receiver suburb, receiver postcode, or consignment service type) was updated.
                    } else if(newArt.Receiver_Suburb__c != oldArt.Receiver_Suburb__c || newArt.ReceiverPostcode__c != oldArt.ReceiverPostcode__c || newArt.Service_Type__c != oldArt.Service_Type__c){
                        validArt.add(newArt);
                    }
                }
            }
        }

        if(!validArt.isEmpty()){
            //Call method to calculate expected consignment depot (network) based on the receiver suburb, postcode and service type.
            StarTrackUtil.calculateDepot(validArt);
            Database.update(validArt);
            comList.putAll(validArt);
        }

        if(!invalidArt.isEmpty()){
            comList.putAll(invalidArt);
        }

        if(!comList.isEmpty()){
            //Initialize local container
            Set<String> invalidStatus = new Set<String>{StarTrack_Constants.CASE_STAT_CLOSED, StarTrack_Constants.CASE_STAT_CLOSEDEXP, StarTrack_Constants.CASE_STAT_CLOSEDCV, StarTrack_Constants.CASE_STAT_CLOSED_PEN};
            Set<String> invalidRecType = new Set<String>{StarTrack_Constants.CASE_VOCINC_RT};
            List<Case> caseList = new List<Case>();

            for(Case caseRec : [SELECT Id, Status, Network__c, ArticleTest__c, LDC_System_Check__c, ArticleTest__r.Network__r.RecordType.DeveloperName, Enquiry_Type__c FROM Case WHERE ArticleTest__c IN :comList.keySet() AND Status NOT IN :invalidStatus AND RecordType.Name NOT IN : invalidRecType]){
                Article__c parentCon = comList.get(caseRec.ArticleTest__c);
                //If current case network matches with the parent consignment depot, then leave as it is. But if not, then update case network to copy depot of the parent consignment.
                if(caseRec.Network__c != parentCon.Network__c){
                    caseRec.Network__c = (StarTrack_Constants.CASE_ENQUIRY_LDC.equals(caseRec.Enquiry_Type__c) && caseRec.LDC_System_Check__c) ? caseRec.Network__c : parentCon.Network__c;
                    caseList.add(caseRec);
                }
            }

            if(!caseList.isEmpty()){
                //Update all valid case records.
                Database.update(caseList);
            }
        }
    }

    //Automate processes based on automation rule table. - David Catindoy (Created Date: Aug 25, 2016)
    //Used nested for-loop to cover complex logic
    public static void subscriptionModel(Map<Id, Article__c> newCons, Map<Id, Article__c> oldCons) {
        StarTrack_Settings__c customSetting = StarTrack_Settings__c.getOrgDefaults();

        if(String.isNotBlank(customSetting.StarTrack_Subscription_Profiles__c) && customSetting.StarTrack_Subscription_Profiles__c.containsIgnoreCase([SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name)){

            //Get accepted consignment summary status value.
            Set<String> conSummaryStat = StarTrack_Constants.CONSIGN_SUMSTATUS;
            Map<Id, Article__c> finalConMap = new Map<Id, Article__c>(); //Container to store valid consignment records.

            newCons = new Map<Id, Article__c>([SELECT Id, RecordType.Name, Name, Consignment_Summary_Status__c, (SELECT Id FROM Proof_of_Deliveries__r), (SELECT Id FROM Event_Messages__r WHERE RecordType.Name = 'StarTrack Delivery/ATL/NHCL/Manifest Event') FROM Article__c WHERE Id =: newCons.keySet()]);

            for(Article__c newCon : newCons.values()){
                Article__c oldCon = oldCons.get(newCon.Id);
                //Check if record type is 'Consignment', consignment summary status value is in the accepted values, and if the consignement summary status has been updated.
                if(StarTrack_Constants.CON_REC_TYPE.equals(newCon.RecordType.Name) &&
                    conSummaryStat.contains(newCon.Consignment_Summary_Status__c) && String.isNotBlank(newCon.Consignment_Summary_Status__c)){
                    finalConMap.put(newCon.Id, newCon);
                    System.debug('Consignment Number: ' + newCon.Name);
                }
            }

            if(!finalConMap.isEmpty()){
                //Query user-configured automation rules.
                List<StarTrack_Automation_Rule__c> stARList = [SELECT Id, Consignment_Summary_Status__c, Case_RecordType__c, Case_Type__c, Case_Purpose__c,
                                                               Case_Status__c, Case_Action__c, Case_Action_Value__c, Task_RecordType__c, RecordType.Name, RecordTypeId,
                                                               Task_Status__c, Task_Action__c, WE_Status__c, WE_Action__c, Order__c, Include_POD_Check__c
                                                               FROM StarTrack_Automation_Rule__c WHERE RecordType.Name = :StarTrack_Constants.SUBAUTO_RULEFUNC ORDER BY Order__c];

                //Query cases related to the consignment, including case related tasks and workflow email records.
                // MW0004540 changed query to refer to IsClosed
                Map<Id, Case> childCases = new Map<Id, Case>([SELECT Id, CaseNumber, ArticleTest__r.Name, ArticleTest__r.Consignment_Summary_Status__c, RecordType.Name, Enquiry_Type__c, Call_Purpose__c, Status, SuppliedEmail,
                                                             ArticleTest__c, ArticleTest__r.NumberofPODs__c, ArticleTest__r.Number_of_Delivery_Events__c, Description_of_contents__c, Description_of_packaging__c, Number_of_Items__c, Network__r.Name,
                                                             Subscription_Consign_Summary_Status__c, Exclude_Subscription_Automation__c, Related_Billing_Account__r.Is_POD_Required_to_Close_Case__c,
                                                             (SELECT Id, RecordType.Name, Status, WhatId, Waiting_for_Operations_Date__c, Acknowledged_Date__c, CreatedDate, Finished_Date__c, Operations_to_Acknowledged_Time__c, Operations_to_Finished_Time__c,
                                                             Create_to_Finished_Time__c, Resolution_Code__c, IsClosed FROM Tasks WHERE IsClosed = :StarTrack_Constants.ST_FALSE),
                                                             (SELECT Id, Status__c, Case__c FROM Workflow_Emails__r WHERE Status__c != :StarTrack_Constants.WFE_STATUS_CLOSE)
                                                             FROM Case WHERE ArticleTest__c IN :finalConMap.keySet() AND Status != :StarTrack_Constants.CASE_STAT_CLOSED AND Exclude_Subscription_Automation__c = :StarTrack_Constants.ST_FALSE]);

                if(!childCases.isEmpty()){
                    //Initialize containers
                    Map<Id, Boolean> caseApprovalStat = Approval.isLocked(new List<Id>(childCases.keySet())); // Check if case record/s is/was locked for approval.
                    Map<Id, String> caseActions = new Map<Id, String>();
                    List<Id> caseRejectApprovals = new List<Id>();
                    List<Case> caseList = new List<Case>();
                    List<CaseComment> commentList = new List<CaseComment>();
                    List<Task> taskRecords = new List<Task>();
                    List<workflow_Email__c> wfRecords = new List<workflow_Email__c>();
                    List<workflow_Email__c> newWFRecords = new List<workflow_Email__c>();

                    System.debug('Case List: ');
                    for(Case caseRec : childCases.values()){
                        System.debug('Consignment Number - ' + caseRec.ArticleTest__r.Name + ' - Case Number - ' + caseRec.CaseNumber + ' - Number of Tasks - ' + caseRec.Tasks.size());
                        System.debug('Consignment Number - ' + caseRec.ArticleTest__r.Name + ' - Case Number - ' + caseRec.CaseNumber + ' - Number of WF Email - ' + caseRec.Workflow_Emails__r.size());
                        if(!caseRec.ArticleTest__r.Consignment_Summary_Status__c.equalsIgnoreCase(caseRec.Subscription_Consign_Summary_Status__c)){
                            for(StarTrack_Automation_Rule__c stRule: stARList){
                                //Call method to check if current case field values matched with whatever specified in the automation rule table.
                                if(compareRec(stRule, caseRec, finalConMap.get(caseRec.ArticleTest__c))){
                                    System.debug('Status: Valid');
                                    caseRec.Subscription_Consign_Summary_Status__c = caseRec.ArticleTest__r.Consignment_Summary_Status__c;
                                    //Check if automation case action is to 'Close' case record.
                                    if(StarTrack_Constants.CASE_ACTCLOSED.equals(stRule.Case_Action__c)){
                                        if(caseApprovalStat.get(caseRec.Id) && !customSetting.Subscription_Include_Lock_Records__c){
                                            //Locked case record cannot be closed, instead post failure comment on the case.
                                           commentList.add(new CaseComment(CommentBody = StarTrack_Constants.FAILURE_COMMENT + stRule.Case_Action__c, ParentId = caseRec.Id));
                                        } else{
                                            //Specify required values for case closure.
                                            caseRec.Status = StarTrack_Constants.CASE_STAT_CLOSED;
                                            caseRec.ResolutionCode__c = String.isBlank(caseRec.ResolutionCode__c) ? StarTrack_Constants.CASE_RES_DEF : caseRec.ResolutionCode__c;
                                            caseRec.Call_Purpose__c = String.isBlank(caseRec.Call_Purpose__c) ? StarTrack_Constants.CASE_PURPOSE_DEF : caseRec.Call_Purpose__c;
                                            caseRec.Enquiry_Type__c = String.isBlank(caseRec.Enquiry_Type__c) ? StarTrack_Constants.CASE_ENQUIRY_DEF : caseRec.Enquiry_Type__c;
                                            caseActions.put(caseRec.Id, stRule.Case_Action__c);
                                        }
                                        caseList.add(caseRec);
                                    } else if(StarTrack_Constants.CASE_ACT_REJECTAPPROVAL.equals(stRule.Case_Action__c) && !caseApprovalStat.get(caseRec.Id)){
                                        //Add case comment to the case record that is not pending for approval.
                                        commentList.add(new CaseComment(CommentBody = StarTrack_Constants.FAILURE_COMMENT + stRule.Case_Action__c, ParentId = caseRec.Id));
                                        caseList.add(caseRec);
                                    } else if(StarTrack_Constants.CASE_ACT_UPDATESTAT.equals(stRule.Case_Action__c) && caseApprovalStat.get(caseRec.Id) && !customSetting.Subscription_Include_Lock_Records__c){
                                        //Locked case record cannot be updated, instead post failure comment on the case.
                                        commentList.add(new CaseComment(CommentBody = StarTrack_Constants.FAILURE_COMMENT + stRule.Case_Action__c, ParentId = caseRec.Id));
                                        caseList.add(caseRec);
                                    } else if(StarTrack_Constants.CASE_ACTSENDEMAIL.equals(stRule.Case_Action__c) && caseApprovalStat.get(caseRec.Id) && !customSetting.Subscription_Include_Lock_Records__c){
                                        //Locked case record cannot be processed for email sending, instead post failure comment on the case.
                                        commentList.add(new CaseComment(CommentBody = StarTrack_Constants.FAILURE_COMMENT + stRule.Case_Action__c, ParentId = caseRec.Id));
                                        caseList.add(caseRec);
                                    } else{
                                        //Check if automation case action is to 'Send email'.
                                        if(StarTrack_Constants.CASE_ACTSENDEMAIL.equals(stRule.Case_Action__c) && String.isNotBlank(caseRec.SuppliedEmail)){
                                            //Create new child WF email record.
                                            workflow_Email__c wfe = new workflow_Email__c(Case__c = caseRec.Id, Status__c = StarTrack_Constants.WFE_STATUS_OPEN, Task_Description__c = stRule.Case_Action_Value__c, Task_Subject__c = stRule.Case_Action_Value__c,
                                                                                          Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING, Workflow_Email_Alert__c = stRule.Case_Action_Value__c, To_Address__c = caseRec.SuppliedEmail,
                                                                                          Name = String.isNotBlank(caseRec.ArticleTest__c) ? caseRec.ArticleTest__r.Name + ' - ' + stRule.Case_Action_Value__c : stRule.Case_Action_Value__c,
                                                                                          Consignment_Number__c = String.isNotBlank(caseRec.ArticleTest__c) ? caseRec.ArticleTest__r.Name : '', Enquiry_Type__c = caseRec.Enquiry_Type__c,
                                                                                          Case_Number__c = caseRec.CaseNumber, Description_Of_Contents__c = caseRec.Description_of_contents__c, Description_Of_Packaging__c = caseRec.Description_of_packaging__c,
                                                                                          Number_of_Items__c = String.valueOf(caseRec.Number_of_Items__c), Network_Name__c = caseRec.Network__r.Name);
                                            newWFRecords.add(wfe);
                                            caseActions.put(caseRec.Id, stRule.Case_Action__c);
                                            caseList.add(caseRec);
                                        }
                                        //Check if automation case action is to 'Create comment' and associated it to case record.
                                        if(StarTrack_Constants.CASE_ACTCOMMENT.equals(stRule.Case_Action__c)){
                                            //Initialize new case comment and specify current case record as the parent.
                                            commentList.add(new CaseComment(CommentBody = String.isNotBlank(stRule.Case_Action_Value__c) ? stRule.Case_Action_Value__c : StarTrack_Constants.Global_NA, ParentId = caseRec.Id));
                                            caseList.add(caseRec);
                                        }

                                        //Check if case action is "Reject Approval"
                                        if(StarTrack_Constants.CASE_ACT_REJECTAPPROVAL.equals(stRule.Case_Action__c)){
                                            caseRejectApprovals.add(caseRec.Id);
                                            caseActions.put(caseRec.Id, stRule.Case_Action__c);
                                            caseList.add(caseRec);
                                        }

                                        //Check if case action is "Update Status"
                                        if(StarTrack_Constants.CASE_ACT_UPDATESTAT.equals(stRule.Case_Action__c) && String.isNotBlank(stRule.Case_Action_Value__c)){
                                            //Clone case record to preserve the current field values.
                                            Case tempCase = caseRec.clone(true, true, true, true);
                                            tempCase.Status =  stRule.Case_Action_Value__c;
                                            caseList.add(tempCase);
                                            caseActions.put(tempCase.Id, stRule.Case_Action__c);
                                        }

                                        if(!caseRec.Tasks.isEmpty()){
                                            //Add all case related tasks to the container.
                                            taskRecords.addAll(caseRec.Tasks);
                                        }
                                        if(!caseRec.Workflow_Emails__r.isEmpty()){
                                            //Add all case related workkflow email records to the container.
                                            wfRecords.addAll(caseRec.Workflow_Emails__r);
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    }

                    if(!taskRecords.isEmpty()){
                        //Initialize local container
                        List<Task> taskList = new List<Task>();
                        for(Task taskRec : taskRecords){
                            Case caseRec = childCases.get(taskRec.WhatId);
                            for(StarTrack_Automation_Rule__c stRule: stARList){
                                // Check current task field values and matched against automation rule table.
                                if(compareRec(stRule, caseRec, finalConMap.get(caseRec.ArticleTest__c)) && (String.isNotBlank(stRule.Task_RecordType__c) ? stRule.Task_RecordType__c.equals(taskRec.RecordType.Name) : true) &&
                                  (String.isNotBlank(stRule.Task_Status__c) ? stRule.Task_Status__c.equals(taskRec.Status) : true) && (String.isNotBlank(stRule.Case_Action__c) ? !stRule.Case_Action__c.equals(StarTrack_Constants.CASE_ACTCLOSED) : true)){
                                    //Check if specified task action is to 'Close' task record.
                                    if(StarTrack_Constants.TASK_ACTFINISHED.equals(stRule.Task_Action__c)){
                                        taskList.add(taskRec);
                                    }
                                    break;
                                }
                            }
                        }

                        if(!taskList.isEmpty()){
                            //Call method to close all tasks specified in the parameter.
                           StarTrackUtil.closeCaseTask(taskList);
                        }
                    }

                    if(!wfRecords.isEmpty()){
                        //Initialize local container
                        List<workflow_Email__c> wfList = new List<workflow_Email__c>();
                        for(workflow_Email__c wfRec : wfRecords){
                            Case caseRec = childCases.get(wfRec.Case__c);
                            for(StarTrack_Automation_Rule__c stRule: stARList){
                                // Check current workflow email field values and matched against automation rule table.
                                if(compareRec(stRule, caseRec, finalConMap.get(caseRec.ArticleTest__c)) && (String.isNotBlank(stRule.WE_Status__c) ? stRule.WE_Status__c.equals(wfRec.Status__c) : true) &&
                                  (String.isNotBlank(stRule.Case_Action__c) ? !stRule.Case_Action__c.equals(StarTrack_Constants.CASE_ACTCLOSED) : true)){
                                    //Check if specified WF email action is to 'Close' workflow email record.
                                    if(StarTrack_Constants.WF_ACTCLOSED.equals(stRule.WE_Action__c)){
                                        wfList.add(wfRec);
                                    }
                                    break;
                                }
                            }
                        }

                        if(!wfList.isEmpty()){
                            //Call method to close all workflow email records specified in the parameter.
                           StarTrackUtil.closeCaseWF(wfList);
                        }
                    }

                    if(!caseList.isEmpty()){
                        //Initialize container.
                        List<CaseComment> failedCasesComment = new List<CaseComment>();
                        // DML statement
                        List<Database.SaveResult> srList = Database.update(caseList, false); //Update all valid case records.

                        // Iterate through each returned result
                        for (Database.SaveResult sr : srList) {
                            if(caseActions.containsKey(sr.getId())){
                                if (!sr.isSuccess()) {
                                    // Operation was unsuccessful, so post comment to the record that was not processed successfully.
                                    failedCasesComment.add(new CaseComment(CommentBody = StarTrack_Constants.FAILURE_COMMENT + caseActions.get(sr.getId()), ParentId = sr.getId()));
                                } else{
                                    if(StarTrack_Constants.CASE_ACTCLOSED.equals(caseActions.get(sr.getId()))){
                                        Case caseDetail = childCases.get(sr.getId());
                                        String commentString = StarTrack_Constants.CASECLOSE_SUCCESS_COMMENT;
                                        commentString = commentString.replace('<ConsignSumStat>', caseDetail.Subscription_Consign_Summary_Status__c);
                                        commentString = commentString.replace('<NumofPODs>', String.valueOf(finalConMap.get(caseDetail.ArticleTest__c).Proof_of_Deliveries__r.size()));
                                        commentString = commentString.replace('<NumofEvents>', String.valueOf(finalConMap.get(caseDetail.ArticleTest__c).Event_Messages__r.size()));
                                        commentString = commentString.replace('<CaseRecType>', caseDetail.RecordType.Name);
                                        commentString = commentString.replace('<CaseType>', caseDetail.Enquiry_Type__c);
                                        commentString = commentString.replace('<CasePurpose>', caseDetail.Call_Purpose__c);
                                        commentString = commentString.replace('<CaseStat>', caseDetail.Status);
                                        commentString = commentString.replace('<IsPODReq>', caseDetail.Related_Billing_Account__r.Is_POD_Required_to_Close_Case__c ? 'Yes' : 'No');
                                        commentList.add(new CaseComment(CommentBody = commentString, ParentId = sr.getId()));
                                    } else{
                                        commentList.add(new CaseComment(CommentBody = StarTrack_Constants.SUCCESS_COMMENT + caseActions.get(sr.getId()), ParentId = sr.getId()));
                                    }
                                }
                            }
                        }

                        System.debug('Case Update Failed - Number of Cases - ' + failedCasesComment.size());

                        if(!failedCasesComment.isEmpty()){
                            //Insert failed cases comment.
                            Database.insert(failedCasesComment);
                        }
                    }

                    if(!caseRejectApprovals.isEmpty()){
                        List<Approval.ProcessWorkitemRequest> reqList = rejectApprovalRecords(caseRejectApprovals); //Call method to create list of work item requests based on the case ids listed in the caseRejectApprovals container/variable.

                        //Check if request list is not empty.
                        if(!reqList.isEmpty()){
                            List<Approval.ProcessResult> resultList =  Approval.process(reqList); //Submit request list to be processed.
                        }
                    }

                    if(!newWFRecords.isEmpty()){
                        // DML statement
                        Database.insert(newWFRecords); //Insert WF email records.
                    }

                    if(!commentList.isEmpty()){
                        //Insert all new case comments.
                        Database.insert(commentList);
                    }
                }
            }
        }
    }

    //This method is used to match case field values against the automation rule table. - David Catindoy (CreatedDate: Aug 25, 2016)
    public static Boolean compareRec(StarTrack_Automation_Rule__c stRule, Case caseRec, Article__c caseCon){

        //Andrew Judd 06-Jan-2017 - Bug 1557 - Added condition to ensure number of delivery events > 0 if POD is required to close case
        if((String.isNotBlank(stRule.Consignment_Summary_Status__c) ? stRule.Consignment_Summary_Status__c.equalsIgnoreCase(caseRec.ArticleTest__r.Consignment_Summary_Status__c) : true) &&
           (String.isNotBlank(stRule.Case_RecordType__c) ? stRule.Case_RecordType__c.equals(caseRec.RecordType.Name) : true) &&
           (String.isNotBlank(stRule.Case_Type__c) ? stRule.Case_Type__c.equals(caseRec.Enquiry_Type__c) : true) && (String.isNotBlank(stRule.Case_Purpose__c) ? stRule.Case_Purpose__c.equals(caseRec.Call_Purpose__c) : true) &&
           (String.isNotBlank(stRule.Case_Status__c) ? stRule.Case_Status__c.equals(caseRec.Status) : true) &&
           (stRule.Include_POD_Check__c ? (caseRec.Related_Billing_Account__r.Is_POD_Required_to_Close_Case__c ? ((caseCon.Proof_of_Deliveries__r.size() >=  caseCon.Event_Messages__r.size()) && caseCon.Event_Messages__r.size() > 0) : true) : true)){
           return true;
        }
        return false;
    }

    //Create a list of approval process work item requests based on the list of case ids passed in the parameter.
    public static List<Approval.ProcessWorkitemRequest> rejectApprovalRecords(List<Id> caseIds){
        List<Approval.ProcessWorkitemRequest> reqList = new List<Approval.ProcessWorkitemRequest>();
        Map<Id, Id> caseToWorkItems = getWorkItemIds(caseIds); //Call method to retrieve process instance work item id associated to the case record.
        for(Id caseId : caseToWorkItems.keySet()){
            //Initialize single process work item request.
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments(StarTrack_Constants.SUB_REJECTAPPROVAL_COMMENT);
            req.setAction(StarTrack_Constants.REJECT_APPROVAL);
            req.setWorkitemId(caseToWorkItems.get(caseId));
            reqList.add(req);
        }
        //Return list of work item request.
        return reqList;
    }

    //Retrieve list of process instance work items associated to the list of case ids passed in the parameter.
    public static Map<Id, Id> getWorkItemIds(List<Id> targetObjectIds){
        //Initialize container
        Map<Id, Id> caseToWorkItems = new Map<Id, Id>();
        //Loop to the list of process instance work item/s retrieved in the query.
        for(ProcessInstanceWorkitem workItem  : [SELECT Id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId IN :targetObjectIds]){
            //Add work item details on the map container.
            caseToWorkItems.put(workItem.ProcessInstance.TargetObjectId, workItem.Id);
        }
        return caseToWorkItems;
    }

    /**
     * Grab the specific details about a single article type and it's attributes.
     */
    public static ArticleTypeMapping__mdt getArticleType(String articleType) {
        return getArticleTypes().get(articleType);
    }

    /**
     * Grab the details about all the article types and their attributes used in various display ui and automation and ui presentation in Salesforce.
     * TODO: Does this need platform cache?
     */
    public static Map<String, ArticleTypeMapping__mdt> getArticleTypes() {
        // see if this data was already requested in this transaction
        if(!articleTypeDefinitionsCache.isEmpty()) {
            return articleTypeDefinitionsCache;
        }

        Map<String, ArticleTypeMapping__mdt> output = new Map<String, ArticleTypeMapping__mdt>();
        for(ArticleTypeMapping__mdt record : [Select Label, DeveloperName, BackgroundColour__c, ForegroundColour__c, Mapping__c
                                                From ArticleTypeMapping__mdt]) {
            output.put(record.Mapping__c, record);
        }

        // add to transaction cache
        articleTypeDefinitionsCache = output;

        return output;
    }

}