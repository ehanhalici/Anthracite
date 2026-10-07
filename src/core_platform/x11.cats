#ifndef ANTH_X11_CATS
#define ANTH_X11_CATS

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/keysym.h>
#define GL_GLEXT_PROTOTYPES 1
#include <GL/gl.h>
#include <GL/glx.h>
#include <poll.h>
#include <signal.h>
#include <string.h>
#include <stdio.h>

static volatile sig_atomic_t anth_sig_exit = 0;

static void anth_sig_handler(int sig) {
  (void)sig;
  anth_sig_exit = 1;
}

static inline void anth_install_signals(void) {
  struct sigaction sa;
  memset(&sa, 0, sizeof sa);
  sa.sa_handler = anth_sig_handler;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = 0;
  sigaction(SIGINT, &sa, NULL);
  sigaction(SIGTERM, &sa, NULL);
  sigaction(SIGHUP, &sa, NULL);
  sigaction(SIGQUIT, &sa, NULL);
}

static inline int anth_sig_received(void) {
  return anth_sig_exit ? 1 : 0;
}

#define ANTH_EV_NONE 0
#define ANTH_EV_CLOSE 1
#define ANTH_EV_RESIZE 2
#define ANTH_EV_EXPOSE 3
#define ANTH_EV_KEY 4
#define ANTH_EV_DOWN 5
#define ANTH_EV_UP 6
#define ANTH_EV_MOTION 7
#define ANTH_EV_WHEEL 8
#define ANTH_EV_SEL_REQ 9
#define ANTH_EV_SEL_NOTIFY 10
#define ANTH_EV_SEL_CLEAR 11

typedef struct anth_event {
  int kind;
  int x, y, w, h;
  int button;
  int mods;
  int text_n;
  unsigned long keysym;
  unsigned long atom0;
  unsigned long atom1;
  unsigned long atom2;
  unsigned long win;
  unsigned long timev;
  char text[64];
} anth_event;

static int anth_xerr(Display *d, XErrorEvent *e) {
  (void)d;
  fprintf(stderr, "anthracite: x error %u major %u\n", e->error_code, e->request_code);
  return 0;
}

static inline void anth_xerr_install(void) { XSetErrorHandler(anth_xerr); }
static inline int anth_alloc_none(void) { return AllocNone; }

static inline int anth_choose_fb(Display *dpy, int screen,
    void **fb, void **visual, void **vi_keep, void **list, int *depth) {
  int attribs[] = {
    GLX_X_RENDERABLE, True,
    GLX_DRAWABLE_TYPE, GLX_WINDOW_BIT,
    GLX_RENDER_TYPE, GLX_RGBA_BIT,
    GLX_X_VISUAL_TYPE, GLX_TRUE_COLOR,
    GLX_RED_SIZE, 8,
    GLX_GREEN_SIZE, 8,
    GLX_BLUE_SIZE, 8,
    GLX_ALPHA_SIZE, 8,
    GLX_DEPTH_SIZE, 0,
    GLX_DOUBLEBUFFER, True,
    None
  };
  int n = 0;
  GLXFBConfig *fbs = glXChooseFBConfig(dpy, screen, attribs, &n);
  if (!fbs || n <= 0) return 0;
  XVisualInfo *vi = glXGetVisualFromFBConfig(dpy, fbs[0]);
  if (!vi) { XFree(fbs); return 0; }
  *fb = fbs[0];
  *visual = vi->visual;
  *vi_keep = vi;
  *list = fbs;
  *depth = vi->depth;
  return 1;
}

static inline unsigned long anth_ulint0(void) { return 0; }

static inline unsigned long anth_create_window(Display *dpy, unsigned long root,
    void *visual, int depth, int x, int y, int w, int h, unsigned long cmap) {
  unsigned uw = w > 0 ? (unsigned)w : 1;
  unsigned uh = h > 0 ? (unsigned)h : 1;
  w = (int)uw;
  h = (int)uh;
  XSetWindowAttributes swa;
  memset(&swa, 0, sizeof swa);
  swa.colormap = (Colormap)cmap;
  swa.event_mask =
    ExposureMask | KeyPressMask | KeyReleaseMask |
    ButtonPressMask | ButtonReleaseMask | PointerMotionMask |
    StructureNotifyMask | FocusChangeMask | PropertyChangeMask;
  swa.background_pixmap = None;
  return (unsigned long)XCreateWindow(
    dpy, (Window)root, x, y, w, h, 0, depth, InputOutput, (Visual *)visual,
    CWColormap | CWEventMask | CWBackPixmap, &swa);
}

