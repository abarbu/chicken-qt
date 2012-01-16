/* main.cpp */

#include <QtGui>
#include <QtUiTools>
#include <QGLWidget>
#include <QtCore>
#include <QtDBus>
#include <QHttp>
#include <chicken.h>
#include <assert.h>

#define ___bool         int
#define ___out


static int qt_char_encoding = 1;	// 0=latin1, 1=utf8, 2=ascii

struct variantlist_fun
{
  virtual void operator()(C_word w) = 0;
};

static void qt_variantlist_do_one(QVariantList* l, variantlist_fun* fun, C_word **storage, int i);
static int qt_variantlist_storage(QVariantList* l, int i);

// We have to craft a custom QObject and lie about its slots so that
// we'll get the appropriate qt_metacall. We can get away without
// this by the qt-approved method of connecting by explicitly
// specifying the ids of the methods. Unfortunately whoever
// implemented QtDBus broke this by having QtDBus provide its own
// incompatible connect that insists on named slots

static const uint qt_meta_data_QDynamicReceiver[] = {
  // content:
  4,       // revision
  0,       // classname
  0,    0, // classinfo
  0,   14, // methods
  0,    0, // properties
  0,    0, // enums/sets
  0,    0, // constructors
  0,       // flags
  0,       // signalCount

  // slots: signature, parameters, type, tag, flags
  18,   17,   17,   17, 0x0a,

  0        // eod
};

static const char qt_meta_stringdata_QDynamicReceiver[] = {
  "QDynamicReceiver\0\0\0\0\0\0" };

struct QDynamicReceiver: public QObject
{
  void *thunk;
  QList<QMetaType::Type> argument_types;
  QMetaObject m;
  char* stringdata;

  static const QMetaObject staticMetaObject;

#ifdef Q_NO_DATA_RELOCATION
  const QMetaObject &getStaticMetaObject() { return staticMetaObject; }
#endif //Q_NO_DATA_RELOCATION

  const QMetaObject *metaObject() const { return &m; }

  void *qt_metacast(const char *_clname);

  QDynamicReceiver(char *name, char *slot, C_word proc);
  ~QDynamicReceiver();

  virtual int qt_metacall(QMetaObject::Call c, int id, void **arguments);

private:
  void setupMetaObject(char *method);
  void fill_types(const QMetaMethod &member);
};

// Nothing interesting here, standard Qt boilerplate
void *QDynamicReceiver::qt_metacast(const char *_clname)
{
  if (!_clname) return 0;
  if (!strcmp(_clname, qt_meta_stringdata_QDynamicReceiver))
    return static_cast<void*>(const_cast< QDynamicReceiver*>(this));
  return QObject::qt_metacast(_clname);
}

void QDynamicReceiver::setupMetaObject(char *method)
{
  m = QMetaObject(staticMetaObject);
  m.d.data = new uint[sizeof(qt_meta_data_QDynamicReceiver)];
  memcpy(const_cast<uint*>(m.d.data), qt_meta_data_QDynamicReceiver,
	 sizeof(qt_meta_data_QDynamicReceiver));

  uint* data = const_cast<uint*>(m.d.data);
  int method_data = data[m.methodOffset()+1];

  QString tmp;

  tmp.append(m.className()).append(QChar::Null);
  data[method_data+3] = tmp.length();
  tmp.append(QChar::Null);
  data[method_data+2] = tmp.length();
  tmp.append(QMetaObject::normalizedType("")).append(QChar::Null);
  // Are parameter names really needed?
  data[method_data+1] = tmp.length();
  tmp.append(QChar::Null);
  data[method_data] = tmp.length();
  tmp.append(QMetaObject::normalizedSignature(method)).append(QChar::Null).append(QChar::Null);

  stringdata = new char[tmp.length()];
  memcpy(stringdata, tmp.toAscii().data(), tmp.length());

  m.d.stringdata = stringdata;
  data[m.methodOffset()] = 1;
}

const QMetaObject QDynamicReceiver::staticMetaObject = {
  { &QObject::staticMetaObject, qt_meta_stringdata_QDynamicReceiver,
    qt_meta_data_QDynamicReceiver, 0 }
};

