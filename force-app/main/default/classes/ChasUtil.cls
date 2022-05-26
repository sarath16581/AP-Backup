/**
 * Util class for CHAS
 * 2020-08-10 hara.sahoo@auspost.com.au Added convertToDateWithTimezoneFormat - Change made for roll out of Safe Drop feature on Missing Items form
 * 2021-04-19 hara.sahoo@auspost.com.au Added date calculations for EDD tracking and related contextual thank you pages
 * 2021-08-25 alex.volkov@auspost.com.au Added "---Enquiry Details---" line to comments to distinguish from case comments submitted by the customer
 * 2021-12-03 edgarallan.castillo3@auspost.com.au Updated case comment creation to use list of comments
 * 2021-12-06 alex.volkov@auspost.com.au Added support for mocks
 * 2022-01-27 hasantha.liyanage@auspost.com.au added null check for convertToDateWithTimezoneFormat()
 * 2022-05-25 hasantha.liyanage@auspost.com.au changed addDays method DDS-9786
 * */
public without sharing class ChasUtil {

    public static ChasUtil getInstance() {
        return (ChasUtil)Application.Utilities.getInstance(ChasUtil.class);
    }

    public static Consumer_Help_and_Support__c CHAS_SETTINGS {
        get {
            if(CHAS_SETTINGS == null) {
                return Consumer_Help_and_Support__c.getInstance();
            }
            return CHAS_SETTINGS;
        }
        set;
    }

    /**
     * get BusinessHours from the org setup
     * */
    public static BusinessHours  getBusinessHours()
    {
        BusinessHours bHours = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE] ;
        return bHours;
    }

    /**
        @Description : Returns the next business day considering the weekends and holidays
        @param : date dateSent(EDD derived from consignment service) , integer maxDays(days configured as the latest date by which consignments shoulf arrive)
        @return : NA
    */
    public static Date calculateNextBusinessDay(Date dateSent, Integer maxDays){
       // Id bHours = getBusinessHours().Id;
       // datetime nextbusinessDayVar = BusinessHours.nextStartDate(bHours, dateSent);
        Datetime maxDeliveryDate =  addDays(dateSent,maxDays);
        return maxDeliveryDate.date();
    }

    /**
     * Add business days to a given date based on the parameters passed
     * */
    public static Datetime addDays(Datetime startDate, Integer days) {
        Id bHours = getBusinessHours().Id;

        for (Integer elapsed = 0; elapsed < days; elapsed++) {
            //Add 1 day
            startDate = startDate.addDays(1);

            //Check if new date is within working days
            if (!BusinessHours.isWithin(bHours, startDate)) {
                //If new date is not within working days, get new working day
                startDate = BusinessHours.nextStartDate(bHours, startDate);
            }
        }
        return startDate;
    }

    /**
     * Check if the current date is within EDD and EDD+Business days
     * */
    public static Boolean isTheDateWithinEDDPlusBusinessdays(Date inputDate){
        Boolean isWithinEDDPlusBusinessdays = false;
        if(Date.today() > inputDate  && Date.today() <= ChasUtil.calculateNextBusinessDay(inputDate,CHAS_SETTINGS.nextUpdateInForLateItems__c != null ? Integer.valueOf(CHAS_SETTINGS.nextUpdateInForLateItems__c): 0))
        {
            isWithinEDDPlusBusinessdays = true;
        }
        return isWithinEDDPlusBusinessdays;
    }
    /**
     * Check if the current date is past EDD+Business days
     * */
    public static Boolean isTheDatePastEDDPlusBusinessdays(Date inputDate){
        Boolean isPastEDDPlusBusinessdays = false;
        if(Date.today() >= ChasUtil.calculateNextBusinessDay(inputDate,CHAS_SETTINGS.nextUpdateInForLateItems__c != null ? Integer.valueOf(CHAS_SETTINGS.nextUpdateInForLateItems__c): 0))
        {
            isPastEDDPlusBusinessdays = true;
        }
        return isPastEDDPlusBusinessdays;
    }
    /**
     * Check the input date with currentdate and return true if inputDate is Past otherwise true
     * */
    public static Boolean isTheDateIsPast(Date inputDate){
        Boolean isTheGivenDateIsPast = false;

        if(inputDate < Date.today()){
            isTheGivenDateIsPast = true;
        }
        return isTheGivenDateIsPast;
    }

    /**
     * Check the input date with currentdate and return true if inputDate is before the provided date otherwise true
     **/
    public static Boolean isTheDateIsBefore(Date inputDate){
        if(inputDate >= Date.today()){
            return true;
        }
        return false;
    }


    /**
     * Convert String Date(YYYYMMDD) to String Date YYYY-MM-DD
* */
    public static String convertToDateStrWithHyphenSeparator(String inputDate){
        String returnDateStr = null;
        try{
            returnDateStr = inputDate.substring(0,4)+'-'+inputDate.substring(4,6)+'-'+inputDate.substring(6,8);
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, 'ChasUtil:Error while parsing String date to string date');
        }
        return returnDateStr;
    }
    /**
     * Convert String 2020-06-30T07:18:46+10:00 to String Date YYYY-MM-DD
* */
    public static String convertToDateWithTimezoneFormat(String inputDate){
        String returnDateStr = null;
        try{
            if(String.isNotBlank(inputDate)) {
                returnDateStr = inputDate.substring(0, 4) + '-' + inputDate.substring(5, 7) + '-' + inputDate.substring(8, 10);
            }
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, 'ChasUtil:Error while parsing String date to string date');
        }
        return returnDateStr;
    }

    /**
     *
     * Format the date to the format "DD MMMM YYYY" eg: 30 August 2019
     * @param inputDate
     *
     * @return
     */
    public static String displayFormatted(String inputDate){
        String returnDateStr = null;
        try{
            // ensemble the date
            returnDateStr = inputDate.substring(6,8)+' '+getMonth(Integer.ValueOf(inputDate.substring(4,6)))+' '+inputDate.substring(0,4);

        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, 'ChasUtil:Error while parsing String date to string date format DD MMMM YYYY');
        }

        return returnDateStr;
    }

    /**
     * Get the month text by the passed month number
     *
     * @param iMonth
     *
     * @return
     */
    public static String getMonth(Integer iMonth) {
        // Get the 3-letter month name from month value
        if (iMonth == 1) {
            return 'January';
        } else if (iMonth == 2) {
            return 'February';
        } else if (iMonth == 3) {
            return 'March';
        } else if (iMonth == 4) {
            return 'April';
        } else if (iMonth == 5) {
            return 'May';
        } else if (iMonth == 6) {
            return 'June';
        } else if (iMonth == 7) {
            return 'July';
        } else if (iMonth == 8) {
            return 'August';
        } else if (iMonth == 9) {
            return 'September';
        } else if (iMonth == 10) {
            return 'October';
        } else if (iMonth == 11) {
            return 'November';
        } else if (iMonth == 12) {
            return 'December';
        }
        else {
            return '';
        }
    }

    /**
  * Convert String Date(DD/MM/YYYY or YYYY/MM/DD (any delimeter ., /, -)) to String Date YYYY-MM-DD
* */
    public static String convertToSFDateStrFormat(String inputDateStr){
        String returnDateStr = null;
        String dateDelimeter = null;
        try{

            //-- Getting delimter of a date String
            if(inputDateStr.contains('/')){
                dateDelimeter = '/';
            }else if(inputDateStr.contains('-')){
                dateDelimeter ='-';
            }else if(inputDateStr.contains('.')){
                dateDelimeter = '.';
            }else{
                System.debug(LoggingLevel.ERROR, 'inputDateStr is coming with invalid delimeter');
            }

            //-- splitteing the Date based n delimeter
            if(dateDelimeter != null){
                String[] dateElemnetsArray =null;

                if(dateDelimeter == '.'){
                    dateElemnetsArray =  inputDateStr.split('\\.');  //-- must escape .
                }else{
                    dateElemnetsArray =  inputDateStr.split(dateDelimeter);
                }

                Boolean isDateStartsWithYear = false;

                //-- identify date starts with Year or not
                if(dateElemnetsArray[0].length() > 2){
                    isDateStartsWithYear = true;
                }

                if(isDateStartsWithYear){
                    returnDateStr = dateElemnetsArray[0] +'-'+dateElemnetsArray[1]+'-'+dateElemnetsArray[2];
                }else{
                    returnDateStr = dateElemnetsArray[2] +'-'+dateElemnetsArray[1]+'-'+dateElemnetsArray[0];
                }
            }
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, 'ChasUtil:convertToSFDateStrFormat() - Error while parsing String date to string date');
        }

        return returnDateStr;
    }

    /**
* Create Casecomment from CaseId and commentBody
* */
    // public static String createCaseComment(String caseId, String commentBody){
    //     System.debug('--- createCaseComment --- START ---');
    //     commentBody = '---Enquiry Details---' + '\n' + commentBody;
    //     Flow.Interview.CreateCaseComment caseCommentFlow;
    //     Map<String, Object> myMap = new Map<String, Object>();
    //     myMap.put('InputCaseID',caseId);
    //     myMap.put('InputCaseDescription', commentBody);
    //     caseCommentFlow = new Flow.Interview.CreateCaseComment(myMap);
    //     caseCommentFlow.start();
    //     System.debug('*** Flow called - returning CaseNumber');

    //     System.debug('--- createCaseComment --- END ---');
    //     return (String)(caseCommentFlow.getVariableValue('CaseNumber'));
    // }

    /**
* Create Casecomment from CaseId and commentBody
* */
    public static String createCaseCommentAndReturnId(String caseId, String commentBody){

        commentBody = '---Enquiry Details---' + '\n' + commentBody;
        Flow.Interview.CreateCaseComment caseCommentFlow;
        Map<String, Object> myMap = new Map<String, Object>();
        myMap.put('InputCaseID',caseId);
        myMap.put('InputCaseDescription', commentBody);
        caseCommentFlow = new Flow.Interview.CreateCaseComment(myMap);
        caseCommentFlow.start();

        return (String)(caseCommentFlow.getVariableValue('CaseCommentID'));
    }
    /**
* Create Parse Case inserted results and create case comment
* */
    public static ChasApexController.CaseWrapper parseInsertedCaseResultsAndCreateComment(Database.SaveResult[] results, ChasApexController.CaseWrapper caseWrapperObj, List<CaseComment> comments) {
        Set<Id> vCaseIds = new Set<Id>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                try{
                    Id lObjectId = Id.valueOf(results[i].getId());
                    String objName = lObjectId.getSobjectType().getDescribe().getName();
                    //-- Creating Case Comment for inserted Case
                    if( objName.equalsIgnoreCase('Case')) {
                        ChasUtil.createCaseComment(lObjectId, comments);
                        vCaseIds.add(lObjectId);
                    }

                }catch(Exception ex) {
                    System.debug('*** - Error while retrieving Case Number/Creating Case Comment ==='+ex);
                }

            } else {
                caseWrapperObj.caseStatus = 'ERROR';
                System.debug('Error: could not create sobject '+ 'for array element ' + i + '.');
                System.debug('The error reported was: '+ results[i].getErrors()[0].getMessage() + '\n');

            }
        }

        caseWrapperObj.caseNumber = CasesSelector.newInstance().selectById(vCaseIds).get(new List<Id>(vCaseIds)[0]).CaseNumber;

        return caseWrapperObj;
    }

    /**
     * create a case comment with publish option
     * @author: edgarallan.castillo3@auspost.com.au
     * @param caseId: target case Id
     * @param commentBody: list of comments to create
     */
    public static void createCaseComment(Id caseId, List<CaseComment> comments)
    {
        for (CaseComment cc: comments) {
            cc.CommentBody = '---Enquiry Details---' + '\n' + cc.CommentBody;
            cc.ParentId = caseId;
        }
        try
        {
            ApplicationDatabase.getInstance().dmlInsert(comments);
        }
        catch (Exception e)
        {
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'CHAS', 'ChasApexController', 'createCaseComment', '', LoggingLevel.ERROR);
        }
    }

    /**
     * @param data sanitise a string passed in with html and javascript escapes
     *
     * @return
     */
    public static String sanitizeString(String data){
        try{
            data = data.escapeHtml4();
            data = data.escapeJava();
        } catch (Exception e) {
            // throws
        }
        return data;
    }
}