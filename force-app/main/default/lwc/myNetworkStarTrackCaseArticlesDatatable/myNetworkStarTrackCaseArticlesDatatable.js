/**
* @changelog
* 2023-03-06 - Mahesh Parvathaneni - SF-874 Used ActualDateTime_TimeStamp__c field
* 2023-03-10 - Mahesh Parvathaneni - SF-889 Updated the logic to check the contact facility from the network
* 2023-05-10 - Mahesh Parvathaneni - SF-946 Updated the logic for AP no network scan
*/
import {
	api,
	track,
	LightningElement
} from 'lwc';
import {
	getValue,
	getCriticalIncidents,
	CONSTANTS
} from 'c/myNetworkStarTrackCaseArticlesService';

export default class MyNetworkStarTrackCaseArticlesDatatable extends LightningElement {

	@api articleDetails; //article details received from parent
	@api receiverPostcode; //receiver post code on case
	@api receiverSuburb; //receiver suburb on case
	@track selectedRows = []; //selected rows
	@track tableData; //data to be rendered in table
	showNetworkScanModal = false; //flag to show/hide the network scan modal
	criticalIncidents; //critical incidents list for the networks
	eventMessagesNetworkWrapper = {}; //event messages wrapper to send to network scan component
	selectedNetworkRows = []; //selected network rows from the child
	removedNetworkRows = []; //removed network rows from the child
	articleId; //articleid to pass to network scan events modal

	tableColumns = [{
			label: 'Article',
			fieldName: 'Name',
			objName: 'Article__c',
			editable: false,
			sortedColumn: false,
			fieldType: 'URL',
			headerCssClass: 'slds-th__action slds-text-link_reset',
			dataCssClass: 'slds-cell-wrap'
		},
		{
			label: 'Last Event Description',
			objName: 'EventMessage__c',
			fieldName: 'EventDescription__c',
			editable: false,
			sortedColumn: false,
			fieldType: 'TEXT',
			headerCssClass: 'slds-th__action slds-text-link_reset',
			dataCssClass: 'slds-cell-wrap'
		},
		{
			label: 'Last Scan Date',
			objName: 'EventMessage__c',
			fieldName: 'ActualDateTime_TimeStamp__c',
			editable: false,
			sortedColumn: false,
			fieldType: 'TEXT',
			headerCssClass: 'slds-th__action slds-text-link_reset',
			dataCssClass: 'slds-cell-wrap'
		},
		{
			label: 'Last AP Network Scan',
			objName: 'EventMessage__c',
			fieldName: 'Facility__c',
			editable: false,
			sortedColumn: false,
			fieldType: 'PILL',
			headerCssClass: 'slds-th__action slds-text-link_reset',
			dataCssClass: 'slds-cell-wrap'
		}
	];


	/**
	 * Formatted table data with required columns to render
	 */
	get formattedArticles() {
		let tableData = this.articleDetails.map(item => {
			let rowData = this.tableColumns.map(column => {
				let row = {
					...column,
					fieldValue: column.objName === 'Article__c' ? getValue(item.article, column.fieldName, null) : getValue(item.eventMessages?.[0].eventMessage, column.fieldName, null),
					key: item.article.Id,
					networkPillItems: this.getNeworkPillItems(item, item.eventMessages?.[0].eventMessage ?? null, item.eventMessages?.[0].network ?? null, column),
					fieldUrl: this.getFieldUrl(item, column),
					eventMessageId: item.eventMessages?.[0]?.eventMessage.Id ?? null
				};
				return row;
			});

			return {
				...item,
				isArticleSelected: this.isArticleSelected(item.article.Id),
				isDisabled: this.isRowDisabled(item.eventMessages?.[0].network),
				rowData: rowData
			}
		})
		this.tableData = tableData;
		return this.tableData;
	}

	//function to check if the article is selected 
	isArticleSelected(articleId) {
		return this.selectedRows.some(row => row.articleId === articleId);
	}

