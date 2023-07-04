/**
*@author Nasir Jawed
*@date 2022-03-20
*@description:This page gets open when the button "Send for ESignature" is clicked from Contract page.It populated the key contact and opportunity driver from
*agreement and land to the LWC page.
*@changelog
*/
import {LightningElement,api,track} from 'lwc';
import getContractRecord from "@salesforce/apex/APT_HelptotheSellerControllerExtended.getContractRecord";
import addCC from "@salesforce/apex/APT_HelptotheSellerControllerExtended.addCC";
import editCC from "@salesforce/apex/APT_HelptotheSellerControllerExtended.editCC";
import deleteCC from "@salesforce/apex/APT_HelptotheSellerControllerExtended.deleteCC";
import docusignImage from "@salesforce/resourceUrl/APTSpendDelegationMatrix";
import sendForESignature from '@salesforce/label/c.Send_for_eSignature_Custom_Message';
import keyContactErrorMsg from '@salesforce/label/c.keyContactErrorMsg';
import { loadStyle } from "lightning/platformResourceLoader";
import APT_CSS_JS from '@salesforce/resourceUrl/APT_CSS_JS';


//Column for Opportunity Driver(User)
const columns =[
	{type: 'button-icon',initialWidth: 50 ,typeAttributes: {  iconName: 'utility:edit',	name: 'edit' }},
	{label: 'Full Name', fieldName: 'APT_Name__c'},
	{label: 'Email Address', fieldName: 'Apttus_DocuApi__Email__c'},
	{label: 'Recipient Type', fieldName: 'Apttus_DocuApi__RecipientType__c'},
	{label: 'Routing Order', fieldName: 'Apttus_DocuApi__SigningOrder__c'},
	{label: 'Notes', fieldName: 'Apttus_DocuApi__Note__c',initialWidth: 300}
];
//Column for Key contact(contact)
const customerColumns =[
	{type: 'button-icon' ,initialWidth: 50,typeAttributes: {  iconName: 'utility:edit',	name: 'edit' }},
	{label: 'Full Name', fieldName: 'APT_Name__c'},
	{label: 'Email Address', fieldName: 'Apttus_DocuApi__Email__c'},
	{label: 'Recipient Type', fieldName: 'Apttus_DocuApi__RecipientType__c'},
	{label: 'Routing Order', fieldName: 'Apttus_DocuApi__SigningOrder__c'},
	{label: 'Notes', fieldName: 'Apttus_DocuApi__Note__c',initialWidth: 300}
];
//Column for Carbon Copy
const ccColumns =[
	{type: 'button-icon' ,initialWidth: 50,typeAttributes: {  iconName: 'utility:edit',	name: 'edit' }},
	{type: 'button-icon' ,initialWidth: 50,typeAttributes: {  iconName: 'utility:delete',name: 'delete' }},
	{label: 'Full Name', fieldName: 'APT_Name__c'},
	{label: 'Email Address', fieldName: 'Apttus_DocuApi__Email__c'},
	{label: 'Recipient Type', fieldName: 'Apttus_DocuApi__RecipientType__c'},
	{label: 'Notes', fieldName: 'Apttus_DocuApi__Note__c',initialWidth: 300}
];

export default class APT_SendESignatureLWC extends LightningElement{

	label ={sendForESignature};
	@api recordId;//Agreement Id
	@api objectApiName='Apttus_DocuApi__DocuSignDefaultRecipient2__c';
	keyContactDocuSign;//contact Record
	userDocuSign;//User Record
	carbonCopyDocuSign; //CC Record
	keyContactPopUp;//contact Record
	userDocuPopUp;//User Record
	carbonCopyPopUp; //CC Record
	userDocuSignRecordType;//User RecordType for Docusign
	emailDocuSignRecordType;//Email RecordType for Docusign
	contactDocuSignRecordType;//contact RecordType for Docusign
	@track mapDataUser=[];//user array
	@track mapDataContact=[];//contact array
	@track mapDataCC=[];//contact array
	@track mapDataContactsList=[];//contact array two
	@track mapDataUserList=[];//user array two
	@track mapDataCCList=[];//user array two
	error;
	columns =columns;
	customerColumns =customerColumns;
	ccColumns = ccColumns;
	isLoading;
	isModalOpenAdd=false;
	isModalOpenUser=false;
	isModalOpenContact=false;
	docusignImage=docusignImage;
	navigationButton;
	navigationButtonVisibility;
	AddButtontrue;
	emailFieldValue = true;
	customerFieldValue = false;
	userFieldValue = false;

