/* -*- indent-tabs-mode: nil -*- 
 *
 * ECMAScript 4 builtins - the "int" object
 *
 * E262-3 15.7
 * E262-4 proposals:numbers
 * Tamarin code
 *
 * Status: Complete; not reviewed; not tested.
 */

package
{
    use namespace intrinsic;
    use strict;

    final class int!
    {       
        public static const MAX_VALUE : int = 0x7FFFFFFF;
        public static const MIN_VALUE : int = -0x80000000;

        /* E262-4 draft */
        function to int(x : Numeric)
            x is int ? x : ToInt(x);

        /* E262-4 draft: The int Constructor Called as a Function */
        function call int(value)
            value === undefined ? 0i : ToInt(value);

        /* E262-4 draft: The int constructor */
        public function int(value) {
            magic::setValue(this, ToInt(value));
	}

        /* E262-4 draft: int.prototype.toString */
        prototype function toString(this:int, radix)
            this.toString(radix);

        override intrinsic function toString(/*radix = 10*/) : string {
            var radix = 10 /* fixme */
            if (radix === 10 || radix === undefined)
                return ToString(magic::getValue(this));
            else if (typeof radix === "number" && radix >= 2 && radix <= 36 && isIntegral(radix)) {
                // FIXME
                throw new Error("Unimplemented: non-decimal radix");
            }
            else
                throw new TypeError("Invalid radix argument to int.toString");
        }
        
        /* E262-4 draft: int.prototype.toLocaleString() */
        prototype function toLocaleString(this:int)
            this.toLocaleString();

        /* INFORMATIVE */
        override intrinsic function toLocaleString() : string
            toString();

        /* E262-4 draft: int.prototype.valueOf */
        prototype function valueOf(this:int)
            this.valueOf();

        override intrinsic function valueOf() : Object!
            this;

        /* E262-3 15.7.4.5 int.prototype.toFixed */
        prototype function toFixed(this:int, fractionDigits)
            this.toFixed(ToDouble(fractionDigits));

        intrinsic function toFixed(fractionDigits:double) : string 
	    ToDouble(this).toFixed(fractionDigits);

        /* E262-4 draft: int.prototype.toExponential */
        prototype function toExponential(this:int, fractionDigits)
            this.toExponential(ToDouble(fractionDigits));

        intrinsic function toExponential(fractionDigits:double) : string
	    ToDouble(this).toExponential(fractionDigits);

        /* E262-4 draft: int.prototype.toPrecision */
        prototype function toPrecision(this:int, precision)
            this.toPrecision(ToDouble(precision));

        intrinsic function toPrecision(precision:double) : string
	    ToDouble(this).toPrecision(precision);
    }
}
