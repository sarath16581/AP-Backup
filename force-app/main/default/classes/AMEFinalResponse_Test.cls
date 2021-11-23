/**
 * @description
 * Test methods for AMEFinalResponse
 * @group Tests
 * @domain Core
 * @changelog
 * 2021-09-28 - Ranjeewa Silva - Added tests to verify additional address fields exposed in the response.
 */
@IsTest
public class AMEFinalResponse_Test {
	static testMethod void testParse() {
			String json = '{'+
		'	\"id\": \"f69e077e-d1e3-445b-ac27-b12d1179da49\",'+
		'	\"results\": [{'+
		'		\"id\": \"c09052b8-bf3d-46f1-9695-597cff172165\",'+
		'		\"references\": [],'+
		'		\"addresses\": [{'+
		'			\"singleLine\": \"55 COLLINS RD LOCH VIC 3945\",'+
		'			\"score\": 1.0,'+
		'			\"semiStructured\": {'+
		'				\"addressLines\": [\"55 COLLINS RD\"],'+
		'				\"locality\": \"LOCH\",'+
		'				\"state\": \"VIC\",'+
		'				\"postcode\": \"3945\",'+
		'				\"countryName\": \"AUSTRALIA\",'+
		'				\"countryCode\": \"AU\"'+
		'			},'+
		'			\"deliveryData\": {'+
		'				\"postcodeDID\": \"3945\",'+
		'				\"localityDID\": 11873,'+
		'				\"groupDID\": 920032,'+
		'				\"roundDID\": 607506,'+
		'				\"sectionDID\": 2715885,'+
		'				\"dpid\": 85865442,'+
		'				\"sectionSequence\": 1090,'+
		'				\"deliveryPointSequence\": 1,'+
		'				\"deliveryOfficeRoundId\": 2056,'+
		'				\"phantom\": false,'+
		'				\"addressType\": \"THOROUGHFARE\",'+
		'				\"thoroughfareAddressType\": \"PRIMARY\",'+
		'				\"secondaryCount\": 0,'+
		'				\"deliveryPointCategory\": \"RESIDENTIAL\"'+
		'			},'+
		'			\"structured\": {'+
		'				\"locality\": \"LOCH\",'+
		'				\"state\": \"VIC\",'+
		'				\"postcode\": \"3945\",'+
		'				\"countryName\": \"AUSTRALIA\",'+
		'				\"countryCode\": \"AU\",'+
		'				\"thoroughfareName\": \"COLLINS\",'+
		'				\"thoroughfareNumber1\": \"55\",'+
		'				\"thoroughfareType\": \"RD\",'+
		'				\"deliveryPointIdentifier\": 85865442'+
		'			},'+
		'			\"upu\": {'+
		'				\"addressLines\": [\"55 COLLINS RD\", \"LOCH VIC 3945\"]'+
		'			},'+
		'			\"geoDataList\": [{'+
		'				\"featureType\": \"CENTROID\",'+
		'				\"latitude\": -38.41134491,'+
		'				\"longitude\": 145.64935712'+
		'			}],'+
		'			\"dpid\": 85865442,'+
		'			\"confidence\": \"HIGH\"'+
		'		}]'+
		'	}]'+
		'}';
		AMEFinalResponse obj = AMEFinalResponse.parse(json);
		System.assert(obj != null);
	}