QDynamicReceiver::QDynamicReceiver(char *name, char *slot, C_word proc)
{
  setObjectName(name);
  thunk = CHICKEN_new_gc_root();
  CHICKEN_gc_root_set(thunk, proc);

  setupMetaObject(slot + 1);
  fill_types(m.method(4));
}

QDynamicReceiver::~QDynamicReceiver()
{
  delete stringdata;
  delete m.d.data;
  CHICKEN_delete_gc_root(thunk);
}

int QDynamicReceiver::qt_metacall(QMetaObject::Call c, int id,
				  void **arguments)
{
  id = QObject::qt_metacall(c, id, arguments);
  if (id < 0 || c != QMetaObject::InvokeMetaMethod)
    return id;

  QVariantList l;
  for(int i = 0; i < argument_types.count(); ++i)
  {
    // TODO This is temporary as I have no idea how Qt wraps
    // pointers passed into qt_metacall
    if(argument_types.at(i))
      l << QVariant(argument_types.at(i), arguments[i + 1]);
  }

  struct f_ : public variantlist_fun { void operator()(C_word o) { C_save(o); } } f;

  int size = 0;
  const int count = l.size();

  for(int i = 0; i < count; ++i)
    size += qt_variantlist_storage(&l, i);

  C_word *storage = C_alloc(size);

  for(int i = 0; i < count; ++i)
    qt_variantlist_do_one(&l, &f, &storage, i);

  l.clear();

  C_callback(CHICKEN_gc_root_ref(thunk), count);
  return -1;
}

void QDynamicReceiver::fill_types(const QMetaMethod &member)
{
  QList<QByteArray> params = member.parameterTypes();
  for (int i = 0; i < params.count(); ++i)
    argument_types << (QMetaType::Type)(QMetaType::type(params.at(i).constData()));
}

class GLWidget: public QGLWidget
{
  void *thunk;

  Q_OBJECT

public:
  GLWidget(char *name, QWidget *parent, C_word proc) : QGLWidget(parent) {
    setObjectName(name);
    thunk = CHICKEN_new_gc_root();
    CHICKEN_gc_root_set(thunk, proc);
  }

  ~GLWidget() { CHICKEN_delete_gc_root(thunk); }

protected:
  // Set up the rendering context, define display lists etc.:
  void initializeGL() { C_save(C_fix(0)); C_callback(CHICKEN_gc_root_ref(thunk), 1); }
  // setup viewport, projection etc.:
  void resizeGL(int w, int h)
  { C_save(C_fix(1)); C_save(C_fix(w)); C_save(C_fix(h));
    C_callback(CHICKEN_gc_root_ref(thunk), 3); }
  // draw the scene:
  void paintGL() { C_save(C_fix(2)); C_callback(CHICKEN_gc_root_ref(thunk), 1); }
};

#define qtobject          QObject *
#define qtapplication     QApplication *
#define qtdynamicreceiver QDynamicReceiver *
#define qtwidget          QWidget *
#define qtpixmap          QPixmap *
#define qttimer           QTimer *
#define qtsound           QSound *
#define qttextedit        QTextEdit *
#define qtaction          QAction *
#define qtvariantlist     QVariantList *
#define qtdbusconnection  QDBusConnection *
#define qtvariantlist     QVariantList *
#define qthttp            QHttp *

#include "prototypes.h"

#include "main.moc"

QApplication *qt_init()
{
  QApplication *app = new QApplication(C_main_argc, C_main_argv);
  QObject::connect(app, SIGNAL(lastWindowClosed()), app, SLOT(quit()));
  return qApp;
}

QWidget *qt_create(char *string, QWidget *parent)
{
  QUiLoader loader;
  QBuffer buf;
  buf.open(QBuffer::ReadWrite);
  buf.write(string);
  buf.seek(0);
  QWidget *w = loader.load(&buf, parent);
  buf.close();
  return w;
}

___bool qt_run(___bool once)
{
  if(once) {
    qApp->processEvents();
    return 1;
  }
  else return qApp->exec();
}

