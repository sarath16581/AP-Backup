/**
 * @author Harry Wang
 * @date 2022-07-11
 * @group Controller
 * @tag Controller
 * @domain ICPS
 * @description Javascript Controller for ICPS Clone.
 * @changelog
 * 2022-07-11 - Harry Wang - Created
 */
import {LightningElement, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import printLabel from '@salesforce/apex/ICPSServiceController.printLabel';

export default class IcpsPrintLabel extends LightningElement {
	@api recordId;

	@api invoke() {
		let event = new ShowToastEvent({
			title: 'Label Print',
			message: 'Processing...',
			variant: 'info'
		});
		this.dispatchEvent(event);
		// print label
		printLabel({
			icpsId: this.recordId
		}).then(result => {
			if (result && result.icpsName && result.pdfStream) {
				this.fileDownload(result.icpsName, result.pdfStream);
			}
		}).catch(error => {
			let event = new ShowToastEvent({
				title: 'ICPS Label Printing Failed',
				message: 'An Error occurred when printing label: ' + error.body.message,
				variant: 'error'
			});
			this.dispatchEvent(event);
		});
	}

	/**
	 * Get PDF stream from label print service and download it locally
	 */
	fileDownload(icpsName, pdfStream){
		let a = document.createElement("a");
		a.href = "data:application/pdf;base64," + pdfStream;
		a.download = 'ICPSLabel - '+ icpsName + '.pdf';
		a.click();
	}
}