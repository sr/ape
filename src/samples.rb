#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'rexml/xpath'

require 'date'
require 'base64'
require 'escaper'
require 'names'

class Samples


  def Samples.foreign_child
    'subject'
  end
  def Samples.foreign_namespace
    Names::DcNamespace
  end
  def Samples.foreign_child_content
    'Simians'
  end
    
  def Samples.service_RNC
    return <<END_OF_SERVICE_SCHEMA
# -*- rnc -*-
# RELAX NG Compact Syntax Grammar for the Atom Protocol

namespace app = "http://www.w3.org/2007/app"
namespace atom = "http://www.w3.org/2005/Atom"
namespace xsd = "http://www.w3.org/2001/XMLSchema"
namespace xhtml = "http://www.w3.org/1999/xhtml"
namespace local = ""

start = appService

# common:attrs

atomURI = text

appCommonAttributes =
   attribute xml:base { atomURI }?,
   attribute xml:lang { atomLanguageTag  }?,
   attribute xml:space {"default"|"preserved"}?,
   undefinedAttribute*


atomCommonAttributes = appCommonAttributes

undefinedAttribute =
  attribute * - (xml:base | xml:space  | xml:lang | local:*) { text }

atomLanguageTag = xsd:string {
   pattern = "([A-Za-z]{1,8}(-[A-Za-z0-9]{1,8})*)?"
}

atomDateConstruct =
    appCommonAttributes,
    xsd:dateTime

# app:service

appService =
   element app:service {
      appCommonAttributes,
      ( appWorkspace+
        & extensionElement* )
   }

# app:workspace

appWorkspace =
   element app:workspace {
      appCommonAttributes,
      ( atomTitle
        & appCollection*
        & extensionSansTitleElement* )
   }

atomTitle = element atom:title { atomTextConstruct }

# app:collection

appCollection =
   element app:collection {
      appCommonAttributes,
      attribute href { atomURI  },
      ( atomTitle
        & appAccept*
        & appCategories*
        & extensionSansTitleElement* )
   }

# app:categories

atomCategory =
    element atom:category {
       atomCommonAttributes,
       attribute term { text },
       attribute scheme { atomURI }?,
       attribute label { text }?,
       undefinedContent
    }

appInlineCategories =
    element app:categories {
        attribute fixed { "yes" | "no" }?,
        attribute scheme { atomURI }?,
        (atomCategory*,
        undefinedContent)
    }

appOutOfLineCategories =
    element app:categories {
        attribute href { atomURI },
        undefinedContent
    }

appCategories = appInlineCategories | appOutOfLineCategories


# app:accept

appAccept =
   element app:accept {
         appCommonAttributes,
         ( text? )
   }

# Simple Extension

simpleSansTitleExtensionElement =
   element * - (app:*|atom:title) {
      text
   }

simpleExtensionElement =
   element * - (app:*) {
      text
   }


# Structured Extension

structuredSansTitleExtensionElement =
   element * - (app:*|atom:title) {
      (attribute * { text }+,
         (text|anyElement)*)
    | (attribute * { text }*,
       (text?, anyElement+, (text|anyElement)*))
   }

structuredExtensionElement =
   element * - (app:*) {
      (attribute * { text }+,
         (text|anyElement)*)
    | (attribute * { text }*,
       (text?, anyElement+, (text|anyElement)*))
   }

# Other Extensibility

extensionSansTitleElement =
 simpleSansTitleExtensionElement|structuredSansTitleExtensionElement


extensionElement =
   simpleExtensionElement | structuredExtensionElement

undefinedContent = (text|anyForeignElement)*

# Extensions

anyElement =
   element * {
      (attribute * { text }
       | text
       | anyElement)*
   }

anyForeignElement =
    element * - app:* {
       (attribute * { text }
        | text
        | anyElement)*
    }

atomPlainTextConstruct =
    atomCommonAttributes,
    attribute type { "text" | "html" }?,
    text

atomXHTMLTextConstruct =
    atomCommonAttributes,
    attribute type { "xhtml" },
    xhtmlDiv

atomTextConstruct = atomPlainTextConstruct | atomXHTMLTextConstruct

anyXHTML = element xhtml:* {
    (attribute * { text }
     | text
     | anyXHTML)*
}

