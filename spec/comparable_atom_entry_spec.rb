require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/../lib/ape/comparable_atom_entry'

describe ComparableAtomEntry do
  before(:each) do

    @entry = Atom::Entry.new.tap do |e|
      e.title = 'Keep Ya Head Up'
      e.summary = 'nice song'
      e.content = 'for sure!'
    end
  end

  describe 'In general' do
    it 'should accept reference entry as an Atom::Entry' do
      lambda { ComparableAtomEntry.new(@entry) }.should_not raise_error
    end

    it 'should accept reference as a string' do
      lambda { ComparableAtomEntry.new(@entry.to_s) }.should_not raise_error
    end

    it 'should raise ArgumentError if unable to parse reference entry' do
      lambda { ComparableAtomEntry.new('<foo/>') }.should raise_error(ArgumentError)
    end

    it 'should accept entry to compare as an Atom::Entry' do
      lambda { ComparableAtomEntry.new(@entry).compare_with(@entry) }.should_not raise_error
    end

    it 'should accept entry to compare as a string' do
      lambda { ComparableAtomEntry.new(@entry).compare_with(@entry.to_s) }.should_not raise_error
    end

    it 'should raise ArgumentError if unable to parse entry to compare' do
      lambda { ComparableAtomEntry.new(@entry).compare_with('<bar>') }.should raise_error(ArgumentError)
    end
  end

  describe 'When comparing two similar entries' do
    it 'should be the same' do
      ComparableAtomEntry.compare(@entry, @entry).should be_same
    end

    it 'should not be different' do
      ComparableAtomEntry.compare(@entry, @entry).should_not be_different
    end

    it 'should not have missing elements' do
      ComparableAtomEntry.compare(@entry, @entry).missing_elements.should be_empty
    end

    it 'should not have different elements' do
      ComparableAtomEntry.compare(@entry, @entry).different_elements.should be_empty
    end

    it 'should not have different element types' do
      ComparableAtomEntry.compare(@entry, @entry).different_element_types.should be_empty
    end
  end

  describe 'When comparing two differents entries' do
    describe 'with missing elements' do
      before(:each) do
        @entry_with_missing_elements = Atom::Entry.new.tap do |e|
          e.title = 'Keep Ya Head Up'
        end
        @comparison = ComparableAtomEntry.compare(@entry, @entry_with_missing_elements)
      end

      it 'should be different' do
        @comparison.should be_different
      end

      it 'should not be the same' do
        @comparison.should_not be_same
      end

      it 'should have missing elements' do
        @comparison.should have(2).missing_elements
      end

      it 'should be missing content' do
        @comparison.missing_elements.should include(:content)
      end

      it 'should be missing summary' do
        @comparison.missing_elements.should include(:summary)
      end
    end

    describe 'with different elements' do
      before(:each) do
        @entry_with_different_elements = @entry.clone.tap do |e|
          e.title = 'foo' 
          e.content = 'bar'
        end

        @comparison = ComparableAtomEntry.compare(@entry, @entry_with_different_elements)
      end

      it 'should be different' do
        @comparison.should be_different
      end

      it 'should have different elements' do
        @comparison.should have(2).different_elements
      end

      it 'should report title as different' do
        @comparison.different_elements.should include([:title,
          @entry.title, @entry_with_different_elements.title])
      end
      
      it 'should report content as different' do
        @comparison.different_elements.should include([:content,
          @entry.content, @entry_with_different_elements.content])
      end

      it 'should not be the same' do
        @comparison.should_not be_same
      end

      it 'should not be missing element' do
        @comparison.missing_elements.should be_empty
      end
    end

    describe 'with different elements[@type]' do
      before(:each) do
        @entry_with_different_element_types = Atom::Entry.new.tap do |e|
          e.title = 'Keep Ya Head Up'
          e.summary = 'nice song'
          e.content = 'for sure!'
        end
      
        @entry_with_different_element_types.title['type'] = 'html'
        @comparison = ComparableAtomEntry.compare(@entry, @entry_with_different_element_types)
      end

      it 'should be different' do
        @comparison.should be_different
      end

      it 'should have different element types' do
        @comparison.should have(1).different_element_types
      end

      it 'should report title has having a different type' do
        @comparison.different_element_types.should include([:title, 'text', 'html'])
      end

      it 'should not be the same' do
        @comparison.should_not be_same
      end

      it 'should not be missing element' do
        @comparison.missing_elements.should be_empty
      end

      it 'should not have different elements' do
        @comparison.different_elements.should be_empty
      end
    end 
  end
end

