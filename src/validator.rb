#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

if RUBY_PLATFORM =~ /java/
  require 'java'
  CompactSchemaReader = com.thaiopensource.validate.rng.CompactSchemaReader
  ValidationDriver = com.thaiopensource.validate.ValidationDriver
  StringReader = java.io.StringReader
  StringWriter = java.io.StringWriter
  InputSource = org.xml.sax.InputSource
  ErrorHandlerImpl = com.thaiopensource.xml.sax.ErrorHandlerImpl
  PropertyMapBuilder = com.thaiopensource.util.PropertyMapBuilder
  ValidateProperty = com.thaiopensource.validate.ValidateProperty
end

class Validator

  attr_reader :error

  def Validator.validate(schema, text, name, ape)
    # Can do this in JRuby, not native Ruby (sigh)
    if RUBY_PLATFORM =~ /java/
      rnc_validate(schema, text, name, ape)
    else
      true
    end
  end

  def Validator.rnc_validate(schema, text, name, ape)
    schemaError = StringWriter.new
    schemaEH = ErrorHandlerImpl.new(schemaError)
    properties = PropertyMapBuilder.new
    properties.put(ValidateProperty::ERROR_HANDLER, schemaEH)
    error = nil
    driver = ValidationDriver.new(properties.toPropertyMap, CompactSchemaReader.getInstance)
    if driver.loadSchema(InputSource.new(StringReader.new(schema)))
      if !driver.validate(InputSource.new(StringReader.new(text)))
        error = schemaError
      end
    else
      error = schemaError
    end

    if !error
      ape.good "#{name} passed schema validation."
    else
      # this kind of sucks, but I spent a looong time lost in a maze of twisty
      #  little passages without being able to figure out how to 
      #  tell jing what name I'd like to call the InputSource
      ape.error "#{name} failed schema validation:\n" + error.toString.gsub('(unknown file):', 'Line ')
      false
    end

  end

end


