/**
 * @description
 * A very simple selector class that sits in the base domain
 * NOTE: This class is needed for Owner fields since an Owner field is not a full representation of a 'User' (since it can also be a group) - 'Name' entity
 * NOTE: This can't be queried directly, but can be used to build a list of fields for 'Owner' fields
 * NOTE: Does not have need to support fieldOverrides since the dataset is small
 *
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Selector
 * @tag Selector
 * @tag Name SObject
 * @domain Core
 * @changelog
 */
public virtual inherited sharing class OwnersSelector extends ApplicationSelector {

	public static OwnersSelector newInstance() {
		return (OwnersSelector)Application.Selectors.newInstance(OwnersSelector.class);
	}

	public override SObjectType getSObjectType() {
		return Name.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Name.Id, Name.Username, Name.FirstName, Name.LastName, Name.Name, Name.Email, Name.ProfileId, Name.UserRoleId
		};
	}
}