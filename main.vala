using Gtk;
using Posix;

public class MainWindow : Gtk.Window {

	private Gdk.Pixbuf file_pixbuf;
    private Gdk.Pixbuf folder_pixbuf;

	public string parent = "/usr/share/applications";

	private Gtk.ListStore store = new Gtk.ListStore (4, typeof (string), typeof (string), typeof (bool), typeof (Gdk.Pixbuf));

	private Gdk.Pixbuf find_icon (string name, IconTheme theme) {
		try {
			Gdk.Pixbuf icon_px;
			icon_px = theme.load_icon (name, 48, Gtk.IconLookupFlags.FORCE_SVG);
			icon_px = icon_px.scale_simple (48, 48, Gdk.InterpType.BILINEAR);
			return icon_px;
		} catch (Error e) { }
		return file_pixbuf.scale_simple (48, 48, Gdk.InterpType.BILINEAR);;
	}

	private void fill_store () {
		GLib.Dir dir;
		string name;
		TreeIter iter;
		
		store.clear ();
		
		try {
			dir = GLib.Dir.open (parent, 0);
			name = dir.read_name ();//GLib.Dir.read_name (dir);

			while (name != null) {
				string path, display_name = "";
				bool is_dir;
				Gdk.Pixbuf icon_px = null;
				IconTheme theme = Gtk.IconTheme.get_default ();
				if (true) {//(name[0] != '.') {
					path = GLib.Path.build_filename (parent, name);
					is_dir = GLib.FileUtils.test (path, FileTest.IS_DIR);
					
					if (!is_dir) {
						try {
							File file = File.new_for_path (path);
							FileInputStream @is = file.read ();
							DataInputStream dis = new DataInputStream (@is);
							string line;
						
							while ((line = dis.read_line ()) != null) {
								string[] lines = line.split("=", 2);
								if (lines[0] == "Name") {
									display_name = lines[1];
								} else if (lines[0] == "Icon") {
									icon_px = find_icon (lines[1], theme);
								}
							}
						} catch (Error e) {
							stdout.printf ("Error: %s\n", e.message);
						}
					} else {
						display_name = GLib.Path.get_basename (path);
						icon_px = folder_pixbuf;
					}
					
					if (display_name == null) {
						display_name = GLib.Path.get_basename (path);
					}
					
					store.append (out iter);
					store.set (iter, 0, path, 1, display_name, 2, is_dir, 3, icon_px);
				}
				name = dir.read_name ();
			}
		} catch (Error e) {
			stderr.printf ("Could not load directory: %s\n", e.message);
			return;
		}
	}

	private void icon_activate (TreePath path) {
		TreeIter iter;
		store.get_iter (out iter, path);
		Posix.system("gtk-launch "+GLib.File.get_basename(iter[0]));
	}

	public MainWindow() {
		try {
			file_pixbuf = new Gdk.Pixbuf.from_file ("/usr/share/ALaunch/gnome-fs-regular.png");
			folder_pixbuf = new Gdk.Pixbuf.from_file ("/usr/share/ALaunch/gnome-fs-directory.png");
		} catch (Error e) {
			stderr.printf ("Could not load icon: %s\n", e.message);
		}
		this.title = "ALaunch";
		this.set_type_hint (Gdk.WindowTypeHint.DOCK);
		this.destroy.connect (Gtk.main_quit);
		
		Gdk.Screen screen = Gdk.Screen.get_default ();
		this.set_default_size (screen.width (), screen.height ());
		
		fill_store ();
		
		IconView iconview = new IconView ();
		iconview.set_model (store);
		iconview.set_text_column (1);
		iconview.set_pixbuf_column (3);
		iconview.item_activated.connect (icon_activate);
		
		ScrolledWindow sw = new ScrolledWindow (null, null);
		sw.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		sw.add (iconview);
		
		Box box = new Box (Orientation.VERTICAL, 1);
		box.pack_start (sw, true, true, 0);
		this.add (box);
	}

}

void main(string[] args) {
	Gtk.init (ref args);
	MainWindow win = new MainWindow ();
	win.show_all ();
	Gtk.main ();
}
