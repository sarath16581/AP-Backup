import CustomerTypeIconsUrl from '@salesforce/resourceUrl/CustomerTypeIcons';

/**
 * Transforms the name columns into the custom multi-line data-type used
 * by the lightning data table to display multiple fields in a single cell.
 * 
 * @param {object} result - The result object
 * @param {string} result.contactId
 * @param {string} result.firstName
 * @param {string} result.lastName
 * @param {string} [result.preferredName]
 * @param {string} [result.organisationName]
 * @param {Function} [recordClickFn]
 * @returns {object[]} - an array of line items for the custom data-type 
 */
export function transformNames(
	{ contactId, firstName, lastName, preferredName, organisationName },
	recordClickFn
) {
	return [
		// Line 1
		{
			text: firstName + ' ' + lastName,
			isLink: true,
			href: '#',
			onClick: function (e) {
				if (recordClickFn) {
					e.preventDefault();
					recordClickFn(contactId);
				}
			},
		},
		// Line 2
		{
			text:
				preferredName && preferredName !== firstName ? `(${preferredName})` : '',
			formatBold: true,
		},
		// Line 3
		{ text: organisationName },
	].filter((item) => item?.text);
}

/**
 * Transforms the phone number columns into the custom multi-line data-type used
 * by the lightning data table to display multiple fields in a single cell.
 * 
 * @param {object} result - The result object
 * @param {string} [result.verifiedMobilePhone]
 * @param {string} [result.mobilePhone]
 * @param {string} [result.phone]
 * @returns {object[]} - an array of line items for the custom data-type 
 */
export function transformPhoneNumbers({ verifiedMobilePhone, mobilePhone, phone }) {
	return Array.from(new Set([verifiedMobilePhone, mobilePhone, phone]))
		.filter((value) => value)
		.map((value) => {
			return {
				text: value,
				isVerified: value === verifiedMobilePhone,
			};
		});
}

/**
 * Transforms the email address columns into the custom multi-line data-type used
 * by the lightning data table to display multiple fields in a single cell.
 * 
 * @param {object} result - The result object
 * @param {string} [result.verifiedEmailAddress]
 * @param {string} [result.emailAddress]
 * @returns {object[]} - an array of line items for the custom data-type 
 */
export function transformEmailAddresses({ verifiedEmailAddress, emailAddress }) {
	return Array.from(new Set([verifiedEmailAddress, emailAddress]))
		.filter((value) => value)
		.map((value) => {
			return {
				text: value,
				isVerified: value === verifiedEmailAddress,
			};
		});
}

/**
 * Transforms the mailing address columns into the custom multi-line data-type used
 * by the lightning data table to display multiple fields in a single cell.
 * 
 * @param {object} result - The result object
 * @param {string} [result.mailingStreet]
 * @param {string} [result.mailingStreet2]
 * @param {string} [result.mailingCity]
 * @param {string} [result.mailingState] 
 * @param {string} [result.mailingPostalCode]
 * @param {string} [result.mailingCountry]
 * @returns {object[]} - an array of line items for the custom data-type 
 */
export function joinMailingAddress({
	mailingStreet,
	mailingStreet2,
	mailingCity,
	mailingState,
	mailingPostalCode,
	mailingCountry,
}) {
	const addressLine1 = mailingStreet || '';
	const addressLine2 = mailingStreet2 || '';
	const addressLine3 = mailingCity || '';
	let addressLine4 = mailingState || '';
	if (mailingState && mailingPostalCode) {
		addressLine4 += ', ';
	}
	addressLine4 += mailingPostalCode || '';
	if ((mailingState || mailingPostalCode) && mailingCountry) {
		addressLine4 += ', ' + mailingCountry;
	}

	return [
		{ text: addressLine1 },
		{ text: addressLine2 },
		{ text: addressLine3 },
		{ text: addressLine4 },
	];
}

/**
 * Transforms the case count columns into the custom multi-line data-type used
 * by the lightning data table to display multiple fields in a single cell.
 * 
 * @param {object} result - The result object
 * @param {string} [result.openCasesCount]
 * @param {string} [result.totalCasesCount]
 * @returns {object[]} - an array of line items for the custom data-type 
 */
export function joinCaseColumns({openCasesCount, totalCasesCount}) {
	return [
			{ text: `${openCasesCount} Open` },
			{ text: `${totalCasesCount} Total` },
		];
}

/**
 * Returns the SVG icon url for the customer type.
 * 
 * @param {object} result - The result object
 * @param {string} [result.customerType]
 * @returns 
 */
export function getCustomerTypeIcon({ customerType }) {
	const iconId = customerType
		?.toLowerCase()
		.replace('consumer smb', 'consumer-smb');
	// If customer type was blank, return a default icon
	return `${CustomerTypeIconsUrl}#${iconId || 'consumer-smb'}`;
}

/**
 * Transforms the search results into a format ready fot the lightning-datatable,
 * using a custom data-type to display multiple fields in a single cell.
 * 
 * @param {object} searchResults - The search results array (records) returned from the search.
 * @param {(event)=>void} recordClickFn - The callback function to use when a record is clicked.
 * @returns {object[]} - An array of objects, each representing a row in the lightning-datatable.
 */
export function transformSearchResults(searchResults, recordClickFn) {
	return searchResults.map((result) => {
		return {
			...result,
			nameArr: transformNames(result, recordClickFn),
			phoneNumbersArr: transformPhoneNumbers(result),
			emailAddressesArr: transformEmailAddresses(result),
			mailingAddressArr: joinMailingAddress(result),
			numCasesArr: joinCaseColumns(result),
			customerTypeIcon: getCustomerTypeIcon(result),
		};
	});
}
