/**
 * @author Paul Perry
 * 
 * Couple of generic helper methods
 * - format: format a string with provided parameters
 * - wrapHtml: Convert text into Html elements with provided attributes and innerHtml
 */

export default class Utils {
	/**
	 * Formatting text where the first argument is the template: format('{0}! I am {1}', 'Hello', 'Paul') => 'Hello! I am Paul'
	 * @param {*} text Template to be merged with provided parameters by index
	 * @param {...any} args Parameter value to be merged
	 * @returns String with formatted result
	 */
	static format = (text, ...args) => {
		return text?.replace(
			/{(\d+)}/g,
			(match, number) => {
				return typeof args[number] !== 'undefined'
					? args[number]
					: match;
			}
		);
	}

	/**
	 * Construct an html element: wrapHtml('click here', 'a', { href : 'www.salesforce.com' }) => '<a href="www.salesforce.com">click here</a>'
	 * @param {*} innerHtml Body for element
	 * @param nodeName Element name (div, a, bold)
	 * @returns String with html element
	 */
	static wrapHtml = ({ innerHtml, nodeName, properties }) => {
		let attribSection = properties
			? Object.keys(properties).map(
				prop => `${prop}` + (properties[prop] !== undefined ? `="${properties[prop]}"` : '')
			).join(" ")
			: null;
			
		return [
			`<${nodeName}${attribSection ? ` ${attribSection}` : ''}>`,
			innerHtml,
			`</${nodeName}>`
		].join('');
	}
}