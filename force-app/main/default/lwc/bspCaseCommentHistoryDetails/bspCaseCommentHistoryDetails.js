import { LightningElement, api, track} from 'lwc';
import { checkAllValidity, valueMissingErrorMsg, topGenericErrorMessage, reloadPage} from 'c/bspCommonJS';
import addComment from '@salesforce/apex/bspEnquiryDetailUplift.addComment';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';

export default class BspCaseCommentHistoryDetails extends LightningElement {

    @api commHistoryList;
    @api caseStatus;
    @api caseId;
    @api caseRecordTypeName;
    @track uploadedFiles=[];
    @api existingFiles;

    @api casePermanentClose;

    errormessage;
    requiredValMissingErrorMsg = valueMissingErrorMsg;

    activeSections=['All'];

    communityURL;

    get isCaseIsClosed() {
        if (this.caseStatus) {
            if (this.caseStatus.toLowerCase() == 'closed' && this.casePermanentClose && 
                this.caseRecordTypeName.startsWith('SSSW')){
                return true;
            }
            else if (this.caseStatus.toLowerCase() == 'closed' &&  this.caseRecordTypeName.startsWith('StarTrack')){
                return true;
            }   
            else {
                return false;
            }
        } else {
            return false;
        }
    }

    get hasFiles(){
        return (this.existingFiles != null && this.existingFiles.length > 0) ? true : false;
    }

    /**
      * fileupload eventHandler
      **/
    onFileUploadHandler(event) {
        if (this.uploadedFiles.length > 0)
            this.uploadedFiles = this.uploadedFiles.concat(event.detail);
        else
            this.uploadedFiles = event.detail;
    }

    onSuccessfullAttachmentInsert(event) {
        if (this.existingFiles.length > 0)
            this.existingFiles = event.detail.concat(this.existingFiles);
        else
            this.existingFiles = event.detail;
    }

    handleSubmitComment(){
        this.errorMessage = null;
        const allValid = checkAllValidity(this.template.querySelectorAll('lightning-textarea'),false);
        
        if (allValid) {
            this.fireEventToToggleLoading(true);

            addComment({
                enqId: this.caseId,
                CommentBodyMsg: this.template.querySelectorAll('[data-id="addComments"]')[0].value,
                //uploadedFiles: this.uploadedFiles,
                caseRecordTypeName:this.caseRecordTypeName,
                caseStatus: this.caseStatus
            }).then(result => {
                reloadPage(false);
                this.fireEventToToggleLoading(false);
            }).catch(error => {
               // alert(JSON.stringify(error));
                this.fireEventToToggleLoading(false);
                this.errorMessage = error.body.message;
            } );
        } else
            this.errorMessage = topGenericErrorMessage;

    }

    fireEventToToggleLoading(val){
        const selectedEvent = new CustomEvent('loadingtoggle', { detail: val });
        this.dispatchEvent(selectedEvent);
    }


    async connectedCallback() {
        try {
            this.communityURL = await retrieveBspCommunityURL();
        } catch (er) {
            console.error(er)
        }
    }

    /*reloadPage(isWithCache){
        window.location.reload(isWithCache); 
    }*/


}