import { LightningElement, track ,api } from 'lwc';
 
export default class PostCodeMappingSearchWrapper extends LightningElement {
    @track selectedPostCodeRecord;
    @api selectedPostCode;
    connectedCallback(){
        if(this.selectedPostCode){
            const value = { 
                        Id: this.selectedPostCode.Id,
                        Name:this.selectedPostCode.Name
                    };
            const valueChangeEvent = new CustomEvent("selectedpostcode", {
                detail: {value}
              });
              this.dispatchEvent(valueChangeEvent);
        }
    }
    searchResultSelectHandler = (record) => {
        this.selectedPostCodeRecord = record;
        const value = record;
        const valueChangeEvent = new CustomEvent("selectedpostcode", {
            detail: { value }
          });
          // Fire the custom event
          this.dispatchEvent(valueChangeEvent);
    }
}