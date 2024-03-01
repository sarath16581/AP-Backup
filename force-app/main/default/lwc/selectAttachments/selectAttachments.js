import { LightningElement, api, wire, track } from 'lwc';
import {NavigationMixin} from "lightning/navigation";
import { gql, graphql, refreshGraphQL } from 'lightning/uiGraphQLApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// For Apttus Contracts
import approvalMatrixImage from "@salesforce/resourceUrl/APTSpendDelegationMatrix";

const columns = [
	{ label: 'Title', fieldName: 'Title' },
	{ label: 'File Size', fieldName: 'ContentSize'},
	{ label: 'Last Modified Date', fieldName: 'ContentModifiedDate', type: 'date' }
];

export default class SelectAttachments extends NavigationMixin(LightningElement) {
	@api recordid;
	@api redirect;

	@track data = [];
	@track preSelectedRows = [];

	columns = columns;
	errors;

	// Additional, object specific functionality
	approvalMatrixImage;

	@wire(graphql, {
		query: '$query',
		variables: '$myVariables'
	})
	graphqlQueryResult(result) {
		this.graphqlData = result; // Store the result so refreshGraphql() can refresh it later

		const { errors, data } = result;		

		if (data) {

			this.data = data.uiapi.query.ContentDocumentLink.edges.map((edge) => ({
				Id: edge.node.ContentDocument.Id,
				Title: edge.node.ContentDocument.Title.value,
				ContentSize: this.formatFileSize(edge.node.ContentDocument.ContentSize.value),
				ContentModifiedDate: edge.node.ContentDocument.ContentModifiedDate.value
			}));

			// Auto select the first attachment, if there is at least one
			if (this.data && this.data.length > 0) {
				this.preSelectedRows = [this.data[0].Id];
			}
		}

		this.errors = errors;
	}

	get query() {
		return gql`
			query getFiles ($recordid: ID) {
				uiapi {
					query {
						ContentDocumentLink ( 
							where: { 
								LinkedEntityId: { 
									eq: $recordid 
								}
							} 
							orderBy: { 
								ContentDocument: { 
									LastModifiedDate: { 
										order: DESC 
									}
								}
							}) {
							edges {
								node {
									Id
									ContentDocument {
										Id
										Title {
											value
										}
										ContentSize {
											value
										}
										ContentModifiedDate {
											value
										}
									}
								}
							}
						}
					}
				}
			}
		`
	}
	
	get myVariables() {
		return {
			recordid: this.recordid
		};
	}

	connectedCallback() {
		// Specific to Apttus and Adobe Sign (mimic existing behaviour as per current Docusign business process)
		if (this.redirect && this.redirect.indexOf('Apttus') !== -1) {
			this.approvalMatrixImage = approvalMatrixImage;
		}	
	}

	formatFileSize(bytes) {
		if (bytes < 1024) {
			return bytes.toString() + ' Bytes';
		}
		else if (bytes >= 1024 && bytes < (1024 * 1024)) {
			//KB
			const totalSizeKB = (bytes / Math.pow(1024, 1)).toFixed(2);
			return totalSizeKB.toString() + ' KB';
			
		}
		else if (bytes >= (1024 * 1024) && bytes < (1024 * 1024 * 1024)) {
			//MB
			const totalSizeMB = (bytes / Math.pow(1024, 2)).toFixed(2);
			return totalSizeMB.toString() + ' MB';
		}
		else {
			//GB
			const totalSizeGB = (bytes / Math.pow(1024, 3)).toFixed(2);
			return totalSizeGB.toString() + ' GB';
		}
	}

	handleSelect(e) {
		this.preSelectedRows = Array.from(e.detail.selectedRows).map(row => row.Id);
		console.log(this.preSelectedRows.join(','))
	}

	// Seleted attachment Ids will be passed as a parameter (comma separted values) to the specified destination URL
	handleRedirect() {
		// throw an error if no attachments are selected
		if (this.preSelectedRows.length == 0) {
			let event = new ShowToastEvent({
				message: 'Please select at least one attachment to proceed',
				variant: 'error'
			});

			this.dispatchEvent(event);
			return;
		} else {
			this[NavigationMixin.Navigate]({
				type: 'standard__webPage',
				attributes: {
					url: '/' + this.redirect + '?c__masterId=' + this.recordid + '&c__attachmentIds=' + this.preSelectedRows.join(',')
				}
			})
		}
	}

	handleBack() {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.recordid,
				actionName: 'view'
			}
		})
	}
	@api
	async handleRefresh() {
		await refreshGraphQL(this.graphqlData);
	}
}



