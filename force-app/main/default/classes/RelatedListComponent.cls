/**************************************************
Type:       Utility class to create Dynamic RelatedList visualforce component
Purpose:    Creates Dynamic RelatedList visualforce component using the supplied custom settings or the related list parameters
Used By:    CaseContactSidepanelContExt.cls, ContactInteractionViewComponentCont.cls          
History:
--------------------------------------------------
22.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

public with sharing class RelatedListComponent
{   
    public static Component.Apex.RelatedList getRelatedList(Id subject, Id parentFieldValue, CaseContactSidePanelTabSettings__c setting)
    {
        return getRelatedList(subject,
                              parentFieldValue,
                              setting.RelationshipName__c,
                              setting.FieldList__c,
                              setting.ObjectName__c,
                              setting.ParentFieldName__c,
                              setting.Filters__c,
                              setting.LinkableField__c,
                              setting.TabLabel__c,
                              setting.HideButtons__c,
                              '500');//TODO: get the value from the custom setting
    } 
    
    public static Component.Apex.RelatedList getRelatedList(Id subject, Id parentFieldValue, InteractionViewRelatedListSettings__c setting) 
    {
        return getRelatedList(subject,
                              parentFieldValue,
                              setting.RelationshipName__c,
                              setting.FieldList__c,
                              setting.ObjectName__c,
                              setting.ParentFieldName__c,
                              setting.Filters__c,
                              setting.LinkableField__c,
                              setting.SectionLabel__c,
                              setting.HideButtons__c,
                              setting.Limit__c);
    }
    
    /*
     * subject and parentFieldValue are the same except in the case of person accounts, where the parentFieldValue is the related contact Id
     */ 
    public static Component.Apex.RelatedList getRelatedList(Id subject, Id parentFieldValue, String relatedList, String fieldList, String objectName, 
            String parentField, String filters, String linkableField, String newLabel, Boolean hideButtons, String lim) 
    {
        Component.Apex.RelatedList rl = new Component.Apex.RelatedList();
        rl.list = relatedList;
        rl.subject = subject;   
        rl.title = newLabel;
        
        Component.Apex.PageblockTable pbt = new Component.Apex.PageblockTable();
        String query = 'SELECT ' + fieldList + 
                       ' FROM ' + objectName +
                       ' WHERE ' + parentField + ' = :parentFieldValue';
        if (filters != null) 
        {
            query += ' AND ' + filters;
        }
        query += ' ORDER BY CreatedDate DESC LIMIT ' + (String.isNotBlank(lim) && lim.isNumeric() ? lim : '500');
        pbt.value = Database.query(query);
        pbt.var = 'v';
        pbt.id = relatedList;
        
        for (String f : fieldList.split(',')) 
        {
            Component.Apex.Column c = new Component.Apex.Column();
            if (f == linkableField) 
            {
                c.expressions.headerValue = '{!$ObjectType.' + objectName + '.fields.' + f + '.label}';
                
                Component.Apex.OutputLink ol = new Component.Apex.OutputLink();
                ol.expressions.value = '/{!v.Id}';
                ol.styleClass = 'linkedField';
                ol.expressions.title = '{!v.Id}';
                
                Component.Apex.OutputField of1 = new Component.Apex.OutputField();
                of1.expressions.value = '{!v.' + f + '}';
                
                ol.childComponents.add(of1);
                c.childComponents.add(ol);
            } 
            else 
            {
                c.expressions.value = '{!v.' + f + '}';
            }
            pbt.childComponents.add(c);
        }
        
        rl.facets.body = pbt;
        
        if (hideButtons) 
        {
            Component.Apex.OutputText listHeader = new Component.Apex.OutputText();
            listHeader.value = newLabel;
            listHeader.style = 'font-weight:bold;font-size: 1.3em;color:black;padding-left:11px;';
			rl.facets.header = listHeader;
            rl.facets.footer = new Component.Apex.OutputPanel();
        }
        
        return rl;
    }
}