void qt_show(QWidget *w) { w->show(); }
void qt_hide(QWidget *w) { w->show(); }
void qt_deleteobject(QObject *o) { delete o; }
void qt_deletepixmap(QPixmap *o) { delete o; }
___bool qt_connect(QObject *w1, char *sig, QObject *w2, char *slot)
{ return QObject::connect(w1, sig, w2, slot); }
___bool qt_disconnect(QObject *w1, char *sig, QObject *w2, char *slot)
{ return QObject::disconnect(w1, sig, w2, slot); }
QWidget *qt_find(QWidget *parent, char *name)
{ return parent->findChild<QWidget *>(QString(name)); }

QDynamicReceiver *qt_dynamicreceiver(char *name, char *slot, C_word proc)
{ return new QDynamicReceiver(name, slot, proc); }

void qt_variant_list_insert_back_int(QVariantList *l, int a) { *l << a; }
void qt_variant_list_insert_back_string(QVariantList *l, char *s) { *l << s; }
void qt_variant_list_insert_back_bool(QVariantList *l, int a) { *l << (bool)a; }
void qt_variant_list_insert_back_uint(QVariantList *l, int a) { *l << (unsigned)a; }
void qt_variant_list_insert_back_double(QVariantList *l, double a) { *l << a; }

QVariantList* qt_make_variantlist() { return new QVariantList; }
void qt_destroy_variantlist(QVariantList *l) { delete l; }

void qt_variant_list_discard_front(QVariantList *l) { l->pop_front(); }
int qt_variant_list_length(QVariantList *l) { return l->length(); }

QDBusConnection *qt_dbus_session_bus()
{ return new QDBusConnection(QDBusConnection::sessionBus()); }
QDBusConnection *qt_dbus_system_bus()
{ return new QDBusConnection(QDBusConnection::systemBus()); }
void qt_destroy_dbus_connection(QDBusConnection *c) { delete c; }

___bool qt_c_dbus_connect(QDBusConnection *c,
			char *service, char *object,
			char *interface, char *signal,
			QObject *w2, char *slot)
{ return c->connect(service, object, interface, signal, w2, slot); }
___bool qt_dbus_disconnect(QDBusConnection *c,
			     char *service, char *object,
			   char *interface, char *signal,
			   QObject *w2, char *slot)
{ return c->disconnect(service, object, interface, signal, w2, slot); }
void qt_c_dbus_list_names(QDBusConnection *bus, QVariantList* l)
{
  QStringList serviceNames = bus->interface()->registeredServiceNames();
  for(int i = 0; i < serviceNames.length(); ++i)
    *l << *(new QString(serviceNames.at(i)));
}
___bool qt_c_dbus_send_signal(QDBusConnection *bus, char *object,
			    char *interface, char *signal, QVariantList* l)
{
  QDBusMessage message = QDBusMessage::createSignal(object, interface, signal);
  message.setArguments(*l);
  return bus->send(message);
}

___bool qt_dbus_register_object(QDBusConnection *bus, char *path, QObject *obj)
{ return bus->registerObject(path, obj, QDBusConnection::ExportAllSlots); }
void qt_dbus_unregister_object(QDBusConnection *bus, char *path)
{ bus->unregisterObject(path); }
___bool qt_dbus_method_call(QDBusConnection *bus, char *service, char *path,
			    char *interface, char *method, QVariantList* l)
{
  QDBusMessage msg = QDBusMessage::createMethodCall(service, path, interface, method);
  msg.setArguments(*l);

  QDBusMessage reply = bus->call(msg, QDBus::BlockWithGui);
  l->clear();
  l->push_back((int)reply.type());
  if(QDBusMessage::ErrorMessage == reply.type())
    l->push_back(reply.errorName());
  if(reply.arguments().length() && reply.arguments().at(0).isValid())
    l->append(reply.arguments());
  return (reply.type() != QDBusMessage::ErrorMessage
	  && reply.type() != QDBusMessage::InvalidMessage);
}

___bool qt_dbus_method_call_with_callback(QDBusConnection *bus, char *service, char *path,
						  char *interface, char *method, QVariantList *l,
						  QObject *obj, char *slot)
{
  QDBusMessage msg = QDBusMessage::createMethodCall(service, path, interface, method);
  msg.setArguments(*l);
  return bus->callWithCallback(msg, obj, slot);
}