xhtmlDiv = element xhtml:div {
  (attribute * { text }
   | text
   | anyXHTML)*
}

# EOF

END_OF_SERVICE_SCHEMA
  end
  
  def Samples.categories_RNC
    return <<END_OF_CATEGORIES_SCHEMA
# -*- rnc -*-
# RELAX NG Compact Syntax Grammar for the Atom Protocol

namespace app = "http://www.w3.org/2007/app"
namespace atom = "http://www.w3.org/2005/Atom"
namespace xsd = "http://www.w3.org/2001/XMLSchema"
namespace local = ""

start = appCategories

atomCommonAttributes =
   attribute xml:base { atomURI }?,
   attribute xml:lang { atomLanguageTag }?,
   undefinedAttribute*

undefinedAttribute =
  attribute * - (xml:base | xml:lang | local:*) { text }

atomURI = text

atomLanguageTag = xsd:string {
   pattern = "[A-Za-z]{1,8}(-[A-Za-z0-9]{1,8})*"
}


atomCategory =
    element atom:category {
       atomCommonAttributes,
       attribute term { text },
       attribute scheme { atomURI }?,
       attribute label { text }?,
       undefinedContent
    }

appInlineCategories =
    element app:categories {
        attribute fixed { "yes" | "no" }?,
        attribute scheme { atomURI }?,
        (atomCategory*)
    }

appOutOfLineCategories =
    element app:categories {
        attribute href { atomURI },
        (empty)
    }

appCategories = appInlineCategories | appOutOfLineCategories


# Extensibility

undefinedContent = (text|anyForeignElement)*

anyElement =
   element * {
      (attribute * { text }
       | text
       | anyElement)*
   }

anyForeignElement =
    element * - atom:* {
       (attribute * { text }
        | text
        | anyElement)*
    }

# EOF
END_OF_CATEGORIES_SCHEMA
  end

  def Samples.atom_RNC
    return <<END_OF_ATOM_SCHEMA
# -*- rnc -*-
# RELAX NG Compact Syntax Grammar for the
# Atom Format Specification Version 11

namespace atom = "http://www.w3.org/2005/Atom"
namespace xhtml = "http://www.w3.org/1999/xhtml"
namespace s = "http://www.ascc.net/xml/schematron"
namespace local = ""

start = atomFeed | atomEntry

# Common attributes

atomCommonAttributes =
   attribute xml:base { atomUri }?,
   attribute xml:lang { atomLanguageTag }?,
   undefinedAttribute*

# Text Constructs

atomPlainTextConstruct =
   atomCommonAttributes,
   attribute type { "text" | "html" }?,
   text

atomXHTMLTextConstruct =
   atomCommonAttributes,
   attribute type { "xhtml" },
   xhtmlDiv

atomTextConstruct = atomPlainTextConstruct | atomXHTMLTextConstruct

# Person Construct

atomPersonConstruct =
   atomCommonAttributes,
   (element atom:name { text }
    & element atom:uri { atomUri }?
    & element atom:email { atomEmailAddress }?
    & extensionElement*)

# Date Construct

atomDateConstruct =
   atomCommonAttributes,
   xsd:dateTime

# atom:feed

atomFeed =
   [
      s:rule [
         context = "atom:feed"
         s:assert [
            test = "atom:author or not(atom:entry[not(atom:author)])"
            "An atom:feed must have an atom:author unless all "
            ~ "of its atom:entry children have an atom:author."
         ]
      ]
   ]
   element atom:feed {
      atomCommonAttributes,
      (atomAuthor*
       & atomCategory*
       & atomContributor*
       & atomGenerator?
       & atomIcon?
       & atomId
       & atomLink*
       & atomLogo?
       & atomRights?
       & atomSubtitle?
       & atomTitle
       & atomUpdated
       & extensionElement*),
      atomEntry*
   }

# atom:entry

