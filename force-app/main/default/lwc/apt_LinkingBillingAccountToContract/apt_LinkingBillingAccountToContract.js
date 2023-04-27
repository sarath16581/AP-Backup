/**
 * @description
 * Lightning Web Component is launched from two places:
 * 	-A list button on Agreement Lodgement Point related list on Apttus Contract layout
 *  -A formula field 'Create' on Apttus Contract to trigger contract template generation before any billing acc, charge/sub acc or organisation is linked
 * Objective: this component is handling the linking of billing account, charge account request and sub account request to Apttus contract
 * 				by inserting a junction object called agreement lodgement point
 * @changelog
 * 2022-06-01 - Seth Heang - Created
 * 01.08.2022   Prerna Rahangdale - Added the the validation for lodgement point records to be same as Proposal.
 * 2023-04-12 - Sarath Burra - CI-880 Added the Logic to poll for a certian time, until the contract line items are generated
 * 								Polling is done every second for 12 secs and the page is loaded automatically once the refreshed data is available
 */
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import {checkUndefinedOrNull,refreshPageWithPoll} from 'c/utils';
import retrieveAgreementLodgementPoints from "@salesforce/apex/APT_LinkingBillAccToContractController.retrieveAgreementLodgementPoints";
import retrieveProductsFromCLI from "@salesforce/apex/APT_LinkingBillAccToContractController.retrieveProductsFromCLI";
import retrieveBillingAcc from "@salesforce/apex/APT_LinkingBillAccToContractController.retrieveBillingAcc";
import retrieveChargeAccountRequests from '@salesforce/apex/APT_LinkingBillAccToContractController.retrieveChargeAccountRequests';
import retrieveSubAccountRequests from '@salesforce/apex/APT_LinkingBillAccToContractController.retrieveSubAccountRequests';
import LABEL_DUP_LINKED_BILLINGACC from '@salesforce/label/c.APT_BillingAccountAlreadyLinked';
import LABEL_NoLinkedAccounts from '@salesforce/label/c.APT_NoLinkedAccounts';
import insertAgreementLodgementPoints from '@salesforce/apex/APT_LinkingBillAccToContractController.insertAgreementLodgementPoints';

// column header for product table
const productColumns = [
	{ label: 'Product Name', fieldName: 'APT_Product_Name__c'},
];

// column header for charge account request table
const chargeAccReqColumns = [
	{ label: 'Name', fieldName: 'Name_URL', type:'url',
	typeAttributes: { label: { fieldName: 'Name'}, target:'_blank'} },
	{ label: 'Legal Entity Name', fieldName: 'Legal_Entity_Name_URL', type:'url',
	typeAttributes: { label: { fieldName: 'Legal_Entity_Name'}, target:'_blank'} },
	{ label: 'ABN', fieldName: 'APT_ABN__c'},
	{ label: 'ACN', fieldName: 'APT_ACN__c'},
	{ label: 'Estimated Credit Limit', fieldName: 'APT_Credit_Limit_Required__c'},
];

// column header for sub account request table
const subAccReqColumns = [
	{ label: 'Name', fieldName: 'Name_URL', type:'url',
	typeAttributes: { label: { fieldName: 'Name'}, target:'_blank'} },
	{ label: 'Suburb', fieldName: 'APT_Postal_Address_Suburb__c'},
	{ label: 'State', fieldName: 'APT_Postal_Address_State__c'},
	{ label: 'Postcode', fieldName: 'APT_Postal_Address_Street_Postcode__c'},
];

// column header for billing account table
const billingAccColumns = [
	{ label: 'Name', fieldName: 'Name_URL', type:'url',
	typeAttributes: { label: { fieldName: 'Name'}, target:'_blank'} },
	{ label: 'Billing Account No.', fieldName: 'LEGACY_ID__c'},
	{ label: 'MLID', fieldName: 'MLID__c'},
	{ label: 'Customer Name', fieldName: 'Customer_Name__c'},
	{ label: 'Is This a Sub-Account', fieldName: 'Is_this_a_sub_account__c'},
	{ label: 'Payer Account Id', fieldName: 'PAYER_ACCOUNT_NAME'},
	{
		label: 'Credit Status',
		cellAttributes: { iconName: { fieldName: 'dynamicIcon' } }
	},
];
// column header for agreement lodgment point table
const agreementLPColumns = [
	{ label: 'Name', fieldName: 'Name_URL', type:'url',
	typeAttributes: { label: { fieldName: 'Name'}, target:'_blank'} },
	{ label: 'Billing Account', fieldName: 'APT_Billing_Account_Name_URL', type:'url',
	typeAttributes: { label: { fieldName: 'APT_Billing_Account_Name'}, target:'_blank'} },
	{ label: 'Charge Account', fieldName: 'APT_Charge_Account_Name_URL', type:'url',
	typeAttributes: { label: { fieldName: 'APT_Charge_Account_Name'}, target:'_blank'} },
	{ label: 'Sub Account', fieldName: 'APT_Sub_Account_Name_URL', type:'url',
	typeAttributes: { label: { fieldName: 'APT_Sub_Account_Name'}, target:'_blank'} }
];

