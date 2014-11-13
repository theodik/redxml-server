require 'spec_helper'

RSpec.describe RedXML::Server::Transformer::KeyBuilder do
  subject { described_class.new('1', '2', '3') }

  it 'returns env key' do
    expect(described_class.environments_key).to eq 'environments'
  end

  it 'test_colletions_key' do
    expect(described_class.collections_key("1")).to eq "1:collections"
  end

  it 'test_child_colletions_key' do
    expect(described_class.child_collections_key("1", "2")).to eq "1:2:collections"
  end

  it 'test_documents_key' do
    expect(described_class.documents_key("1", "2")).to eq "1:2:documents"
  end

  it 'test_collection_info' do
    expect(subject.collection_info).to eq "1:2<info"
    expect(described_class.collection_info("a3c", "555")).to eq "a3c:555<info"
  end

  shared_examples 'key builder' do
    it 'test_environment_info' do
      expect(subject.environment_info).to eq "1<info"
      expect(described_class.environment_info("a3c")).to eq "a3c<info"
    end

    it 'test_info' do
      expect(subject.info).to eq "1:2:3<info"
    end

    it 'test_env_iterator_k' do
      expect(described_class.env_iterator_key).to eq "info"
    end

    it 'test_elem_mapping_key' do
      expect(subject.elem_mapping_key).to eq "1:2:3<emapping"
    end

    it 'test_attr_mapping_key' do
      expect(subject.attr_mapping_key).to eq "1:2:3<amapping"
    end

    it 'test_content_key' do
      expect(subject.content_key).to eq "1:2:3<content"
    end

    it 'test_namespace_key' do
      expect(subject.namespace_key).to eq "1:2:3<namespaces"
    end

    describe '#root' do
      it 'initializes with string' do
        element_builder = subject.root("1")
        expect(element_builder).to be_a RedXML::Server::Transformer::KeyElementBuilder
        expect(element_builder.root_key).to eq '1'
      end
      it 'initializes with integer' do
        element_builder = subject.root(1)
        expect(element_builder).to be_a RedXML::Server::Transformer::KeyElementBuilder
        expect(element_builder.root_key).to eq '1'
      end
    end

    it 'test_to_s' do
      result = "#{subject}"
      expect(result).to eq "1:2:3"
    end
  end

  context 'builds from string' do
    it_behaves_like 'key builder' do
      described_class.build_from_s "1:2:3<info"
    end
    it_behaves_like 'key builder' do
      described_class.build_from_s "1:2:3"
    end
    it_behaves_like 'key builder' do
      described_class.build_from_s "1:2:3<nonsense"
    end
  end
end
