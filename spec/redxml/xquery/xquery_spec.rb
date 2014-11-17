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
      RedXML::Server.options = {db: {driver: :redis}}
      @db_interface = RedXML::Server::Database.checkout
    end

    after(:all) do
      RedXML::Server::Database.checkin @db_interface
    end

    before(:all) do
      redis_clear
      redis_load 'catalog_dump.json'
    end

    subject { described_class.new(@db_interface, 'test', 'new') }

    it 'returns dom' do
      result = subject.execute("doc('catalog.xml')/catalog")
      expect(result).to be_a Array
      expect(result.first).to be_a Nokogiri::XML::Element
    end

    describe 'xquery' do
      # more for
      test_query( 'for $prod in doc("catalog.xml")/catalog/product
                  for $name in doc("catalog.xml")/catalog/product/name
                  return $name',
                  result: ['<name language="en">Fleece Pullover</name>', '<name language="en">Floppy Sun Hat</name>', '<name language="en">Deluxe Travel Bag</name>', '<name language="en">Cotton Dress Shirt</name>',
                           '<name language="en">Fleece Pullover</name>', '<name language="en">Floppy Sun Hat</name>', '<name language="en">Deluxe Travel Bag</name>', '<name language="en">Cotton Dress Shirt</name>',
                           '<name language="en">Fleece Pullover</name>', '<name language="en">Floppy Sun Hat</name>', '<name language="en">Deluxe Travel Bag</name>', '<name language="en">Cotton Dress Shirt</name>',
                           '<name language="en">Fleece Pullover</name>', '<name language="en">Floppy Sun Hat</name>', '<name language="en">Deluxe Travel Bag</name>', '<name language="en">Cotton Dress Shirt</name>',])
      # second let instead of that for
      test_query( 'for $prod in doc("catalog.xml")/catalog/product
                  let $name := doc("catalog.xml")/catalog/product/name
                  return $name',
                  result: ['<name language="en">Fleece Pullover</name><name language="en">Floppy Sun Hat</name><name language="en">Deluxe Travel Bag</name><name language="en">Cotton Dress Shirt</name>',
                           '<name language="en">Fleece Pullover</name><name language="en">Floppy Sun Hat</name><name language="en">Deluxe Travel Bag</name><name language="en">Cotton Dress Shirt</name>',
                           '<name language="en">Fleece Pullover</name><name language="en">Floppy Sun Hat</name><name language="en">Deluxe Travel Bag</name><name language="en">Cotton Dress Shirt</name>',
                           '<name language="en">Fleece Pullover</name><name language="en">Floppy Sun Hat</name><name language="en">Deluxe Travel Bag</name><name language="en">Cotton Dress Shirt</name>'])
      #regular for, where, order by, return
      test_query( "for $prod in doc(  \"catalog.xml\"  )/catalog/product[position()<=3]  where $prod/@dept<=\"ACC\" order by $prod/name return $prod/name",
                 result: ["<name language=\"en\">Deluxe Travel Bag</name>", "<name language=\"en\">Floppy Sun Hat</name>"])
      #check where difference
      test_query( "for $prod in doc(  \"catalog.xml\"  )/catalog/product[position()<=3] where $prod/@dept>=\"ACC\" order by $prod/name return $prod/name",
                 result: ["<name language=\"en\">Deluxe Travel Bag</name>", '<name language="en">Fleece Pullover</name>', "<name language=\"en\">Floppy Sun Hat</name>"])
      #check ascending order
      test_query( "for $prod in doc(  \"catalog.xml\"  )/catalog/product[position()<=3]  where $prod/@dept>=\"ACC\" order by $prod/name ascending return $prod/name",
                 result: ["<name language=\"en\">Deluxe Travel Bag</name>", '<name language="en">Fleece Pullover</name>', "<name language=\"en\">Floppy Sun Hat</name>"])
      #check descending order
      test_query( "for $prod in doc(  \"catalog.xml\"  )/catalog/product[position()<=3]  where $prod/@dept>=\"ACC\" order by $prod/name descending return $prod/name",
                 result: ["<name language=\"en\">Floppy Sun Hat</name>", '<name language="en">Fleece Pullover</name>', "<name language=\"en\">Deluxe Travel Bag</name>"])
      #check return element wrap
      test_query( "for $prod in doc(  \"catalog.xml\"  )/catalog/product[position()<=3]  where $prod/@dept<=\"ACC\" order by $prod/name return <elem>$prod/name</elem>",
                 result: ["<elem>$prod/name</elem>", "<elem>$prod/name</elem>"])
      test_query( "for $prod in doc(  \"catalog.xml\"  )/catalog/product[position()<=3]  where $prod/@dept<=\"ACC\" order by $prod/name return <elem>{$prod/name}</elem>",
                 result: ["<elem><name language=\"en\">Deluxe Travel Bag</name></elem>", "<elem><name language=\"en\">Floppy Sun Hat</name></elem>"])
      #check whitespaces and without order
      test_query( "for $prod in  doc(  \"catalog.xml\"  ) /  catalog/ product[position() <=3 ]  where $prod/@dept<=\"ACC\" return <elem>{$prod/name}</elem>",
                 result: ["<elem><name language=\"en\">Floppy Sun Hat</name></elem>", "<elem><name language=\"en\">Deluxe Travel Bag</name></elem>"])
      #check without where and order
      test_query( 'for $prod in doc("catalog.xml")/catalog/product  return <elem>{$prod/name}</elem>',
                 result: ['<elem><name language="en">Fleece Pullover</name></elem>', "<elem><name language=\"en\">Floppy Sun Hat</name></elem>", "<elem><name language=\"en\">Deluxe Travel Bag</name></elem>", '<elem><name language="en">Cotton Dress Shirt</name></elem>'])
      #check text
      test_query( 'for $prod in doc("catalog.xml")/catalog/product[2]  return <elem>{$prod/name/text()}</elem>',
                 result: ['<elem>Floppy Sun Hat</elem>'])
      #check let
      test_query( 'for $prod in doc("catalog.xml")/catalog/product[2] let $name := $prod/name  return <elem>{$name/text()}</elem>',
                 result: ['<elem>Floppy Sun Hat</elem>'])
      #let
      test_query( "for $prod in doc(  \"catalog.xml\"  )/catalog/product[position()<=3] let $name := $prod/name where $prod/@dept<=\"ACC\" order by $name return <elem>{$name}</elem>",
                 result: ["<elem><name language=\"en\">Deluxe Travel Bag</name></elem>", "<elem><name language=\"en\">Floppy Sun Hat</name></elem>"])
      #all
      test_query(
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language eq "en"
       order by $n
       return <names>{$n/text()}</names>',
       result: ['<names>Cotton Dress Shirt</names>', '<names>Deluxe Travel Bag</names>', '<names>Fleece Pullover</names>', '<names>Floppy Sun Hat</names>'])
      test_query(
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language ne "een"
       order by $n
       return $n/text()',
       result: ['Cotton Dress Shirt', 'Deluxe Travel Bag', 'Fleece Pullover', 'Floppy Sun Hat'])
      test_query(
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language ne "een"
       order by $n
       return $p/name/text()',
       result: ['Cotton Dress Shirt', 'Deluxe Travel Bag', 'Fleece Pullover', 'Floppy Sun Hat'])
      #multiple result occurence
      test_query(
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language ne "een"
       order by $n
       return <elem att="{$p/name}" nextattr="{$p/number/text()}">{$p/name}</elem>',
       result: ['<elem att="Cotton Dress Shirt" nextattr="784"><name language="en">Cotton Dress Shirt</name></elem>',
                '<elem att="Deluxe Travel Bag" nextattr="443"><name language="en">Deluxe Travel Bag</name></elem>',
                '<elem att="Fleece Pullover" nextattr="557cdata cast<>"><name language="en">Fleece Pullover</name></elem>',
                '<elem att="Floppy Sun Hat" nextattr="563"><name language="en">Floppy Sun Hat</name></elem>'])
      test_query(
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language ne "een"
       order by $n
       return <elem att="{$p/name}" nextattr="{$p/number}">{$p/name/text()}</elem>',
       result: ['<elem att="Cotton Dress Shirt" nextattr="784">Cotton Dress Shirt</elem>',
                '<elem att="Deluxe Travel Bag" nextattr="443">Deluxe Travel Bag</elem>',
                '<elem att="Fleece Pullover" nextattr="557cdata cast<>">Fleece Pullover</elem>',
                '<elem att="Floppy Sun Hat" nextattr="563">Floppy Sun Hat</elem>'])
      #overal wrap
      test_query(
        '<ul>{for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language ne "een"
       order by $n
       return <elem att="{$p/name}" nextattr="{$p/number}">{$p/name/text()}</elem>}</ul>',
       result: ['<ul><elem att="Cotton Dress Shirt" nextattr="784">Cotton Dress Shirt</elem><elem att="Deluxe Travel Bag" nextattr="443">Deluxe Travel Bag</elem><elem att="Fleece Pullover" nextattr="557cdata cast<>">Fleece Pullover</elem><elem att="Floppy Sun Hat" nextattr="563">Floppy Sun Hat</elem></ul>'])
      test_query(
        '<ul>{for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language ne "een"
       order by $n
       return <elem att="{$p/name/text()}" nextattr="{$p/number/text()}">{$p/name/text()}</elem>}</ul>',
       result: ['<ul><elem att="Cotton Dress Shirt" nextattr="784">Cotton Dress Shirt</elem><elem att="Deluxe Travel Bag" nextattr="443">Deluxe Travel Bag</elem><elem att="Fleece Pullover" nextattr="557cdata cast<>">Fleece Pullover</elem><elem att="Floppy Sun Hat" nextattr="563">Floppy Sun Hat</elem></ul>'])
    end
  end
end
