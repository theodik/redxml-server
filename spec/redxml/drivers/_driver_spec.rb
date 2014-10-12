require 'spec_helper'

shared_examples 'a driver' do
  let(:key) { "key_#{rand(1.1000)}" }
  let(:value) { "value_#{rand(1.1000)}" }

  it 'sets key to a string' do
    subject.set_string(key, value)
    expect(subject.get_keys).to include key
    expect(subject.key_exists?(key)).to be_truthy
    expect(subject.get_string(key)).to eq value
  end

  it 'renames key' do
    old_key = 'key_1'
    new_key = 'key_2'
    subject.set_string(old_key, value)
    expect(subject.get_string(old_key)).to eq value
    subject.rename_key(old_key, new_key)
    expect(subject.get_string(new_key)).to eq value
  end

  it 'deletes a key' do
    subject.set_string(key, value)
    expect(subject.key_exists?(key)).to be_truthy
    subject.delete_key(key)
    expect(subject.key_exists?(key)).to be_falsey
  end

  it 'appends string to a key' do
    subject.set_string(key, value)
    new_value = value + '_new'
    subject.append_string(key, '_new')
    expect(subject.get_string(key)).to eq new_value
  end

  describe 'increment value' do
    let(:value) { rand(1..10) }

    it "creates value if it doesn'ẗ exists" do
      subject.increment_value(key)
      expect(subject.get_string(key)).to eq '1'
    end

    it 'increments value by one' do
      subject.set_string(key, "#{value}")
      subject.increment_value(key)
      expect(subject.get_string(key)).to eq((value + 1).to_s)
    end

    it 'increments value by value' do
      subject.set_string(key, "#{value}")
      inc_val = rand(1..10)
      subject.increment_value(key, inc_val)
      expect(subject.get_string(key)).to eq((value + inc_val).to_s)
    end
  end

  context 'decrement value' do
    let(:value) { rand(1..10) }

    it "creates value if it doesn'ẗ exists" do
      subject.decrement_value(key)
      expect(subject.get_string(key)).to eq '-1'
    end

    it 'decrements value by one' do
      subject.set_string(key, "#{value}")
      subject.decrement_value(key)
      expect(subject.get_string(key)).to eq((value - 1).to_s)
    end

    it 'decrements value by value' do
      subject.set_string(key, "#{value}")
      inc_val = rand(1..10)
      subject.decrement_value(key, inc_val)
      expect(subject.get_string(key)).to eq((value - inc_val).to_s)
    end
  end

  context 'hashes' do
    let(:value) { { 'key1' => 'value1', 'key2' => 'value' } }

    it 'sets hash to a key' do
      subject.set_hash(key, value)
      value.keys.each do |field|
        expect(subject.field_exists?(key, field)).to be_truthy
      end
      expect(subject.get_hash(key)).to eq value
    end

    it 'deletes a field' do
      subject.set_hash(key, value)
      expect(subject.field_exists?(key, 'key1')).to be_truthy
      subject.delete_value(key, 'key1')
      expect(subject.field_exists?(key, 'key1')).to be_falsey
    end

    it 'sets value of a hash field' do
      field = 'field'
      value = 'value'
      subject.set_value(key, field, value)
      expect(subject.get_value(key, field)).to eq value
    end

    it 'returns all values from a hash' do
      subject.set_hash(key, value)
      expect(subject.get_values(key)).to eq value.values
    end

    it 'returns all fields of a hash' do
      subject.set_hash(key, value)
      expect(subject.get_fields(key)).to eq value.keys
    end
  end
end