static inline void anth_wm(Display *dpy, unsigned long win, unsigned long atom) {
  Atom a = (Atom)atom;
  XSetWMProtocols(dpy, (Window)win, &a, 1);
  XSizeHints *h = XAllocSizeHints();
  if (h) {
    h->flags = PMinSize;
    h->min_width = 640;
    h->min_height = 400;
    XSetWMNormalHints(dpy, (Window)win, h);
    XFree(h);
  }
}

#ifndef GLX_CONTEXT_MAJOR_VERSION_ARB
#define GLX_CONTEXT_MAJOR_VERSION_ARB 0x2091
#define GLX_CONTEXT_MINOR_VERSION_ARB 0x2092
#define GLX_CONTEXT_PROFILE_MASK_ARB 0x9126
#define GLX_CONTEXT_CORE_PROFILE_BIT_ARB 0x00000001
#endif

static inline void *anth_create_ctx(Display *dpy, void *fb) {
  typedef GLXContext (*fn_t)(Display *, GLXFBConfig, GLXContext, Bool, const int *);
  fn_t fn = (fn_t)glXGetProcAddressARB((const GLubyte *)"glXCreateContextAttribsARB");
  if (!fn) return 0;
  int attribs[] = {
    GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
    GLX_CONTEXT_MINOR_VERSION_ARB, 3,
    GLX_CONTEXT_PROFILE_MASK_ARB, GLX_CONTEXT_CORE_PROFILE_BIT_ARB,
    None
  };
  return fn(dpy, (GLXFBConfig)fb, 0, True, attribs);
}

static inline int anth_make_current(Display *dpy, unsigned long win, void *ctx) {
  return glXMakeCurrent(dpy, (GLXDrawable)win, (GLXContext)ctx);
}
static inline void anth_swap(Display *dpy, unsigned long win) {
  glXSwapBuffers(dpy, (GLXDrawable)win);
}
static inline void anth_destroy_ctx(Display *dpy, void *ctx) {
  if (ctx) glXDestroyContext(dpy, (GLXContext)ctx);
}
static inline void anth_vsync(Display *dpy, unsigned long win) {
  typedef void (*fn_t)(Display *, GLXDrawable, int);
  fn_t fn = (fn_t)glXGetProcAddressARB((const GLubyte *)"glXSwapIntervalEXT");
  if (fn) fn(dpy, (GLXDrawable)win, 1);
}

static inline void anth_open_im(Display *dpy, unsigned long win, void **im, void **ic) {
  *im = 0;
  *ic = 0;
  XSetLocaleModifiers("");
  XIM xim = XOpenIM(dpy, 0, 0, 0);
  if (!xim) return;
  XIC xic = XCreateIC(xim,
    XNInputStyle, (XIMPreeditNothing | XIMStatusNothing),
    XNClientWindow, (Window)win,
    NULL);
  *im = xim;
  *ic = xic;
}
static inline void anth_close_im(void *im, void *ic) {
  if (ic) XDestroyIC((XIC)ic);
  if (im) XCloseIM((XIM)im);
}

static inline int anth_fd(Display *dpy) { return ConnectionNumber(dpy); }
static inline int anth_poll(int fd, int ms) {
  if (anth_sig_exit) return 0;
  struct pollfd p;
  p.fd = fd;
  p.events = POLLIN;
  p.revents = 0;
  int r = poll(&p, 1, ms);
  if (anth_sig_exit) return 0;
  return r;
}

