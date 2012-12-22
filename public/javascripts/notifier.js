var Hoptoad = {
  VERSION           : '2.0',
  NOTICE_XML        : '<?xml version="1.0" encoding="UTF-8"?>\
  <notice version="2.0">\
    <api-key></api-key>\
    <notifier>\
      <name>errbit_notifier_js</name>\
      <version>2.0</version>\
      <url>https://github.com/errbit/errbit</url>\
    </notifier>\
    <error>\
      <class>EXCEPTION_CLASS</class>\
      <message>EXCEPTION_MESSAGE</message>\
      <backtrace>BACKTRACE_LINES</backtrace>\
    </error>\
    <request>\
      <url>REQUEST_URL</url>\
      <component>REQUEST_COMPONENT</component>\
      <action>REQUEST_ACTION</action>\
    </request>\
    <server-environment>\
      <project-root>PROJECT_ROOT</project-root>\
      <environment-name>production</environment-name>\
    </server-environment>\
  </notice>',
  ROOT              : window.location.protocol + '//' + window.location.host,
  BACKTRACE_MATCHER : /^(.*)\@(.*)\:(\d+)$/,
  backtrace_filters : [/notifier\.js/],

  notify: function(error) {
    var xml     = escape(Hoptoad.generateXML(error));
    var host    = Hoptoad.host;
    var url     = '//' + host + '/notifier_api/v2/notices.xml?data=' + xml;
    var request = document.createElement('iframe');

    request.style.width   = '1px';
    request.style.height  = '1px';
    request.style.display = 'none';
    request.src = url;

    document.getElementsByTagName('head')[0].appendChild(request);
  },

  setEnvironment: function(value) {
    var matcher = /<environment-name>.*<\/environment-name>/;

    Hoptoad.NOTICE_XML  = Hoptoad.NOTICE_XML.replace(matcher,
                                                     '<environment-name>' +
                                                       value +
                                                     '</environment-name>')
  },

  setHost: function(value) {
    Hoptoad.host = value;
  },

  setKey: function(value) {
    var matcher = /<api-key>.*<\/api-key>/;

    Hoptoad.NOTICE_XML = Hoptoad.NOTICE_XML.replace(matcher,
                                                    '<api-key>' +
                                                      value +
                                                    '</api-key>');
  },

  setErrorDefaults: function(value) {
    Hoptoad.errorDefaults = value;
  },

  generateXML: function(errorWithoutDefaults) {
    var error = Hoptoad.mergeDefault(Hoptoad.errorDefaults, errorWithoutDefaults);

    var xml       = Hoptoad.NOTICE_XML;
    var url       = Hoptoad.escapeText(error.url       || '');
    var component = Hoptoad.escapeText(error.component || '');
    var action    = Hoptoad.escapeText(error.action    || '');
    var type      = Hoptoad.escapeText(error.type      || 'Error');
    var message   = Hoptoad.escapeText(error.message   || 'Unknown error.');
    var backtrace = Hoptoad.generateBacktrace(error);


    if (Hoptoad.trim(url) == '' && Hoptoad.trim(component) == '') {
      xml = xml.replace(/<request>.*<\/request>/, '');
    } else {
      var data    = '';

      var cgi_data = error['cgi-data'] || {};
      cgi_data["HTTP_USER_AGENT"] = navigator.userAgent;
      data += '<cgi-data>';
      data += Hoptoad.generateVariables(cgi_data);
      data += '</cgi-data>';

      var methods = ['params', 'session'];

      for (var i = 0; i < methods.length; i++) {
        var method = methods[i];

        if (error[method]) {
          data += '<' + method + '>';
          data += Hoptoad.generateVariables(error[method]);
          data += '</' + method + '>';
        }
      }

      xml = xml.replace('</request>',        data + '</request>')
               .replace('REQUEST_URL',       url)
               .replace('REQUEST_ACTION',    action)
               .replace('REQUEST_COMPONENT', component);
    }

    return xml.replace('PROJECT_ROOT',     Hoptoad.ROOT)
              .replace('EXCEPTION_CLASS',   type)
              .replace('EXCEPTION_MESSAGE', message)
              .replace('BACKTRACE_LINES',   backtrace.join(''));
  },

  generateBacktrace: function(error) {
    error = error || {};

    if (typeof error.stack != 'string') {
      try {
        (0)();
      } catch(e) {
        error.stack = e.stack;
      }
    }

    var backtrace  = [];
    var stacktrace = Hoptoad.getStackTrace(error);

    for (var i = 0, l = stacktrace.length; i < l; i++) {
      var line    = stacktrace[i];
      var matches = line.match(Hoptoad.BACKTRACE_MATCHER);

      if (matches && Hoptoad.validBacktraceLine(line)) {
        var file = matches[2].replace(Hoptoad.ROOT, '[PROJECT_ROOT]');

        if (i == 0) {
          if (matches[2].match(document.location.href)) {
            backtrace.push('<line method="" file="internal: " number=""/>');
          }
        }

        backtrace.push('<line method="' + Hoptoad.escapeText(matches[1]) +
                       '" file="' + Hoptoad.escapeText(file) +
                       '" number="' + matches[3] + '" />');
      }
    }

    return backtrace;
  },

  getStackTrace: function(error) {
    var stacktrace = printStackTrace({ e : error, guess : false });

    for (var i = 0, l = stacktrace.length; i < l; i++) {
      if (stacktrace[i].match(/\:\d+$/)) {
        continue;
      }

      if (stacktrace[i].indexOf('@') == -1) {
        stacktrace[i] += '@unsupported.js';
      }

      stacktrace[i] += ':0';
    }

    return stacktrace;
  },

  validBacktraceLine: function(line) {
    for (var i = 0; i < Hoptoad.backtrace_filters.length; i++) {
      if (line.match(Hoptoad.backtrace_filters[i])) {
        return false;
      }
    }

    return true;
  },

  generateVariables: function(parameters) {
    var key;
    var result = '';

    for (key in parameters) {
      result += '<var key="' + Hoptoad.escapeText(key) + '">' +
                  Hoptoad.escapeText(parameters[key]) +
                '</var>';
    }

    return result;
  },

  escapeText: function(text) {
    return text.replace(/&/g, '&#38;')
               .replace(/</g, '&#60;')
               .replace(/>/g, '&#62;')
               .replace(/'/g, '&#39;')
               .replace(/"/g, '&#34;');
  },

  trim: function(text) {
    return text.toString().replace(/^\s+/, '').replace(/\s+$/, '');
  },

  mergeDefault: function(defaults, hash) {
    var cloned = {};
    var key;

    for (key in hash) {
      cloned[key] = hash[key];
    }

    for (key in defaults) {
      if (!cloned.hasOwnProperty(key)) {
        cloned[key] = defaults[key];
      }
    }

    return cloned;
  }
};

// From: http://stacktracejs.com/
//
// Domain Public by Eric Wendelin http://eriwen.com/ (2008)
//                  Luke Smith http://lucassmith.name/ (2008)
//                  Loic Dachary <loic@dachary.org> (2008)
//                  Johan Euphrosine <proppy@aminche.com> (2008)
//                  Oyvind Sean Kinsey http://kinsey.no/blog (2010)
//                  Victor Homyakov <victor-homyakov@users.sourceforge.net> (2010)

function printStackTrace(a){var a=a||{guess:!0},b=a.e||null,a=!!a.guess,d=new printStackTrace.implementation,b=d.run(b);return a?d.guessAnonymousFunctions(b):b}printStackTrace.implementation=function(){};
printStackTrace.implementation.prototype={run:function(a,b){a=a||this.createException();b=b||this.mode(a);return"other"===b?this.other(arguments.callee):this[b](a)},createException:function(){try{this.undef()}catch(a){return a}},mode:function(a){return a.arguments&&a.stack?"chrome":a.stack&&a.sourceURL?"safari":"string"===typeof a.message&&"undefined"!==typeof window&&window.opera?!a.stacktrace||-1<a.message.indexOf("\n")&&a.message.split("\n").length>a.stacktrace.split("\n").length?"opera9":!a.stack?
"opera10a":0>a.stacktrace.indexOf("called from line")?"opera10b":"opera11":a.stack?"firefox":"other"},instrumentFunction:function(a,b,d){var a=a||window,c=a[b];a[b]=function(){d.call(this,printStackTrace().slice(4));return a[b]._instrumented.apply(this,arguments)};a[b]._instrumented=c},deinstrumentFunction:function(a,b){a[b].constructor===Function&&(a[b]._instrumented&&a[b]._instrumented.constructor===Function)&&(a[b]=a[b]._instrumented)},chrome:function(a){a=(a.stack+"\n").replace(/^\S[^\(]+?[\n$]/gm,
"").replace(/^\s+(at eval )?at\s+/gm,"").replace(/^([^\(]+?)([\n$])/gm,"{anonymous}()@$1$2").replace(/^Object.<anonymous>\s*\(([^\)]+)\)/gm,"{anonymous}()@$1").split("\n");a.pop();return a},safari:function(a){return a.stack.replace(/\[native code\]\n/m,"").replace(/^@/gm,"{anonymous}()@").split("\n")},firefox:function(a){return a.stack.replace(/(?:\n@:0)?\s+$/m,"").replace(/^[\(@]/gm,"{anonymous}()@").split("\n")},opera11:function(a){for(var b=/^.*line (\d+), column (\d+)(?: in (.+))? in (\S+):$/,
a=a.stacktrace.split("\n"),d=[],c=0,f=a.length;c<f;c+=2){var e=b.exec(a[c]);if(e){var g=e[4]+":"+e[1]+":"+e[2],e=e[3]||"global code",e=e.replace(/<anonymous function: (\S+)>/,"$1").replace(/<anonymous function>/,"{anonymous}");d.push(e+"@"+g+" -- "+a[c+1].replace(/^\s+/,""))}}return d},opera10b:function(a){for(var b=/^(.*)@(.+):(\d+)$/,a=a.stacktrace.split("\n"),d=[],c=0,f=a.length;c<f;c++){var e=b.exec(a[c]);e&&d.push((e[1]?e[1]+"()":"global code")+"@"+e[2]+":"+e[3])}return d},opera10a:function(a){for(var b=
/Line (\d+).*script (?:in )?(\S+)(?:: In function (\S+))?$/i,a=a.stacktrace.split("\n"),d=[],c=0,f=a.length;c<f;c+=2){var e=b.exec(a[c]);e&&d.push((e[3]||"{anonymous}")+"()@"+e[2]+":"+e[1]+" -- "+a[c+1].replace(/^\s+/,""))}return d},opera9:function(a){for(var b=/Line (\d+).*script (?:in )?(\S+)/i,a=a.message.split("\n"),d=[],c=2,f=a.length;c<f;c+=2){var e=b.exec(a[c]);e&&d.push("{anonymous}()@"+e[2]+":"+e[1]+" -- "+a[c+1].replace(/^\s+/,""))}return d},other:function(a){for(var b=/function\s*([\w\-$]+)?\s*\(/i,
d=[],c,f;a&&a.arguments&&10>d.length;)c=b.test(a.toString())?RegExp.$1||"{anonymous}":"{anonymous}",f=Array.prototype.slice.call(a.arguments||[]),d[d.length]=c+"("+this.stringifyArguments(f)+")",a=a.caller;return d},stringifyArguments:function(a){for(var b=[],d=Array.prototype.slice,c=0;c<a.length;++c){var f=a[c];void 0===f?b[c]="undefined":null===f?b[c]="null":f.constructor&&(f.constructor===Array?b[c]=3>f.length?"["+this.stringifyArguments(f)+"]":"["+this.stringifyArguments(d.call(f,0,1))+"..."+
this.stringifyArguments(d.call(f,-1))+"]":f.constructor===Object?b[c]="#object":f.constructor===Function?b[c]="#function":f.constructor===String?b[c]='"'+f+'"':f.constructor===Number&&(b[c]=f))}return b.join(",")},sourceCache:{},ajax:function(a){var b=this.createXMLHTTPObject();if(b)try{return b.open("GET",a,!1),b.send(null),b.responseText}catch(d){}return""},createXMLHTTPObject:function(){for(var a,b=[function(){return new XMLHttpRequest},function(){return new ActiveXObject("Msxml2.XMLHTTP")},function(){return new ActiveXObject("Msxml3.XMLHTTP")},
function(){return new ActiveXObject("Microsoft.XMLHTTP")}],d=0;d<b.length;d++)try{return a=b[d](),this.createXMLHTTPObject=b[d],a}catch(c){}},isSameDomain:function(a){return"undefined"!==typeof location&&-1!==a.indexOf(location.hostname)},getSource:function(a){a in this.sourceCache||(this.sourceCache[a]=this.ajax(a).split("\n"));return this.sourceCache[a]},guessAnonymousFunctions:function(a){for(var b=0;b<a.length;++b){var d=/^(.*?)(?::(\d+))(?::(\d+))?(?: -- .+)?$/,c=a[b],f=/\{anonymous\}\(.*\)@(.*)/.exec(c);
if(f){var e=d.exec(f[1]);e&&(d=e[1],f=e[2],e=e[3]||0,d&&(this.isSameDomain(d)&&f)&&(d=this.guessAnonymousFunction(d,f,e),a[b]=c.replace("{anonymous}",d)))}}return a},guessAnonymousFunction:function(a,b){var d;try{d=this.findFunctionName(this.getSource(a),b)}catch(c){d="getSource failed with url: "+a+", exception: "+c.toString()}return d},findFunctionName:function(a,b){for(var d=/function\s+([^(]*?)\s*\(([^)]*)\)/,c=/['"]?([0-9A-Za-z_]+)['"]?\s*[:=]\s*function\b/,f=/['"]?([0-9A-Za-z_]+)['"]?\s*[:=]\s*(?:eval|new Function)\b/,
e="",g,j=Math.min(b,20),h,i=0;i<j;++i)if(g=a[b-i-1],h=g.indexOf("//"),0<=h&&(g=g.substr(0,h)),g)if(e=g+e,(g=c.exec(e))&&g[1]||(g=d.exec(e))&&g[1]||(g=f.exec(e))&&g[1])return g[1];return"(?)"}};

window.onerror = function(message, file, line) {
  setTimeout(function() {
    Hoptoad.notify({
      message : message,
      stack   : '()@' + file + ':' + line,
      url     : document.location.href
    });
  }, 100);
  return true;
};