	/**
	 * Tests the scenario when AME response does not contain the optional GNAF_FRONTAGE geo data
	 */
	@IsTest
	static void testParseResponseWithOnlyCentroidGeoData() {
		String json = '{'+
				'	\"id\": \"f69e077e-d1e3-445b-ac27-b12d1179da49\",'+
				'	\"results\": [{'+
				'		\"id\": \"c09052b8-bf3d-46f1-9695-597cff172165\",'+
				'		\"references\": [],'+
				'		\"addresses\": [{'+
				'			\"singleLine\": \"55 COLLINS RD LOCH VIC 3945\",'+
				'			\"score\": 1.0,'+
				'			\"semiStructured\": {'+
				'				\"addressLines\": [\"55 COLLINS RD\"],'+
				'				\"locality\": \"LOCH\",'+
				'				\"state\": \"VIC\",'+
				'				\"postcode\": \"3945\",'+
				'				\"countryName\": \"AUSTRALIA\",'+
				'				\"countryCode\": \"AU\"'+
				'			},'+
				'			\"deliveryData\": {'+
				'				\"postcodeDID\": \"3945\",'+
				'				\"localityDID\": 11873,'+
				'				\"groupDID\": 920032,'+
				'				\"roundDID\": 607506,'+
				'				\"sectionDID\": 2715885,'+
				'				\"dpid\": 85865442,'+
				'				\"sectionSequence\": 1090,'+
				'				\"deliveryPointSequence\": 1,'+
				'				\"deliveryOfficeRoundId\": 2056,'+
				'				\"phantom\": false,'+
				'				\"addressType\": \"THOROUGHFARE\",'+
				'				\"thoroughfareAddressType\": \"PRIMARY\",'+
				'				\"secondaryCount\": 0,'+
				'				\"sideOfStreetCode\": \"ANY\",'+
				'				\"deliveryPointCategory\": \"RESIDENTIAL\"'+
				'			},'+
				'			\"structured\": {'+
				'				\"locality\": \"LOCH\",'+
				'				\"state\": \"VIC\",'+
				'				\"postcode\": \"3945\",'+
				'				\"countryName\": \"AUSTRALIA\",'+
				'				\"countryCode\": \"AU\",'+
				'				\"thoroughfareName\": \"COLLINS\",'+
				'				\"thoroughfareNumber1\": \"55\",'+
				'				\"thoroughfareType\": \"RD\",'+
				'				\"deliveryPointIdentifier\": 85865442'+
				'			},'+
				'			\"upu\": {'+
				'				\"addressLines\": [\"55 COLLINS RD\", \"LOCH VIC 3945\"]'+
				'			},'+
				'			\"geoDataList\": [{'+
				'				\"featureType\": \"CENTROID\",'+
				'				\"latitude\": -38.41134491,'+
				'				\"longitude\": 145.64935712'+
				'			}],'+
				'			\"dpid\": 85865442,'+
				'			\"confidence\": \"HIGH\"'+
				'		}]'+
				'	}]'+
				'}';

		Test.startTest();

		AMEFinalResponse response = AMEFinalResponse.parse(json);
		System.assert(response != null, 'Expected to parse the json response.');
		System.assertNotEquals(null, response.results, 'Expected valid address results, but received null.');
		System.assertEquals(1, response.results.size(), 'Expected only one address result.');
		System.assertEquals(1, response.results[0].addresses.size(), 'Expected only one valid address');

		AMEFinalResponse.GeoDataList centroidGeo = response.results[0].addresses[0].getGeoData(AMEFinalResponse.GEO_FEATURE_TYPE_CENTROID);
		AMEFinalResponse.GeoDataList frontageGeo = response.results[0].addresses[0].getGeoData(AMEFinalResponse.GEO_FEATURE_TYPE_GNAF_FRONTAGE);

		Test.stopTest();

		System.assertEquals('85865442', response.results[0].addresses[0].dpid, 'Expected dpid not populated');
		System.assertEquals(1, response.results[0].addresses[0].geoDataList.size(), 'Expected geo data for only CENTROID');
		System.assertNotEquals(null, centroidGeo, 'Expected valid geo data for CENTROID');
		System.assertEquals(AMEFinalResponse.GEO_FEATURE_TYPE_CENTROID, centroidGeo.featureType, 'Expected geo data not returned for CENTROID.');
		System.assertEquals(null, frontageGeo, 'Expected null for frontage geo data as it is not returned from AME.');
	}

