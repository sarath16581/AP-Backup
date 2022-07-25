/***
 * @author George Nguyen
 * @date 2022-07-11
 * @domain Core
 * @description Mock class for TibcoLabelPrintingService_Test & AsyncTibcoLabelPrintingService_Test
 * @changelog
 * 2022-07-11 - George Nguyen - Created
 */
public class TibcoLabelPrintingServiceWebServiceMock implements WebServiceMock {
    public Void doInvoke(Object stub, Object soapRequest, Map<String,Object> responseMap, String endpoint, String soapAction, String requestName, String responseNamespace, String responseName, String responseType) {
     
        TibcoLabelPrintingService.getResponse res = new TibcoLabelPrintingService.getResponse();

        TibcoLabelPrintingService.GetResponseType generated = new TibcoLabelPrintingService.GetResponseType();
        generated.Labels = new List<TibcoLabelPrintingService.LabelResponseType>();
        TibcoLabelPrintingService.LabelResponseType label = new TibcoLabelPrintingService.LabelResponseType();
        generated.Labels.add(label);
        res.Generated = generated; 

        responseMap.put('response_x', res);
     }
}