	//Calling the logic on load of component and passing the contract ID
	connectedCallback(){
		loadStyle(this, APT_CSS_JS );
		this.isLoading=true;
		this.navigationButtonVisibility=true;
		getContractRecord(
			{
				recordId: this.recordId
			})
			.then((result) =>{
				if(result != null){
					this.navigationButton=true;
					this.mapDataUserList= null;
					this.mapDataContactsList = null;
					this.mapDataCCList = null;
					//looping the return of docusign recipient record which got created from controller and assigning it to the array
					for(let key in result){
						// Filtering opportunity Driver record
						if(key==='user'){
							this.mapDataUser.push({key:key,value:result[key]});
							for(let usr in this.mapDataUser){
								this.mapDataUserList =this.mapDataUser[usr].value;
							}
						}
						// Filtering key contact record
						if(key==='contact'){
							this.mapDataContact.push({key:key,value:result[key]});
							for(let con in this.mapDataContact){
								this.mapDataContactsList = this.mapDataContact[con].value;
							}
						}
						// Filtering Carbon Copy record
						if(key==='cc'){
							this.mapDataCC.push({key:key,value:result[key]});
							for(let cc in this.mapDataCC){
								this.mapDataCCList = this.mapDataCC[cc].value;
							}
						}
					}
					this.isLoading = false;
				}else{
					this.isLoading = false;
					this.error = keyContactErrorMsg;
					this.AddButtontrue=true;
				}

			})
			.catch((error) =>{
				this.isLoading = false;
				this.error = error.body.message;
			})
	}
	get options() {
		return [
			{ label: 'Manually enter recipients details', value: 'Email' },
			{ label: 'Customer (Contact)', value: 'Customer' },
			{ label: 'Sales Professional (User)', value: 'User' },
		];
	}
	value = 'Email';
	carbonCopy ='Carbon Copy';
	handleRadioChange(event){
		const selectedOption = event.detail.value;

		if (selectedOption === 'Email'){
			this.isLoading = true;
			this.emailFieldValue = true;
			this.isLoading = false;
		}else{
			this.emailFieldValue = false;
			this.isLoading = false;
		}

		if (selectedOption === 'Customer'){
			this.isLoading = true;
			this.customerFieldValue = true;
			this.isLoading = false;
		}else{
			this.customerFieldValue = false;
			this.isLoading = false;
		}

		if (selectedOption === 'User'){
			this.isLoading = true;
			this.userFieldValue = true;
			this.isLoading = false;
		}else{
			this.userFieldValue = false;
			this.isLoading = false;
		}
		this.addCarbonCopyRecordType(selectedOption);
	}

