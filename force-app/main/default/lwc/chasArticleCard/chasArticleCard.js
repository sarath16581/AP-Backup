/**
 * @description Component showing individual article
 * @author Edgar Castillo
 * @date 2022-02-22
 * @group Help&Support
 * @changelog
 */

import { LightningElement, api } from 'lwc';

export default class ChasArticleCard extends LightningElement {
  @api articleItem;
  @api totalItem;
  item;
  articleId;
  articleStatus;
  articleLabel;
  articleSelected = false;

  statusDelivered = [
    "Delivered",
    "Awaiting collection",
    "Estimated delivery by",
    "Returned"
  ];

  statusOnItsWay = [
    "It's on its way",
    "It's coming today",
    "In transit",
    "Accepted by driver",
    "Onboard with driver",
    "Transferred"
  ];

  statusReturnToSender = [
    "Returning to sender",
    "Possible delay",
    "Returned to sender",
    "Contact sender",
    "Unsuccessful pickup",
    "Attempted delivery",
    "Undeliverable",
    "Unknown"
  ];

  statusDespatched = [
    "Despatched",
    "We've got it",
    "Your parcel is coming",
    "Started",
    "Processing",
    "Initiated",
    "Manifested",
    "Lodged",
    "Started",
    "Ready for processing"
  ];

  statusReturnToSender = [
    "Contact sender"
  ]

  connectedCallback() {
    this.articleId=this.articleItem.articleId;
    this.articleStatus=this.articleItem.articleStatusCode;
    this.articleLabel="ITEM " + this.articleItem.articleCount + " OF " + this.totalItem;
    this.articleSelected = this.articleItem.selected;
  }

  isSelected(event) {
    this.articleSelected = event.target.checked;
    const isSelected = new CustomEvent("isselected", {
      detail: {
        articleId: this.articleId,
        articleSelected: this.articleSelected
      }
    });
    this.dispatchEvent(isSelected);
  }

  get getStatusClass() {
    let bgColor;
    if (this.statusDelivered.includes(this.articleStatus)) {
      bgColor = 'status-delivered';
    } else if (this.statusOnItsWay.includes(this.articleStatus)) {
      bgColor = 'status-on-its-way';
    } else if (this.statusReturnToSender.includes(this.articleStatus)) {
      bgColor = 'status-return-to-sender';
    } else if (this.statusDespatched.includes(this.articleStatus)) {
      bgColor = 'status-despatched';
    } else if (this.statusReturnToSender.includes(this.articleStatus)) {
      bgColor = 'status-contact-sender';
    } else {
      bgColor = 'status-default';
    }
    
    return bgColor;
  }
}