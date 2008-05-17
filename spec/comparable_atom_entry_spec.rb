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
    before(:each) do
      @comparison = ComparableAtomEntry.compare(@entry, @entry)
    end

    it 'should be the same' do
      @comparison.should be_same
    end

    it 'should not be different' do
      @comparison.should_not be_different
    end

    it 'should not have missing elements' do
      @comparison.missing_elements.should be_empty
    end

    it 'should not have different elements' do
      @comparison.different_elements.should be_empty
    end

    it 'should not have different element types' do
      @comparison.different_element_types.should be_empty
    end

    it 'should have no differences' do
      @comparison.differences.should be_empty
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

      it 'should have differences' do
        @comparison.should have(2).differences
      end

      it 'should report differences in English' do
        @comparison.differences.should include('content element is missing.')
        @comparison.differences.should include('summary element is missing.')
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
          @entry.title.to_s, @entry_with_different_elements.title.to_s])
      end
      
      it 'should report content as different' do
        @comparison.different_elements.should include([:content,
          @entry.content.to_s, @entry_with_different_elements.content.to_s])
      end

      it 'should have differences' do
        @comparison.should have(2).differences
      end

      it 'should report differences in English' do
        @comparison.differences.should include('title element is "foo" but it should be "Keep Ya Head Up".')
        @comparison.differences.should include('content element is "bar" but it should be "for sure!".')
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

      it 'should report title as having a different type' do
        @comparison.different_element_types.should include([:title, 'text', 'html'])
      end

      it 'should have difference' do
        @comparison.should have(1).difference
      end

      it 'should report difference in English' do
        @comparison.difference.should include('title element has type "html" but it should be "text".')
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

    describe 'with missing, different and different @type elements' do
      before(:each) do
        @entry = Atom::Entry.new.tap do |e|
          e.title = '<strong>foo</strong>'
          e.summary = 'bar'
          e.content = '<p>spam</p>'
          end.tap do |e|
            e.title['type'] = 'html'
            e.content['type'] = 'xhtml'
        end

        @different_entry = Atom::Entry.new.tap do |e|
          e.title = 'foo'
          e.content = '<strong>yumyum</strong>'
          end.tap do |e|
            e.title['type'] = 'text'
            e.content['type'] = 'html'
        end

        @comparison = ComparableAtomEntry.compare(@entry, @different_entry)
      end

      it 'should be different' do
        @comparison.should be_different
      end

      it 'should not be the same' do
        @comparison.should_not be_same
      end

      it 'should have missing elements' do
        @comparison.missing_elements.should have(1).missing_elements
      end

      it 'should have different elements' do
        @comparison.should have(2).different_elements
      end

      it 'should have different element types' do
        @comparison.should have(2).different_element_types
      end

      it 'should report summary as missing' do
        @comparison.missing_elements.should include(:summary)
      end

      it 'should report different title' do
        @comparison.different_elements.should include([:title, '<strong>foo</strong>', 'foo'])
      end

      it 'should report different content' do
        @comparison.different_elements.should include([:content, '<p>spam</p>', '<strong>yumyum</strong>'])
      end

      it 'should report title as having a different type' do
        @comparison.different_element_types.should include([:title, 'html', 'text'])
      end

      it 'should report content as having a different type' do
        @comparison.different_element_types.should include([:content, 'xhtml', 'html'])
      end

      it 'should have differences' do
        @comparison.should have(5).differences
      end

      it 'should report differences in English' do
        @comparison.differences.should include('summary element is missing.')
        @comparison.differences.should include('title element is "foo" but it should be "<strong>foo</strong>".')

        @comparison.differences.should include('content element is "<strong>yumyum</strong>" but it should be "<p>spam</p>".')
        @comparison.differences.should include('title element has type "text" but it should be "html".')
        @comparison.differences.should include('content element has type "html" but it should be "xhtml".')
      end
    end
  end
end

