import { LightningElement, api, wire } from 'lwc';
import {NavigationMixin} from "lightning/navigation";
import { gql, graphql } from 'lightning/uiGraphQLApi';

const columns = [
	{ label: 'Id', fieldName: 'Id' },
	{ label: 'Title', fieldName: 'Title' }
	// { label: 'Website', fieldName: 'website', type: 'url' },
	// { label: 'Phone', fieldName: 'phone', type: 'phone' },
	// { label: 'Balance', fieldName: 'amount', type: 'currency' },
	// { label: 'CloseAt', fieldName: 'closeAt', type: 'date' },
];

export default class SelectAttachments extends NavigationMixin(LightningElement) {
	@api recordid;
	@api redirect;

	data = [];
	columns = columns;
	selectedIds = [];
	
	@wire(graphql, {
		query: gql`
			query getFiles ($recordid: ID) {
				uiapi {
					query {
						ContentDocumentLink( where: { LinkedEntityId: { eq: $recordid } }) {
							edges {
								node {
									Id
									ContentDocument {
										Id
										Title {
											value
										}
									}
								}
							}
						}
					}
				}
			}
		`,
		variables: '$myVariables',
		operationName: 'getFiles',
	})
	graphql;

	get myVariables() {
		return {
			recordid: this.recordid
		};
	}

	get files() {
		return this.graphql.data?.uiapi.query.ContentDocumentLink.edges.map((edge) => ({
			Id: edge.node.ContentDocument.Id,
			Title: edge.node.ContentDocument.Title.value
		}));
	}

	handleSelect(e) {
		this.selectedIds = Array.from(e.detail.selectedRows).map(row => row.Id);
		console.log(this.selectedIds);
	}

	// Seleted attachment Ids will be passed as a parameter (comma separted values) to the specified destination URL
	handleRedirect() {
		this[NavigationMixin.Navigate]({
			type: 'standard__webPage',
			attributes: {
				url: this.redirect + '?id=' + this.recordid + '&attachmentids=' + this.selectedIds.join(',')
			}
		})
	}
}



