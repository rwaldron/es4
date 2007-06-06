/* -*- mode: java; indent-tabs-mode: nil -*- 
 *
 * ECMAScript 4 builtins - the "RegExp" object
 * E262-3 15.10
 * E262-4 proposals:extend_regexps
 *
 * Status: complete; not reviewed; not tested.
 *
 * See RegExpCompiler.es for the compiler.
 * See RegExpEvaluator.es for the evaluator and compiled code representation.
 */

package
{
    import Unicode.*;
    import RegExpInternals.*;
    use namespace intrinsic;
    use default namespace public;
    use strict;

    /* E262-3 15.10: Regular expression object */
    public dynamic class RegExp
    {
        /* E262-3 15.10.3.1: The RegExp constructor called as a function */
        meta static function invoke( pattern, flags ) {
            if (pattern is RegExp && flags === undefined)
                return pattern;
            else
                return new RegExp(pattern, flags);
        }

        /* E262-3 15.10.4.1: The RegExp constructor */
        public function RegExp( pattern, flags ) {
            let src : string = "";

            if (pattern is RegExp) {
                if (flags === undefined) {
                    src = pattern.source;
                    flags = pattern.flags;
                }
                else 
                    throw new TypeError("Illegal construction of regular expression");
            }
            else {
                src = pattern === undefined ? "" : String(pattern);
                flags = flags === undefined ? "" : String(flags);
            }

            let usedflags : Object! = { m: false, i: false, g: false, x: false, y: false };

            for ( let i=0, cs=explodeString(flags) ; i < cs.length ; i++ ) {
                let f = cs[i];
                if (!(f in usedflags))
                  throw new SyntaxError("Invalid flag: " + f);
                if (usedflags[f])
                    throw new SyntaxError("Duplicated flag: " + f);
                usedflags[f] = true;
            }

            [matcher,names] = (new RegExpCompiler(src, usedflags)).compile();
            
            multiline = usedflags.m;
            ignoreCase = usedflags.i;
            global = usedflags.g;
            extended = usedflags.x;
            sticky = usedflags.y;
            lastIndex = 0;
            source = src;
        }

        /* E262-4 proposals:extend_regexps: RegExp instances are
           callable, and a call to an instance is equivalent to
           calling its exec() method.
        */
        meta function invoke(s : string) : Array
            exec(s);

        /* E262-3 15.10.6.2: RegExp.prototype.exec */
        intrinsic function exec(s : string) : Array {
            let length : uint = s.length;
            let i : double = ToInteger(lastIndex);
            if (!global)
                i = 0;
            let res : MatchResult = failure;
            while (true) {
                if (i < 0 || i > length) {
                    lastIndex = 0;
                    return null;
                }
                res = matcher.match(s, i, multiline, ignoreCase);
                if (res !== failure)
                    break;
                ++i;
            }
            if (global)
                lastIndex = res.endIndex;
            let a = new Array(res.cap.length);
            a.index = i;
            a.input = s;
            a.length = res.cap.length;
            a[0] = s.substring(i,res.endIndex);
            for ( let j=1 ; j < res.cap.length ; j++ )
                a[j] = res.cap[j];
            for ( let j=1 ; j < names.length ; j++ )
                if (names[j] !== null)
                    a[names[j]] = res.cap[j];
            return a;
        }

        prototype function exec(s)
            this.exec(ToString(s));

        /* E262-3 15.10.6.3: RegExp.prototype.test */
        intrinsic function test(s : string) : boolean
             exec(s) !== null;

        prototype function test(s)
            this.test(ToString(s));

        /* E262-3 15.10.6.4: RegExp.prototype.toString */
        override intrinsic function toString() : String
            "/" + (source.length == 0 ? "(?:)" : source) + "/" + flags;

        prototype function toString()
            this.intrinsic::toString();

        /* E262-3 15.10.7: properties of regexp instances */
        /* FIXME: the flags should be 'const'.  Ticket #24. */
        public var multiline  : boolean;
        public var ignoreCase : boolean;
        public var global     : boolean;
        public var extended   : boolean; // E262-4 proposals:extend_regexps
        public var sticky     : boolean; // E262-4 proposals:extend_regexps
        public var source     : string;
        public var lastIndex  : double;

        /* E262-4 - [[Match]] may not *have* to be public, but String
         * uses it, and if we want to model the language in the
         * language we should expose it -- it's benign.
         * 
         * FIXME: Should it be exposed like this?  Recorded as ticket #56.
        */
        intrinsic function match(s : string, i : uint) : MatchResult
            matcher.match(s, i, multiline, ignoreCase);

        /* E262-4 - nCapturingParens used by String.prototype.replace.
         *
         * FIXME: Should it be exposed like this?  Recorded as ticket #56.
         */
        intrinsic function get nCapturingParens() : uint
            matcher.nCapturingParens;

        /* Internal */
        private var matcher : RegExpMatcher;      // The [[Match]] property  // FIXME: const.  Ticket #24.
        private var names : [string?];            // Named submatches  // FIXME: const.  Ticket #24.

        /* E262-3 15.10.6.4 probably is meant to require the flags to
         * be returned in lexicographic order for the purposes of
         * toString().
         */
        private function get flags() : string {
            return (global ? "g" : "") +
                   (ignoreCase ? "i" : "") +
                   (multiline ? "m" : "") +
                   (extended ? "x" : "") +
                   (sticky ? "y" : "");
        }
    }
}
