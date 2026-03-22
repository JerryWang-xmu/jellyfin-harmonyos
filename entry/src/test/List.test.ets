import localUnitTest from './LocalUnit.test';
import batchOneUnitTest from './BatchOneUnit.test';
import batchTwoUnitTest from './BatchTwoUnit.test';
import batchThreeUnitTest from './BatchThreeUnit.test';
import navigationRefactorUnitTest from './NavigationRefactorUnit.test';

export default function testsuite() {
  localUnitTest();
  batchOneUnitTest();
  batchTwoUnitTest();
  batchThreeUnitTest();
  navigationRefactorUnitTest();
}