require 'atom/entry'

class ComparableAtomEntry
  COMPARABLE_ELEMENTS = %w(title summary content)

  def self.compare(reference_entry, compared_entry)
    new(reference_entry).compare_with(compared_entry)
  end
      
  def initialize(reference_entry)
    @reference = get_entry_from(reference_entry)
  end

  def compare_with(compared_entry)
    compared = get_entry_from(compared_entry)
    comparison = ComparableAtomEntryResult.new

    COMPARABLE_ELEMENTS.map{|e| e.to_sym}.each do |element|
      comparison.missing_elements << element if has_element?(@reference, element) && !has_element?(compared, element)

      next if comparison.missing_elements.include?(element)

      unless compared.send(element).to_s == @reference.send(element).to_s
        comparison.different_elements << [element, @reference.send(element), compared.send(element)] 
      end

      unless @reference.send(element)['type'] == compared.send(element)['type']
        comparison.different_element_types << [element, @reference.send(element)['type'],
          compared.send(element)['type']]
      end
    end

    comparison
  end

  def different_from?(compared_entry)
    !same_as?(compared_entry)
  end

  private
    def get_entry_from(entry)
      entry.is_a?(Atom::Entry) ? entry : Atom::Entry.parse(entry)
    rescue Atom::ParseError
      raise ArgumentError
    end

    def has_element?(entry, element)
      entry.respond_to?(element) && entry.send(element)
    end
end

class ComparableAtomEntryResult
  attr_accessor :missing_elements, :different_elements, :different_element_types

  def initialize
    @missing_elements   = []
    @different_elements = []
    @different_element_types = []
  end

  def same?
    missing_elements.empty? && different_elements.empty? && different_element_types.empty?
  end

  def different?
    !same?
  end
end