// radio option for rate selection
const ALL_RATE_RADIO_OPT = { label: 'Apply rates to All Accounts for this Organisation' , value: 'allRate'};
const CAR_SAR_RATE_RADIO_OPT = { label: 'Apply rates only to new Charge Accounts/Sub Accounts' , value: 'carSarRate'};
const BILL_ACC_RATE_RADIO_OPT = { label: 'Apply rates to specific Billing Accounts' , value: 'billingAccRate'};
const PROPOSAL_NEW_ACC_TYPE_CHARGE_ACCOUNT = 'Charge Account';
const PROPOSAL_NEW_ACC_TYPE_CHARGE_SUB_ACCOUNT = 'Charge Account + Sub Account';
const BASE_URL = 'https://' + location.host + '/';

export default class Apt_LinkingBillingAccountToContract extends NavigationMixin(LightningElement) {
	@api recordId;
	error = '';
	displayRateActions = false;
	noAgreementLineItems=false;
	displayProducts = false;
	productNamelist = [];
	selectedProduct = {};
	selectedCAR = [];
	selectedSAR = [];
	selectedBillingAcc = [];

	// flag for display various tables
	displayCARTable = false;
	displaySARTable = false;
	displayBATable = false;
	displayALPTable = false;
	displayLPTable = false;

	// mapping table columns
	displayProdCols = productColumns;
	displayCARCols = chargeAccReqColumns;
	displaySARCols = subAccReqColumns;
	displayALPCols = agreementLPColumns;
	displayBACols = billingAccColumns;
	lockLinkAccountBtn = true;

	// lists for populating the various tables
	carList = [];
	sarList = [];
	bilingAccList = [];
	aLPList = [];
	wiredALPList = [];
	@track cliData=[];
	hasPollingError=false;
	showSpinner=false;
	recordsData=[];

	selectRateAction = '';
	proposalAccountType = '';
	// flag for radio button
	displayCarSarRateRatioBtn = false;
	displayBillingAccRateRatioBtn = false;
	displayAllAccountRateRatioBtn = false;
	contractAccId = '';
	proposalId ='';
	isLoading = false;
	hasOrgLvRelationship = false;
	hasChargeSubORBillingAccRelationship = false;
	disableProdSpecificBillAccBtn = false;
	disableContractRelationshipBtn = false;
	isNewCustomerFlow = false;
	isExistingCustomerFlow = false;

	@track lodgementPointVar;
	@track lodgementPointList;

	// PRERNA 25/07/2022
	selectedHandler(event){
		if( event.detail.selRecords !== undefined){
			this.lodgementPointVar = event.detail.selRecords;
			this.lodgementPointList = JSON.stringify(event.detail.selRecords);
		}
		event.preventDefault();
		return false;
	}

	/**
	 * getter method to build the rate option for radio button group
	 * Options include:
	 * -Apply rates to All Accounts for this Organisation
	 * -Apply rates only to new Charge Accounts/Sub Accounts
	 * -Apply rates to specific Billing Accounts
	 */
	get rateActions(){
		this.validateContractRelationshipAndRateButtonVisibility();
		let rateActionList = [];
		/**
		 * Only display "Apply rates to All Accounts for this Organisation" under below condition:
		 * -Add Contract relationship button is selected
		 * Note: Product specific billing account button selection does not display this option
		 *  */
		if(this.displayAllAccountRateRatioBtn === true){
			rateActionList.push(ALL_RATE_RADIO_OPT);
		}
		/**
		 * Only display "Apply rates only to new Charge Accounts/Sub Accounts" under below condition:
		 * -Proposal.New Account Type is 'Charge Account' OR 'Charge + Sub Account'
		 *  */
		if(this.displayCarSarRateRatioBtn === true){
			rateActionList.push(CAR_SAR_RATE_RADIO_OPT);
		}
		/**
		 * Only display "Apply rates to specific Billing Accounts" under below condition:
		 * -Proposal.New Account Type is BLANK
		 *  */
		else if(this.displayBillingAccRateRatioBtn === true){
			rateActionList.push(BILL_ACC_RATE_RADIO_OPT);
		}
		return rateActionList;
	}

