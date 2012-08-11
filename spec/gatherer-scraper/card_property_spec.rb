# -*- encoding: utf-8 -*-
require 'spec_helper'

describe CardProperty, :vcr => { :cassette_name => 'gatherer/card', :record => :new_episodes } do
  context "when 'Acidic Slime' multiverseid is given" do
    before(:all) do
      VCR.use_cassette('gatherer/card', record: :new_episodes) do
        @acidic_slime = described_class.parse(265718)
      end
    end
    subject { @acidic_slime }
    its(:multiverseid) { should == 265718 }
    its(:card_name) { should == 'Acidic Slime' }
    its(:'mana_cost.mana_symbols') { should == [3, :Green, :Green] }
    its(:converted_mana_cost) { should == 5 }
    its(:'type.supertypes') { should == [] }
    its(:'type.cardtypes') { should == [:Creature] }
    its(:'type.subtypes') { should == [:Ooze] }
    its(:card_text) do
      should == (<<EOS).chomp
<div class="cardtextbox">Deathtouch <i>(Any amount of damage this deals to a creature is enough to destroy it.)</i>
</div>
<div class="cardtextbox">When Acidic Slime enters the battlefield, destroy target artifact, enchantment, or land.</div>
EOS
    end
    its(:flavor_text) { should be_nil }
    its(:'p_t.power') { should == '2' }
    its(:'p_t.toughness') { should == '2' }
    its(:expansion) { should == :'Magic 2013' }
    its(:rarity) { should == :Uncommon }

    describe '#all_sets' do
      subject { @acidic_slime.all_sets }
      it "should contain 'Magic 2010 (Uncommon)'" do
        subject.include?(AllSet.new(:'Magic 2010', :Uncommon)).should be_true
      end
      it "should contain 'Magic 2011 (Uncommon)'" do
        subject.include?(AllSet.new(:'Magic 2011', :Uncommon)).should be_true
      end
      it "should contain 'Magic 2012 (Uncommon)'" do
        subject.include?(AllSet.new(:'Magic 2012', :Uncommon)).should be_true
      end
      it "should contain 'Magic 2013 (Uncommon)'" do
        subject.include?(AllSet.new(:'Magic 2013', :Uncommon)).should be_true
      end
      it "should contain 'Magic: The Gathering-Commander (Uncommon)'" do
        subject.include?(AllSet.new(:'Magic: The Gathering-Commander', :Uncommon)).should be_true
      end
      its(:length) { should == 5 }
    end
    its(:card_number) { should == 159 }
    its(:artist) { should == 'Karl Kopinski' }
  end
  context 'when M13 cards are given' do
    it 'should not raise error' do
      multiverseids = GathererScraper::SearchResult.new(set: 'Magic 2013').multiverseids
      expect do
        multiverseids.each do |multiverseid|
          begin
            described_class.parse(multiverseid)
          rescue => e
            raise e.exception(e.message + " + multiverseid: #{multiverseid}")
          end
        end
      end.not_to raise_error
    end
  end

  describe '(validation category)' do
    before(:all) do
      VCR.use_cassette('gatherer/card', record: :new_episodes) do
        @slime = described_class.parse(265718)
        def @slime.select(overrides, attr_sym)
          if overrides.has_key? attr_sym
            overrides[attr_sym]
          else
            instance_eval "#{attr_sym}"
          end
        end
        def @slime.override(overrides = {})
          CardProperty.new(select(overrides, :multiverseid),
                           select(overrides, :card_name),
                           select(overrides, :mana_cost),
                           select(overrides, :converted_mana_cost),
                           select(overrides, :type),
                           select(overrides, :card_text),
                           select(overrides, :flavor_text),
                           select(overrides, :p_t),
                           select(overrides, :expansion),
                           select(overrides, :rarity),
                           select(overrides, :all_sets),
                           select(overrides, :card_number),
                           select(overrides, :artist))
        end
      end
    end
    describe 'no override CardProperty' do
      subject { @slime.override }
      it 'all properties should == original\'s' do
        subject.multiverseid.should == @slime.multiverseid
        subject.card_name.should == @slime.card_name
        subject.mana_cost.should == @slime.mana_cost
        subject.converted_mana_cost.should == @slime.converted_mana_cost
        subject.type.should == @slime.type
        subject.card_text.should == @slime.card_text
        subject.flavor_text.should == @slime.flavor_text
        subject.p_t.should == @slime.p_t
        subject.expansion.should == @slime.expansion
        subject.rarity.should == @slime.rarity
        subject.all_sets.should == @slime.all_sets
        subject.card_number.should == @slime.card_number
        subject.artist.should == @slime.artist
      end
    end
    shared_examples_for :validation do |subject_exp, is_raise_error, value_text, error_text_for_match|
      if is_raise_error
        it "when it is #{value_text} should raise Exception" do
          if error_text_for_match
            eval(subject_exp).to raise_error(ArgumentError, error_text_for_match)
          else
            eval(subject_exp).to raise_error(ArgumentError)
          end
        end
      else
        it "should accept value #{value_text}" do
          eval(subject_exp).not_to raise_error
        end
      end
    end
    def self.validation_spec(attr_name, value, is_raise_error, desc_texts = {})
      subject_exp = "expect { @slime.override(#{ {attr_name => value} }) }"
      value_text = desc_texts[:value_text] || value.to_s
      include_examples :validation, subject_exp, is_raise_error, value_text, desc_texts[:error_text]
    end
    def self.nil_validation_spec(attr_name, is_raise_error)
      options = { value_text: '"nil"' }
      options[:error_text] = /can't be blank/ if is_raise_error
      validation_spec(attr_name, nil, is_raise_error, options)
    end
    def self.kind_validation_spec(attr_name, value, kind_of_class)
      validation_spec(attr_name, value, true,
                      value_text: "not #{kind_of_class} object (ex: #{value}:#{value.class})",
                      error_text: /not a kind of #{kind_of_class}/)
    end
    def self.strip_validation_spec(attr_name, multiline = false)
      validation_spec(attr_name, " test ", true, value_text:
                      'not striped text (ex: " test ")', error_text: /is invalid/)
      if multiline
        validation_spec(:flavor_text, "line one\nline two", false,
                        value_text: 'a multiline striped text')
      end
    end
    describe '#multiverseid' do
      context 'when it is 1' do
        it { @slime.override({multiverseid: 1}).multiverseid.should == 1 }
        validation_spec :multiverseid, 1, false
      end
      kind_validation_spec(:multiverseid, "10", Integer)
      validation_spec :multiverseid, "1aa0", true, error_text: /not a number/
      nil_validation_spec :multiverseid, true
      validation_spec(:multiverseid, -1, true,
                      error_text: /must be greater than or equal to 1/)
      validation_spec(:multiverseid, 0, true,
                      error_text: /must be greater than or equal to 1/)
    end
    describe '#card_name' do
      kind_validation_spec(:card_name, 1, String)
      nil_validation_spec :card_name, true
      strip_validation_spec :card_name
    end
    describe '#mana_cost' do
      kind_validation_spec(:mana_cost, [:test], ManaCost)
      nil_validation_spec :mana_cost, false
      describe 'ManaCost#mana_symbols' do
        def self.validation_spec(value, is_raise_error, desc_texts = {})
          subject_exp = "expect { ManaCost.new(#{value}) }"
          value_text = desc_texts[:value_text] || value.to_s
          include_examples(:validation, subject_exp, is_raise_error, value_text,
                           desc_texts[:error_text])
        end
        validation_spec(':Red', true, value_text: 'not Enumerable object(ex: Red:Symbol)',
                        error_text: /not a kind of Enumerable/)
        validation_spec([], true, value_text: '[](blank array)',
                        error_text: /can't be blank/)
        describe 'invalid state element' do
          validation_spec(['test'], true,
                          value_text: 'containing neither Integer nor Symbol',
                          error_text: /neither a kind of Integer nor Symbol/)
          validation_spec([15], false,
                          value_text: 'two digit mana cost (ex: 15)')
          validation_spec([-1], true,
                          value_text: 'containing not a Natural Number',
                          error_text: /not a Natural Number/)
          validation_spec([3, :Red, :Phy_Red], true,
                          value_text: 'containing unknown symbol(ex: Phy_Red)',
                          error_text: /not contained in Mana Symbol List/)
        end
        validation_spec([:'Variable Colorless', 3, :Red], false,
                        value_text: 'X mana(ex: X3R)')
        validation_spec([:Red, 3], true,
                        value_text: 'having a Integer other than leftmost or next to X(ex: R3)',
                        error_text: /invalid mana symbol order/)
        validation_spec([:'Variable Colorless', :Red, 3], true,
                        value_text: 'having a Integer other than leftmost or next ot X(ex: XR3)',
                        error_text: /invalid mana symbol order/)
      end
    end
    describe '#converted_mana_cost' do
      nil_validation_spec :converted_mana_cost, false
      validation_spec :converted_mana_cost, 0, false
      validation_spec(:converted_mana_cost, -1, true, value_text: 'Minus(ex: -1)',
                      error_text: /must be greater than or equal to 0/)
      kind_validation_spec(:converted_mana_cost, 0.5, Integer)
    end
    describe '#type' do
      nil_validation_spec :type, true
      kind_validation_spec(:type, 3, Type)
    end
    describe Type do
      def override(overrides = {})
        archetype = @slime.type
        Type.new(overrides.has_key?(:supertypes) ? overrides[:supertypes] : archetype.supertypes,
                 overrides.has_key?(:cardtypes) ? overrides[:cardtypes] : archetype.cardtypes,
                 overrides.has_key?(:subtypes) ? overrides[:subtypes] : archetype.subtypes)
      end
      shared_examples_for :types do |example_of_allowing_types, allow_blank_array, contain_unknown_type|
        def self.validation_spec(value, is_raise_error, desc_texts = {})
          subject_exp = "expect { override( { subject => #{value} }) }"
          value_text = desc_texts[:value_text] || value.to_s
          include_examples(:validation, subject_exp, is_raise_error, value_text,
                           desc_texts[:error_text])
        end
        validation_spec('nil', true, value_text: '"nil"',
                        error_text: /can't be (nil|blank)/)
        if allow_blank_array
          validation_spec [], false, value_text: 'a blank array([])'
        else
          validation_spec([], true, value_text: 'a blank array([])',
                          error_text: /blank/)
        end
        validation_spec(example_of_allowing_types, false,
                        value_text: 'multiple elements')
        if contain_unknown_type
          validation_spec([:Unknown], false,
                          value_text: 'unknown element now yet')
        else
          validation_spec([:Unknown], true, value_text: 'unknown element',
                          error_text: /not a (super|card|sub)type/)
        end
        validation_spec(example_of_allowing_types * 2, true,
                        value_text: 'having duplicate elements',
                        error_text: /not unique/)
      end
      describe '#supertypes' do
        subject { :supertypes }
        include_examples :types, Type::ALL_SUPERTYPE_LIST, true, false
      end
      describe '#cardtypes' do
        subject { :cardtypes }
        include_examples :types, Type::ALL_CARDTYPE_LIST, false, false
      end
      describe '#subtypes' do
        subject { :subtypes }
        include_examples :types, Type::ALL_SUPERTYPE_LIST, true, true
      end
    end
    describe '#card_text' do
      nil_validation_spec :card_text, false
      kind_validation_spec :card_text, 3, String
      strip_validation_spec :card_text, multiline: true
    end
    describe '#flavor_text' do
      nil_validation_spec :flavor_text, false
      kind_validation_spec :flavor_text, 3, String
      strip_validation_spec :flavor_text, multiline: true
    end
    describe '#p_t' do
      nil_validation_spec :p_t, false
      kind_validation_spec :p_t, [1, 2], PT
    end
    describe PT do
      def self.validation_spec(power, toughness, is_raise_error, desc_texts = {})
        subject_exp = "expect { PT.new('#{power}', '#{toughness}') }"
        value_text = desc_texts[:value_text] || "( #{power} / #{toughness} )"
        include_examples(:validation, subject_exp, is_raise_error, value_text,
                         desc_texts[:error_text])
      end
      validation_spec 2, 2, false, value_text: 'a Bear ( 2 / 2 )'
      validation_spec 0, 0, false
      validation_spec(-3, -2, false)
      validation_spec 'abc', 'def', true
      validation_spec '*', '*', false
      validation_spec '*', '1+*', false, value_text: 'Tarmogoyf ( * / 1+* )'
    end
    describe '#expansion' do
      nil_validation_spec :expansion, true
      kind_validation_spec :expansion, 'test', Symbol
      strip_validation_spec :expansion
      validation_spec(:expansion, :'Magic 2013', false,
                      value_text: 'supporting expansion (ex: Magic 2013)')
      validation_spec(:expansion, :'Magic 2010', true,
                      value_text: 'unsupporting expansion (ex: Magic 2010)')
    end
    describe '#rarity' do
      nil_validation_spec :rarity, true
      kind_validation_spec :rarity, 'Rare', Symbol
      CardProperty::ALL_RARITY_LIST.each do |rarity|
        validation_spec :rarity, rarity, false
      end
      validation_spec :rarity, :Unrare, true, value_text: ':Unrare(Symbol)'
    end
    describe '#all_sets' do
      validation_spec :all_sets, nil, true, value_text: '"nil"',
        error_text: /can't be nil/
      validation_spec :all_sets, [], false
      kind_validation_spec :all_sets, 'M13 Rare', Enumerable
      include_examples :validation, "expect { @slime.override( {:all_sets => ([AllSet.new(:'Magic 2013', :Rare)])} ) }", false, 'Array what only contains :AllSet objects', nil
      validation_spec :all_sets, [3, 2], true,
        value_text: 'containing not a AllSet object',
        error_text: /can only contain AllSet object/
    end
    describe AllSet do
      def self.validation_spec(set_name, rarity, is_raise_error, desc_texts = {})
        subject_exp = "expect { AllSet.new(#{set_name}, #{rarity}) }"
        value_text = desc_texts[:value_text] || "( #{set_name} - #{rarity} )"
        include_examples(:validation, subject_exp, is_raise_error, value_text,
                         desc_texts[:error_text])
      end
      validation_spec ":'Magic 2010'", ':Uncommon', false
      validation_spec("'Magic 2010'", ":'Uncommon'", true,
                      value_text: 'its set_name is not a Symbol Object',
                      error_text: /not a kind of Symbol/)
      validation_spec(":'Magic 2010'", "'Uncommon'", true,
                      value_text: 'its rarity is not a Symbol Object',
                      error_text: /not a kind of Symbol/)
      validation_spec(":'ABCDEFG'", ':Uncommon', false,
                      value_text: 'random name(ABCDEFG) (FIXME:)')
      AllSet::ALL_RARITY_LIST.each do |rarity|
        validation_spec(":'Magic 2010'", ":'#{rarity}'", false,
                        value_text: rarity)
      end
    end
    describe '#card_number' do
      nil_validation_spec :card_number, true
      kind_validation_spec :card_number, 0.5, Integer
      validation_spec(:card_number, 0, true, value_text: 'zero(0)',
                      error_text: /must be greater than or equal to 1/)
      validation_spec :card_number, 1, false
    end
    describe '#artist' do
      kind_validation_spec :artist, 1, String
      nil_validation_spec :artist, true
      strip_validation_spec :artist
    end
  end
end