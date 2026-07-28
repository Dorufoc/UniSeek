import localUnitTest from './LocalUnit.test';
import foundationTest from './Foundation.test'
import recruiterResumeFilterTest from './RecruiterResumeFilter.test'
import applicationTabPolicyTest from './ApplicationTabPolicy.test'
import auditPoliciesTest from './AuditPolicies.test'
import chatUtilsTest from './chat/ChatUtils.test';
import chatComponentsTest from './chat/ChatComponents.test';
import chatWebSocketPolicyTest from './chat/ChatWebSocketPolicy.test';
import regionPathBuilderTest from './RegionPathBuilder.test'

export default function testsuite() {
  localUnitTest();
  foundationTest()
  recruiterResumeFilterTest()
  applicationTabPolicyTest()
  auditPoliciesTest()
  chatUtilsTest();
  chatComponentsTest();
  chatWebSocketPolicyTest();
  regionPathBuilderTest();
}
