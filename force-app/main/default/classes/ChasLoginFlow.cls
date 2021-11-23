/**
 * Created by nmain on 12/07/2018.
 */

Public class ChasLoginFlow {

    @InvocableMethod
    public static List<Boolean>  requestedCommunityIsCHAS() {
        List<Boolean> retList = new List<Boolean>();
        String networkId = '';
        try{

            retList.add(false);

            networkId = Network.getNetworkId();
            Network myNetwork = [SELECT Id, Name, Description, Status FROM Network WHERE ID = :networkId LIMIT 1];
            if (myNetwork.Name.contains('Consumer Help and Support'))
                retList[0]=true;

        } catch (Exception ex){
            System.debug('*** System Exception: '+ex);
        }
        return retList;
    }
}