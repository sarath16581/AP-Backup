public class CaseHandOffMappingWrapper {
    public List<FieldMapping> mappings;
    
    public class FieldMapping {
        public String unifiedField;
        public String classicField;
        public Map<String, String> valuesMapping;
    }
}