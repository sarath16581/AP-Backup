/**
 * Created by hasantha on 10/5/19.
 */
({
    save : function(component, event, helper) {
        console.log('save ' +component.get('v.parentId'));
        helper.save(component,helper);
    },

})