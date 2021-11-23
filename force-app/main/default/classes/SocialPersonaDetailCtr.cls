/**************************************************
Description:    Display Social Persona page

History:
--------------------------------------------------
2018-06-06  clint.dsilva@auspost.com.au  added functionality to handle null post
**************************************************/



public class SocialPersonaDetailCtr {


    public SocialPersona persona {get; set;}
    public ExternalSocialAccount socialAccount {get; set;}

    public Boolean error { get; set; } // CONFIRM ERROR FATAL INFO WARNING
    public String theURL { get; set; }
    public String html { get; set; }

    public Integer  queryLimit = 5;
    public Integer  offset {get;set;}
    public Boolean  hasMore {get;set;}
    public Map<Id,String> caseNumberMap {get; set;}
    
    public String objId;
    public List<SocialPost> caseRelatedPosts  {get;set;}
    public SocialPost firstPost {get;set;}

    public SocialPersonaDetailCtr() {

        error = false;
        String objId = ApexPages.currentPage().getParameters().get('id');

        list<SocialPost> lPosts;
        if (!String.isNotBlank(objId)) return;
            Id idValue = objId;
            Schema.SObjectType token = idValue.getSObjectType();
            Schema.DescribeSObjectResult dr = token.getDescribe();

        if (dr.getName()  == 'SocialPost'){
           lPosts = [SELECT Id,  PersonaId, Persona.ExternalId, Persona.Name, Parent.Name, Persona.RealName, Persona.ProfileUrl, OutboundSocialAccountId
            FROM SocialPost WHERE Id = :objId ];
        }else if (dr.getName()  == 'Case'){
            list<Case> lc = [select Id , (Select id from Posts where isoutbound = false order by createdDate limit 1) from Case where id =: objId];
            if (!lc.isEmpty()){
                lPosts = lc[0].Posts;
                if(lPosts != null && lPosts.size() > 0){
                    lPosts = [SELECT Id,  PersonaId, Persona.ExternalId, Persona.Name, Parent.Name, Persona.RealName, Persona.ProfileUrl, OutboundSocialAccountId, Provider
                                FROM SocialPost WHERE Id = :lPosts[0].Id limit 1];
                }
            }
        }

        if (lPosts != null && !lPosts.isEmpty()){ 
            List<SocialPersona> l = [SELECT AreWeFollowing,Bio,CreatedById,CreatedDate,
                    ExternalId,ExternalPictureURL,Followers,Following,
                    Id,IsBlacklisted,IsDefault,IsDeleted,IsFollowingUs,
                    Klout,LastModifiedById,LastModifiedDate,ListedCount,
                    MediaProvider,MediaType,Name,NumberOfFriends,
                    NumberOfTweets,ParentId,ProfileType,ProfileUrl,Provider,
                    R6SourceId,RealName,SystemModstamp,TopicType,Parent.Name
                    FROM SocialPersona
                    WHERE Id = :lPosts[0].PersonaId LIMIT 1];
            if (!l.isEmpty()){
                persona = l[0];
            }
            else{
                List<ExternalSocialAccount> esa = [SELECT Id, ExternalPictureURL, Provider, Username 
                                                    FROM ExternalSocialAccount 
                                                    WHERE Id = :lPosts[0].OutboundSocialAccountId Limit 1];
                
                if(!esa.isEmpty()){
                    socialAccount = esa[0];
                }
            }
        }

    }

    //@todo limits!!
    public List<SocialPost> getPostList(){
        List<SocialPost> result  = null;
        if ( persona != null ){

            Map<Id,SocialPost> mp = new Map<Id,SocialPost>([Select Id from SocialPost where IsOutbound = false AND PersonaId =: persona.Id]);
            result = [ SELECT Name, MessageType,Content,Handle, Posted, ParentId, Parent.Name,  
                        Provider,  PersonaId, TopicProfileName, IsOutbound, Persona.ExternalPictureURL, OutboundSocialAccount.ExternalPictureURL
                        FROM SocialPost
                        WHERE 
                            ( IsOutbound = false AND PersonaId =: persona.Id ) 
                            OR 
                            ( IsOutbound = true AND ReplyToId in: mp.keySet() ) 
                        ORDER BY Posted DESC 
                        LIMIT 10000 ];
                        
         }
         
         
         if ( socialAccount != null ){

            Map<Id,SocialPost> mp = new Map<Id,SocialPost>([Select Id from SocialPost where IsOutbound = true AND OutboundSocialAccountId=: socialAccount.Id]);
            result = [ SELECT Name, MessageType,Content,Handle, Posted, ParentId, Parent.Name,
                        Provider,  PersonaId, TopicProfileName, IsOutbound, Persona.ExternalPictureURL, OutboundSocialAccount.ExternalPictureURL
                        FROM SocialPost
                        WHERE 
                            ( IsOutbound = true AND OutboundSocialAccountId =: socialAccount.Id) 
                            OR 
                            ( IsOutbound = false AND ReplyToId in: mp.keySet() ) 
                        ORDER BY Posted DESC 
                        LIMIT 10000 ];
                        
         }
         
         if (result != null &&  !result.isEmpty()){
             List<Id> lSt = new List<Id>();
             caseNumberMap = new Map<Id,String>();
             for(SocialPost post : result){
                 lSt.add(post.ParentId);
             }
             for(Case c : [Select Id, CaseNumber from Case where id in:lSt]){
                 caseNumberMap.put(c.Id,c.CaseNumber);
             }

         }
        
        return result;
    }
    
    
    public String getSalesforceUrl() {
        return System.Url.getSalesforceBaseUrl().toExternalForm();
    }
    
    
    
    
    
    
     /********  returns list of SocialPosts made by socialPersona   ****************/

