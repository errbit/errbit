/* Please see the LICENSE file for copyright and distribution information */

#include "ruby_libxml.h"
#include "ruby_xml_xpath.h"
#include "ruby_xml_xpath_expression.h"

/*
 * Document-class: LibXML::XML::XPath::Expression
 *
 * The XML::XPath::Expression class is used to compile
 * XPath expressions so they can be parsed only once
 * but reused multiple times.
 *
 *  doc = XML::Document.string(IO.read('some xml file'))
 *  expr = XPath::Expression.new('//first')
 *  doc.root.each do |node|
 *   result = node.find(expr) # many, many, many times
 *   # ...
 *  end
 */

VALUE cXMLXPathExpression;

static void rxml_xpath_expression_free(xmlXPathCompExprPtr expr)
{
  xmlXPathFreeCompExpr(expr);
}

static VALUE rxml_xpath_expression_alloc(VALUE klass)
{
  return Data_Wrap_Struct(cXMLXPathExpression, NULL,
      rxml_xpath_expression_free, NULL);
}

/* call-seq:
 *    XPath::Expression.compile(expression) -> XPath::Expression
 *
 * Compiles an XPatch expression. This improves performance
 * when an XPath expression is called multiple times.
 *
 *  doc = XML::Document.string('<header><first>hi</first></header>')
 *  expr = XPath::Expression.new('//first')
 *  nodes = doc.find(expr)
 */
static VALUE rxml_xpath_expression_compile(VALUE klass, VALUE expression)
{
  VALUE args[] = {expression};
  return rb_class_new_instance(1, args, cXMLXPathExpression);
}

/* call-seq:
 *    XPath::Expression.new(expression) -> XPath::Expression
 *
 * Compiles an XPatch expression. This improves performance
 * when an XPath expression is called multiple times.
 *
 *  doc = XML::Document.string('<header><first>hi</first></header>')
 *  expr = XPath::Expression.new('//first')
 *  nodes = doc.find(expr)
 */
static VALUE rxml_xpath_expression_initialize(VALUE self, VALUE expression)
{
  xmlXPathCompExprPtr compexpr = xmlXPathCompile((const xmlChar*)StringValueCStr(expression));

  if (compexpr == NULL)
  {
    xmlErrorPtr xerror = xmlGetLastError();
    rxml_raise(xerror);
  }

  DATA_PTR( self) = compexpr;
  return self;
}

void rxml_init_xpath_expression(void)
{
  cXMLXPathExpression = rb_define_class_under(mXPath, "Expression", rb_cObject);
  rb_define_alloc_func(cXMLXPathExpression, rxml_xpath_expression_alloc);
  rb_define_singleton_method(cXMLXPathExpression, "compile", rxml_xpath_expression_compile, 1);
  rb_define_method(cXMLXPathExpression, "initialize", rxml_xpath_expression_initialize, 1);
}
