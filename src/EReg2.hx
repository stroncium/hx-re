//      This program is free software; you can redistribute it and/or modify
//      it under the terms of the GNU General Public License as published by
//      the Free Software Foundation; either version 2 of the License, or
//      (at your option) any later version.
//
//      This program is distributed in the hope that it will be useful,
//      but WITHOUT ANY WARRANTY; without even the implied warranty of
//      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//      GNU General Public License for more details.
//
//      You should have received a copy of the GNU General Public License
//      along with this program; if not, write to the Free Software
//      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
//      MA 02110-1301, USA.



/*
 * Allowed flags:
 *  i - (case) insensitive
 *  s - dotall, '.' matches all symbols including newlines, not working in js
 *  m - multiline
 *  g - global
 *
 * Other flags will be stripped.
 */

/*
 * Works in utf8 mode by default except js(depends on page encoding)
 * Depends on utf8 static var(true by default) for cpp, neko and php.
 * It should be switched to false if PCRE are compiled w/o utf8 support.
 */

private class Exception{
  public static var NON_EXISTING_MATCH:String  = 'EReg: Trying to get non-existing match.';
  public static var NO_MATCH:String = 'EReg: No string matched.';
  public static var OPT_S_NOT_IMPLEMENTED = "'s' option not implemented for this platform.";
  }

class EReg2{
  public static var utf8:Bool = true;
  private var as_string:String;

  var r:Dynamic;
  var global:Bool;

  #if !(flash9 || js)
    var last:String;
  #end

  #if (flash9 || js)
    var result:{
      > Array<String>,
      index : Int,
      input : String
      };
  #elseif (neko || cpp)
    var lastpos:Int;
    #if neko
      static private var regexp_new_options_r = neko.Lib.load("regexp", "regexp_new_options", 2);
      static private inline function regexp_new_options(re:String, opt:String){
        regexp_new_options_r(untyped re.__s, untyped opt.__s);
        }

      static private var regexp_match_r = neko.Lib.load("regexp", "regexp_match", 4);
      static private inline function regexp_match(r:Dynamic, s:String, offset:Int, length:Int):Bool{
        return regexp_match_r(r, untyped s.__s, offset, length);
        }

      static private var regexp_matched_r = neko.Lib.load("regexp", "regexp_matched", 2);
      static private inline function regexp_matched(r:Dynamic, num:Int):String{
        return new String(regexp_matched_r(r, num));
        }

      static private var regexp_matched_pos:Dynamic->Int->{ pos:Int, len:Int } = neko.Lib.load("regexp", "regexp_matched_pos", 2);
    #else
      static private var regexp_new_options = cpp.Lib.load("regexp", "regexp_new_options", 2);
      static private var regexp_match = cpp.Lib.load("regexp", "regexp_match", 4);
      static private var regexp_matched = cpp.Lib.load("regexp", "regexp_matched", 2);
      static private var regexp_matched_pos:Dynamic->Int->{ pos:Int, len:Int } = cpp.Lib.load("regexp", "regexp_matched_pos", 2);
    #end
  #elseif php
    var matches : ArrayAccess<Dynamic>;
    var pos:Int;
    var len:Int;
  #else
    #error
  #end

  public function new(r:String, opt:String) {
    this.as_string = '~/'+r+'/'+opt;
    #if flash9
      this.global = (opt.indexOf('g') != -1);
      this.r = untyped __new__(__global__["RegExp"], r, opt);
    #elseif (neko || cpp || php || js)
      #if (neko || php || cpp)
        var newopt:String = utf8 ? 'u': ''; // utf-8
      #elseif (js || flash9)
        var newopt:String = '';
      #end
      this.global = false;
      #if (cpp || neko)
        this.lastpos = 0;
      #end

      var i:Int = 0;
      var len:Int = opt.length;
      while(i < len){
        switch(opt.charAt(i)){
          case 'i': newopt+='i';
          case 's':{
            #if js
              throw Exception.OPT_S_NOT_IMPLEMENTED;
            #else
              newopt+='s';
            #end
            }
          case 'm': newopt+='m';
          case 'g': {
            #if js
              newopt+='g';
            #end
            this.global = true;
            }
          }
        i++;
        }
      #if (neko || cpp)
        this.r = regexp_new_options(r, newopt);
      #elseif php
        this.r = "/" + untyped __php__("str_replace")("/", "\\/", r) + "/" + newopt;
      #elseif js
        this.r = untyped __new__("RegExp",r,newopt);
      #end
    #end
    }

