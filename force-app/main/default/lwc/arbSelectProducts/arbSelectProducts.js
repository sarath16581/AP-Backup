import { LightningElement, track, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import getProducts from '@salesforce/apex/ProductsSelector.getProducts';
import saveSelection from '@salesforce/apex/AtRiskBusinessController.saveSelection';

export default class BarSelectProducts extends LightningElement {

	@track editing = false
	@track viewing = true
	
	@track productData = []

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

	@track selectedRows = []
	@track currentSelectedRows = []
	@track currentProducts = [];

	@track expandedRows = [];

	_recordId;

	@api set recordId(recordId) {
		if (recordId !== this._recordId) {
			this._recordId = recordId;

			this.loadProducts();
		}
	}

	get recordId() {
		return this._recordId;
	}

	loadProducts() {
		getProducts({barId: this._recordId})
			.then(result => {
				const expanded = [];

				this.selectedRows = result.selectedIDs;

				let productTree = {};

				result.products.forEach(record => {
					let level4 = productTree[record.Product_Level_4__c];

					if (!level4) {
						level4 = {
							id: record.Product_Level_4__c,
							name: record.Product_Level_4__c,
							expanded: true,
							children: {}
						};

						productTree[record.Product_Level_4__c] = level4;

						expanded.push(record.Product_Level_4__c);
					}

					level4.children[record.Name] = {
						id: record.Id,
						name: record.Name,
						code: record.ProductCode,
						type: record.APT_Product_type__c,
						revenue: 1000
					}

					if (this.selectedRows.indexOf(record.Id) >= 0) {
						this.currentProducts.push({
							id: record.Id,
							name: record.Name
						});
					}

					expanded.push(record.Id);
				});

				this.productData = this.toGridData(productTree, 4);
				this.expandedRows = expanded;
			})
			.catch(error => {
				console.error('[SELECT PRODUCTS]', error);
			});
	}

	toGridData(treeData, level) {
		const keys = Object.keys(treeData);

		const data = [];

		keys.forEach(key => {
			const props = Object.keys(treeData[key]);

			let record = {};

			props.forEach(prop => {
				if (prop !== 'children') {
					record[prop] = treeData[key][prop];
				}
			});

			if (treeData[key]['children']) {
				record['_children'] = this.toGridData(treeData[key]['children'], level + 1);
			}

			record['level'] = level;

			data.push(record);
		});

		return data;
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

			let selectedCount = 0;

			this.productData.forEach(level4 => {
				level4['_children'].forEach(level5 => {
					if (tempList.indexOf(level5.id) >= 0) {
						selectedCount++;
					}
				});
			});
        }
	}

	edit(event) {
		this.editing = true;
		this.viewing = false;
	}

	saveSelection(event) {
		const selectedProductIDs = this.selectedRows.filter(id => (id.indexOf('01') == 0));

		saveSelection({barId: this.recordId, productIDs: selectedProductIDs})
			.then(result => {
				// Refresh record page
				notifyRecordUpdateAvailable([{recordId: this._recordId}]).then(() => {
					this.dispatchEvent(new CloseActionScreenEvent());
				});

				this.editing = false;
				this.viewing = true;
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