atomEntry =
   [
      s:rule [
         context = "atom:entry"
         s:assert [
            test = "atom:link[@rel='alternate'] "
            ~ "or atom:link[not(@rel)] "
            ~ "or atom:content"
            "An atom:entry must have at least one atom:link element "
            ~ "with a rel attribute of 'alternate' "
            ~ "or an atom:content."
         ]
      ]
      s:rule [
         context = "atom:entry"
         s:assert [
            test = "atom:author or "
            ~ "../atom:author or atom:source/atom:author"
            "An atom:entry must have an atom:author "
            ~ "if its feed does not."
         ]
      ]
   ]
   element atom:entry {
      atomCommonAttributes,
      (atomAuthor*
       & atomCategory*
       & atomContent?
       & atomContributor*
       & atomId
       & atomLink*
       & atomPublished?
       & atomRights?
       & atomSource?
       & atomSummary?
       & atomTitle
       & atomUpdated
       & extensionElement*)
   }

# atom:content

atomInlineTextContent =
   element atom:content {
      atomCommonAttributes,
      attribute type { "text" | "html" }?,
      (text)*
   }

atomInlineXHTMLContent =
   element atom:content {
      atomCommonAttributes,
      attribute type { "xhtml" },
      xhtmlDiv
   }

atomInlineOtherContent =
   element atom:content {
      atomCommonAttributes,
      attribute type { atomMediaType }?,
      (text|anyElement)*
   }

atomOutOfLineContent =
   element atom:content {
      atomCommonAttributes,
      attribute type { atomMediaType }?,
      attribute src { atomUri },
      empty
   }

atomContent = atomInlineTextContent
 | atomInlineXHTMLContent
 | atomInlineOtherContent
 | atomOutOfLineContent

# atom:author

atomAuthor = element atom:author { atomPersonConstruct }

# atom:category

atomCategory =
   element atom:category {
      atomCommonAttributes,
      attribute term { text },
      attribute scheme { atomUri }?,
      attribute label { text }?,
      undefinedContent
   }

# atom:contributor

atomContributor = element atom:contributor { atomPersonConstruct }

# atom:generator

atomGenerator = element atom:generator {
   atomCommonAttributes,
   attribute uri { atomUri }?,
   attribute version { text }?,
   text
}

# atom:icon

atomIcon = element atom:icon {
   atomCommonAttributes,
   (atomUri)
}

# atom:id

atomId = element atom:id {
   atomCommonAttributes,
   (atomUri)
}

# atom:logo

atomLogo = element atom:logo {
   atomCommonAttributes,
   (atomUri)
}

# atom:link

atomLink =
   element atom:link {
      atomCommonAttributes,
      attribute href { atomUri },
      attribute rel { atomNCName | atomUri }?,
      attribute type { atomMediaType }?,
      attribute hreflang { atomLanguageTag }?,
      attribute title { text }?,
      attribute length { text }?,
      undefinedContent
   }

# atom:published

atomPublished = element atom:published { atomDateConstruct }

# atom:rights

atomRights = element atom:rights { atomTextConstruct }

# atom:source

atomSource =
   element atom:source {
      atomCommonAttributes,
      (atomAuthor*
       & atomCategory*
       & atomContributor*
       & atomGenerator?
       & atomIcon?
       & atomId?
       & atomLink*
       & atomLogo?
       & atomRights?
       & atomSubtitle?
       & atomTitle?
       & atomUpdated?
       & extensionElement*)
   }

# atom:subtitle

atomSubtitle = element atom:subtitle { atomTextConstruct }

# atom:summary

atomSummary = element atom:summary { atomTextConstruct }

# atom:title

atomTitle = element atom:title { atomTextConstruct }

# atom:updated

atomUpdated = element atom:updated { atomDateConstruct }

# Low-level simple types

atomNCName = xsd:string { minLength = "1" pattern = "[^:]*" }

# Whatever a media type is, it contains at least one slash
atomMediaType = xsd:string { pattern = ".+/.+" }

# As defined in RFC 3066
atomLanguageTag = xsd:string {
   pattern = "[A-Za-z]{1,8}(-[A-Za-z0-9]{1,8})*"
}

# Unconstrained; it's not entirely clear how IRI fit into
# xsd:anyURI so let's not try to constrain it here
atomUri = text

# Whatever an email address is, it contains at least one @
atomEmailAddress = xsd:string { pattern = ".+@.+" }

# Simple Extension

simpleExtensionElement =
   element * - atom:* {
      text
   }

# Structured Extension

structuredExtensionElement =
   element * - atom:* {
      (attribute * { text }+,
         (text|anyElement)*)
    | (attribute * { text }*,
       (text?, anyElement+, (text|anyElement)*))
   }

# Other Extensibility