static inline void anth_next(Display *dpy, void *ic, unsigned long wm, anth_event *out) {
  XEvent e;
  XNextEvent(dpy, &e);
  memset(out, 0, sizeof *out);
  if (XFilterEvent(&e, None)) return;
  if (e.type == KeyPress) {
    out->kind = ANTH_EV_KEY;
    out->x = e.xkey.x;
    out->y = e.xkey.y;
    out->mods = (int)e.xkey.state;
    KeySym ks = 0;
    int n = 0;
    if (ic) {
      Status st = 0;
      n = Xutf8LookupString((XIC)ic, &e.xkey, out->text, 63, &ks, &st);
      if (n < 0) n = 0;
    } else {
      n = XLookupString(&e.xkey, out->text, 63, &ks, 0);
    }
    if (ks == 0) {
      ks = XLookupKeysym(&e.xkey, 0);
    }
    out->text_n = n;
    out->text[n] = 0;
    out->keysym = (unsigned long)ks;
  } else if (e.type == ButtonPress || e.type == ButtonRelease) {
    out->x = e.xbutton.x;
    out->y = e.xbutton.y;
    out->mods = (int)e.xbutton.state;
    out->button = e.xbutton.button;
    if ((e.xbutton.button == 4 || e.xbutton.button == 5) && e.type == ButtonPress)
      out->kind = ANTH_EV_WHEEL;
    else if (e.xbutton.button < 4)
      out->kind = (e.type == ButtonPress) ? ANTH_EV_DOWN : ANTH_EV_UP;
  } else if (e.type == MotionNotify) {
    out->kind = ANTH_EV_MOTION;
    out->x = e.xmotion.x;
    out->y = e.xmotion.y;
    out->mods = (int)e.xmotion.state;
  } else if (e.type == ConfigureNotify) {
    out->kind = ANTH_EV_RESIZE;
    out->w = e.xconfigure.width;
    out->h = e.xconfigure.height;
  } else if (e.type == Expose) {
    if (e.xexpose.count == 0) out->kind = ANTH_EV_EXPOSE;
  } else if (e.type == ClientMessage) {
    if ((Atom)e.xclient.data.l[0] == (Atom)wm) out->kind = ANTH_EV_CLOSE;
  } else if (e.type == SelectionRequest) {
    out->kind = ANTH_EV_SEL_REQ;
    out->atom0 = e.xselectionrequest.selection;
    out->atom1 = e.xselectionrequest.target;
    out->atom2 = e.xselectionrequest.property;
    out->win = e.xselectionrequest.requestor;
    out->timev = e.xselectionrequest.time;
  } else if (e.type == SelectionNotify) {
    out->kind = ANTH_EV_SEL_NOTIFY;
    out->atom0 = e.xselection.selection;
    out->atom1 = e.xselection.target;
    out->atom2 = e.xselection.property;
  } else if (e.type == SelectionClear) {
    out->kind = ANTH_EV_SEL_CLEAR;
    out->atom0 = e.xselectionclear.selection;
  }
}

static inline int anth_ev_kind(anth_event *e) { return e->kind; }
static inline int anth_ev_x(anth_event *e) { return e->x; }
static inline int anth_ev_y(anth_event *e) { return e->y; }
static inline int anth_ev_w(anth_event *e) { return e->w; }
static inline int anth_ev_h(anth_event *e) { return e->h; }
static inline int anth_ev_button(anth_event *e) { return e->button; }
static inline int anth_ev_mods(anth_event *e) { return e->mods; }
static inline int anth_ev_text_n(anth_event *e) { return e->text_n; }
static inline unsigned long anth_ev_keysym(anth_event *e) { return e->keysym; }
static inline unsigned long anth_ev_atom0(anth_event *e) { return e->atom0; }
static inline unsigned long anth_ev_atom1(anth_event *e) { return e->atom1; }
static inline unsigned long anth_ev_atom2(anth_event *e) { return e->atom2; }
static inline unsigned long anth_ev_win(anth_event *e) { return e->win; }
static inline int anth_ev_text(anth_event *e, void *dst, int n) {
  int k;
  if (!e || !dst || n <= 0) return 0;
  k = e->text_n;
  if (k < 0) k = 0;
  if (k > n) k = n;
  if (k > 63) k = 63;
  if (k > 0) memcpy(dst, e->text, (size_t)k);
  return k;
}

static inline int anth_ev_key_char(anth_event *e) {
  if (!e) return 0;
  unsigned long ks = e->keysym;
  if (ks >= 'a' && ks <= 'z') return (int)ks;
  if (ks >= 'A' && ks <= 'Z') return (int)(ks - 'A' + 'a');
  if (ks >= '0' && ks <= '9') return (int)ks;
  return 0;
}
static inline int anth_shift_on(anth_event *e) {
  return (e && (e->mods & ShiftMask)) ? 1 : 0;
}
static inline int anth_ctrl_on(anth_event *e) {
  return (e && (e->mods & ControlMask)) ? 1 : 0;
}

#define ANTH_KEYSYM_ISO_LEFT_TAB 0xFE20UL

enum anth_key {
  ANTH_KEY_LEFT,
  ANTH_KEY_RIGHT,
  ANTH_KEY_UP,
  ANTH_KEY_DOWN,
  ANTH_KEY_BACKSPACE,
  ANTH_KEY_DELETE,
  ANTH_KEY_HOME,
  ANTH_KEY_END,
  ANTH_KEY_RETURN,
  ANTH_KEY_TAB,
  ANTH_KEY_ESCAPE,
  ANTH_KEY_PAGE_UP,
  ANTH_KEY_PAGE_DOWN
};

