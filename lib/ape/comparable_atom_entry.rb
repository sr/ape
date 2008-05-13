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
    result = ComparableAtomEntryResult.new(@reference, compared_entry)

    COMPARABLE_ELEMENTS.map(&:to_sym).each do |element|
      result.missing_elements << element if @reference.respond_to?(element) && !compared.respond_to?(element)
      next if result.missing_elements.include?(element)

      unless compared.send(element) == reference.send(element)
        result.differing_elements << [element, reference.send(element), compared.send(element)] 
      end
      unless @reference.send(element)['type'] == compared.send(element)['type']
        result.differing_elements_type << [reference.send(element)['type'], compared.send(element)['type']]
      end
    end

    result
  end

  def same_as?(compared_entry)
    compare_with(compared_entry).same?
  end

#  alias :same_as? :==

  def different_from?(compared_entry)
    !same_as?(compared_entry)
  end

  private
    def get_entry_from(entry)
      return
        if entry.is_a?(Atom::Entry)
          entry
        else
          Atom::Entry.parse(entry)
        end
    rescue Atom::ParseError
      raise ArgumentError
    end
end

class ComparableAtomEntryResult
  attr_accessor :missing_elements, :differing_elements, :differing_element_types

  def initialize
    @missing_elements   = []
    @differing_elements = []
    @differing_element_types = []
  end

  def differences 
    differences = []

    @missing_elements.each { |element| differences << "#{element} is missing" }

    @differing_elements.each do |element, reference_element, compared_element|
      differences << "#{element} is #{compared_element} but should be #{reference_element}"
    end

    @differing_type.each do |element, reference_element_type, compared_element_type|
      differences << "#{element} has type #{compared_element_type} but should be #{reference_element_type}"
    end

    differences
  end

  def same?
    missing_elements.empty? && differing_elements.empty? && differing_types
  end

  def different?
    !same
  end
end
