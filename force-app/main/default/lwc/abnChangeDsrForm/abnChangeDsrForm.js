/**
 * Created by wangh23 on 6/06/2024.
 */

import {api, LightningElement, track, wire} from 'lwc';
import LightningAlert from "lightning/alert";
import LightningConfirm from "lightning/confirm";
import getOpportunities from '@salesforce/apex/ABNChangeController.getOpportunities';
import getColumns from '@salesforce/apex/ABNChangeController.retrieveColumns';
import getDSRs from '@salesforce/apex/ABNChangeController.getDSRsByAccountId';
import LABEL_NO_DSR from "@salesforce/label/c.ABNChangeDSRFormNoDSRError";
import LABEL_NO_OPPORTUNITIES from "@salesforce/label/c.ABNChangeDSRFormNoOpportunitiesError";
import LABEL_NO_AP_OPPORTUNITIES from "@salesforce/label/c.ABNChangeDSRFormNoAPOpportunitiesError";
import LABEL_NO_ST_OPPORTUNITIES from "@salesforce/label/c.ABNChangeDSRFormNoSTOpportunitiesError";
import LABEL_CUSTOMER_SIGNER_INFO from "@salesforce/label/c.ABNChangeDSRFormCustomerSignerInfo";
import {getObjectInfo, getPicklistValues} from "lightning/uiObjectInfoApi";
import DSR_OBJECT from "@salesforce/schema/Deal_Support_Request__c";
import PRODUCT_FIELD from "@salesforce/schema/Deal_Support_Request__c.Product__c";

const RADIO_OPTIONS = [
	{ label: 'Yes', value: 'Yes' },
	{ label: 'No', value: 'No' },
];

const PRODUCTS_OPTIONS = [
	{ label: 'AP', value: 'AP' },
	{ label: 'ST', value: 'ST' },
];

export default class AbnChangeDsrForm extends LightningElement {
	@api newOrganisationName;
	@api businessAtRisk;

	filteredOpportunities = [];
	errorMessage;
	opportunities = [];
	opportunityColumns;
	dsrs = [];
	dsrColumns;
	selectedOpps = [];
	selectedOppIds = [];
	selectedDSRs = []
	selectedDsrIds = [];
	hasSelectedAPOpportunity = false;
	hasSelectedSTOpportunity = false;
	noDSRError;
	noOpportunitiesError;
	@track attachedFiles = [];
	fileUploadError;

	//Form input values
	isActiveContract;
	estimatedAccountClosureDate;
	isSkipProposal = 'Yes';
	isStandardPricing = 'Yes';
	@track products = [];

