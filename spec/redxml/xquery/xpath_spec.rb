require 'spec_helper'

RSpec.describe RedXML::Server::XQuery::Executor do
  def self.test_query(query, options = {})
    it query do
      result = subject.execute query
      results = result.map{|i| i.respond_to?(:to_html) ? i.to_html : i }
      expect(results).to eq options[:result]
    end
  end

  describe '::execute' do
    before(:all) do
      redis_clear
      redis_load 'catalog_dump.json'
    end

    let(:db_interface) { RedXML::Server::Database.connection }
    subject { described_class.new(db_interface, 'test', 'new') }

    context 'xpath' do
      test_query 'doc("catalog.xml")/catalog/product[colorChoices][number gt "500"][@dept = "MEN"]/colorChoices',
        result: ['<colorChoices>white gray</colorChoices>']

      test_query 'doc("catalog.xml")/catalog/product[colorChoices][number gt "500"][@dept = "WMN"]/colorChoices',
        result: ['<colorChoices no="four">navy black</colorChoices>']

      test_query "doc(  \"catalog.xml\"  )/catalog/product[colorChoices][number>='784']/number",
        result: ['<number>784</number>']

      test_query "doc(  \"catalog.xml\"  )/catalog/product[colorChoices][number='784']/number",
        result: ["<number>784</number>"]

      test_query "doc(  \"catalog.xml\"  )/catalog/product[colorChoices][number<='558']/number",
        result: ["<number>557cdata cast<></number>"]

      test_query "doc(  \"catalog.xml\"  )/catalog/product[colorChoices]/number",
        result: ['<number>557cdata cast<></number>', '<number>784</number>']

      test_query "doc(  \"catalog.xml\"  )/catalog/product/colorChoices[@no]",
        result: ['<colorChoices no="four">navy black</colorChoices>']

      test_query "doc(  \"catalog.xml\"  )/catalog/product[1]/@dept",
        result: ["WMN"]

      test_query "doc(  \"catalog.xml\"  )/catalog/product/number[. eq '443']",
        result: ["<number>443</number>"]

      test_query "doc(  \"catalog.xml\"  )/catalog/product/name",
        result: ['<name language="en">Fleece Pullover</name>', '<name language="en">Floppy Sun Hat</name>', '<name language="en">Deluxe Travel Bag</name>', '<name language="en">Cotton Dress Shirt</name>']

      test_query "doc(  \"catalog.xml\"  )/catalog/product[nocdata]/number[. >= 563]",
        result: ["<number>563</number>", "<number>784</number>"]

      test_query "doc(  \"catalog.xml\"  )/catalog/product/number[. ge '563']",
        result: ["<number>563</number>", "<number>784</number>"]

      test_query "doc(  \"catalog.xml\"  )/catalog/product[nocdata]/number[. > 563]",
        result: ["<number>784</number>"]

      test_query "doc(  \"catalog.xml\"  )/catalog/product/number[. <= '563']",
        result: ["<number>557cdata cast<></number>", "<number>563</number>", "<number>443</number>"]

      test_query "doc(  \"catalog.xml\"  )/catalog/product/number[. < '563']",
        result: ["<number>557cdata cast<></number>", "<number>443</number>"]

      test_query "doc(\"catalog.xml\")/catalog/product[nocdata][number = 443]/@dept",
        result: ["ACC"]

      test_query "doc(\"catalog.xml\")/catalog/product[nocdata][number =443]/@dept",
        result: ["ACC"]

      test_query "doc(\"catalog.xml\")/catalog/product[nocdata][number= 443]/@dept",
        result: ["ACC"]

      test_query "doc(\"catalog.xml\")/catalog/product[nocdata][number=443]/@dept",
        result: ["ACC"]

      test_query "doc(\"catalog.xml\")//product[nocdata][number=443]/@dept",
        result: ["ACC"]

      test_query "doc(\"catalog.xml\")/catalog/*[nocdata][number=443]/@dept",
        result: ["ACC"]

      test_query "doc(\"catalog.xml\")/catalog/*[@dept = 'ACC']/@dept",
        result: ["ACC", "ACC"]

      test_query "doc(\"catalog.xml\")/catalog/*[@dept = \"ACC\"]/@dept",
        result: ["ACC", "ACC"]

      test_query "doc(\"catalog.xml\")//@dept",
        result: ["WMN", "ACC", "ACC", "MEN"]

      test_query "doc(\"catalog.xml\")//product[last()]",
        result: ["<product dept=\"MEN\"><number>784</number><name language=\"en\">Cotton Dress Shirt</name><colorChoices>white gray</colorChoices><desc>Our<i>favorite</i>shirt!<!--Second commentary--></desc><nocdata></nocdata></product>"]

      test_query "doc(\"catalog.xml\")//product[position() >= 4]",
        result: ["<product dept=\"MEN\"><number>784</number><name language=\"en\">Cotton Dress Shirt</name><colorChoices>white gray</colorChoices><desc>Our<i>favorite</i>shirt!<!--Second commentary--></desc><nocdata></nocdata></product>"]

      test_query "doc(\"catalog.xml\")//product[position() > 3]",
        result: ["<product dept=\"MEN\"><number>784</number><name language=\"en\">Cotton Dress Shirt</name><colorChoices>white gray</colorChoices><desc>Our<i>favorite</i>shirt!<!--Second commentary--></desc><nocdata></nocdata></product>"]

      test_query "doc(\"catalog.xml\")//product[3 < position()]",
        result: ["<product dept=\"MEN\"><number>784</number><name language=\"en\">Cotton Dress Shirt</name><colorChoices>white gray</colorChoices><desc>Our<i>favorite</i>shirt!<!--Second commentary--></desc><nocdata></nocdata></product>"]

      test_query "doc(\"catalog.xml\")//product[last()]/name/text()",
        result: ["Cotton Dress Shirt"]

      test_query "doc(\"catalog.xml\")/catalog/product[name = \"Fleece Pullover\"]/number/text()",
        result: ["557cdata cast<>"]
    end
  end
end

