/**
 * @author Hasantha Liyanage
 * @date 2023-10-02
 * @group child component
 * @domain BSP
 * @description Helps to generate mailto: content for the bsp access request email
 * @changelog
 * 2023-10-02 - Hasantha Liyanage  - Created
 */

import {api, LightningElement} from 'lwc';
import {NavigationMixin} from "lightning/navigation";

export default class BspRequestAccessContent extends NavigationMixin(LightningElement) {
	superAdminRoles = [];
	businessName;
	isRolesAvailable = false;
	@api billingNumber;
	@api contentParam = {}


	renderedCallback() {
		// failsafe in case the array is being passed with empty list
		if(this.contentParam.superAdminRoles.length > 0) {
			this.isRolesAvailable = true;
		}
	}

	/**
	 * handle on click of the link and pass the selected contact details to generate the email content
	 * @param event
	 */
	handleOnClick(event) {
		const selectedContentParam= this.contentParam.superAdminRoles.find(({ contactId }) => contactId === event.currentTarget.dataset.id);
		this.handleOpenMailto(selectedContentParam);
	}

	/**
	 * generate the mailto email content
	 * @param contentParam
	 */
	handleOpenMailto(contentParam) {
		const email = contentParam.email;
		const subject = 'Australia Post - Business Support Portal - Enable account number';
		let body = 'Hi '+contentParam.firstName+',';
		body += '\n\n';
		body += 'Can you please update my Australia Post Business Support Portal access.';
		body += '\n\n';
		body += 'As an Access Management Administrator, you\'re authorised to update user access.';
		body += '\n\n';
		body += 'I\'m submitting a \'credit claim\' enquiry on the Business Support Portal (https://bsp.auspost.com.au/s/CreditClaimForm) for '+this.contentParam.businessName;
		body += '\n\n';
		body += 'Please review which accounts I have access to, including this account number, '+ this.billingNumber +'.';
		body += '\n\n\n';
		body += 'How to update Business Support Portal user access';
		body += '\n';
		body += '--------------------';
		body += '\n';
		body += '1. Load the Australia Merchant Portal https://merchant-portal.auspost.com.au';
		body += '\n';
		body += '2. Select \'Access Management\'';
		body += '\n';
		body += '3. Locate user '+this.contentParam.loggedInUserEmail+' and select the edit icon';
		body += '\n';
		body += '4. For \'Business Support Portal\', update or enable account numbers including '+ this.billingNumber +'.';
		body += '\n';
		body += '5. Select \'Save changes\'';
		body += '\n\n\n';

		// Define the email URL
		const mailtoUrl = `mailto:${email}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;

		// Use the NavigationMixin to open the email client
		this[NavigationMixin.Navigate]({
			type: 'standard__webPage',
			attributes: {
				url: mailtoUrl
			}
		});
	}
}