static inline int anth_key_is(anth_event *e, int key) {
  if (!e) return 0;
  unsigned long ks = e->keysym;
  switch (key) {
  case ANTH_KEY_LEFT: return ks == XK_Left || ks == XK_KP_Left;
  case ANTH_KEY_RIGHT: return ks == XK_Right || ks == XK_KP_Right;
  case ANTH_KEY_UP: return ks == XK_Up || ks == XK_KP_Up;
  case ANTH_KEY_DOWN: return ks == XK_Down || ks == XK_KP_Down;
  case ANTH_KEY_BACKSPACE: return ks == XK_BackSpace;
  case ANTH_KEY_DELETE: return ks == XK_Delete || ks == XK_KP_Delete;
  case ANTH_KEY_HOME: return ks == XK_Home || ks == XK_KP_Home;
  case ANTH_KEY_END: return ks == XK_End || ks == XK_KP_End;
  case ANTH_KEY_RETURN: return ks == XK_Return || ks == XK_KP_Enter;
  case ANTH_KEY_TAB: return ks == XK_Tab || ks == XK_KP_Tab || ks == ANTH_KEYSYM_ISO_LEFT_TAB;
  case ANTH_KEY_ESCAPE: return ks == XK_Escape;
  case ANTH_KEY_PAGE_UP: return ks == XK_Page_Up || ks == XK_KP_Page_Up;
  case ANTH_KEY_PAGE_DOWN: return ks == XK_Page_Down || ks == XK_KP_Page_Down;
  default: return 0;
  }
}
static inline int anth_mod_ctrl(void) { return ControlMask; }
static inline int anth_mod_shift(void) { return ShiftMask; }

static inline void anth_sel_reply(Display *dpy, anth_event *ev,
    const unsigned char *data, int n, unsigned long utf8, unsigned long targets,
    unsigned long png) {
  XSelectionEvent sev;
  memset(&sev, 0, sizeof sev);
  sev.type = SelectionNotify;
  sev.display = dpy;
  sev.requestor = (Window)ev->win;
  sev.selection = (Atom)ev->atom0;
  sev.target = (Atom)ev->atom1;
  sev.time = ev->timev;
  sev.property = (Atom)ev->atom2;
  if ((Atom)ev->atom1 == (Atom)targets) {
    Atom arr[3];
    arr[0] = (Atom)utf8;
    arr[1] = XA_STRING;
    arr[2] = (Atom)png;
    XChangeProperty(dpy, sev.requestor, sev.property, XA_ATOM, 32,
      PropModeReplace, (unsigned char *)arr, 3);
  } else if ((Atom)ev->atom1 == (Atom)utf8 || (Atom)ev->atom1 == XA_STRING) {
    XChangeProperty(dpy, sev.requestor, sev.property, (Atom)ev->atom1, 8,
      PropModeReplace, data ? data : (const unsigned char *)"", n > 0 ? n : 0);
  } else if ((Atom)ev->atom1 == (Atom)png && data && n > 0) {
    XChangeProperty(dpy, sev.requestor, sev.property, (Atom)png, 8,
      PropModeReplace, data, n);
  } else {
    sev.property = None;
  }
  XSendEvent(dpy, sev.requestor, False, 0, (XEvent *)&sev);
  XFlush(dpy);
}

static inline int anth_sel_read(Display *dpy, unsigned long win, unsigned long prop,
    void *dst, int cap) {
  Atom actual = None;
  int format = 0;
  unsigned long n = 0, rem = 0;
  unsigned char *data = 0;
  if (!dpy || !dst || cap <= 0 || !prop) return 0;
  int r = XGetWindowProperty(dpy, (Window)win, (Atom)prop, 0, 1 << 20, True,
    AnyPropertyType, &actual, &format, &n, &rem, &data);
  if (r != Success || !data) {
    if (data) XFree(data);
    return 0;
  }
  int nbytes = (format == 8) ? (int)n : (int)(n * (unsigned long)(format / 8));
  if (nbytes < 0) nbytes = 0;
  if (nbytes > cap) nbytes = cap;
  if (nbytes > 0) memcpy(dst, data, (size_t)nbytes);
  XFree(data);
  return nbytes;
}

static inline void anth_sel_convert(Display *dpy, unsigned long win,
    unsigned long sel, unsigned long target, unsigned long prop) {
  XConvertSelection(dpy, (Atom)sel, (Atom)target, (Atom)prop, (Window)win, CurrentTime);
}
static inline void anth_sel_own(Display *dpy, unsigned long sel, unsigned long win) {
  XSetSelectionOwner(dpy, (Atom)sel, (Window)win, CurrentTime);
}

#endif
