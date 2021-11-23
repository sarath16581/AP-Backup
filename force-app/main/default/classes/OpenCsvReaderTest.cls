@isTest
private class OpenCsvReaderTest {

	private static OpenCsvReader createReaderSpecialCases() {
	
		OpenCsvParser.StringBuilder sb = new OpenCsvParser.StringBuilder();
		sb.append('a,b,c').append('\n'); // standard case
		sb.append('a,\"b,b,b\",c').append('\n'); // quoted elements
		sb.append(',,').append('\n'); // empty elements
		sb.append('a,\"PO Box 123,\nKippax,ACT. 2615.\nAustralia\",d.\n');
		sb.append('\"Glen \"\"The Man\"\" Smith\",Athlete,Developer\n'); // Test quoted quote chars
		sb.append('\"\"\"\"\"\",\"test\","c"\n'); // """""","test","c" representing: "", test, c
		sb.append('\"a\nb\",b,\"\nd\"\n');
		
		// These tests just use new line as the separator
		return new OpenCsvReader (new OpenCsvParser(), sb.asString(), '\n');
	}
	
	private static OpenCsvReader createReaderSimpleData() {
	
		OpenCsvParser.StringBuilder sb = new OpenCsvParser.StringBuilder();
		sb.append('\"ID\",\"ISDELETED\",\"NAME\"').append('\n');
		sb.append('\"a0iA0000000UTcgIAG\",\"false\",\"PB-2010-1\"').append('\n');
		sb.append('\"a0iA0000000UTchIAG\",\"false\",\"PB-2010-2\"').append('\n');
		sb.append('\"a0iA0000000UTciIAG\",\"false\",\"PB-2010-3\"').append('\n');
		sb.append('\"a0iA0000000UTcjIAG\",\"false\",\"PB-2010-4\"').append('\n');
		sb.append('\"a0iA0000000UTckIAG\",\"false\",\"PB-2010-5\"').append('\n');
		// There was a bug with trailing empty cells
		sb.append('\"\",\"\",\"\"').append('\n');
		
		// These tests just use new line as the separator
		return new OpenCsvReader (new OpenCsvParser(), sb.asString(), '\n');
	}
	
	/**
	* Tests iterating over a reader.
	*/
	@isTest
	static void testParseLineSpecialCases() {
	
		OpenCsvReader reader = createReaderSpecialCases();
		
		// test normal case
		String[] nextLine = reader.readNext();
		System.assertEquals('a', nextLine[0]);
		System.assertEquals('b', nextLine[1]);
		System.assertEquals('c', nextLine[2]);
		
		// test quoted commas
		nextLine = reader.readNext();
		System.assertEquals('a', nextLine[0]);
		System.assertEquals('b,b,b', nextLine[1]);
		System.assertEquals('c', nextLine[2]);
		
		// test empty elements
		nextLine = reader.readNext();
		System.assertEquals(3, nextLine.size());
		
		// test multiline quoted
		nextLine = reader.readNext();
		System.assertEquals(3, nextLine.size());
		
		// test quoted quote chars
		nextLine = reader.readNext();
		System.assertEquals('Glen \"The Man\" Smith', nextLine[0]);
		
		nextLine = reader.readNext();
		System.assertEquals('\"\"', nextLine[0]); // check the tricky situation
		System.assertEquals('test', nextLine[1]); // make sure we didn't ruin the next field...
		System.assertEquals('c', nextLine[2]);
		
		nextLine = reader.readNext();
		System.assertEquals(3, nextLine.size());
		
		//test end of stream
		System.assertEquals(null, reader.readNext());
	}
	
	/**
	* Test parsing to a list.
	*/
	@isTest
	static void testParseAllSpecialCases() {
	
		OpenCsvReader reader = createReaderSpecialCases();
		
		Integer start = Limits.getScriptStatements();
		List<List<String>> rows = reader.readAll();
		Integer finish = Limits.getScriptStatements();
		System.debug('ScriptStatements for testParseAllSpecialCases=' + (finish - start));
		
		String result = '';
		for (Integer r = 0; r < rows.size(); r++) {
			List<String> cols = rows.get(r);
			for (Integer c = 0; c < cols.size(); c++) {
				result += '[' + r + '][' + c + ']=[' + cols[c] + ']; ';
			}
			result += '\n';
			System.assertEquals(3, cols.size());
		}
		System.assertEquals(7, rows.size());
		
		System.debug('Result testParseAllSpecialCases=\n' + result);
	}
		
	@isTest
	static void testParseAllSimpleData() {
		
		OpenCsvReader reader = createReaderSimpleData();
		
		Integer start = Limits.getScriptStatements();
		List<List<String>> rows = reader.readAll();
		Integer finish = Limits.getScriptStatements();
		System.debug('ScriptStatements testParseAllSimpleData=' + (finish - start));
		
		String result = '';
		for (Integer r = 0; r < rows.size(); r++) {
			List<String> cols = rows.get(r);
			for (Integer c = 0; c < cols.size(); c++) {
				result += '[' + r + '][' + c + ']=[' + cols[c] + ']; ';
			}
			result += '\n';
			System.assertEquals(3, cols.size());
		}
		System.assertEquals(7, rows.size());
		
		System.debug('Result testParseAllSimpleData=\n' + result);
	}
}