___bool qt_dbus_register_service(QDBusConnection *bus, char *service)
{ return bus->interface()->registerService(service); }
___bool qt_dbus_unregister_service(QDBusConnection *bus, char *service)
{ return bus->unregisterService(service); }

___bool qt_invokemethod(QObject *o, char *signal, QVariantList *arguments)
{
  int idx = o->metaObject()->indexOfMethod(signal+1);

  if(idx < 0) return false;

  const char *typeName = o->metaObject()->method(idx).typeName();
  int resultType = QMetaType::type(typeName);
  void *result = QMetaType::construct(resultType, 0);

  QList<QGenericArgument> genericArgs;

  for(QList<QVariant>::ConstIterator iter = arguments->begin();
      iter != arguments->end();
      ++iter)
    genericArgs << QGenericArgument(iter->typeName(),iter->data());

  QGenericReturnArgument ret( typeName, result );
  QByteArray signature = o->metaObject()->method(idx).signature();

  if(QMetaObject::invokeMethod(o,
			       signature.left(signature.indexOf('(')),
			       ret,
			       genericArgs.value(0, QGenericArgument()),
			       genericArgs.value(1, QGenericArgument()),
			       genericArgs.value(2, QGenericArgument()),
			       genericArgs.value(3, QGenericArgument()),
			       genericArgs.value(4, QGenericArgument()),
			       genericArgs.value(5, QGenericArgument()),
			       genericArgs.value(6, QGenericArgument()),
			       genericArgs.value(7, QGenericArgument()),
			       genericArgs.value(8, QGenericArgument()),
			       genericArgs.value(9, QGenericArgument())))
  {
    QVariant returnValue(resultType, result);
    QMetaType::destroy(resultType, result);
    if(resultType != QVariant::Invalid)
      arguments->push_front(returnValue);
    return true;
  }

  QMetaType::destroy(resultType, result);
  qDebug("No such method '%s'", signal+1 );
  return false;
}

static char *qstrdata(const QString &str);
int qstrdata_size(const QString &str);

static int qt_variantlist_storage(QVariantList* l, int i)
{
  switch(l->at(i).type())
  {
  case QVariant::Int:
  case QVariant::UInt:
  case QVariant::Bool:
    return 0;
  case QVariant::Double:
    return C_SIZEOF_FLONUM;
  case QVariant::String:
    return C_SIZEOF_STRING(qstrdata_size(l->at(i).toString()));
  default:
    printf("QVariantList (size) doesn't know how to convert  '%s'(%d) into a chicken type\n",
	   l->at(i).typeName(), l->at(i).type());
    exit(1);
  }
}

static void qt_variantlist_do_one(QVariantList* l, variantlist_fun* fun, C_word **storage, int i)
{
  C_word w;

  switch(l->at(i).type())
  {
  case QVariant::Int: w = C_fix(l->at(i).toInt()); break;
    // TODO C_fix is signed, this might overflow, what's the unsigned version?
  case QVariant::UInt: w = C_fix(l->at(i).toUInt()); break;
  case QVariant::Bool: w = C_mk_bool(l->at(i).toBool()); break;
  case QVariant::Double: w = C_flonum((C_word**)storage, l->at(i).toDouble()); break;
  case QVariant::String:
      w = C_string((C_word**)storage, qstrdata_size(l->at(i).toString()),
		   qstrdata(l->at(i).toString())); break;
  default:
    printf("QVariantList doesn't know how to convert  '%s'(%d) into a chicken type\n",
	   l->at(i).typeName(), l->at(i).type());
    exit(1);
  }

  (*fun)(w);
}

void qt_variantlist_remove_front(C_word c, C_word self, C_word k, C_word cl)
{
  QVariantList* l = (QVariantList*)C_pointer_address(cl);

  struct f_ : public variantlist_fun
  {
    C_word k;
    QVariantList* l;
    f_(C_word k_, QVariantList* l_) : k(k_), l(l_) {}
    void operator()(C_word o) { l->pop_front(); C_kontinue(k, o); }
  } f(k, l);

  C_word *storage = C_alloc(qt_variantlist_storage(l, 0));
  qt_variantlist_do_one(l, &f, &storage, 0);
}

