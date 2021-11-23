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
* A very simple CSV parser released under a commercial-friendly license.
* This just implements splitting a single line into fields.
*
* Java code Glen Smith, Rainer Pruy
* Apex port Keith Clarke
*/
public class OpenCsvParser {

	public class OpenCsvParserException extends Exception {
	}
	
	/** Make public just for tests. */
	public class StringBuilder {
		private String s = '';
		public StringBuilder append(String other) {
			s += other;
			return this;
		}
		public Integer length() {
			return s.length();
		}
		public String asString() {
			return s;
		}
	}
	
	private static final Set<String> WHITESPACE = new Set<String>{' ', '\t', '\n', '\r'};
	
	private final String separator;
	private final String quote;
	private final String escape;
	private final Boolean strictQuotes;
	private String pending;
	private Boolean inField = false;
	private final Boolean ignoreLeadingWhiteSpace;
	
	/** The default separator to use if none is supplied to the constructor. */
	public static final String DEFAULT_SEPARATOR = ',';
	
	/** The default quote Stringacter to use if none is supplied to the constructor. */
	public static final String DEFAULT_QUOTE_CHARACTER = '"';
	
	/** The default escape character to use if none is supplied to the constructor. */
	public static final String DEFAULT_ESCAPE_CHARACTER = '\\';
	
	/** The default strict quote behavior to use if none is supplied to the constructor */
	public static final Boolean DEFAULT_STRICT_QUOTES = false;
	
	/** The default leading whitespace behavior to use if none is supplied to the constructor */
	public static final Boolean DEFAULT_IGNORE_LEADING_WHITESPACE = true;
	
	/**
	* Constructs OpenCsvParser using defaults.
	*/
	public OpenCsvParser() {
		this(DEFAULT_SEPARATOR, DEFAULT_QUOTE_CHARACTER, DEFAULT_ESCAPE_CHARACTER,
		DEFAULT_STRICT_QUOTES, DEFAULT_IGNORE_LEADING_WHITESPACE);
	}
	
	/**
	* Constructs OpenCsvParser with supplied separator and quote String.
	* Allows setting the "strict quotes" and "ignore leading whitespace" flags
	* @param separator
	* the delimiter to use for separating entries
	* @param quote
	* the character to use for quoted elements
	* @param escape
	* the character to use for escaping a separator or quote
	* @param strictQuotes
	* if true, characters outside the quotes are ignored
	* @param ignoreLeadingWhiteSpace
	* if true, white space in front of a quote in a field is ignored
	*/
	public OpenCsvParser(String separator, String quote, String escape,
			Boolean strictQuotes, Boolean ignoreLeadingWhiteSpace) {
		this.separator = separator;
		this.quote = quote;
		this.escape = escape;
		this.strictQuotes = strictQuotes;
		this.ignoreLeadingWhiteSpace = ignoreLeadingWhiteSpace;
	}
	
	/**
	* @return true if something was left over from last call(s)
	*/
	public Boolean isPending() {
		return pending != null;
	}
	
	public String[] parseLineMulti(String nextLine) {
		return parseLine(nextLine, true);
	}
	
