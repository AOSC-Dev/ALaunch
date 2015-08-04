class MainWindow < Gtk::Window
	
	def initialize()
		provider = Gtk::CssProvider.new
   		provider.load(:data => File.read("css_accordion.css"))
	end

	def apply_css(widget, provider)
    	widget.style_context.add_provider(provider, GLib::MAXUINT)
    	if widget.is_a?(Gtk::Container)
    		widget.each_forall do |child|
        		apply_css(child, provider)
        	end
        end
    end
    
end