	/**
	 * wire method to retrieve the agreement lodgement points record based on apttus contract Id,
	 * then populate the returned data into the aLPList to display on the UI
	 * @param {contractId}
	 */
	@wire(retrieveAgreementLodgementPoints, {contractId: '$recordId'})
	wiredAgreementLP(result){
		if(result.data){
			this.wiredALPList = result;
			var data = this.wiredALPList.data;
			if(data.length !== 0){
				// display agreement lodgment point table
				this.displayALPTable = true;
				// copy array to modify the element in array
				data = JSON.parse(JSON.stringify(data));
				// clear array to prevent duplicate
				this.aLPList = [];
				data.forEach(alp => {
					// build navigation url for lookup fields hyperlinks to open on a new tab on click in the table
					alp.Name_URL = BASE_URL + alp.Id;
					// check for undefined value/property on the obj, to prevent variable referencing error
					if(alp.hasOwnProperty('APT_Billing_Account__r') && !this.isUndefinedOrNull(alp.APT_Billing_Account__r.Name)){
						// map billing account name and url link for display in the table
						alp.APT_Billing_Account_Name = alp.APT_Billing_Account__r.Name;
						alp.APT_Billing_Account_Name_URL = BASE_URL + alp.APT_Billing_Account__c;
						this.hasChargeSubORBillingAccRelationship = true;
					}
					if(alp.hasOwnProperty('APT_Charge_Account__r') && !this.isUndefinedOrNull(alp.APT_Charge_Account__r.Name)){
						// map charge account name and url link for display in the table
						alp.APT_Charge_Account_Name = alp.APT_Charge_Account__r.Name;
						alp.APT_Charge_Account_Name_URL = BASE_URL + alp.APT_Charge_Account__c;
						this.hasChargeSubORBillingAccRelationship = true;
					}
					if(alp.hasOwnProperty('APT_Sub_Account__r') && !this.isUndefinedOrNull(alp.APT_Sub_Account__r.Name)){
						// map sub account name and url link for display in the table
						alp.APT_Sub_Account_Name = alp.APT_Sub_Account__r.Name;
						alp.APT_Sub_Account_Name_URL = BASE_URL + alp.APT_Sub_Account__c;
						this.hasChargeSubORBillingAccRelationship = true;
					}
					// set org relationship flag for dynamic display of apply rate radio buttons
					if(this.isUndefinedOrNull(alp.APT_Charge_Account__c) &&
						this.isUndefinedOrNull(alp.APT_Sub_Account__c) &&
						this.isUndefinedOrNull(alp.APT_Billing_Account__c)){
						this.hasOrgLvRelationship = true;
					}
					// Dynamically display Add Contract button on Product specific billing account button on page load
					if(alp.hasOwnProperty('APT_Product__c')){
						this.disableContractRelationshipBtn = true;
					}else{
						this.disableProdSpecificBillAccBtn = true;
					}
					this.aLPList.push(alp);
				})
				/**
				 * rebuild array to make the table data rerender, as array.push() changes doesn't rerender
				 * same problem here: https://salesforce.stackexchange.com/questions/252996/array-push-wont-update-lightning-web-component-view
				**/
				this.aLPList = [...this.aLPList];
			}
		} else if(result.data){
			this.error = error;
		}
	}

	/**
	 * Validate visibility of three ratio buttons for applying Rates at the Org level, Charge/Sub Acc level or Billing Account level under below condition:
	 * -When Charge/Sub Acc or Billing Account relationship has been linked, then hide the display of "Apply rates to All Accounts" radio button
	 * -When Organisation level relationship has been linked, then hide the display of "Apply rates to specific Billing Account" or "Apply rates only to new Charge Account/Sub Accounts" radio buttons
	 */
	validateContractRelationshipAndRateButtonVisibility(){
		if(this.hasChargeSubORBillingAccRelationship === true){
			this.displayAllAccountRateRatioBtn = false;
		}else if(this.hasOrgLvRelationship === true){
			this.displayBillingAccRateRatioBtn = false;
			this.displayCarSarRateRatioBtn = false;
		}
	}

