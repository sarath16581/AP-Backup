import { LightningElement, api } from 'lwc';

export default class ArticleItem extends LightningElement {
    @api article
    
    columns = [
        { label: 'Label', fieldName: 'name' },
        { label: 'Website', fieldName: 'website', type: 'url' },
        { label: 'Phone', fieldName: 'phone', type: 'phone' },
        { label: 'Balance', fieldName: 'amount', type: 'currency' },
        { label: 'Close Date', fieldName: 'closeAt', type: 'date' },
    ] 
}