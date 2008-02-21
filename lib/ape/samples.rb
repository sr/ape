#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"
require 'rexml/xpath'
require 'date'
require 'base64'
require 'erubis'

module Ape
  class Samples
    
     @@service_schema = nil
     @@categories_schema = nil
     @@atom_schema = nil
     @@home = nil
     
     def Samples.home=(home)
       @@home = home
     end

    def Samples.foreign_child
      'subject'
    end
    def Samples.foreign_namespace
      Names::DcNamespace
    end
    def Samples.foreign_child_content
      'Simians'
    end
    
    def Samples.load_schema(file_name)
      schema = ""
      File.open(File.join(File.dirname(__FILE__), "/samples/#{file_name}_schema.txt")) do |file|
        while(line = file.gets)
          schema << line
        end
      end
      schema
    end
      
    def Samples.service_RNC
      @@service_schema = load_schema('service') unless @@service_schema
      @@service_schema
    end
  
  def Samples.categories_RNC
    @@categories_schema = load_schema('categories') unless @@categories_schema
    @@categories_schema
  end

  def Samples.atom_RNC
    @@atom_schema = load_schema('atom') unless @@atom_schema
    @@atom_schema
  end

  #recipe from cap
  def Samples.home_directory
      ENV["HOME"] || (ENV["HOMEPATH"] && "#{ENV["HOMEDRIVE"]}#{ENV["HOMEPATH"]}") ||
          "/"
  end
  
  def Samples.home
    @@home || ENV["APE_HOME"] || File.join(home_directory,".ape")
  end
  
    def Samples.make_id
      id = ''
      5.times { id += rand(1000000).to_s }
      "tag:tbray.org,2005:#{id}"
    end
    
    def Samples.entry_path(type)
      File.exist?(File.join(home, "/#{type}.eruby"))?
        File.join(home, "/#{type}.eruby") :
        File.join(File.dirname(__FILE__), "/samples/#{type}.eruby")
    end
    
    def Samples.load_template(type)
      entry_path = entry_path(type)
      input = File.read(entry_path)
      eruby = Erubis::Eruby.new(input)
    end
    
    
    def Samples.mini_entry
      eruby = load_template('mini_entry')
      
      now = DateTime::now.strftime("%Y-%m-%dT%H:%M:%S%z").sub(/(..)$/, ':\1')
      id = make_id
      
      eruby.result(binding())
    end

    def Samples.basic_entry
      eruby = load_template('basic_entry')
      
      id = make_id
      now = DateTime::now.strftime("%Y-%m-%dT%H:%M:%S%z").sub(/(..)$/, ':\1')
      title = Escaper.escape('From the <APE> (サル)')
      summary = "Summary from the &lt;b>&amp;lt;&amp;nbsp;APE&amp;nbsp;>&lt;/b> at #{now}"
      subject = Names::DcNamespace
      
      eruby.result(binding())
    end
    
    def Samples.unclean_xhtml_entry
      eruby = load_template('unclean_xhtml_entry')
      
      id = make_id
      now = DateTime::now.strftime("%Y-%m-%dT%H:%M:%S%z").sub(/(..)$/, ':\1')
      
      eruby.result(binding())
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
end
