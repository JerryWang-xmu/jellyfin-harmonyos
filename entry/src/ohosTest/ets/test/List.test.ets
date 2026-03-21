/**
 * Jellyfin HarmonyOS - Test List
 * Main test entry point that registers all test suites
 */

import abilityTest from './Ability.test';
import testSuite from './AllTests.test';

export default function testsuite() {
  // Original ability test
  abilityTest();

  // Jellyfin unit test suite
  testSuite();
}
