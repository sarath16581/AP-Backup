public class CaseMassUploadManager 
{
    public static String DATA_TYPE_TEXT = 'Text';
    public static String DATA_TYPE_NUMBER = 'Number';
    public static String DATA_TYPE_DATETIME = 'DateTime';
    public static String DATA_TYPE_DATE = 'Date';
    
    public static String DEFAULT_OWNER_QUEUE_NAME = 'SSSW Consumer Inbound';
    public static String DEFAULT_CASE_TYPE = 'General Enquiry';
    
    private static Integer TOKEN_SIZE_THRESHOLD = 2;
    
    public static String CASE_ORIGIN_MASS_UPLOAD = 'Bulk Upload';
    public static String CASE_ORIGIN_DECIPHA = 'AP Retail (PM26)';
    
    public static String TOO_MANY_ROWS_MESSAGE = 'If the CSV file has too many rows, please break it into small files with few rows (~100)';
    
    private static Map<String, CaseMassUploadFieldMappingSettings__c> settingsInternal;
    public static Map<String, CaseMassUploadFieldMappingSettings__c> Settings 
    {
        get
        {
            if (settingsInternal == null)
            {
                settingsInternal = CaseMassUploadFieldMappingSettings__c.getAll();
            }
            return settingsInternal;
        }

        set;
    }
    
    private static Group defaultOwnerInternal;
    public static Group DefaultOwner
    {
        get
        {
            List<Group> groups = [SELECT Id FROM Group WHERE Name = :DEFAULT_OWNER_QUEUE_NAME];
            if (groups.size() > 0)
            {
                defaultOwnerInternal = groups[0];
            }
            return defaultOwnerInternal;
        }
        
        set;
    }
    
    public static List<Case> createCases(Case proxyCase, String csv)
    {
        List<Case> cases = new List<Case>();
        Boolean isPortal = false;
        OpenCsvReader reader = new OpenCsvReader(new OpenCsvParser(), csv, '[\r\n]');
        List<List<String>> allRows = reader.readAll();
        System.debug('---All Rows Size: ' + allRows.size());
        CCUSettings__c bsp = CCUSettings__c.getInstance();
        system.debug(userInfo.getProfileId());
        system.debug(bsp.CCUCommunityUserProfileId__c);
        if(userInfo.getProfileId()==Id.valueOf(bsp.CCUCommunityUserProfileId__c)) {
            isPortal = true;
        }
        if (allRows.size() > 1) 
        {       
            List<String> headerRow = allRows.remove(0);
            
            System.debug('---headerRow: ' + headerRow);
            
            for (List<String> row : allRows)
            {
                System.debug('---row: ' + row);
                if (row.size() <= TOKEN_SIZE_THRESHOLD)//ignoring blank lines and lines with insufficient column data
                {
                    continue;
                }
                system.debug('**EachRow:'+row);
                Boolean flag = false;
                for(Integer i=0;i<row.size();i++) {
                    if(row[i] != '') {
                        flag = true;
                    }
                }
                if(flag) {
                    cases.add(createCase(proxyCase, headerRow, row, isPortal));
                } else {
                    throw new BulkUploadException('A few of the rows in CSV file do not have any data');
                }
            }
        }
        return cases;
    }
    
    public static Case createCase(Case proxyCase, List<String> headerRow, List<String> csvRow, Boolean isPortal)
    {
        Case c = proxyCase.clone(false, true);
        for (Integer i = 0; i < csvRow.size(); i++)
        {
            String value = csvRow.get(i);
            String columnName = headerRow.get(i);
            System.debug('---value:' + value);          
            System.debug('---columnName:' + columnName);
            
            if (value == null || value == '') 
            {
                continue;
            }
            
            CaseMassUploadFieldMappingSettings__c setting = Settings.get(columnName);
            
            System.debug('---setting:' + setting);
            
            if (setting != null) 
            {
                if (setting.DataType__c == DATA_TYPE_NUMBER)
                {
                    c.put(setting.SFDCFieldAPIName__c, parseNumber(value));
                }
                else if (setting.DataType__c == DATA_TYPE_DATETIME)
                {
                    c.put(setting.SFDCFieldAPIName__c, parseDateTime(value));
                }
                else if (setting.DataType__c == DATA_TYPE_DATE)
                {
                    c.put(setting.SFDCFieldAPIName__c, parsetDate(value));
                }
                else
                {
                    c.put(setting.SFDCFieldAPIName__c, value);
                }
            }
            if(!isPortal) {
                // All fields and the respective values are populated in Description
                String des = c.Description == null ? '' : c.Description ;
                des += columnName + ' : ' + value + '\n';
                c.Description = des;
            }
        }
        //ensure required fields get default value
        if (c.Type == null) 
        {
            c.Type = DEFAULT_CASE_TYPE;
        }
        System.debug('---Case:' + c);
        return c;
    }
    
    //assumes the date in dd/MM/yyyy format
    public static Date parsetDate(String s)
    {
        try 
        {
            String[] tokens = s.split('/');
            return Date.newInstance(Integer.valueOf(tokens[2]), Integer.valueOf(tokens[1]), Integer.valueOf(tokens[0]));
        }
        catch (Exception e)
        {
            return null;
        }
    }
    
    public static Decimal parseNumber(String s)
    {
        try 
        {
            return Decimal.valueOf(s);
        }
        catch (Exception e)
        {
            return null;
        }
    }
    
    public static DateTime parseDateTime(String s)
    {
        try 
        {
            return DateTime.valueOf(s);
        }
        catch (Exception e)
        {
            return null;
        }
    }
}