static char *qstrdata(const QString &str)
{
  static char *strbuf = NULL;
  static int strbuflen = 0;

  int len = qstrdata_size(str);

  if(strbuf == NULL || strbuflen < (len + 1)) {
    strbuf = (char *)realloc(strbuf, strbuflen = (len + 1));
    assert(strbuf != NULL);
  }

  char *ptr;

  switch(qt_char_encoding) {
  case 1: ptr = str.toLatin1().data(); break;
  case 2: ptr = str.toUtf8().data(); break;
  default: ptr = str.toAscii().data(); break;
  }

  memcpy(strbuf, ptr, len + 1);
  return strbuf;
}

int qstrdata_size(const QString &str)
{
  QByteArray arr;
  switch(qt_char_encoding) {
  case 1: arr = str.toLatin1(); break;
  case 2: arr = str.toUtf8(); break;
  default: arr = str.toAscii(); break;
  }

  return arr.size();
}

int qchrdata(const QChar chr)
{
  switch(qt_char_encoding) {

  case 1: return chr.toLatin1(); break;
  case 2: return chr.unicode(); break;
  default: return chr.toAscii(); break;
  }
}


qtpixmap qt_pixmap(char *filename)
{
  QPixmap *px = new QPixmap(filename);

  if(px->isNull()) {
    delete px;
    return 0;
  }

  return px;
}


int qt_message(char *caption, char *text, QWidget *parent, char *b0, char *b1, char *b2)
{
  return QMessageBox::information(parent, caption, text, b0, b1, b2);
}


#define propsetter(name, type)						\
  ___bool qt_set ## name ## property(QWidget *w, char *prop, type val)	\
  {									\
    const QMetaObject *mo = w->metaObject();				\
    int i = mo->indexOfProperty(prop);					\
    if(i == -1) return 0;						\
    else return mo->property(i).write(w, val);				\
  }


propsetter(string, char *)
propsetter(bool, ___bool)
propsetter(int, int)
propsetter(float, double)
propsetter(char, char)


___bool qt_setpixmapproperty(QWidget *w, char *prop, qtpixmap val)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  if(i == -1) return 0;
  else return mo->property(i).write(w, *val);
}


___bool qt_setpointproperty(QWidget *w, char *prop, int *val)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  if(i == -1) return 0;
  else {
    switch(mo->property(i).type()) {
    case QVariant::Point: return mo->property(i).write(w, QPoint(val[ 0 ], val[ 1 ]));
    case QVariant::Size: return mo->property(i).write(w, QSize(val[ 0 ], val[ 1 ]));
    default: return false;
    }
  }
}


___bool qt_setpointfproperty(QWidget *w, char *prop, double *val)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  if(i == -1) return 0;
  else {
    switch(mo->property(i).type()) {
    case QVariant::PointF: return mo->property(i).write(w, QPointF(val[ 0 ], val[ 1 ]));
    case QVariant::SizeF: return mo->property(i).write(w, QSizeF(val[ 0 ], val[ 1 ]));
    default: return false;
    }
  }
}


___bool qt_setrectproperty(QWidget *w, char *prop, int *val)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  if(i == -1) return 0;
  else return mo->property(i).write(w, QRect(val[ 0 ], val[ 1 ], val[ 2 ], val[ 3 ]));
}


___bool qt_setrectfproperty(QWidget *w, char *prop, double *val)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  if(i == -1) return 0;
  else return mo->property(i).write(w, QRectF(val[ 0 ], val[ 1 ], val[ 2 ], val[ 3 ]));
}


char *qt_getstringproperty(QWidget *w, char *prop)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  return qstrdata(mo->property(i).read(w).toString());
}


int qt_getcharproperty(QWidget *w, char *prop)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  return qchrdata(mo->property(i).read(w).toChar());
}


int qt_getintproperty(QWidget *w, char *prop)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  return mo->property(i).read(w).toInt();
}


