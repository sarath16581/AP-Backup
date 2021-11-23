/**
  * @author       : Sameed Khan<sameed.khan@mav3rik.com>
  * @date         : 01/05/2019
  * @description  : Component that searches customers to provides auto complete
--------------------------------------- History --------------------------------------------------
01.04.2019    Sameed Khan(Mav3rik)    Created
**/

import { LightningElement, api, wire } from 'lwc'
import getMinLOA from '@salesforce/apex/CustomerSearchCtrl.getMinLOA'

export default class CustomerSearch extends LightningElement {
    @api searchResultSelectHandler
    @api label = 'Customer lookup'
    @api fieldLevelHelp = 'Enter customer email or phone number (details will auto-populate if known customer).'
    @api required = false

    @wire(getMinLOA)
    minLOA

    titleFormatter = record => {
        if (record.IsPersonAccount) {
            let title = `${record.Name} (Consumer)`
            if (record.CRMCSSOID__c) {
                title = `${title} · CSSO`
            }
            if (record.LevelOfAssurance__c && this.minLOA.data && record.LevelOfAssurance__c > this.minLOA.data) {
                title = `${title} · Verified`
            }
            return title
        }
        return `${record.Name} | ${record.Account.Name}`
    }

    subtitleFormatter = record => {
        const additionalFieldData = Object.entries(record)
            .filter(([key, value]) => !!(['Name', 'MobilePhone', 'Email'].includes(key) && !!value))
            .reduce((acc, [, value]) => {
                return acc ? `${acc}  ·  ${value}` : `${value}`
            }, '')
        return additionalFieldData
    }
}