  public function match(s:String, ?offset:Int = -1):Bool {
    #if (flash9 || js)
      if(offset >= 0){
        r.lastIndex = offset;
        }
      result = untyped r.exec(s);
      return (result != null);
    #elseif (neko || cpp)
      if(offset < 0){
        offset = ( this.global && (s==this.last)) ? this.lastpos : 0;
        }
      var m = regexp_match(r, s, offset, s.length - offset );
      if(this.global){
        if ( m ) {
          var p = regexp_matched_pos(r, 0);
          this.lastpos = p.pos + p.len;
          }
        else{
          this.lastpos = 0;
          }
        }
      this.last = m ? s : null;
      return m;
    #elseif php
      if(offset < 0){
        offset = ( this.global && (s==this.last)) ? (this.pos+this.len) : 0;
        }
      var p : Int = untyped __php__("preg_match")(this.r, s, matches, __php__("PREG_OFFSET_CAPTURE"), offset);
      if(p > 0){
        this.last = s;
        this.pos = untyped __php__("$this->matches[0][1]");
        this.len = untyped __php__("strlen")(__php__("$this->matches[0][0]"));
        }
      else{
        this.last = null;
        }
      return (p > 0);
    #end
    }

  public function matched(n:Int):String {
    #if (flash9 || js)
      if( (result == null) || (n < 0) || (n >= result.length) ){
        throw Exception.NON_EXISTING_MATCH;
        }
      return untyped result[n];
    #elseif (neko || cpp)
      var m = regexp_matched(r,n);
      if (m == null){
        throw Exception.NON_EXISTING_MATCH;
        }
      return m;
    #elseif php
      var m_num:Int = untyped __call__("count", matches);
      if( (last == null) || (n < 0) || (n >= m_num) ){
        throw Exception.NON_EXISTING_MATCH;
        }
      return (untyped __php__("$this->matches[$n][1] < 0")) ? // if -1 pos
        null: // none matched
        untyped __php__("$this->matches[$n][0]");
    #end
    }

  public function matched_left():String {
    #if (flash9 || js)
      if( result == null ){
        throw Exception.NO_MATCH;
        }
      return result.input.substr(0, result.index);
    #elseif (neko || cpp)
      if( last == null ){
        throw Exception.NO_MATCH;
        }
      var p = regexp_matched_pos(r,0);
      return last.substr(0, p.pos);
    #elseif php
      if( untyped __call__("count", matches) == 0 ){
        throw Exception.NO_MATCH;
        }
      return last.substr(0, untyped __php__("$this->matches[0][1]"));
    #end
    }

  public function matched_right():String {
    #if (flash9 || js)
      if( result == null ){
        throw Exception.NO_MATCH;
        }
      var l:Int = result.index+result[0].length;
      var inp:String = result.input;
      return inp.substr(l, inp.length - l);
    #elseif (neko || cpp)
      if( last == null ){
        throw Exception.NO_MATCH;
        }
      var p = regexp_matched_pos(r,0);
      var rightpos = p.pos + p.len;
      return last.substr(rightpos, last.length - rightpos);
    #elseif php
      if( untyped __call__("count", matches) == 0 ){
        throw Exception.NO_MATCH;
        }
      return last.substr(untyped __php__("$this->matches[0][1]") + __php__("strlen")(__php__("$this->matches[0][0]")));
    #end
    }

  public function matched_pos():{pos:Int, len:Int} {
    #if (flash9 || js)
      if( result == null ){
        throw Exception.NO_MATCH;
        }
      return {
        pos: result.index,
        len: result[0].length
        }
    #elseif (neko || cpp)
      if( last == null ){
        throw Exception.NO_MATCH;
        }
      return regexp_matched_pos(r,0);
    #elseif php
      return {
        pos : this.pos,
        len : this.len
        };
    #end
    }

  public function split(s:String):Array<String> {
    #if (flash9 || js)
      if(global){
        return s.split(r);
        }
      else{
        result = untyped r.exec(s);
        if(result == null){
          return [s];
          }
        else{
          var match_s:Int = result.index;
          var match_f:Int = result[0].length+match_s;
          return [
            s.substr(0, match_s),
            s.substr(match_f, s.length - match_f)
            ];
          }
        }
    #elseif (neko || cpp)
      var start:Int = 0;
      var len:Int = s.length;
      var ret = new Array<String>();
      var p;
      var cont:Bool = true;
      while(cont && regexp_match(r, untyped s, start, len)){
        p = regexp_matched_pos(r,0);
        ret.push(s.substr(start, p.pos-start));
        start = p.pos + p.len;
        len = s.length - start;
        cont = this.global;
        }
      ret.push(s.substr(start, len));
      return ret;
    #elseif php
      return untyped php.Lib.toHaxeArray(
        untyped __php__('preg_split')(
          this.r,
          s,
          this.global ? -1 : 2
          )
        );
    #end
    }

