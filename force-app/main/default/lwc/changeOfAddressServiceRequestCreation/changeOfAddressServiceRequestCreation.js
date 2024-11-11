import { LightningElement, api } from 'lwc';
import frameServicerequests from '@salesforce/apex/ChangeOfAddressController.frameServicerequests';


export default class ChangeOfAddressServiceRequestCreation extends LightningElement {
	@api accountRecord;//This scenario is only applicable for (Enterprise, Financial, Intermediaries) Account Types. This covers Billing Account selection for both AP and ST Accounts.
	@api accountId ='001Qy00000YiHpbIAF';  //remove this later
	@api newBillingAddress;
	@api newPhysicalAddress;
	@api currentBillingAddress;
	@api currentPhysicalAddress;
	@api billingAccsSelectedAP = [];
	@api billingAccsSelectedST = [];
	@api productSelected; // Potential values AP, ST, Both
	creditDSRAPRec;
	creditDSRSTRec;
	onboardingDSRSTRec;
	phyAddressAPMessage;
	emailCaseAPRec;
	emailCaseSTRec;
	title;
	filter = {};    
	//customer request attachment has to be created as CV and 2 CDL's has to be created

    get acceptedFormats() {
        return ['.csv', '.png'];
    }
	connectedCallback() {
		this.title='Service Request Form';
		this.frameServicerequests();
		this.accountId ='001Qy00000YiHpbIAF';
		this.filter = {
            criteria: [
				{
					fieldPath: 'AccountId',
					operator: 'eq',
					value: this.accountId,
				}
			]
        };

	}
    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        console.log('No. of files uploaded : ' + uploadedFiles.length);
		
		if(this.creditDSRAPRec){
			let creditDSRAPReclocal = this.creditDSRAPRec;
			creditDSRAPReclocal.Customer_Request_Attached__c = 'Yes';
			this.creditDSRAPRec = JSON.parse(JSON.stringify(creditDSRAPReclocal));
		}
		if(this.creditDSRSTRec){
			let creditDSRSTReclocal = this.creditDSRSTRec;
			creditDSRSTReclocal.Customer_Request_Attached__c = 'Yes';
			this.creditDSRSTRec = JSON.parse(JSON.stringify(creditDSRSTReclocal)); //both ways works direct assignment or parse and stringify
		}
		if(this.onboardingDSRSTRec){
			let onboardingDSRSTReclocal = this.onboardingDSRSTRec;
			onboardingDSRSTReclocal.Customer_Request_Attached__c = 'Yes';
			this.onboardingDSRSTRec = JSON.parse(JSON.stringify(onboardingDSRSTReclocal)); //both ways works
		}
		// If the record-id  is passed in the file uploader in html, no need of creating any cdl. the relationship will get created by the system
		// if there is no record-id then this will give you uploadedFiles[0].documentId, contentdocument id and  cdl has to be created in code.
		console.log('content document id ' + uploadedFiles[0].documentId); 
		console.log('content document name ' + uploadedFiles[0].name);
	}

	getapPhysicalAddressChange(){
		if(this.productSelected==='AP' || this.productSelected==='Both'){
			if(this.isPhysicalAddressChanged){
				return true;
			}
		}
		return false;
	}
	
	handleContactSelection(event){
		const contactid = event.detail.recordId;
		const calledfromname = event.target.name;
		if(calledfromname === 'stcustomercontact'){
			let emailCaseSTReclocal = this.emailCaseSTRec;
			emailCaseSTReclocal.customerContact = contactid;
			this.emailCaseSTRec = JSON.parse(JSON.stringify(emailCaseSTReclocal));
		}else if(calledfromname === 'apcustomercontact'){
			let emailCaseAPReclocal = this.emailCaseAPRec;
			emailCaseAPReclocal.customerContact = contactid;
			this.emailCaseAPRec = JSON.parse(JSON.stringify(emailCaseAPReclocal));
		}
		
	}

	frameServicerequests(){
		const requestDetails = {};
		//commented this and needs to be uncommented when values from child cmp passes correctly start
        /*requestDetails.apBillingAccCount = this.billingAccsSelectedAP?this.billingAccsSelectedAP.length:0;
        requestDetails.stBillingAccCount = this.billingAccsSelectedST?this.billingAccsSelectedST.length:0;
        requestDetails.customerRequestAttached = 'No';
		requestDetails.baOptionSelected = this.productSelected;
		requestDetails.accType = this.accountRecord.Sales_Segment__c;
		requestDetails.newBillingAddress = this.newBillingAddress;
		requestDetails.isBillingAddressChanged = this.newBillingAddress? true : false;
		requestDetails.isPhysicalAddressChanged = this.newPhysicalAddress? true : false;
		requestDetails.newPhysicalAddress = this.newPhysicalAddress;
		requestDetails.accountId = this.accountId;
		requestDetails.accountRecord = this.accountRecord; */
		//commented this and needs to be uncommented when values from child cmp passes correctly end
		//remove this when values from child cmp passes correctly start

		//remove this when values from child cmp passes correctly end
		requestDetails.apBillingAccCount = 5;
		requestDetails.stBillingAccCount = 5;
		requestDetails.customerRequestAttached = 'No';
		requestDetails.baOptionSelected = '';
		requestDetails.accType = 'Small Business'; // modify the value to [requestDetails.accType = "Small Business"] to render email to case sections
		requestDetails.newBillingAddress = 'test new billing address';
		requestDetails.isBillingAddressChanged = true;
		requestDetails.isPhysicalAddressChanged = true;
		requestDetails.newPhysicalAddress = 'test new physical address';
		requestDetails.orgId = '001Qy00000YiHpbIAF';
		
		frameServicerequests({reqParams: requestDetails})
		.then(result => {
			// Returned result if from sobject and can't be extended so objectifying the result to make it extensible
			if(!result.error){
				if(result.creditDSRAPRec){
					this.creditDSRAPRec = result.creditDSRAPRec;
				}
				if(result.creditDSRSTRec){
					this.creditDSRSTRec = result.creditDSRSTRec;
				}
				if(result.onboardingDSRSTRec){
					this.onboardingDSRSTRec = result.onboardingDSRSTRec;
				}
				if(result.emailCaseAPRec){
					this.emailCaseAPRec = result.emailCaseAPRec;
				}
				if(result.emailCaseSTRec){
					this.emailCaseSTRec = result.emailCaseSTRec;
				}
			}else if(result.error){
				this.error = result.error;
			}
		})
		.catch(error => {
			this.error = error;
			console.log('error : ' + JSON.stringify(this.error));
		});
	}

}