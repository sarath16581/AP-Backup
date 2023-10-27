/**
 * @author Hasantha Liyanage
 * @date 2023-09-20
 * @group child component
 * @domain BSP
 * @description Type ahead component row
 * @changelog
 * 2023-09-20 - Hasantha Liyanage  - Created
 */
import {api, LightningElement} from 'lwc';

export default class BspTypeAheadRow extends LightningElement {
	@api iconName
	@api record
	@api searchTerm

	renderedCallback() {
		const nameNode = this.template.querySelector('.search-result-name')
		// eslint-disable-next-line @lwc/lwc/no-inner-html
		nameNode.innerHTML = this._highlightSubstring(this.record.label,this.searchTerm)
		const addtionalFieldsDataNode = this.template.querySelector('.search-result-additional-data');
		// eslint-disable-next-line @lwc/lwc/no-inner-html
		addtionalFieldsDataNode.innerHTML = this._highlightSubstring(this.record.sublabel, this.searchTerm)
	}

	selectedHandler() {
		const selectedEvent = new CustomEvent('selected', { detail: this.record });
		this.dispatchEvent(selectedEvent);
	}
	_highlightSubstring(baseString = '', subString = '') {
		if (subString.length <= 0) {
			return baseString;
		}
		// Convert both the baseString and subString to uppercase for case-insensitive matching
		const baseStringUpper = baseString.toUpperCase();
		const subStringUpper = subString.toUpperCase();

		// Initialize an array to store the portions to highlight
		const portionsToHighlight = [];

		let startIndex = 0;

		while (startIndex < baseStringUpper.length) {
			const subStrIndex = baseStringUpper.indexOf(subStringUpper, startIndex);

			if (subStrIndex < 0) {
				break; // No more matches found, exit the loop
			}

			// Get the portion to highlight and its start and end indices
			const start = subStrIndex;
			const end = subStrIndex + subString.length;
			const portionToHighlight = {
				text: baseString.slice(start, end),
				start,
				end
			};

			// Add the portion to the array
			portionsToHighlight.push(portionToHighlight);

			// Move the startIndex to the next position after the found subString
			startIndex = end;
		}

		if (portionsToHighlight.length === 0) {
			return baseString; // No matches found, return the original string
		}

		// Regular expression with the 'g' flag to match all occurrences
		const regex = new RegExp(subStringUpper, 'gi');

		// Add <b> tags to all matched substrings
		const highlightedText = baseString.replace(regex, (match) => {
			return `<b>${match}</b>`;
		});

		return highlightedText;
	}

/*_highlightSubstring(baseString = '', subString = '') {
		const subStrIndex = baseString.toUpperCase().indexOf(subString.toUpperCase())
		if(subStrIndex < 0) { return baseString; }
		console.log('this.searchTerm in ROW '+subStrIndex +' '+ subStrIndex +' '+ subString.length);
		const portionToHighlight = baseString.slice(subStrIndex, subStrIndex + subString.length);
		return baseString.replace(portionToHighlight, `<b>${portionToHighlight}</b>`)
	}*/
}