	/**
	 * wire method to retrieve the contract line item record based on apttus contract Id,
	 * then extract contract's orginsation Id, proposal's new account type, proposal Id and product Name
	 * for downstream usages and UI display of product
	 * @param {contractId}
	 */
	@wire(retrieveProductsFromCLI, {contractId: '$recordId'})
	wireProduct(result){
		this.cliData=result;
		if(result.data){
			this.recordsData=result.data;
			//Added the Logic to poll for a certian time, until the contract line items are generated
  			//Polling is done every second for 12 secs and the page is loaded automatically once the refreshed data is available
			//Also Display a message for the user to indicate Agreement line item creation is in progress
			if(checkUndefinedOrNull(this.recordsData[0])){
				this.noAgreementLineItems=true;
				this.showSpinner=true;
				const poll = refreshPageWithPoll(this.cliData,1000,20000).then((message) => {console.log(message);})
				.catch((error) => {
					this.showSpinner=false;
					this.hasPollingError=true;
				});
			}else{
				this.noAgreementLineItems=false;
				this.showSpinner=false;
				this.hasPollingError=false;
				// get contract's organisation Id
				this.contractAccId = this.recordsData[0].Apttus__AgreementId__r.Apttus__Account__c;
				// get proposal's new account type
				this.proposalAccountType = this.recordsData[0].Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__r.APT_Method_of_Payment__c;
				// get proposal Id
				this.proposalId = this.recordsData[0].Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__c;
				// save product name to display on UI
				this.recordsData.forEach(product => {
				this.productNamelist.push(product);
				})

				/**
				 * Capture flag to display "Apply rates to specific Billing Accounts" radio option under below condition:
				 * -Proposal.New Account Type is BLANK
				 *  */
				if(this.isUndefinedOrNull(this.proposalAccountType)){
					this.isExistingCustomerFlow = true;
					this.displayBillingAccRateRatioBtn = true;
				}

				/**
				 * Capture flag to display "Apply rates only to new Charge Accounts/Sub Accounts" radio option under below condition:
				 * -Proposal.New Account Type is 'Charge Account' OR 'Charge + Sub Account'
				 *  */
				else if(this.proposalAccountType === PROPOSAL_NEW_ACC_TYPE_CHARGE_ACCOUNT
						|| this.proposalAccountType === PROPOSAL_NEW_ACC_TYPE_CHARGE_SUB_ACCOUNT){
					this.isNewCustomerFlow = true;
					this.displayCarSarRateRatioBtn = true;
				}

			}

		}else if(result.error){
			this.error = result.error;
		}
	}

	/**
	 * method to retrieve both charge account request and sub account request based on proposal Id
	 * and populate the returned data into the table for display on UI
	 */
	getChargeAndSubAccountRequests(){
		this.isLoading = true;
		if(!this.isUndefinedOrNull(this.proposalId)){
			// imperatively apex call to retrieve charge account request based on the proposal Id
			retrieveChargeAccountRequests(
				{ propId: this.proposalId }
			).then((result) =>{
				// make a copy of array to modify its element for table display
				let data = JSON.parse(JSON.stringify(result));
				data.forEach(car =>{
					// build navigation url for charge account req hyperlink to open on a new tab on click in the table
					car.Name_URL = BASE_URL + car.Id;
					car.Legal_Entity_Name_URL = BASE_URL + car.APT_Organisation__c;
					// check for undefined value/property on obj, to prevent referencing error
					if(car.hasOwnProperty('APT_Organisation__r') && !this.isUndefinedOrNull(car.APT_Organisation__r.Name)){
						car.Legal_Entity_Name = car.APT_Organisation__r.Name;
					}
					this.carList.push(car);
				})
				// imperatively apex call to retrieve sub account request based on the proposal Id
				retrieveSubAccountRequests(
					{ propId: this.proposalId }
				).then((result) =>{
					// make a copy of array to modify its element for table display
					let data = JSON.parse(JSON.stringify(result));
					data.forEach(sar =>{
						// build navigation url for sub account req hyperlink to open on a new tab on click in the table
						sar.Name_URL = BASE_URL + sar.Id;
						this.sarList.push(sar);
					})
					// validate the display of charge/sub account tables
					this.validateDisplayChargeSubAccTable();
					this.isLoading = false;
				})
				.catch((error) => {
					this.isLoading = false;
					this.error = error;
				})
			})
			.catch((error) => {
				this.isLoading = false;
				this.error = error;
			})
		}
	}