extensionElement =
   simpleExtensionElement | structuredExtensionElement

undefinedAttribute =
  attribute * - (xml:base | xml:lang | local:*) { text }

undefinedContent = (text|anyForeignElement)*

anyElement =
   element * {
      (attribute * { text }
       | text
       | anyElement)*
   }

anyForeignElement =
   element * - atom:* {
      (attribute * { text }
       | text
       | anyElement)*
   }

# XHTML

anyXHTML = element xhtml:* {
   (attribute * { text }
    | text
    | anyXHTML)*
}

xhtmlDiv = element xhtml:div {
   (attribute * { text }
    | text
    | anyXHTML)*
}

# EOF
END_OF_ATOM_SCHEMA

  end

  def Samples.make_id
    id = ''
    5.times { id += rand(1000000).to_s }
    "tag:tbray.org,2005:#{id}"
  end 
  
  
  def Samples.mini_entry
    now = DateTime::now
    return <<END_OF_MINI_ENTRY
<entry xmlns="http://www.w3.org/2005/Atom">
  <title>Entry Mini-1</title>
  <author><name>EM</name></author>
  <id>#{make_id}</id>
  <updated>#{now.strftime("%Y-%m-%dT%H:%M:%S%z").sub /(..)$/, ':\1'}</updated>
  <content>Content of Mini-1</content>
