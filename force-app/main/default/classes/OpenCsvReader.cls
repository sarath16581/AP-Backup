/**
Copyright 2005 Bytecode Pty Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/**
* A very simple CSV reader released under a commercial-friendly license.
*
* Java code Glen Smith.
* Apex port Keith Clarke.
*/
public class OpenCsvReader {

	private String[] csvLines;
	private Integer lineIndex = 0;
	private Boolean hasNext = true;
	private OpenCsvParser parser;
	
	public OpenCsvReader(OpenCsvParser parser, String entireCsvFile, String lineSeparator) {
		// Java code uses a BufferedReader so this port is fairly different...
		this.csvLines = csvLines = entireCsvFile.split(lineSeparator);
		this.parser = parser;
	}
	
	/**
	* Reads the entire file into a List with each element being a List of tokens.
	*
	* @return a List of List<String>, with each List<String> representing a line of the file.
	*/
	public List<List<String>> readAll() {
		List<List<String>> allElements = new List<List<String>>();
		while (hasNext) {
			List<String> nextLineAsTokens = readNext();
			if (nextLineAsTokens != null) {
				allElements.add(nextLineAsTokens);
			}
		}
		return allElements;
	}
	
	/**
	* Reads the next line and converts to a string list.
	*/
	public List<String> readNext() {
		List<String> result = null;
		do {
			String nextLine = getNextLine();
			if (!hasNext) {
				return result; // should throw if still pending?
			}
			List<String> r = parser.parseLineMulti(nextLine);
			if (result == null) {
				result = r;
			} else {
				result.addAll(r);
			}
		} while (parser.isPending());
		return result;
	}
	
	/**
	* Reads the next line from the file.
	*
	* @return the next line from the file without trailing newline
	*/
	private String getNextLine() {
		hasNext = lineIndex < csvLines.size();
		return hasNext ? csvLines[lineIndex++] : null;
	}
}