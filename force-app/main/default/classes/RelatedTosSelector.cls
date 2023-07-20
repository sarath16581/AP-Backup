/**
 * @description
 * A very simple selector class that sits in the base domain
 * NOTE: This class is needed for Who fields since an Who field is not a full representation of a 'Contact' (since it can also be other SObjects)
 * NOTE: This can't be queried directly, but can be used to build a list of fields for 'Owner' fields
 * NOTE: Does not have need to support fieldOverrides since the dataset is small
 *
 * @author SteveL
 * @date 2023-07-13
 * @group Selector
 * @tag Selector
 * @tag Name SObject
 * @domain Core
 * @changelog
 */
public virtual inherited sharing class RelatedTosSelector extends ApplicationSelector {
    public static RelatedTosSelector newInstance() {
        return (RelatedTosSelector)Application.Selectors.newInstance(RelatedTosSelector.class);
    }

    public override SObjectType getSObjectType() {
        return Name.getSObjectType();
    }

    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
                Name.Id,Name.Name,Name.Email
        };
    }
}