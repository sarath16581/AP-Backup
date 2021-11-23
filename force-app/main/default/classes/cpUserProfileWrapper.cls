/*Community cloud profile. Used to display user profile image and nickname on homepage*/
public without sharing class cpUserProfileWrapper {
    
    @AuraEnabled
    public String userFullName {get; set;}
    @AuraEnabled
    public String smallPhotoUrl {get; set;}
    
  /*Community cloud profile. Used to display user profile image and nickname on homepage*/
    public cpUserProfileWrapper(String userFullName, String smallPhotoUrl) {
        this.userFullName = userFullName;
        this.smallPhotoUrl = smallPhotoUrl;
    }

}