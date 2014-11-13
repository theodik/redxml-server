require 'spec_helper'

RSpec.describe RedXML::Server::Transformer::KeyElementBuilder do
  let(:key_builder) { RedXML::Server::Transformer::KeyBuilder.new('1', '2', '3') }
  before do
   @key_elem_builder = described_class.new(key_builder, '1')
  end

  it 'test_elem!' do
    assert_equal(true, @key_elem_builder.elem!("30", "2").key_str == "1:30>2")
    assert_equal(true, @key_elem_builder.elem!(2, 3).key_str == "1:30>2:2>3")
    assert_equal(true, @key_elem_builder.elem!(71, "4").elem!("2", 1).key_str == "1:30>2:2>3:71>4:2>1")
  end

  it 'test_elem' do
    assert_equal(true, @key_elem_builder.elem("30", "2") == "1:30>2")
    assert_equal(true, @key_elem_builder.elem(2, 3) == "1:2>3")
    assert_equal(true, @key_elem_builder.elem(71, "4") == "1:71>4")
    assert_equal(true, @key_elem_builder.elem!(71, "4").elem("341", 1003) == "1:71>4:341>1003")
  end

  it 'test_attr' do
    assert_equal(true, @key_elem_builder.attr() == "1<a")
    assert_equal(true, @key_elem_builder.elem!(123, 2).attr() == "1:123>2<a")
  end

  it 'test_text' do
    assert_equal(true, @key_elem_builder.text(3) == "1>t>3")
    assert_equal(true, @key_elem_builder.elem!(981, 312).text("1001") == "1:981>312>t>1001")
  end

  it 'test_comment' do
    assert_equal(true, @key_elem_builder.comment(5) == "1>c>5")
    assert_equal(true, @key_elem_builder.elem!(122, 91).comment("1000") == "1:122>91>c>1000")
  end

  it 'test_cdata' do
    assert_equal(true, @key_elem_builder.cdata(99) == "1>d>99")
    assert_equal(true, @key_elem_builder.elem!(2, 272).cdata("99") == "1:2>272>d>99")
  end

  it 'test_parent!' do
    assert_raise RedXML::Server::Transformer::NoElementError do
     @key_elem_builder.parent!
    end
    @key_elem_builder.elem!(12, 2).elem!("125", 54)
    assert_equal(true, @key_elem_builder.parent!.key_str == "1:12>2")
    @key_elem_builder.elem!(95, 45).elem!("12", "111")
    assert_equal(true, @key_elem_builder.parent!.key_str == "1:12>2:95>45")
    assert_equal(true, @key_elem_builder.parent!.parent!.key_str == "1")
  end

  it 'test_parent' do
    assert_raise RedXML::Server::Transformer::NoElementError do
     @key_elem_builder.parent
    end
    @key_elem_builder.elem!(11, "3").elem!(87, 32)
    assert_equal(true, @key_elem_builder.parent == "1:11>3")
    @key_elem_builder.elem!(54, 33).elem!("34", 112)
    assert_equal(true, @key_elem_builder.parent == "1:11>3:87>32:54>33")
    assert_equal(true, @key_elem_builder.parent!.parent == "1:11>3:87>32")
    assert_equal(true, @key_elem_builder.parent!.parent!.parent == "1")
  end

  it 'test_next_elem!' do
    assert_raise RedXML::Server::Transformer::NoElementError do
     @key_elem_builder.next_elem!
    end
    @key_elem_builder.elem!(41, "2").elem!(1, 1)
    assert_equal(true, @key_elem_builder.next_elem!.key_str == "1:41>2:1>2")
    assert_equal(true, @key_elem_builder.next_elem!.key_str == "1:41>2:1>3")
    @key_elem_builder.elem!(3, "99")
    assert_equal(true, @key_elem_builder.next_elem!.key_str == "1:41>2:1>3:3>100")
  end

  it 'test_next_elem' do
    assert_raise RedXML::Server::Transformer::NoElementError do
     @key_elem_builder.next_elem
    end
    @key_elem_builder.elem!(41, "2").elem!(1, 1)
    assert_equal(true, @key_elem_builder.next_elem == "1:41>2:1>2")
    @key_elem_builder.elem!(3, "1999")
    assert_equal(true, @key_elem_builder.next_elem == "1:41>2:1>1:3>2000")
  end

  it 'test_prev_elem!' do
    assert_raise RedXML::Server::Transformer::NoElementError do
     @key_elem_builder.prev_elem!
    end
    @key_elem_builder.elem!(23, "2").elem!(1, 30)
    assert_equal(true, @key_elem_builder.prev_elem!.key_str == "1:23>2:1>29")
    assert_equal(true, @key_elem_builder.prev_elem!.key_str == "1:23>2:1>28")
    @key_elem_builder.elem!(3, "100")
    assert_equal(true, @key_elem_builder.prev_elem!.key_str == "1:23>2:1>28:3>99")
    @key_elem_builder.elem!(999, "1")
    assert_raise RedXML::Server::Transformer::WrongOrderError do
     @key_elem_builder.prev_elem!
    end
  end

  it 'test_prev_elem' do
    assert_raise RedXML::Server::Transformer::NoElementError do
     @key_elem_builder.prev_elem
    end
    @key_elem_builder.elem!(23, "2").elem!(1, 30)
    assert_equal(true, @key_elem_builder.prev_elem == "1:23>2:1>29")
    @key_elem_builder.elem!(3, "100")
    assert_equal(true, @key_elem_builder.prev_elem == "1:23>2:1>30:3>99")
    @key_elem_builder.elem!(999, "1")
    assert_raise RedXML::Server::Transformer::WrongOrderError do
     @key_elem_builder.prev_elem
    end
  end

  it 'test_root_only?' do
    assert_equal(true, @key_elem_builder.root_only? == true)
    @key_elem_builder.elem!(1,1)
    assert_equal(true, @key_elem_builder.root_only? == false)
    assert_equal(true, @key_elem_builder.parent!.root_only? == true)
  end

  it 'test_elem_id' do
    assert_equal(true, @key_elem_builder.elem_id == "1")
    @key_elem_builder.elem!(12,29)
    assert_equal(true, @key_elem_builder.elem_id == "12")
    @key_elem_builder.elem!(99,99)
    assert_equal(true, @key_elem_builder.elem_id == "99")
    @key_elem_builder.parent!
    assert_equal(true, @key_elem_builder.elem_id == "12")
    @key_elem_builder.parent!
    assert_equal(true, @key_elem_builder.elem_id == "1")
  end

  it 'test_order' do
    assert_raise RedXML::Server::Transformer::WrongOrderError do
     @key_elem_builder.order
    end
    @key_elem_builder.elem!(2,99)
    assert_equal(true, @key_elem_builder.order == 99)
    @key_elem_builder.next_elem!
    assert_equal(true, @key_elem_builder.order == 100)
    @key_elem_builder.elem!(2, 12)
    assert_equal(true, @key_elem_builder.order == 12)
    @key_elem_builder.parent!
    assert_equal(true, @key_elem_builder.order == 100)
    @key_elem_builder.prev_elem!
    assert_equal(true, @key_elem_builder.order == 99)
    @key_elem_builder.parent!
    assert_raise RedXML::Server::Transformer::WrongOrderError do
     @key_elem_builder.order
    end
  end

  it 'test_text_order' do
    assert_raise RedXML::Server::Transformer::WrongOrderError do
     described_class.text_order("1")
    end
    assert_raise RedXML::Server::Transformer::WrongOrderError do
     described_class.text_order("1:2>2:99>1000")
    end
    assert_equal(true, described_class.text_order("1:2>99>t>3") == 3)
    assert_equal(true, described_class.text_order("1:2>99:987>21>t>99") == 99)
  end

  it 'test_text?' do
    assert_equal(true, described_class.text?("1") == false)
    assert_equal(true, described_class.text?("1:2>1") == false)
    assert_equal(true, described_class.text?("1:56>4>t>4:99>100") == false)
    assert_equal(true, described_class.text?("1:3>4>t>99") == true)
    assert_equal(true, described_class.text?("1:3>65>t>11:4>5>t>2") == true)
  end

  it 'test_comment?' do
    assert_equal(true, described_class.comment?("1") == false)
    assert_equal(true, described_class.comment?("1:2>1") == false)
    assert_equal(true, described_class.comment?("1:56>4>c>4:99>100") == false)
    assert_equal(true, described_class.comment?("1:3>4>c>99") == true)
    assert_equal(true, described_class.comment?("1:3>65>c>11:4>5>c>2") == true)
  end

  it 'test_cdata?' do
    assert_equal(true, described_class.cdata?("1") == false)
    assert_equal(true, described_class.cdata?("1:2>1") == false)
    assert_equal(true, described_class.cdata?("1:56>4>d>4:99>100") == false)
    assert_equal(true, described_class.cdata?("1:3>4>d>99") == true)
    assert_equal(true, described_class.cdata?("1:3>65>t>11:4>5>d>2") == true)
  end

  it 'test_element?' do
    assert_equal(true, described_class.element?("1") == true)
    assert_equal(true, described_class.element?("1:2>1") == true)
    assert_equal(true, described_class.element?("1:56>4>d>4:99>100") == true)
    assert_equal(true, described_class.element?("1:3>4>d>99") == false)
    assert_equal(true, described_class.element?("1:3>65>t>11:4>5>d>2") == false)
    assert_equal(true, described_class.element?("1:3>65>t>99:4>12>t>2") == false)
  end

  it 'test_text_type' do
    assert_equal(true, described_class.text_type("1") == false)
    assert_equal(true, described_class.text_type("1:2>1") == false)
    assert_equal(true, described_class.text_type("1:56>4>d>4:99>100") == false)
    assert_equal(true, described_class.text_type("1:3>4>d>99") == RedXML::Server::XML::TextContent::CDATA)
    assert_equal(true, described_class.text_type("1:3>65>t>11:4>5>c>2") == RedXML::Server::XML::TextContent::COMMENT)
    assert_equal(true, described_class.text_type("1:3>65>t>99:4>12>t>2") == RedXML::Server::XML::TextContent::PLAIN)
  end

  it 'test_build_from_s' do
    test_one = "1:2>7:5>1"
    test_two = "2:7>2:3>99>t>2"
    @key_elem_builder = described_class.build_from_s(@key_builder, test_one)
    assert_equal(true, @key_elem_builder.key_str == test_one)
    assert_equal(true, @key_elem_builder.order == 1)
    @key_elem_builder.next_elem!
    assert_equal(true, @key_elem_builder.order == 2)
    @key_elem_builder.parent!
    assert_equal(true, @key_elem_builder.order == 7)

    @key_elem_builder = described_class.build_from_s(@key_builder, test_two)
    #Attention here! Text keys are not supported, this is how it's supposed to be
    assert_equal(true, @key_elem_builder.key_str == "2:7>2:3>99")
    assert_equal(true, @key_elem_builder.order == 99)
    @key_elem_builder.next_elem!
    assert_equal(true, @key_elem_builder.order == 100)
    @key_elem_builder.parent!
    assert_equal(true, @key_elem_builder.order == 2)
  end
end
