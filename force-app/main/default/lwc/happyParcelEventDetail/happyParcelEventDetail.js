/**
 * @description Happy Parcel Event Details
 * @author Mathew Jose
 * @date 2021-10-04
 * @group Tracking
 * @changelog
 */
 import { LightningElement, api} from "lwc";
 import HappyParcelBase from "c/happyParcelBase";
 
 export default class HappyParcelEventDetails extends HappyParcelBase {
 
    @api loading = false;
    //Field with values to be passed by the parent.
    @api fields;
    //event id associated with the event message
    @api eventId;
    //style class to be applied to the component.
    @api variant;

 
     // this is used to merge the schema and the data together into a single array item
     // we do this just in time since there is no way of knowing whether record or config will be delivered to the component first
    get fieldsIterator() {
        const animationDelayIncrementor = 10;
        let animationDelay = parseInt(this.animationDelay, 10);

        let fields = this.fields.map(item => {
            animationDelay += animationDelayIncrementor;
            return {...item, animationCss: this.getAnimationStyleCss(animationDelay)}
        });
            // only return the fields that contain a value
        return fields.filter(item => item.fieldValue);
    }
 
    get waiting() {
        return this.loading;
    }
 
    get heading() {
        return  'More details';
    }
    //Used to close the overflow popup by firing an event to the parent.
    closeOverflowModal(event) {
        this.dispatchEvent(new CustomEvent('closeoverflowview', {detail: this.eventId}));
    }    
 
 
 }