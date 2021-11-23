/**
    * This is Contact Trigger sending email to new COntacts via ET.  
    * 
    * @Author kalpita.talwadekar@auspost.com.au
    * @Date 2/10/2015
    *   
    */
trigger Trig_Contact on Contact (after insert) {
    
    et4ae5.triggerUtility.automate('Contact');
           
}