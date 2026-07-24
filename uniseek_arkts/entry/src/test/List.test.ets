import localUnitTest from './LocalUnit.test';
import foundationTest from './Foundation.test'
import recruiterResumeFilterTest from './RecruiterResumeFilter.test'
import applicationTabPolicyTest from './ApplicationTabPolicy.test'
import auditPoliciesTest from './AuditPolicies.test'
import chatUtilsTest from './chat/ChatUtils.test';
import chatComponentsTest from './chat/ChatComponents.test';

export default function testsuite() {
  localUnitTest();
  foundationTest()
  recruiterResumeFilterTest()
  applicationTabPolicyTest()
  auditPoliciesTest()
  chatUtilsTest();
  chatComponentsTest();
}
