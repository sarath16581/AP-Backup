/***
 * @author George Nguyen
 * @date 2022-05-25
 * @group Utility
 * @tag Utility
 * @domain Core
 * @description A very simple selector class that provides string formatting capabilities
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
public with sharing class StringFormattingService {

    public static StringFormattingService getInstance() {
		return (StringFormattingService)Application.Utilities.getInstance(StringFormattingService.class);
	}

    @TestVisible
    Pattern compiledPattern {
        get{
            if(compiledPattern == null) {
                String regex = '^('
                    + '6104|614|04|'
                    + '6102|612|02|'
                    + '6103|613|03|'
                    + '6106|616|06|'
                    + '6107|617|07|'
                    + '6108|618|08'
                    + ')';
                compiledPattern = Pattern.compile(regex);
            }
            return compiledPattern;
        }
        set;
    }

    public String formatPhoneNumber(String phoneNumber) {
        String result = phoneNumber;
        if(phoneNumber != null) {
            phoneNumber = phoneNumber.replaceAll('[^\\d]', '');
            if(phoneNumber.startsWith('1300') || phoneNumber.startsWith('13') || phoneNumber.startsWith('1800')) {
                result = phoneNumber;
            } else {
                Matcher m = compiledPattern.matcher(phoneNumber);
                if(m.find()) {
                    String prefix = phoneNumber.substring(0, m.end());
                    result = '+61' + prefix.right(1) + phoneNumber.replaceFirst(prefix, '');
                }
            }
        }
        return result;
    }

}