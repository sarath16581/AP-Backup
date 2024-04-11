/**
 * @author Mathew Jose
 * @date 2021-09-05
 * @description Component which allows Bulk Edit capability of Opportunity Products via list button.
 * @changelog
 * 2021-09-05 - Mathew Jose - Created
 * 2023-04-12 - Harry Wang - Added new column Annualised Value on the datatable
 * 2023-05-05 - Harry Wang - refactor navigation and fix saving defects
 * 2023-10-16 - Bharat Patel - Implementation of STP-9640, 'Generation Proposal Document' & 'Generation Agreement' actions redirect to OPC
 */
import {LightningElement, track, api , wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOppProducts from '@salesforce/apex/APT_OpptyProductListController.getOpptyProducts';
import setOppProducts from '@salesforce/apex/APT_OpptyProductListController.updateOppProducts';
import {refreshApex} from '@salesforce/apex';
import {NavigationMixin} from "lightning/navigation";
import {getRecordNotifyChange} from 'lightning/uiRecordApi';
import LightningConfirm from 'lightning/confirm';
import getProposalDocGenerationProgress from '@salesforce/apex/APT_CheckoutController.getProposalDocGenerationProgress';


export default class OppProductDataTable extends NavigationMixin(LightningElement) {

	@track data = [];
	@track draftValues = [];
	@api oppId;
	@api oppName;
	@api isSpinning = false;
	@api recalculateopc = false;
	@track tableErrors = { rows: {}, table: {} };
	@track hideConfirmOPCButton = false;
	lastSavedData = [];
	responseData;
	@api proposalId;
	@track isProposalDocumentFlow = false;
	@api isST;
	@api isManualContract;
	@api isAmend;
	@api isRenew;
	contractServiceDetailsUrl = '/lightning/cmp/c__APT_ContractServiceDetailsWrapper?c__proposalId=';
	@track isProposalDocumentGenerationRunning = false;

	get columns() {
		return [
			{ label: 'Product Name', fieldName: 'ProductName', editable: false, wrapText: true, initialWidth: 160},
			{ label: 'Revenue Start Date', fieldName: 'Contract_Start_Date__c', type: 'date-local', editable: true, initialWidth: 160, iconName:'utility:stop'},
			{ label: 'Revenue End Date', fieldName: 'Contract_End_Date__c', type: 'date-local', editable: true, initialWidth: 160, iconName:'utility:stop'},
			{ label: 'Quantity', fieldName: 'Quantity', type: 'Integer', editable: true, initialWidth: 160, iconName:'utility:stop'},
			{ label: 'Unit Sales Price (Ex GST)', fieldName: 'UnitPrice', type: 'currency', editable: true ,initialWidth: 160, iconName:'utility:stop',
				cellAttributes: { alignment: 'left' }
			},
			{ label: 'Total Price', fieldName: 'TotalPrice', type: 'currency', editable: false, initialWidth: 160,
				cellAttributes: { alignment: 'left' }
			},
			{ label: 'Annualised Value', fieldName: 'Annualised_Value__c', type: 'currency', editable: false, initialWidth: 160,
				cellAttributes: { alignment: 'left' }
			},
			{ label: 'Last 12 months Revenue', fieldName: 'TweleveMonthRevenue__c', type: 'currency', editable: false, initialWidth: 160,
				cellAttributes: { alignment: 'left' }
			},
			{ label: 'Annual Retained Value', fieldName: 'RetainedRevenue__c', type: 'currency', editable: false, initialWidth: 160,
				cellAttributes: { alignment: 'left' }
			},
			{ label: 'Annual Incremental Value', fieldName: 'IncrementalRevenue__c', type: 'currency', editable: false, initialWidth: 160,
				cellAttributes: { alignment: 'left' }
			},
			{ label: 'Quote Number', fieldName: 'Contract_Number__c', type: 'text', editable: true, initialWidth: 160},
			{ label: 'Contract Product?', fieldName: 'ContractProduct', type: 'boolean', editable: true, initialWidth: 160, iconName:'utility:stop',
				cellAttributes: { alignment: 'center'}
			},
		];
	}

	@wire(getOppProducts, {oppId: '$oppId', recalculate: '$recalculateopc' })
	wiredOppProducts(results) {
		let { error, data } = results;
		this.responseData = results;
		if (data) {
			// data
			try {
				this.data = JSON.parse(JSON.stringify(data));
				if (this.data.length===0) {
					this.error = 'To see products on this page, you will need to add them via the Product Catalogue page within Apttus. Once you have added products, they will then be displayed on this page. For further help, please contact your local CRM Specialist.';
					this.showNotification('Error', this.error, 'error');
				} else {
					this.oppName = this.data[0].Opportunity.Name;
					this.convertToForm(this.data)
					//save last saved copy
					this.lastSavedData = JSON.parse(JSON.stringify(this.data));
				}
				if(this.proposalId !== 'noProposal' && this.proposalId !== undefined && this.recalculateopc === false) {
					this.isProposalDocumentFlow = true;
				}
			} catch (err) {
				this.error = 'There was an issue retrieving Opportunity products.';
				this.showNotification('Error', this.error, 'error');
			}
		}
		else if (error) {
			this.error = error;
            this.revenueData = undefined;
			this.showNotification('Error', this.error, 'error');
		}
	}

	convertToForm(productObjectRows) {
		for (let i = 0; i < productObjectRows.length; i++) {
			productObjectRows[i].ProductName = productObjectRows[i].Product2.Name;
			productObjectRows[i].ContractProduct = productObjectRows[i].Contract_Product__c === 'Yes';
			productObjectRows[i].Growth = productObjectRows[i].Change_Classification__c === 'Yes';
		}
	}

	convertFromForm(productFormRows) {
		productFormRows.forEach(i => {
			if (i.ContractProduct != null) {
				i.Contract_Product__c = i.ContractProduct  ? 'Yes' : 'No';
			}
			if (i.Growth != null) {
				i.Change_Classification__c = i.Growth  ? 'Yes' : 'No';
			}
		});
	}

	handleChange() {
		this.hideConfirmOPCButton = true;

		if(this.proposalId !== 'noProposal' && this.proposalId !== undefined && this.recalculateopc === false) {
			this.isProposalDocumentFlow = false;
		}
	}

	handleSave(event) {
		this.tableErrors = { rows: {}, table: {} };
		this.draftValues = event.detail.draftValues;
		this.lastSavedData = JSON.parse(JSON.stringify(this.data));
		this.isSpinning = true;
		this.convertFromForm(this.draftValues);
		this.updateDataValues(this.draftValues);
		let copyData = [... this.data];
		setOppProducts({ oppProds: copyData })
			.then((result) => {
				result = JSON.parse(result);
				if(result.status === 'Success'){
					refreshApex(this.responseData).then(() => {this.isSpinning = false});
					this.draftValues = [];
					if(this.recalculateopc) {
						this.draftValues = [];
						this.hideConfirmOPCButton = false;
					} else {
						const ids = copyData.map(p => {
							return {recordId: p.Id};
						});
						// deprecated method: getRecordNotifyChange is used here to notify LDS to refresh cache to replace notifyRecordUpdateAvailable
						// notifyRecordUpdateAvailable will not trigger cache refresh as expected when second time user save changes on the bulk edit screen
						getRecordNotifyChange(ids);
						this.template.querySelector('lightning-datatable').selectedRows=[];
						//this.handleNavigateToOppProducts();

						if(this.proposalId !== 'noProposal' && this.proposalId !== undefined && this.recalculateopc === false) {
							this.isProposalDocumentFlow = true;
						}
					}
				}else{
					this.isSpinning = false;
					this.setTableError(result);
				}
			})
			.catch((error) => {
				this.error = error;
			});
	}

	handleCancel() {
		//remove draftValues & revert data changes
		this.hideConfirmOPCButton = false;
		this.data = JSON.parse(JSON.stringify(this.lastSavedData));
		this.draftValues = [];

		if(this.proposalId !== 'noProposal' && this.proposalId !== undefined && this.recalculateopc === false) {
			this.isProposalDocumentFlow = true;
		}
	}

	handleCancelClosure() {
		this.dispatchEvent(new CustomEvent('canceled'));
	}

	handleConfirmOPC(){
		this.dispatchEvent(new CustomEvent('confirmed'));
		if(this.isProposalDocumentFlow) {
			this.isSpinning = true;
			//still proposal doc generation is running, recheck after few seconds
			this.checkProposalDocGenerationProgress(this.proposalId);
		}
	}

	updateDataValues(updateItems) {
		let copyData = [... this.data];
		for (let i = 0; i < copyData.length; i++) {
			for(let j = 0; j < updateItems.length; j++){
				if(copyData[i].Id === updateItems[j].Id){
					for(let field in updateItems[j]){
						if(copyData[i][field] !== updateItems[j][field]){
							copyData[i][field] = updateItems[j][field];
						}
					}
				}
			}

		}
		//write changes back to original data
		this.data = [...copyData];
	}

	setTableError(errorData){
		let errorRows = {};
		errorRows = errorData.rows;
		for(let i=0; i< errorRows.length; i++){
			this.tableErrors.rows[errorRows[i].rowId] = { title: errorRows[i].title, messages: errorRows[i].errorMessages, fieldNames: errorRows[i].fieldNames};
		}
		this.tableErrors.table.title = errorData.table.title;
		this.tableErrors.table.messages = errorData.table.errorMessages;
	}

	handleNavigateToOpp(){
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.oppId,
				objectApiName: 'Opportunity', // objectApiName is optional
				actionName: 'view'
			}
		});
	}

	handleNavigateToOppProducts(){
		this[NavigationMixin.Navigate]({
			type: 'standard__recordRelationshipPage',
			attributes: {
				recordId: this.oppId,
				objectApiName: 'Opportunity',
				relationshipApiName: 'OpportunityLineItems',
				actionName: 'view'
			}
		});
	}

	showNotification(title, message, variant) {
		this.dispatchEvent(
			new ShowToastEvent({
				title: title,
				message: message,
				variant: variant,
				mode : 'sticky',
			}),
		);
	}

	/**
	*function will request to check the progress of proposal document generation
	*@param proposalId
	*/
	checkProposalDocGenerationProgress(proposalIdValue) {
		//show message 'Please wait, while the system processes your request'
		this.isProposalDocumentGenerationRunning = true;
		//check for proposal APT_Document_Generation_in_Progress__c = false
		getProposalDocGenerationProgress({ proposalId: proposalIdValue })
			.then((result) => {
				if(result === true) {
					//still proposal doc generation is running, recheck after few seconds
					this._interval = setTimeout(() => {
						this.checkProposalDocGenerationProgress(this.proposalId);
					}, 3000);
				}
				else {
						this.isSpinning = false;
						this.isProposalDocumentGenerationRunning = false;
						//identify contract flow or proposal flow
						if(this.isST !== undefined) {
							//redirect to contract record
							window.location.href = this.contractServiceDetailsUrl + this.proposalId + '&c__isST=' + this.isST + '&c__isManualContract=' + this.isManualContract + '&c__isAmend=' + this.isAmend + '&c__isRenew=' + this.isRenew;
						}
						else {
							//redirect to proposal record
							this[NavigationMixin.Navigate]({
								type: 'standard__recordPage',
								attributes: {
									recordId: this.proposalId,
									objectApiName: 'Apttus_Proposal__Proposal__c',
									actionName: 'view'
								}
							});
						}
				}
			})
			.catch((error) => {
				this.error = error;
				this.isLoading = false;
				this.isProposalDocumentGenerationRunning = false;
			});
	}
}