	/**
	 * method to retrieve billing account records based on contract's organisation Id
	 * and populate the returned data into the table for display on UI
	 */
	getBillingAccounts(){
		this.isLoading = true;
		if(!this.isUndefinedOrNull(this.contractAccId)){
			// make imperative apex call to retrieve billing account based on contract's organisation id
			retrieveBillingAcc(
				{ contractOrgId: this.contractAccId }
			).then((result) =>{
				// copy to a new array to update dynamicIcon attribute
				var data = JSON.parse(JSON.stringify(result));
				data.forEach(ba =>{
					// build navigation url for billing account hyperlink to open on a new tab on click in the table
					ba.Name_URL = BASE_URL + ba.Id;
					// update dynamicIcon attribute to allow dynamic icon display in the table
					if(ba.Credit_Status__c === true){
						ba.dynamicIcon = 'action:close';
					}else{
						ba.dynamicIcon = 'action:approval';
					}
					// check for undefined variable/property, then update PAYER_ACCOUNT_NAME and Is_this_a_sub_account__c for data display in table
					if(ba.hasOwnProperty('PAYER_ACCOUNT_ID__r') &&
						!this.isUndefinedOrNull(ba.PAYER_ACCOUNT_ID__r.Name)){
							ba.PAYER_ACCOUNT_NAME = ba.PAYER_ACCOUNT_ID__r.Name;
							ba.Is_this_a_sub_account__c = 'Yes';
					}else{
						ba.Is_this_a_sub_account__c = 'No';
					}
					this.bilingAccList.push(ba);
				})
				// validate the display of billing account tables
				this.validateDisplayBATable();
				this.isLoading = false;
			})
			.catch((error) => {
				this.isLoading = false;
				this.error = error;
			})
		}
	}
	/**
	 * method to save selection of specific product on product selection and validate table display
	 */
	handleSelectedProduct(event){
		this.selectedProduct = event.detail.selectedRows[0];
		this.displayRateActions = true;
		// hide all table when switching production selection
		this.displayCARTable = false;
		this.displaySARTable = false;
		this.displayBATable = false;
		this.lockLinkAccountBtn = false;
		this.displayLPTable = false;
	}

	/**
	 * method to save selection of charge account request and enable the 'Add Billing Account' button for clicking
	 */
	handleSelectedCAR(event){
		this.selectedCAR = event.detail.selectedRows;
		this.lockLinkAccountBtn = false;
		event.preventDefault();
	}

	/**
	 * method to save selection of sub account request and enable the 'Add Billing Account' button for clicking
	 */
	handleSelectedSAR(event){
		this.selectedSAR = event.detail.selectedRows;
		this.lockLinkAccountBtn = false;
		event.preventDefault();
	}

	/**
	 * method to save selection of billing account and enable the 'Add Billing Account' button for clicking
	 */
	handleSelectedBillingAcc(event){
		this.selectedBillingAcc = event.detail.selectedRows;
		this.lockLinkAccountBtn = false;
		event.preventDefault();
	}