</entry>
END_OF_MINI_ENTRY
  end

  def Samples.basic_entry
    e = '<entry xmlns="http://www.w3.org/2005/Atom">' + "\n"
    e += ' <title>' + Escaper.escape('From the <APE> (サル)') + "</title>\n"
    e += " <author><name>The Atom Protocol Exerciser</name></author>\n"
    now = DateTime::now
    e += " <id>#{make_id}</id>\n"
    updated = now.strftime("%Y-%m-%dT%H:%M:%S%z").sub /(..)$/, ':\1'
    e += " <updated>#{updated}</updated>\n"
    summary = "Summary from the <APE> at #{updated}"
    e += " <link href='http://www.tbray.org/ape'/>"
    e += " <summary type='html'>" + Escaper.escape(Escaper.escape(summary)) +
      "</summary>\n"
    e += " <content type='xhtml'><div xmlns='http://www.w3.org/1999/xhtml'>" +
      "<p>A test post from the &lt;APE&gt; at #{updated}</p>" +
      "<p>If you see this in an entry, it's probably a left-over from an " +
      "unsuccessful Ape run; feel free to delete it.</p>" +
      "</div></content>\n"
    
    e += " <dc:subject xmlns:dc='#{Names::DcNamespace}'>Simians</dc:subject>\n"
    e += "</entry>\n"
    return e
  end

  def Samples.cat_test_entry
    e = retitled_entry('Testing category posting')
  end

  def Samples.retitled_entry(new_title, new_id = nil)
    e = basic_entry
    e.gsub!(/<title>.*<\/title>/, "<title>#{new_title}</title>")
    new_id = make_id unless new_id
    e.gsub(/<id>.*<\/id>/, "<id>#{new_id}</id>")
  end

  def Samples.picture
    b64 =<<END_OF_PICTURE
    /9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQE
    BQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/
    2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQU
    FBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAA8AEYDASIAAhEBAxEB/8QA
    HwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUF
    BAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkK
    FhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1
    dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXG
    x8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEB
    AQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAEC
    AxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRom
    JygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOE
    hYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU
    1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD5fgS0knaT
    7C4UddzHINab3lrboz/2ezop5LAnj3qtbK1xJbwbcZYZwc4GeprpZLNZY5Tu
    Ai8skhjgHk5FfJNtWVm/m/8Agn7M6dOGzSdvzdvKxl2VzaAec2n7uMqDnBHr
    W1FPEY7YDTrVYXUNl5fw/wAf0qjps0NzbCEMUZMBhnJz9PwqzZbISIpQj27s
    A+4ZK99w/wAKycU229fm/wDM9aVDlhF09uv9eRrG6jmgeGLTrR2kPG2T5uMe
    /wDnNcnrGuxpdGMWCM4cR7V+bkehzXSatJBo4S3sZFkmkQ75x0QZ7H1965z7
    MjIxDsAEJyTkgY5b9KjlitV+N/yuXSoyrO/T835FKe/Ms8khsMFRtIwR2780
    77bGqQObHZORwgz8wHGRz6/yqOxkZmnO1isjYXeMZB4yPyqvrSJa30DF2bdu
    4TtycZq7Nbp2stdTgapyqciaerTXp899uhFc6qLmQg23X5iTxz9aKZes0RRX
    yxA+7n9aK6YcvKrq/wAzkr4W1R8rsu1rnSWD2UcLPIgE3BIDHJPt7ZqBXmiv
    ZnuSTaMCpUAHy89P8j1pdKtGe7jllI+i84H9TW7JIt/PLYCGREyfKbachu5P
    P/6q578rf3/1/X/B6mkopTV2/wAv6X4fNRp4ZitLQXsLZlUL8p5LAjg/XFVz
    fRKky+YMbCd7L19himadPLat9lD5jALKqtyuPT2961bfT4LlELQA+ZuyVXJz
    nrWMlKKbk9j0KOIVLlp2321f/D9bmH9uihxNJgKNqnjJxjJx+NFuh1RONjRE
    gkgYIHOFH+eK0tV0m3adDFEjgEbuM5yAc5z+lVpA+nRGOMrGGOPNPAXHO0de
    abkqvNKP9alLETgoULJfPy+X6kGqWovJRaQqqxx4DzoM9Ow9ag8iNmeN4wXG
    V3tgluevsa0WlSw0uS5hj82RW2kOp2ITzuPHX6etQ3CJcWkdyymJpGLbTxsI
    /iXjp9aiOiv8vnv+Wv8AWtT9m6iw6Wq6+d7Wt2vp6+W3NyqtlIEm6c7XKZ9O
    MGirjz/aUDOFkOfvOOG9+aK9OnhnUipXt8m/0PCq5p7Cbpyim115kv1ROzSy
    SR3UK5jx8yg8tzXW3Gtw3Gm26QQBbtkCO6DmQjp2yP61yGk34SQIGco5ypHY
    9s1q2MS2l1LdKCNg3le3ORj8a5uTbmt5f1/XT5ae1UVZpvr3/r0/4ZpNp76X
    Os2AZW6KTgZJ6Y9OKgOszpAyu6IEPAKA5IPT2qxFeG/Xz5mbzpAQikFsL6/l
    WXcp5832e2KuZPmKsCNo9/50KN07nalCmvaTev8AwxqrqNxe2kzI0RkGAFMa
    7j1PXHHpVqKZLm3WK+aOUld5IbAb6+9Zl5af2WqnzQ1lN0lQcbsY4PXr61Qa
    5JixvIJbCgDGCO9KUFq1szWm4VaSS0kvw/H8jcivItPlSDasqEfJuAAYd1PH
    A9aoavOt3O4wTC5y74+97cDoMdRUEc39p2brONoiOHOcYb1pmrShII7W2Oc8
    LzyB2rPka1fb+v8AP8fSXiVN8qXv7X8lv/lfsmvWhqBF5MiWsqQhF+ZiePoK
    KpzfuI1C/OqkqV2d/WiuqMqkFaLsjklh8K3erFN9/wCmSaNqBSPdNE5KkMML
    1561tJrqSSylbaQh49oXgdjyea5S21W5ReJPb8KvW2sXQlzvByhPI+tdUqDb
    TaX3v/I+bjjHy2v+C/UmfWjazbYopHToQeorSj1WGGzkRSwuZT+8kdSSB/d6
    dKw/t0skr7tp2kAfKKsapqs4kiAKjChshRnOBS9k7ar8f+AavFyqa30Xl/wT
    RjvtkDW8zs9q+NyMh+96ism4umR9kSSSgEqrn+Jc/pSf23ds0zFwdvIBUYzV
    aLU55DG5Khj3CipdKTbdlr5/8A1hifZ2af8AX3luDUC0dxCySoJG3byBj8fy
    qG71KW4nSRomwq7CV4OO2KonVLgblDAAcDAqAanO8+0kADngURoXbdvxZM8Y
    001+n/Dk41B8ZaFmx8oyx6UVVn1m5jRCGXOMfdorRU2lqvx/4BhPFzlK6lb5
    I//Z
END_OF_PICTURE
    Base64.decode64(b64)
  end

end
