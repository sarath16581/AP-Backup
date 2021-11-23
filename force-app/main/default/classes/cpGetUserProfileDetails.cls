//Class to retrieve user profile of the article/featured content author
public without sharing class cpGetUserProfileDetails {

    @AuraEnabled
    //Get user Profile
    public static cpUserProfileWrapper GetUserProfileDetails(String articleId){
        try{
            //Fetch  user’s current community
            String communityId = Network.getNetworkId();
    
            //Query to fetch Created by User Id  of the article
            String  contentCreatorId = [Select Id, CreatedById from Featured_Content__kav Where Id =: articleId Limit 1].CreatedById;
    
            //Query on User to fetch User's Name
            User userDetail = [Select Name From User Where Id =: contentCreatorId Limit 1];
    
            //Create wrapper to return to component
            cpUserProfileWrapper wrappedProfile;
    
            //Api call to fetch User's Profile pic and Name using connect api
            if((!String.isBlank(communityId) && !String.isBlank(contentCreatorId)) || test.isRunningTest()){
                ConnectApi.Photo authorPhoto;
                if(!test.isRunningTest())
                    authorPhoto = ConnectApi.UserProfiles.getPhoto(communityId, contentCreatorId);
                else
                    authorPhoto = ConnectApi.UserProfiles.getPhoto(null, userInfo.getUserId());
                String smallPhotoUrl = '';
                if(authorPhoto != null){
                    smallPhotoUrl = authorPhoto.smallPhotoUrl;
                }
               wrappedProfile = new cpUserProfileWrapper(userDetail.Name, smallPhotoUrl);
            }
            return wrappedProfile;
        } catch(exception ex){
            return null;
        }
    }
}