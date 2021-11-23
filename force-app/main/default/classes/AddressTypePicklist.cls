/**
 * @author alexvolkov
 * @date 31/1/20
 * @description Address Type picklist for App builder derived from Address Fields Mapping Metadata
 */

/**
--------------------------------------- History --------------------------------------------------
31.01.2020    alex.volkov@auspost.com.au    Initial creation
02.03.2020    alex.volkov@auspost.com.au    Switched from Address Type picklist to all metadata records
**/

global class AddressTypePicklist extends VisualEditor.DynamicPickList
{
	/**
 	* @description Singleton returning address configuration names for Lightning App Builder
 	*/
	@TestVisible
	private static VisualEditor.DynamicPickListRows ADDRESS_CONFIGS
	{
		/* Get all Address Field Mappings */
		get
		{
			if (ADDRESS_CONFIGS == null)
			{
				ADDRESS_CONFIGS = new VisualEditor.DynamicPickListRows();
				for (Address_Fields_Mapping__mdt afm: [SELECT Label, DeveloperName FROM Address_Fields_Mapping__mdt ORDER BY Label])
				{
					ADDRESS_CONFIGS.addRow(new VisualEditor.DataRow(afm.Label, afm.DeveloperName));
				}
			}
			return ADDRESS_CONFIGS;
		}
		private set;
	}

	/**
	* @description Default value of the picklist
	* @return No default value
	*/
	global override VisualEditor.DataRow getDefaultValue()
	{
		return null;
	}

	/**
	* @description Get picklist values
	* @return Picklist rows
	*/
	global override VisualEditor.DynamicPickListRows getValues()
	{
		return ADDRESS_CONFIGS;
	}
}