	/**
	 * Tests the scenario when AME response contains the optional GNAF_FRONTAGE geo data
	 */
	@IsTest
	static void testParseResponseWithAdditionalGeoData() {
		String json = '{'+
				'	\"id\": \"f69e077e-d1e3-445b-ac27-b12d1179da49\",'+
				'	\"results\": [{'+
				'		\"id\": \"c09052b8-bf3d-46f1-9695-597cff172165\",'+
				'		\"references\": [],'+
				'		\"addresses\": [{'+
				'			\"singleLine\": \"55 COLLINS RD LOCH VIC 3945\",'+
				'			\"score\": 1.0,'+
				'			\"semiStructured\": {'+
				'				\"addressLines\": [\"55 COLLINS RD\"],'+
				'				\"locality\": \"LOCH\",'+
				'				\"state\": \"VIC\",'+
				'				\"postcode\": \"3945\",'+
				'				\"countryName\": \"AUSTRALIA\",'+
				'				\"countryCode\": \"AU\"'+
				'			},'+
				'			\"deliveryData\": {'+
				'				\"postcodeDID\": \"3945\",'+
				'				\"localityDID\": 11873,'+
				'				\"groupDID\": 920032,'+
				'				\"roundDID\": 607506,'+
				'				\"sectionDID\": 2715885,'+
				'				\"dpid\": 85865442,'+
				'				\"sectionSequence\": 1090,'+
				'				\"deliveryPointSequence\": 1,'+
				'				\"deliveryOfficeRoundId\": 2056,'+
				'				\"phantom\": false,'+
				'				\"addressType\": \"THOROUGHFARE\",'+
				'				\"thoroughfareAddressType\": \"PRIMARY\",'+
				'				\"secondaryCount\": 0,'+
				'				\"sideOfStreetCode\": \"SAME\",'+
				'				\"deliveryPointCategory\": \"RESIDENTIAL\"'+
				'			},'+
				'			\"structured\": {'+
				'				\"locality\": \"LOCH\",'+
				'				\"state\": \"VIC\",'+
				'				\"postcode\": \"3945\",'+
				'				\"countryName\": \"AUSTRALIA\",'+
				'				\"countryCode\": \"AU\",'+
				'				\"thoroughfareName\": \"COLLINS\",'+
				'				\"thoroughfareNumber1\": \"55\",'+
				'				\"thoroughfareType\": \"RD\",'+
				'				\"deliveryPointIdentifier\": 85865442'+
				'			},'+
				'			\"upu\": {'+
				'				\"addressLines\": [\"55 COLLINS RD\", \"LOCH VIC 3945\"]'+
				'			},'+
				'			\"geoDataList\": [{'+
				'				\"featureType\": \"CENTROID\",'+
				'				\"latitude\": -38.41134491,'+
				'				\"longitude\": 145.64935712'+
				'			},{'+
				'				\"featureType\": \"GNAF_FRONTAGE\",'+
				'				\"latitude\": -38.88888888,'+
				'				\"longitude\": 145.99999999'+
				'			}],'+
				'			\"dpid\": 85865442,'+
				'			\"confidence\": \"HIGH\"'+
				'		}]'+
				'	}]'+
				'}';

		Test.startTest();

		AMEFinalResponse response = AMEFinalResponse.parse(json);
		System.assertNotEquals(null, response, 'Expected a valid response, but received null.');
		System.assertNotEquals(null, response.results, 'Expected valid address results, but received null.');
		System.assertEquals(1, response.results.size(), 'Expected only one address result.');
		System.assertEquals(1, response.results[0].addresses.size(), 'Expected only one valid address');

		AMEFinalResponse.GeoDataList centroidGeo = response.results[0].addresses[0].getGeoData(AMEFinalResponse.GEO_FEATURE_TYPE_CENTROID);
		AMEFinalResponse.GeoDataList frontageGeo = response.results[0].addresses[0].getGeoData(AMEFinalResponse.GEO_FEATURE_TYPE_GNAF_FRONTAGE);

		Test.stopTest();

		System.assertEquals('85865442', response.results[0].addresses[0].dpid, 'Expected dpid not populated');
		System.assertEquals(2, response.results[0].addresses[0].geoDataList.size(), 'Expected geo data for both CENTROID and GNAF_FRONTAGE to be returned');

		System.assertNotEquals(null, centroidGeo, 'Expected valid geo data for CENTROID');
		System.assertEquals(AMEFinalResponse.GEO_FEATURE_TYPE_CENTROID, centroidGeo.featureType, 'Expected geo data not returned for CENTROID.');

		System.assertNotEquals(null, frontageGeo, 'Expected valid geo data for GNAF_FRONTAGE');
		System.assertEquals(AMEFinalResponse.GEO_FEATURE_TYPE_GNAF_FRONTAGE, frontageGeo.featureType, 'Expected geo data not returned for GNAF_FRONTAGE.');
	}
}