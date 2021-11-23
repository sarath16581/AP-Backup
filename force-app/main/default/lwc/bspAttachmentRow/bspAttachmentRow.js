import { LightningElement, api } from 'lwc';

export default class BspAttachmentRow extends LightningElement {

    @api attachmentId;
    @api attachmentName;
    @api communityURL;


    get downloadAttachmentLink() {
        if (this.communityURL && this.attachmentId)
            return this.communityURL + '/servlet/servlet.FileDownload?file='+this.attachmentId;
        else
            return '#';
    }
}