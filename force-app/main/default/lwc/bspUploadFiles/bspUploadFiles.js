/*
* @author		: Jansi Rani. jansi.rani@auspost.com.au
* @date			: 21/08/2020
* @description	: Component for Uploading files.
* @changes		:
*				23/08/2023 Hasantha Liyanage : allow by pass accepted file formats
*/
import { LightningElement, track, api } from 'lwc';
import userId from '@salesforce/user/Id';
import { acceptedFileFormats } from 'c/bspCommonJS';
import deleteAttachment from '@salesforce/apex/bspEnquiryUplift.deleteAttachment';
import insertFiles from '@salesforce/apex/bspBaseUplift.insertFiles';

export default class BspUploadFiles extends LightningElement {

	// @api existingFiles;
	currentUserId = userId;
	acceptedFormats = acceptedFileFormats;
	fileUploadLabel = 'Attach a document or image (e.g. Proof of delivery or wholesale invoice)';
	isLoading = false;

	@track uploadedFiles = [];
	//-- the recod to which file is attached
	@api recordId;
	@api acceptedFormatOverWrite;
	@api labelOverWrite;

	currentFiles = [];

	connectedCallback() {
		if(this.acceptedFormatOverWrite) {
			this.acceptedFormats = this.acceptedFormatOverWrite;
		}
		if(this.labelOverWrite) {
			this.fileUploadLabel = this.labelOverWrite;
		}
	}

	/**
	 * Handler after file uploaded successfully 
	 */
	onUploadFinished(event) {
		this.currentFiles = event.detail.files;

		//--- if recordId --- then inserting attachment
		if (this.recordId) {
			this.isLoading = true;
			insertFiles({ parentId: this.recordId, uploadedFiles: this.currentFiles })
				.then(result => {
					console.log('successfully inserted attachments');
					this.isLoading = false;
					this.fireEventWithAttachments(result);
				}).catch(error => {
					console.error(error);
					this.isLoading = false;
					this.removecurrentFiles();  // error while inserting attchment so...removing fom list
				});
		} 
		else {
			if (this.uploadedFiles.length > 0)
				this.uploadedFiles = this.uploadedFiles.concat(event.detail.files);
			else
				this.uploadedFiles = event.detail.files;
			
				//fire an event 
			this.fireEventWithFiles();
		}
	}

	/**
	 * Handler to delete a uploaded file 
	 */
	onDeleteUpload(event) {
		this.isLoading = true;
		let fileId = event.target.dataset.id;
		deleteAttachment({ fileId: fileId })
			.then(result => {
				console.log('file:' + fileId + ' removed');
				this.removeFromUploadedByFileId(fileId);
				this.isLoading = false;
				//fire an event
				this.fireEventWithFiles();
			}).catch(error => {
				console.error('error occured');
				console.error(error);
				this.isLoading = false;
			});
	}

	/**
	 *firing event to send the files
		*/
	fireEventWithFiles() {
		const selectedEvent = new CustomEvent('fileupload', { detail: this.uploadedFiles });
		this.dispatchEvent(selectedEvent);
	}

	/**
	 *firing event to send the files
		*/
	fireEventWithAttachments(result) {
		let uploadedAttachments = [];
		for (var key in result) {
			uploadedAttachments.push({
				value: result[key],
				key: key
			});
		}
		const selectedEvent = new CustomEvent('successfullattachmentinsert', { detail: uploadedAttachments });
		this.dispatchEvent(selectedEvent);
	}

	/**
		 * Removing the file from the display list. the files are uploaded against the user, 
		 * only attached to the case at submit
		 * @param fileId
		 */
	removeFromUploadedByFileId(fileId) {
		for (let i = 0; i < this.uploadedFiles.length; ++i) {
			let objFile = this.uploadedFiles[i];
			if (objFile.documentId == fileId) {
				this.uploadedFiles.splice(i, 1);
				return;
			}
		}
	}

	removecurrentFiles() {
		if (this.currentFiles) {
			for (let k = 0; k < this.currentFiles.length; ++k) {
				for (let i = 0; i < this.uploadedFiles.length; ++i) {
					if (this.uploadedFiles[i] == this.currentFiles[0]) {
						this.uploadedFiles.splice(i, 1);
						return;
					}
				}
			}
			
		}

	}

	get parentId() {
		if (this.recordId)
			return this.recordId;
		else
			this.currentUserId;
	}

	get hasFiles() {
		return (this.uploadedFiles != null && this.uploadedFiles.length > 0) ? true : false;
	}

}