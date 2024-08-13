/**
 * @description DSR creation show existing/created DSRs component.
 * User-created DSRs will be displayed in the table
 * @author Harry Wang
 * @date 2024-06-05
 * @group Controller
 * @changelog
 * 2024-06-05 - Harry Wang - Created
 */
import {LightningElement, api} from 'lwc';
import getColumns from '@salesforce/apex/ABNChangeController.retrieveColumns';
import LightningAlert from "lightning/alert";

export default class AbnChangeDsrShowDsrs extends LightningElement {
	@api dsrList;
	columns;
	isLoading = true;

	/**
	 *  Retrieve DSR table columns based on ABNChangeDSRCreationFinalDSRColumn field set
	 *  Map record type and owner details
	 */
	connectedCallback() {
		// Retrieve columns for the DSR table, map Record Type and Owner
		getColumns({objectName:'Deal_Support_Request__c', fieldSetName: 'ABNChangeDSRCreationFinalDSRColumn'}).then(c => {
			this.columns = c.map(item => {
				return {...item};
			});

			this.columns.splice(0, 0, { label: 'Deal Support Request ID', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}});
			this.columns.push({ label: 'Record Type', fieldName: 'recordType' });
			this.columns.push({ label: 'Owner', fieldName: 'owner' })
		}).catch(error => {
			console.error(error);
			LightningAlert.open({
				message: 'Something went wrong while retrieving the columns. Please try again',
				theme: 'error',
				label: 'ABN Change DSRs Creation'
			});
		}).finally(() => {
			this.isLoading = false;
		});
	}

	/**
	 *  Dispatch close screen action event to parent wrapper
	 */
	handleClose() {
		this.dispatchEvent(new CustomEvent('close'));
	}
}