	/**
	 *  Retrieve Opportunity list by business at risk Id
	 *  then retrieve opportunity table columns based on ABNChangeDSRCreationOpportunityColumn field set
	 */
	_wiredOpportunities;
	@wire(getOpportunities, {accountId: '$businessAtRisk.Related_Organisation__c'})
	wiredData(result) {
		const {data, error} = result;
		this._wiredOpportunities = result;
		if (error) {
			console.error(error);
			this.errorMessage = error;
			return;
		}
		if (data?.length > 0) {
			// map contact name url
			let nameUrl;
			this.opportunities = data.filter(row => row.IsClosed === false).map(row => {
				nameUrl = `/${row.Id}`;
				return {...row , nameUrl}
			});
			this.opportunities.forEach(row => {
				row.legalEntityName = this.newOrganisationName;
				row.keyContactName = row.KeyContact__r?.Name;
				row.owner = row.Owner?.Name;
			});

			// Retrieve opportunity columns
			getColumns({objectName:'Opportunity', fieldSetName: 'ABNChangeDSRCreationOpportunityColumn'}).then(c => {
				this.opportunityColumns = c.map(item => {
					return {...item};
				});
				// insert name, legal entity name and key contact
				this.opportunityColumns.splice(0, 0, { label: 'Name', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}});
				this.opportunityColumns.splice(1, 0, { label: 'Legal Entity Name', fieldName: 'legalEntityName' });
				this.opportunityColumns.splice(2, 0, { label: 'Key Contact', fieldName: 'keyContactName' });
				this.opportunityColumns.push({ label: 'Owner', fieldName: 'owner' })
			}).catch(error => {
				console.error(error);
				LightningAlert.open({
					message: 'Something went wrong while retrieving the columns. Please try again',
					theme: 'error',
					label: 'ABN Change DSRs Creation'
				});
			});
		}
	}

	/**
	 *  Retrieve customer onboarding record type Id to get picklist values for product for DSR object.
	 */
	customerOnboardingRecordTypeId;
	@wire(getObjectInfo, { objectApiName: DSR_OBJECT })
	results({ error, data }) {
		if (data) {
			this.customerOnboardingRecordTypeId = Object.keys(data.recordTypeInfos).find(rti => data.recordTypeInfos[rti].name === 'Customer Onboarding');
		} else if (error) {
			console.error(error);
			LightningAlert.open({
				message: 'Something went wrong while retrieving customer onboarding record type. Please try again',
				theme: 'error',
				label: 'ABN Change DSRs Creation'
			});
		}
	}

	/**
	 *  Retrieve picklist values for customer onboarding record type retrieved from above wired method
	 */
	productTypes;
	@wire(getPicklistValues, { recordTypeId: "$customerOnboardingRecordTypeId", fieldApiName: PRODUCT_FIELD })
	picklistResults({data}) {
		if (data) {
			this.productTypes = data.values.map(e => e.value);
		}
	}

	get radioOptions() {
		return RADIO_OPTIONS;
	}

	get productsOptions() {
		return PRODUCTS_OPTIONS;
	}

	get todayDate() {
		return new Date().toISOString().split('T')[0];
	}

	get hasActiveContract() {
		return this.isActiveContract === 'Yes';
	}

	get hasProductsSelected() {
		// clear opportunity selection if opportunity table is hidden
		if (this.products.length === 0 || this.filteredOpportunities.length === 0) {
			this.selectedOpps = [];
		}
		return this.products.length > 0 && this.filteredOpportunities.length > 0;
	}

	get noStandardPricing() {
		return this.isStandardPricing === 'No' && this.dsrs.length > 0;
	}

	get customerSignerInfo() {
		return LABEL_CUSTOMER_SIGNER_INFO;
	}

	get dsrSelectionError() {
		if (this.selectedDSRs.length === 0 && this.products.length === 0) {
			return 'At least one DSR needs to be selected';
		}
	}

	get oppSelectionError() {
		if (this.selectedOpps.length === 0) {
			return 'At least one opportunity needs to be selected';
		}
	}

	/**
	 *  Called when user update the form.
	 *  Update relevant attributes based on data set Id
	 */
	handleInputChange(event) {
		if (event.target.dataset.id === 'activeContract') {
			this.isActiveContract = event.detail.value;
		} else if (event.target.dataset.id === 'estimatedAccountClosureDate') {
			this.estimatedAccountClosureDate = event.target.value;
		} else if (event.target.dataset.id === 'skipProposal') {
			this.isSkipProposal = event.detail.value;
		} else if (event.target.dataset.id === 'standardPricing') {
			this.isStandardPricing = event.detail.value;
			this.noOpportunitiesError = null;
			this.products = [];
			this.selectedDSRs = [];
			this.selectedDsrIds = [];
			const productElement = this.template.querySelector('[data-id="products"]');
			if (this.isStandardPricing === 'No') {
				productElement.required = false;
				this.loadDSRs();
			} else {
				this.noDSRError = null;
				if (productElement != null) {
					productElement.required = true;
				}
			}
		} else if (event.target.dataset.id === 'products') {
			this.products = event.detail.value;
			// reset filtered opportunities and no opportunities error
			this.filteredOpportunities = [];
			this.noOpportunitiesError = null;

			this.computeOpportunities();
		}
	}

	/**
	 *  Called when user finished attaching documents
	 *  Attached docs will be pushed to attachedFiles
	 */
	handleUploadFinished(event) {
		this.attachedFiles.push(...event.detail.files);
	}

	/**
	 *  Will be called when user deleted attached documents
	 */
	handleDeleteFile(event) {
		const index = event.detail.name;
		this.attachedFiles.splice(index, 1);
	}

	get acceptedFormats() {
		return ['.pdf', '.png', '.jpg', '.csv'];
	}

	/**
	 *  Handler method when user clicks Create button.
	 *  Validate user inputs then structure the request wrapper.
	 *  Dispatch 'create' event with request wrapper to parent for DSR creation.
	 */
	handleCreateDSRs() {
		this.validateCreateDSRs()
			.then(validationResult => {
				if (validationResult) {
					const dsrTypes = [];
					if (this.isActiveContract === 'Yes') {
						if (this.isSkipProposal === 'No') {
							dsrTypes.push('proposalGeneration');
						} else {
							dsrTypes.push('contractGeneration');
						}
						if (this.selectedOpps.reduce((previousValue, currentValue) => previousValue || currentValue.IsStartrackProposal__c === 'Yes')) {
							dsrTypes.push('terminateSTBAs');
						}
						dsrTypes.push('terminateContracts');
					}
					dsrTypes.push('closeAllBAs');
					const wrapper = {
						dsrTypes: dsrTypes,
						atRiskBusinessId: this.businessAtRisk.Id,
						organisationId: this.businessAtRisk.Legal_Entity_Name__c,
						organisationABN: this.businessAtRisk.Legal_Entity_Name__r.ABN__c,
						opportunityWrappers: this.selectedOpps.map(opp => {
							return {
								opportunityId: opp.Id,
								productType: opp.IsStartrackProposal__c === 'Yes' ? 'ST' : 'AP',
								keyContactId: opp.KeyContact__c
							}
						}),
						relatedOpportunity: this.businessAtRisk.Related_Opportunity__c,
						allProductTypes:this.productTypes,
						isStandardPricing: this.isStandardPricing,
						pricingDSRNames: this.selectedDSRs.map(e => e.Name),
						estimatedClosureDate: this.estimatedAccountClosureDate,
						customerRequestDocumentIds: this.attachedFiles.map(f => f.documentId)
					};
					this.dispatchEvent(new CustomEvent('create', {
						detail : wrapper
					}));
				}
			});
	}

	/**
	 *  Triggered when user toggle 'Standard Pricing utilised'
	 *  Retrieve Pricing Support Request DSR for user to select.
	 */
	loadDSRs() {
		getDSRs({accountId: this.businessAtRisk.Related_Organisation__c}).then(results => {
			let nameUrl;
			this.dsrs = results.filter(row => row.Status__c !== 'Draft' && row.RecordType.DeveloperName.startsWith('Pricing_Support_Request')).map(row => {
				nameUrl = `/${row.Id}`;
				return {...row , nameUrl}
			});

			if (this.dsrs.length === 0) {
				this.noDSRError = LABEL_NO_DSR;
				return;
			}

			this.dsrs.forEach(row => {
				row.recordType = row.RecordType?.Name;
				row.owner = row.Owner?.Name;
			});

			getColumns({objectName:'Deal_Support_Request__c', fieldSetName: 'ABNChangeDSRCreationDSRColumn'}).then(c => {
				this.dsrColumns = c.map(item => {
					return {...item};
				});
				this.dsrColumns.splice(0, 0, { label: 'Name', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}});
				this.dsrColumns.splice(1, 0, { label: 'Record Type', fieldName: 'recordType' });
				this.dsrColumns.push({ label: 'Owner', fieldName: 'owner' })
			});
		}).catch(error => {
			console.error(error);
			LightningAlert.open({
				message: 'Something went wrong while retrieving DSRs and columns. Please try again',
				theme: 'error',
				label: 'ABN Change DSRs Creation'
			});
		});
	}

	/**
	 *  Triggered when user select DSRd for pricing
	 *  Products (AP or ST) will be auto-selected based on selected DSR type
	 */
	handleSelectedRows(event) {
		if (event.target.dataset.id === 'dsrTable') {
			this.products = [];
			this.selectedDSRs = event.detail.selectedRows;
			// auto-select products type based on record type
			this.selectedDSRs.forEach(dsr => {
				if (dsr.RecordType.DeveloperName === 'Pricing_Support_Request_StarTrack' && !this.products.includes('ST')) {
					this.products.push('ST');
				} else if (dsr.RecordType.DeveloperName !== 'Pricing_Support_Request_StarTrack' && !this.products.includes('AP')) {
					this.products.splice(0, 0, 'AP')
				}
			});
			this.computeOpportunities();
		}
		if (event.target.dataset.id === 'oppTable') {
			this.selectedOpps = event.detail.selectedRows;
		}

	}

	/**
	 *  Validate form before creating DSRs.
	 *  Ensure all required inputs are not blank, date is valid, customer request documents are attached and at least opportunity is selected
	 */
	async validateCreateDSRs() {
		// validate all inputs
		const allInputValid = [...this.template.querySelectorAll('.input')]
			.reduce((validSoFar, inputCmp) => {
				inputCmp.reportValidity();
				return validSoFar && inputCmp.checkValidity();
			}, true);

		// validate if customer request attached
		let requestValid;
		if (this.attachedFiles.length === 0) {
			const inputCmp = this.template.querySelector('[data-id="requestAttached"]');
			inputCmp.setCustomValidity('Customer request attachment required.');
			inputCmp.reportValidity();
			requestValid = false;
		} else {
			requestValid = true;
		}

		const opportunitySelectionValid = this.isActiveContract === 'No' || this.selectedOpps.length > 0;
		const result = await LightningConfirm.open({
			message: 'Do you want to create DSR(s) for ABN change?  ',
			theme: 'inverse',
			label: 'ABN Change DSRs Creation'
		});
		return result && allInputValid && opportunitySelectionValid && requestValid;
	}

	/**
	 *  Triggered when user toggle Products selection(AP to ST)
	 *  Opportunity datable need to be re-computed based on the product selection.
	 *  Type of selected opportunities need match the product types
	 *  Show error message if no related opportunities linked.
	 *
	 */
	computeOpportunities() {
		this.filteredOpportunities = [];
		this.opportunities.forEach(row => {
			const oppProductType = row.IsStartrackProposal__c === 'Yes' ? 'ST' : 'AP';
			if (this.products.includes(oppProductType)) {
				this.filteredOpportunities.push(row);
				if (oppProductType === 'ST') {
					this.hasSelectedSTOpportunity = true;
				} else {
					this.hasSelectedAPOpportunity = true;
				}
			}
		});

		if (this.products.includes('AP') && this.products.includes('ST') && !this.hasSelectedSTOpportunity && !this.hasSelectedAPOpportunity) {
			this.noOpportunitiesError = LABEL_NO_OPPORTUNITIES;
		} else if (this.products.includes('AP') && !this.hasSelectedAPOpportunity) {
			this.noOpportunitiesError = LABEL_NO_AP_OPPORTUNITIES;
		} else if (this.products.includes('ST') && !this.hasSelectedSTOpportunity) {
			this.noOpportunitiesError = LABEL_NO_ST_OPPORTUNITIES;
		}

		// Pre-select row if only one opportunity
		if (this.filteredOpportunities.length === 1 && this.selectedOpps.length === 0) {
			this.selectedOppIds.push(this.filteredOpportunities[0].Id);
			this.selectedOpps.push(this.filteredOpportunities);
		}
	}
}