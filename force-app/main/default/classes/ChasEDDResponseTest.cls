/**
* @description Test class for ChasEDDResponse
* @date 2021-07-04
* @group Tests
* @tags Chas, H&S, EDD
* @domain Help and Support
* @changelog
*/
@isTest
public class ChasEDDResponseTest {
static testMethod void testParse() {
		String json = '{'+
		'    \"articles\": ['+
		'        {'+
		'            \"id\": \"33WNM000047501000605000\",'+
		'            \"href\": \"/consignment/v2/articles/33WNM000047501000605000\",'+
		'            \"estimatedDelivery\": {'+
		'                \"onDate\": \"2020-07-29T10:00:00+10:00\",'+
		'                \"expectedBetween\": {'+
		'                    \"fromDate\": \"2020-07-28T10:00:00+10:00\",'+
		'                    \"toDate\": \"2020-07-30T10:00:00+10:00\"'+
		'                }'+
		'            }'+
		'        }'+
		'    ]'+
		'}';
		ChasEDDResponse obj = ChasEDDResponse.parse(json);
		System.assert(obj != null);
        if(obj != null){
           ChasEDDResponse.consumeObject(System.JSON.createParser(json)) ;
        }
}
    
}