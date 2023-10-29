# dxf2ruby.rb - (C) 2011 jim.foltz@gmail.com

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

# About DXF (Nots from AutoCAD)
#
# DXF _Objects_ have no graphical representation. (aka nongraphical objects)
# DXF _Entities_ are graphical objects.

# Accommodating DXF files from future releases of AutoCAD® will be easier
# if you write your DXF processing program in a table-driven way, ignore
# undefined group codes, and make no assumptions about the order of group codes
# in an entity. With each new AutoCAD release, new group codes will be added to
# entities to accommodate additional features.

# My Namespace
module JF
  module Dxf2Ruby

    # Acad Versons
    ACAD_VERSION = {
      'AC1006' => 'R10'          ,
      'AC1009' => 'R11 and R12'  ,
      'AC1012' => 'R13'          ,
      'AC1014' => 'R14'          ,
      'AC1015' => 'AutoCAD 2000' ,
      'AC1018' => 'AutoCAD 2004' ,
      'AC1021' => 'AutoCAD 2007' ,
      'AC1024' => 'AutoCAD 2010'
    }

    # Public: Main Loop
    #
    # filename - the name of the file
    #
    # Returns the dxf object
    def self.parse(filename)
      if RUBY_VERSION == '2.0.0'
        read_flag = 'r:Windows-1252:UTF-8'
      else
        read_flag = 'r'
      end
      @fdxf_id = 0
      fp       = File.open(filename, read_flag)
      dxf      = {'HEADER' => {}, 'TABLES' => {}, 'BLOCKS' => [], 'ENTITIES' => []}

      while true
        c, v = read_codes(fp)
        break if v == "EOF"

        if v == "SECTION"
          c, v = read_codes(fp)
          #next if c == 999

          if v == "HEADER"
            hdr = dxf['HEADER']
            while true
              c, v = read_codes(fp)
              break if v == "EOF"
              #next if c == 999
              break if v == "ENDSEC" # or v == "BLOCKS" or v == "ENTITIES" or v == "EOF"
              if c == 9
                key = v
                hdr[key] = {}
              else
                add_att(hdr[key], c, v)
              end
            end # while
          end # if HEADER

          if v == "BLOCKS"
            blks = dxf[v]
            parse_entities(blks, fp)
          end # BLOCKS Section

          if v == "ENTITIES"
            ents = dxf[v]
            parse_entities(ents, fp)
          end #  ENTITIES section

          if v == "TABLES"
             tbls = dxf[v]
             parse_tables(tbls, fp)
          end

        end # if in SECTION

      end # main loop

      fp.close
      return dxf
    end

    def self.parse_entities(section, fp)
      last_ent = nil
      last_code = nil
      while true
        c, v = read_codes(fp)
        #next if c == 999
        break if v == "ENDSEC" or v == "EOF"
        # LWPOLYLINE bulges (code 42) only exist if not zero. 
        if last_ent == "LWPOLYLINE"
          if c == 10
            section[-1][42] ||= []
            # Create default 42
            add_att(section.last, 42, 0)
          end
          if c == 42
            # update default
            section.last[42][-1] = v
            next
          end
        end
        if c == 0
          section << {c => v}
          last_ent = v.dup
          if $JFDEBUG
            section.last['fid'] = "f#{@fdxf_id}"
            @fdxf_id += 1
          end
        else
          add_att(section.last, c, v)
        end
        last_code = c
      end # while
    end # def self.parse_entities

    # dxf["tables"] = {"VPORT" => [{..}, {..}], "LAYERS" => [{..}, {..}, ..]}
    def self.parse_tables(section, fp)
       table = nil
       row =  {}
       context = nil
       while true
          c, v = read_codes(fp)
          break if v == "ENDSEC" || v == "EOF"
          if c == 0 
             if v == "TABLE"
                c, v = read_codes(fp)
                fail if c != 2
                section[v] = {} 
                entities = section[v][:entities] = []
                header = section[v][:header] = {} 
                context = header
                next
             else
                # New
                entities.push({})
                context = entities[-1]
                next
             end
          else
             add_att(context, c, v)
          end
       end # while

    end

    def self.read_codes_p(fp)
       c, v = read_codes(fp)
       if c == 0
          puts
       end
       print "(#{c} #{v})"
       return( [c, v] )
    end

    def self.read_codes(fp)
      begin
        c = fp.gets
        return [0, "EOF"] if c.nil?
        v = fp.gets
        return [0, "EOF"] if v.nil?
        c = c.to_i
        raise "Comment" if c == 999
        v.strip!
        v.upcase! if c == 0
        case c
        when 10..59, 140..147, 210..239, 1010..1059
          v = v.to_f
        when 60..79, 90..99, 170..175,280..289, 370..379, 380..389,500..409, 1060..1079
          v = v.to_i
        end
      end
      return( [c, v] )
    rescue => ex
      if ex.message == "Comment"
        retry
      else
        fail
      end
    end

    def self.add_att(ent, code, value)
      # Initially, I thought each code mapped to a single value. Turns out
      # a code can be a list of values. 
      if ent.nil? and $JFDEBUG
        p caller
        p code
        p value
      end
      if ent[code].nil?
        ent[code] = value
      elsif ent[code].class == Array
        ent[code] << value
      else
        t = ent[code]
        ent[code] = []
        ent[code] << t
        ent[code] << value
      end
    end


  end # mod Dxf2Ruby
end # mod JF


if $0 == __FILE__
  t1       = Time.now
  lwp      = ARGV.delete('-l')
  extract  = ARGV.delete('-e')
  pretty   = ARGV.delete('-p')
  $JFDEBUG = true if ARGV.delete('-d')
  filename = ARGV.shift
  handle   = ARGV.shift
  puts "Ruby Version: #{RUBY_VERSION}"
  puts "File: #{File.expand_path(filename)}"
  dxf = JF::Dxf2Ruby.parse(filename)
  puts "Finished in #{Time.now - t1}"
  if extract
    print "Handle: "
    handle = $stdin.gets.chomp
    dxf['ENTITIES'].each do |entity|
      if entity[5] == handle
        p entity
      end
    end
  end
  if lwp
    dxf['ENTITIES'].each do |entity|
      if entity[0] == 'LWPOLYLINE'
        puts "#{entity[5]}:#{entity[90]}:#{entity[42].length}"
      end
    end
    exit
  end
  if pretty
    require 'pp'
    s = PP.pp(dxf, "")
  else
    s = ""
    dxf.each do |sec, list|
      s << sec.to_s << "\n"
      list.each { |line| s << line.to_s << "\n" }
    end
  end
  cmd = "less -S"
  IO.popen(cmd, 'w') { |f| f.puts(s) }
end
