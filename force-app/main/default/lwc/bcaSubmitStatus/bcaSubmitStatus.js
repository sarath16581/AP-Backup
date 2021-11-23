import { LightningElement, api } from 'lwc';

export default class BcaSubmitStatus extends LightningElement {

    iconName;
    @api caSubmitResults;

    get getIcon() {
        if (this.caSubmitResults.status) {
            if (this.caSubmitResults.status == 'error') {
                this.iconName = 'round-cross-filled';             
            }else{
                this.iconName = 'round-tick-filled';                     
            }
        }
        return this.iconName;
    }
    
}