	public String[] parseLine(String nextLine) {
		return parseLine(nextLine, false);
	}
	/**
	* Parses an incoming String and returns an array of elements.
	*
	* @param nextLine
	* the string to parse
	* @param multi
	* @return the comma-tokenized list of elements, or null if nextLine is null
	* @throws IOException if bad things happen during the read
	*/
	private String[] parseLine(String nextLine, Boolean multi) {
	
		if (!multi && pending != null) {
			pending = null;
		}
		
		if (nextLine == null) {
			if (pending != null) {
				String s = pending;
				pending = null;
				return new String[] {s};
			} else {
				return null;
			}
		}
	
		// Special case simple lines to help stay inside script statements governor limits.
		// Only handles quoted string lines.
		if (pending == null) {
			if (nextLine.indexOf(escape) == -1) {
				if (nextLine.startsWith(quote) && nextLine.endsWith(quote)) {
					// The -1 split argument preserves trailing empty strings
					String[] ss = nextLine
					.substring(quote.length(), nextLine.length() - quote.length())
					.split(quote + separator + quote, -1);
					if (!quoteInAnyElement(ss)) {
						return ss;
					} else {
						// Fall through to safe but expensive logic
					}
				}
			}
		}
		
		List<String>tokensOnThisLine = new List<String>();
		StringBuilder sb = new StringBuilder();
		Boolean inQuotes = false;
		if (pending != null) {
			sb.append(pending);
			pending = null;
			inQuotes = true;
		}
		for (Integer i = 0; i < nextLine.length(); i++) {
		
			String c = charAt(nextLine, i);
			if (c == this.escape) {
				if (isNextCharacterEscapable(nextLine, inQuotes || inField, i)) {
					sb.append(charAt(nextLine, i + 1));
					i++;
				}
			} else if (c == quote) {
				if (isNextCharacterEscapedQuote(nextLine, inQuotes || inField, i)) {
					sb.append(charAt(nextLine, i + 1));
					i++;
				} else {
					inQuotes = !inQuotes;
					
					// the tricky case of an embedded quote in the middle: a,bc"d"ef,g
					if (!strictQuotes) {
						if (i > 2 //not on the beginning of the line
						&& charAt(nextLine, i-1) != this.separator //not at the beginning of an escape sequence
						&& nextLine.length()>(i+1)
						&& charAt(nextLine, i+1) != this.separator //not at the end of an escape sequence
						) {
							if (ignoreLeadingWhiteSpace && sb.length() > 0 && isAllWhiteSpace(sb)) {
								sb = new StringBuilder(); //discard white space leading up to quote
							} else {
								sb.append(c);
							}
						}
					}
				}
				inField = !inField;
			} else if (c == separator && !inQuotes) {
				tokensOnThisLine.add(sb.asString());
				sb = new StringBuilder(); // start work on next token
				inField = false;
			} else {
				if (!strictQuotes || inQuotes){
					sb.append(c);
					inField = true;
				}
			}
		}
		// line is done - check status
		if (inQuotes) {
			if (multi) {
				// continuing a quoted section, re-append newline
				sb.append('\n');
				pending = sb.asString();
				sb = null; // this partial content is not to be added to field list yet
			} else {
				throw new OpenCsvParserException('Un-terminated quoted field at end of CSV line');
			}
		}
		if (sb != null) {
			tokensOnThisLine.add(sb.asString());
		}
		return tokensOnThisLine;
	}
		
	private Boolean quoteInAnyElement(String[] ss) {
		for (String s : ss) {
			if (s.indexOf(quote) != -1) {
				return true;
			}
		}
		return false;
	}
	
	/**
	* precondition: the current character is a quote or an escape
	* @param nextLine the current line
	* @param inQuotes true if the current context is quoted
	* @param i current index in line
	* @return true if the following character is a quote
	*/
	public Boolean isNextCharacterEscapedQuote(String nextLine, Boolean inQuotes, Integer i) {
		return inQuotes // we are in quotes, therefore there can be escaped quotes in here.
			&& nextLine.length() > (i + 1) // there is indeed another character to check.
			&& charAt(nextLine, i + 1) == quote;
	}
	
	/**
	* precondition: the current character is an escape
	* @param nextLine the current line
	* @param inQuotes true if the current context is quoted
	* @param i current index in line
	* @return true if the following character is a quote
	*/
	public Boolean isNextCharacterEscapable(String nextLine, Boolean inQuotes, Integer i) {
		return inQuotes // we are in quotes, therefore there can be escaped quotes in here.
			&& nextLine.length() > (i + 1) // there is indeed another character to check.
			&& (charAt(nextLine, i + 1) == quote || charAt(nextLine, i + 1) == escape);
	}
	
	/**
	* precondition: sb.length() > 0
	* @param sb A sequence of characters to examine
	* @return true if every character in the sequence is whitespace
	*/
	private Boolean isAllWhiteSpace(StringBuilder sb) {
		for (Integer i = 0; i < sb.length(); i++) {
			String c = charAt(sb.asString(), i);
			if (!WHITESPACE.contains(c)) {
				return false;
			}
		}
		return true;
	}
	
	private String charAt(String s, Integer index) {
		return s.substring(index, index + 1);
	}
}