/**************************************************
Description:    Endpoint for Alive ping (/alive)
History:
--------------------------------------------------
2018-11-28  nathan.franklin@auspost.com.au  Created
**************************************************/
public with sharing class ResourceAliveV1 extends ResourceAPIService.IApi {

    // /alive - SF_ALIVE metadata type
    public override ResourceAPIService.IResourceResponse query() {
        return new ResourceAPIService.ResourceResponse(200, '', 'OK');
    }

    // /alive - SF_ALIVE metadata type
    public override ResourceAPIService.IResourceResponse post() {
        return new ResourceAPIService.ResourceResponse(200, '', 'OK');
    }

}