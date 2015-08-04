require 'gtk3'

class ALaunch

	def initialize()
		@window = MainWindow.new(800,500)
		@window.show_all
		Gtk.main
	end

end

class MainWindow < Gtk::Window
	COL_PATH, COL_DISPLAY_NAME, COL_IS_DIR, COL_PIXBUF = (0..3).to_a
	 
	def solve_desktop(filename,want)
		file = File.open(filename)
		
		while line  = file.gets
        	case line.split("=")[0]
        	when "Name"
        		name = line.split("=")[1]
        	when "Icon"
        		foo = line.split("=")
        		bar = foo[1]
        		bar[-1] = "."
        		icon = find_file(bar + "svg")
        	when "Exec"
        		exec = line.split("=")[1]
			end
		end if File.ftype(filename) != "directory"
		name = File.basename(filename) if File.ftype(filename)=="directory"

		if name==nil
			name = File.basename(filename, ".desktop")
		end
		
		case want
		when "NAME"
			return name
		when "ICON"
		begin
			icon_px = Gdk::Pixbuf.new(icon) if File.ftype(filename) != "directory"
			icon_px = @file_pixbuf if icon == nil
			icon_px = @folder_pixbuf if File.ftype(filename) == "directory"
			rescue Exception
				return @file_pixbuf
			else
     			return icon_px
		end
		when "EXEC"
			return exec
		end
	end
	 
	def find_file(basename)
    	%w(. /usr/share/gtk-3.0/demo /usr/share/icons/Numix-Circle-Light/scalable/apps/).each do |dirname|
    	  	path = File.join(dirname, basename)
    	  	if File.exist?(path)
    	    	return path
    	  	end
    	end
		
    	return find_file("gnome-fs-regular.png")
  	end
	 
	def fill_store
		@store.clear
		Dir.glob(File.join(@parent, "*")).each do |path|
        	is_dir = FileTest.directory?(path)
        	iter = @store.append
        	filename = GLib.filename_to_utf8(path)
        	iter[COL_DISPLAY_NAME] = solve_desktop(filename,"NAME")
        	iter[COL_PATH] = path
        	iter[COL_IS_DIR] = is_dir
        	iter[COL_PIXBUF] = solve_desktop(filename,"ICON")
      	end
    end
	
	def initialize(x,y)
		super("ALaunch")
		self.signal_connect("destroy") {
			Gtk.main_quit
		}
		
		@file_pixbuf = Gdk::Pixbuf.new(find_file("gnome-fs-regular.png"))
      	@folder_pixbuf = Gdk::Pixbuf.new(find_file("gnome-fs-directory.png"))
		
		@store = Gtk::ListStore.new(String, String, TrueClass, Gdk::Pixbuf)
		@parent = "/usr/share/applications/"
		
		@store.set_default_sort_func do |a, b|
        	if !a[COL_IS_DIR] and b[COL_IS_DIR]
        	  	1
        	elsif a[COL_IS_DIR] and !b[COL_IS_DIR]
        	  	-1
        	else
        	  	a[COL_DISPLAY_NAME] <=> b[COL_DISPLAY_NAME]
        	end
      	end
      	@store.set_sort_column_id(Gtk::TreeSortable::DEFAULT_SORT_COLUMN_ID, Gtk::SortType::ASCENDING)
      	fill_store
      	set_default_size(x,y)
      	set_border_width(0)
      	
      	sw = Gtk::ScrolledWindow.new
      	sw.shadow_type = :etched_in
      	sw.set_policy(:automatic, :automatic)
      	
      	iconview = Gtk::IconView.new(@store)
      	iconview.selection_mode = :multiple
      	iconview.text_column = COL_DISPLAY_NAME
      	iconview.pixbuf_column = COL_PIXBUF
      	iconview.signal_connect("item_activated") do |iview, path|
        	iter = @store.get_iter(path)
			if File.ftype(iter[COL_PATH]) != "directory"
				system("gtk-launch "+File.basename(iter[COL_PATH], ".desktop"))
        	elsif iter[COL_DISPLAY_NAME]
          		@parent = iter[COL_PATH]
          		fill_store
        	end
      	end
      	sw.add(iconview)
      	self.add(sw)
      	iconview.grab_focus
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

ALaunch.new()
