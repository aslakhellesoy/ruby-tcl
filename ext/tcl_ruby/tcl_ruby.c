#include <ruby.h>
#include <tcl.h>

typedef struct {
  Tcl_Interp *interp;
  VALUE exit_exception;
} tcl_interp_struct;

static VALUE rb_value_to_s(VALUE value) {
  return rb_funcall(value, rb_intern("to_s"), 0, 0);
}

static void rb_tcl_interp_destroy(tcl_interp_struct *tcl_interp) {
  Tcl_DeleteInterp(tcl_interp->interp);
  Tcl_Release(tcl_interp->interp);
  free(tcl_interp);
}

static VALUE rb_tcl_interp_send_begin(VALUE args) {
  VALUE obj = rb_ary_entry(args, 0);
  VALUE interp_receive_args = rb_ary_entry(args, 1);
  
  VALUE result = rb_funcall2(obj, rb_intern("interp_receive"), RARRAY(interp_receive_args)->len, RARRAY(interp_receive_args)->ptr);
  
  tcl_interp_struct *tcl_interp;
  Data_Get_Struct(obj, tcl_interp_struct, tcl_interp);

  char *tcl_result = strdup(RSTRING(rb_value_to_s(result))->ptr);
  Tcl_SetResult(tcl_interp->interp, tcl_result, (Tcl_FreeProc *)free);
  
  return Qtrue;
}

static VALUE rb_tcl_interp_send_rescue(VALUE args, VALUE error_info) {
  VALUE obj = rb_ary_entry(args, 0);
  tcl_interp_struct *tcl_interp;
  Data_Get_Struct(obj, tcl_interp_struct, tcl_interp);
  
  char *tcl_result = strdup(RSTRING(rb_value_to_s(error_info))->ptr);
  Tcl_SetResult(tcl_interp->interp, tcl_result, (Tcl_FreeProc *)free);

  if (rb_obj_is_kind_of(error_info, rb_eSystemExit)) {
    tcl_interp->exit_exception = error_info;
  }

  return Qfalse;
}

static int rb_tcl_interp_send(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]) {
  VALUE interp_receive_args = rb_ary_new2(objc - 1);
  int i;
  
  for (i = 1; i < objc; i++) {
    int element_length;
    const char *element;
    
    element = Tcl_GetStringFromObj(objv[i], &element_length);
    rb_ary_push(interp_receive_args, rb_tainted_str_new2(element));
  }
  
  VALUE args = rb_ary_new3(2, (VALUE) clientData, interp_receive_args);
  
  if (rb_rescue2(rb_tcl_interp_send_begin, args, rb_tcl_interp_send_rescue, args, rb_eException) == Qtrue) {
    return TCL_OK;
  } else {
    return TCL_ERROR;
  }
}

static VALUE rb_tcl_interp_allocate(VALUE klass) {
  tcl_interp_struct *tcl_interp;
  VALUE obj = Data_Make_Struct(klass, tcl_interp_struct, NULL, rb_tcl_interp_destroy, tcl_interp);
  
  tcl_interp->interp = Tcl_CreateInterp();
  tcl_interp->exit_exception = Qnil;
  Tcl_Init(tcl_interp->interp);
  Tcl_Preserve(tcl_interp->interp);
  
  Tcl_CreateObjCommand(tcl_interp->interp, "interp_send", (Tcl_ObjCmdProc *)rb_tcl_interp_send, (ClientData) obj, (Tcl_CmdDeleteProc *)NULL);
  
  return obj;
}

static VALUE rb_tcl_safe_interp_allocate(VALUE klass) {
  VALUE obj = rb_tcl_interp_allocate(klass);

  tcl_interp_struct *tcl_interp;
  Data_Get_Struct(obj, tcl_interp_struct, tcl_interp);
  
  Tcl_MakeSafe(tcl_interp->interp);

  return obj;
}

