class RETest extends haxe.unit.TestCase{

  function testTest(){
    assertTrue(true);
    assertFalse(false);
    assertEquals(1, 1);
  }

  function testMatchAll(){
    var matches =  new RE('q+a').matchAll('qaqqaqqqa');

    assertTrue(matches.hasNext());
    var m = matches.next();
    trace('\npos:${m.pos} len:${m.len} ${m.group(0)}');
    assertEquals(m.pos, 0);
    assertEquals(m.len, 2);


    assertTrue(matches.hasNext());
    var m = matches.next();
    trace('\npos:${m.pos} len:${m.len} ${m.group(0)}');
    assertEquals(m.pos, 2);
    assertEquals(m.len, 3);

    assertTrue(matches.hasNext());
    var m = matches.next();
    trace('\npos:${m.pos} len:${m.len} ${m.group(0)}');
    assertEquals(m.pos, 5);
    assertEquals(m.len, 4);

    assertFalse(matches.hasNext());
  }

  public static function main(){
    var runner = new haxe.unit.TestRunner();
    runner.add(new RETest());
    var success = runner.run();

    #if sys
    Sys.exit(success ? 0 : 1);
    #end
  }
}
