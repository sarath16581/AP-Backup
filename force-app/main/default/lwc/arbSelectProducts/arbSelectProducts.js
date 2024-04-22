import { LightningElement, track, api } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import getProducts from '@salesforce/apex/AtRiskBusinessController.getProducts';
import saveSelection from '@salesforce/apex/AtRiskBusinessController.saveSelection';

export default class BarSelectProducts extends LightningElement {

	@track loading = true;

	@track editing = false;
	@track viewing = true;

	@track empty = true;

	@track disableSave = true;

	@track gridColumns = [
		{
			type: 'text',
			fieldName: 'name',
			label: 'Product'
		},
		{
			type: 'currency',
			fieldName: 'revenue',
			label: 'Revenue'
		}
	];

	@track productData = [];
	@track selectedRows = [];
	@track currentSelectedRows = [];
	@track currentProducts = [];

	@track expandedRows = [];

	_recordId;

	@api set recordId(recordId) {
		if (recordId !== this._recordId) {
			this._recordId = recordId;

			this.loadProducts(false, true);
		}
	}

	get recordId() {
		return this._recordId;
	}

	loadProducts(allProducts, resetViewFlag) {
		this.productData = [];
		this.selectedRows = [];
		this.currentSelectedRows = [];
		this.currentProducts = [];
		this.expandedRows = [];

		this.disableSave = true;

		getProducts({arbId: this._recordId, allProducts: allProducts})
			.then(result => {
				if (result.products.length === 0) {
					this.empty = true;
					this.loading = false;
					return;
				}

				const expanded = [];

				this.selectedRows = result.selectedIDs;

				if (this.selectedRows && this.selectedRows.length && this.selectedRows.length > 0) {
					this.disableSave = false;
				}

				let productTree = {};

				result.products.forEach(record => {
					let level4 = productTree[record.level4Name];

					if (!level4) {
						level4 = {
							id: record.level4Name,
							name: record.level4Name,
							expanded: true,
							children: []
						};

						productTree[record.level4Name] = level4;

						expanded.push(record.level4Name);
					}

					level4.children.push({
						id: record.id,
						name: record.name,
						code: record.code,
						type: record.type,
						revenue: record.revenue
					});

					if (this.selectedRows.indexOf(record.Id) >= 0) {
						this.currentProducts.push({
							id: record.id,
							name: record.name
						});
					}

					expanded.push(record.id);
				});

				this.productData = this.toGridData(productTree, 4);
				this.expandedRows = expanded;

				this.empty = false;
				this.loading = false;

				if (resetViewFlag) {
					this.viewing = true;
					this.editing = false;
					
					// Refresh record page
					notifyRecordUpdateAvailable([{recordId: this._recordId}]);
				}
			})
			.catch(error => {
				console.error('[SELECT PRODUCTS]', error);
				this.loading = false;
			});
	}

	toGridData(treeData) {
		return Object.keys(treeData).map(
			level4Name => {
				const group = treeData[level4Name];
				return ({
					_children : group.children,
					...Object.keys(group).filter(
						prop => prop !== 'children'
					).reduce(
						(result, prop) => Object.assign(result, { [prop] : group[prop] }),
						{ }
					)
				});
			}
		);
	}

	updateSelectedRows() {
		let tempList = [];
		let selectRows = this.template.querySelector('lightning-tree-grid').getSelectedRows();
		if(selectRows.length > 0){
			selectRows.forEach(record => {
				tempList.push(record.id);
			})

			// select and deselect child rows based on header row
			this.productData.forEach(record => {
				// if header was checked and remains checked, do not add sub-rows

				// if header was not checked but is now checked, add sub-rows
				if(!this.currentSelectedRows.includes(record.id) && tempList.includes(record.id)) {
					record['_children'].forEach(item => {
						if(!tempList.includes(item.id)) {
							tempList.push(item.id);
						}
					})
				}

				// if header was checked and is no longer checked, remove header and sub-rows
				if(this.currentSelectedRows.includes(record.id) && !tempList.includes(record.id)) {
					record['_children'].forEach(item => {
						const index = tempList.indexOf(item.id);
						if(index > -1) {
							tempList.splice(index, 1);
						}
					})
				}

				// if all child rows for the header row are checked, add the header
				// else remove the header
				let allSelected = true;
				record['_children'].forEach(item => {
					if(!tempList.includes(item.id)) {
						allSelected = false;
					}
				})

				if(allSelected && !tempList.includes(record.id)) {
					tempList.push(record.id);
				} else if(!allSelected && tempList.includes(record.id)) {
					const index = tempList.indexOf(record.id);
					if(index > -1) {
						tempList.splice(index, 1);
					}
				}

			})

			this.selectedRows = tempList;
			this.currentSelectedRows = tempList;
			
			this.disableSave = !(this.selectedRows && this.selectedRows.length && this.selectedRows.length > 0);
		}
	}

	edit(event) {
		this.loading = true;
		this.editing = true;
		this.viewing = false;
		this.empty = false;
 
		this.loadProducts(true, false);
	}

	saveSelection(event) {
		this.loading = true;

		this.selectedRows = this.template.querySelector('lightning-tree-grid').getSelectedRows()

		const selectedProductIDs = this.selectedRows.filter(item => (item.id.indexOf('01') === 0)).map(item => item.id);

		saveSelection({arbId: this._recordId, productIds: selectedProductIDs})
			.then(() => {
				this.loadProducts(false, true);
			})
			.catch(error => {
				console.error('[SAVE SELECTION]', error);
			});
	}

	close(event) {
		this.editing = false;
		this.viewing = true;
	}
}