#ifdef TCL_LIMIT_TIME
static VALUE rb_tcl_interp_eval(VALUE self, VALUE args) {
  VALUE script = rb_ary_entry(args, 0);

  int timeout = 0;
  if (RARRAY(args)->len == 2) {
    timeout = NUM2INT(rb_ary_entry(args, 1));
  }
#else
static VALUE rb_tcl_interp_eval(VALUE self, VALUE script) {
#endif

  tcl_interp_struct *tcl_interp;
  Data_Get_Struct(self, tcl_interp_struct, tcl_interp);

#ifdef TCL_LIMIT_TIME
  if (timeout > 0) {
    Tcl_Time timeout_time;
    Tcl_GetTime(&timeout_time);
    timeout_time.sec += (long) timeout / 1000;
    timeout_time.usec += (long) (timeout % 1000) * 1000;

    Tcl_LimitSetTime(tcl_interp->interp, &timeout_time);
    Tcl_LimitTypeSet(tcl_interp->interp, TCL_LIMIT_TIME);
  }
#endif

  int result = Tcl_Eval(tcl_interp->interp, RSTRING(rb_value_to_s(script))->ptr);
  
  VALUE error_class = rb_const_get(rb_const_get(rb_cObject, rb_intern("Tcl")), rb_intern("Error"));

#ifdef TCL_LIMIT_TIME
  if (timeout > 0) {
    if (Tcl_LimitTypeExceeded(tcl_interp->interp, TCL_LIMIT_TIME))
      error_class = rb_const_get(rb_const_get(rb_cObject, rb_intern("Tcl")), rb_intern("Timeout"));
      
    Tcl_LimitTypeReset(tcl_interp->interp, TCL_LIMIT_TIME);
  }
#endif
  
  switch (result) {
    case TCL_OK:
      return rb_tainted_str_new2(tcl_interp->interp->result);
    case TCL_ERROR:
      if (NIL_P(tcl_interp->exit_exception)) {
        rb_raise(error_class, "%s", tcl_interp->interp->result);
      } else {
        rb_exit(NUM2INT(rb_iv_get(tcl_interp->exit_exception, "status")));
      }
    default:
      return Qnil;
  }
}

static VALUE rb_tcl_interp_list_to_array(VALUE self, VALUE list) {
  tcl_interp_struct *tcl_interp;
  Data_Get_Struct(self, tcl_interp_struct, tcl_interp);
  
  Tcl_Obj *string = Tcl_NewStringObj(RSTRING(rb_value_to_s(list))->ptr, -1);
  Tcl_IncrRefCount(string);

  int list_length, i;
  Tcl_Obj **elements;
  
  if (Tcl_ListObjGetElements(tcl_interp->interp, string, &list_length, &elements) != TCL_OK) {
    Tcl_DecrRefCount(string);
    return Qnil;
  }
  
  for (i = 0; i < list_length; i++)
    Tcl_IncrRefCount(elements[i]);
  
  VALUE result = rb_ary_new2(list_length);
  
  for (i = 0; i < list_length; i++) {
    int element_length;
    const char *element;
    
    element = Tcl_GetStringFromObj(elements[i], &element_length);
    rb_ary_push(result, element ? rb_tainted_str_new(element, element_length) : rb_str_new2(""));
    Tcl_DecrRefCount(elements[i]);
  }
  
  Tcl_DecrRefCount(string);

  return result;
}

static VALUE rb_tcl_interp_array_to_list(VALUE self, VALUE array) {
  tcl_interp_struct *tcl_interp;
  Data_Get_Struct(self, tcl_interp_struct, tcl_interp);

  int array_length = RARRAY(array)->len, i;
  
  Tcl_Obj *list = Tcl_NewObj();
  Tcl_IncrRefCount(list);
  
  for (i = 0; i < array_length; i++) {
    VALUE element = rb_ary_entry(array, i);
    Tcl_Obj *string = Tcl_NewStringObj(RSTRING(rb_value_to_s(element))->ptr, -1);

    Tcl_IncrRefCount(string);
    Tcl_ListObjAppendElement(tcl_interp->interp, list, string);
    Tcl_DecrRefCount(string);
  }

  VALUE result = rb_tainted_str_new2(Tcl_GetStringFromObj(list, NULL));
  
  Tcl_DecrRefCount(list);
  
  return result;
}

void Init_tcl_ruby() {
  VALUE tcl_module = rb_define_module("Tcl");
  VALUE interp_class = rb_define_class_under(tcl_module, "Interp", rb_cObject);
  VALUE safe_interp_class = rb_define_class_under(tcl_module, "SafeInterp", interp_class);
  VALUE error_class = rb_define_class_under(tcl_module, "Error", rb_eStandardError);

  rb_define_alloc_func(interp_class, rb_tcl_interp_allocate);
  rb_define_alloc_func(safe_interp_class, rb_tcl_safe_interp_allocate);
  rb_define_method(interp_class, "list_to_array", rb_tcl_interp_list_to_array, 1);
  rb_define_method(interp_class, "array_to_list", rb_tcl_interp_array_to_list, 1);

#ifdef TCL_LIMIT_TIME
  VALUE timeout_class = rb_define_class_under(tcl_module, "Timeout", error_class);
  rb_define_method(interp_class, "eval", rb_tcl_interp_eval, -2);
#else
  rb_define_method(interp_class, "eval", rb_tcl_interp_eval, 1);
#endif
}
