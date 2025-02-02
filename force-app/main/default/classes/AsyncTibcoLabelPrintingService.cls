//Generated by wsdl2apex
@SuppressWarnings('PMD')
public class AsyncTibcoLabelPrintingService {
    public class getResponseFuture extends System.WebServiceCalloutFuture {
        public TibcoLabelPrintingService.GetResponseType getValue() {
            TibcoLabelPrintingService.getResponse response = (TibcoLabelPrintingService.getResponse)System.WebServiceCallout.endInvoke(this);
            return response.Generated;
        }
    }
    public class AsyncLabelPrintingServicePort {
        public String endpoint_x = 'https://webapi-ptestext.npe.auspost.com.au/ptest/lps/labelPrintingService';
        public Map<String,String> inputHttpHeaders_x;
        public String clientCertName_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'http://www.auspost.com.au/Schema/ProductandServiceFulfilment/LodgementManagement/generateLabel:v1', 'TibcoLabelPrintingService'};
        public AsyncTibcoLabelPrintingService.getResponseFuture beginGet(System.Continuation continuation,TibcoLabelPrintingService.GetRequestType Generate) {
            TibcoLabelPrintingService.get request_x = new TibcoLabelPrintingService.get();
            request_x.Generate = Generate;
            return (AsyncTibcoLabelPrintingService.getResponseFuture) System.WebServiceCallout.beginInvoke(
              this,
              request_x,
              AsyncTibcoLabelPrintingService.getResponseFuture.class,
              continuation,
              new String[]{endpoint_x,
              '',
              'http://www.auspost.com.au/Schema/ProductandServiceFulfilment/LodgementManagement/generateLabel:v1',
              'get',
              'http://www.auspost.com.au/Schema/ProductandServiceFulfilment/LodgementManagement/generateLabel:v1',
              'getResponse',
              'TibcoLabelPrintingService.getResponse'}
            );
        }
    }
}