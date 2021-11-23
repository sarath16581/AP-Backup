public class DAUsageAnalyzer {
    
    public DAUsageAnalyzer(){
        
        Pattern patternToSearch;
        Matcher matcherPattern;
        integer loopCounter = 4;
        List<CEPARC.ArchivaWrapperController.DataStorageUsageClass> UsageInfoList = new List<CEPARC.ArchivaWrapperController.DataStorageUsageClass>();
        String  dataStorageString;
        String requestUrl = '/setup/org/orgstorageusage.jsp?id=' + UserInfo.getOrganizationId() + '&setupid=CompanyResourceDisk';
        
        //Get the Storage Page, prepare to scrape
        PageReference pg = new PageReference( requestUrl );
        String htmlCode = '';
        if(!Test.isRunningTest()){
            htmlCode = pg.getContent().toString();
        }
        htmlCode = htmlCode.replace('\r\n', ' ');
        htmlCode = htmlCode.replace('\n', ' ');
        htmlCode = htmlCode.replace('\r', ' ');
        
        htmlCode = htmlCode.substring(0, 100000);
        
        System.debug('htmlCode'+JSON.serialize(htmlCode));
        
        integer i=0;
        
        patternToSearch = Pattern.compile('rappingClass -->(.*?)<!-- W');
        matcherPattern = patternToSearch.matcher(htmlCode);
        
        //System.debug('1----'+matcherPattern.find());
        //System.debug('2----'+matcherPattern.find()); 
        for(i = 0; i < 1; i++ ){
            
            if(matcherPattern.find() && i == 1) {//
                dataStorageString = htmlCode.substring(matcherPattern.start(), matcherPattern.end());
                pattern subPatternToSearch = Pattern.compile('-- ListRow --> (.*?) <!');
                matcher subMatcherPattern = subPatternToSearch.matcher(dataStorageString);
                
                while(subMatcherPattern.find() && loopCounter >= 0){
                    
                    CEPARC.ArchivaWrapperController.DataStorageUsageClass UsageInfo = new CEPARC.ArchivaWrapperController.DataStorageUsageClass();
                    String usageDetails = '';
                    String dataStorage = dataStorageString.substring(subMatcherPattern.start(), subMatcherPattern.end());
                    pattern subProPatternToSearch = Pattern.compile('dataCell  "><(.*?)</span>');
                    matcher subProMatcherPattern = subProPatternToSearch.matcher(dataStorage);
                    
                    if (subProMatcherPattern.find()) {
                        String dataString = dataStorage.substring(subProMatcherPattern.start(), subProMatcherPattern.end());
                        String str = dataString.substringBeforeLast('<');
                        UsageInfo.objLabel = str.substringAfterLast('>');
                    }
                    
                    if(UsageInfo.objLabel != 'DataArchiva Config'){// && !archivaUtilInstance.isCustomSetting(archivaUtilInstance.getObjAPIFromPluralName(UsageInfo.objLabel))
                        pattern subPro1PatternToSearch = Pattern.compile('<td class=" dataCell  numericalColumn">.*?</td>');
                        matcher subPro1MatcherPattern = subPro1PatternToSearch.matcher(dataStorage);
                        
                        String wholeString = '';
                        
                        While(subPro1MatcherPattern.find()){
                            
                            String data = dataStorage.substring(subPro1MatcherPattern.start(), subPro1MatcherPattern.end());
                            String innerStr = data.substringBeforeLast('<');
                            usageDetails = innerStr.substringAfterLast('>');
                            
                            if(true){
                                if(usageDetails.contains('B'))
                                    usageDetails = usageDetails.contains(',') ? usageDetails.replaceAll(',', '.')  : usageDetails;
                                if(!(usageDetails.contains('B')))
                                    usageDetails = usageDetails.contains('.') ? usageDetails.replaceAll('.', ',')  : usageDetails;        
                            }else if(false){
                                if(usageDetails.contains('B'))
                                    usageDetails = usageDetails.contains(',') ? usageDetails.replaceAll(',', '.')  : usageDetails;
                                if(!(usageDetails.contains('B')))
                                    usageDetails = usageDetails.contains('.') ? usageDetails.replaceAll('.', ',')  : usageDetails; 	
                                if(usageDetails.contains('%'))
                                    usageDetails = usageDetails.contains(' ') ? usageDetails.replaceAll(' ', '')  : usageDetails;
                            }else if(false){
                                if(usageDetails.contains('B'))
                                    usageDetails = usageDetails.contains(',') ? usageDetails.replaceAll(',', '.')  : usageDetails;
                                if(!(usageDetails.contains('B')))
                                    usageDetails = usageDetails.contains(' ') ? usageDetails.replaceAll(' ', ',')  : usageDetails; 
                            }else if(false){
                                if(usageDetails.contains('B'))
                                    usageDetails = usageDetails.contains(',') ? usageDetails.replaceAll(',', '.')  : usageDetails;
                                if(!(usageDetails.contains('B')))
                                    usageDetails = usageDetails.contains(' ') ? usageDetails.replaceAll(' ', ',')  : usageDetails; 
                                if(usageDetails.contains('%'))
                                    usageDetails = usageDetails.contains(' ') ? usageDetails.replaceAll(' ', '')  : usageDetails;
                            }else if(false){
                                if(!(usageDetails.contains('B')))
                                    usageDetails = usageDetails.contains(',,') ? usageDetails.replaceAll(',,', '')  : usageDetails; 
                                if(usageDetails.contains('%'))
                                    usageDetails = usageDetails.contains(' ') ? usageDetails.replaceAll(' ', '')  : usageDetails;
                            }
                            wholeString += usageDetails.contains(',') ? usageDetails.remove(',')+',' : usageDetails+ ',';
                        }
                        UsageInfo.objDetailStr = wholeString.removeEnd(',');
                        
                        UsageInfoList.add(UsageInfo);
                        loopCounter--;
                    }
                }
            }
        }
        System.debug('UsageInfoList---'+JSON.serialize(UsageInfoList));
    }

}