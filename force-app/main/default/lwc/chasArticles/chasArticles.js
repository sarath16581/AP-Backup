/**
 * @description Component showing list of articles
 * @author Edgar Allan Castillo
 * @date 2022-02-22
 * @group Help&Support
 * @changelog
 */

import { LightningElement, api, track } from 'lwc';
export default class ChasArticles extends LightningElement {
  @api articles = [];
  @track data = [];
  totalArticles = 0;

  connectedCallback() {
    this.totalArticles = this.articles.length;
    for (var i = 0; i < this.totalArticles; i++) {
      this.data.push({
        articleCount: (i + 1),
        selected: this.articles[i].isSelected,
        articleId: this.articles[i].articleId,
        articleStatusCode: this.articles[i].trackStatusValue,
        articleStatusMsg: this.articles[i].trackStatusValue
      });
    }
  }

  isSelected(event) {
    const isSelected = new CustomEvent("isselected", {
      detail: {
        articleId: event.detail.articleId,
        articleSelected: event.detail.articleSelected
      }
    });
    
    this.dispatchEvent(isSelected);
  }  
}