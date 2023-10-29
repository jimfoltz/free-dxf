#require "fileutils"
require "find"

module JF
    module FreeDXF
        module Teigha

            # Teigha Command Line Format is:
            #   Quoted Input Folder
            #   Quoted Output Folder
            #   Output_version ["ACAD9","ACAD10","ACAD12", "ACAD13","ACAD14", "ACAD2000","ACAD2004", "ACAD2007","ACAD2010"]
            #   Output File type {"DWG","DXF","DXB"}
            #   Recurse Input Folder {"0","1"}
            #   Audit each file {"0","1"}
            #   [optional] Input file filter (default:"*.DWG;*.DXF") (Use File.basename(filename))

           OPTIONS = {
              :output_version => "ACAD10"
           }
           OUTPUT_TYPE    = "DXF"
           RECURSE        = "0"
           AUDIT          = "0"

            def self.path
                teigha = Sketchup.read_default("JF\\FreeDXF-#{VERSION}", "Teigha", "")
                if ! File.exists?(teigha)
                   teigha = find_teigha
                   Sketchup.write_default("JF\\FreeDXF-#{VERSION}", "Teigha", teigha) if teigha
                end
                teigha
            end

            # Find Teigha .exe on Windows
            def self.find_teigha
               teigha = nil
               if File.exists?("/Applications/TeighaFileConverter.app/Contents/MacOS/TeighaFileConverter")
                  teihga = "/Applications/TeighaFileConverter.app/Contents/MacOS/TeighaFileConverter"
               else
                  program_folders = ["C:/Users/Jim/Apps/Teigha", "C:/Program Files/ODA", "C:/Program Files (x86)/ODA"]
                  program_folders.each {|folder|
                     next unless File.exists?(folder)
                     Find.find(folder) { |path|
                        if path[/teighafileconverter.exe/i]
                           teigha = path
                           break
                        end
                     }
                     break if teigha
                  }
               end
               teigha
            end

            def self.available?
                if path()
                    true
                else
                    false
                end
            end

            def self.dialog
               res = UI.inputbox(["ACAD Version"],
                           ["ACAD10"],
                           ['ACAD9|ACAD10|ACAD12|ACAD13|ACAD14|ACAD2000|ACAD2004|ACAD2007|ACAD2010'],
                          'Teigha Output Version'
                          )
               if res
                  OPTIONS[:output_version] = res[0]
               end
            end

            def self.convert(dwg_file)

                dwg_dir = File.dirname(dwg_file)

                teigha = path()

                # Create a temporary folder to store the dxf file
                dxf_dir = Sketchup.temp_dir + "/FreeDXF"
                unless File.directory?(dxf_dir)
                    Dir.mkdir(dxf_dir)
                end

                dxf_file = dxf_dir + "/" + File.basename(dwg_file, ".dwg") + ".dxf"

                res = %x("#{teigha}" "#{dwg_dir}" "#{dxf_dir}" "#{OPTIONS[:output_version]}" "#{OUTPUT_TYPE}" "#{RECURSE}" "#{AUDIT}" "#{File.basename(dwg_file)}")
                p $?
                p res unless res.empty?

                if File.exists?(dxf_file)
                    return dxf_file
                else
                    return nil
                end

            end # convert

        end # module TeighaFileConverter

    end # module FreeCAD

end # module JF
