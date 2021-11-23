@IsTest
public class PUD_MPBPayloadClass_Test {
	static testMethod void testParse() {
		String json = '{'+
		' \"requestor\":{'+
		'    \"sourceSystem\":\"MPB\"'+
		' },'+
		' \"booking\":{'+
		'    \"customerNumber\":\"61935858\",'+
		'    \"billingAccountNumber\":\"213123123\",'+
		'    \"customerId\":\"0010w000007k52iAAA\",'+
		'    \"locationName\":\"Happy Hats Kew6\",'+
		'    \"dateVal\":\"2019-11-07\",'+
		'    \"startTime\":\"08:00:00\",'+
		'    \"endTime\":\"17:00:00\",'+
		'    \"contactPhone\":\"0444444443\",'+
		'    \"contactName\":\"Nick Jonas Sr\",'+
		'    \"contactEmail\":\"piggy5@example.com\",'+
		'    \"addressLine1\":\"L 6 436 ST KILDA RD\",'+
		'    \"city\":\"Melbourne\",'+
		'    \"postCode\":\"3004\",'+
		'    \"state\":\"VIC\",'+
		'    \"bookingComments\":\"Some instructions on delivery etc..\",'+
		'    \"depot\":\"445763\",'+
		'    \"revenueCheck\":true,'+
        '    \"articleCount\":\"4\",'+    
		'    \"articles\":['+
		'           {'+
		'               \"articleId\": \"99702060490201004562503\",'+
		'               \"length\": \"30\",'+
		'               \"width\": \"22\",'+
		'               \"height\": \"22\",'+
		'               \"weight\": \"14\",'+
		'               \"internationalOrDomestic\": \"DOMESTIC\",'+
		'               \"destinationPostCode\": \"4101\"'+
		'           },'+
		'           {'+
		'               \"articleId\": \"99702060484701004562507\",'+
		'               \"length\": \"30\",'+
		'               \"width\": \"22\",'+
		'               \"height\": \"22\",'+
		'               \"weight\": \"14\",'+
		'               \"internationalOrDomestic\": \"DOMESTIC\",'+
		'               \"destinationPostCode\": \"4101\"'+
		'           },'+
		'           {'+
		'               \"articleId\": \"99702060478701004562506\",'+
		'               \"length\": \"30\",'+
		'               \"width\": \"22\",'+
		'               \"height\": \"22\",'+
		'               \"weight\": \"14\",'+
		'               \"internationalOrDomestic\": \"DOMESTIC\",'+
		'               \"destinationPostCode\": \"4101\"'+
		'           },'+
		'           {'+
		'               \"articleId\": \"99702060465401004562501\",'+
		'               \"length\": \"30\",'+
		'               \"width\": \"22\",'+
		'               \"height\": \"22\",'+
		'               \"weight\": \"14\",'+
		'               \"internationalOrDomestic\": \"DOMESTIC\",'+
		'               \"destinationPostCode\": \"4101\"'+
		'           }'+
		'       ]'+
		' }'+
		'}';
		PUD_MPBPayloadClass obj = PUD_MPBPayloadClass.parse(json);
		System.assert(obj != null);
	}
}