public without sharing class cpNavBarController {
    
    @AuraEnabled
    public static list<NavigationMenuItem> getMenuItems(){
        
        String commId = Network.getNetworkId();
        list<NavigationMenuItem> menuItems = [Select DefaultListViewId, Type, TargetPrefs, Label, Target from NavigationMenuItem where  NavigationLinkSet.NetworkId = :commId order by Position asc];
  
        return menuItems;
    }
}