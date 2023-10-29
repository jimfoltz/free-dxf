# Copyright 2013, Trimble Navigation Limited

# This software is provided as an example of using the Ruby interface
# to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name        :   Bezier Curve Tool 1.0
# Description :   A tool to create Bezier curves.
# Menu Item   :   Draw->Bezier Curves
# Context Menu:   Edit Bezier Curve
# Usage       :   Select 4 points-
#             :   1. Start point of the curve
#             :   2. Endpoint of the curve
#             :   3. Second control point. It determines the tangency at the
#                    start
#             :   4. Next to last control point. It determines the tangency at
#                    the end
# Date        :   8/26/2004
# Type        :   Tool
#-----------------------------------------------------------------------------

require 'sketchup.rb'

# Ruby implementation of Bezier curves

module Bezier

# Evaluate a Bezier curve at a parameter.
# The curve is defined by an array of its control points.
# The parameter ranges from 0 to 1
# This is based on the technique described in "CAGD  A Practical Guide, 4th
# Edition" by Gerald Farin. page 60

def self.eval(pts, t)
    degree = pts.length - 1
    if degree < 1
        return nil
    end
    
    t1 = 1.0 - t
    fact = 1.0
    n_choose_i = 1

    x = pts[0].x * t1
    y = pts[0].y * t1
    z = pts[0].z * t1
    
    for i in 1...degree
        fact = fact*t
        n_choose_i = n_choose_i*(degree-i+1)/i
        fn = fact * n_choose_i
        x = (x + fn*pts[i].x) * t1
        y = (y + fn*pts[i].y) * t1
        z = (z + fn*pts[i].z) * t1
    end

    x = x + fact*t*pts[degree].x
    y = y + fact*t*pts[degree].y
    z = z + fact*t*pts[degree].z

    Geom::Point3d.new(x, y, z)
end

# Evaluate the curve at a number of points and return the points in an array
def self.points(pts, numpts)
    curvepts = []
    dt = 1.0 / numpts

    # evaluate the points on the curve
    for i in 0..numpts
        t = i * dt
        curvepts[i] = self.eval(pts, t)
    end
    curvepts
end

# Create a Bezier curve in SketchUp - leave for example
def self.curve(pts, numseg = 16)
    model = Sketchup.active_model
    entities = model.active_entities
    model.start_operation "Bezier Curve"
    
    curvepts = self.points(pts, numseg)
    
    # create the curve
    edges = entities.add_curve(curvepts);
    model.commit_operation
    edges
end

end # module Bezier
