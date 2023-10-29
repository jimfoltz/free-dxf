# Copyright 2011 jim.foltz@gmail.com

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


#load File.dirname(__FILE__) + '/inputbox.rb'
load(File.dirname(__FILE__) + "/dxf2ruby.rb")
load(File.dirname(__FILE__) + "/bezier.rb") unless defined?(Bezier)
#load(File.dirname(__FILE__) + "/teigha.rb") unless defined?(JF::FreeDXF::Teigha)



module JF
    module FreeDXF

        DEBUG = ENV['JFDEBUG'] == "ON"

        LengthUnits = {
            0 => 'Inches',
            1 => 'Feet',
            2 => 'Millimeters',
            3 => 'Centimeters',
            4 => 'Meters'
        }

        OPTIONS = {
            :import_units => 'Inches',
            :circle_segments => 24
        }

        def self.lv(&block)
            puts "local_variables:"
            foo = yield if block_given?
            foo.each {|v| puts "#{v} = #{eval(v.to_s, block.binding).inspect}"}
        end

        def self.debug_out(*message)
            puts "=" * 42
            message.each {|m| puts m}
        end

        # reset Inputbox
        def self.reset
            @ib = nil
        end

        def self.model_units
            LengthUnits[ Sketchup.active_model.options["UnitsOptions"]["LengthUnit"] ]
        end

        def self.do_options2(filepath)
            inputs = []
            inputs << ["Scale"    , model_units() , LengthUnits.values.join("|")]
            inputs << ["Segments" , 24            , nil]
            inputs = inputs.transpose
            #p inputs
            ans = UI.inputbox(inputs[0], inputs[1], "FreeDXF #{VERSION}")
            OPTIONS[:import_units] = ans[0]
            OPTIONS[:circle_segments] = ans[1]
            @opts = {}
            #@opts[:arc_segments]    = 12
            #@opts[:circle_segments] = 24
            @opts[:layers]          = 'Dxf Layers'
            @opts[:text]            = true
            @opts[:screen_text]     = false
            @opts[:mtext]           = true
            @opts[:dims]            = true
            @opts[:font_quality] = 1.0 # 0.0 is best
            @opts[:tags] = true if DEBUG
            do_import(filepath)
        end

        def self.do_options(filepath)

            wwidth = 300
            window_options = {
                :title           => "FreeDXF #{VERSION}",
                :preferences_key => 'JF\FreeDXF',
                :width => wwidth,
                :height => 250
            }
            window = SKUI::Window.new(window_options)

            grp_scale = SKUI::Groupbox.new("Scale")

            grp_scale.top    = 5
            grp_scale.left   = 5
            grp_scale.right  = 5
            grp_scale.height = 72
            window.add_control(grp_scale)

            lbl_units = SKUI::Label.new("Units:")
            lbl_units.top  = 20
            lbl_units.right = wwidth / 2.0
            grp_scale.add_control(lbl_units)

            lst_units = SKUI::Listbox.new(LengthUnits.values)
            lst_units.name = :import_units
            lst_units.left  = wwidth / 2.0
            lst_units.value = model_units()
            grp_scale.add_control(lst_units)

            # GEOM
            grpGeom = SKUI::Groupbox.new("Geometry")
            grpGeom.top = 65
            grpGeom.left = 5
            grpGeom.right = 5
            grpGeom.height = 72
            window.add_control(grpGeom)
            # Circle Segments
            lblCircleSegments = SKUI::Label.new("Circle Segments:")
            lblCircleSegments.top = grpGeom.top + 25
            lblCircleSegments.right = wwidth / 2.0
            window.add_control(lblCircleSegments)
            txtCircleSegments = SKUI::Textbox.new(24)
            txtCircleSegments.name = :circle_segments
            txtCircleSegments.size(50, 25)
            txtCircleSegments.top = lblCircleSegments.top - 5
            txtCircleSegments.left = wwidth / 2.0
            window.add_control(txtCircleSegments)

            # Import
            btnImport = SKUI::Button.new('Import') { |control| 
                OPTIONS[:import_units] = control.window[:import_units].value
                OPTIONS[:circle_segments] = control.window[:circle_segments].value.to_i
                do_import(filepath, control.window)
            }
            btnImport.name = :export
            btnImport.bottom = 5
            btnImport.left = 5
            window.add_control(btnImport)

            # CANCEL
            b = SKUI::Button.new('Cancel') { |control|
                control.window.close
            }
            b.bottom = 5; b.right = 5
            window.add_control(b)

            window.show
            #if not @ib.nil?
            #  @ib.load
            #  @opts[:arc_segments]    = @ib[0].to_i
            #  @opts[:circle_segments] = @ib[1].to_i
            #else
            #@ib = Inputbox.new("FreeDXF Options", {:use_keys=>true})
            #@ib.add "Arc Segments", 12
            #@ib.add "Circle Segments", 24
            #@ib.add "Layers", ["Dxf Layers", "Layer0", "by Dxf Type"]
            #@ib.add "Import Text?", ["Yes", "No"]
            #@ib.add "Screen Text?", ["Yes", "No"], "No"
            #@ib.add "Import MText?", ["Yes", "No"]
            #@ib.add "Dims?", ["Yes", "No"]
            #if $JFDEBUG
            #  @ib.add "Debug Tags?", ["No", "Yes"], 'Yes'
            #end
            ##end
            #opts = @ib.show
            #return opts if opts == false
            #@ib.save
            @opts = {}
            @opts[:arc_segments]    = 12
            @opts[:circle_segments] = 24
            @opts[:layers]          = 'Dxf Layers'
            @opts[:text]            = true
            @opts[:screen_text]     = false
            @opts[:mtext]           = true
            @opts[:dims]            = true
            @opts[:font_quality] = 1.0 # 0.0 is best
            @opts[:tags] = true if DEBUG
            #if $JFDEBUG
            #  @opts[:tags] = (opts[7] == "Yes" ? true : false)
            #end
            #puts "Options: #{ @opts.inspect }" if $JFDEBUG
            window
        end

        def self.arc_segments(l)
            segs = l.radians * OPTIONS[:circle_segments] / 360.0
            segs = segs < 2 ? 2 : segs.to_i
        end

        def self.select_file(extra_extensions = "")
            title     = "FreeDXF #{VERSION} Select DXF File"
            directory = nil
            # filename  = 'DXF|*.dxf|DWG|*.dwg||'
            filenames = "Cad Files|*.dxf" + extra_extensions + "||"
            if Sketchup.version.to_i <= 8
            filenames = '*.dxf'
            end
            file_path = UI.openpanel(title, directory, filenames)
            if file_path.nil?
                return nil
            else
                file_path.tr!('\\', '/')
                @last_selected_file = file_path
                return file_path
            end
        end

        def self.main

            puts "\nFreeDXF debugging ON." if DEBUG

            extra_extensions = ""#Teigha.available? ? ";*.dwg" : ""

            file_path = select_file(extra_extensions)

            return if file_path.nil?

            #file_path.downcase!

            if file_path[-1,4] == ".dwg"
                Teigha.dialog()
                file_path = Teigha.convert(file_path)
                if file_path.nil?
                    puts "dxf file was not created."
                    return
                end
            end

            do_options2(file_path)

        end # main

        
        def self.do_import(file_path, window = nil)
            @fdxf_id = 0
            t0 = Time.now
            import(file_path)
            unless @top_group.deleted?
                # set_view(:top)
                #Sketchup.active_model.active_view.zoom @top_group 
            end
            puts "FreeDXF Import time: #{Time.now - t0}" if DEBUG
            window.close if window
        end

        def self.set_view(direction)
            cam = Sketchup.active_model.active_view.camera
            case direction
            when :top
                cam.set([0, 0, 10], ORIGIN, Y_AXIS)
            end
        end

        def self.import(file_path)
            @layer_entities  = {}
            @top_group       = Sketchup.active_model.entities.add_group
            #@top_group.entities.add_cpoint(ORIGIN)
            @top_group.name  = File.basename(file_path)
            @parent_entities = Sketchup.active_model
            @top_entities    = @top_group.entities
            @entities        = @top_entities
            @scale           = 1.0
            @known_types     = Hash.new{0}
            @unknown_types   = Hash.new{0}
            @verts           = []

            start_time = Time.now
            Sketchup.active_model.start_operation("FreeDXF", true)
            Sketchup.status_text = "Parsing #{File.basename(file_path)}"
            dxf = Dxf2Ruby.parse(file_path)

            for e in dxf['BLOCKS']
                if e[0] == "BLOCK"
                    @base = ORIGIN - Geom::Point3d.new(e[10] || 0, e[20] || 0, e.fetch(30, 0))
                    name       = e[2].nil? ? e[5] : e[2]
                    uniq_name  = Sketchup.active_model.definitions.unique_name(name)
                    definition = Sketchup.active_model.definitions.add(uniq_name)
                    @entities  = definition.entities
                    #@entities.add_cpoint(ORIGIN)
                    @in_block  = true
                elsif e[0] == "ENDBLK"
                    @entities.transform_entities(@base, @entities.to_a)
                    @base = nil
                    @in_block = false
                    @entities = @top_entities
                else
                    draw(e)
                end
            end

            for e in dxf['ENTITIES']
                draw(e)
            end

            Sketchup.active_model.active_layer = Sketchup.active_model.layers[0]
            # Scale
            scale =
                case OPTIONS[:import_units]
                when "Inches"
                    1.inch
                when "Feet"
                    1.feet
                when "Millimeters"
                    1.mm
                when "Centimeters"
                    1.cm
                when "Meters"
                    1.m
                end
            #puts "scale = #{scale.inspect} (#{scale.class})"

            tr = Geom::Transformation.scaling(ORIGIN, scale)
            @top_group.transform!(tr) unless scale == 1.0

            # Set Layer Colors
            colors = {}
            IO.foreach(File.dirname(__FILE__) + "/acad_colors.csv") { |line|
               line.strip!
               id, red, green, blue = line.split(',').map{|e| e.to_i}
               id = id.abs
               colors[id] = Sketchup::Color.new(red, green, blue)
            }
            begin
               dxf_layers = dxf['TABLES']['LAYER'][:entities]
               dxf_layers.each {|l|
                  next if l.empty? # FIXME LAYER Table contains an empty Hash at the end
                  name = l[2]
                  color_id = l[62].to_i
                  layer = Sketchup.active_model.layers[name]
                  if layer
                     if color_id < 0
                        layer.visible = false
                     end
                     layer.color = colors[color_id.abs]
                  end
               }
            rescue NoMethodError => e
               warn "No Layers" if DEBUG
            end

            Sketchup.active_model.commit_operation

            # Summary
            if DEBUG
                UI.beep
                puts "Knowns:\n#{ (@known_types.keys - @unknown_types.keys).join("\n") }"
                puts "Unknowns:\n#{  @unknown_types.keys.join("\n") }"  
                puts "Time: #{ Time.now - start_time }"
                puts "=" * 40
            end

            dxf = nil

        end # import

        def self.draw(e)
            # e[67] : model space or paper space
            return unless e.fetch(67, 0) == 0
            @known_types[ e[0] ] += 1
            #set_layer(e)
            case e[0]
            when "POINT"
                draw_point(e)
            when "LINE"
                draw_line(e)
            when "CIRCLE"
                draw_circle(e)
            when "LWPOLYLINE"
                draw_lwpolyline(e)
            when "ARC"
                draw_arc(e)
            when "POLYLINE"
                draw_polyline(e)
            when "SEQEND"
                draw_seqend(e)
            when "VERTEX"
                draw_vertex(e)
            when "SOLID"
                draw_solid(e)
            when "INSERT"
                draw_insert(e)
            when "3DFACE"
                draw_3dface(e)
            when "ELLIPSE"
                draw_ellipse(e)
            when "SPLINE"
                draw_spline(e)
            when "TEXT"
                draw_text(e) if @opts[:text]
            when "MTEXT"
                draw_mtext(e) if @opts[:mtext]
            when "DIMENSION"
                draw_dimension(e) if @opts[:dims]
            else
                @unknown_types[e[0]] += 1
            end
        end

        def self.draw_polyline(e)
            #set_layer :fdxf_polyline
            if e[0] == "POLYLINE"
                if e[70]
                    @closed           = (e[70] &  1) != 0
                    @is_polyface_mesh = (e[70] & 64) != 0
                    @is_polygon_mesh  = (e[70] & 16) != 0
                end
                @polyline               = e
                @verts.clear
                @handle                 = e[5]
                @polyface_mesh_vertices = []
                @polyface_mesh_faces    = []
                @polygon_mesh_vertices  = []
                @in_polyline            = true
            end
        rescue
            debug_out(e)
            fail
        end

        def self.draw_vertex(e)
            if e[70]
                if ( (e[70] & 128) > 0 ) # is polyface mesh vertex
                    if ( ( e[70] & 64) > 0 ) # has vertex coords
                        @polyface_mesh_vertices.push(e)
                    else
                        @polyface_mesh_faces.push(e)
                    end
                    return
                end
                # is 3d polygon mesh
                if ( (e[70] & 64) > 0 )
                    @polygon_mesh_vertices.push(e)
                end
                return
            end
            if @in_polyline
                pos = Geom::Point3d.new(e[10], e[20], e.fetch(30, 0.0))
                @verts << [pos, e[42] ]
            end
        rescue => ex
            lv {local_variables}
            debug_out(e)
            fail
        end

        def self.draw_seqend(e)
            if @is_polyface_mesh
                @is_polyface_mesh = nil
                @in_polyline = false
                draw_polyface_mesh(e)
                return
            end
            if @is_polygon_mesh
                @is_polygon_mesh = nil
                @in_polyline = false
                draw_polygon_mesh(e)
                return
            end
            return unless @in_polyline
            entities = get_entities(@polyline[8])
            @in_polyline = false
            if @verts.length > 0
                @verts.push(@verts[0]) if @closed
                @closed = nil
                lp = nil
                for i in 0..@verts.length-1
                    #puts "vert[#{i}]=#{ @verts[i].inspect }" if $JFDEBUG
                    pos = @verts[i][0]
                    #pos = Geom::Point3d.new(e[10], e[20], e.fetch(30, 0.0))
                    #@entities.add_cpoint(pos)
                    if not lp.nil?
                        b = lp[1] || 0.0
                        if b != 0.0
                            c, radius, x, l = calc_bulge(lp[0], pos, b)
                            #@entities.add_cpoint(c)
                            segs = arc_segments(l)
                            curve = arc = entities.add_arc(c, x, Z_AXIS, radius, 0, l, segs )
                            @entities.add_text(e['fdxf_id'], c) if DEBUG
                            if curve.nil? and DEBUG
                                warn "no arc (b): #{@handle}"
                            end
                        else
                            curve = entities.add_edges(lp[0], pos)
                            if curve.nil? and DEBUG
                                warn "no arc: #{__LINE__} #{@handle} #{lp[0].inspect}, #{pos.inspect}"
                            end
                        end
                    end
                    lp = @verts[i]#.clone
                end
                if @opts[:tags]
                    curve.each {|c| c.set_attribute("FreeDXF", "fid", @polyline['fid'])}#rescue nil
                end
                @verts = []
                @data = []
                @seq = nil
            end
        end

        def self.draw_polyface_mesh(e)
            mesh = Geom::PolygonMesh.new
            positions = @polyface_mesh_vertices.map{|v| Geom::Point3d.new(v[10]||0.0, v[20]||0.0, v[30]||0.0)}
            @polyface_mesh_faces.each_with_index do |v, i|
                begin
                    i_1 = v[71].abs - 1
                    i_2 = v[72].abs - 1
                    i_3 = v[73].abs - 1
                    i_4 = v[74]
                    i_4 = i_4.abs if i_4
                    points = [ positions[i_1], positions[i_2], positions[i_3] ]
                    points.push(positions[i_4 - 1]) if i_4
                    mesh.add_polygon( points )
                    @polyface_mesh_faces = nil
                    @polyface_mesh_vertices = nil
                rescue => ex
                    debug_out(points)
                    fail
                end
            end
            entities = get_entities(@polyline[8])
            @polyline = nil
            faces = entities.add_faces_from_mesh(mesh, 0)
            #faces.each{ |f| f.set_attribute('FreeDXF', 'fid', @polyline['fid']) }
        rescue => ex
            puts "instance_variables:"
            instance_variables.each {|v| puts "#{v} = #{eval(v.to_s).inspect}"}
            p OPTIONS
            lv() {local_variables}
            fail
        end

        def self.draw_polygon_mesh(e)
            m_size = @polyline[71]
            n_size = @polyline[72]
            positions = Array.new
            i = 0
            m_size.times do |m|
                n_size.times do |n|
                    #puts "V#{i}: (#{m}, #{n})"
                    positions[m] ||= []
                    v = @polygon_mesh_vertices[i]
                    i += 1
                    positions[m][n] = Geom::Point3d.new(v[10], v[20], v[30])
                end
            end
            grp = get_entities(@polyline[8]).add_group
            #grp.entities.add_cpoint(ORIGIN)
            if @opts[:tags]
                #grp.set_attribute('FreeDXF', 'handle', @polyline[5])
                grp.set_attribute('FreeDXF', 'fid', @polyline['fid'])
            end
            grp.name = e[330] || "Mesh"
            entities = grp.entities

            for m in 0..m_size - 1
                edges = entities.add_edges(positions[m])
                if @opts[:tags]
                    #edges.each {|edge| edge.set_attribute('FreeDXF', 'handle', e[5])}
                    edges.each {|edge| edge.set_attribute('FreeDXF', 'fid', e['fid'])}
                end
            end
            p2 = positions.transpose
            for n in 0..n_size-1
                edges = entities.add_edges(p2[n])
                if @opts[:tags]
                    #edges.each {|edge| edge.set_attribute('FreeDXF', 'handle', e[5])}
                    edges.each {|edge| edge.set_attribute('FreeDXF', 'fid', e['fid'])}
                end
            end
        end

        def self.draw_line(r)
            #if @opts[:layers] == "by Type"
            #set_layer(:fdxf_line)
            #end
            entities = get_entities(r[8])
            pt1 = Geom::Point3d.new(r[10], r[20], r.fetch(30, 0.0))#].map{|e| @scale * e}
            pt2 = Geom::Point3d.new(r[11], r[21], r.fetch(31, 0.0))#].map{|e| @scale * e}
            extrusion = Geom::Vector3d.new(r[210] || 0, r[220] || 0, r[230] || 1)
            extrusion.length = r[39] || 0
            if extrusion.length == 0
                line = entities.add_line(pt1, pt2)
                if line and @opts[:tags]
                    line.set_attribute("FreeDXF", "handle", r[5]) if @opts[:tags]
                    line.set_attribute("FreeDXF", "fid", r['fid']) if @opts[:tags]
                end
            else
                pt3 = pt2.offset(extrusion)
                pt4 = pt1.offset(extrusion)
                #line = @entities.add_line(pt3, pt4)
                face = entities.add_face(pt1, pt2, pt3, pt4)
                if face and @opts[:tags]
                    face.set_attribute("FreeDXF", "fid", r['fid']) if DEBUG
                    #  face.set_attribute("FreeDXF", "handle", r[5]) if $JFDEBUG
                end
            end

            #if $JFDEBUG
            #t = @entities.add_text(r['fdxf_id'], pt1)
            #t.layer = @fdxf_layers[:id]
            #end
        end

        def self.draw_lwpolyline(r)
            #set_layer :fdxf_lwpolyline
            arc = []
            entities = get_entities(r[8])
            pline_flag = r[70]
            nverts = r[90]
            xs = r[10]#.split(@list_sep)
            ys = r[20]#.split(@list_sep)
            bs = r[42]
            lp = nil
            id = r[5]
            if ((pline_flag & 1) == 1)
                xs.push(xs[0])
                ys.push(ys[0])
            end
            if xs.class == Array
                for i in 0..xs.length-2
                    pt = Geom::Point3d.new(xs[i], ys[i])
                    #@entities.add_text(i.to_s, pt)
                    #@entities.add_cpoint(pt)
                    np = Geom::Point3d.new(xs[i+1], ys[i+1])
                    b = bs[i] || 0.0#if bs 
                    if b == 0.0
                        arc.concat [entities.add_line(pt, np)]
                    else
                        c, radius, x, l = calc_bulge(pt, np, b)
                        #@entities.add_text("#{i}:#{id}", c)
                        #arc.concat(entities.add_arc(c, x, Z_AXIS, radius, 0, l, @opts[:arc_segments]))
                        arc.concat(entities.add_arc(c, x, Z_AXIS, radius, 0, l, arc_segments(l)))
                        #@entities.add_line(pt, np)
                        #arc.map{|edge| edge.layer = @fdxf_layers[:lwpoly]}
                    end
                    arc.flatten!
                    arc.compact!
                    if @opts[:tags]
                        arc.each{|e| e.set_attribute("FreeDXF", "fid", r['fid'])}
                    end
                    #end # AND draw cords
                end
            else
                raise "shouldn't be here"
            end
        rescue => ex
            puts ex.backtrace.join("\n")
            p r
            fail
        end

        def self.calc_bulge(p1, p2, bulge)
            cord = p2.vector_to(p1) # vector from p1 to p2
            clength = cord.length
            s = (bulge * clength)/2.0 # sagitta (height)
            radius = (((clength/2.0)**2 + s**2)/(2.0*s)).abs # magic formula
            angle = (4.0 * Math::atan(bulge)).radians #.degrees # theta (included angle)
            radial = cord.clone.normalize # * radius # a radius length vector aligned with cord
            radial.length = radius
            delta = (180.0 - (angle.abs))/2.0 # the angle from cord to center
            delta = -delta if bulge < 0
            rmat = Geom::Transformation.rotation(p1, Z_AXIS, -delta.degrees)
            radial2 = radial.clone
            radial.transform! rmat
            center = p2.offset radial
            #startpoint = p1 - center
            endpoint = p2 - center
            [center, radius, center.vector_to(p1),  angle.degrees]
        rescue => e
            # Fireman 1.dxf
            p e
            puts "p1:#{p1}\np2:#{p2}\nbulge:#{bulge}"
            nil
        end

        def self.ocs2wcs(a_z)
            if a_z.x.abs < 1.0/64.0 && a_z.y.abs < 1.0/64.0
                a_x = Y_AXIS * a_z
            else
                a_x = Z_AXIS * a_z
            end
            a_y = a_z * a_x
            tr = Geom::Transformation.axes(ORIGIN, a_x, a_y, a_z)
        end

        def self.draw_circle(r)
            #set_layer :fdxf_circle
            entities  = get_entities(r[8])
            center    = Geom::Point3d.new(r[10], r[20], r.fetch(30, 0.0))#.map{|e| @scale * e}
            radius    = r[40]# * @scale
            thickness = r[39]
            normal    = [0, 0, 1] #|| r["210"]
            a_z       = Geom::Vector3d.new( r.fetch(210, 0), r.fetch(220, 0), r.fetch(230, 1) )
            if a_z.x.abs < 1.0/64.0 && a_z.y.abs < 1.0/64.0
                a_x = Y_AXIS * a_z
            else
                a_x = Z_AXIS * a_z
            end
            a_y        = a_z * a_x
            tr         = Geom::Transformation.axes(ORIGIN, a_x, a_y, a_z)
            new_center = center.transform(tr)
            new_normal = normal.transform(tr)
            circle     = entities.add_circle(new_center, new_normal, radius, OPTIONS[:circle_segments])

            #warn "no circle." if circle.nil?
            if circle and @opts[:tags]
                #circle.map{|e| e.set_attribute("FreeDXF", "handle", r[5])}
                circle.map{|e| e.set_attribute("FreeDXF", "fid", r['fid'])}
            end

            if @opts[:circle_cpoints]
                #cpoint = entities.add_cpoint(center)
                #cpoint.layer = @layer
            end
            #circle.each{|e| e.layer = @layer } if circle
        rescue => ex
            p OPTIONS
            local_variables.each {|v| puts "#{v} = #{eval(v.to_s).inspect}"}
            fail
        end

        def self.draw_arc(r)
            #set_layer :fdxf_arc
            #puts r[210] if r[210]
            entities = get_entities(r[8])
            center = Geom::Point3d.new( r[10], r[20], r.fetch(30, 0.0) )# ].map {|e| @scale * e}
            radius = r[40] #  * @scale
            start_angle = (r[50]+ 360.0).degrees
            end_angle = (r[51]+ 360.0).degrees
            if start_angle > end_angle or end_angle == 0
                end_angle = (end_angle + 360.degrees)#.degrees
            end
            arclen = (end_angle - start_angle).abs
            xaxis = Geom::Vector3d.new(Math.cos(start_angle), Math.sin(start_angle), 0)
            start_angle = 0
            end_angle = arclen
            if end_angle < 0
                start_angle, end_angle = end_angle, start_angle
                start_angle *= -1
            end
            #p arclen.radians
            segments = arc_segments(arclen)
            arc = entities.add_arc(center, xaxis, [0, 0, 1], radius, start_angle, end_angle, segments)
            if arc.nil?
                #warn "draw_arc: no arc. handle:#{r[5].inspect}"
                #cpoint =  entities.add_cpoint(center) if $JFDEBUG
            end
            if DEBUG
                #text =  @entities.add_text(r['fdxf_id'], center)
                #text.layer = @fdxf_layers[:id]
                #cpoint.layer = @layer
            end
        rescue => ex
            local_variables.each {|v| puts "#{v} = #{eval(v.to_s).inspect}"}
            fail
        end

        def self.draw_solid(r)
            #set_layer :fdxf_solid
            entities = get_entities(r[8])
            p1 = [ r[10], r[20], r.fetch(30, 0.0)]
            p2 = [ r[11], r[21], r.fetch(31, 0.0)]
            p3 = [ r[12], r[22], r.fetch(32, 0.0)]
            p4 = [ r[13], r[23], r.fetch(33, 0.0)]
            pts = [p1, p2, p3, p4].uniq
            #pts.each_with_index{|pt, i| @entities.add_text(i.to_s, pt)}
            thickness = r.fetch(39, 0)
            # TODO: It's more complex than this...
            dir = [ r[210] || 0, r[220] ||0 , r[230] || 1]
            tr = Geom::Transformation.new(ORIGIN, dir)
            pts = pts.map{|pt| pt.transform!(tr)}
            begin
                #face = @entities.add_face(pts[0], pts[1], pts[3], pts[2])
                face = entities.add_face(pts)#[0], pts[1], pts[3], pts[2])
            rescue
                p pts if DEBUG
                pts.each_with_index {|pt, i| entities.add_cpoint(pt); entities.add_text(i.to_s, pt)}
                #face = @entities.add_face(pts[0], pts[1], pts[3])
                #face = @entities.add_face(pts[1], pts[3], pts[2])
            end
            #face2 = @entities.add_face(pts[1], pts[3], pts[4])
            if face
                #face.set_attribute("FreeDXF", "handle", r[5]) if @opts[:tags]
                face.set_attribute("FreeDXF", "fid", r['fid']) if @opts[:tags]
                face.pushpull(-thickness) if thickness != 0
            end
        end

        def self.draw_insert(r)
            #set_layer :fdxf_blocks
            #return if r['ents'].nil?
            pt = Geom::Point3d.new( r[10], r[20], r.fetch(30, 0.0))# ].map{|e| @scale * e}
            xscale = r.fetch(41, 1.0)
            yscale = r.fetch(42, 1.0)
            zscale = r.fetch(43, 1.0)
            angle  = r.fetch(50, 0.0)
            t = Geom::Transformation.new(pt)
            name = r.fetch(2, nil)
            cdef = Sketchup.active_model.definitions[name] if name
            if cdef
                ins = @entities.add_instance(cdef, t)
                t = Geom::Transformation.scaling(pt, xscale, yscale, zscale)
                ins.transform!(t)
                t =Geom::Transformation.rotation(pt, t.zaxis, angle.degrees)
                ins.transform!(t)
                ins.layer = get_layer(r[8])
                if @opts[:tags]
                    ins.set_attribute('FreeDXF', 'fid', r['fid'])
                end
            end
        end

        def self.draw_3dface(r)
            #set_layer :fdxf_3dface
            edge_visibility_flag = r.fetch(70, 0)
            entities = get_entities(r[8])
            pt1 = Geom::Point3d.new( r[10], r[20], r.fetch(30, 0.0) )#.map {|e| @scale * e}
            pt2 = Geom::Point3d.new( r[11], r[21], r.fetch(31, 0.0) )#.map {|e| @scale * e}
            pt3 = Geom::Point3d.new( r[12], r[22], r.fetch(32, 0.0) )#.map {|e| @scale * e}
            pt4 = Geom::Point3d.new( r[13], r[23], r.fetch(33, 0.0) )#.map {|e| @scale * e}
            pts = [pt1, pt2, pt3, pt4]
            begin
                entities.add_face(pts)
            rescue => ex
                #entities.add_face(pt1, pt2, pt3)
                #entities.add_face(pt1, pt2, pt4)
            end
        end

        def self.draw_ellipse(r)

           entities = get_entities(r[8])
           c = [r[10], r[20], r.fetch(30, 0.0)] # .map{|e| @scale * e}
           c = Geom::Point3d.new(c)
           #entities.add_cpoint(c)
           #entities.add_text("center", c)
           end_vec = Geom::Vector3d.new([r[11], r[21], r.fetch(31, 0.0)])
           end_pt = c + end_vec
           #entities.add_cpoint(end_pt)
           #entities.add_text("major axis end_pt", end_pt)
           #entities.add_cline(c, end_pt)
           u1 = r[41]
           u2 = r[42]
           a = [r[11], r[21], r[31]] # .map{|e| @scale * e}
           a = Geom::Point3d.new(a)
           ratio = r[40]
           #w = a.distance(c) / 4.0
           w = a.distance([0,0,0])# / 2.0
           h = w * ratio.to_f
           lpt = nil
           s = ((u2 - u1) / 24.0)
           pts = []
           (u1..u2).step(s) { |u| 
              pt = []
              pt.x = (c.x + w * Math.cos(u))
              pt.y = (c.y + h * Math.sin(u))
              pt.z = 0
              pts << pt.clone
           }
           angle = (Math.atan2(end_pt.y-c.y, end_pt.x-c.x)+2*Math::PI).modulo(2*Math::PI)
           tr = Geom::Transformation.rotation(c, [0,0,1], angle)
           pts = pts.map {|pt| pt.transform(tr)}
           
           cp = entities.add_curve(pts)
        end


        # All points in WCS
        def self.draw_point(r)
            #set_layer :fdxf_point
            entities = get_entities(r[8])
            pt = Geom::Point3d.new(r[10], r[20], r.fetch(30, 0.0))
            entities.add_cpoint(pt)
            thick = r.fetch(39, 0.0)
            if thick != 0
                dir = Geom::Vector3d.new(r.fetch(210, 0.0), r.fetch(220, 0.0), r.fetch(230, 1.0))
                dir.length = thick
                pt2 = pt.offset(dir)
                entities.add_line(pt, pt2)
            end
        end # POINT


        def self.draw_spline(e)

            if DEBUG
                print "DRAW_SPLINE\n"
                e.each { |key, value|
                    if value.class == Array  
                        print "Key: #{key}, Class: #{value.class.to_s}, Value: "
                        value.each { |t| print t," " }
                        print "\n"
                    else
                        print "Key: #{key}, Class: #{value.class.to_s}, Value: #{value}\n"
                    end	
                }
            end	

