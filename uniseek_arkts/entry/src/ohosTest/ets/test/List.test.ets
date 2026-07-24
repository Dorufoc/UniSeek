import abilityTest from './Ability.test';
import chatUtilsTest from './chat/ChatUtils.test';
import chatComponentsTest from './chat/ChatComponents.test';

export default function testsuite() {
  abilityTest();
  chatUtilsTest();
  chatComponentsTest();
}
