/***
 * @author George Nguyen
 * @date 2022-07-11
 * @domain Core
 * @description A XML serializer class that serializes an object to xml string format
 * @changelog
 * 2022-07-11 - George Nguyen - Created
 */
public inherited sharing class XML {

    public static String serialize(String parentNode, Object objectToSerialize) {
        return addNode(parentNode, process((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(objectToSerialize))), false);
    } 

    static String process(Map<String, Object> propertyVsObject) {
        String result = '';
        for(String propertyName: propertyVsObject.keySet()) {
            Object o = propertyVsObject.get(propertyName);
            if(o == null) {
                result += addNode(propertyName, null, true);
            } else if(o instanceOf List<Object>) {
                result += process(propertyName, (List<Object>)o);
            } else if(o instanceOf Map<String, Object>) {
                result += addNode(propertyName, process((Map<String, Object>)o), false);
            } else {
                result += addNode(propertyName, String.valueOf(o), true);
            }
        }
        return result;
    }

    static String process(String node, List<Object> objects) {
        String result = '';
        for(Object o: objects) {
            result += serialize(node, o);
        } 
        return result;
    }

    static String addNode(String node, String value, Boolean escapeValue){
        String result = '';
        if(String.isBlank(node) == false) {
            String escapedNode = node.escapeHtml4();
            String escapedValue = String.isBlank(value) ? '' : (escapeValue == true ? value.escapeHtml4() : value);
            result = '<' + escapedNode + '>' + escapedValue + '</' + escapedNode + '>';
        } 
        return result;
    }
}