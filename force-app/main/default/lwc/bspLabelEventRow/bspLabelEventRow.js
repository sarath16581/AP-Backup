import { LightningElement, api } from "lwc";
import { convertToFormattedDateStr } from 'c/bspCommonJS';

export default class BspLabelEventRow extends LightningElement {
  @api le;
  @api isConsignmentAuthenticated;
  @api isCEAttachmentsExists;
  @api selectedEventArticle;
  @api isConsignmentSerchIsAPType;

  get isCENotesAttachmentsExists() {
    return this.le.NotesAndAttachments ? this.le.NotesAndAttachments.length > 0 ? true : false : false;
  }

  get isCurrentAndSelectedArticleIsSame() {
    return this.le ? this.le.Article__c == this.selectedEventArticle ? true : false : false;
  }

  get articleLinkClass() {
    return this.isCurrentAndSelectedArticleIsSame ? "no-underline-dec brand-link-button" : "underline-dec brand-link-button";
  }

  selectEventArticle() {
    //event.preventDefault();
    this.selectedEventArticle = this.le.Article__c;
    this.dispatchAnEventWithSelectedArticle(this.selectedEventArticle);
    //return false;
  }

  dispatchAnEventWithSelectedArticle(selectedArticle) {
    const c = new CustomEvent("selectedarticlechange", { detail: selectedArticle });
    this.dispatchEvent(c);
  }

  get podHref(){
    return '/bsp/POD_Redirect?id=' + this.le.Id;
  }

  get stFormattedActualDateTimeStr(){
    return this.le.ActualDateTime_TimeStamp__c ? convertToFormattedDateStr(this.le.ActualDateTime_TimeStamp__c) : '';
  }
}