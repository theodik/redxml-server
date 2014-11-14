require 'spec_helper'

RSpec.describe RedXML::Server::XQuery::Executor do
  def self.test_query(check_query, before_result, update_query, after_result)
    it update_query do
      result = subject.execute check_query
      results = result.map{|i| i.respond_to?(:to_html) ? i.to_html : i }
      expect(results).to eq before_result

      result = subject.execute update_query

      result = subject.execute check_query
      results = result.map{|i| i.respond_to?(:to_html) ? i.to_html : i }
      expect(results).to eq after_result
    end
  end

  describe '::execute' do
    before do
      redis_clear
      redis_load 'catalog_dump.json'
    end

    let(:db_interface) { RedXML::Server::Database.connection }
    subject { described_class.new(db_interface, 'test', 'new') }

    context 'update' do
      #DELETE
      test_query(
        'doc("catalog.xml")/catalog/product[3]/name/text()',
        [ "Deluxe Travel Bag" ],
        'delete node doc("catalog.xml")/catalog/product[3]',
        [ "Cotton Dress Shirt" ]
      )
      test_query(
        'doc("catalog.xml")/catalog/product[2]/name/text()',
        [ "Floppy Sun Hat" ],
        'for $prod in doc("catalog.xml")/catalog/product where $prod[nocdata]/number = 563 return delete node $prod',
        [ "Deluxe Travel Bag" ]
      )
      test_query(
        'doc("catalog.xml")/catalog/product[1]/name/text()',
        [ "Fleece Pullover" ],
        'for $prod in doc("catalog.xml")/catalog/product
       where $prod/@dept != "MEN"
       return delete nodes $prod',
       [ "Cotton Dress Shirt" ]
      )
      test_query(
        'doc("catalog.xml")/catalog/product[1]/name/text()',
        [ "Fleece Pullover" ],
        'delete nodes doc("catalog.xml")/catalog/product[@dept != "MEN"]',
        [ "Cotton Dress Shirt" ]
      )

      # INSERT
      #attr
      test_query(
        'doc("catalog.xml")/catalog/product[1]/@dept',
        ["WMN"],
        'insert nodes attribute dept { "something" } into doc("catalog.xml")/catalog/product[1]',
        ["something"]
      )
      test_query(
        'doc("catalog.xml")/catalog/product[1]/@att',
        [],
        'insert nodes attribute att { "something" } into doc("catalog.xml")/catalog/product[1]',
        ["something"]
      )
      #elem
      test_query(
        'doc("catalog.xml")/catalog/product[1]/added/name[@at eq "some"]/text()',
        [],
        'insert nodes <added><name at="some">some text</name></added> into doc("catalog.xml")/catalog/product[1]',
        ['some text']
      )
      #check into as...
      test_query(
        'doc("catalog.xml")/catalog/product[4]/*[last()]/name[@at eq "some"]/text()',
        [],
        'insert nodes <added><name at="some">some text</name></added> as last into doc("catalog.xml")/catalog/product[4]',
        ['some text']
      )
      test_query(
        'doc("catalog.xml")/catalog/product[4]/*[1]/name[@at eq "some"]/text()',
        [],
        'insert nodes <added><name at="some">some text</name></added> as first into doc("catalog.xml")/catalog/product[4]',
        ['some text']
      )
      #check after/before
      test_query(
        'doc("catalog.xml")/catalog/*[5]/name[@at eq "some"]/text()',
        [],
        'insert node <added><name at="some">some text</name></added> after doc("catalog.xml")/catalog/product[4]',
        ['some text']
      )
      test_query(
        'doc("catalog.xml")/catalog/*[4]/name[@at eq "some"]/text()',
        [],
        'insert node <added><name at="some">some text</name></added> before doc("catalog.xml")/catalog/product[4]',
        ['some text']
      )
      #check insert text
      test_query(
        'doc("catalog.xml")/catalog/text()',
        [""],
        'insert node "new text" into doc("catalog.xml")/catalog',
        ['new text']
      )
      test_query(
        'doc("catalog.xml")/catalog/text()',
        [""],
        'insert node "new text" as first into doc("catalog.xml")/catalog',
        ['new text']
      )
      test_query(
        'doc("catalog.xml")/catalog/text()',
        [""],
        'insert node "new text" before doc("catalog.xml")/catalog/product[2]',
        ['new text']
      )
      test_query(
        'doc("catalog.xml")/catalog/product[2]/name/text()',
        ["Floppy Sun Hat"],
        'insert node "new text" as last into doc("catalog.xml")/catalog/product[2]/name',
        ['Floppy Sun Hatnew text']
      )
      test_query(
        'doc("catalog.xml")/catalog/product[2]/name/text()',
        ["Floppy Sun Hat"],
        'insert node "new text" as first into doc("catalog.xml")/catalog/product[2]/name',
        ['new textFloppy Sun Hat']
      )
      test_query(
        'doc("catalog.xml")/catalog/product[3]/text()',
        ["one text"],
        'insert node "two text" as first into doc("catalog.xml")/catalog/product[3]',
        ['two textone text']
      )
      test_query(
        'doc("catalog.xml")/catalog/product[3]/text()',
        ["one text"],
        'insert node "two text" as last into doc("catalog.xml")/catalog/product[3]',
        ['one texttwo text']
      )
      test_query(
        'doc("catalog.xml")/catalog/product[3]/text()',
        ["one text"],
        'insert node "two text" before doc("catalog.xml")/catalog/product[3]/number',
        ['two textone text']
      )
      test_query(
        'doc("catalog.xml")/catalog/product[3]/text()',
        ["one text"],
        'insert node "two text" before doc("catalog.xml")/catalog/product[3]/name',
        ['one texttwo text']
      )
      test_query(
        'doc("catalog.xml")/catalog/product[3]/text()',
        ["one text"],
        'insert node "two text" after doc("catalog.xml")/catalog/product[3]/name',
        ['one texttwo text']
      )

      #FLWOR
      test_query(
        'doc("catalog.xml")/catalog/product[2]/name/text()',
        ["Floppy Sun Hat"],
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n = "Deluxe Travel Bag"
       order by $n
       return insert node $n before doc("catalog.xml")/catalog/product[2]/name',
       ['Deluxe Travel Bag', 'Floppy Sun Hat']
      )
      #more nodes to insert
      test_query(
        'doc("catalog.xml")/catalog/product[3]/name/text()',
        ["Deluxe Travel Bag"],
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language eq "en"
       order by $n
       return insert node $n before doc("catalog.xml")/catalog/product[3]/name',
       ['Cotton Dress Shirt', 'Deluxe Travel Bag', 'Fleece Pullover', 'Floppy Sun Hat', 'Deluxe Travel Bag']
      )
      #check after (nodes need to be reversed for proper insertion)
      test_query(
        'doc("catalog.xml")/catalog/product[3]/name/text()',
        ["Deluxe Travel Bag"],
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language eq "en"
       order by $n
       return insert node $n after doc("catalog.xml")/catalog/product[3]/name',
       ['Deluxe Travel Bag', 'Cotton Dress Shirt', 'Deluxe Travel Bag', 'Fleece Pullover', 'Floppy Sun Hat']
      )
      #insertion order
      test_query(
        'doc("catalog.xml")/catalog/product[3]/name/text()',
        ["Deluxe Travel Bag"],
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language eq "en"
       order by $n ascending
       return insert node $n after doc("catalog.xml")/catalog/product[3]/name',
       ['Deluxe Travel Bag', 'Cotton Dress Shirt', 'Deluxe Travel Bag', 'Fleece Pullover', 'Floppy Sun Hat']
      )
      test_query(
        'doc("catalog.xml")/catalog/product[3]/name/text()',
        ["Deluxe Travel Bag"],
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language eq "en"
       order by $n descending
       return insert node $n after doc("catalog.xml")/catalog/product[3]/name',
       ['Deluxe Travel Bag', 'Floppy Sun Hat', 'Fleece Pullover', 'Deluxe Travel Bag', 'Cotton Dress Shirt']
      )
      test_query(
        'doc("catalog.xml")/catalog/product[3]/name/text()',
        ["Deluxe Travel Bag"],
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language eq "en"
       order by $n descending
       return insert node $n before doc("catalog.xml")/catalog/product[3]/name',
       ['Floppy Sun Hat', 'Fleece Pullover', 'Deluxe Travel Bag', 'Cotton Dress Shirt', 'Deluxe Travel Bag']
      )
      test_query(
        'doc("catalog.xml")/catalog/product[3]/name/text()',
        ["Deluxe Travel Bag"],
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language eq "en"
       order by $n descending
       return insert node $n as first into doc("catalog.xml")/catalog/product[3]',
       ['Floppy Sun Hat', 'Fleece Pullover', 'Deluxe Travel Bag', 'Cotton Dress Shirt', 'Deluxe Travel Bag']
      )
      test_query(
        'doc("catalog.xml")/catalog/product[3]/name/text()',
        ["Deluxe Travel Bag"],
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language eq "en"
       order by $n descending
       return insert node $n as last into doc("catalog.xml")/catalog/product[3]',
       ['Deluxe Travel Bag', 'Floppy Sun Hat', 'Fleece Pullover', 'Deluxe Travel Bag', 'Cotton Dress Shirt']
      )

      #inserting multiple
      test_query(
        'doc("catalog.xml")/catalog/product[@ATTR = "seek"]/name/text()',
        [],
        'for $p in doc("catalog.xml")/catalog/product
       let $n := $p/name
       where $n/@language eq "en"
       order by $n descending
       return insert nodes ($n, <name>Another Name</name>, attribute ATTR { "seek" }, "twenty something") as last into doc("catalog.xml")/catalog/product[3]',
       ['Deluxe Travel Bag', 'Floppy Sun Hat', 'Fleece Pullover', 'Deluxe Travel Bag', 'Cotton Dress Shirt', 'Another Name', 'Another Name', 'Another Name', 'Another Name']
      )
    end
  end
end
