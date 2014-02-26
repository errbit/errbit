// Airbrake JavaScript Notifier Bundle
(function(window, document, undefined) {
// Domain Public by Eric Wendelin http://eriwen.com/ (2008)
//                  Luke Smith http://lucassmith.name/ (2008)
//                  Loic Dachary <loic@dachary.org> (2008)
//                  Johan Euphrosine <proppy@aminche.com> (2008)
//                  Øyvind Sean Kinsey http://kinsey.no/blog (2010)
//                  Victor Homyakov (2010)
//
// Information and discussions
// http://jspoker.pokersource.info/skin/test-printstacktrace.html
// http://eriwen.com/javascript/js-stack-trace/
// http://eriwen.com/javascript/stacktrace-update/
// http://pastie.org/253058
//
// guessFunctionNameFromLines comes from firebug
//
// Software License Agreement (BSD License)
//
// Copyright (c) 2007, Parakey Inc.
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above
//   copyright notice, this list of conditions and the
//   following disclaimer.
//
// * Redistributions in binary form must reproduce the above
//   copyright notice, this list of conditions and the
//   following disclaimer in the documentation and/or other
//   materials provided with the distribution.
//
// * Neither the name of Parakey Inc. nor the names of its
//   contributors may be used to endorse or promote products
//   derived from this software without specific prior
//   written permission of Parakey Inc.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
// FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
// IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/**
 * Main function giving a function stack trace with a forced or passed in Error
 *
 * @cfg {Error} e The error to create a stacktrace from (optional)
 * @cfg {Boolean} guess If we should try to resolve the names of anonymous functions
 * @return {Array} of Strings with functions, lines, files, and arguments where possible
 */
function printStackTrace(options) {
    options = options || {guess: true};
    var ex = options.e || null, guess = !!options.guess;
    var p = new printStackTrace.implementation(), result = p.run(ex);
    return (guess) ? p.guessAnonymousFunctions(result) : result;
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = printStackTrace;
}

printStackTrace.implementation = function() {
};

printStackTrace.implementation.prototype = {
    /**
     * @param {Error} ex The error to create a stacktrace from (optional)
     * @param {String} mode Forced mode (optional, mostly for unit tests)
     */
    run: function(ex, mode) {
        ex = ex || this.createException();
        // examine exception properties w/o debugger
        //for (var prop in ex) {alert("Ex['" + prop + "']=" + ex[prop]);}
        mode = mode || this.mode(ex);
        if (mode === 'other') {
            return this.other(arguments.callee);
        } else {
            return this[mode](ex);
        }
    },

    createException: function() {
        try {
            this.undef();
        } catch (e) {
            return e;
        }
    },

    /**
     * Mode could differ for different exception, e.g.
     * exceptions in Chrome may or may not have arguments or stack.
     *
     * @return {String} mode of operation for the exception
     */
    mode: function(e) {
        if (e['arguments'] && e.stack) {
            return 'chrome';
        } else if (e.stack && e.sourceURL) {
            return 'safari';
        } else if (e.stack && e.number) {
            return 'ie';
        } else if (typeof e.message === 'string' && typeof window !== 'undefined' && window.opera) {
            // e.message.indexOf("Backtrace:") > -1 -> opera
            // !e.stacktrace -> opera
            if (!e.stacktrace) {
                return 'opera9'; // use e.message
            }
            // 'opera#sourceloc' in e -> opera9, opera10a
            if (e.message.indexOf('\n') > -1 && e.message.split('\n').length > e.stacktrace.split('\n').length) {
                return 'opera9'; // use e.message
            }
            // e.stacktrace && !e.stack -> opera10a
            if (!e.stack) {
                return 'opera10a'; // use e.stacktrace
            }
            // e.stacktrace && e.stack -> opera10b
            if (e.stacktrace.indexOf("called from line") < 0) {
                return 'opera10b'; // use e.stacktrace, format differs from 'opera10a'
            }
            // e.stacktrace && e.stack -> opera11
            return 'opera11'; // use e.stacktrace, format differs from 'opera10a', 'opera10b'
        } else if (e.stack && !e.fileName) {
            // Chrome 27 does not have e.arguments as earlier versions,
            // but still does not have e.fileName as Firefox
            return 'chrome';
        } else if (e.stack) {
            return 'firefox';
        }
        return 'other';
    },

    /**
     * Given a context, function name, and callback function, overwrite it so that it calls
     * printStackTrace() first with a callback and then runs the rest of the body.
     *
     * @param {Object} context of execution (e.g. window)
     * @param {String} functionName to instrument
     * @param {Function} callback function to call with a stack trace on invocation
     */
    instrumentFunction: function(context, functionName, callback) {
        context = context || window;
        var original = context[functionName];
        context[functionName] = function instrumented() {
            callback.call(this, printStackTrace().slice(4));
            return context[functionName]._instrumented.apply(this, arguments);
        };
        context[functionName]._instrumented = original;
    },

    /**
     * Given a context and function name of a function that has been
     * instrumented, revert the function to it's original (non-instrumented)
     * state.
     *
     * @param {Object} context of execution (e.g. window)
     * @param {String} functionName to de-instrument
     */
    deinstrumentFunction: function(context, functionName) {
        if (context[functionName].constructor === Function &&
                context[functionName]._instrumented &&
                context[functionName]._instrumented.constructor === Function) {
            context[functionName] = context[functionName]._instrumented;
        }
    },

    /**
     * Given an Error object, return a formatted Array based on Chrome's stack string.
     *
     * @param e - Error object to inspect
     * @return Array<String> of function calls, files and line numbers
     */
    chrome: function(e) {
        var stack = (e.stack + '\n').replace(/^\S[^\(]+?[\n$]/gm, '').
          replace(/^\s+(at eval )?at\s+/gm, '').
          replace(/^([^\(]+?)([\n$])/gm, '{anonymous}()@$1$2').
          replace(/^Object.<anonymous>\s*\(([^\)]+)\)/gm, '{anonymous}()@$1').split('\n');
        stack.pop();
        return stack;
    },

    /**
     * Given an Error object, return a formatted Array based on Safari's stack string.
     *
     * @param e - Error object to inspect
     * @return Array<String> of function calls, files and line numbers
     */
    safari: function(e) {
        return e.stack.replace(/\[native code\]\n/m, '')
            .replace(/^(?=\w+Error\:).*$\n/m, '')
            .replace(/^@/gm, '{anonymous}()@')
            .split('\n');
    },

    /**
     * Given an Error object, return a formatted Array based on IE's stack string.
     *
     * @param e - Error object to inspect
     * @return Array<String> of function calls, files and line numbers
     */
    ie: function(e) {
        var lineRE = /^.*at (\w+) \(([^\)]+)\)$/gm;
        return e.stack.replace(/at Anonymous function /gm, '{anonymous}()@')
            .replace(/^(?=\w+Error\:).*$\n/m, '')
            .replace(lineRE, '$1@$2')
            .split('\n');
    },

    /**
     * Given an Error object, return a formatted Array based on Firefox's stack string.
     *
     * @param e - Error object to inspect
     * @return Array<String> of function calls, files and line numbers
     */
    firefox: function(e) {
        return e.stack.replace(/(?:\n@:0)?\s+$/m, '').replace(/^[\(@]/gm, '{anonymous}()@').split('\n');
    },

    opera11: function(e) {
        var ANON = '{anonymous}', lineRE = /^.*line (\d+), column (\d+)(?: in (.+))? in (\S+):$/;
        var lines = e.stacktrace.split('\n'), result = [];

        for (var i = 0, len = lines.length; i < len; i += 2) {
            var match = lineRE.exec(lines[i]);
            if (match) {
                var location = match[4] + ':' + match[1] + ':' + match[2];
                var fnName = match[3] || "global code";
                fnName = fnName.replace(/<anonymous function: (\S+)>/, "$1").replace(/<anonymous function>/, ANON);
                result.push(fnName + '@' + location + ' -- ' + lines[i + 1].replace(/^\s+/, ''));
            }
        }

        return result;
    },

    opera10b: function(e) {
        // "<anonymous function: run>([arguments not available])@file://localhost/G:/js/stacktrace.js:27\n" +
        // "printStackTrace([arguments not available])@file://localhost/G:/js/stacktrace.js:18\n" +
        // "@file://localhost/G:/js/test/functional/testcase1.html:15"
        var lineRE = /^(.*)@(.+):(\d+)$/;
        var lines = e.stacktrace.split('\n'), result = [];

        for (var i = 0, len = lines.length; i < len; i++) {
            var match = lineRE.exec(lines[i]);
            if (match) {
                var fnName = match[1]? (match[1] + '()') : "global code";
                result.push(fnName + '@' + match[2] + ':' + match[3]);
            }
        }

        return result;
    },

    /**
     * Given an Error object, return a formatted Array based on Opera 10's stacktrace string.
     *
     * @param e - Error object to inspect
     * @return Array<String> of function calls, files and line numbers
     */
    opera10a: function(e) {
        // "  Line 27 of linked script file://localhost/G:/js/stacktrace.js\n"
        // "  Line 11 of inline#1 script in file://localhost/G:/js/test/functional/testcase1.html: In function foo\n"
        var ANON = '{anonymous}', lineRE = /Line (\d+).*script (?:in )?(\S+)(?:: In function (\S+))?$/i;
        var lines = e.stacktrace.split('\n'), result = [];

        for (var i = 0, len = lines.length; i < len; i += 2) {
            var match = lineRE.exec(lines[i]);
            if (match) {
                var fnName = match[3] || ANON;
                result.push(fnName + '()@' + match[2] + ':' + match[1] + ' -- ' + lines[i + 1].replace(/^\s+/, ''));
            }
        }

        return result;
    },

    // Opera 7.x-9.2x only!
    opera9: function(e) {
        // "  Line 43 of linked script file://localhost/G:/js/stacktrace.js\n"
        // "  Line 7 of inline#1 script in file://localhost/G:/js/test/functional/testcase1.html\n"
        var ANON = '{anonymous}', lineRE = /Line (\d+).*script (?:in )?(\S+)/i;
        var lines = e.message.split('\n'), result = [];

        for (var i = 2, len = lines.length; i < len; i += 2) {
            var match = lineRE.exec(lines[i]);
            if (match) {
                result.push(ANON + '()@' + match[2] + ':' + match[1] + ' -- ' + lines[i + 1].replace(/^\s+/, ''));
            }
        }

        return result;
    },

    // Safari 5-, IE 9-, and others
    other: function(curr) {
        var ANON = '{anonymous}', fnRE = /function\s*([\w\-$]+)?\s*\(/i, stack = [], fn, args, maxStackSize = 10;
        while (curr && curr['arguments'] && stack.length < maxStackSize) {
            fn = fnRE.test(curr.toString()) ? RegExp.$1 || ANON : ANON;
            args = Array.prototype.slice.call(curr['arguments'] || []);
            stack[stack.length] = fn + '(' + this.stringifyArguments(args) + ')';
            curr = curr.caller;
        }
        return stack;
    },

    /**
     * Given arguments array as a String, substituting type names for non-string types.
     *
     * @param {Arguments,Array} args
     * @return {String} stringified arguments
     */
    stringifyArguments: function(args) {
        var result = [];
        var slice = Array.prototype.slice;
        for (var i = 0; i < args.length; ++i) {
            var arg = args[i];
            if (arg === undefined) {
                result[i] = 'undefined';
            } else if (arg === null) {
                result[i] = 'null';
            } else if (arg.constructor) {
                if (arg.constructor === Array) {
                    if (arg.length < 3) {
                        result[i] = '[' + this.stringifyArguments(arg) + ']';
                    } else {
                        result[i] = '[' + this.stringifyArguments(slice.call(arg, 0, 1)) + '...' + this.stringifyArguments(slice.call(arg, -1)) + ']';
                    }
                } else if (arg.constructor === Object) {
                    result[i] = '#object';
                } else if (arg.constructor === Function) {
                    result[i] = '#function';
                } else if (arg.constructor === String) {
                    result[i] = '"' + arg + '"';
                } else if (arg.constructor === Number) {
                    result[i] = arg;
                }
            }
        }
        return result.join(',');
    },

    sourceCache: {},

    /**
     * @return the text from a given URL
     */
    ajax: function(url) {
        var req = this.createXMLHTTPObject();
        if (req) {
            try {
                req.open('GET', url, false);
                //req.overrideMimeType('text/plain');
                //req.overrideMimeType('text/javascript');
                req.send(null);
                //return req.status == 200 ? req.responseText : '';
                return req.responseText;
            } catch (e) {
            }
        }
        return '';
    },

    /**
     * Try XHR methods in order and store XHR factory.
     *
     * @return <Function> XHR function or equivalent
     */
    createXMLHTTPObject: function() {
        var xmlhttp, XMLHttpFactories = [
            function() {
                return new XMLHttpRequest();
            }, function() {
                return new ActiveXObject('Msxml2.XMLHTTP');
            }, function() {
                return new ActiveXObject('Msxml3.XMLHTTP');
            }, function() {
                return new ActiveXObject('Microsoft.XMLHTTP');
            }
        ];
        for (var i = 0; i < XMLHttpFactories.length; i++) {
            try {
                xmlhttp = XMLHttpFactories[i]();
                // Use memoization to cache the factory
                this.createXMLHTTPObject = XMLHttpFactories[i];
                return xmlhttp;
            } catch (e) {
            }
        }
    },

    /**
     * Given a URL, check if it is in the same domain (so we can get the source
     * via Ajax).
     *
     * @param url <String> source url
     * @return <Boolean> False if we need a cross-domain request
     */
    isSameDomain: function(url) {
        return typeof location !== "undefined" && url.indexOf(location.hostname) !== -1; // location may not be defined, e.g. when running from nodejs.
    },

    /**
     * Get source code from given URL if in the same domain.
     *
     * @param url <String> JS source URL
     * @return <Array> Array of source code lines
     */
    getSource: function(url) {
        // TODO reuse source from script tags?
        if (!(url in this.sourceCache)) {
            this.sourceCache[url] = this.ajax(url).split('\n');
        }
        return this.sourceCache[url];
    },

    guessAnonymousFunctions: function(stack) {
        for (var i = 0; i < stack.length; ++i) {
            var reStack = /\{anonymous\}\(.*\)@(.*)/,
                reRef = /^(.*?)(?::(\d+))(?::(\d+))?(?: -- .+)?$/,
                frame = stack[i], ref = reStack.exec(frame);

            if (ref) {
                var m = reRef.exec(ref[1]);
                if (m) { // If falsey, we did not get any file/line information
                    var file = m[1], lineno = m[2], charno = m[3] || 0;
                    if (file && this.isSameDomain(file) && lineno) {
                        var functionName = this.guessAnonymousFunction(file, lineno, charno);
                        stack[i] = frame.replace('{anonymous}', functionName);
                    }
                }
            }
        }
        return stack;
    },

    guessAnonymousFunction: function(url, lineNo, charNo) {
        var ret;
        try {
            ret = this.findFunctionName(this.getSource(url), lineNo);
        } catch (e) {
            ret = 'getSource failed with url: ' + url + ', exception: ' + e.toString();
        }
        return ret;
    },

    findFunctionName: function(source, lineNo) {
        // FIXME findFunctionName fails for compressed source
        // (more than one function on the same line)
        // function {name}({args}) m[1]=name m[2]=args
        var reFunctionDeclaration = /function\s+([^(]*?)\s*\(([^)]*)\)/;
        // {name} = function ({args}) TODO args capture
        // /['"]?([0-9A-Za-z_]+)['"]?\s*[:=]\s*function(?:[^(]*)/
        var reFunctionExpression = /['"]?([$_A-Za-z][$_A-Za-z0-9]*)['"]?\s*[:=]\s*function\b/;
        // {name} = eval()
        var reFunctionEvaluation = /['"]?([$_A-Za-z][$_A-Za-z0-9]*)['"]?\s*[:=]\s*(?:eval|new Function)\b/;
        // Walk backwards in the source lines until we find
        // the line which matches one of the patterns above
        var code = "", line, maxLines = Math.min(lineNo, 20), m, commentPos;
        for (var i = 0; i < maxLines; ++i) {
            // lineNo is 1-based, source[] is 0-based
            line = source[lineNo - i - 1];
            commentPos = line.indexOf('//');
            if (commentPos >= 0) {
                line = line.substr(0, commentPos);
            }
            // TODO check other types of comments? Commented code may lead to false positive
            if (line) {
                code = line + code;
                m = reFunctionExpression.exec(code);
                if (m && m[1]) {
                    return m[1];
                }
                m = reFunctionDeclaration.exec(code);
                if (m && m[1]) {
                    //return m[1] + "(" + (m[2] || "") + ")";
                    return m[1];
                }
                m = reFunctionEvaluation.exec(code);
                if (m && m[1]) {
                    return m[1];
                }
            }
        }
        return '(?)';
    }
};// Airbrake JavaScript Notifier
(function() {
    "use strict";
    
    var NOTICE_XML = '<?xml version="1.0" encoding="UTF-8"?>' +
        '<notice version="2.0">' +
            '<api-key>{key}</api-key>' +
            '<notifier>' +
                '<name>airbrake_js</name>' +
                '<version>0.2.0</version>' +
                '<url>http://airbrake.io</url>' +
            '</notifier>' +
            '<error>' +
                '<class>{exception_class}</class>' +
                '<message><![CDATA[{exception_message}]]></message>' +
                '<backtrace>{backtrace_lines}</backtrace>' +
            '</error>' +
            '<request>' +
                '<url><![CDATA[{request_url}]]></url>' +
                '<component>{request_component}</component>' +
                '<action>{request_action}</action>' +
                '{request}' +
            '</request>' +
            '<server-environment>' +
                '<project-root>{project_root}</project-root>' +
                '<environment-name>{environment}</environment-name>' +
                '<app-version>{appVersion}</app-version>' +
            '</server-environment>' +
            '<current-user>' +
                '<id>{user_id}</id>' +
                '<name>{user_name}</name>' +
                '<email>{user_email}</email>' +
            '</current-user>' +
        '</notice>',
        REQUEST_VARIABLE_GROUP_XML = '<{group_name}>{inner_content}</{group_name}>',
        REQUEST_VARIABLE_XML = '<var key="{key}">{value}</var>',
        BACKTRACE_LINE_XML = '<line method="{function}" file="{file}" number="{line}" />',
        Config,
        Global,
        Util,
        _publicAPI,
        
        NOTICE_JSON = {
            "notifier": {
                "name": "airbrake_js",
                "version": "0.2.0",
                "url": "http://airbrake.io"
            },
            "error": [
             {
				"type": "{exception_class}",
                "message": "{exception_message}",
                "backtrace": []
				
            }
			],
            "context": {
				"language": "JavaScript",
				"environment": "{environment}",
				
                "version": "1.1.1",
				"url": "{request_url}",
                "rootDirectory": "{project_root}",
                "action": "{request_action}",
                "app-version": "{appVersion}",

                "userId": "{user_id}",
                "userName": "{user_name}",
                "userEmail": "{user_email}"
            },
            "environment": {},
			//"session": "",
			"params": {}
        };

    Util = {
        /*
         * Merge a number of objects into one.
         * 
         * Usage example: 
         *  var obj1 = {
         *          a: 'a'
         *      },
         *      obj2 = {
         *          b: 'b'     
         *      },
         *      obj3 = {
         *          c: 'c'     
         *      },
         *      mergedObj = Util.merge(obj1, obj2, obj3);  
         *
         * mergedObj is: {
         *     a: 'a',
         *     b: 'b',
         *     c: 'c'
         * }
         * 
         */
        merge: (function() {
            function processProperty (key, dest, src) {
                if (src.hasOwnProperty(key)) {
                    dest[key] = src[key];
                }
            }

            return function() {
                var objects = Array.prototype.slice.call(arguments),
                    obj,
                    key,
                    result = {};

                while (obj = objects.shift()) {
                    for (key in obj) {
                        processProperty(key, result, obj);
                    }
                }

                return result;
            };
        })(),
        
        /*
         * Replace &, <, >, ', " characters with correspondent HTML entities.
         */
        escape: function (text) {
            return text.replace(/&/g, '&#38;').replace(/</g, '&#60;').replace(/>/g, '&#62;')
                    .replace(/'/g, '&#39;').replace(/"/g, '&#34;');
        },
        
        /*
         * Remove leading and trailing space characters. 
         */
        trim: function (text) {
            return text.toString().replace(/^\s+/, '').replace(/\s+$/, '');
        },
        
        /*
         * Fill 'text' pattern with 'data' values.
         * 
         * e.g. Utils.substitute('<{tag}></{tag}>', {tag: 'div'}, true) will return '<div></div>'
         * 
         * emptyForUndefinedData - a flag, if true, all matched {<name>} without data.<name> value specified will be 
         * replaced with empty string.
         */
        substitute: function (text, data, emptyForUndefinedData) {
            return text.replace(/{([\w_.-]+)}/g, function(match, key) {
                return (key in data) ? data[key] : (emptyForUndefinedData ? '' : match);
            });
        },
        
        /*
         * Perform pattern rendering for an array of data objects. 
         * Returns a concatenation of rendered strings of all objects in array. 
         */
        substituteArr: function (text, dataArr, emptyForUndefinedData) {
            var _i = 0, _l = 0, 
                returnStr = '';
            
            for (_i = 0, _l = dataArr.length; _i < _l; _i += 1) {
                returnStr += this.substitute(text, dataArr[_i], emptyForUndefinedData);
            }
            
            return returnStr;
        },
        
        /*
         * Add hook for jQuery.fn.on function, to manualy call window.Airbrake.captureException() method
         * for every exception occurred.
         * 
         * Let function 'f' be binded as an event handler:
         * 
         * $(window).on 'click', f
         * 
         * If an exception is occurred inside f's body, it will be catched here 
         * and forwarded to captureException method.
         * 
         * processjQueryEventHandlerWrapping is called every time window.Airbrake.setTrackJQ method is used,
         * if it switches previously setted value. 
         */
        processjQueryEventHandlerWrapping: function () {
            if (Config.options.trackJQ === true) {
                Config.jQuery_fn_on_original = Config.jQuery_fn_on_original || jQuery.fn.on;

                jQuery.fn.on = function () {
                    var args = Array.prototype.slice.call(arguments),
                        fnArgIdx = 4;

                    // Search index of function argument
                    while((--fnArgIdx > -1) && (typeof args[fnArgIdx] !== 'function'));

                    // If the function is not found, then subscribe original event handler function
                    if (fnArgIdx === -1) {
                        return Config.jQuery_fn_on_original.apply(this, arguments);
                    }

                    // If the function is found, then subscribe wrapped event handler function
                    args[fnArgIdx] = (function (fnOriginHandler) {
                        return function() {
                            try {
                                fnOriginHandler.apply(this, arguments);
                            } catch (e) {
                                Global.captureException(e);
                            }
                        };
                    })(args[fnArgIdx]);
                    
                    // Call original jQuery.fn.on, with the same list of arguments, but 
                    // a function replaced with a proxy.
                    return Config.jQuery_fn_on_original.apply(this, args);
                };
            } else {
                // Recover original jQuery.fn.on if Config.options.trackJQ is set to false
                (typeof Config.jQuery_fn_on_original === 'function') && (jQuery.fn.on = Config.jQuery_fn_on_original);
            }
        },

        isjQueryPresent: function () {
            // Currently only 1.7.x version supported
            return (typeof jQuery === 'function') && ('fn' in jQuery) && ('jquery' in jQuery.fn)
                    && (jQuery.fn.jquery.indexOf('1.7') === 0)
        },
        
        /*
         * Make first letter in a string capital. e.g. 'guessFunctionName' -> 'GuessFunctionName'
         * Is used to generate getter and setter method names.
         */
        capitalizeFirstLetter: function (str) {
            return str.charAt(0).toUpperCase() + str.slice(1);  
        },
        
        /*
         * Generate public API from an array of specifically formated objects, e.g.
         * 
         * - this will generate 'setEnvironment' and 'getEnvironment' API methods for configObj.xmlData.environment variable:
         * {
         *     variable: 'environment',
         *     namespace: 'xmlData'
         * }
         * 
         * - this will define 'method' function as 'captureException' API method 
         * {
         *     methodName: 'captureException',
         *     method: (function (...) {...});
         * }
         * 
         */
        generatePublicAPI: (function () {
            function _generateSetter (variable, namespace, configObj) {
                return function (value) {
                    configObj[namespace][variable] = value;
                };
            }
            
            function _generateGetter (variable, namespace, configObj) {
                return function (value) {
                    return configObj[namespace][variable];
                };
            }
            
            /*
             * publicAPI: array of specifically formated objects
             * configObj: inner configuration object 
             */
            return function (publicAPI, configObj) {
                var _i = 0, _m = null, _capitalized = '',
                    returnObj = {};
                
                for (_i = 0; _i < publicAPI.length; _i += 1) {
                    _m = publicAPI[_i];
                    
                    switch (true) {
                        case (typeof _m.variable !== 'undefined') && (typeof _m.methodName === 'undefined'):
                            _capitalized = Util.capitalizeFirstLetter(_m.variable)
                            returnObj['set' + _capitalized] = _generateSetter(_m.variable, _m.namespace, configObj);
                            returnObj['get' + _capitalized] = _generateGetter(_m.variable, _m.namespace, configObj);
                            
                            break;
                        case (typeof _m.methodName !== 'undefined') && (typeof _m.method !== 'undefined'):
                            returnObj[_m.methodName] = _m.method
                            
                            break;
                        
                        default:                       
                    }
                }
                
                return returnObj;
            };
        } ())
    };

    /*
     * The object to store settings. Allocated from the Global (windows scope) so that users can change settings
     * only through the methods, rather than through a direct change of the object fileds. So that we can to handle
     * change settings event (in setter method).
     */
    Config = {
        xmlData: {
            environment: 'environment'
        },

        options: {
            trackJQ: false, // jQuery.fn.jquery
            host: 'api.airbrake.io',
            errorDefaults: {},
            guessFunctionName: false,
            requestType: 'GET', // Can be 'POST' or 'GET'
            outputFormat: 'XML' // Can be 'XML' or 'JSON'
        }
    };
    
    /*
     * The public API definition object. If no 'methodName' and 'method' values specified,
     * getter and setter for 'variable' will be defined.
     */
    _publicAPI = [
        {
            variable: 'environment',
            namespace: 'xmlData'
        }, {
            variable: 'key',
            namespace: 'xmlData'
        }, {
            variable: 'host',
            namespace: 'options'
        },{
		    variable: 'projectId',
            namespace: 'options'
		},{
            variable: 'errorDefaults',
            namespace: 'options'
        }, {
            variable: 'guessFunctionName',
            namespace: 'options'
        }, {
            variable: 'outputFormat',
            namespace: 'options'
        }, {
            methodName: 'setCurrentUser',
            method: (function (value) {
                for (var key in value) {
                    if (value.hasOwnProperty(key)) {
                        Config.xmlData['user_' + key] = value[key];
                    }
                }
            })
        }, {
            methodName: 'setTrackJQ',
            variable: 'trackJQ',
            namespace: 'options',
            method: (function (value) {
                if (!Util.isjQueryPresent()) {
                    throw Error('Please do not call \'Airbrake.setTrackJQ\' if jQuery does\'t present');
                }
    
                value = !!value;
    
                if (Config.options.trackJQ === value) {
                    return;
                }
    
                Config.options.trackJQ = value;
    
                Util.processjQueryEventHandlerWrapping();
            })
        }, {
            methodName: 'captureException',
            method: (function (e) {
                new Notifier().notify({
                    message: e.message,
                    stack: e.stack
                });
            })
        }, {
            variable: 'appVersion',
            namespace: 'xmlData'
        }
    ];

    // Share to global scope as Airbrake ("window.Hoptoad" for backward compatibility)
    Global = window.Airbrake = window.Hoptoad = Util.generatePublicAPI(_publicAPI, Config);

    function Notifier() {
        this.options = Util.merge({}, Config.options);
        this.xmlData = Util.merge(this.DEF_XML_DATA, Config.xmlData);
    }
    
    Notifier.prototype = {
        constructor: Notifier,
        VERSION: '0.2.0',
        ROOT: window.location.protocol + '//' + window.location.host,
        BACKTRACE_MATCHER: /^(.*)\@(.*)\:(\d+)$/,
        backtrace_filters: [/notifier\.js/],
        DEF_XML_DATA: {
            request: {}
        },

        notify: (function () {
            /*
             * Emit GET request via <iframe> element.
             * Data is transmited as a part of query string.
             */
            function _sendGETRequest (url, data) {
                var request = document.createElement('iframe');
                
                request.style.display = 'none';
                request.src = url + '?data=' + data;
                
                // When request has been sent, delete iframe
                request.onload = function () {
                    // To avoid infinite progress indicator
                    setTimeout(function() {
                        document.body.removeChild(request);
                    }, 0);
                };
    
                document.body.appendChild(request);
            }
            
            /*
             * Cross-domain AJAX POST request. 
             * 
             * It requires a server setup as described in Cross-Origin Resource Sharing spec:
             * http://www.w3.org/TR/cors/
             */
            function _sendPOSTRequest (url, data) {
                var request = new XMLHttpRequest();
                request.open('POST', url, true);
                request.setRequestHeader('Content-Type', 'application/json');
                request.send(data);
            }
            
            return function (error) {
                var outputData = '',
					url =  '';
				    //
                
                   /*
                    * Should be changed to url = '//' + ...
                    * to use the protocol of current page (http or https). Only sends 'secure' if page is secure.  
					* XML uses V2 API. http://collect.airbrake.io/notifier_api/v2/notices
			       */
               
			
                switch (this.options['outputFormat']) {
                    case 'XML':
	                   outputData = encodeURIComponent(this.generateXML(this.generateDataJSON(error)));
					   url = ('https:' == document.location.protocol ? 'https://' : 'http://') + this.options.host + '/notifier_api/v2/notices';
                        _sendGETRequest(url, outputData);
					   break;

                    case 'JSON': 
 					/*
					*   JSON uses API V3. Needs project in URL. 
					*   http://collect.airbrake.io/api/v3/projects/[PROJECT_ID]/notices?key=[API_KEY]
					* url = window.location.protocol + '://' + this.options.host + '/api/v3/projects' + this.options.projectId + '/notices?key=' + this.options.key;
					*/
 						outputData = JSON.stringify(this.generateJSON(this.generateDataJSON(error)));  
						url = ('https:' == document.location.protocol ? 'https://' : 'http://') + this.options.host + '/api/v3/projects/' + this.options.projectId + '/notices?key=' + this.xmlData.key;
                        _sendPOSTRequest(url, outputData);
						break;

                    default:
                }

            };
        } ()),
        
        /*
         * Generate inner JSON representation of exception data that can be rendered as XML or JSON. 
         */
        generateDataJSON: (function () {
            /*
             * Generate variables array for inputObj object.
             * 
             * e.g.
             * 
             * _generateVariables({a: 'a'}) -> [{key: 'a', value: 'a'}]
             * 
             */
            function _generateVariables (inputObj) {
                var key = '', returnArr = [];
                
                for (key in inputObj) {
                    if (inputObj.hasOwnProperty(key)) {
                        returnArr.push({
                            key: key,
                            value: inputObj[key]
                        });
                    }
                }
                
                return returnArr;
            }
            
            /*
             * Generate Request part of notification.  
             */
            function _composeRequestObj (methods, errorObj) {
                var _i = 0,
                    returnObj = {},
                    type = '';
                
                for (_i = 0; _i < methods.length; _i += 1) {
                    type = methods[_i];
                    if (typeof errorObj[type] !== 'undefined') {
                        returnObj[type] = _generateVariables(errorObj[type]);
                    }
                }
                
                return returnObj;             
            }
            
            return function (errorWithoutDefaults) {
                    /*
                     * A constructor line:
                     * 
                     * this.xmlData = Util.merge(this.DEF_XML_DATA, Config.xmlData);
                     */
                var outputData = this.xmlData, 
                    error = Util.merge(this.options.errorDefaults, errorWithoutDefaults),
                    
                    component = error.component || '',
                    request_url = (error.url || '' + location.href),
                    
                    methods = ['cgi-data', 'params', 'session'],
                    _outputData = null;
                
                _outputData = {
                    request_url: request_url,
                    request_action: (error.action || ''),
                    request_component: component,
                    request: (function () {
                        if (request_url || component) {
                            error['cgi-data'] = error['cgi-data'] || {};
                            error['cgi-data'].HTTP_USER_AGENT = navigator.userAgent;
                            return Util.merge(outputData.request, _composeRequestObj(methods, error));
                        } else {
                            return {}
                        }
                    } ()),
                    
                    project_root: this.ROOT,
                    exception_class: (error.type || errorWithoutDefaults.type ||
                                        (errorWithoutDefaults.constructor.name != "Object" ? errorWithoutDefaults.constructor.name : 'Error')),
                    exception_message: (error.message || errorWithoutDefaults.message || 'Unknown error.'),
                    backtrace_lines: this.generateBacktrace(errorWithoutDefaults)
                }
                
                outputData = Util.merge(outputData, _outputData);
                
                return outputData;
            };
        } ()),
        
        /*
         * Generate XML notification from inner JSON representation.
         * NOTICE_XML is used as pattern.
         */
        generateXML: (function () {
            function _generateRequestVariableGroups (requestObj) {
                var _group = '',
                    returnStr = '';
                
                for (_group in requestObj) {
                    if (requestObj.hasOwnProperty(_group)) {
                        returnStr += Util.substitute(REQUEST_VARIABLE_GROUP_XML, {
                            group_name: _group,
                            inner_content: Util.substituteArr(REQUEST_VARIABLE_XML, requestObj[_group], true)
                        }, true);
                    }
                }
                
                return returnStr;
            }
            
            return function (JSONdataObj) {
                JSONdataObj.request = _generateRequestVariableGroups(JSONdataObj.request);
                JSONdataObj.backtrace_lines = Util.substituteArr(BACKTRACE_LINE_XML, JSONdataObj.backtrace_lines, true);
                
                return Util.substitute(NOTICE_XML, JSONdataObj, true);
            };
        } ()),
        
        /*
         * Generate JSON notification from inner JSON representation.
         * NOTICE_JSON is used as pattern.
         */
        generateJSON: function (JSONdataObj) {
            // Pattern string is JSON.stringify(NOTICE_JSON)
            // The rendered string is parsed back as JSON.
            var outputJSON = JSON.parse(Util.substitute(JSON.stringify(NOTICE_JSON), JSONdataObj, true));
            
            // REMOVED - Request from JSON. 
			outputJSON.request = Util.merge(outputJSON.request, JSONdataObj.request);
            outputJSON.error.backtrace = JSONdataObj.backtrace_lines;
            
            return outputJSON;
        },
        
        generateBacktrace: function (error) {
            var backtrace = [],
                file,
                i,
                matches,
                stacktrace;

            error = error || {};

            if (typeof error.stack !== 'string') {
                try {
                    (0)();
                } catch (e) {
                    error.stack = e.stack;
                }
            }

            stacktrace = this.getStackTrace(error);

            for (i = 0; i < stacktrace.length; i++) {
                matches = stacktrace[i].match(this.BACKTRACE_MATCHER);

                if (matches && this.validBacktraceLine(stacktrace[i])) {
                    file = matches[2].replace(this.ROOT, '[PROJECT_ROOT]');

                    if (i === 0 && matches[2].match(document.location.href)) {
                        // backtrace.push('<line method="" file="internal: " number=""/>');
                       
                        backtrace.push({
						// Updated to fit in with V3 new terms for Backtrace data.
                            'function': '',
                            file: 'internal: ',
                            line: ''
                        });
                    }

                    // backtrace.push('<line method="' + Util.escape(matches[1]) + '" file="' + Util.escape(file) +
                    //        '" number="' + matches[3] + '" />');
                    
                    backtrace.push({
                        'function': Util.escape(matches[1]),
                        file: Util.escape(file),
                        line: matches[3]
                    });
                }
            }

            return backtrace;
        },

        getStackTrace: function (error) {
            var i,
                stacktrace = printStackTrace({
                    e: error,
                    guess: this.options.guessFunctionName
                });

            for (i = 0; i < stacktrace.length; i++) {
                if (stacktrace[i].match(/\:\d+$/)) {
                    continue;
                }

                if (stacktrace[i].indexOf('@') === -1) {
                    stacktrace[i] += '@unsupported.js';
                }

                stacktrace[i] += ':0';
            }

            return stacktrace;
        },

        validBacktraceLine: function (line) {
            for (var i = 0; i < this.backtrace_filters.length; i++) {
                if (line.match(this.backtrace_filters[i])) {
                    return false;
                }
            }

            return true;
        }
    };

    var oldOnerror = window.onerror;
    window.onerror = function (message, file, line, code, error) {
        setTimeout(function () {
            var e = error || {stack: '()@' + file + ':' + line}
            e.message = message
            new Notifier().notify(e);
        }, 0);
        if (oldOnerror) {
          return oldOnerror(message, file, line, code, error);
        }
        return true;
    };
})();
})(window, document);
