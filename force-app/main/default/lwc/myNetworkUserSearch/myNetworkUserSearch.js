import { LightningElement, api } from 'lwc';

export default class MyNetworkUserSearch extends LightningElement {
    @api searchResultSelectHandler
    @api label = 'MyNetwork User lookup'
    @api fieldLevelHelp = 'Enter User Name.'
    @api required = false

    titleFormatter = record => {       
        return `${record.Name}`
    }
    subtitleFormatter = record => {
        const additionalFieldData = Object.entries(record)
            .filter(([key, value]) => !!(['Name', 'Email'].includes(key) && !!value))
            .reduce((acc, [, value]) => {
                return acc ? `${acc}  ·  ${value}` : `${value}`
            }, '')
        return additionalFieldData
    }
}