double qt_getfloatproperty(QWidget *w, char *prop)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  return mo->property(i).read(w).toDouble();
}


___bool qt_getboolproperty(QWidget *w, char *prop)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  return mo->property(i).read(w).toBool();
}


qtpixmap qt_getpixmapproperty(QWidget *w, char *prop)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  return new QPixmap(mo->property(i).read(w).value<QPixmap>());
}


C_word qt_getpointfproperty(QWidget *w, char *prop, C_word pt)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  QPointF qpt = mo->property(i).read(w).toPointF();
  *((double *)C_data_pointer(C_block_item(pt, 1))) = qpt.x();
  ((double *)C_data_pointer(C_block_item(pt, 1)))[ 1 ] = qpt.y();
  return pt;
}


C_word qt_getpointproperty(QWidget *w, char *prop, C_word pt)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  QPoint qpt = mo->property(i).read(w).toPoint();
  *((int *)C_data_pointer(C_block_item(pt, 1))) = qpt.x();
  ((int *)C_data_pointer(C_block_item(pt, 1)))[ 1 ] = qpt.y();
  return pt;
}


C_word qt_getrectfproperty(QWidget *w, char *prop, C_word pt)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  QRectF qpt = mo->property(i).read(w).toRectF();
  *((double *)C_data_pointer(C_block_item(pt, 1))) = qpt.x();
  ((double *)C_data_pointer(C_block_item(pt, 1)))[ 1 ] = qpt.y();
  ((double *)C_data_pointer(C_block_item(pt, 1)))[ 2 ] = qpt.width();
  ((double *)C_data_pointer(C_block_item(pt, 1)))[ 3 ] = qpt.height();
  return pt;
}


C_word qt_getrectproperty(QWidget *w, char *prop, C_word pt)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  QRect qpt = mo->property(i).read(w).toRect();
  *((int *)C_data_pointer(C_block_item(pt, 1))) = qpt.x();
  ((int *)C_data_pointer(C_block_item(pt, 1)))[ 1 ] = qpt.y();
  ((int *)C_data_pointer(C_block_item(pt, 1)))[ 2 ] = qpt.width();
  ((int *)C_data_pointer(C_block_item(pt, 1)))[ 3 ] = qpt.height();
  return pt;
}


C_word qt_getsizefproperty(QWidget *w, char *prop, C_word pt)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  QSizeF qpt = mo->property(i).read(w).toSizeF();
  *((double *)C_data_pointer(C_block_item(pt, 1))) = qpt.width();
  ((double *)C_data_pointer(C_block_item(pt, 1)))[ 1 ] = qpt.height();
  return pt;
}


C_word qt_getsizeproperty(QWidget *w, char *prop, C_word pt)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);
  QSize qpt = mo->property(i).read(w).toSize();
  *((int *)C_data_pointer(C_block_item(pt, 1))) = qpt.width();
  ((int *)C_data_pointer(C_block_item(pt, 1)))[ 1 ] = qpt.height();
  return pt;
}


int qt_propertytype(qtwidget w, char *prop)
{
  const QMetaObject *mo = w->metaObject();
  int i = mo->indexOfProperty(prop);

  if(i == -1) return 0;
  else {
    switch(mo->property(i).type()) {
    case QVariant::Bool: return 1;
    case QVariant::Char: return 2;
    case QVariant::Double: return 3;
    case QVariant::Int:
    case QVariant::UInt: return 4;
    case QVariant::LongLong:
    case QVariant::ULongLong: return 3;
    case QVariant::String: return 5;
    case QVariant::Pixmap: return 6;
    case QVariant::PointF: return 7;
    case QVariant::RectF: return 8;
    case QVariant::SizeF: return 9;
    case QVariant::Point: return 10;
    case QVariant::Size: return 11;
    case QVariant::Rect: return 12;
    default: return 0;
    }
  }
}

const char *qt_classname(qtobject w) { return w->metaObject()->className(); }
qtwidget qt_gl(char *name, qtwidget parent, C_word proc) { return new GLWidget(name, parent, proc); }
void qt_update(qtwidget w) { w->update(); }

