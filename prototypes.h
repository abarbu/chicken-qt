/* prototypes.h */



struct QDynamicReceiver;
class GLWidget;

qtapplication qt_init();
qtwidget qt_create(char *string, qtwidget parent);
___safe void qt_show(qtwidget widget);
void qt_hide(qtwidget widget);
___safe ___bool qt_run(___bool once);
void qt_deleteobject(qtobject widget);
void qt_deletepixmap(qtpixmap widget);
qtpixmap qt_pixmap(char *filename);
___bool qt_connect(qtobject w1, char *sig, qtobject w2, char *slot);
___bool qt_disconnect(qtobject w1, char *sig, qtobject w2, char *slot);
qtwidget qt_find(qtwidget parent, char *name);
qtdynamicreceiver qt_dynamicreceiver(char *name, char *slot, C_word proc);
int qt_message(char *caption, char *text, qtwidget parent, char *b0, char *b1, char *b2);
const char *qt_classname(qtobject w);
___bool qt_setstringproperty(qtwidget w, char *prop, char *val);
___bool qt_setboolproperty(qtwidget w, char *prop, ___bool val);
___bool qt_setintproperty(qtwidget w, char *prop, int val);
___bool qt_setfloatproperty(qtwidget w, char *prop, double val);
___bool qt_setcharproperty(qtwidget w, char *prop, char val);
___bool qt_setpixmapproperty(qtwidget w, char *prop, qtpixmap val);
___bool qt_setpointproperty(qtwidget w, char *prop, int *val);
___bool qt_setpointfproperty(qtwidget w, char *prop, double *val);
___bool qt_setrectproperty(qtwidget w, char *prop, int *val);
___bool qt_setrectfproperty(qtwidget w, char *prop, double *val);
char *qt_getstringproperty(qtwidget w, char *prop);
___bool qt_getboolproperty(qtwidget w, char *prop);
int qt_getintproperty(qtwidget w, char *prop);
qtpixmap qt_getpixmapproperty(qtwidget w, char *prop);
C_word qt_getpointfproperty(qtwidget w, char *prop, C_word pt);
C_word qt_getpointproperty(qtwidget w, char *prop, C_word pt);
C_word qt_getrectfproperty(qtwidget w, char *prop, C_word rc);
C_word qt_getrectproperty(qtwidget w, char *prop, C_word rc);
C_word qt_getsizefproperty(qtwidget w, char *prop, C_word sz);
C_word qt_getsizeproperty(qtwidget w, char *prop, C_word sz);
double qt_getfloatproperty(qtwidget w, char *prop);
int qt_getcharproperty(qtwidget w, char *prop);
int qt_propertytype(qtwidget w, char *prop);
qtwidget qt_gl(char *name, qtwidget parent, C_word proc);
void qt_update(qtwidget w);
qttimer qt_make_timer(double secs);
void qt_destroy_timer(qttimer timer);
qtsound qt_sound(char *filename);
void qt_clearlistwidget(qtwidget w);
void qt_addcomboboxitem(qtwidget w, char *s);
void qt_addlistwidgetitem(qtwidget w, char *s);
void qt_addtreewidgetitem(qtwidget w, char *s);
char *qt_listwidgetitem(qtwidget w, int i);
char *qt_getexistingdirectory(qtwidget p, char *cap, char *dir, int opts);
char *qt_getopenfilename(qtwidget p, char *cap, char *dir, char *filter, int opts);
char *qt_getsavefilename(qtwidget p, char *cap, char *dir, char *filter, int opts);
void qt_setheaders(qtwidget w, char *s);
char *qt_selection(qttextedit w);
void qt_insert(qttextedit w, char *s);
qtaction qt_shortcut(qtwidget w, char *k);
void qt_add_action(qtwidget w, qtaction a);
void qt_remove_action(qtwidget w, qtaction a);
int qt_charencoding(int mode);
void qt_attribute(qtwidget w, int attribute, int set);
int qt_testattribute(qtwidget w, int attribute);
int qt_window_flags(qtwidget w);
void qt_set_window_flags(qtwidget w, int f);
qtwidget qt_desktop();
void qt_variantlist_remove_front(C_word c, C_word self, C_word k, C_word l);
qtvariantlist qt_make_variantlist();
void qt_destroy_variantlist(qtvariantlist l);
void qt_variant_list_insert_back_int(qtvariantlist l, int a);
void qt_variant_list_insert_back_string(qtvariantlist l, char *s);
void qt_variant_list_insert_back_bool(qtvariantlist l, int a);
void qt_variant_list_insert_back_uint(qtvariantlist l, int a);
void qt_variant_list_insert_back_double(qtvariantlist l, double a);
int qt_variant_list_length(qtvariantlist l);
___bool qt_invokemethod(qtobject o, char *signal, qtvariantlist arguments);
void qt_variant_list_discard_front(qtvariantlist l);
qtdbusconnection qt_dbus_session_bus();
qtdbusconnection qt_dbus_system_bus();
void qt_destroy_dbus_connection(qtdbusconnection c);
___bool qt_c_dbus_connect(qtdbusconnection c,
			char *service, char *object,
			char *interface, char *signal,
			qtobject w2, char *slot);
___bool qt_dbus_disconnect(qtdbusconnection c,
			   char *service, char *object,
			   char *interface, char *signal,
			   qtobject w2, char *slot);
void qt_c_dbus_list_names(qtdbusconnection c, qtvariantlist l);
___bool qt_c_dbus_send_signal(qtdbusconnection bus, char *object,
			    char *interface, char *signal, qtvariantlist l);
___bool qt_dbus_register_object(qtdbusconnection bus, char *path, qtobject obj);
void qt_dbus_unregister_object(qtdbusconnection bus, char *path);
___bool qt_dbus_method_call(qtdbusconnection bus, char *service, char *path,
			    char *interface, char *method, qtvariantlist l);
___bool qt_dbus_method_call_with_callback(qtdbusconnection bus, char *service, char *path,
					  char *interface, char *method, qtvariantlist l,
					  qtobject obj, char *slot);
___bool qt_dbus_register_service(qtdbusconnection bus, char *service);
___bool qt_dbus_unregister_service(qtdbusconnection bus, char *service);

qthttp qt_make_http();
void qt_destroy_http(qthttp h);
int qt_http_set_host(qthttp h, char *host, int port);
int qt_http_get(qthttp h, char *url);
// TODO this should return ___byte_vector but easyffi complains
char *qt_http_read_bytes(qthttp h);
char *qt_http_read_string(qthttp h);
void qt_webview_set_html(qtwidget w, char *html);
char *qt_textedit_to_html(qtwidget w);
char *qt_textedit_to_plain_text(qtwidget w);
char *qt_lineedit_text(qtwidget w);