	//function to set the disabled property for rows in datatable
	isRowDisabled(network) {
		let isDisabled = false;
		if (this.selectedNetworkRows.length > 0) {
			this.selectedNetworkRows.forEach(row => {
				if (row.contactMethod === CONSTANTS.MY_NETWORK) {
					return isDisabled;
				}
			})
		} else {
			//set disabled checkbox
			if (network && network.Contact_Facility__c === CONSTANTS.MY_NETWORK) {
				return isDisabled;				
			} else {
				isDisabled = true;
			}
		}
		return isDisabled;
	}

	//get network pill items data object for the event messages
	getNeworkPillItems(item, eventMessage, network, column) {
		let networkPillItems = [];
		let articleId = item.article.Id;
		//check if any selected networks for an article (not the initial load)
		if (this.selectedNetworkRows.length > 0) {
			//check the article exists in the selectedNetworkRows (if user has changed the networks)
			let isArticleExistsInNetworkRows = false;
			this.selectedNetworkRows.forEach(row => {
				if (row.articleId === articleId) {
					isArticleExistsInNetworkRows = true;
				}
			});

			if (isArticleExistsInNetworkRows) {
				//check the article if exists in tableData
				let article = this.tableData.find(data => data.article.Id === articleId);
				if (article) {
					//get the existing pill items
					let articleRowData = this.tableData.find(data => data.article.Id === articleId).rowData;
					let existingPillItems = articleRowData.find(row => row.fieldName === 'Facility__c').networkPillItems;

					this.selectedNetworkRows.forEach(row => {
						if (row.articleId === articleId) {
							const isDuplicate = existingPillItems.some(pill => pill.name === row.network);
							if (!isDuplicate) {
								existingPillItems.push({
									label: row.networkLabel,
									name: row.network,
									contactMethod: row.contactMethod
								})
							}
						}
					});
					networkPillItems = existingPillItems;
				} else {
					this.selectedNetworkRows.forEach(row => {
						if (row.articleId === articleId) {
							networkPillItems.push({
								label: row.networkLabel,
								name: row.network,
								contactMethod: row.contactMethod
							});
						}
					});
				}
			} else {
				//for initial render when no networks selected from modal
				//set the network as per the latest event message record
				if (eventMessage !== null && network !== null) {
					networkPillItems = this.getLatestNetworkPillItems(eventMessage, network);
				}
			}
		} else if (column.fieldType === 'PILL' && eventMessage !== null && network !== null) {
			//for initial render when no networks selected from modal
			//set the network as per the latest event message record
			networkPillItems = this.getLatestNetworkPillItems(eventMessage, network);
		}
		return networkPillItems;
	}

	//format url for the field
	getFieldUrl(item, column) {
		let target = null;
		if (column.fieldType === 'URL' && column.objName === 'Article__c') {
			target = item.article.Id;
		}
		return target;
	}

	//get the latest network from event message
	getLatestNetworkPillItems(eventMessage, network) {
		let networkPillItems = [];
		const index = this.removedNetworkRows.findIndex(obj => {
			return obj.articleId === eventMessage.Article__c && obj.network === network.Id;
		});
		if(index === -1) {
			networkPillItems.push({
				label: network.Name,
				name: network.Id,
				contactMethod: network.Contact_Facility__c
			});
		}
		return networkPillItems;
	}

	//handler for networksearch event from the child
	handleNetworkSearch(event) {
		let articleId = event.detail.articleId;
		this.articleId = articleId;
		this.eventMessagesNetworkWrapper = {
			eventMessages: this.articleDetails.find(data => data.article.Id === articleId).eventMessages,
			selectedNetworks: event.detail.selectedNetworks
		}

		if (this.criticalIncidents === null || this.criticalIncidents === undefined) {
			this.isLoading = true;
			//load the critical incidents knowledge articles
			getCriticalIncidents()
				.then(response => {
					this.isLoading = false;
					this.criticalIncidents = response;
					this.showNetworkScanModal = true;
				})
				.catch(error => {
					this.isLoading = false;
					console.error('getCriticalIncidents call failed: ' + error.body.message);
				})
		} else {
			this.showNetworkScanModal = true;
		}
	}

