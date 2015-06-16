import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class HelloTest {
  @Test
  public void test() {
    assertEquals("Hello World", new Hello().get());
  }
}