	/**
	 * method to save selection of radio button rate option and validate the table display accordingly
	 * @param {*} event
	 */
	handleSelectedRateAction(event){
		this.selectRateAction = event.target.value;
		// On Selection of 'Apply rates to All Accounts for this Organisation' radio button
		if(this.selectRateAction === 'allRate'){
			// hide all tables, other than agreement LP table
			this.displayCARTable = false;
			this.displaySARTable = false;
			this.displayBATable = false;
			this.lockLinkAccountBtn = false;
			// deselect all selected charge/sub acc request and billing account
			this.selectedCAR = [];
			this.selectedSAR = [];
			this.selectedBillingAcc = [];
			// clear any error such as no linked account
			this.error = void 0;
			// existing customer scenario, do not display lodgement point section
			if(this.isNewCustomerFlow === true){
				this.displayLPTable = true;
			}else if(this.isExistingCustomerFlow === true){
				// new customer scenario, display lodgement point section
				this.displayLPTable = false;
			}
		}
		// On Selection of 'Apply rates only to new Charge Accounts/Sub Accounts' radio button
		else if(this.selectRateAction === 'carSarRate'){
			// make an imperative apex call to retrieve the charge/sub account requests and populate the table
			if(this.carList.length === 0 && this.sarList.length === 0){
				this.getChargeAndSubAccountRequests();
			}else{
				// validate the charge/sub account req table display
				this.validateDisplayChargeSubAccTable();
			}
			this.displayLPTable = true;
		}
		// On Selection of 'Apply rates to specific Billing Accounts' radio buton
		else if(this.selectRateAction === 'billingAccRate'){
			if(this.bilingAccList.length === 0){
				// make an imperative apex call to retrieve the billing account to populate the table
				this.getBillingAccounts();
			}else{
				// validate the billing account table display
				this.validateDisplayBATable();
			}
		}
		event.preventDefault();
	}

	/**
	 * method to validate the billing account table display and throw error if no linked account exists
	 */
	validateDisplayBATable(){
		this.displayCARTable = false;
		this.displaySARTable = false;
		if(this.bilingAccList.length > 0 ){
			this.displayBATable = true;
		}else{
			// display error if no linked account exists
			this.error = LABEL_NoLinkedAccounts;
		}
	}

	/**
	 * method to validate the charge/sub account req table display and throw error if no linked account exists
	 */
	validateDisplayChargeSubAccTable(){
		if(this.carList.length > 0 ){
			this.displayCARTable = true;
		}
		if(this.sarList.length > 0 ){
			this.displaySARTable = true;
		}
		// display error if no linked account exists
		if(this.carList.length === 0 && this.sarList.length === 0){
			this.error = LABEL_NoLinkedAccounts;
		}
		this.displayBATable = false;
	}

	/**
	 * method to handle when clicking 'Add Product specific Billing Account' button.
	 * It display product table for product specific selection, and hide other tables
	 * @param {*} event
	 */
	handleProductSpecificBillingAccbutton(event){
		// disable display of 'Apply rates to All Accounts for this organisation' radio button for this selection
		this.displayAllAccountRateRatioBtn = false;
		// display product table
		this.displayProducts = true;
		// hide rate radio button
		this.displayRateActions = false;
		// hide all tables
		this.displayCARTable = false;
		this.displaySARTable = false;
		this.displayBATable = false;
		// clear product and rate option selected
		this.selectedProduct = void 0;
		this.selectRateAction = void 0;

		this.disableProdSpecificBillAccBtn = false;
		this.disableContractRelationshipBtn = true;
		event.preventDefault();
	}

	/**
	 * method to handle when clicking 'Add Generic Billing Account' button.
	 * It display radio button group for rate selection, and hide other tables
	 * @param {*} event
	 */
	handleContractRelationshipbutton(event){
		// enable display of 'Apply rates to All Accounts for this organisation' radio button for this selection
		this.displayAllAccountRateRatioBtn = true;
		// hide product table
		this.displayProducts = false;
		// display rate radio button
		this.displayRateActions = true;
		// hide all tables
		this.displayCARTable = false;
		this.displaySARTable = false;
		this.displayBATable = false;
		// clear product and rate option selected
		this.selectedProduct = void 0;
		this.selectRateAction = void 0;
		this.disableProdSpecificBillAccBtn = true;
		this.disableContractRelationshipBtn = false;
		event.preventDefault();
	}