    /*
    * @description
    *   @param Id personaId
    *   @return Map<Id,List<SocialPost>>
    *     list of Persona's SocialPosts : posts written by the persona that are thread starters
    *    returns map  where - key is the Id of the social post related to the persona
    *            - value is an ordered list containing all SocialPost on the key post thread
    * @return Map<Id,List<SocialPost>>
    */
    public Map<Id,List<SocialPost>> getPersonaConversation(){
        Map<Id,List<SocialPost>> result = new Map<Id,List<SocialPost>>();
  

        List<SocialPost> caseRelatedPosts = new List<SocialPost>();
        
        if ( persona != null ){
        
            caseRelatedPosts = [SELECT Content,Handle,Provider,Headline,Id,ReplyToId, MessageType , 
                                  ParentId,Posted ,Persona.Name , Persona.ExternalPictureURL , 
                                  IsOutbound,  OutboundSocialAccount.MasterLabel ,  Parent.Name,
                  OutboundSocialAccount.ExternalPictureURL  
                                FROM SocialPost
                                WHERE PersonaId =:persona.Id
                                AND ReplyToId = null  
                                order by  Posted desc ];
        
        }
        system.debug('\n==== SocialAccount '+socialAccount);
        if ( socialAccount != null ){

           caseRelatedPosts = [SELECT Content,Handle,Provider,Headline,Id,ReplyToId, MessageType , 
                                  ParentId,Posted ,Persona.Name , Persona.ExternalPictureURL , 
                                  IsOutbound,  OutboundSocialAccount.MasterLabel ,  Parent.Name,
                  OutboundSocialAccount.ExternalPictureURL  
                                FROM SocialPost
                                WHERE OutboundSocialAccountId =:socialAccount.Id
                                AND ReplyToId = null  
                                order by  Posted desc ];
                        
         }
        
        if (! caseRelatedPosts.isEmpty()){
            for(SocialPost sp : caseRelatedPosts){
                result.put(sp.Id,getConversations(sp.Id));
            }            
        }

    return result;
    }
       
/*
    * @description
    * @param   - social Post Id 
    *    returns  ordered list containing all SocialPost on the parameter post thread
    * @return List<SocialPost>
    */

    public List<SocialPost> getConversations(Id postId){

    List<SocialPost> result = new List<SocialPost>();

    if (  String.isNotBlank(postId) && controlLimits())  {
      result = [  Select Content,Handle,Provider,Headline,Id,ReplyToId, MessageType , 
                  ParentId,Posted ,Persona.Name , Persona.ExternalPictureURL , 
                  IsOutbound,  OutboundSocialAccount.MasterLabel , Parent.Name,
                  OutboundSocialAccount.ExternalPictureURL ,
                  ResponseContextExternalId , ExternalPostId
            from SocialPost
            where id =: postId];

      if (!result.isEmpty()){
        firstPost = result[0]; 
        //firstPost.Content = firstPost.Content+'[1-'+firstPost.ReplyToId+':'+firstPost.Id+']';
            while(firstPost.ReplyToId != null) {
              firstPost = [SELECT Content,Handle,Provider,Headline,Id,ReplyToId, MessageType , 
                      ParentId,Posted ,Persona.Name , Persona.ExternalPictureURL , 
                      IsOutbound,  OutboundSocialAccount.MasterLabel , Parent.Name,
                      OutboundSocialAccount.ExternalPictureURL, 
                      ResponseContextExternalId , ExternalPostId
                    FROM SocialPost
                    WHERE Id=:firstPost.ReplyToId];
            }
        if (firstPost.Provider=='Twitter'){
          result.addAll(getThreads(new List<String>{firstPost.ExternalPostId} ));  
        }else{
          result.addAll(getThreads(new List<String>{firstPost.ExternalPostId} ));
        }
        }
    }
    
      return result;
    }
 

    /*
    * @description
    * @param     - list of SocialPost
    *      - message type   
    *    returns  ordered list containing all replies to the incoming posts   
    * @return List<SocialPost>
    */
  public List<SocialPost> getThreads(List<String> contextExternalIds ){

    List<SocialPost> result = new List<SocialPost>();
    List<String> currentIds; 
      if (! contextExternalIds.isEmpty() && controlLimits() ){
        currentIds = new List<String>();
          system.debug('\n=== getThreads :'+contextExternalIds   );
          for(SocialPost sp  : [
                    Select Id , ReplyToId, Content, Handle, MessageType , ParentId, Posted ,
                             OutboundSocialAccount.ExternalPictureURL ,
                            Persona.Name , Persona.ExternalPictureURL, IsOutbound,  
                            OutboundSocialAccount.MasterLabel , Parent.Name,
                            ResponseContextExternalId , ExternalPostId, Provider
                    from SocialPost
                    where
                       ResponseContextExternalId  in : contextExternalIds  
                        and ExternalPostId not in : contextExternalIds 
                    and Posted >= :firstPost.Posted
                    order by Posted asc 
      ]){ 
              system.debug('\n=== [ExternalPostId:'+sp.ExternalPostId+':'+sp.MessageType+'] ResponseContextExternalId:'+
                        sp.ResponseContextExternalId  );
              //sp.Content = sp.Content+'[2-'+sp.ReplyToId+':'+sp.Id+']';
              result.add( sp);
              result.addAll(getThreads(new List<String>{sp.ExternalPostId} ));
              
      }

          //result.addAll(getThreads(currentIds));

    }
    return result;
  }
    
    private Boolean controlLimits(){
        
        Boolean continueQuerying = (Limits.getLimitQueries() - Limits.getQueries()) > 10;
        system.debug('\n===controlLimits queries :'+Limits.getQueries()+' of '+Limits.getLimitQueries() +
                    '\n continueQuerying :'+continueQuerying);
        return  continueQuerying;
    }
    

}