	addCarbonCopyRecordType(selectedOption){
		this.isLoading = false;
		addCC({
			recordType: selectedOption
		})
		.then((result) =>{

			if(result != null){
				if(selectedOption === 'Email'){
					this.emailDocuSignRecordType=result;
					this.emailFieldValue = true;
					this.customerFieldValue = false;
					this.userFieldValue = false;
					this.isLoading = false;
				}
				if(selectedOption === 'Customer'){
					this.contactDocuSignRecordType=result;
					this.isLoading = false;
				}
				if(selectedOption === 'User'){
					this.userDocuSignRecordType=result;
					this.isLoading = false;
				}

			}
		})
		.catch((error) =>{
			this.isLoading = false;
		})

	}
	// logic to add Carbon copy on the DocuSign Recipient onject
	addCarbonCopy(){
		this.isLoading = true;
		this.isModalOpenAdd = true;
		this.addCarbonCopyRecordType(this.value);
		this.isLoading = false;
	}
	//closing the pop up fro Carbon copy
	closeModalAdd(){
		this.isLoading = false;
		this.isModalOpenAdd = false;
		this.connectedCallback();
	}
	handleRowActionUser(event){
		this.isLoading = true;
		this.isModalOpenUser = true;
		const actionName = event.detail.action.name;
		const fullrow = JSON.stringify(event.detail.row);
		this.userDocuSign =event.detail.row.Id;
		this.userDocuSignRecordType = event.detail.row.RecordTypeId;
		this.isLoading = false;
	}
	handleSuccess(event){
		this.isModalOpenUser = false;
		this.isModalOpenContact = false;
		this.isModalOpenEditCC = false;
		this.isModalOpenAdd = false;
		this.isLoading = false;
		this.connectedCallback();
	}
	handleRowActionContact(event){
		this.isLoading = true;
		this.isModalOpenContact = true;
		const actionName = event.detail.action.name;
		const fullrow = JSON.stringify(event.detail.row);
		this.keyContactDocuSign =event.detail.row.Id;
		this.isLoading = false;
	}
	handleRowActionCC(event){

		const actionName = event.detail.action.name;
		if(actionName === 'edit'){
			this.isLoading = true;
			this.isModalOpenEditCC = true;
			const fullrow = JSON.stringify(event.detail.row);

			editCC({
				id: event.detail.row.Id
			})
			.then((result) =>{
				if(result === 'Email'){
					this.carbonCopyDocuSign =event.detail.row.Id;
					this.carbonCopyPopUp = true;
					this.userDocuPopUp = false;
					this.keyContactPopUp = false;
				}
				if(result === 'User'){
					this.userDocuSign =event.detail.row.Id
					this.userDocuPopUp = true;
					this.carbonCopyPopUp = false;
					this.keyContactPopUp = false;
				}
				if(result === 'Customer'){
					this.keyContactDocuSign =event.detail.row.Id
					this.keyContactPopUp = true;
					this.userDocuPopUp = false;
					this.carbonCopyPopUp = false;
				}
			})
			.catch((error) =>{
				this.isLoading = false;
			})


			this.isLoading = false;
			this.connectedCallback();
		}

		if(actionName === 'delete'){
			console.log('actionRow:'+ event.detail.row.Id);
			deleteCC({
				id: event.detail.row.Id
			})
			.then((result) =>{
				if(result === true){
					this.connectedCallback();
				}
			})
			.catch((error) =>{
				this.isLoading = false;
			})

		}

	}

	//to close modal set isModalOpenContact track value as false
	closeModalCC(){
		this.isLoading = false;
		this.isModalOpenEditCC = false;
		this.connectedCallback();
	}

	//to close modal set isModalOpenContact track value as false
	closeModalContact(){
		this.isLoading = false;
		this.isModalOpenContact = false;
		this.connectedCallback();
	}
	//to close modal set isModalOpenUser track value as false
	closeModalUser(){
		this.isLoading = false;
		this.isModalOpenUser = false;
		this.connectedCallback();
	}

	//calling the standard method to add the Carbon copy and inserting the record
	handleSubmit(event){
		const fields = event.detail.fields;
		fields.Apttus_CMDSign__AgreementId__c = this.recordId;
		fields.Apttus_DocuApi__RecipientType__c = 'Carbon Copy';

		if(this.value === 'Email'){
			fields.RecordTypeId = this.emailDocuSignRecordType;
		}
		if(this.value === 'User'){
			fields.APT_Docusign_Recipient_Type__c = 'Sales user';
			fields.RecordTypeId = this.userDocuSignRecordType;
		}
		if(this.value === 'Customer'){
			fields.APT_Docusign_Recipient_Type__c = 'Customer';
			fields.RecordTypeId = this.contactDocuSignRecordType;
		}

		this.template.querySelector('lightning-record-edit-form').submit(fields);
	}
	//Redircting the user to agreement page
	get handleBackToContract(){
		this.isLoading = true;
		return (this.sfdcBaseURL = window.location.origin + '/lightning/r/Apttus__APTS_Agreement__c/'+this.recordId+'/view');
	}

	//Redircting the user to attachment page
	get navigateToAttachmentsPage(){
		this.isLoading = true;
		return (this.sfdcBaseURL = window.location.origin + '/apex/Apttus_CMDSign__CMDocuSignCreateEnvelope?id='+this.recordId);
	}
}