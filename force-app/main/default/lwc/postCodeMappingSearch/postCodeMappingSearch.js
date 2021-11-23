import { LightningElement, api,track } from 'lwc';
 
export default class PostCodeMappingSearch extends LightningElement {
    @api searchResultSelectHandler
    @api label = 'PostCode lookup'
    @api fieldLevelHelp = 'Enter postCode or Suburb'
    @api required = false
    @api selectedPostCode;
    @track postCodeSelectedFlag = false;
    @track pillItemVar;
    titleFormatter = record => {       
        return `${record.APT_Post_Code__c}`
    }
    searchResultSelectHandler = record =>{
        const pillItemVar={};
        if(this.selectedPostCode){
            this.postCodeSelectedFlag = true;
            pillItemVar = {
                    type: 'icon',
                    Name: this.selectedPostCode.Name,
                    iconName: "standard:contact",
                
            };
        }
        return pillItemVar
    }
    connectedCallback(){
        if(this.selectedPostCode){
            this.postCodeSelectedFlag = true;
            this.pillItemVar = {
                    type: 'icon',
                    Name: this.selectedPostCode.Name,
                    iconName: "standard:contact",
                
            };
            //this.template.querySelector("c-lookup").setSelectedRecord(this.pillItemVar);
            var cmpRec  = this.template.querySelector("c-lookup");
        }
       
        //this.searchResultSelectHandler = this.pillItemVar;
    }
    subtitleFormatter = record => {
        const additionalFieldData = Object.entries(record)
            .filter(([key, value]) => !!(['APT_Post_Code__c', 'APT_Suburb__c'].includes(key) && !!value))
            .reduce((acc, [, value]) => {
                return acc ? `${acc}  ·  ${value}` : `${value}`
            }, '')
        return additionalFieldData
    }
    
}