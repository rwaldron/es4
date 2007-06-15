/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is [Open Source Virtual Machine.].
 *
 * The Initial Developer of the Original Code is
 * Adobe System Incorporated.
 * Portions created by the Initial Developer are Copyright (C) 2005-2006
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Adobe AS3 Team
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

package Prototyping {

	namespace defaultNS;

	class DefaultClass {

		var array:Array = new Array(1,2,3);						// Default property
		internal var intNumber:Number = 100;					// internal property
		protected var protInt:int = -1;						// protected property

		public var pubUint:uint = 1;							// public property
		private var privVar:Boolean = true;						// private property
		public static var pubStat:Number = 100;		// public static property
		defaultNS var nsProp:String = "nsProp";						// namespace property

		// default method
		function defaultMethod():Boolean{ return true; }

		// Internal method
		internal function internalMethod():int { return 1; }

		// protected method
		protected function protectedMethod():uint { return 1; }

		// public method
		public function publicMethod():Boolean { return true; }

		// private method
		private function privateMethod():Boolean { return true; }

		// namespace method
		defaultNS function nsMethod():Number { return 1; }

		// public final method
		public final function publicFinalMethod():Number { return 1; }

		// public static method
		public static function publicStaticMethod():int { return 42; }

		// access private property from same class same package
		public function accPrivProp():Boolean {
			return this.privVar;
		}

		//accessor function for ns property
		public function accNS():String {
			return this.defaultNS::nsProp;
		}

		//accessor function for namespace method
		public function accNSMethod():Number{
			return this.defaultNS::nsMethod();
		}

		// access private method from same class same package
		public function accPrivMethod():Boolean {
			return this.privateMethod();
		}

		//accessor for default property
		public function accessDefaultProperty():Array{
			return this.array;
		}

	}


}