  public function replace(s:String, by:String):String {
    #if (flash9 || js)
      return untyped s.replace(r, by);
    #elseif (neko || cpp)
      var buffer = new StringBuf();
      var str = new Array<String>();
      var ins = new Array<Int>();
      var fin:String;
      var insnum:Int = 0;

      var start:Int = 0;
      var curpos:Int;
      var nxt1:Int;
      var nxt2:Int;
      while( (curpos = by.indexOf('$', start)) != -1){
        nxt1 = by.charCodeAt(curpos+1) - 48; // '0' ... '9' => 0 ... 9
        if( (nxt1 > 0) && (nxt1 <= 9) ){ // means it's a place for insert
          str.push(by.substr(start, curpos - start)); // string part
          insnum++;
          nxt2 = by.charCodeAt(curpos+2) - 48;
          if( (nxt2 >= 0) && (nxt1 <= 9) ){ // means it's a 2 digit number
            ins.push( (nxt1*10) + nxt2 ); // 2-digit insert part
            start = curpos + 3;
            }
          else{
            ins.push( nxt1 ); // 1-digit insert part
            start = curpos + 2;
            }
          }
        }
      fin = by.substr(start, by.length - start);

      var len:Int = s.length;
      start = 0;
      var cont:Bool = true;
      while(cont && regexp_match(r, untyped s, start, len-start)){
        var p = regexp_matched_pos(r,0);
        buffer.addSub(s, start, p.pos-start);
        var i:Int;

        i = 0;
        while(i < insnum){
          buffer.add(str[i]);
          var m = regexp_matched(r,ins[i]);
          if (m == null){
            throw Exception.NON_EXISTING_MATCH;
            }
          buffer.add(new String(m));
          i++;
          }
        buffer.add(fin);

        start = p.pos + p.len;
        //~ len = s.length - start;
        cont = global;
        }
      buffer.addSub(s, start, len-start);
      return buffer.toString();
    #elseif php
      by = untyped __call__("str_replace", "$$", "\\$", by);
      untyped __php__(
        "if(!preg_match('/\\\\([^?].+?\\\\)/', $this->r)) $by = preg_replace('/\\$(\\d+)/', '\\\\\\$\\1', $by)"
        );
      return untyped __php__("preg_replace")(this.r, by, s, this.global ? -1 : 1);
    #end
    }

  public function custom_replace(s:String, fnc:EReg2->String):String {
    #if (flash9 || neko || php || cpp || js)
      var buffer = new StringBuf();
      while( match(s) ) {
        buffer.add(matched_left());
        buffer.add( fnc(this) );
        s = matched_right();
        }
      buffer.add(s);
      return buffer.toString();
    #end
    }

  public function match_all(s:String):Array<String> {
    #if flash9
      if(global){
        var ret:Array<String> = untyped s.match(r);
        return (ret.length > 0)?
          ret : null;
        }
      else{
        var ret:String = untyped s.match(r);
        return (ret != null) ?
          [ret] : null;
        }
    #elseif js
      return untyped s.match(r);
    #elseif (neko || cpp)
      var start:Int = 0;
      var len:Int = s.length;
      var ret = new Array<String>();
      var cont:Bool = true;
      while(cont && regexp_match(r, untyped s, start, len)){
        ret.push(regexp_matched(r, 0));
        var p = regexp_matched_pos(r,0);
        start = p.pos + p.len;
        len = s.length - start;
        cont = this.global;
        }
      return (ret.length > 0)?
        ret : null;
    #elseif php
      var p:Int = this.global ?
        untyped __php__('preg_match_all')(this.r, s, matches, untyped __php__('PREG_PATTERN_ORDER')) :
        untyped __php__("preg_match")(this.r, s, matches);
      return (p > 0) ?
        this.global ?
          untyped php.Lib.toHaxeArray(untyped __php__('$this->matches[0]')):
          untyped [ untyped __php__('$this->matches[0]') ]:
        null;
    #end
    }

  public function toString(){
    return this.as_string;
    }

  }
