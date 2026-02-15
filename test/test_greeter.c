#include "unity.h"
#include "greeter.h"
#include <string.h>

void setUp(void) {}
void tearDown(void) {}

void test_greeting_returns_expected_string(void) {
    TEST_ASSERT_EQUAL_STRING("Hello from clang in Docker!", get_greeting());
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_greeting_returns_expected_string);
    return UNITY_END();
}