	//handler for modalclose event from the child
	handleModalclose(event) {
		this.showNetworkScanModal = false;
	}

	//handler on article select checkbox
	handleRowChange(event) {
		if (event.target.checked) {
			let networks = this.getSelectedNetworks(event.target.dataset.id);
			let row = {
				articleId: event.target.dataset.id,
				referenceId: event.target.dataset.referenceId,
				networks: networks
			}
			this.selectedRows.push(row);
		} else {
			let index = this.selectedRows.findIndex(row => row.articleId === event.target.dataset.id);
			if (index > -1) {
				this.selectedRows.splice(index, 1);
			}
		}
		this.selectedRows = [...this.selectedRows];
		this.dispatchEvent(new CustomEvent('rowselect', {
			detail: {
				selectedRows: this.selectedRows
			}
		}));
	}

	//get networks related to article selected
	getSelectedNetworks(articleId) {
		let selectedRowData = this.tableData.find(data => data.article.Id === articleId).rowData;
		return selectedRowData.find(row => row.fieldName === 'Facility__c').networkPillItems;
	}

	//handler on event message select from child component (modal)
	handleRowSelect(event) {
		//close the modal
		this.showNetworkScanModal = false;
		//store the selected network rows from child
		if (event.detail.selectedRows && event.detail.selectedRows.length > 0) {
			event.detail.selectedRows.forEach(sr => {
				const index = this.selectedNetworkRows.findIndex(row => {
					return row.articleId === sr.articleId && row.network === sr.network;
				})
				if (index === -1) {
					this.selectedNetworkRows.push(sr);
				}
				if (this.removedNetworkRows.length > 0) {
					for (let i = 0; i < this.removedNetworkRows.length; i++) {
						if (this.removedNetworkRows[i].articleId === sr.articleId && this.removedNetworkRows[i].network === sr.network) {
							this.removedNetworkRows.splice(i, 1);
						}
					}
				}
			})
			//re-render the tableData to bind the selected pill items from getNeworkPillItems method
			this.tableData = [...this.tableData];
			//fire event to parent with selectedRows in case of user trying to submit again in case of any error
			this.dispatchSelectedRows();
		}
	}

	//handler for network removed event from child
	handleNetworkRemoved(event) {
		//add to removedNetworkRows array
		this.removedNetworkRows.push({
			articleId: event.detail.articleId,
			network: event.detail.network
		});

		//remove the items from selectedNetworkRows if exists
		if (this.selectedNetworkRows.length > 0) {
			for (let i = 0; i < this.selectedNetworkRows.length; i++) {
				if (this.selectedNetworkRows[i].articleId === event.detail.articleId && this.selectedNetworkRows[i].network === event.detail.network) {
					this.selectedNetworkRows.splice(i, 1);
				}
			}
		}
		//remove the network pills from table data
		let articleRowData = this.tableData.find(data => data.article.Id === event.detail.articleId).rowData;
		let existingPillItems = articleRowData.find(row => row.fieldName === 'Facility__c').networkPillItems;

		for (let i = 0; i < existingPillItems.length; i++) {
			if (existingPillItems[i].name === event.detail.network) {
				existingPillItems.splice(i, 1);
			}
		}

		this.tableData.find(data => data.article.Id === event.detail.articleId).rowData.
				find(row => row.fieldName === 'Facility__c').networkPillItems = existingPillItems;

		//re-render the tableData to bind the selected pill items from getNeworkPillItems method
		this.tableData = [...this.tableData];
	}

	//fire event to parent with selectedRows
	dispatchSelectedRows() {
		this.selectedRows.forEach(row => {
			row.networks = this.getSelectedNetworks(row.articleId);
		})
		this.selectedRows = [...this.selectedRows];
		this.dispatchEvent(new CustomEvent('rowselect', {
			detail: {
				selectedRows: this.selectedRows
			}
		}));
	}

}