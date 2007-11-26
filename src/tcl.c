#include <ruby.h>
#include <tcl.h>

typedef struct {
  Tcl_Interp *interp;
} tcl_interp_struct;

static VALUE rb_value_to_s(VALUE value) {
  return rb_funcall(value, rb_intern("to_s"), 0, 0);
}

void rb_tcl_interp_destroy(tcl_interp_struct *tcl_interp) {
  Tcl_DeleteInterp(tcl_interp->interp);
  Tcl_Release(tcl_interp->interp);
  free(tcl_interp);
}

static VALUE rb_tcl_interp_allocate(VALUE klass) {
  tcl_interp_struct *tcl_interp;
  VALUE obj = Data_Make_Struct(klass, tcl_interp_struct, NULL, rb_tcl_interp_destroy, tcl_interp);
  
  tcl_interp->interp = Tcl_CreateInterp();
  Tcl_Init(tcl_interp->interp);
  Tcl_Preserve(tcl_interp->interp);
  
  return obj;
}

static VALUE rb_tcl_safe_interp_allocate(VALUE klass) {
  VALUE obj = rb_tcl_interp_allocate(klass);

  tcl_interp_struct *tcl_interp;
  Data_Get_Struct(obj, tcl_interp_struct, tcl_interp);
  
  Tcl_MakeSafe(tcl_interp->interp);

  return obj;
}

static VALUE rb_tcl_interp_eval(VALUE self, VALUE script) {
  VALUE error_class = rb_const_get(rb_const_get(rb_cObject, rb_intern("Tcl")), rb_intern("Error"));

  tcl_interp_struct *tcl_interp;
  Data_Get_Struct(self, tcl_interp_struct, tcl_interp);

  int result = Tcl_Eval(tcl_interp->interp, RSTRING(rb_value_to_s(script))->ptr);

  switch (result) {
    case TCL_OK:
      return rb_tainted_str_new2(tcl_interp->interp->result);
    case TCL_ERROR:
      rb_raise(error_class, "%s", tcl_interp->interp->result);
    default:
      return Qnil;
  }
}

static VALUE rb_tcl_interp_list_to_array(VALUE self, VALUE list) {
  tcl_interp_struct *tcl_interp;
  Data_Get_Struct(self, tcl_interp_struct, tcl_interp);
  
  Tcl_Obj *string = Tcl_NewStringObj(RSTRING(rb_value_to_s(list))->ptr, -1);

  int list_length, i;
  Tcl_Obj **elements;
  
  if (Tcl_ListObjGetElements(tcl_interp->interp, string, &list_length, &elements) != TCL_OK)
    return Qnil;
  
  VALUE result = rb_ary_new2(list_length);
  
  for (i = 0; i < list_length; i++) {
    int element_length;
    const char *element;
    
    element = Tcl_GetStringFromObj(elements[i], &element_length);
    rb_ary_push(result, element ? rb_tainted_str_new(element, element_length) : rb_str_new2(""));
  }
  
  return result;
}

static VALUE rb_tcl_interp_array_to_list(VALUE self, VALUE array) {
  tcl_interp_struct *tcl_interp;
  Data_Get_Struct(self, tcl_interp_struct, tcl_interp);

  int array_length = NUM2INT(rb_funcall(array, rb_intern("length"), 0, 0)), i;
  
  Tcl_Obj *list = Tcl_NewObj();
  
  for (i = 0; i < array_length; i++) {
    VALUE element = rb_ary_entry(array, i);
    Tcl_Obj *string = Tcl_NewStringObj(RSTRING(rb_value_to_s(element))->ptr, -1);

    Tcl_ListObjAppendElement(tcl_interp->interp, list, string);
  }

  return rb_tainted_str_new2(Tcl_GetStringFromObj(list, NULL));
}

void Init_tcl() {
  VALUE tcl_module = rb_define_module("Tcl");
  VALUE interp_class = rb_define_class_under(tcl_module, "Interp", rb_cObject);
  VALUE safe_interp_class = rb_define_class_under(tcl_module, "SafeInterp", interp_class);
  VALUE error_class = rb_define_class_under(tcl_module, "Error", rb_eStandardError);
  
  rb_define_alloc_func(interp_class, rb_tcl_interp_allocate);
  rb_define_alloc_func(safe_interp_class, rb_tcl_safe_interp_allocate);
  rb_define_method(interp_class, "eval", rb_tcl_interp_eval, 1);
  rb_define_method(interp_class, "list_to_array", rb_tcl_interp_list_to_array, 1);
  rb_define_method(interp_class, "array_to_list", rb_tcl_interp_array_to_list, 1);
}