=begin
DRAW_SPLINE
Key: 71, Class: Fixnum, Value: 3 #Degree of the spline curve
Key: 5, Class: String, Value: 3C
Key: 220, Class: Float, Value: 0.0
Key: 330, Class: String, Value: 1F
Key: fid, Class: String, Value: f4
Key: 0, Class: String, Value: SPLINE
Key: 72, Class: Fixnum, Value: 14 #Number of knots 
Key: 210, Class: Float, Value: 0.0
Key: 100, Class: Array, Value: AcDbEntity AcDbSpline 
Key: 40, Class: Array, Value: 0.0 0.0 0.0 0.0 1.0 1.0 1.0 2.0 2.0 2.0 3.0 3.0 3.0 3.0 
Key: 73, Class: Fixnum, Value: 10 #Number of control points
Key: 62, Class: Fixnum, Value: 250 #color
Key: 30, Class: Array, Value: 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 
Key: 74, Class: Fixnum, Value: 0
Key: 8, Class: String, Value: LAYER_1
Key: 20, Class: Array, Value: 2.52370469771977 2.52370469771977 -0.47628445083579 -9.47625189650246 -2.47633463479758 -2.47633463479758 -4.47621256398511 -13.476352264426 -17.4762803775754 -17.4762803775754 
Key: 42, Class: Float, Value: 1.0e-10
Key: 70, Class: Fixnum, Value: 8 #Spline flag (bit coded): 8 = Planar
Key: 10, Class: Array, Value: 18.2650349889233 8.26512857866289 -1.73495008637182 -1.73495008637182 8.26495632388862 11.2651177272184 18.2650349889233 18.2169759069041 -1.73495008637182 8.26512857866289 
Key: 43, Class: Float, Value: 1.0e-10
Key: 230, Class: Float, Value: 1.0
-->scale = 0.0393700787401575 (Length)
=end

            #http://www.autodesk.com/techpubs/autocad/acad2000/dxf/spline_dxf_06.htm
            #http://images.autodesk.com/adsk/files/acad_dxf0.pdf, page 151

            entities = get_entities(e[8])	 #Value LAYER_1

            if e[10].respond_to?(:each)  #return true if the e[10] class has an :each method on it - Array class verify?
                pts = []
                numseg = 12 #e[72]  #Number of knots - for spline, not bezier - higher value = better result but slover action
                degree = e[71]  #Degree of the spline curve

                #e[73]  Number of control points
                #e[62]  Color number (fixed)
                #e[10]  Control points (in WCS); one entry per control point - DXF: X
                #e[40]  Knot value (one entry per knot)

                for i in 0..e[10].length-1
                    pos = Geom::Point3d.new([ e[10][i] || 0, e[20][i] || 0, e[30][i] || 0 ] )
                    pts.push( pos )  #collect bezier control points
                    #entities.add_cpoint( pos )  #draw construction point for debug only

                    if pts.length == degree+1   #I assume that degree=3 need 4 control points for the bezier curve
                        curvepts = Bezier::points( pts, numseg )  #Bezier::points(Array of 4+ Point3d, Number of Segments)
                        edges = entities.add_curve( curvepts )  #draw the curve, return an array of Edges that make up the curve

                        # COPY FROM PLUGIN - su_bezier::create_curve
                        # Attach an attribute to the curve with the array of points 4 edit with su_bezier plugin
                        bezier_curve = edges[0].curve  # get the Curve object that this Edge belongs to
                        if( bezier_curve )
                            bezier_curve.set_attribute("skp", "crvtype", "Bezier")
                            bezier_curve.set_attribute("skp", "crvpts", pts)
                        end

                        pts = [ pos ]  #the last point now is the first
                    end  #if		
                end  #for
            end  #if .respond_to?
        rescue => ex
            puts "Failure in spline."
            lv {local_variables}
            warn "backtrace"
			puts ex.backtrace
        end  #SPLINE


        # {5=>"40D5E", 330=>"18", 0=>"TEXT", 1=>"2'-0\"", 100=>["AcDbEntity", "AcDbText", "AcDbText"], 7=>"ARCHD", 40=>6.0, 62=>0, 30=>0.0, 8=>"TEXT", 20=>1276.87402748742, 10=>670.551253338073}
        # {5=>"40D5A", 330=>"18", 0=>"TEXT", 50=>90.0, 1=>"TO TOP OF O'HANG", 100=>["AcDbEntity", "AcDbText", "AcDbText"], 7=>"ARCHD", 40=>6.0, 62=>0, 30=>0.0, 8=>"TEXT", 20=>1427.03893761635, 10=>63.3665941452673}

        def self.clean_text(txt)
            txt.gsub!('\P', "\n") # paragraph
            txt.gsub!('\~', " ") # non-breaking space
            txt.gsub!('%%u', '') # underline
            txt
        end

        def self.draw_text(e)
            entities = get_entities(e[8])
            pt = Geom::Point3d.new([e[10], e[20], e.fetch(30, 0.0)])
            txt = e[1]
            txt = clean_text(txt)
            if @opts[:screen_text]
                @entities.add_text(txt, pt)
                return
            end
            unless txt.empty?
                #puts "txt: #{ txt.inspect }" if $JFDEBUG
                begin
                    gr = entities.add_group
                    #gr.entities.add_cpoint(ORIGIN)
                    gr.name = "TEXT"
                    gr.material = "Black"
                    gr.set_attribute("FreeDXF", "text", txt)
                    height = e[40] > 0.125 ? e[40] : 0.125
                    gr.entities.add_3d_text(txt, TextAlignLeft, "Arial Narrow", false, false, height, 1)
                    gr.transform!(pt)
                    v = text_align_vector(gr, e[71])
                    gr.transform!(v)
                    rot = Geom::Transformation.rotation(gr.transformation.origin, [0, 0, 1], (e[50]||0).degrees)
                    gr.transform!(rot)
                    #gr.explode
                rescue => ex
                    warn 'in draw_text()'
                    fail
                end
            end
        end

        def self.draw_mtext(e)
            pt = Geom::Point3d.new([e[10], e[20], e.fetch(30, 0.0)])
            entities = get_entities(e[8])
            #entities.add_cpoint(ORIGIN)
            txt = e[1]#.strip
            return if txt.empty?
            # Text as screen text option?
            # @entities.add_text(txt, pt)
            if txt[0].chr == "{" and txt[-1].chr == "}"
                #txt.slice(1, -1)
                txt = txt[1..-2]
            end
            txt = clean_text(txt)
            if @opts[:screen_text]
                entities.add_text(txt, pt)
                return
            end
            bold = false
            italic = false
            if txt[";"]
                codes, txt = txt.split(";")
                codes = codes.split("|")
                font_code, font = codes[0].split('\f')
                #bold = codes[1] == "b1"
                #italic = codes[2] == "i1"
                codes.each do |code|
                    italic = true if code == "i1"
                    bold   = true if code == "b1"
                end
            end
            font == font || e[7]
            return if txt.nil?


            unless txt.strip.empty?
                begin
                    gr = entities.add_group
                    #gr.entities.add_cpoint(ORIGIN)
                    height = e[40] > 0.125? e[40] : 0.125
                    status = gr.entities.add_3d_text(txt, TextAlignLeft, "Arial", bold, italic, height, @opts[:font_quality])
                    #gr.name = "MTEXT"
                    gr.name = txt[0..25]
                    if e['fid']
                        gr.set_attribute('FreeDXF', 'fid', e['fid'])
                    end
                    gr.material = "Black"
                    gr.transform!(pt)
                    #Attachment point:
                    #1 = Top left; 2 = Top center; 3 = Top right;
                    #4 = Middle left; 5 = Middle center; 6 = Middle right;
                    #7 = Bottom left; 8 = Bottom center; 9 = Bottom right
                    v = text_align_vector(gr, e[71])
                    gr.transform!(v)
                    rot = Geom::Transformation.rotation(gr.transformation.origin, [0, 0, 1], (e[50]||0).degrees)
                    gr.transform!(rot)
                rescue => ex
                    p e
                    p ex
                    p ex.backtrace
                    p gr
                    fail 'in draw_mtext()'
                end
            end
        end

        def self.text_align_vector(gr, attach_point)
            bb = gr.bounds
            w = gr.bounds.width
            h = gr.bounds.height
            o = gr.transformation.origin
            v = [0, 0, 0]
            case attach_point
            when 1
                v = [0     , -h]
            when 2
                v = [-w/2.0, -h]
            when 3
                v = [-w    , -h]
            when 4
                v = [0     , -h/2.0]
            when 5
                v = [-w/2.0, -h/2.0]
            when 6
                v = [-w    , -h/2.0]
            when 7
                v = [0     , 0]
            when 8
                v = [-w/2.0, 0]
            when 9
                v = [-w    , 0]
            end
            return v
        end


        #
        # TODO:
        # Dimensions are considerably more complex then this.
        #
        def self.draw_dimension(e)
            #return
            block_name = e[2]
            cdef = Sketchup.active_model.definitions[block_name]
            if cdef
                point = Geom::Point3d.new(e.fetch(10, 0), e.fetch(20, 0), e.fetch(30, 0))
                axes = Geom::Vector3d.new(e.fetch(210, 0), e.fetch(220, 0), e.fetch(230, 1))
                #tr = ocs2wcs(axes)
                #tr = [0, 0, 0]
                #point = point.transform(tr)
                point = [0, 0, 0]
                ins = @entities.add_instance(cdef, point)
                ins.name = "Dimension"
            end
        end

        def self.set_layer(ent)
            ent_layer = ent[8] || ent[0]
            ent_type = ent[0]
            #return if ent_type == "SEQEND"
            layers = Sketchup.active_model.layers
            if @in_block
                Sketchup.active_model.active_layer = layers[0]
                return
            end
            if @opts[:layers] == "by Dxf Type"
                layer = layers[ent_type]
                if layer.nil?
                    layer = layers.add(ent_type)
                end
                Sketchup.active_model.active_layer = layer
            elsif @opts[:layers] == "Layer0"
                Sketchup.active_model.active_layer = layers[0]
            elsif @opts[:layers] == "Dxf Layers"
                layer = layers[ent_layer]
                if layer.nil?
                    layer = layers.add(ent_layer)
                end
                Sketchup.active_model.active_layer = layer
            end
        end

        def set_layer_colors

        end

        def self.find_by_handle()
            r = UI.inputbox(["Handle or fid"], [""])
            Sketchup.active_model.selection.clear
            #for e in Sketchup.active_model.entities
            #Sketchup.active_model.selection.add(e) if e.get_attribute("FreeDXF", "handle") == r[0]
            #end
            find_recursive(Sketchup.active_model.entities, r[0])
            puts Sketchup.active_model.selection.length
        end

        def self.find_recursive(entities, handle)
            for entity in entities
                att_handle = entity.get_attribute('FreeDXF', 'handle')
                att_fid    = entity.get_attribute('FreeDXF', 'fid')
                if handle == att_handle || handle == att_fid
                    Sketchup.active_model.selection.add(entity)
                end
                if entity.is_a?(Sketchup::Group)
                    find_recursive(entity.entities, handle)
                end
                if entity.is_a?(Sketchup::ComponentInstance)
                    find_recursive(entity.definition.entities, handle)
                end
            end
        end

        def self.get_layer(name)
            layers = Sketchup.active_model.layers
            layers.add(name)
        end

        # Returns an entities collection
        def self.get_entities(name)
            #return Sketchup.active_model.entities
            if @in_block
                return @entities
            end
            name ||= "UNKOWN"
            if @layer_entities[name].nil?
                gr       = @top_entities.add_group
                #gr.entities.add_cpoint(ORIGIN)
                gr.name  = name
                layer    = get_layer(name)
                gr.layer = get_layer(name)
                @layer_entities[name] = gr.entities
            end
            return @layer_entities[name]
        end



        # Menus
        #submenu = UI.menu("Plugins").add_submenu("FreeDXF #{FreeDXF::VERSION}")
        menu = defined?(JF.menu) ? JF.menu('f') : UI.menu("Plugins")
        #submenu.add_item("FreeDXF #{JF::FreeDXF::VERSION}") {JF::FreeDXF.do_options}
        menu.add_item("FreeDXF #{JF::FreeDXF::VERSION}") {JF::FreeDXF.main}
        if DEBUG
            menu.add_item("FreeDXF Find by Handle #{JF::FreeDXF::VERSION}") {JF::FreeDXF.find_by_handle}
        end
        UI.add_context_menu_handler do |menu|
            if DEBUG
                menu.add_item("FreeDXF Show DXF Handle") {
                    h = Sketchup.active_model.selection[0].get_attribute("FreeDXF", "fid")
                    UI.messagebox("fid: #{h}")
                }
            end
        end

    end # module FreeDXF
end # module JF