	/**
	 * method to redirect the user back to the Apttus Contract, upon clicking 'Back to Apttus Contract' button
	 */
	redirectBackToContract(){
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.recordId,
				objectApiName: 'Apttus__APTS_Agreement__c',
				actionName: 'view'
			},
		});
	}

	/**
	 * method to perform validation on checkbox selection on the lightning datatable, when user click 'Apply Relationship' button
	 * It will throw appropriate error upon failing validation
	 * @returns BOOLEAN
	 */
	validateSelectionNotEmpty(){
		if(this.isNewCustomerFlow === true && (this.selectRateAction === 'carSarRate' || this.selectRateAction === 'allRate')
			&& this.lodgementPointVar.length === 0 ){
			this.isLoading = false;
			const evt = new ShowToastEvent({
				title: 'Link Billing Account',
				message: 'Please select at least one lodgement point',
				variant: 'error',
			});
			this.dispatchEvent(evt);
			return false;
		} else if(this.isNewCustomerFlow === true && (this.selectRateAction === 'carSarRate' || this.selectRateAction === 'allRate')
			&& this.lodgementPointVar.length > 1){
			this.isLoading = false;
			const evt = new ShowToastEvent({
				title: 'Link Billing Account',
				message: 'Please select only one lodgement point',
				variant: 'error',
			});
			this.dispatchEvent(evt);
			return false;
		} else if(this.selectRateAction === 'carSarRate' && this.selectedCAR.length === 0 && this.selectedSAR.length === 0){
			this.isLoading = false;
			const evt = new ShowToastEvent({
				title: 'Link Billing Account',
				message: 'Please select at least one charge account request or sub account request',
				variant: 'error',
			});
			this.dispatchEvent(evt);
			return false;
		} else if(this.selectRateAction === 'billingAccRate' && this.selectedBillingAcc.length === 0){
			this.isLoading = false;
			const evt = new ShowToastEvent({
				title: 'Link Billing Account',
				message: 'Please select at least one billing account',
				variant: 'error',
			});
			this.dispatchEvent(evt);
			return false;
		}
		return true;
	}

	/**
	 * method for linking billing account by performing neccessary validation check including duplicate check.
	 * Once successful, it calls apex method to DML insert the agreement LP with appropriate field mappings
	 * @param {*} event
	 */
	handleLinkingBillingAccount(event){
		event.preventDefault();
		this.isLoading = true;
		if(this.validateSelectionNotEmpty() === false){
			return;
		}

		// obj list for linking storing billing account, charge and sub account request
		var objLinkingList = [];
		// obj list returned after performing duplicate validation
		var newobjLinkingListAfterDupValidation = [];
		// No need for duplicate check, if there is no existing linking records
		if(this.aLPList.length === 0){
			// Applying all rate scenario, thus add contract's org Id for the linking
			if(this.selectRateAction === 'allRate'){
				objLinkingList.push( { "id": this.contractAccId, "objType": "APT_Organisation__c"});
			}
			// Applying for Charge/Sub Acc scenario, thus add Charge/Sub Acc Id for the linking
			else if(this.selectRateAction === 'carSarRate'){
				if(this.selectedCAR.length > 0){
					this.selectedCAR.forEach(car=>{
						objLinkingList.push( {  "id": car.Id, "objType": "APT_Charge_Account__c"});
					})
				}
				if(this.selectedSAR.length > 0){
					this.selectedSAR.forEach(sar=>{
						objLinkingList.push( {  "id": sar.Id, "objType": "APT_Sub_Account__c"});
					})
				}
			}
			// Applying for specific Billing Acc scenario, thus add billing acc Id for the linking
			else if(this.selectRateAction === 'billingAccRate'){
				if(this.selectedBillingAcc.length > 0){
					this.selectedBillingAcc.forEach(billingAcc=>{
						objLinkingList.push({id: billingAcc.Id, objType: "APT_Billing_Account__c"});
					})
				}
			}
		}else{
			// there is existing linking records, so call validation method to perform duplicate check on existing agreement lodgement points
			newobjLinkingListAfterDupValidation = this.validateDuplicateLinkedAgreementLP();
		}

		// merge the validated list into main list
		if(newobjLinkingListAfterDupValidation?.length > 0){
			objLinkingList = objLinkingList.concat(newobjLinkingListAfterDupValidation);
		}
		// imperatively apex call to insert the linking records
		if(objLinkingList?.length > 0){
			let productName;
			if(!this.isUndefinedOrNull(this.selectedProduct)){
				productName = this.selectedProduct.APT_Product_Name__c;
			}
			insertAgreementLodgementPoints(
				{
					wrapperObjList: objLinkingList,
					contractId: this.recordId,
					orgId: this.contractAccId,
					prodName: productName,
				    proposalId:this.proposalId,
					lodgementPointWCCs:this.lodgementPointList
				}
			).then((result) =>{
				if(result === 'SUCCESS'){
					this.isLoading = false;
					const evt = new ShowToastEvent({
						title: 'Link Billing Account',
						message: 'New Agreement Lodgement Point(s) record successfully added',
						variant: 'success',
					});
					this.dispatchEvent(evt);
					this.displayALPTable = true;
					// refresh the agreement lodgement point table with the new data updated
					refreshApex(this.wiredALPList);
				}
				if(result === 'FAILED'){
					this.isLoading = false;
					const evt = new ShowToastEvent({
						title: 'Lodgement Point',
						message: 'Lodgement point selected must be within one of the primary lodgement zone/s entered in the shopping cart.',
						variant: 'error',
					});
					this.dispatchEvent(evt);
				}
			})
			.catch((error) => {
				this.isLoading = false;
				const evt = new ShowToastEvent({
					title: 'Link Billing Account',
					message: error.body.message,
					variant: 'error',
				});
				this.dispatchEvent(evt);
			})
		}
	}

	/**
	 * method to perform duplicate record check on agreement LP and return appropriate error upon criteria met
	 * @returns [] objLinkingList
	 */
	validateDuplicateLinkedAgreementLP(){
		// error flag for detecting if a linked account already exists
		var dupAccError = false;
		var objLinkingList = [];
		// iterate over the agreement lodgement point and check if relavent lookup fields already exists
		if(this.selectRateAction === 'billingAccRate'){
			// iterate over selected billing accounts and check for matching billing account Id on agreement LP
			this.selectedBillingAcc.forEach(billingAcc=>{
				this.aLPList.forEach(alp=>{
					if(alp.APT_Billing_Account__c === billingAcc.Id){
						// match found, set the flag
						dupAccError = true;
					}
				});
				// ensure valid Id prior to saving to list
				if(!this.isUndefinedOrNull(billingAcc.Id)){
					objLinkingList.push( { "id": billingAcc.Id, "objType": "APT_Billing_Account__c"});
				}
			})
		}else if(this.selectRateAction === 'carSarRate'){
			// iterate over selected charge account requests and check for matching charge account requests on agreement LP
			this.selectedCAR.forEach(car=>{
				this.aLPList.forEach(alp=>{
					if(alp.APT_Charge_Account__c === car.Id){
						// match found, set the flag
						dupAccError = true;
					}
				});
				// ensure valid Id prior to saving to list
				if(!this.isUndefinedOrNull(car.Id)){
					objLinkingList.push( { "id": car.Id, "objType": "APT_Charge_Account__c"});
				}
			})
			// iterate over selected sub account requests and check for matching sub account requests on agreement LP
			this.selectedSAR.forEach(sar=>{
				this.aLPList.forEach(alp=>{
					if(alp.APT_Sub_Account__c === sar.Id){
						// match found, set the flag
						dupAccError = true;
					}
				});
				// ensure valid Id prior to saving to list
				if(!this.isUndefinedOrNull(sar.Id)){
					//idList.push(sar.Id);
					objLinkingList.push( { "id": sar.Id, "objType": "APT_Sub_Account__c"});
				}
			})
		}else if(this.selectRateAction === 'allRate'){
			// iterate over existing linked records and ensure that billing account and charge/sub account req are blank and organisation matches
			this.aLPList.forEach(alp=>{
				if(alp.APT_Organisation__c === this.contractAccId &&
					this.isUndefinedOrNull(alp.APT_Billing_Account__c) &&
					this.isUndefinedOrNull(alp.APT_Charge_Account__c) &&
					this.isUndefinedOrNull(alp.APT_Sub_Account__c)){
					// match found, set the flag
					dupAccError = true;
				}
			});
			// ensure valid Id prior to saving to list
			if(!this.isUndefinedOrNull(this.contractAccId)){
				objLinkingList.push( { "id": this.contractAccId, "objType": "APT_Organisation__c"});
			}
		}
		// display error due to duplicate record found
		if(dupAccError === true){
			this.isLoading = false;
			const evt = new ShowToastEvent({
				title: 'Link Billing Account',
				message: LABEL_DUP_LINKED_BILLINGACC,
				variant: 'error',
			});
			this.dispatchEvent(evt);
			return;
		}
		// return the list if no duplicate record found
		else{
			return objLinkingList;
		}
	}

	/**
	 * function checks if field is undefined or null
	 * @param  field
	 * @returns boolean
	 */
	isUndefinedOrNull(field) {
		return (typeof field === 'undefined' || field === null);
	}
}