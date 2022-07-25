/***
 * @author George Nguyen
 * @date 2022-07-11
 * @domain Core
 * @description Test class for XML serializer class
 * @changelog
 * 2022-07-11 - George Nguyen - Created
 */
@IsTest
class XML_Test {

    @IsTest
    static void serialize() {
        DummyParent p = new DummyParent();
        p.name = 'test parent';
        p.children = new List<DummyChild>();

        DummyChild c1 = new DummyChild();
        c1.name = 'child 1';
        p.children.add(c1);

        DummyChild c2 = new DummyChild();
        c2.name = 'child 2';
        p.children.add(c2);

        String result = XML.serialize('testNode', p);
        System.assertEquals('<testNode><name>test parent</name><children><name>child 1</name></children><children><name>child 2</name></children></testNode>', result, 'the generated xml should match the expected xml sting');
    }

    public class DummyParent {
        public String name {get;set;}
        public List<DummyChild> children {get;set;}
    }

    public class DummyChild {
        public String name {get;set;}
    }
}