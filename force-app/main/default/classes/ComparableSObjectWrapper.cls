/**************************************************
Type:       Wrapper class for SObjects that makes them comparable
Purpose:	Makes an SObject comparable by the given Number type field
Used By: 	for eg to sort a list of SObjects based on a Number field value            
History:
--------------------------------------------------
14.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

public class ComparableSObjectWrapper implements Comparable 
{
	public SObject sObj;
	
	private String fieldToCompare;

	/*
	 * parameter sObj : wrapped SObject
	 * parameter fieldToCompare : the Number type field of which values are used to compare the SObjects
	 */
	public ComparableSObjectWrapper(SObject sObj, String fieldToCompare) 
	{
    	this.sObj = sObj;
    	this.fieldToCompare = fieldToCompare;
	}
	
    public Integer compareTo(Object compareTo) 
    {   
    	SObject cSObj = ((ComparableSObjectWrapper)compareTo).sObj;
        
        Object val1 = sObj.get(fieldToCompare);
        Object val2 = cSObj.get(fieldToCompare);
        if (val1 instanceof Decimal && val2 instanceof Decimal) 
        {
        	return compare((Decimal)val1, (Decimal)val2);
        }
        return 0;//considered equal?
    }
    
    public Integer compare(Decimal d1, Decimal d2) 
    {
    	return d1 > d2
    		? 1
    		: d1 < d2
    			? -1
    			: 0;
    }
}