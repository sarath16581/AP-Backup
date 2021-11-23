@IsTest
public class AMEInitialResponse_Test {
    static testMethod void testParse() {
		String json = '{  '+
		'   \"id\":\"377eac5d-8871-4567-aad1-c38f3cc34858\",'+
		'   \"results\":[  '+
		'      {  '+
		'         \"id\":\"2403b1e8-4832-4d39-982f-95d706bdfb2d\",'+
		'         \"references\":[  '+
		''+
		'         ],'+
		'         \"addresses\":[  '+
		'            {  '+
		'               \"singleLine\":\"55 COLLINS RD LOCH VIC 3945\",'+
		'               \"score\":226.16925,'+
		'               \"dpid\":85865442,'+
		'               \"confidence\":\"LOW\"'+
		'            },'+
		'            {  '+
		'               \"singleLine\":\"55 COLLINS ST KIAMA NSW 2533\",'+
		'               \"score\":226.16925,'+
		'               \"dpid\":58460623,'+
		'               \"confidence\":\"LOW\"'+
		'            },'+
		'            {  '+
		'               \"singleLine\":\"55 COLLINS ST ENFIELD SA 5085\",'+
		'               \"score\":226.16925,'+
		'               \"dpid\":88605057,'+
		'               \"confidence\":\"LOW\"'+
		'            },'+
		'            {  '+
		'               \"singleLine\":\"55 COLLINS RD MELTON VIC 3337\",'+
		'               \"score\":226.16925,'+
		'               \"dpid\":95494763,'+
		'               \"confidence\":\"LOW\"'+
		'            },'+
		'            {  '+
		'               \"singleLine\":\"55 COLLINS PDE HACKHAM SA 5163\",'+
		'               \"score\":226.16925,'+
		'               \"dpid\":77886069,'+
		'               \"confidence\":\"LOW\"'+
		'            },'+
		'            {  '+
		'               \"singleLine\":\"55 COLLINS ST BELMORE NSW 2192\",'+
		'               \"score\":226.16925,'+
		'               \"dpid\":60954644,'+
		'               \"confidence\":\"LOW\"'+
		'            },'+
		'            {  '+
		'               \"singleLine\":\"55 COLLINS ST SUNBURY VIC 3429\",'+
		'               \"score\":226.16925,'+
		'               \"dpid\":76830952,'+
		'               \"confidence\":\"LOW\"'+
		'            },'+
		'            {  '+
		'               \"singleLine\":\"55 COLLINS RD ST IVES NSW 2075\",'+
		'               \"score\":226.16925,'+
		'               \"dpid\":30183561,'+
		'               \"confidence\":\"LOW\"'+
		'            },'+
		'            {  '+
		'               \"singleLine\":\"55 COLLINS RD YANDINA QLD 4561\",'+
		'               \"score\":226.16925,'+
		'               \"dpid\":68636744,'+
		'               \"confidence\":\"LOW\"'+
		'            },'+
		'            {  '+
		'               \"singleLine\":\"55 COLLINS ST CORRIMAL NSW 2518\",'+
		'               \"score\":226.16925,'+
		'               \"dpid\":71683068,'+
		'               \"confidence\":\"LOW\"'+
		'            }'+
		'         ]'+
		'      }'+
		'   ]'+
		'}';
		AMEInitialResponse obj = AMEInitialResponse.parse(json);
		System.assert(obj != null);
	}

}