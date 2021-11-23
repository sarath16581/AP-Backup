/**
 * Date            Version          Owner               Desription
 * 07-Mar-17        1.0             Adrian A            Initial version for Document Preview
 */
public with sharing class DocumentPreviewController{
    // Add to the following list if you have other images you want to show
    Set <String> ImageExtensions = new Set <String> {'JPG', 'JPEG', 'GIF', 'PNG','PDF','WORD_X','EXCEL_X','POWER_POINT_X'};
    
    // The record that has the attachments we want to show
    private final SObject so;

    // The photos for the VF page to use
    public List <Photo> Photos {get; private set;}

    /* @created by: Adrian Recio
     * @description: Contains the information for the VF page to render the photo      
     */ 
    public with sharing class Photo{
        public String id   {get; private set;}
        public String url  {get; private set;}
        public String urlThumb  {get; private set;}
        public String urlAdobe  {get; private set;}
        public String name {get; private set;}
        public String active {get; private set;}
        
        /* Building Actual File Preview */
        public Photo (String ipId, String ipName, String activeVal){
            id   = ipId;
            
            // Build thumbnail render URL
            urlThumb = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480' +
            			'&versionId=' + id;
                
            // Build actual file preview render URL
            urlAdobe = 'shepherd_prefix=/sfc/servlet.shepherd&v=' + id + '&mode=chatterfilepreview';
            name = ipName;
            active = activeVal;
        }
    }
    
    /* @created by: Adrian Recio
     * @description: Constructor   
     */ 
    public DocumentPreviewController (ApexPages.StandardController controller){
        this.so = controller.getRecord ();
        Photos = new List <Photo> ();
        fetchPhotos ();
    }
    
    /* @created by: Adrian Recio
     * @description: Main method to pull related files of parent record and build the wrapper class list
     */ 
    private void fetchPhotos (){
        String       FileNameExtn;

        Photos.clear ();  // Empty the list between calls to be sure...
        Set<Id> contentDocIdSet = new Set<Id>();
        
        // Pull document link which contains parent record information
        for(ContentDocumentLink cdlVar: [SELECT Id, LinkedEntityId, ContentDocumentId, Visibility, IsDeleted, ShareType
                                             FROM ContentDocumentLink 
											 WHERE LinkedEntityId = :so.Id]){
            contentDocIdSet.add(cdlVar.ContentDocumentId);
        }
                                                 
        system.debug('CDL Set:' + contentDocIdSet);
        
        // Pull content version which contains the actual document details
        // Make sure to select latest version by adding condition IsLatest
        for (ContentVersion a : [SELECT Id,ContentDocumentId,Title,FileType FROM ContentVersion 
                                      where ContentDocumentId IN :contentDocIdSet and IsLatest = true]){
           
            system.debug('Is Contained:' + ImageExtensions.contains(a.FileType));                              	
            
            string activeVal = '';
            if(Photos.size()==0){ // Assign current active file on page load
                activeVal = 'active';
            }
        
            Photos.add (new Photo (a.Id, a.Title, activeVal));
        }
        
        system.debug('Photo List:' + Photos);
    }  
}