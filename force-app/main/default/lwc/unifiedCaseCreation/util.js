/**
 * Return an array of picklist options (label/value pairs) for a given field.
 * This method is useful for generating picklist options where there is a controlling field.
 * 
 * @param {Record<string, PicklistFieldValues>} picklistFieldValues
 * @param {string} fieldApiName
 * @param {string|undefined} [controllingFieldValue]
 * @returns {PicklistOption[]}
 */
export function getPicklistOptions(picklistFieldValues, fieldApiName, controllingFieldValue) {
	if(!picklistFieldValues || !Object.hasOwnProperty.call(picklistFieldValues, fieldApiName)) {
		return [];
	}

	const picklistField = picklistFieldValues[fieldApiName];
	const hasControllingField = Object.keys(picklistField.controllerValues).length > 0;
	const controllingFieldKey = picklistField.controllerValues[controllingFieldValue];

	return picklistField.values
		.filter(picklistValue => !hasControllingField || picklistValue.validFor.includes(controllingFieldKey))
		.map(picklistValue => ({
			label: picklistValue.label,
			value: picklistValue.value
		}));
}

/**
 * Use this method to check if a picklist option is available based on the controlling field value.
 *
 * @param {Record<string, PicklistFieldValues>} picklistFieldValues
 * @param {string} fieldApiName
 * @param {string|undefined} controllingFieldValue
 * @param {string} value
 * @returns {boolean}
 */
export function isPicklistOptionAvailable(picklistFieldValues, fieldApiName, controllingFieldValue, value) {
	return getPicklistOptions(picklistFieldValues, fieldApiName, controllingFieldValue).some(option => option.value === value);
}