qttimer qt_make_timer(double secs)
{
  QTimer *tm = new QTimer();
  tm->setInterval((int)(secs * 1000));
  return tm;
}

void qt_destroy_timer(qttimer timer) { delete timer; }

void qt_start(qttimer t) { t->start(); }
void qt_stoptimer(qttimer t) { t->stop(); }
void qt_stopsound(qtsound t) { t->stop(); }
void qt_clearlistwidget(qtwidget w) { ((QListWidget *)w)->clear(); }
void qt_addcomboboxitem(qtwidget w, char *s) { ((QComboBox *)w)->addItem(s); }
void qt_addlistwidgetitem(qtwidget w, char *s) { ((QListWidget *)w)->addItem(s); }

void qt_addtreewidgetitem(qtwidget w, char *s)
{
  QStringList lst = QString(s).split("|");
  ((QTreeWidget *)w)->addTopLevelItem(new QTreeWidgetItem(lst));
}

char *qt_listwidgetitem(qtwidget w, int i) {
  return qstrdata(((QListWidget *)w)->item(i)->text());
}

qtsound qt_sound(char *filename) { return new QSound(filename); }
void qt_play(qtsound s) { s->play(); }


char *qt_getexistingdirectory(qtwidget p, char *cap, char *dir, int opts)
{
  return qstrdata(QFileDialog::getExistingDirectory(p, cap, dir, (QFileDialog::Option)opts));
}


char *qt_getopenfilename(qtwidget p, char *cap, char *dir, char *filter, int opts)
{
  return qstrdata(QFileDialog::getOpenFileName(p, cap, dir, filter, 0, (QFileDialog::Options)opts));
}


char *qt_getsavefilename(qtwidget p, char *cap, char *dir, char *filter, int opts)
{
  return qstrdata(QFileDialog::getSaveFileName(p, cap, dir, filter, 0, (QFileDialog::Options)opts));
}


void qt_setheaders(qtwidget w, char *s) { ((QTreeWidget *)w)->setHeaderLabels(QString(s).split("|")); }


char *qt_selection(qttextedit t)
{
  QString txt = ((QTextEdit *)t)->textCursor().selectedText();
  txt.replace(QChar(QChar::ParagraphSeparator), '\n');
  return qstrdata(txt);
}


void qt_insert(qttextedit t, char *s)
{
  QTextEdit *te = (QTextEdit *)t;
  QTextCursor c = te->textCursor();
  c.insertText(s);
}


qtaction qt_shortcut(qtwidget w, char *key)
{
  QAction *a = new QAction(w);
  a->setShortcut(QKeySequence(key));
  return a;
}


void qt_add_action(qtwidget w, qtaction a) { ((QWidget *)w)->addAction((QAction *)a); }
void qt_remove_action(qtwidget w, qtaction a) { ((QWidget *)w)->removeAction((QAction *)a); }


int qt_charencoding(int mode)
{
  if(mode) return qt_char_encoding = mode;
  else return qt_char_encoding;
}

void qt_attribute(qtwidget w, int attribute, int set)
{
  ((QWidget*)w)->setAttribute((Qt::WidgetAttribute)attribute, set);
}

int qt_testattribute(qtwidget w, int attribute)
{
  return ((QWidget*)w)->testAttribute((Qt::WidgetAttribute)attribute);
}

int qt_window_flags(qtwidget w)
{
  return ((QWidget*)w)->windowFlags();
}

void qt_set_window_flags(qtwidget w, int f)
{
  ((QWidget*)w)->setWindowFlags((Qt::WindowFlags)f);
}

qtwidget qt_desktop() { return QApplication::desktop(); }

QHttp* qt_make_http() { return new QHttp(); }
void qt_destroy_http(QHttp *h) { delete h; }
int qt_http_set_host(QHttp *h, char *host, int port) { return h->setHost(host, port); }
int qt_http_get(QHttp *h, char *url) { return h->get(QUrl(url).toEncoded()); }
// blob version
char *qt_http_read_bytes(QHttp *h) { return h->readAll().data(); }
char *qt_http_read_string(QHttp *h) { return qstrdata(QString(h->readAll().data())); }
