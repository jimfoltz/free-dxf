# Copyright 2011 jim.foltz@gmail.com
#
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

require 'sketchup'
require 'extensions'

module JF
  module FreeDXF
     VERSION = '16a'.freeze
    PLUGIN_ROOT = File.join(File.dirname(__FILE__), 'jf_FreeDXF')
    # Embed SKUI
    #load(File.join(PLUGIN_ROOT, 'SKUI', 'embed_skui.rb'))
    #::SKUI.embed_in(self)

    ext = SketchupExtension.new("FreeDXF", File.join(PLUGIN_ROOT, 'freedxf.rb'))
    ext.description = "FreeDXF #{VERSION} - a .dxf file importer for SketchUp."
    ext.creator     = "jim.foltz@gmail.com, rsa@o2.pl"
    ext.copyright   = "2011-2016 Jim Foltz"
    ext.version     = VERSION
    Sketchup.register_extension(ext, true)
  end
end

# History
#
# 0.10.2 
#   arc segments are proportional to circle segments
# 0.10.0 - Added Teigha .dwg to .dxf conversion
