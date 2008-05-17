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

    COMPARABLE_ELEMENTS.map(&:to_sym).select{ |e| @reference.respond_to?(e) }.each do |element|
      comparison.missing_elements << element unless has_element?(compared, element)

      next if comparison.missing_elements.include?(element)

      unless compared.send(element).to_s == @reference.send(element).to_s
        comparison.different_elements << [element, @reference.send(element).to_s, compared.send(element).to_s] 
      end

      unless @reference.send(element)['type'] == compared.send(element)['type']
        comparison.different_element_types << [element, @reference.send(element)['type'],
          compared.send(element)['type']]
      end
    end

    # TODO: be more precise (analyse scheme and label)
    @reference.categories.each do |category|
      comparison.missing_categories << category unless has_category?(compared, category)
    end

    comparison
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

    def has_category?(entry, category)
      entry.categories.detect { |c| c.term == category.term }
    end
end

class ComparableAtomEntryResult
  attr_accessor :missing_elements, :different_elements, :different_element_types
  attr_accessor :missing_categories

  def initialize
    @missing_elements   = []
    @different_elements = []
    @different_element_types = []
    @missing_categories = []
  end

  def same?
    missing_elements.empty? && different_elements.empty? && different_element_types.empty? && \
      missing_categories.empty?
  end

  def different?
    !same?
  end

  def differences
    differences = []
    @missing_elements.each { |element| differences << "#{element} element is missing."}

    @different_elements.each do |element, reference_element, compared_element|
      differences << %Q{#{element} element is "#{compared_element}" but it should be "#{reference_element}".}
    end

    @different_element_types.each do |element, reference_type, compared_type|
      differences << %Q{#{element} element has type "#{compared_type}" but it should be "#{reference_type}".}
    end

    @missing_categories.each { |category| differences << %Q{Category #{category.to_s} is missing.} }

    differences
  end

  alias :difference :differences
end
